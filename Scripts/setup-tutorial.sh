#!/usr/bin/env bash
set -euo pipefail

# setup-tutorial.sh — scaffold tutorial app files from the FountainAI repo
# Usage: Scripts/setup-tutorial.sh <AppName> [BundleID]

APP_NAME="${1:-}"
BUNDLE_ID="${2:-}"

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $(basename "$0") <AppName> [BundleID]" >&2
  exit 2
fi

TARGET_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"
REPO_DIR="$TMP_DIR/the-fountainai"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ ! -d "$REPO_DIR" ]]; then
  git clone --depth 1 https://github.com/Fountain-Coach/the-fountainai.git "$REPO_DIR" >/dev/null
fi

pushd "$REPO_DIR" >/dev/null
if [[ -n "$BUNDLE_ID" ]]; then
  Scripts/new-gui-app.sh "$APP_NAME" "$BUNDLE_ID"
else
  Scripts/new-gui-app.sh "$APP_NAME"
fi
popd >/dev/null

cp "$REPO_DIR/apps/$APP_NAME/main.swift" "$TARGET_DIR/"
cp "$REPO_DIR/Package.swift" "$TARGET_DIR/"

echo "Generated main.swift and Package.swift in $TARGET_DIR"
