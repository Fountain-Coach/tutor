# 05 – AI Integration with OpenAPI

Template-first workflow: `setup.sh` scaffolds a minimal Swift package from the FountainAI monorepo; build and run locally to explore the concept.

Call FountainAI’s OpenAPI endpoints from any HTTP client. This tutorial focuses on the LLM Gateway’s generate API using a local Gateway you run from source. Only the model request itself is remote: your local Gateway calls the provider (e.g., OpenAI) with your API key; everything else remains on your machine.

> Local vs Upstream
> - Local mode (default) is dependency-free and builds/tests offline. It does not include `LLMGatewayAPI`.
> - For real client libraries and API calls, scaffold upstream: `./setup.sh --profile ai --upstream`.

## Before you begin
- Install Tutor CLI and add to PATH (see docs/tutor-cli.md and docs/shells-and-git.md).
- Run all commands from `tutorials/05-ai-integration-openapi/`.
- Ensure you have an API key or local gateway token.

## 1. Scaffold the project
This tutorial uses the `ai` profile by default to include FountainAI client libraries. To be explicit or to regenerate:

```bash
./setup.sh --profile ai --upstream
```

Advanced: `./setup.sh --upstream` (or `SETUP_MODE=upstream ./setup.sh`) attempts to scaffold via the upstream monorepo and copy its generated files here; falls back to local if it fails.

## 2. Get API access
Obtain an API key or local token, then expose it to your environment:

```bash
export FOUNTAIN_AI_KEY="sk-your-key"
export LLM_GATEWAY_URL="http://localhost:8080/api/v1"
```

## 3. Invoke an AI endpoint
Send a POST request to the LLM Gateway `generate` path with the desired model and prompt.

### cURL example

```bash
curl "$LLM_GATEWAY_URL/generate" \
  -H "Authorization: Bearer $FOUNTAIN_AI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model":"fountain-medium",
    "messages":[{"role":"user","content":"Write a haiku about springs."}]
  }'
```

### Swift client snippet

```swift
import Foundation

let apiKey = ProcessInfo.processInfo.environment["FOUNTAIN_AI_KEY"]!
let base = ProcessInfo.processInfo.environment["LLM_GATEWAY_URL"] ?? "http://localhost:8080/api/v1"
let url = URL(string: base + "/generate")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
request.addValue("application/json", forHTTPHeaderField: "Content-Type")

let body: [String: Any] = [
  "model": "fountain-medium",
  "messages": [["role": "user", "content": "Draft a short poem about waterfalls."]]
]
request.httpBody = try JSONSerialization.data(withJSONObject: body)

let task = URLSession.shared.dataTask(with: request) { data, _, _ in
    if let data = data, let response = String(data: data, encoding: .utf8) {
        print(response)
    }
}
task.resume()
```

## Build and run
Compile and run the package:

```bash
tutor build
tutor run
```

## Troubleshooting
- 401/403: verify `$FOUNTAIN_AI_KEY` is set and valid for the target gateway.
- Connection refused: ensure your local gateway is running and `LLM_GATEWAY_URL` is correct.
- Model errors: list available models or confirm the `model` name expected by your gateway.

## Run tests
```bash
tutor test
```
Add tests that validate your request-building logic (headers, JSON encoding) and response parsing.

## Next steps
Use the responses in your app to drive features like summarization, dialogue, or content generation.

## See also
- [Deep dive: Dependency management with SwiftPM and profiles](../../docs/dependency-management-deep-dive.md)
