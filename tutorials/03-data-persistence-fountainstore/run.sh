#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"; shift || true

usage() {
  cat <<USAGE
Usage:
  ./run.sh build                 # build this lesson
  ./run.sh run                   # run this lesson
  ./run.sh test                  # test this lesson
  ./run.sh open                  # open in Xcode (macOS)
  ./run.sh clean                 # remove local caches
USAGE
}

clean_local() { rm -rf .build .modulecache .swift-module-cache .swiftpm .tutor || true; }

case "${cmd}" in
  build) tutor build --dir . "$@" ;;
  run)   tutor run   --dir . "$@" ;;
  test)  tutor test  --dir . "$@" ;;
  open)  command -v xed >/dev/null && xed . || echo "Open this folder in your editor." ;;
  clean) clean_local ;;
  -h|--help|help|"") usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 2 ;;
esac

