import SwiftUI
import FountainAICore
import FountainAIAdapters
import LLMGatewayAPI

@main
struct AppEntry: App {
    @State private var settings = AppSettings()
    @State private var vm: AskViewModel? = nil
    @State private var settingsStore = DefaultSettingsStore(keychain: KeychainDefault())
    var body: some Scene {
        WindowGroup { MainView(vm: vm, onAsk: ask).onAppear { configure() } }
    }
    private func makeLLM() -> LLMService {
        let token: String? = (try? settingsStore.getSecret(for: settings.apiKeyRef ?? "")).flatMap { String(data: $0, encoding: .utf8) }
        switch settings.provider {
        case .openai:
            if let token, !token.isEmpty { return OpenAIAdapter(apiKey: token) } else { return MockLLMService() }
        case .customHTTP, .localServer:
            guard let urlStr = settings.baseURL, let url = URL(string: urlStr) else { return MockLLMService() }
            let client = LLMGatewayClient(baseURL: url, bearerToken: token)
            return LLMGatewayAdapter(client: client)
        }
    }
    private func configure() { do { settings = try settingsStore.load() } catch { }; vm = AskViewModel(llm: makeLLM(), browser: MockBrowserService()) }
    private func ask(_ q: String) async -> String { await vm?.ask(question: q); return await vm?.answer ?? "" }
}
struct MainView: View {
    let vm: AskViewModel?; let onAsk: (String) async -> String
    @State private var q = ""; @State private var a = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask").font(.title2)
            TextField("Your question", text: $q)
            Button("Get Answer") { Task { a = await onAsk(q) } }
            Divider(); ScrollView { Text(a).frame(maxWidth: .infinity, alignment: .leading) }
        }.padding().frame(minWidth: 600, minHeight: 400)
    }
}
final class MockLLMService: LLMService { func chat(model: String, messages: [FountainAICore.ChatMessage]) async throws -> String { "(mock) " + (messages.last?.content ?? "") } }
final class MockBrowserService: BrowserService { func analyze(url: String, corpusId: String?) async throws -> (title: String?, summary: String?) { (nil, nil) } }
