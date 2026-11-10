# OMorals Media

One repository, two things:

| Path | What it is | Served at |
| --- | --- | --- |
| `site/` | Public website: YouTube studio, digital marketing, web & mobile apps. Plain HTML/CSS/JS with a WebGL scene (three.js), GSAP scroll choreography and Lenis smooth scroll. No build step. | `https://omorals.web.app/` |
| `lib/` | **OMorals Workspace**, the team's internal tool (Flutter web): tasks and projects, the YouTube video pipeline, leads and call tracking, team management. | `https://omorals.web.app/app/` |

Backend is Firebase project **`omorals`**: Authentication (Google + email/password), Cloud Firestore, Hosting.

## Workspace: who sees what

Roles: `owner` > `admin` > `manager` > `member`. Departments: `youtube`, `marketing`, `development`.

- The **studio owner** claims the workspace on their first sign-in (Google sign-in with an account listed, as a hash, in `mayClaimWorkspace()` in the rules).
- Everyone else who signs up is **pending** until an owner/admin approves them on the Team screen and picks their department and role.
- Members see Tasks plus their department's screens. Callers only see **their own** leads and calls.
- A call is stamped with the server's clock and cannot be edited or deleted by the caller afterwards.

All of this is enforced in [`firestore.rules`](firestore.rules), not just in the UI.

The website's contact form writes to the `inquiries` collection; managers see those under **Calls & leads → Website enquiries** and can convert them into leads.

## Run it locally

```bash
# 1. build with the local-emulator switch on
tool/build.sh --dart-define=USE_EMULATOR=true

# 2. start local Auth + Firestore + Hosting (nothing touches the real project)
firebase emulators:start --project omorals --only auth,firestore,hosting

# 3. optional: a demo team with sample tasks, videos, leads and calls
python3 tool/seed_emulator.py
```

Open <http://localhost:5050> (site) and <http://localhost:5050/app/> (workspace).

To work on the website alone: `python3 -m http.server 4173 --directory site`.

## Deploy

**From this Mac**

```bash
./deploy.sh            # build + deploy site, workspace and Firestore rules
./deploy.sh preview    # temporary preview URL, expires in 7 days
./deploy.sh rules      # only the Firestore rules
```

**From GitHub (CI/CD)**: [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)

- push to `main` → analyze, test, build, deploy live
- pull request → analyze, test, build, preview URL in the job summary
- every morning (07:00 IST) → rebuild so the site's "Latest from the channel" is fresh
- keyless: GitHub signs in to Google with Workload Identity Federation, so there is no secret to store or rotate

One-time switch-on (creates a deploy-only service account that only this repository can use):

```bash
gcloud auth login
tool/setup_ci.sh
```

Until that has been run, the workflow builds and tests but skips the deploy steps.

## Versions and releases

The version is the `version:` line in `pubspec.yaml`; history is in [`CHANGELOG.md`](CHANGELOG.md).

To cut a release, bump the version, add a changelog section, then tag and push:

```bash
git tag -a v2.1.0 -m "v2.1.0" && git push origin v2.1.0
```

[`.github/workflows/release.yml`](.github/workflows/release.yml) then builds everything once and publishes:

- a **GitHub Release** with the built web bundle (`omorals-web-<version>.zip`) attached
- a **container image** on GitHub Packages, which serves the same site with nginx:

```bash
docker run -p 8080:80 ghcr.io/chandrachaan/omorals:latest
```

The image talks to the same Firebase project as the live site, so the workspace inside it shows real data.

## Editing the website

- Copy and sections: `site/index.html`
- Colours, type, layout: `site/css/main.css` (tokens at the top)
- Interactions (loader, cursor, scroll): `site/js/main.js`
- 3D scene and where each object sits per section: `site/js/scene.js` (`POSES`)
- Latest videos: `site/videos.json`, refreshed by `tool/fetch_videos.py` from the channel's public feed on every build

`site/vendor/` holds pinned copies of three.js 0.187, GSAP 3.15 and Lenis 1.3 so the site has no third-party script dependencies at runtime.

## Notes

- `android/` and `ios/` are from the original 2024 prototype and have not been migrated to the current Flutter toolchain; the workspace currently ships as a web app.
- The old prototype's source is in git history before the `rebuild/site-and-workspace` branch.
