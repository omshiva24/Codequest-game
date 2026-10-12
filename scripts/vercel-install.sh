#!/usr/bin/env bash
# CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
# All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.
# Installs a pinned Flutter SDK on the Vercel build machine (Vercel has no
# Flutter preinstalled) and the API's Node packages from the lockfile.
# Pinning versions keeps builds reproducible.
set -euo pipefail

# API packages (exact versions from package-lock.json, no install scripts).
npm ci --omit=dev --ignore-scripts --no-audit --no-fund

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"
FLUTTER_DIR="${FLUTTER_DIR:-$PWD/.flutter-sdk}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics --enable-web > /dev/null
flutter --version
flutter pub get
