#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"; shift || true

usage() {
  cat <<USAGE
Usage:
  ./run.sh setup [--local|--upstream] [--profile ai]   # scaffold
  ./run.sh build                                       # build
  ./run.sh run                                         # run
  ./run.sh test                                        # test
  ./run.sh open                                        # open in Xcode (macOS)
  ./run.sh clean                                       # remove local caches

Notes:
  To call a live gateway, export env vars before 'run':
    export FOUNTAIN_AI_KEY=YOUR_API_KEY
    export LLM_GATEWAY_URL=http://localhost:8080/api/v1
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

