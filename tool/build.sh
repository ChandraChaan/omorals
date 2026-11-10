#!/usr/bin/env bash
# Build everything into ./dist:
#   dist/        the public website (from ./site)
#   dist/app/    the team workspace (Flutter web, from ./lib)
#
# Usage: tool/build.sh [extra flutter build args]
#   e.g. tool/build.sh --dart-define=USE_EMULATOR=true
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Refreshing latest videos"
python3 tool/fetch_videos.py || echo "    (skipped)"

echo "==> Building workspace app"
flutter pub get
flutter build web --release --base-href /app/ "$@"

echo "==> Assembling dist/"
OUT="$ROOT/dist"
mkdir -p "$OUT"
find "$OUT" -mindepth 1 -delete
cp -R "$ROOT/site/." "$OUT/"
mkdir -p "$OUT/app"
cp -R "$ROOT/build/web/." "$OUT/app/"

echo "==> Done: $(find "$OUT" -type f | wc -l | tr -d ' ') files in dist/"
