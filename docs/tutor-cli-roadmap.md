# Tutor CLI Roadmap

This is a living list of improvements to optimize the CLI for both humans and LLM/Codex automation.

## Completed

- Live status feedback (spinner, phase, elapsed).
- Machine-readable outputs (`.tutor/status.json`, `.tutor/events.ndjson`).
- Error parsing with concise failure summary via `tutor status`.
- Auto-parallel builds/tests (`--jobs <cores>` if not provided).
- Quiet and no-progress modes (`--quiet`, `--no-progress`).
- JSON summary (`--json-summary`) with error taxonomy and hints.

## In Progress / Next

- Percent progress heuristic (e.g., compiled files/targets seen).
- Local status server or Unix socket for streaming events without polling.
- Repro bundle on failure (minimal command + env snapshot).
- Rich test summaries with flaky detection and timing.
- Optional ANSI-less mode for strict log parsers.

## Ideas To Explore

- Pluggable reporters (console, JSON, GitHub Actions annotations).
- First-class CI mode to format output for GHA with `::error` annotations.
- Caching strategies beyond module caches (derived data dir hints, SPM cache key control).
- Self-update command to rebuild/install CLI in place.

Contributions welcome—open a PR referencing this roadmap and the affected tutorial paths.

