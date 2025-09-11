import Foundation

struct Args {
    var repo: String = ""
    var app: String = ""
    var bundleID: String? = nil
}

func parseArgs() -> Args {
    var a = Args()
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let arg = it.next() {
        switch arg {
        case "--repo": a.repo = it.next() ?? ""
        case "--app": a.app = it.next() ?? ""
        case "--bundle-id": a.bundleID = it.next()
        case "-h", "--help":
            print("Usage: scaffold-cli --repo <path> --app <Name> [--bundle-id <id>]")
            exit(0)
        default:
            // ignore unknown for forward-compat
            break
        }
    }
    return a
}

func readFile(_ path: String) throws -> String {
    return try String(contentsOfFile: path, encoding: .utf8)
}

func writeFile(_ path: String, _ content: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try content.write(to: url, atomically: true, encoding: .utf8)
}

func insertElement(in text: String, arrayName: String, element: String) -> String {
    // Find the array declaration: let <arrayName>
    guard let declRange = text.range(of: "let \(arrayName)", options: .regularExpression) else { return text }
    // Find first '[' after declaration
    guard let openBracketRange = text.range(of: "\\[", options: .regularExpression, range: declRange.lowerBound..<text.endIndex) else { return text }
    var idx = openBracketRange.upperBound
    var depth = 1
    var insertIndex: String.Index? = nil
    while idx < text.endIndex {
        let ch = text[idx]
        if ch == "[" { depth += 1 }
        if ch == "]" { depth -= 1; if depth == 0 { insertIndex = idx; break } }
        idx = text.index(after: idx)
    }
    guard let closeIdx = insertIndex else { return text }
    // Determine indentation by looking backwards to the start of the closing line
    var lineStart = closeIdx
    while lineStart > text.startIndex && text[text.index(before: lineStart)] != "\n" {
        lineStart = text.index(before: lineStart)
    }
    // Use 4 spaces indentation by default
    let indent = "    "
    let prefix = text[..<lineStart]
    let suffix = text[lineStart...]
    var addition = "\n\(indent)\(element)"
    // Avoid duplicate insertion
    if text.contains(element) { addition = "" }
    return String(prefix) + addition + String(suffix)
}

func ensureScaffold(repo: String, app: String) throws {
    let pkgPath = repo + "/Package.swift"
    var pkg = try readFile(pkgPath)

    // Insert products
    let productLine = ".executable(name: \"\(app)\", targets: [\"\(app)\"]),"
    pkg = insertElement(in: pkg, arrayName: "fullProducts", element: productLine)
    pkg = insertElement(in: pkg, arrayName: "leanProducts", element: productLine)

    // Insert targets
    let targetLine = ".executableTarget(\n        name: \"\(app)\",\n        dependencies: [\"FountainAIAdapters\", \"FountainAICore\"],\n        path: \"apps/\(app)\"\n    ),"
    pkg = insertElement(in: pkg, arrayName: "fullTargets", element: targetLine)
    pkg = insertElement(in: pkg, arrayName: "leanTargets", element: targetLine)

    try writeFile(pkgPath, pkg)

    // Write a basic main.swift in apps/<App>
    let mainPath = repo + "/apps/\(app)/main.swift"
    if !FileManager.default.fileExists(atPath: mainPath) {
        let main = """
import SwiftUI
import FountainAICore
import FountainAIAdapters
import LLMGatewayAPI

        @main
        struct AppEntry: App {
            @State private var settings = AppSettings()
            @State private var vm: AskViewModel? = nil
            @State private var settingsStore = DefaultSettingsStore(keychain: KeychainDefault())
            @State private var errorMessage: String? = nil
            var body: some Scene {
                WindowGroup {
                    MainView(vm: vm, onAsk: ask)
                        .onAppear { configure() }
                }
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
            private func configure() {
                do { settings = try settingsStore.load() } catch { }
                let llm = makeLLM()
                vm = AskViewModel(llm: llm, browser: MockBrowserService())
            }
            private func ask(_ q: String) async -> String { await vm?.ask(question: q); return await vm?.answer ?? "" }
        }
        struct MainView: View {
            let vm: AskViewModel?
            let onAsk: (String) async -> String
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
        """
        try writeFile(mainPath, main)
    }
}

@main
struct Runner {
    static func main() {
        let args = parseArgs()
        guard !args.repo.isEmpty, !args.app.isEmpty else {
            fputs("Missing required args. Usage: scaffold-cli --repo <path> --app <Name> [--bundle-id <id>]\n", stderr)
            exit(2)
        }
        do {
            try ensureScaffold(repo: args.repo, app: args.app)
            print("Scaffolded in repo: \(args.repo), app: \(args.app)")
        } catch {
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }
}
