#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"; shift || true

usage() {
  cat <<USAGE
Usage:
  ./run.sh setup [--local|--upstream] [--profile <ai|midi2>]  # scaffold
  ./run.sh build                                              # build (Swift package structure)
  ./run.sh run                                                # run (console placeholder)
  ./run.sh test                                               # test
  ./run.sh open                                               # open in Xcode
  ./run.sh clean                                              # remove local caches
USAGE
}

clean_local() { rm -rf .build .modulecache .swift-module-cache .swiftpm .tutor || true; }

case "${cmd}" in
  setup) ./setup.sh "$@" ;;
  build) tutor build --dir . "$@" ;;
  run)   tutor run   --dir . "$@" ;;
  test)  tutor test  --dir . "$@" ;;
  open)  command -v xed >/dev/null && xed . || echo "Open this folder in your editor." ;;
  clean) clean_local ;;
  -h|--help|help|"") usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 2 ;;
esac

