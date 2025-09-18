#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"; shift || true

usage() {
  cat <<USAGE
Usage:
  ./run.sh open            # open in Xcode (macOS)
  ./run.sh build           # build the app
  ./run.sh run             # run the app
  ./run.sh test            # run tests
  ./run.sh clean           # remove local caches
USAGE
}

clean_local() { rm -rf .build .modulecache .swift-module-cache .swiftpm .tutor || true; }

case "$cmd" in
  open)  command -v xed >/dev/null && xed . || echo "Open this folder in your editor." ;;
  build) tutor build --dir . "$@" ;;
  run)   tutor run   --dir . "$@" ;;
  test)  tutor test  --dir . "$@" ;;
  clean) clean_local ;;
  -h|--help|help|"") usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 2 ;;
esac

