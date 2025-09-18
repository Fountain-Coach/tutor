# Module 04 — Planner + LLM Gateway Loop

**Outcome**: Plan then execute; the planner orchestrates steps via Function Caller with corpus context.

## What you’ll ship
A two-phase interface: 1) plan (list of steps), 2) execute with tool outputs.

## Specs to read
- `openapi/planner.yml`
- `openapi/function-caller.yml`
- Gateway specs used by the LLM gateway

## Behavioral acceptance
- [ ] `POST /planner` yields an ordered step list with corpus context
- [ ] `POST /planner/execute` runs steps via Function Caller and shows ordered outputs

## Test plan
- Contract test for step ordering and minimal error handling per step

## Runbook
- Ensure Planner and Function Caller URLs are set; surface `NotSupported` if capabilities are missing

## Hand-off to Codex
> Implement plan → execute controls wired to the documented endpoints only.
