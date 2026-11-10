#!/usr/bin/env bash
# One-time setup so GitHub Actions can deploy this project.
#
# Keyless: uses Workload Identity Federation, so GitHub proves which repository
# is running and Google hands it a short-lived token. No key file is created
# and nothing is stored in GitHub secrets.
#
# Run once, as the Google account that owns the Firebase project:
#
#   gcloud auth login
#   tool/setup_ci.sh
#
# Safe to re-run; every step checks whether it already exists.
set -euo pipefail

PROJECT="omorals"
REPO="ChandraChaan/omorals"
SA="github-deploy"
POOL="github"
PROVIDER="github-oidc"
EMAIL="$SA@$PROJECT.iam.gserviceaccount.com"

# The least the Firebase CLI needs to deploy Hosting and Firestore rules.
ROLES=(
  roles/firebasehosting.admin
  roles/firebaserules.admin
  roles/datastore.indexAdmin
  roles/serviceusage.apiKeysViewer
  roles/serviceusage.serviceUsageConsumer
  roles/firebase.viewer
)

command -v gcloud >/dev/null || { echo "gcloud is not installed: https://cloud.google.com/sdk/docs/install" >&2; exit 1; }
command -v gh >/dev/null || { echo "GitHub CLI (gh) is not installed: https://cli.github.com" >&2; exit 1; }

NUMBER="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')"
echo "==> Project $PROJECT ($NUMBER), repository $REPO"

echo "==> Enabling APIs"
gcloud services enable iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com \
  cloudresourcemanager.googleapis.com --project "$PROJECT"

echo "==> Deploy service account"
gcloud iam service-accounts describe "$EMAIL" --project "$PROJECT" >/dev/null 2>&1 ||
  gcloud iam service-accounts create "$SA" --project "$PROJECT" \
    --display-name "GitHub Actions deploy" \
    --description "Deploys Firebase Hosting and Firestore rules for $REPO"

for role in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$EMAIL" \
    --role "$role" --condition=None --quiet >/dev/null
  echo "    granted $role"
done

echo "==> Identity pool and GitHub provider"
gcloud iam workload-identity-pools describe "$POOL" --project "$PROJECT" --location global >/dev/null 2>&1 ||
  gcloud iam workload-identity-pools create "$POOL" --project "$PROJECT" --location global \
    --display-name "GitHub Actions"

gcloud iam workload-identity-pools providers describe "$PROVIDER" --project "$PROJECT" --location global \
  --workload-identity-pool "$POOL" >/dev/null 2>&1 ||
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" --project "$PROJECT" --location global \
    --workload-identity-pool "$POOL" --display-name "GitHub OIDC" \
    --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition "assertion.repository == '$REPO'"

echo "==> Allowing only $REPO to act as the deploy account"
gcloud iam service-accounts add-iam-policy-binding "$EMAIL" --project "$PROJECT" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/$NUMBER/locations/global/workloadIdentityPools/$POOL/attribute.repository/$REPO" \
  --quiet >/dev/null

echo "==> Switching deploys on in GitHub"
gh variable set FIREBASE_DEPLOY --body on --repo "$REPO"

cat <<EOF

Done. GitHub Actions can now deploy.
  provider:        projects/$NUMBER/locations/global/workloadIdentityPools/$POOL/providers/$PROVIDER
  service account: $EMAIL

Try it: gh workflow run "Build and deploy" --repo $REPO --ref main
EOF
