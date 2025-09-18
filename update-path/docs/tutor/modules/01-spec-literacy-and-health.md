# Module 01 — Spec Literacy & Health

**Outcome**: Be able to enumerate services from OpenAPI specs, check `/v1/health`, and list `/v1/capabilities`.

## What you’ll ship
A simple dashboard listing all documented services with live health & capabilities.

## Specs to read
- `openapi/bootstrap.yml`
- `openapi/baseline-awareness.yml`
- `openapi/persist.yml` (FountainStore)
- `openapi/planner.yml`
- `openapi/function-caller.yml`
- `openapi/tools-factory.yml`
- Relevant gateway specs (rate limiter, budget breaker, security, etc.)

## Behavioral acceptance
- [ ] Load the above specs and render a services table (name, base URL, health, capabilities)
- [ ] Unknown/missing capability is shown with guidance: “Needs: <capability>”

## Test plan
- Validate 200 from `/v1/health` per service
- Parse and render `/v1/capabilities`

## Runbook
- Configure base URLs and keys from **_includes/env.md**

## Hand-off to Codex
> Build a service table that reads from the listed specs and queries `/v1/health` and `/v1/capabilities`. No hardcoded endpoints.
