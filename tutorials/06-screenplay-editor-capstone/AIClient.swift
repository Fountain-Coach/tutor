import Foundation

struct Message: Codable {
    let role: String
    let content: String
}

func askAI(prompt: String, completion: @escaping (String) -> Void) {
    let apiKey = ProcessInfo.processInfo.environment["FOUNTAIN_AI_KEY"]!
    let url = URL(string: "https://api.fountain.ai/v1/generate")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = [
        "model": "fountain-medium",
        "messages": [["role": "user", "content": prompt]]
    ]
    request.httpBody = try! JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, _, _ in
        if let data = data, let text = String(data: data, encoding: .utf8) {
            completion(text)
        }
    }.resume()
}
