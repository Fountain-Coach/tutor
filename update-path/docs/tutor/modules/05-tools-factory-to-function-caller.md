# Module 05 — Tools Factory → Function Caller

**Outcome**: Register a tool from an OpenAPI operation; invoke it via Function Caller; persist results.

## What you’ll ship
A tool registration pane (by `operationId`) and an invocation panel with result history.

## Specs to read
- `openapi/tools-factory.yml`
- `openapi/function-caller.yml`
- `openapi/persist.yml`

## Behavioral acceptance
- [ ] Register operations in Tools Factory
- [ ] Tools appear in catalog and are invokable by `operationId`
- [ ] Results persisted in corpus with links back to tool invocation

## Test plan
- Validate tool registration lifecycle and result persistence

## Runbook
- Configure Tools Factory and Function Caller URLs

## Hand-off to Codex
> Implement tool registration from spec and invocation via Function Caller; store outputs in corpus.
