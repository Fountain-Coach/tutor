#!/usr/bin/env bash
set -euo pipefail

# Run the FountainAI Gateway from source (no Docker)
#
# Subcommands:
#   start      Clone (if needed), build, run in background, and health‑check
#   stop       Stop background Gateway process
#   status     Print process and health status
#   logs       Tail the Gateway log (ctrl‑c to exit)
#
# Options (for start):
#   --repo <path>     Path to an existing the-fountainai checkout (default: tools/_deps/the-fountainai)
#   --branch <name>   Branch to clone (default: main)
#   --port <n>        Port to bind (default: 8080)
#   --no-auth         Disable auth in dev (Gateway flag)
#   --dev             Enable dev mode (Gateway flag)
#   --foreground      Run in foreground (no background, no pid file)
#   --timeout <sec>   Health wait timeout (default: 30)
#
# Environment exported on success:
#   LLM_GATEWAY_URL   http://127.0.0.1:<port>/api/v1
#   FOUNTAIN_AI_KEY   local-dev-key (only meaningful when --no-auth is NOT used)
#
# Examples:
#   Scripts/run-gateway-source.sh start --dev --no-auth --port 8080
#   Scripts/run-gateway-source.sh status
#   Scripts/run-gateway-source.sh logs
#   Scripts/run-gateway-source.sh stop

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TUTOR_DIR="$ROOT_DIR/.tutor"
mkdir -p "$TUTOR_DIR"
PID_FILE="$TUTOR_DIR/gateway.pid"
LOG_FILE="$TUTOR_DIR/gateway.log"
PORT=8080
REPO_DEFAULT="$ROOT_DIR/tools/_deps/the-fountainai"
REPO="$REPO_DEFAULT"
BRANCH="main"
NO_AUTH=0
DEV_MODE=0
FOREGROUND=0
TIMEOUT=30

cmd="${1:-start}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --port) PORT="${2:-8080}"; shift 2 ;;
    --no-auth) NO_AUTH=1; shift ;;
    --dev) DEV_MODE=1; shift ;;
    --foreground) FOREGROUND=1; shift ;;
    --timeout) TIMEOUT="${2:-30}"; shift 2 ;;
    -h|--help|help) cmd="help"; shift || true ;;
    *) break ;;
  esac
done

usage() {
  sed -n '1,80p' "$0" | sed -n '1,60p'
}

run_health() {
  local url="http://127.0.0.1:${PORT}/health"
  curl -fsS "$url" >/dev/null 2>&1
}

cmd_help() { usage; }

cmd_status() {
  if [[ -f "$PID_FILE" ]]; then
    local pid; pid="$(cat "$PID_FILE" || true)"
    if [[ -n "${pid:-}" && -e "/proc/$pid" ]] || ps -p "$pid" >/dev/null 2>&1; then
      echo "Gateway PID: $pid (running)"
    else
      echo "Gateway PID file present but process not running"
    fi
  else
    echo "Gateway not started (no pid file)"
  fi
  if run_health; then echo "Health: OK"; else echo "Health: unavailable"; fi
  echo "Log: $LOG_FILE"
}

cmd_logs() {
  echo "Tailing $LOG_FILE (ctrl-c to stop)…"
  touch "$LOG_FILE" && tail -f "$LOG_FILE"
}

cmd_stop() {
  if [[ ! -f "$PID_FILE" ]]; then echo "No pid file ($PID_FILE)"; exit 0; fi
  local pid; pid="$(cat "$PID_FILE" || true)"
  if [[ -z "${pid:-}" ]]; then echo "Empty pid file"; rm -f "$PID_FILE"; exit 0; fi
  if kill "$pid" >/dev/null 2>&1; then
    echo "Stopped process $pid"
    rm -f "$PID_FILE"
  else
    echo "Process $pid not running"
    rm -f "$PID_FILE"
  fi
}

cmd_start() {
  # Clone if missing
  if [[ ! -d "$REPO/.git" ]]; then
    echo "Cloning the-fountainai into $REPO (branch: $BRANCH)…"
    mkdir -p "$(dirname "$REPO")"
    git clone --branch "$BRANCH" https://github.com/Fountain-Coach/the-fountainai.git "$REPO"
  else
    echo "Using existing repo at $REPO"
  fi

  # Build GatewayServer
  echo "Building GatewayServer…"
  pushd "$REPO/services/GatewayServer" >/dev/null
  swift build

  # Compose run flags
  local args=("run" "GatewayServer" "--port" "$PORT")
  (( DEV_MODE == 1 )) && args+=("--dev")
  (( NO_AUTH == 1 )) && args+=("--no-auth")

  echo "Starting Gateway on :$PORT…"
  if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo "[warn] OPENAI_API_KEY is not set. The Gateway will start, but LLM-backed endpoints will fail until a provider key is configured." >&2
    echo "       Export OPENAI_API_KEY in your shell before 'start' to pass it through to the Gateway process." >&2
  else
    echo "Provider credentials detected: OPENAI_API_KEY is set (will be inherited by the Gateway process)."
  fi
  if (( FOREGROUND == 1 )); then
    echo "(foreground) Logs will print below; ctrl-c to stop"
    swift "${args[@]}"
  else
    # background with logs + pid
    ( swift "${args[@]}" >>"$LOG_FILE" 2>&1 & echo $! >"$PID_FILE" )
    popd >/dev/null || true

    echo -n "Waiting for health"
    local deadline=$((SECONDS + TIMEOUT))
    until run_health; do
      echo -n "."; sleep 1
      if (( SECONDS >= deadline )); then
        echo; echo "Gateway failed health within ${TIMEOUT}s. See $LOG_FILE." >&2
        exit 1
      fi
    done
    echo; echo "Health OK"

    export LLM_GATEWAY_URL="http://127.0.0.1:${PORT}/api/v1"
    export FOUNTAIN_AI_KEY="local-dev-key"
    echo "Environment set for tutorials:"
    echo "  export LLM_GATEWAY_URL=$LLM_GATEWAY_URL"
    echo "  export FOUNTAIN_AI_KEY=$FOUNTAIN_AI_KEY"
    echo "Logs: $LOG_FILE | PID: $(cat "$PID_FILE")"
  fi
}

case "$cmd" in
  start) cmd_start ;;
  stop)  cmd_stop ;;
  status) cmd_status ;;
  logs)  cmd_logs ;;
  help|-h|--help|*) cmd_help ;;
esac
