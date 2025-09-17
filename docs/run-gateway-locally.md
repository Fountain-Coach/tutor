# Run the FountainAI Gateway Locally

This guide shows how to start a local Gateway so tutorials (e.g., 01–Hello Csound) can request AI‑generated content (like a `.csd` score).
We use the Source build (no Docker).

Architecture note: FountainAI (Gateway, tutorials, and tools) runs on your machine. The only external network call is from your local Gateway process to the model provider (e.g., OpenAI) via the configured adapter and your API key.

## Prerequisites
- macOS 14+, Swift 6.1+ (Xcode + Command Line Tools)
- Git installed

## Build From Source (macOS)

1) Clone the upstream monorepo

```bash
git clone https://github.com/Fountain-Coach/the-fountainai.git
cd the-fountainai
```

2) Build the Gateway service

```bash
cd services/GatewayServer
swift build
```

3) Set provider credentials (required)

The Gateway must be able to reach a language model provider. For OpenAI-compatible providers:

```bash
export OPENAI_API_KEY="sk-..."               # required
# Optional if using a non-default endpoint (Azure, self-hosted):
# export OPENAI_BASE_URL="https://api.openai.com/v1"
```

4) Run the Gateway (dev mode)

```bash
# Example flags; adjust if your service uses different names
swift run GatewayServer \
  --port 8080 \
  --dev \
  --no-auth
```

5) Verify health

```bash
curl http://localhost:8080/health
# Expect: {"ok":true} (or similar)
```

6) Set tutorial env vars

```bash
export LLM_GATEWAY_URL=http://localhost:8080/api/v1
export FOUNTAIN_AI_KEY=local-dev-key   # if auth is off, you can omit this
```

## Try It From a Tutorial (No Client Install Required)

1) Move into a tutorial folder (e.g., Hello Csound):

```bash
cd tutorials/01-hello-csound
```

2) Ask for a `.csd` via HTTP and write it into the tutorial (adjust prompt and JSON paths to your Gateway’s schema). Single copy/paste command:

```bash
PROMPT='Return a complete Csound .csd with a gentle envelope and a 3-note motif at 120 BPM. Output only .csd.'; \
curl -sS "$LLM_GATEWAY_URL/generate" \
  -H "Authorization: Bearer ${FOUNTAIN_AI_KEY:-}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg p \"$PROMPT\" '{model:"fountain-medium", messages:[{role:"user", content:$p}]}')" \
  | jq -r '.content // .choices[0].message.content' \
  > Sources/HelloCsound/hello.csd && echo 'Wrote Sources/HelloCsound/hello.csd'
```

3) Run as usual

```bash
./run.sh hear
```

## Notes
- Schema differences: adjust the `jq` selector to match your Gateway’s response.
- Fencing: if the model returns fenced code (```csound … ```), strip the fences before writing.
- Security: for non‑dev environments, do not use `--no-auth`; you’ll need a valid API key.
- Troubleshooting: check the Gateway logs and `/health` endpoint; ensure Swift 6.1+ is installed if building from source.
