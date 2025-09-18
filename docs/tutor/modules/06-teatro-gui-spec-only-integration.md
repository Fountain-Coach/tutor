# Module 06 — Teatro GUI: Spec-Only Integration

**Outcome**: Wire Teatro to browse corpora, baselines/drift, and planner runs solely via APIs.

## What you’ll ship
A minimal, deterministic GUI that renders server responses; no internal shortcuts.

## Specs to read
- The same specs from Modules 02–05 (persist, awareness, planner, tools, function caller)

## Behavioral acceptance
- [ ] All state derived from HTTP responses
- [ ] Missing capability paths rendered with user guidance

## Test plan
- Snapshot test the GUI against canned API fixtures

## Runbook
- Set `TEATRO_BASE_URL` only if GUI is served separately; otherwise integrate locally

## Hand-off to Codex
> Render-only GUI that binds to the existing APIs. No direct file or DB access.
