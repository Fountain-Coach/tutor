#!/usr/bin/env bash
set -euo pipefail
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$PWD/.modulecache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH" "$PWD/.swift-module-cache"
swift build --disable-sandbox \
  -Xcc -fmodules-cache-path="$CLANG_MODULE_CACHE_PATH" \
  -Xswiftc -module-cache-path -Xswiftc "$PWD/.swift-module-cache" "$@"
