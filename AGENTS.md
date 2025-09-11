# Repository Guidelines

## Project Structure & Module Organization
- Root contains `README.md`, `LICENSE`, and reference PDFs. All tutorial content lives in `tutorials/`.
- Tutorials use numbered, kebab-case folders: `tutorials/NN-title/` (e.g., `06-screenplay-editor-capstone/`).
- Each tutorial includes a `README.md` plus sample code and assets (e.g., `MainScene.teatro`, `NoteStore.swift`, `CuePlayer.ts`, MIDI files).

## Build, Test, and Development Commands
- Per tutorial folder:
  - `./setup.sh` — scaffold a minimal SwiftPM app (use `--upstream` for advanced mode).
  - `swift build` — compile the app.
  - `swift run` — run the app.
  - `swift test` — run unit tests (required).
- CI: GitHub Actions workflow (`.github/workflows/swift-ci.yml`) runs setup, build, and tests for all tutorials on PRs.

## Coding Style & Naming Conventions
- Swift: 4-space indent; types `PascalCase`, members `lowerCamelCase`; one primary type per file; suffixes like `Store`, `Client` (e.g., `NoteStore.swift`, `AIClient.swift`).
- TypeScript: 2-space indent; ES module imports; classes `PascalCase` (e.g., `CuePlayer.ts`).
- Teatro DSL: scene files `PascalCase` (e.g., `MainScene.teatro`); event names `kebab-case` (`save-note`, `play-cue`, `ask-ai`).
- Markdown: headings in Title Case; relative links; short paragraphs; fenced code blocks with language hints.

## Testing Guidelines
- Tests are mandatory. Every tutorial scaffold includes a SwiftPM test target and a minimal unit test.
- Swift (SwiftPM):
  - Run tests with `swift test` in each tutorial folder.
  - Pattern: put pure logic in small functions (e.g., `greet()` in `Greeter.swift`) and test them via `@testable import <TargetName>`.
  - Add new tests under `Tests/<TargetName>Tests/` and keep them fast and deterministic.
- TypeScript examples:
  - If adding TS code, include lightweight tests (e.g., Vitest/Jest) and run them via `npm test` in that tutorial subfolder.
- Coverage: aim for 80%+ of added logic. Prefer testing behavior over implementation details.
- Self-correction loop: write a failing test for each bug/feature, implement, then re-run `swift test` until green.

## Commit & Pull Request Guidelines
- Use Conventional Commits (seen in history): `docs:`, `feat:`, `fix:`, `chore:`.
- PRs should include: purpose, key changes, affected tutorial paths, linked issues, and small before/after snippets or screenshots where UI is relevant.
- Branch naming: `codex/<topic>` or `copilot/<topic>` is preferred for tutorial edits.

## Security & Configuration Tips
- Do not commit secrets or keys. Use placeholders (e.g., `YOUR_API_KEY`) and optional `.env.example` in tutorial folders when needed.
- Keep binaries large files (PDF, media) unchanged unless explicitly updating a tutorial asset.
