import Foundation

struct CLI {
    enum Command: String { case scaffold, build, run, test, help }
}

@main
struct TutorCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let cmdString = args.first, let cmd = CLI.Command(rawValue: cmdString) else {
            printUsage(); return
        }
        var rest = Array(args.dropFirst())
        switch cmd {
        case .scaffold:
            await runScaffold(args: &rest)
        case .build:
            runSwift(cmd: "build", args: &rest)
        case .run:
            runSwift(cmd: "run", args: &rest)
        case .test:
            runSwift(cmd: "test", args: &rest)
        case .help:
            printUsage()
        }
    }

    static func printUsage() {
        let usage = """
        tutor-cli <command> [options]

        Commands:
          scaffold   --repo <path> --app <Name> [--bundle-id <id>]
          build      [--dir <path>] [-- <swift build args>]
          run        [--dir <path>] [-- <swift run args>]
          test       [--dir <path>] [-- <swift test args>]

        Examples:
          tutor-cli build --dir tutorials/01-hello-fountainai
          tutor-cli run --dir tutorials/01-hello-fountainai
          tutor-cli test --dir tutorials/01-hello-fountainai
          tutor-cli scaffold --repo /path/to/the-fountainai --app HelloFountainAI
        """
        print(usage)
    }

    static func parseDir(args: inout [String]) -> (dir: String, pass: [String]) {
        var dir = FileManager.default.currentDirectoryPath
        if let idx = args.firstIndex(of: "--dir"), idx + 1 < args.count {
            dir = args[idx + 1]
            args.removeSubrange(idx...(idx+1))
        }
        if let dashIdx = args.firstIndex(of: "--") {
            let pass = Array(args[(dashIdx+1)...])
            args.removeSubrange(dashIdx..<args.count)
            return (dir, pass)
        }
        return (dir, [])
    }

    static func runSwift(cmd: String, args: inout [String]) {
        let (dir, pass) = parseDir(args: &args)
        let moduleCache = (dir as NSString).appendingPathComponent(".modulecache")
        let swiftModuleCache = (dir as NSString).appendingPathComponent(".swift-module-cache")
        try? FileManager.default.createDirectory(atPath: moduleCache, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: swiftModuleCache, withIntermediateDirectories: true)

        var procArgs = [cmd, "--disable-sandbox",
                        "-Xcc", "-fmodules-cache-path=\(moduleCache)",
                        "-Xswiftc", "-module-cache-path", "-Xswiftc", swiftModuleCache]
        procArgs.append(contentsOf: pass)
        let code = runProcess(launchPath: "/usr/bin/swift", args: procArgs, cwd: dir)
        if code != 0 { exit(Int32(code)) }
    }

    static func runScaffold(args: inout [String]) async {
        var repo = ""; var app = ""; var bundle: String? = nil
        var it = args.makeIterator()
        while let a = it.next() {
            switch a {
            case "--repo": repo = it.next() ?? ""
            case "--app": app = it.next() ?? ""
            case "--bundle-id": bundle = it.next()
            default: break
            }
        }
        guard !repo.isEmpty, !app.isEmpty else {
            fputs("Usage: tutor-cli scaffold --repo <path> --app <Name> [--bundle-id <id>]\n", stderr)
            exit(2)
        }
        do {
            try ensureScaffold(repo: repo, app: app)
            print("Scaffolded in repo: \(repo), app: \(app)")
        } catch {
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }

    static func runProcess(launchPath: String, args: [String], cwd: String) -> Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = args
        task.currentDirectoryURL = URL(fileURLWithPath: cwd)
        var env = ProcessInfo.processInfo.environment
        env["CLANG_MODULE_CACHE_PATH"] = env["CLANG_MODULE_CACHE_PATH"] ?? ((cwd as NSString).appendingPathComponent(".modulecache"))
        task.environment = env
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError
        do { try task.run(); task.waitUntilExit(); return task.terminationStatus } catch { return 1 }
    }
}

// MARK: - Upstream Scaffold Logic (from prior CLI)

func readFile(_ path: String) throws -> String { try String(contentsOfFile: path, encoding: .utf8) }
func writeFile(_ path: String, _ content: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try content.write(to: url, atomically: true, encoding: .utf8)
}

func insertElement(in text: String, arrayName: String, element: String) -> String {
    guard let declRange = text.range(of: "let \(arrayName)", options: .regularExpression) else { return text }
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
    var lineStart = closeIdx
    while lineStart > text.startIndex && text[text.index(before: lineStart)] != "\n" { lineStart = text.index(before: lineStart) }
    let indent = "    "
    let prefix = text[..<lineStart]
    let suffix = text[lineStart...]
    let addition = text.contains(element) ? "" : "\n\(indent)\(element)"
    return String(prefix) + addition + String(suffix)
}

func ensureScaffold(repo: String, app: String) throws {
    let pkgPath = repo + "/Package.swift"
    var pkg = try readFile(pkgPath)
    let productLine = ".executable(name: \"\(app)\", targets: [\"\(app)\"]),"
    pkg = insertElement(in: pkg, arrayName: "fullProducts", element: productLine)
    pkg = insertElement(in: pkg, arrayName: "leanProducts", element: productLine)
    let targetLine = ".executableTarget(\n        name: \"\(app)\",\n        dependencies: [\"FountainAIAdapters\", \"FountainAICore\"],\n        path: \"apps/\(app)\"\n    ),"
    pkg = insertElement(in: pkg, arrayName: "fullTargets", element: targetLine)
    pkg = insertElement(in: pkg, arrayName: "leanTargets", element: targetLine)
    try writeFile(pkgPath, pkg)
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
            var body: some Scene { WindowGroup { MainView(vm: vm, onAsk: ask).onAppear { configure() } } }
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
            private func configure() { do { settings = try settingsStore.load() } catch { }; let llm = makeLLM(); vm = AskViewModel(llm: llm, browser: MockBrowserService()) }
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
        """
        try writeFile(mainPath, main)
    }
}

