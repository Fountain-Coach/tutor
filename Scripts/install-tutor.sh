#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLI_DIR="$ROOT_DIR/tools/tutor-cli"

echo "Building Tutor CLI…"
cd "$CLI_DIR"
swift build -c release

DEST_DIR="${1:-$HOME/.local/bin}"
mkdir -p "$DEST_DIR"
cp ".build/release/tutor" "$DEST_DIR/tutor"
echo "Installed: $DEST_DIR/tutor"
echo "If needed, add to PATH: export PATH=$DEST_DIR:\$PATH"

