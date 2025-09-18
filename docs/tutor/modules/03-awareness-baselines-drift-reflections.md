# Module 03 — Awareness: Baselines, Drift, Reflections

**Outcome**: Add a new baseline and observe drift & narrative patterns; manage reflections.

## What you’ll ship
A page to add baselines, list versions, and visualize drift/patterns over time.

## Specs to read
- `openapi/baseline-awareness.yml`
- `openapi/persist.yml`

## Behavioral acceptance
- [ ] `POST /corpora/{id}/baselines` persists a new baseline version
- [ ] `GET` returns version history; drift/patterns endpoints are visible in UI
- [ ] Reflections can be created and paginated

## Test plan
- Verify version bump after baseline creation
- Validate drift/pattern data shapes and empty-state handling

## Runbook
- Depend on corpus id from Module 02; reuse environment from **_includes/env.md**

## Hand-off to Codex
> Implement baseline CRUD, render drift/pattern insights, and a simple reflections timeline.
