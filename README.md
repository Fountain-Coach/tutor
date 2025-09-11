# FountainAI Tutorial Series

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally to explore the concept.

This repository hosts the tutorial content for FountainAI. Each lesson scaffolds a minimal Swift Package app via `setup.sh`, which wraps scripts from the upstream [FountainAI monorepo](https://github.com/Fountain-Coach/the-fountainai). Tutorials focus on learning the workflow and core concepts, not running the full platform services.

## Big Picture: FountainAI (upstream)
- OpenAPI-first contracts in `openapi/` define personas and policies (gateway, auth, rate limit, security, persistence).
- Core services in `services/`: `GatewayServer` (request pipeline) and `PersistServer` (FountainStore).
- App tooling in `Scripts/`: `new-gui-app.sh <Name>` scaffolds `apps/<Name>`; `make_app.sh <Name>` bundles a `.app` on macOS.
- These tutorials copy the generated `main.swift` and `Package.swift` locally for a minimal SPM experience.

## Getting Started

1. Clone this repo.
2. Change into a tutorial: `cd tutorials/01-hello-fountainai`
3. Make the script executable if needed: `chmod +x setup.sh`
4. Scaffold the app: `./setup.sh`
5. Build and run: `swift build && swift run`

Expected: the app prints a greeting in the terminal. Open the project in Xcode with `xed .` if you prefer a GUI.

## What You Can Do

- Use `tutorials/<name>/setup.sh` to generate a minimal app per lesson.
- Build with `swift build` and run with `swift run`.
- Read each tutorial’s README to connect UI events, persistence, MIDI, and AI.

## Full Stack Option

- To explore the full platform, clone the upstream monorepo and run/build services there.
- On macOS, bundle GUI targets with `Scripts/make_app.sh <Name>` and launch `dist/<Name>.app`.

## Prerequisites

- Swift 6.1+ toolchain (macOS 14+ recommended)
- Optional: `OPENAI_API_KEY` for AI features
- Basic familiarity with Swift and SwiftUI

## Tutorials

- [01 – Hello FountainAI](tutorials/01-hello-fountainai/README.md)
- [02 – Basic UI with Teatro](tutorials/02-basic-ui-teatro/README.md)
- [03 – Data Persistence with FountainStore](tutorials/03-data-persistence-fountainstore/README.md)
- [04 – Multimedia with MIDI2](tutorials/04-multimedia-midi2/README.md)
- [05 – AI Integration with OpenAPI](tutorials/05-ai-integration-openapi/README.md)
- [06 – Screenplay Editor Capstone](tutorials/06-screenplay-editor-capstone/README.md)
