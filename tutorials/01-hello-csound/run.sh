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
#   ./run.sh ai-csd "Return a complete Csound .csd …"  # writes Sources/HelloCsound/hello.csd
#   ./run.sh ai-csd-hear "…"                           # fetch + play (macOS)

cmd="${1:-}"
shift || true

run() {
  # Ensure we’re in this tutorial folder
  tutor run --dir . "$@"
}

have_lily() { command -v lilypond >/dev/null 2>&1; }

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
    CS_MOTIF=1 LY_EXPORT=1 run
    if have_lily; then
      echo "Engrave with: lilypond motif.ly"; [[ "$duo" == 1 ]] && echo "Engrave duo with: lilypond motif_duo.ly"
    else
      echo "LilyPond not installed — wrote copy-ready .ly (motif.ly$([[ "$duo" == 1 ]] && echo ", motif_duo.ly"))."
      echo "Install LilyPond to engrave PDFs later."
    fi ;;

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
    TRIAD_QUALITY="$quality" CS_TRIAD=1 LY_EXPORT=1 run
    if have_lily; then
      echo "Engrave with: lilypond triad.ly"
    else
      echo "LilyPond not installed — wrote copy-ready triad.ly. Install LilyPond to engrave a PDF."
    fi ;;

  status)
    echo "Lesson: 01 – Hello Csound"
    swift --version || true
    if have_lily; then
      echo "LilyPond: installed"
    else
      echo "LilyPond: missing — exports write copy-ready .ly files (engrave later)."
    fi
    exit 0 ;;

  ai-csd)
    prompt="${1:-}"; shift || true
    if [[ -z "${prompt}" ]]; then echo "Provide a prompt in quotes." >&2; exit 2; fi
    if [[ -z "${LLM_GATEWAY_URL:-}" ]]; then echo "Set LLM_GATEWAY_URL (e.g., http://localhost:8080/api/v1)" >&2; exit 2; fi
    # Quick health check before requesting content
    if ! curl -fsS "${LLM_GATEWAY_URL%/}/health" >/dev/null 2>&1; then
      echo "Gateway health check failed at ${LLM_GATEWAY_URL%/}/health" >&2
      echo "Tip: Run 'Scripts/run-gateway-source.sh start --dev --no-auth' from repo root and ensure OPENAI_API_KEY is set." >&2
      exit 1
    fi
    body=$(jq -n --arg p "$prompt" '{model:"fountain-medium", messages:[{role:"user", content:$p}]}')
    curl -sS "$LLM_GATEWAY_URL/generate" \
      -H "Authorization: Bearer ${FOUNTAIN_AI_KEY:-}" \
      -H "Content-Type: application/json" \
      -d "$body" \
      | jq -r '.content // .choices[0].message.content' \
      > Sources/HelloCsound/hello.csd
    echo "Wrote Sources/HelloCsound/hello.csd" ;;

  ai-csd-hear)
    prompt="${1:-}"; shift || true
    "$0" ai-csd "$prompt"
    "$0" hear ;;

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
  ./run.sh status                    # check tools and next steps
  ./run.sh ai-csd "Return a complete Csound .csd …"    # fetch .csd via local Gateway
  ./run.sh ai-csd-hear "…"                              # fetch + play
USAGE
    exit 2 ;;
esac
