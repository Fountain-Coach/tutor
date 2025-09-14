# FountainAI Tutorial Series

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally using the Swift-powered `tutor-cli` (no Xcode required).

[![Swift Tutorials CI](https://github.com/Fountain-Coach/tutor/actions/workflows/swift-ci.yml/badge.svg)](https://github.com/Fountain-Coach/tutor/actions/workflows/swift-ci.yml)

This repository hosts the tutorial content for FountainAI. Each lesson scaffolds a minimal Swift Package app via `setup.sh`, which wraps scripts from the upstream [FountainAI monorepo](https://github.com/Fountain-Coach/the-fountainai). Tutorials focus on learning the workflow and core concepts, not running the full platform services.

## Big Picture: FountainAI (upstream)
- OpenAPI-first contracts in `openapi/` define personas and policies (gateway, auth, rate limit, security, persistence).
- Core services in `services/`: `GatewayServer` (request pipeline) and `PersistServer` (FountainStore).
- App tooling in `Scripts/`: `new-gui-app.sh <Name>` scaffolds `apps/<Name>`; `make_app.sh <Name>` bundles a `.app` on macOS.
- These tutorials copy the generated `main.swift` and `Package.swift` locally for a minimal SPM experience.

Primers and deep dives
- Shells and Git (zsh PATH, Git basics): docs/shells-and-git.md
- Tutor CLI (install and usage): docs/tutor-cli.md
- Dependency management (profiles, SwiftPM): docs/dependency-management-deep-dive.md

## Getting Started

1. Clone this repo.
2. Change into a tutorial: `cd tutorials/01-hello-fountainai`
3. Make the script executable if needed: `chmod +x setup.sh`
4. Scaffold the app: `./setup.sh`
5. Install the CLI (one time): `Scripts/install-tutor.sh` (installs to `~/.local/bin/tutor`). Or build then self-install: `cd tools/tutor-cli && swift build -c release && .build/release/tutor install`.
6. Build and run the app from the tutorial folder:
   - `tutor build`
   - `tutor run`
   - Tail: `tutor tail` (streams live status/events in the terminal)
   - Snapshot: `tutor log` (prints a snapshot; writes `.tutor/doctor.json`)

More on the CLI: see docs/tutor-cli.md. Use `tutor --help` anytime.

Expected: the app prints a greeting in the terminal. Open the project in Xcode with `xed .` if you prefer a GUI.

## What You Can Do

- Use `tutorials/<name>/setup.sh` to generate a minimal app per lesson.
- Build with `swift build` and run with `swift run`.
- Read each tutorial’s README to connect UI events, persistence, MIDI, and AI.

## Full Stack Option

- To explore the full platform, clone the upstream monorepo and run/build services there.
- On macOS, bundle GUI targets with `Scripts/make_app.sh <Name>` and launch `dist/<Name>.app`.

### Viewer Deprecated

- The native viewer is deprecated. Prefer terminal-first workflow with `tutor tail` and `tutor log`.

## Prerequisites

- Swift 6.1+ toolchain (macOS 14+ recommended)
- Optional: `OPENAI_API_KEY` for AI features
- Basic familiarity with Swift and SwiftUI
- Shells and Git: see docs/shells-and-git.md (zsh PATH, Git basics)

## First-time Setup Checklist

- Verify Swift: `swift --version` (requires Swift 6.1+ on macOS 14+).
- Install Tutor CLI: `Scripts/install-tutor.sh` (installs `tutor` to `~/.local/bin`).
- Add to PATH (zsh): `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc`.
- Confirm install: `which tutor` and `tutor --help`.
- Choose a tutorial (e.g., `cd tutorials/01-hello-fountainai`) and scaffold: `./setup.sh --upstream`.
- Build/Run/Test: `tutor build`, `tutor run`, `tutor test`.

## Troubleshooting

- tutor: command not found
  - Ensure `~/.local/bin` is on PATH (zsh): `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc`, then reopen the terminal.
- Swift toolchain issues
  - Install Xcode + Command Line Tools; accept license: `xcode-select -p`, `xcodebuild -runFirstLaunch`.
  - Verify: `swift --version` shows 6.1+.
- Network/clone failures during `./setup.sh --upstream`
  - Check connectivity, VPN/proxy, and retry. The script resumes from a clean temp dir.
- Gateway/API errors at runtime
  - Set env vars before `tutor run`: `export LLM_GATEWAY_URL=http://localhost:8080/api/v1` and optionally `export FOUNTAIN_AI_KEY=sk-...`.
- Permission denied on scripts
  - Mark executable: `chmod +x setup.sh`.

## Tutorials

- [01 – Hello FountainAI](tutorials/01-hello-fountainai/README.md)
- [02 – Basic UI with Teatro](tutorials/02-basic-ui-teatro/README.md)
- [03 – Data Persistence with FountainStore](tutorials/03-data-persistence-fountainstore/README.md)
- [04 – Multimedia with MIDI2](tutorials/04-multimedia-midi2/README.md)
- [05 – AI Integration with OpenAPI](tutorials/05-ai-integration-openapi/README.md)
- [06 – Screenplay Editor Capstone](tutorials/06-screenplay-editor-capstone/README.md)
## Profiles (Optional)

Use `--profile <name>` to include client libraries from the upstream FountainAI package:

- `basic` (default): minimal app scaffold
- `ai`: + `FountainAICore`, `FountainAIAdapters`, `LLMGatewayAPI`
- `persist`: + `PersistAPI`, `FountainStoreClient` (plus core/adapters)
- `midi2`: + `MIDI2Models`, `MIDI2Core`, `SSEOverMIDI`, `FlexBridge`
- `capstone`: union of `ai` + `persist` + `midi2`
- `full-client`: all client APIs (`GatewayAPI`, `LLMGatewayAPI`, `PersistAPI`, `SemanticBrowserAPI`) plus core/adapters

Examples:
- `./setup.sh --upstream --profile ai`
- `./setup.sh --profile persist`
- `./setup.sh --upstream --profile full-client`

CLI equivalents (from a tutorial folder):
- `tutor build`
- `tutor run`
- `tutor test`

Profile quick map:

| Profile      | Modules |
|--------------|---------|
| `basic`      | (none) |
| `ai`         | `FountainAICore`, `FountainAIAdapters`, `LLMGatewayAPI` |
| `persist`    | `PersistAPI`, `FountainStoreClient` (+ core/adapters) |
| `midi2`      | `MIDI2Models`, `MIDI2Core`, `SSEOverMIDI`, `FlexBridge` |
| `capstone`   | union of `ai` + `persist` + `midi2` |
| `full-client`| `GatewayAPI`, `LLMGatewayAPI`, `PersistAPI`, `SemanticBrowserAPI` (+ core/adapters) |
