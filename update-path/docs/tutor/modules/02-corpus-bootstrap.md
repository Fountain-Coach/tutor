# Module 02 — Corpus Bootstrap

**Outcome**: Create a corpus and seed roles/baselines; verify via Awareness.

## What you’ll ship
A bootstrap screen that creates a new corpus and displays its initial baseline state.

## Specs to read
- `openapi/bootstrap.yml`
- `openapi/persist.yml`
- `openapi/baseline-awareness.yml`

## Behavioral acceptance
- [ ] `POST /bootstrap` creates a corpus and seeds roles/baselines
- [ ] FountainStore reflects corpus records; Awareness shows an initial snapshot

## Test plan
- Confirm corpus creation returns identifiers and version info
- Confirm Awareness reads back seeded baseline

## Runbook
- Ensure FountainStore and Bootstrap URLs are configured (see **_includes/env.md**)

## Hand-off to Codex
> Implement a bootstrap flow: create corpus → fetch baseline → render confirmation.
