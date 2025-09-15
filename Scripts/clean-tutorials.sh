#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Cleaning build artifacts (.build, caches, .tutor) across tutorials…"
find tutorials -maxdepth 2 -type d \( -name .build -o -name .modulecache -o -name .swift-module-cache -o -name .tutor \) -print -exec rm -rf {} +

echo "Removing generated sources from tutorials where setup.sh creates them…"

# 01 – Hello Csound: generated sources/tests
rm -f tutorials/01-hello-csound/Sources/HelloCsound/CsoundPlayer.swift || true
rm -f tutorials/01-hello-csound/Sources/HelloCsound/main.swift || true
rm -f tutorials/01-hello-csound/Tests/HelloCsoundTests/CsoundPlayerTests.swift || true

# 02 – Basic UI with Teatro: local package scaffold (generated)
rm -f tutorials/02-basic-ui-teatro/Package.swift || true
rm -rf tutorials/02-basic-ui-teatro/Sources || true
rm -rf tutorials/02-basic-ui-teatro/Tests || true

echo "Clean complete."

