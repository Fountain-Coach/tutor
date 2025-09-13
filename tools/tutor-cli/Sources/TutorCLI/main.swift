import Foundation
import Dispatch
#if canImport(Darwin)
import Darwin
#endif

struct CLI {
    enum Command: String { case scaffold, build, run, test, status, install, help }
}

@main
struct TutorCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        if args.first == "-h" || args.first == "--help" || args.isEmpty {
            printUsage(); return
        }
        guard let cmdString = args.first, let cmd = CLI.Command(rawValue: cmdString) else { printUsage(); return }
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
        case .status:
            runStatus(args: &rest)
        case .install:
            runInstall(args: &rest)
        case .help:
            printUsage()
        }
    }

    static func printUsage() {
        let usage = """
        tutor <command> [options]

        Commands:
          scaffold   --repo <path> --app <Name> [--bundle-id <id>]
          build      [--dir <path>] [--verbose] [--no-progress] [--quiet] [--no-status-file] [--status-file <path>] [--event-file <path>] [-- <swift build args>]
          run        [--dir <path>] [--verbose] [--no-progress] [--quiet] [--no-status-file] [--status-file <path>] [--event-file <path>] [-- <swift run args>]
          test       [--dir <path>] [--verbose] [--no-progress] [--quiet] [--no-status-file] [--status-file <path>] [--event-file <path>] [-- <swift test args>]
          status     [--dir <path>] [--json] [--watch]

        Examples:
          tutor build --dir tutorials/01-hello-fountainai
          tutor run --dir tutorials/01-hello-fountainai
          tutor test --dir tutorials/01-hello-fountainai
          tutor scaffold --repo /path/to/the-fountainai --app HelloFountainAI
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
        // Local CLI flags
        var verbose = false
        var showProgress = true
        var quiet = false
        var noStatusFile = false
        var statusFileOverride: String? = nil
        var eventFileOverride: String? = nil
        if let idx = args.firstIndex(of: "--verbose") { verbose = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "-v") { verbose = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--no-progress") { showProgress = false; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--quiet") { quiet = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--no-status-file") { noStatusFile = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--status-file"), idx + 1 < args.count { statusFileOverride = args[idx+1]; args.removeSubrange(idx...(idx+1)) }
        if let idx = args.firstIndex(of: "--event-file"), idx + 1 < args.count { eventFileOverride = args[idx+1]; args.removeSubrange(idx...(idx+1)) }

        let (dir, pass) = parseDir(args: &args)
        let moduleCache = (dir as NSString).appendingPathComponent(".modulecache")
        let swiftModuleCache = (dir as NSString).appendingPathComponent(".swift-module-cache")
        try? FileManager.default.createDirectory(atPath: moduleCache, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: swiftModuleCache, withIntermediateDirectories: true)

        var procArgs = [cmd, "--disable-sandbox",
                        "-Xcc", "-fmodules-cache-path=\(moduleCache)",
                        "-Xswiftc", "-module-cache-path", "-Xswiftc", swiftModuleCache]

        // Add parallelism if not provided explicitly
        let hasJobs = pass.contains(where: { $0 == "--jobs" || $0 == "-j" })
        var passThrough = pass
        if !hasJobs {
            let cores = max(2, ProcessInfo.processInfo.activeProcessorCount)
            passThrough.insert(contentsOf: ["--jobs", String(cores)], at: 0)
        }

        if verbose { procArgs.insert("-v", at: 1) }
        procArgs.append(contentsOf: passThrough)
        let header = "Running: swift \(procArgs.joined(separator: " "))\nDirectory: \(dir)"
        if !quiet { fputs("\(header)\n", stderr) }
        let title: String
        switch cmd { case "build": title = "Building"; case "test": title = "Testing"; case "run": title = "Running"; default: title = cmd.capitalized }
        // Setup machine-readable outputs
        let tutorDir = (dir as NSString).appendingPathComponent(".tutor")
        try? FileManager.default.createDirectory(atPath: tutorDir, withIntermediateDirectories: true)
        let statusPath = noStatusFile ? nil : (statusFileOverride ?? (tutorDir as NSString).appendingPathComponent("status.json"))
        let eventPath = eventFileOverride ?? (tutorDir as NSString).appendingPathComponent("events.ndjson")

        let code = runProcess(
            launchPath: "/usr/bin/swift",
            args: procArgs,
            cwd: dir,
            showProgress: showProgress && !quiet,
            title: title,
            echoOutput: !quiet,
            statusFile: statusPath,
            eventFile: eventPath,
            command: cmd
        )
        if code != 0 { exit(Int32(code)) }
    }

    static func runInstall(args: inout [String]) {
        var binDir = (NSHomeDirectory() as NSString).appendingPathComponent(".local/bin")
        if let idx = args.firstIndex(of: "--bin-dir"), idx + 1 < args.count { binDir = args[idx+1] }
        let fm = FileManager.default
        try? fm.createDirectory(atPath: binDir, withIntermediateDirectories: true)
        let selfPath = (CommandLine.arguments.first!).hasPrefix("/") ? CommandLine.arguments.first! : URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(CommandLine.arguments.first!).path
        let target = (binDir as NSString).appendingPathComponent("tutor")
        do {
            if fm.fileExists(atPath: target) { try? fm.removeItem(atPath: target) }
            try fm.copyItem(atPath: selfPath, toPath: target)
            print("Installed tutor to \(target)\nAdd to PATH if needed: export PATH=\(binDir):$PATH")
        } catch {
            fputs("Install failed: \(error)\n", stderr)
            exit(1)
        }
    }

    static func runScaffold(args: inout [String]) async {
        var repo = ""; var app = ""
        var it = args.makeIterator()
        while let a = it.next() {
            switch a {
            case "--repo": repo = it.next() ?? ""
            case "--app": app = it.next() ?? ""
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

    static func runProcess(launchPath: String,
                           args: [String],
                           cwd: String,
                           showProgress: Bool = true,
                           title: String = "Working",
                           echoOutput: Bool = true,
                           statusFile: String?,
                           eventFile: String?,
                           command: String) -> Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = args
        task.currentDirectoryURL = URL(fileURLWithPath: cwd)
        var env = ProcessInfo.processInfo.environment
        env["CLANG_MODULE_CACHE_PATH"] = env["CLANG_MODULE_CACHE_PATH"] ?? ((cwd as NSString).appendingPathComponent(".modulecache"))
        task.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        let start = Date()
        let reporter = ProgressReporter(enabled: showProgress, title: title)

        var phase = "starting"
        var errors: [[String: Any]] = []
        var warnings: [[String: Any]] = []
        let errorRegex = try? NSRegularExpression(pattern: "^(.*?):(\\d+):(\\d+): error: (.*)$")
        let warningRegex = try? NSRegularExpression(pattern: "^(.*?):(\\d+):(\\d+): warning: (.*)$")

        func writeStatus(final: Bool = false, exitCode: Int32? = nil) {
            guard let statusFile else { return }
            var obj: [String: Any] = [
                "title": title,
                "command": command,
                "phase": phase,
                "status": reporter.currentStatus,
                "elapsed": Int(Date().timeIntervalSince(start)),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            if final { obj["final"] = true; obj["exitCode"] = exitCode ?? 0; obj["errors"] = errors; obj["warnings"] = warnings }
            writeJSONAtomic(path: statusFile, object: obj)
        }

        func writeEvent(_ type: String, _ payload: [String: Any]) {
            guard let eventFile else { return }
            var obj = payload
            obj["type"] = type
            obj["ts"] = ISO8601DateFormatter().string(from: Date())
            appendNDJSON(path: eventFile, object: obj)
        }

        func handle(line: String) {
            // Basic phase detection for status
            let s = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if s.isEmpty { return }
            if s.contains("Fetching") { phase = "fetching"; reporter.set(status: "Fetching packages") }
            else if s.contains("Updating") { phase = "updating"; reporter.set(status: "Updating dependencies") }
            else if s.contains("Resolving") || s.contains("Resolve") { phase = "resolving"; reporter.set(status: "Resolving package graph") }
            else if s.contains("Compiling") {
                // SwiftPM verbose format: "Compiling <module> <file>.swift"
                phase = "compiling"
                if let mod = s.split(separator: " ").dropFirst().first { reporter.set(status: "Compiling \(mod)") }
                else { reporter.set(status: "Compiling sources") }
            }
            else if s.contains("Linking") { phase = "linking"; reporter.set(status: "Linking targets") }
            else if s.contains("Testing") || s.contains("Test Suite") { phase = "testing"; reporter.set(status: "Running tests") }
            else if s.lowercased().contains("building for") { phase = "preparing"; reporter.set(status: "Preparing build") }
            else if s.contains("Build complete!") { phase = "completed"; reporter.set(status: "Build complete") }
            else if s.contains("Executing") { phase = "running"; reporter.set(status: "Launching app") }

            if s.contains("error:") || s.contains("warning:") {
                let lineRange = NSRange(location: 0, length: (s as NSString).length)
                if let m = errorRegex?.firstMatch(in: s, options: [], range: lineRange) {
                    let file = (s as NSString).substring(with: m.range(at: 1))
                    let ln = Int((s as NSString).substring(with: m.range(at: 2))) ?? 0
                    let col = Int((s as NSString).substring(with: m.range(at: 3))) ?? 0
                    let msg = (s as NSString).substring(with: m.range(at: 4))
                    let e: [String: Any] = ["file": file, "line": ln, "column": col, "message": msg]
                    errors.append(e)
                    writeEvent("error", ["error": e])
                    reporter.set(status: "Error encountered")
                } else if let m = warningRegex?.firstMatch(in: s, options: [], range: lineRange) {
                    let file = (s as NSString).substring(with: m.range(at: 1))
                    let ln = Int((s as NSString).substring(with: m.range(at: 2))) ?? 0
                    let col = Int((s as NSString).substring(with: m.range(at: 3))) ?? 0
                    let msg = (s as NSString).substring(with: m.range(at: 4))
                    let w: [String: Any] = ["file": file, "line": ln, "column": col, "message": msg]
                    warnings.append(w)
                    writeEvent("warning", ["warning": w])
                }
            }

            // Emit log lines as events (without full echo if quiet)
            writeEvent("log", ["line": s])
            writeStatus()
        }

        // Stream output
        let outHandle = stdoutPipe.fileHandleForReading
        let errHandle = stderrPipe.fileHandleForReading
        outHandle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.isEmpty { return }
            if echoOutput { FileHandle.standardOutput.write(data) }
            if let text = String(data: data, encoding: .utf8) { text.split(separator: "\n", omittingEmptySubsequences: false).forEach { handle(line: String($0)) } }
        }
        errHandle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.isEmpty { return }
            if echoOutput { FileHandle.standardError.write(data) }
            if let text = String(data: data, encoding: .utf8) { text.split(separator: "\n", omittingEmptySubsequences: false).forEach { handle(line: String($0)) } }
        }

        do {
            reporter.start()
            writeEvent("start", ["title": title, "command": command])
            writeStatus()
            try task.run()
            task.waitUntilExit()
        } catch {
            reporter.stop(final: false)
            writeEvent("crash", ["message": "Failed to start process: \(error.localizedDescription)"])
            writeStatus(final: true, exitCode: 1)
            return 1
        }
        reporter.stop(final: true, elapsed: Date().timeIntervalSince(start))
        let code = task.terminationStatus
        writeEvent("end", ["exitCode": code])
        writeStatus(final: true, exitCode: code)
        return code
    }
}

// MARK: - Upstream Scaffold Logic (from prior CLI)

func readFile(_ path: String) throws -> String { try String(contentsOfFile: path, encoding: .utf8) }
func writeFile(_ path: String, _ content: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try content.write(to: url, atomically: true, encoding: .utf8)
}

// MARK: - Live Progress Reporter

final class ProgressReporter {
    private let enabled: Bool
    private let title: String
    private var timer: DispatchSourceTimer?
    private var start = Date()
    private var lastStatus = "Starting"
    private var spinnerIndex = 0
    private let spinnerFrames = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
    private let isTTY: Bool
    private(set) var currentStatus: String = "Starting"

    init(enabled: Bool, title: String) {
        self.enabled = enabled
        self.title = title
        #if canImport(Darwin)
        self.isTTY = isatty(STDERR_FILENO) != 0
        #else
        self.isTTY = true
        #endif
    }

    func start() {
        guard enabled else { return }
        start = Date()
        fputs("\(title)…\n", stderr)
        let t = DispatchSource.makeTimerSource(queue: .global())
        t.schedule(deadline: .now(), repeating: .milliseconds(200))
        t.setEventHandler { [weak self] in self?.tick() }
        timer = t
        t.resume()
    }

    func set(status: String) {
        guard enabled else { return }
        lastStatus = status
        currentStatus = status
    }

    private func tick() {
        let elapsed = Int(Date().timeIntervalSince(start))
        let frame = spinnerFrames[spinnerIndex % spinnerFrames.count]
        spinnerIndex += 1
        if isTTY {
            fputs("\r\u{001B}[2K\(frame) \(title): \(lastStatus) (\(elapsed)s)", stderr)
            fflush(stderr)
        } else {
            // Non-TTY: emit a line every 3 seconds
            if spinnerIndex % 15 == 0 { fputs("… \(title.lowercased()) — \(lastStatus) (\(elapsed)s)\n", stderr) }
        }
    }

    func stop(final: Bool, elapsed: TimeInterval? = nil) {
        guard enabled else { return }
        timer?.cancel()
        if isTTY { fputs("\r\u{001B}[2K", stderr) }
        if final {
            let e = elapsed ?? Date().timeIntervalSince(start)
            let fmt = String(format: "%.2f", e)
            fputs("✓ \(title) completed in \(fmt)s\n", stderr)
        }
    }
}

// MARK: - Machine IO helpers

@discardableResult
func writeJSONAtomic(path: String, object: [String: Any]) -> Bool {
    do {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: path) { try? FileManager.default.removeItem(atPath: path) }
        try FileManager.default.moveItem(at: tmp, to: url)
        return true
    } catch {
        return false
    }
}

@discardableResult
func appendNDJSON(path: String, object: [String: Any]) -> Bool {
    do {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: path) { FileManager.default.createFile(atPath: path, contents: nil) }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.write(contentsOf: "\n".data(using: .utf8)!)
        return true
    } catch {
        return false
    }
}

// MARK: - Status command

extension TutorCLI {
    static func runStatus(args: inout [String]) {
        var json = false
        var watch = false
        if let idx = args.firstIndex(of: "--json") { json = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--watch") { watch = true; args.remove(at: idx) }
        let (dir, _) = parseDir(args: &args)
        let statusPath = (dir as NSString).appendingPathComponent(".tutor/status.json")
        func printOnce() {
            guard let data = FileManager.default.contents(atPath: statusPath) else { fputs("No status found at \(statusPath)\n", stderr); return }
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { fputs("Invalid status file.\n", stderr); return }
            if json {
                if let s = String(data: data, encoding: .utf8) { print(s) }
            } else {
                let title = obj["title"] as? String ?? "Work"
                let phase = obj["phase"] as? String ?? ""
                let status = obj["status"] as? String ?? ""
                let elapsed = obj["elapsed"] as? Int ?? 0
                print("\(title): \(status) [phase=\(phase)] (\(elapsed)s)")
                if let final = obj["final"] as? Bool, final {
                    let code = obj["exitCode"] as? Int ?? 0
                    print(code == 0 ? "Result: success" : "Result: failure (code \(code))")
                    if code != 0, let errs = obj["errors"] as? [[String: Any]], !errs.isEmpty {
                        let first = errs[0]
                        let file = first["file"] as? String ?? ""
                        let line = first["line"] as? Int ?? 0
                        let msg = first["message"] as? String ?? ""
                        print("First error: \(file):\(line): \(msg)")
                    }
                }
            }
        }
        if watch {
            var lastSize: UInt64 = 0
            while true {
                let attrs = try? FileManager.default.attributesOfItem(atPath: statusPath)
                let size = (attrs?[.size] as? NSNumber)?.uint64Value ?? 0
                if size != lastSize {
                    printOnce()
                    lastSize = size
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
        } else {
            printOnce()
        }
    }
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
