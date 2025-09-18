# Module 07 — Observability & Guards

**Outcome**: Add gateway plugins (budget, rate-limit, destructive-ops guard) and visualize their effects.

## What you’ll ship
Controls and indicators for budget/rate-limit states; explicit flows for destructive operations.

## Specs to read
- Gateway OpenAPIs: budget breaker, rate limiter, destructive operations guard, security sentinel

## Behavioral acceptance
- [ ] Budget/Rate-limit decisions observable in responses/headers and surfaced in UI
- [ ] Sensitive calls require explicit approval and are gated accordingly
- [ ] Metrics available via `/metrics` or equivalent endpoints

## Test plan
- Simulate throttling and verify UX clarity

## Runbook
- Ensure gateway base URLs are configured; propagate headers/metadata to the GUI layer

## Hand-off to Codex
> Integrate gateway decisions into UX, including guard rails and operator prompts.
