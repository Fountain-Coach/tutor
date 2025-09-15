# Tutor Tutorials — Agent Guide

This guide is for agents working inside `tutorials/`. It summarizes how this subtree is organized, how to scaffold and validate each lesson, and what not to commit. It reflects patterns in recent commits (Conventional Commits, template‑first workflow, Tutor CLI) and the current repository structure.

## Scope
- Applies to all directories under `tutorials/` (e.g., `01-hello-csound/`, `03-data-persistence-fountainstore/`).
- Complements the repo‑root `AGENTS.md`. If instructions conflict, user prompt > root AGENTS.md > this file.

## Structure & Workflow
- One lesson per folder: `NN-title/` with `README.md`, `setup.sh`, optional source/assets.
- Template‑first: `setup.sh` generates/patches a minimal SwiftPM package locally.
- Prefer local, dependency‑free scaffolds by default; use upstream profiles when explicitly requested.

## Local vs Upstream Scaffolding
- Local (default): no network deps; builds/tests offline; may generate small simulator files.
  - Run: `./setup.sh --local` (implicit), often `--profile basic`.
- Upstream: pulls FountainAI client packages; needs network and a configured toolchain.
  - Run: `./setup.sh --upstream --profile <ai|persist|midi2|capstone|full-client>`.

## Build, Test, Run
- Use Tutor CLI from each lesson directory:
  - `tutor build`
  - `tutor test`
  - `tutor run`
- Install once from repo root: `Scripts/install-tutor.sh` then add `~/.local/bin` to `PATH`.

## Generated Files Policy
- Do not commit generated sources or caches. Keep the starter repo clean.
- Allowed to commit: `README.md`, `setup.sh`, minimal `Package.swift` when required for resources, small assets (e.g., `hello.csd`).
- Not to commit (examples):
  - `Sources/**/main.swift` and simulator stubs created by `setup.sh`.
  - `Sources/**/CsoundPlayer.swift` (01), ad‑hoc scaffolds for UI (02).
  - Build artifacts: `.build/`, `.modulecache/`, `.swift-module-cache/`, `.tutor/`, `.swiftpm/`.
- Use `Scripts/clean-tutorials.sh` to remove caches and generated sources across lessons.

## Per‑Lesson Notes
- 01 – Hello Csound
  - Bundles `hello.csd` via `Package.swift` resources.
  - `setup.sh` generates `CsoundPlayer.swift`, `main.swift`, and a sample test if missing; don’t commit them.
  - Expected run output includes a generated sample count.
- 02 – Basic UI with Teatro
  - UI‑first tutorial. Local mode prints a placeholder; open in Xcode to work with Teatro files.
  - When offline, force local basic profile: `./setup.sh --local --profile basic`.
- 03 – Data Persistence (FountainStore)
  - Local mode uses a tiny simulated `FountainStore.swift` (committed) to stay offline; expand tests here.
- 04 – Multimedia with MIDI2, 05 – OpenAPI, 06 – Capstone
  - Local mode is dependency‑free for structure and tests.
  - Use `--upstream` with the appropriate profile for full client stacks.

## Coding Style
- Swift: 4‑space indent; Types `PascalCase`, members `lowerCamelCase`; one primary type per file.
- TypeScript (if present): 2‑space indent; ES modules; classes `PascalCase`.
- Teatro DSL: scene files `PascalCase` (e.g., `MainScene.teatro`), events in `kebab-case`.
- Markdown: Title Case headings, relative links, short paragraphs, fenced code blocks.

## Testing
- Tests are mandatory per lesson. Keep them fast/deterministic.
- Pattern: put pure logic in small functions and test via `@testable import`.
- Target 80%+ coverage for new logic; prefer behavior tests over implementation details.
- Run: `tutor test` from the lesson directory.

## Git & PR Hygiene
- Follow Conventional Commits (`docs:`, `feat:`, `fix:`, `chore:`). History shows this is enforced.
- Keep changes scoped to a lesson. Don’t collateral‑edit other lessons unless necessary.
- For resource additions, prefer text assets; avoid committing binaries unless required by the lesson design.

## Cleanup & Troubleshooting
- Reset to a clean state: `Scripts/clean-tutorials.sh`.
- Caches can cause odd build behavior; remove `.swiftpm/` and `.tutor/` per lesson if needed.
- Network‑free environments: stick to local `--profile basic`; avoid upstream profiles.
- If `swift run` errors due to multiple products, ensure you are in the lesson folder and that `setup.sh` has generated the local package.

## When In Doubt
- Prefer local scaffolds; generate rather than commit.
- Validate with `tutor build/test/run` before pushing.
- Keep READMEs accurate; note local vs upstream expectations explicitly.

