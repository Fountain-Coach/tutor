import SwiftUI

struct ChatMessageItem: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

struct ChatView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var prompt: String = "Return a complete Csound .csd with a gentle envelope and a 3-note motif at 120 BPM. Output only .csd."
    @State private var isLoading = false
    @State private var error: String?
    @State private var messages: [ChatMessageItem] = []

    let onInsert: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chat • Csound Ideas").font(.title2).padding(.bottom, 4)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { m in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(m.role.capitalized).font(.caption).foregroundStyle(.secondary)
                            Text(m.content).font(.body).textSelection(.enabled)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(6)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .top, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $prompt)
                        .font(.system(size: 15))
                        .padding(8)
                        .frame(minHeight: 140)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(6)
                    if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Your prompt")
                            .foregroundStyle(.secondary)
                            .padding(.top, 14)
                            .padding(.leading, 14)
                    }
                }
                Button(isLoading ? "Asking…" : "Ask") {
                    Task { await ask() }
                }.disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Insert As .csd") {
                    if let last = messages.last?.content { onInsert(last) }
                }.disabled(messages.isEmpty)
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .padding()
    }

    func ask() async {
        isLoading = true; defer { isLoading = false }
        messages.append(.init(role: "user", content: prompt))
        do {
            let base = settings.gatewayURL
            guard let url = URL(string: base + "/generate") else { error = "Invalid LLM_GATEWAY_URL"; return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            let token = settings.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty { req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "model": "fountain-medium",
                "messages": [["role": "user", "content": prompt]]
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else {
                error = String(data: data, encoding: .utf8) ?? "Gateway error"; return
            }
            let text = String(data: data, encoding: .utf8) ?? ""
            // Try a couple common shapes
            let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let content = (parsed? ["content"] as? String)
                ?? ((((parsed? ["choices"] as? [[String: Any]])?.first? ["message"]) as? [String: Any])? ["content"] as? String)
                ?? text
            messages.append(.init(role: "assistant", content: content))
            error = nil
        } catch {
            self.error = String(describing: error)
        }
    }
}
