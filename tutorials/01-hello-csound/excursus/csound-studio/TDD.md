TDD Guide for Csound Studio

Goal: Maintain high confidence with fast, deterministic tests for core behavior. Follow red → green → refactor.

Principles
- Isolate pure logic (CsoundStudioCore) from UI and I/O.
- Favor behavior assertions (inputs/outputs) over internal state.
- Keep tests fast (<100ms each) and deterministic (no network, no binaries).
- Cover error paths and boundary conditions.

Checklist (per change)
1) Write a failing test
   - Add tests under `Tests/CsoundStudioTests/` importing `@testable import CsoundStudioCore`.
   - For parsing logic: include focused samples (e.g., `.csd` with specific i‑lines).
   - For exporters: assert key substrings/tokens, not exact full text.
2) Make it pass
   - Change only the smallest production code needed in `Sources/CsoundStudioCore/`.
   - Avoid adding external dependencies or side effects.
3) Refactor
   - Improve names, extract helpers, remove duplication.
   - Keep public API stable; prefer internal helpers.
4) Re‑run tests locally: `tutor test` (or `swift test`).
5) CI
   - Ensure `.github/workflows/swift-ci.yml` includes this lesson.
   - Avoid tests that depend on installed tools (e.g., `lilypond`, `csound`).

Areas to Expand
- LilyPond mapping edge cases: dotted durations, extreme tempos, empty inputs.
- Csound parser robustness: non‑standard spacing, comments, multiple instruments.
- System checks: error messaging, invalid URLs.

Anti‑Patterns
- Shelling out in tests; prefer pure functions.
- Testing SwiftUI views directly in this lesson; test the logic invoked by actions instead.

