#!/usr/bin/env bash
set -euo pipefail

# setup-tutorial.sh — scaffold a minimal local Swift package for a tutorial
#
# Usage:
#   Scripts/setup-tutorial.sh <AppName> [BundleID] [--local|--upstream]
#   SETUP_MODE=upstream Scripts/setup-tutorial.sh <AppName> [BundleID]
#
# Notes:
# - Local mode (default) creates a tiny SPM executable with main.swift in this folder.
# - Upstream mode tries to invoke the FountainAI monorepo's scaffolder, then
#   copies the generated main.swift here. If it fails, we fall back to local.

APP_NAME=""
BUNDLE_ID=""
MODE="${SETUP_MODE:-local}"  # local | upstream

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --upstream)
      MODE="upstream"; shift ;;
    --local)
      MODE="local"; shift ;;
    --bundle-id)
      BUNDLE_ID="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: $(basename "$0") <AppName> [BundleID] [--local|--upstream]"; exit 0 ;;
    *)
      if [[ -z "$APP_NAME" ]]; then APP_NAME="$1";
      elif [[ -z "$BUNDLE_ID" ]]; then BUNDLE_ID="$1";
      fi
      shift ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $(basename "$0") <AppName> [BundleID] [--local|--upstream]" >&2
  exit 2
fi

TARGET_DIR="$(pwd)"
PKG_FILE="$TARGET_DIR/Package.swift"
MAIN_FILE="$TARGET_DIR/main.swift"

generate_local() {
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
            sources: ["main.swift", "Greeter.swift"]
        ),
        .testTarget(
            name: "${APP_NAME}Tests",
            dependencies: ["$APP_NAME"],
            path: "Tests/${APP_NAME}Tests"
        )
    ]
)
EOF

  # Always ensure a Greeter for tests; harmless if unused by main
  cat > "$TARGET_DIR/Greeter.swift" <<'SWIFT'
import Foundation

public func greet() -> String {
    return "Hello, FountainAI!"
}
SWIFT

  if [[ ! -f "$MAIN_FILE" ]]; then
    cat > "$MAIN_FILE" <<'SWIFT'
import Foundation

print(greet())
SWIFT
  fi
  mkdir -p "$TARGET_DIR/Tests/${APP_NAME}Tests"
  cat > "$TARGET_DIR/Tests/${APP_NAME}Tests/${APP_NAME}Tests.swift" <<EOF
import XCTest
@testable import $APP_NAME

final class ${APP_NAME}Tests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
EOF
  echo "Generated Package.swift and main.swift for $APP_NAME in $TARGET_DIR (local mode)"
}

attempt_upstream() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local repodir="$tmpdir/the-fountainai"
  cleanup() { rm -rf "$tmpdir"; }
  echo "Fetching FountainAI monorepo…"
  git clone --depth 1 https://github.com/Fountain-Coach/the-fountainai.git "$repodir" >/dev/null
  echo "Building scaffold-cli (Swift) black-box…"
  ( cd "$(dirname "$0")/../tools/scaffold-cli" && \
    export CLANG_MODULE_CACHE_PATH="$PWD/.modulecache" && \
    mkdir -p "$CLANG_MODULE_CACHE_PATH" && \
    swift build -c release >/dev/null )
  local cli="$(cd "$(dirname "$0")/../tools/scaffold-cli" && pwd)/.build/release/scaffold-cli"
  if [[ ! -x "$cli" ]]; then
    echo "Failed to build scaffold-cli. Falling back to local minimal package." >&2
    cleanup; return 1
  fi
  echo "Scaffolding via scaffold-cli…"
  if ! "$cli" --repo "$repodir" --app "$APP_NAME" ${BUNDLE_ID:+--bundle-id "$BUNDLE_ID"}; then
    echo "scaffold-cli failed. Falling back to local minimal package." >&2
    cleanup; return 1
  fi
  if [[ -f "$repodir/apps/$APP_NAME/main.swift" ]]; then
    cp "$repodir/apps/$APP_NAME/main.swift" "$MAIN_FILE"
    echo "Copied generated main.swift from upstream scaffold."
  fi
  # Always use local minimal Package.swift for portability in this tutorial repo
  generate_local
  echo "Prepared local package using scaffolded main.swift."
  cleanup
}

if [[ "$MODE" == "upstream" ]]; then
  if ! attempt_upstream; then
    generate_local
  fi
else
  generate_local
fi
