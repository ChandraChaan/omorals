#!/usr/bin/env bash
# One-command deploy from this Mac.
#
#   ./deploy.sh            build + deploy website, workspace app and database rules
#   ./deploy.sh preview    build + deploy to a temporary preview URL (expires in 7 days)
#   ./deploy.sh rules      deploy only the Firestore security rules
#
# Needs: flutter, python3 and the Firebase CLI (npm i -g firebase-tools; firebase login).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
PROJECT="omorals"
MODE="${1:-live}"

case "$MODE" in
  rules)
    firebase deploy --project "$PROJECT" --only firestore
    ;;
  preview)
    tool/build.sh
    firebase hosting:channel:deploy "preview-$(date +%m%d-%H%M)" --project "$PROJECT" --expires 7d
    ;;
  live)
    tool/build.sh
    firebase deploy --project "$PROJECT" --only hosting,firestore
    echo
    echo "Live: https://$PROJECT.web.app  (workspace: https://$PROJECT.web.app/app/)"
    ;;
  *)
    echo "Unknown mode '$MODE'. Use: ./deploy.sh [live|preview|rules]" >&2
    exit 1
    ;;
esac
