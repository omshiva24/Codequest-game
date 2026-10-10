#!/usr/bin/env bash
# Builds the Flutter web app into build/web for Vercel to serve.
set -euo pipefail

FLUTTER_DIR="${FLUTTER_DIR:-$PWD/.flutter-sdk}"
export PATH="$FLUTTER_DIR/bin:$PATH"

# --no-web-resources-cdn: serve the rendering engine (CanvasKit) from our own
# domain instead of a third-party CDN, so the CSP can stay strict.
flutter build web --release --no-web-resources-cdn --base-href /
