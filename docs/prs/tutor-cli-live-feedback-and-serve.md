# PR: Tutor CLI — Live Feedback, Machine Outputs, Serve, and MIDI

## Purpose

Improve the Tutor CLI for both humans and LLM/agent use by adding live progress reporting, machine‑readable outputs, a local server with SSE, and MIDI mirroring using the existing FountainAI stack.

## Key Changes

- Live progress with phases and percent, plus elapsed time.
- Machine outputs during build/run/test:
  - `.tutor/status.json` (current phase/status/elapsed/final code)
  - `.tutor/events.ndjson` (NDJSON of logs, phases, warnings, errors)
- JSON summary:
  - `--json-summary` prints structured summary (category, hint, counts, lists)
  - `/summary` endpoint returns the same payload
- Error taxonomy + hints: DEPENDENCY_NETWORK, RESOLVE_GRAPH, COMPILE, LINK, TEST, RUNTIME, UNKNOWN
- Serve command (HTTP + SSE): `/health`, `/status`, `/events`, `/summary`
  - Auth token by default; `--dev` disables auth
  - `--socket <path>` Unix domain socket SSE (no HTTP headers) for sandboxed envs
- MIDI mirroring via FountainAI `SSEOverMIDI` (preferred), CoreMIDI as fallback
- CI annotations: `--ci` emits `::error`/`::warning` on parsed diagnostics

## Affected Paths

- `tools/tutor-cli/Sources/TutorCLI/main.swift`
- `tools/tutor-cli/Package.swift`
- `docs/tutor-cli.md`, `docs/tutor-cli-roadmap.md`
- `docs/examples/sse_http_client.swift`
- `.github/workflows/tutor-ci-example.yml`
- Tests: `tools/tutor-cli/Tests/TutorCLITests/*`

## Usage Examples

- Human: `tutor build` (status line with percent), `tutor test --verbose`
- Machine: `tutor build --quiet --json-summary`
- Serve:
  - `tutor serve --dir tutorials/01-hello-fountainai --port 0 --dev`
  - `curl http://127.0.0.1:<port>/status`, `/summary`, or subscribe to `/events`
  - Unix socket: `tutor serve --socket /tmp/tutor.sse --dev` and connect with `socat` or provided clients
- MIDI: `tutor test --midi --midi-virtual-name "TutorCLI-Status"`
- CI: `tutor build --ci --quiet --json-summary`

## Tests

- Unit tests for arg parsing, JSON IO, failure categorization, and summary aggregation
- Opt‑in integration tests for the server (`TUTOR_INTEGRATION=1 swift test`)

## Notes

- The CLI links the FountainAI `SSEOverMIDI` product from a local checkout (`tools/_deps/the-fountainai`) when present; otherwise CoreMIDI SysEx fallback is used.
- Docs include Swift and Python clients for SSE over Unix sockets, and a Swift HTTP SSE client for `/events`.

