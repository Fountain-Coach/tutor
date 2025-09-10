# 05 – AI Integration with OpenAPI

Learn how to call FountainAI services from any HTTP client by using its OpenAPI endpoints.

## 1. Get API access
Create an account and generate an API key, then expose it to your environment:

```bash
export FOUNTAIN_AI_KEY="sk-your-key"
```

## 2. Invoke an AI endpoint
Send a POST request to the `/v1/generate` path with the desired model and prompt.

### cURL example

```bash
curl https://api.fountain.ai/v1/generate \
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
let url = URL(string: "https://api.fountain.ai/v1/generate")!
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

## Next steps
Use the responses in your app to drive features like summarization, dialogue, or content generation.
