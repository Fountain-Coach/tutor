# Repository Guidelines

## Project Structure & Module Organization
- Root contains `README.md`, `LICENSE`, and reference PDFs. All tutorial content lives in `tutorials/`.
- Tutorials use numbered, kebab-case folders: `tutorials/NN-title/` (e.g., `06-screenplay-editor-capstone/`).
- Each tutorial includes a `README.md` plus sample code and assets (e.g., `MainScene.teatro`, `NoteStore.swift`, `CuePlayer.ts`, MIDI files).

## Build, Test, and Development Commands
- This repo hosts guides and snippets; it is not a standalone build. Build snippets inside your local FountainAI template/app or Xcode project.
- Example (from tutorial 01; scripts live in the FountainAI monorepo):
  - `Scripts/selfcheck.sh` — verify toolchain.
  - `Scripts/new-gui-app.sh HelloFountainAI` — scaffold a SwiftUI app.
  - `Scripts/build-local.sh` — build locally.
  - `scripts/start-local.sh HelloFountainAI` — run locally.

## Coding Style & Naming Conventions
- Swift: 4-space indent; types `PascalCase`, members `lowerCamelCase`; one primary type per file; suffixes like `Store`, `Client` (e.g., `NoteStore.swift`, `AIClient.swift`).
- TypeScript: 2-space indent; ES module imports; classes `PascalCase` (e.g., `CuePlayer.ts`).
- Teatro DSL: scene files `PascalCase` (e.g., `MainScene.teatro`); event names `kebab-case` (`save-note`, `play-cue`, `ask-ai`).
- Markdown: headings in Title Case; relative links; short paragraphs; fenced code blocks with language hints.

## Testing Guidelines
- No centralized tests here. Validate snippets where they run:
  - Swift in Xcode or your FountainAI template app.
  - TypeScript with `tsc --noEmit` and a minimal harness if needed.
  - Check links in `README.md` resolve and assets are present.
- Keep snippets minimal, compilable, and referenced in the tutorial `README.md`.

## Commit & Pull Request Guidelines
- Use Conventional Commits (seen in history): `docs:`, `feat:`, `fix:`, `chore:`.
- PRs should include: purpose, key changes, affected tutorial paths, linked issues, and small before/after snippets or screenshots where UI is relevant.
- Branch naming: `codex/<topic>` or `copilot/<topic>` is preferred for tutorial edits.

## Security & Configuration Tips
- Do not commit secrets or keys. Use placeholders (e.g., `YOUR_API_KEY`) and optional `.env.example` in tutorial folders when needed.
- Keep binaries large files (PDF, media) unchanged unless explicitly updating a tutorial asset.
