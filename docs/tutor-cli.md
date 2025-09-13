# Tutor CLI

A small Swift command-line tool to scaffold, build, run, and test tutorials without Xcode.

## Install

- One‑time install to `~/.local/bin/tutor`:
  - `Scripts/install-tutor.sh`
- Ensure `~/.local/bin` is on your PATH:
  - `export PATH=$HOME/.local/bin:$PATH`
  - Add permanently (zsh): `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc`

Or install via the CLI itself (after building it once):

- `cd tools/tutor-cli && swift build -c release && .build/release/tutor install`

## Usage

- From any tutorial folder:
  - Build: `tutor build`
  - Run: `tutor run`
  - Test: `tutor test`
- Help:
  - `tutor --help`
  - `tutor help`
- Options:
  - `--dir <path>` to target a different folder
  - `--verbose` or `-v` to print SwiftPM verbose output
  - `--no-progress` to disable the live status line
  - `--quiet` to suppress Swift output and show only status
  - `--json-summary` to emit a final JSON summary to stdout (pair with `--quiet` for machine use)
  - `--midi` to emit events as MIDI SysEx on a virtual source (macOS)
  - `--midi-virtual-name <name>` to name the virtual MIDI source (default `TutorCLI`)
  - Auto-parallelism: if `--jobs/-j` is not provided, uses CPU cores
  - `--` to pass flags to underlying `swift` (e.g., `-- -c release`)

## Status & Machine Readability

- Live status files are written to `<tutorial>/.tutor/` during `build`, `run`, or `test`:
  - `status.json` — current phase, status, elapsed, and final exit code; safe to poll.
  - `events.ndjson` — newline‑delimited JSON event stream (log, phase changes, warnings, errors).
- Query status at any time:
  - Human: `tutor status --dir <tutorial>`
  - JSON: `tutor status --dir <tutorial> --json`
  - Watch: `tutor status --dir <tutorial> --watch`
- Control files:
  - `--no-status-file` to skip writing `status.json`
  - `--status-file <path>` and `--event-file <path>` to override defaults

## MIDI Output (Experimental)

- macOS only: the CLI can expose a virtual MIDI source and send each event as a compact SysEx message (manufacturer ID 0x7D), compatible with FountainAI's `SSEOverMIDI`.
- Enable: `tutor build --midi` (or with any subcommand).
- Connect your DAW or MIDI monitor to the virtual port (default `TutorCLI`).
- Customize name: `--midi-virtual-name "TutorCLI-Status"`.
- Payload: a truncated JSON blob inside SysEx for status, warnings, errors, and final summary.
 - Internals: when the FountainAI package is present, the CLI links `SSEOverMIDI`; otherwise it falls back to a CoreMIDI shim that emits the same wire format.

## Error Taxonomy & Hints

- On failure, the CLI classifies errors and provides concise hints.
- Categories: `DEPENDENCY_NETWORK`, `RESOLVE_GRAPH`, `COMPILE`, `LINK`, `TEST`, `RUNTIME`, `UNKNOWN`.
- Get a one‑shot machine summary:
  - `tutor build --json-summary --quiet`
  - Output includes `category`, `hint`, counts, and first errors/warnings.

## Live Status Feedback

- The CLI shows a live status line with spinner and elapsed time.
- Phases include: resolving, fetching/updating, compiling, linking, testing, and running.
- Use `--verbose` to see detailed SwiftPM lines while the status updates.

## Scaffold (advanced)

- Scaffold an app target inside a cloned FountainAI monorepo (used by `setup.sh --upstream`):
  - `tutor scaffold --repo /path/to/the-fountainai --app HelloFountainAI`

## Environment

- Builds set local caches to avoid macOS permission issues:
  - `.modulecache/` and `.swift-module-cache/` in the tutorial folder
- AI UI uses env vars:
  - `LLM_GATEWAY_URL` (default `http://localhost:8080/api/v1`)
  - `FOUNTAIN_AI_KEY` (optional bearer token)

## Notes

- The CLI is preferred. Profiles in `setup.sh` still control which FountainAI products your app depends on.
- See also: `docs/dependency-management-deep-dive.md` for profiles and SwiftPM behavior.
- Roadmap: `docs/tutor-cli-roadmap.md` tracks ongoing improvements.
