# Tutor Path (OpenAPI-First, Corpus-Aware)

> Drop-in docs pack for the **Tutor** repository. This creates a coherent, spec-driven path that matches the current FountainAI scope: **OpenAPI-first**, **corpus via FountainStore**, **GUI (Teatro) only via documented APIs**, and **capability-aware** services.

---

## Repository Layout (Proposed)

```
README.md
AGENTS.md
LICENSE
docs/
  tutor/
    README.md
    modules/
      01-spec-literacy-and-health.md
      02-corpus-bootstrap.md
      03-awareness-baselines-drift-reflections.md
      04-planner-and-llm-gateway-loop.md
      05-tools-factory-to-function-caller.md
      06-teatro-gui-spec-only-integration.md
      07-observability-and-guards.md
      08-reasoning-streams-midi2-optional.md
    _includes/
      env.md
      repo-links.md
      testing-checklists.md
```

> **Notes**
> - Keep all module docs within `docs/tutor/modules/` and reference common snippets (env, links, testing) from `_includes/`.
> - This pack assumes each service exposes `/v1/health`, `/v1/capabilities`, and documented OpenAPI schemas under an `openapi/` directory across repos.

---

## Global Principles

1. **OpenAPI before code** — start each module by curating/reading the spec.
2. **Corpus everywhere** — tests run against a seeded FountainStore corpus.
3. **GUI via APIs** — Teatro exercises only spec’d endpoints; no internal calls.
4. **Capabilities-aware** — surface missing features via `/v1/capabilities`.

## Profiles (Conceptual)

- `ai` — completions/streaming via an HTTP gateway (model-agnostic).
- `persist` — FountainStore as the durable store for corpora & artifacts.
- `teatro` — GUI that renders strictly from API responses.
- `midi2` — optional reasoning/timing/sonic transparency (SSE-over-MIDI).

## Modules

1. [**Spec Literacy & Health**](docs/tutor/modules/01-spec-literacy-and-health.md) — list services, check `/v1/health`, enumerate `/v1/capabilities`.
2. [**Corpus Bootstrap**](docs/tutor/modules/02-corpus-bootstrap.md) — create a corpus, seed baselines/roles, verify state.
3. [**Awareness: Baselines, Drift, Reflections**](docs/tutor/modules/03-awareness-baselines-drift-reflections.md) — add baselines, inspect drift & narrative patterns.
4. [**Planner + LLM Gateway Loop**](docs/tutor/modules/04-planner-and-llm-gateway-loop.md) — plan → execute via Function Caller with corpus context.
5. [**Tools Factory → Function Caller**](docs/tutor/modules/05-tools-factory-to-function-caller.md) — register/invoke tools from OpenAPI operations.
6. [**Teatro GUI: Spec-Only Integration**](docs/tutor/modules/06-teatro-gui-spec-only-integration.md) — browse corpora, baselines, planner runs via APIs.
7. [**Observability & Guards**](docs/tutor/modules/07-observability-and-guards.md) — budget, rate-limit, destructive-ops guard; expose metrics.
8. [**Reasoning Streams (Optional, MIDI2)**](docs/tutor/modules/08-reasoning-streams-midi2-optional.md) — live transparent streams; transport controls.

## How To Use This Path

- Start at Module 01 and continue sequentially; each module keeps the previous app useful.
- Treat the **acceptance criteria** and **test plans** as your source of truth.
- When a capability is missing, surface it in the UI as a request with guidance.

## Shared Resources

- **Environment Baseline:** [`docs/tutor/_includes/env.md`](docs/tutor/_includes/env.md)
- **Testing Checklists:** [`docs/tutor/_includes/testing-checklists.md`](docs/tutor/_includes/testing-checklists.md)
- **Repo Links:** [`docs/tutor/_includes/repo-links.md`](docs/tutor/_includes/repo-links.md)
