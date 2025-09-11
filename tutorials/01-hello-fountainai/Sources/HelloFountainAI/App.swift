import SwiftUI
import LLMGatewayAPI

@main
struct AppEntry: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var prompt: String = "Say hello to FountainAI"
    @State private var responseText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LLM Gateway Chat").font(.title2)
            TextField("Your prompt", text: $prompt)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button(isLoading ? "Asking…" : "Ask") {
                    Task { await ask() }
                }
                .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Divider()
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            ScrollView { Text(responseText).frame(maxWidth: .infinity, alignment: .leading) }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    func ask() async {
        isLoading = true; defer { isLoading = false }
        do {
            let base = ProcessInfo.processInfo.environment["LLM_GATEWAY_URL"] ?? "http://localhost:8080/api/v1"
            guard let url = URL(string: base) else { errorMessage = "Invalid LLM_GATEWAY_URL"; return }
            let token = ProcessInfo.processInfo.environment["FOUNTAIN_AI_KEY"]
            let client = LLMGatewayClient(baseURL: url, bearerToken: token)
            let req = ChatRequest(model: "gpt-4o-mini", messages: [ChatMessage(role: "user", content: prompt)])
            let result = try await client.chat(req)
            responseText = String(describing: result)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
