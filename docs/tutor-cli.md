# Tutor CLI

A small Swift command-line tool to scaffold, build, run, and test tutorials without Xcode.

## Install

- One‑time install to `~/.local/bin/tutor`:
  - `Scripts/install-tutor.sh`
- Ensure `~/.local/bin` is on your PATH:
  - `export PATH=$HOME/.local/bin:$PATH`

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
  - `--` to pass flags to underlying `swift` (e.g., `-- -c release`)

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
