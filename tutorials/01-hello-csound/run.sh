#!/usr/bin/env bash
set -euo pipefail

# Human‑friendly wrapper around common recipes for this lesson.
# Usage examples:
#   ./run.sh tone
#   ./run.sh hear
#   ./run.sh motif
#   ./run.sh motif-hear
#   ./run.sh motif-score [--tempo 90] [--duo]
#   ./run.sh triad [--quality minor]
#   ./run.sh triad-score [--quality minor] [--tempo 72]

cmd="${1:-}"
shift || true

run() {
  # Ensure we’re in this tutorial folder
  tutor run --dir . "$@"
}

case "$cmd" in
  tone|print|default|"")
    run ;;

  hear)
    CS_PLAY=1 run ;;

  motif)
    CS_MOTIF=1 run ;;

  motif-hear)
    CS_MOTIF=1 CS_PLAY=1 run ;;

  motif-score)
    tempo=""; duo=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --tempo) tempo="${2:-}"; shift 2 ;;
        --duo) duo=1; shift ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done
    if [[ -n "$tempo" ]]; then LY_TEMPO="$tempo"; export LY_TEMPO; fi
    if [[ "$duo" == 1 ]]; then LY_DUO=1; export LY_DUO; fi
    CS_MOTIF=1 LY_EXPORT=1 run ;;

  triad)
    quality="major"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --quality) quality="${2:-major}"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done
    TRIAD_QUALITY="$quality" CS_TRIAD=1 run ;;

  triad-score)
    quality="major"; tempo=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --quality) quality="${2:-major}"; shift 2 ;;
        --tempo) tempo="${2:-}"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
      esac
    done
    [[ -n "$tempo" ]] && export LY_TEMPO="$tempo"
    TRIAD_QUALITY="$quality" CS_TRIAD=1 LY_EXPORT=1 run ;;

  *)
    cat >&2 <<USAGE
Usage:
  ./run.sh tone                      # print sample count
  ./run.sh hear                      # play the tone (macOS)
  ./run.sh motif                     # 3‑note motif (printed)
  ./run.sh motif-hear                # motif and play
  ./run.sh motif-score [--tempo 90] [--duo]  # write motif.ly (and motif_duo.ly when --duo)
  ./run.sh triad [--quality minor]   # play a triad (major default)
  ./run.sh triad-score [--quality minor] [--tempo 72]  # write triad.ly
USAGE
    exit 2 ;;
esac

