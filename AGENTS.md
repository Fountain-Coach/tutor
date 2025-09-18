# Repository Guidelines

## Current Layout
- `README.md` hosts the Tutor Path overview at the repository root.
- `docs/tutor/README.md` keeps the breadcrumb back to the root guide while the module chapters stay in `docs/tutor/modules/`.
- Shared snippets for the module content live in `docs/tutor/_includes/` (`env.md`, `testing-checklists.md`, `repo-links.md`).
- Keep this arrangement stable: add new reference material under `docs/`, and reserve the root for high-signal entry points like the Tutor Path, this guide, and licensing files.

## Tutor Path Modules
- **Module 01 — Spec Literacy & Health**: enumerate documented services, query `/v1/health` and `/v1/capabilities`, and surface missing capabilities with guidance.
- **Module 02 — Corpus Bootstrap**: create corpora through the bootstrap API, seed baselines, and verify persistence through Awareness.
- **Module 03 — Awareness: Baselines, Drift, Reflections**: manage baseline versions, visualize drift/patterns, and maintain reflections timelines.
- **Module 04 — Planner + LLM Gateway Loop**: collect ordered planner steps then execute them via Function Caller with corpus context.
- **Module 05 — Tools Factory → Function Caller**: register OpenAPI operations as tools, invoke them, and persist invocation results in the corpus.
- **Module 06 — Teatro GUI: Spec-Only Integration**: render a GUI that only consumes documented HTTP APIs; no internal shortcuts.
- **Module 07 — Observability & Guards**: expose gateway limits, destructive-operation guards, and related metrics in the UI.
- **Module 08 — Reasoning Streams (Optional, MIDI2)**: stream planner/awareness events (SSE-over-MIDI) with transport controls for transparency.

### Module Maintenance Guidelines
- Preserve the shared outline in each module: **Outcome**, **What you’ll ship**, **Specs to read**, **Behavioral acceptance**, **Test plan**, **Runbook**, **Hand-off to Codex**.
- When new capabilities arrive, update the relevant module(s) and cross-link any supporting deep dives in `docs/`.
- Keep spec references current; remove deprecated endpoints and replace them with the documented equivalents.
- Acceptance checklists use `- [ ]` syntax—update them when altering scope and mirror those changes in tests.

## Documentation Workflow
- Update the root `README.md` whenever the Tutor Path sequence or shared resources change so contributors onboard via a single canonical entry point.
- Link into module chapters with relative paths (e.g. `docs/tutor/modules/01-spec-literacy-and-health.md`). Avoid hard-coded URLs; everything should work when browsing locally.
- When editing module content, reuse snippets from `_includes/` instead of duplicating environment or testing instructions.
- If you relocate docs, leave breadcrumbs (as in `docs/tutor/README.md`) so existing links degrade gracefully.

## Tutorial Scaffolding (When Present)
- Tutorials belong in `tutorials/` using numbered, kebab-case folders: `tutorials/NN-title/` (e.g. `tutorials/06-screenplay-editor-capstone/`).
- Each tutorial should provide a `README.md`, runnable sample code, assets (`MainScene.teatro`, `NoteStore.swift`, `CuePlayer.ts`, MIDI files), and a test target.
- Deep-dive articles or cross-cutting guides continue to live in `docs/` alongside the Tutor Path material.

## Build, Test, and Development Commands
- From inside a tutorial folder:
  - `./setup.sh` scaffolds the default SwiftPM app.
  - `./setup.sh --upstream` pulls the upstream Swift scaffolder wired to FountainAI.
  - `./setup.sh --profile <name>` adds FountainAI client libraries (`basic`, `ai`, `persist`, `midi2`, `capstone`, `full-client`).
  - After scaffolding, prefer the Tutor CLI (`tutor build`, `tutor run`, `tutor test`). Install it once via `Scripts/install-tutor.sh`.
- CI runs `.github/workflows/swift-ci.yml`, which exercises setup, build, and tests for every tutorial.

## Coding Style & Naming Conventions
- Swift: 4-space indent, types in `PascalCase`, members `lowerCamelCase`, one primary type per file, suffixes like `Store`, `Client`.
- TypeScript: 2-space indent, ES module imports, classes in `PascalCase`.
- Teatro DSL: scene files `PascalCase` (`MainScene.teatro`); events `kebab-case` (`save-note`).
- Markdown: Title Case headings, relative links, short paragraphs, fenced code blocks with language hints.

## Testing Guidelines
- Every tutorial must ship with tests. Keep logic small and testable via SwiftPM test targets or lightweight TS test runners (Vitest/Jest).
- Use behavior-driven assertions; aim for >80% coverage of any new logic.
- Follow the self-correction loop: write a failing test, implement the fix/feature, rerun `swift test` (or `npm test`) until green.

## Contribution Checklist
- Conventional Commits (`docs:`, `feat:`, `fix:`, `chore:`) keep history readable.
- PRs should document purpose, key changes, affected tutorial paths, linked issues, and include before/after snippets or screenshots where UI is relevant.
- Prefer branches named `codex/<topic>` or `copilot/<topic>` for tutorial updates.
- Never commit secrets; use placeholders such as `YOUR_API_KEY` and provide `.env.example` files when configuration is required.
- Leave large binaries untouched unless an asset update is explicitly requested.
