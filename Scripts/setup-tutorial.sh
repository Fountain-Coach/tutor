#!/usr/bin/env bash
set -euo pipefail

# setup-tutorial.sh — scaffold a minimal local Swift package for a tutorial
# Usage: Scripts/setup-tutorial.sh <AppName> [BundleID]
# Notes:
# - This script intentionally does NOT build the upstream monorepo.
# - It creates a tiny SPM executable target in the current directory using
#   a single-file layout (main.swift in this folder) for simplicity.

APP_NAME="${1:-}"
if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $(basename "$0") <AppName> [BundleID]" >&2
  exit 2
fi

TARGET_DIR="$(pwd)"
PKG_FILE="$TARGET_DIR/Package.swift"
MAIN_FILE="$TARGET_DIR/main.swift"

cat > "$PKG_FILE" <<EOF
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "$APP_NAME",
    platforms: [ .macOS(.v14) ],
    products: [
        .executable(name: "$APP_NAME", targets: ["$APP_NAME"])
    ],
    targets: [
        .executableTarget(
            name: "$APP_NAME",
            path: ".",
            sources: ["main.swift"]
        )
    ]
)
EOF

if [[ ! -f "$MAIN_FILE" ]]; then
  cat > "$MAIN_FILE" <<'SWIFT'
import Foundation

print("Hello, FountainAI!")
SWIFT
fi

echo "Generated Package.swift and main.swift for $APP_NAME in $TARGET_DIR"
