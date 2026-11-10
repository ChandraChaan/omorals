# Changelog

Versions follow [semantic versioning](https://semver.org). The version lives in
`pubspec.yaml`; a release is made by pushing a matching `v*` tag.

## 2.0.0 (2026-11-10)

A full rebuild. The 2024 prototype is replaced by a public website and an
internal team workspace, both served from Firebase.

### Website
- New public site for the YouTube studio, digital marketing and web & mobile
  app work, with process and contact sections.
- WebGL scene that follows scroll and pointer; on phones each 3D object gets
  its own space so it never sits behind text.
- Preloader, smooth scroll, scroll-driven text and card animation, all of
  which stand down for reduced-motion settings.
- "Latest from the channel" filled from the channel's public feed at build time.
- Contact form that sends enquiries to the workspace.
- Light cursor follower: the system cursor stays visible, with a thin ring and
  a contextual label over videos and cards.

### Workspace
- Tasks and projects with a drag-and-drop board, list view and comments.
- YouTube video pipeline with eight stages, time-in-stage and stage history.
- Leads and call logging, follow-ups, call log, per-agent scoreboard and
  website enquiries.
- Team approval, roles (owner, admin, manager, member) and departments.
- Overview for managers: KPIs, team pulse, pipeline strip, needs-attention list.

### Platform
- Firestore security rules enforce every permission; 36 role-by-role checks
  run against the local emulators.
- GitHub Actions: build and test on every push, keyless deploy to Firebase
  Hosting, daily rebuild.
- Releases: built web bundle attached to each GitHub Release and a container
  image published to GitHub Packages.

## 1.0.0 (2024)

The original prototype: a Flutter app listing the channel's videos, with
author, voice and editor screens. Kept in history at the `v1.0.0` tag.
