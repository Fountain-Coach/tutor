import Foundation
import Dispatch
#if canImport(Darwin)
import Darwin
#endif
#if canImport(Network)
@preconcurrency import Network
#endif

struct CLI {
    enum Command: String { case scaffold, build, run, test, status, serve, doctor, viewer, install, help }
}

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
        case .serve:
            runServe(args: &rest)
        case .doctor:
            await runDoctor(args: &rest)
        case .viewer:
            runViewer(args: &rest)
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
          build      [--dir <path>] [--verbose] [--no-progress] [--quiet] [--json-summary] [--ci] [--midi] [--midi-virtual-name <name>] [--no-status-file] [--status-file <path>] [--event-file <path>] [-- <swift build args>]
          run        [--dir <path>] [--verbose] [--no-progress] [--quiet] [--json-summary] [--ci] [--midi] [--midi-virtual-name <name>] [--no-status-file] [--status-file <path>] [--event-file <path>] [-- <swift run args>]
          test       [--dir <path>] [--verbose] [--no-progress] [--quiet] [--json-summary] [--ci] [--midi] [--midi-virtual-name <name>] [--no-status-file] [--status-file <path>] [--event-file <path>] [-- <swift test args>]
          status     [--dir <path>] [--json] [--watch]
          serve      [--dir <path>] [--port <n>|--port 0] [--no-auth] [--dev] [--socket <path>] [--midi] [--midi-virtual-name <name>]
          doctor     [--dir <path>]  (runs local server health checks)
          viewer     [--dir <path>]  (launch native viewer for status/events)
          viewer     [--dir <path>]  (launch native viewer for status/events)

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
        var jsonSummary = false
        var midiEnabled = false
        var midiName: String? = nil
        var ciMode = false
        if let idx = args.firstIndex(of: "--verbose") { verbose = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "-v") { verbose = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--no-progress") { showProgress = false; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--quiet") { quiet = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--no-status-file") { noStatusFile = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--status-file"), idx + 1 < args.count { statusFileOverride = args[idx+1]; args.removeSubrange(idx...(idx+1)) }
        if let idx = args.firstIndex(of: "--event-file"), idx + 1 < args.count { eventFileOverride = args[idx+1]; args.removeSubrange(idx...(idx+1)) }
        if let idx = args.firstIndex(of: "--json-summary") { jsonSummary = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--ci") { ciMode = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--midi") { midiEnabled = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--midi-virtual-name"), idx + 1 < args.count { midiName = args[idx+1]; args.removeSubrange(idx...(idx+1)) }

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
            command: cmd,
            jsonSummary: jsonSummary,
            ciMode: ciMode,
            midiEnabled: midiEnabled,
            midiName: midiName,
            extraEnv: nil
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
                           command: String,
                           jsonSummary: Bool,
                           ciMode: Bool,
                           midiEnabled: Bool,
                           midiName: String?,
                           extraEnv: [String: String]? = nil) -> Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = args
        task.currentDirectoryURL = URL(fileURLWithPath: cwd)
        var env = ProcessInfo.processInfo.environment
        env["CLANG_MODULE_CACHE_PATH"] = env["CLANG_MODULE_CACHE_PATH"] ?? ((cwd as NSString).appendingPathComponent(".modulecache"))
        if let extraEnv {
            for (k,v) in extraEnv { env[k] = v }
        }
        task.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        let start = Date()
        let reporter = ProgressReporter(enabled: showProgress, title: title)
        let midi = midiEnabled ? MIDIBridge.make(name: midiName ?? "TutorCLI") : nil
        let ctx = RunContext(title: title,
                             command: command,
                             statusPath: statusFile,
                             eventPath: eventFile,
                             reporter: reporter,
                             midi: midi,
                             ciMode: ciMode,
                             start: start)

        // events/status handled via RunContext

        let handle: @Sendable (String) -> Void = { sLine in ctx.process(line: sLine) }

        // Stream output
        let outHandle = stdoutPipe.fileHandleForReading
        let errHandle = stderrPipe.fileHandleForReading
        outHandle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.isEmpty { return }
            if echoOutput { FileHandle.standardOutput.write(data) }
            if let text = String(data: data, encoding: .utf8) { text.split(separator: "\n", omittingEmptySubsequences: false).forEach { handle(String($0)) } }
        }
        errHandle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.isEmpty { return }
            if echoOutput { FileHandle.standardError.write(data) }
            if let text = String(data: data, encoding: .utf8) { text.split(separator: "\n", omittingEmptySubsequences: false).forEach { handle(String($0)) } }
        }

        do {
            reporter.start()
            ctx.onStart()
            try task.run()
            task.waitUntilExit()
        } catch {
            reporter.stop(final: false)
            ctx.onCrash(message: "Failed to start process: \(error.localizedDescription)")
            return 1
        }
        reporter.stop(final: true, elapsed: Date().timeIntervalSince(start))
        let code = task.terminationStatus
        ctx.onFinish(exitCode: code)

        if jsonSummary {
            if let text = ctx.makeSummaryJSON() { print(text) }
        }
        return code
    }
}

final class RunContext: @unchecked Sendable {
    private let q = DispatchQueue(label: "TutorCLI.RunContext")
    private let title: String
    private let command: String
    private let statusPath: String?
    private let eventPath: String?
    private let reporter: ProgressReporter
    private let midi: MIDIBridge?
    private let ciMode: Bool
    private let start: Date
    private var phase: String = "starting"
    private var errors: [[String: Any]] = []
    private var warnings: [[String: Any]] = []
    private let errorRegex = try? NSRegularExpression(pattern: "^(.*?):(\\d+):(\\d+): error: (.*)$")
    private let warningRegex = try? NSRegularExpression(pattern: "^(.*?):(\\d+):(\\d+): warning: (.*)$")
    private var sawTestFailure = false
    private var sawLinkerError = false
    private var sawResolveError = false
    private var sawNetworkError = false

    init(title: String, command: String, statusPath: String?, eventPath: String?, reporter: ProgressReporter, midi: MIDIBridge?, ciMode: Bool, start: Date) {
        self.title = title; self.command = command; self.statusPath = statusPath; self.eventPath = eventPath; self.reporter = reporter; self.midi = midi; self.ciMode = ciMode; self.start = start
    }

    func onStart() { q.sync { writeEvent(type: "start", payload: ["title": title, "command": command]); writeStatus() } }
    func onCrash(message: String) { q.sync { writeEvent(type: "crash", payload: ["message": message]); writeStatus(final: true, exitCode: 1) } }
    func onFinish(exitCode: Int32) { q.sync { writeEvent(type: "end", payload: ["exitCode": exitCode]); writeStatus(final: true, exitCode: exitCode) } }

    func process(line: String) {
        let s = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return }
        q.sync {
            if s.contains("Fetching") { phase = "fetching"; reporter.set(status: "Fetching packages") }
            else if s.contains("Updating") { phase = "updating"; reporter.set(status: "Updating dependencies") }
            else if s.contains("Resolving") || s.contains("Resolve") { phase = "resolving"; reporter.set(status: "Resolving package graph") }
            else if s.contains("Compiling") { phase = "compiling"; if let mod = s.split(separator: " ").dropFirst().first { reporter.set(status: "Compiling \(mod)") } else { reporter.set(status: "Compiling sources") }; reporter.bumpCompile() }
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
                    writeEvent(type: "error", payload: ["error": e])
                    reporter.set(status: "Error encountered")
                    if ciMode { print("::error file=\(file),line=\(ln),col=\(col)::\(msg.replacingOccurrences(of: "\n", with: " "))") }
                    if msg.localizedCaseInsensitiveContains("linker command failed") || msg.localizedCaseInsensitiveContains("Undefined symbols") { sawLinkerError = true }
                    if msg.localizedCaseInsensitiveContains("could not resolve") || msg.localizedCaseInsensitiveContains("resolve") { sawResolveError = true }
                    if msg.localizedCaseInsensitiveContains("timed out") || msg.localizedCaseInsensitiveContains("network") || msg.localizedCaseInsensitiveContains("failed to connect") { sawNetworkError = true }
                } else if let m = warningRegex?.firstMatch(in: s, options: [], range: lineRange) {
                    let file = (s as NSString).substring(with: m.range(at: 1))
                    let ln = Int((s as NSString).substring(with: m.range(at: 2))) ?? 0
                    let col = Int((s as NSString).substring(with: m.range(at: 3))) ?? 0
                    let msg = (s as NSString).substring(with: m.range(at: 4))
                    let w: [String: Any] = ["file": file, "line": ln, "column": col, "message": msg]
                    warnings.append(w)
                    writeEvent(type: "warning", payload: ["warning": w])
                    if ciMode { print("::warning file=\(file),line=\(ln),col=\(col)::\(msg.replacingOccurrences(of: "\n", with: " "))") }
                }
            }
            if s.contains("Test Suite 'All tests' failed") || s.contains("Failing tests:") { sawTestFailure = true }
            writeEvent(type: "log", payload: ["line": s])
            writeStatus()
        }
    }

    private func writeStatus(final: Bool = false, exitCode: Int32? = nil) {
        guard let statusPath else { return }
        var obj: [String: Any] = [
            "title": title,
            "command": command,
            "phase": phase,
            "status": reporter.currentStatus,
            "elapsed": Int(Date().timeIntervalSince(start)),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        if final { obj["final"] = true; obj["exitCode"] = exitCode ?? 0; obj["errors"] = errors; obj["warnings"] = warnings }
        _ = writeJSONAtomic(path: statusPath, object: obj)
        midi?.sendEvent(type: final ? "status-final" : "status", payload: obj)
    }

    private func writeEvent(type: String, payload: [String: Any]) {
        guard let eventPath else { return }
        var obj = payload
        obj["type"] = type
        obj["ts"] = ISO8601DateFormatter().string(from: Date())
        _ = appendNDJSON(path: eventPath, object: obj)
        midi?.sendEvent(type: type, payload: obj)
    }

    func makeSummaryJSON() -> String? {
        let (category, hint) = categorizeFailure(command: command, phase: phase, code: 0, sawTestFailure: sawTestFailure, sawLinkerError: sawLinkerError, sawResolveError: sawResolveError, sawNetworkError: sawNetworkError, errors: errors)
        let summary: [String: Any] = [
            "title": title,
            "command": command,
            "phase": phase,
            "elapsed": Int(Date().timeIntervalSince(start)),
            "exitCode": 0,
            "category": category,
            "hint": hint,
            "errorCount": errors.count,
            "warningCount": warnings.count,
            "errors": errors,
            "warnings": warnings
        ]
        if let data = try? JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted]), let text = String(data: data, encoding: .utf8) { return text }
        return nil
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

final class ProgressReporter: @unchecked Sendable {
    private let enabled: Bool
    private let title: String
    private var timer: DispatchSourceTimer?
    private var startTime = Date()
    private var lastStatus = "Starting"
    private var spinnerIndex = 0
    private let spinnerFrames = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
    private let isTTY: Bool
    private(set) var currentStatus: String = "Starting"
    private var compileTicks: Int = 0
    private var percent: Int = 0

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
        startTime = Date()
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

    func bumpCompile() {
        compileTicks += 1
        // Heuristic: each compile tick advances ~0.5% up to 90%
        let base = min(90, 10 + (compileTicks / 2))
        percent = max(percent, base)
    }

    private func tick() {
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let frame = spinnerFrames[spinnerIndex % spinnerFrames.count]
        spinnerIndex += 1
        // Phase-based baseline percent when no compile ticks
        if currentStatus.hasPrefix("Resolving") { percent = max(percent, 10) }
        else if currentStatus.hasPrefix("Fetching") || currentStatus.hasPrefix("Updating") { percent = max(percent, 15) }
        else if currentStatus.hasPrefix("Linking") { percent = max(percent, 95) }
        else if currentStatus.hasPrefix("Running") { percent = max(percent, 98) }
        if isTTY {
            fputs("\r\u{001B}[2K\(frame) \(title): \(lastStatus) \(percent)% (\(elapsed)s)", stderr)
            fflush(stderr)
        } else {
            // Non-TTY: emit a line every 3 seconds
            if spinnerIndex % 15 == 0 { fputs("… \(title.lowercased()) — \(lastStatus) \(percent)% (\(elapsed)s)\n", stderr) }
        }
    }

    // Test hook to drive coverage deterministically
    func testTick() { tick() }

    func stop(final: Bool, elapsed: TimeInterval? = nil) {
        guard enabled else { return }
        timer?.cancel()
        if isTTY { fputs("\r\u{001B}[2K", stderr) }
        if final {
            let e = elapsed ?? Date().timeIntervalSince(startTime)
            let fmt = String(format: "%.2f", e)
            fputs("✓ \(title) completed in \(fmt)s\n", stderr)
        }
    }
}

// MARK: - MIDI Bridge (uses FountainAI SSEOverMIDI when available)

#if canImport(SSEOverMIDI)
import SSEOverMIDI
import MIDI2Core
import MIDI2Transports

final class MIDIBridge {
    private let session: RTPMidiSession
    private let sender: DefaultSseSender
    private let receiver: DefaultSseReceiver
    private let reliability = Reliability()

    init?(name: String) {
        let sess = RTPMidiSession(localName: name)
        let flex = FlexPacker()
        let sysx = SysEx8Packer()
        self.session = sess
        self.sender = DefaultSseSender(rtp: sess, flex: flex, sysx: sysx, rel: reliability)
        self.receiver = DefaultSseReceiver(rtp: sess, flex: flex, sysx: sysx, rel: reliability)
        do {
            try receiver.start() // opens the session; required for send path
        } catch {
            return nil
        }
    }

    static func make(name: String) -> MIDIBridge? { MIDIBridge(name: name) }

    func sendEvent(type: String, payload: [String: Any]) {
        var obj = payload
        obj["evt"] = type
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []),
              let json = String(data: data, encoding: .utf8) else { return }
        do {
            let env = SseEnvelope(ev: type, seq: 0, data: json)
            try sender.send(event: env)
            sender.flush()
        } catch {
            // ignore send errors in bridge
        }
    }

    deinit { sender.close() }
}
#elseif canImport(CoreMIDI)
import CoreMIDI
final class MIDIBridge {
    private var client = MIDIClientRef()
    private var source = MIDIEndpointRef()
    private let jsonMax = 180 // keep SysEx small
    init?(name: String) {
        var cl = MIDIClientRef()
        if MIDIClientCreateWithBlock(name as CFString, &cl, nil) != noErr { return nil }
        client = cl
        var src = MIDIEndpointRef()
        if MIDISourceCreate(client, name as CFString, &src) != noErr { return nil }
        source = src
    }
    static func make(name: String) -> MIDIBridge? { MIDIBridge(name: name) }
    func sendEvent(type: String, payload: [String: Any]) {
        var obj = payload
        obj["evt"] = type
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []), !data.isEmpty else { return }
        let clipped = Data(data.prefix(jsonMax))
        var bytes = [UInt8](repeating: 0, count: clipped.count + 3)
        bytes[0] = 0xF0 // SysEx start
        bytes[1] = 0x7D // Non-commercial manufacturer ID
        for (i, b) in clipped.enumerated() { bytes[i+2] = b & 0x7F }
        bytes[bytes.count - 1] = 0xF7 // SysEx end
        send(bytes: bytes)
    }
    private func send(bytes: [UInt8]) {
        let capacity = 512
        let plPointer = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: 1)
        defer { plPointer.deallocate() }
        var packet = MIDIPacketListInit(plPointer)
        packet = MIDIPacketListAdd(plPointer, capacity, packet, 0, bytes.count, bytes)
        MIDIReceived(source, plPointer)
    }
    deinit { if source != 0 { MIDIEndpointDispose(source) }; if client != 0 { MIDIClientDispose(client) } }
}
#else
final class MIDIBridge {
    static func make(name: String) -> MIDIBridge? { nil }
    func sendEvent(type: String, payload: [String: Any]) {}
}
#endif

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

// Categorize failure and provide a concise hint
func categorizeFailure(command: String, phase: String, code: Int32, sawTestFailure: Bool, sawLinkerError: Bool, sawResolveError: Bool, sawNetworkError: Bool, errors: [[String: Any]]) -> (String, String) {
    if code == 0 { return ("success", "") }
    // Heuristics
    if sawNetworkError || (phase == "fetching" && !errors.isEmpty) { return ("DEPENDENCY_NETWORK", "Check network and credentials. Try: `swift package resolve -v`. If behind a proxy, configure git and SwiftPM.") }
    if sawResolveError || phase == "resolving" { return ("RESOLVE_GRAPH", "Dependency resolution failed. Pin or update versions, then `swift package clean && swift package resolve -v`.") }
    if sawTestFailure || (command == "test" && phase == "testing") { return ("TEST", "Tests failed. Run `tutor test --verbose` for details; focus on the first failing test.") }
    if sawLinkerError || phase == "linking" { return ("LINK", "Linker error. Verify target dependencies and frameworks, clean build, and ensure module visibility.") }
    if phase == "compiling" || errors.contains(where: { ($0["file"] as? String)?.hasSuffix(".swift") == true }) {
        return ("COMPILE", "Compile error. Inspect the first error. Try `tutor build --verbose` to see the failing file and line.")
    }
    if command == "run" { return ("RUNTIME", "App crashed at runtime. Re-run with `tutor run --verbose` and check logs.") }
    return ("UNKNOWN", "Failure cause unclear. Re-run with `--verbose` and check `.tutor/events.ndjson` for clues.") }

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

// MARK: - Serve (HTTP + SSE)

extension TutorCLI {
    static func runDoctor(args: inout [String]) async {
        let (dir, _) = parseDir(args: &args)
        let tutorDir = (dir as NSString).appendingPathComponent(".tutor")
        try? FileManager.default.createDirectory(atPath: tutorDir, withIntermediateDirectories: true)
        let statusPath = (tutorDir as NSString).appendingPathComponent("status.json")
        let eventsPath = (tutorDir as NSString).appendingPathComponent("events.ndjson")
        if !FileManager.default.fileExists(atPath: statusPath) {
            _ = writeJSONAtomic(path: statusPath, object: [
                "title": "Doctor",
                "command": "build",
                "phase": "resolving",
                "elapsed": 0,
                "exitCode": 0
            ])
        }
        if !FileManager.default.fileExists(atPath: eventsPath) {
            _ = appendNDJSON(path: eventsPath, object: ["type": "log", "line": "init"]) 
        }
        let server = LocalHTTPServer(port: 0, statusPath: statusPath, eventsPath: eventsPath, token: nil, midiName: nil, socketPath: nil)
        let port = (try? server.start()) ?? 0
        if port == 0 { fputs("Doctor: failed to start server\n", stderr); exit(2) }
        func get(_ path: String, accept: String? = nil, timeout: TimeInterval = 3.0) -> (code: Int, body: Data) {
            let url = URL(string: "http://127.0.0.1:\(port)\(path)")!
            var req = URLRequest(url: url); if let a = accept { req.addValue(a, forHTTPHeaderField: "Accept") }
            final class Box: @unchecked Sendable { var code: Int = -1; var body: Data = Data() }
            let box = Box()
            let sem = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: req) { data, resp, _ in
                box.code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                box.body = data ?? Data()
                sem.signal()
            }
            task.resume()
            _ = sem.wait(timeout: .now() + timeout)
            return (box.code, box.body)
        }
        var ok = true
        // Health
        let h = get("/health"); print("/health -> \(h.code)")
        ok = ok && (h.code == 200)
        // Status
        let s = get("/status"); print("/status -> \(s.code)")
        ok = ok && (s.code == 200)
        // Summary
        let sum = get("/summary"); print("/summary -> \(sum.code)")
        ok = ok && (sum.code == 200)
        // SSE: subscribe and then write warning
        final class SSECap: NSObject, URLSessionDataDelegate, @unchecked Sendable { private(set) var saw = false
            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
                if let s = String(data: data, encoding: .utf8), s.contains("event: warning") { saw = true }
            } }
        let cap = SSECap()
        let session = URLSession(configuration: .default, delegate: cap, delegateQueue: .main)
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/events")!)
        req.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: req)
        task.resume()
        // Append an event after a short delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            _ = appendNDJSON(path: eventsPath, object: ["type": "warning", "warning": ["message": "be careful"]])
        }
        // Poll for up to 3 seconds
        var tries = 30; var sseOK = false
        while tries > 0 {
            if cap.saw { sseOK = true; break }
            usleep(100_000) // 0.1s
            tries -= 1
        }
        print("/events (sse) -> \(sseOK ? "OK" : "NO EVENT")")
        ok = ok && sseOK
        if ok { print("Doctor: OK"); exit(0) } else { fputs("Doctor: some checks failed\n", stderr); exit(1) }
    }
    static func runServe(args: inout [String]) {
        var port: Int = 53127
        var noAuth = false
        var dev = false
        var midiEnabled = false
        var midiName: String? = nil
        var socketPath: String? = nil
        if let idx = args.firstIndex(of: "--port"), idx + 1 < args.count, let p = Int(args[idx+1]) { port = p; args.removeSubrange(idx...(idx+1)) }
        if let idx = args.firstIndex(of: "--no-auth") { noAuth = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--dev") { dev = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--socket"), idx + 1 < args.count { socketPath = args[idx+1]; args.removeSubrange(idx...(idx+1)) }
        if let idx = args.firstIndex(of: "--midi") { midiEnabled = true; args.remove(at: idx) }
        if let idx = args.firstIndex(of: "--midi-virtual-name"), idx + 1 < args.count { midiName = args[idx+1]; args.removeSubrange(idx...(idx+1)) }
        let (dir, _) = parseDir(args: &args)

        let tutorDir = (dir as NSString).appendingPathComponent(".tutor")
        try? FileManager.default.createDirectory(atPath: tutorDir, withIntermediateDirectories: true)
        let statusPath = (tutorDir as NSString).appendingPathComponent("status.json")
        let eventsPath = (tutorDir as NSString).appendingPathComponent("events.ndjson")
        let tokenPath = (tutorDir as NSString).appendingPathComponent("token")

        var token: String? = nil
        if !(noAuth || dev) {
            token = (try? String(contentsOfFile: tokenPath))?.trimmingCharacters(in: .whitespacesAndNewlines)
            if token == nil || token!.isEmpty {
                token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                try? token!.write(to: URL(fileURLWithPath: tokenPath), atomically: true, encoding: .utf8)
            }
        }

        let server = LocalHTTPServer(port: port, statusPath: statusPath, eventsPath: eventsPath, token: token, midiName: midiEnabled ? (midiName ?? "TutorCLI") : nil, socketPath: socketPath)
        do {
            let actualPort = try server.start()
            if let sp = socketPath { print("Serving SSE on unix://\(sp)") }
            if actualPort > 0 {
                if let token { print("Serving on http://127.0.0.1:\(actualPort)  token=\(token)") }
                else { print("Serving on http://127.0.0.1:\(actualPort) (auth disabled)") }
                print("Endpoints: /health, /status, /summary, /events | Use 'tutor viewer' for native UI")
            }
            // Keep process alive indefinitely (simple, robust)
            while true { Thread.sleep(forTimeInterval: 60) }
        } catch {
            fputs("Failed to start server: \(error)\n", stderr)
            exit(1)
        }
    }
}

extension TutorCLI {
    static func runViewer(args: inout [String]) {
        let (dir, _) = parseDir(args: &args)
        var env = ProcessInfo.processInfo.environment
        env["TUTOR_DIR"] = dir
        let viewerPath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent("tools/teatro-viewer")
        // Spawn: swift run --disable-sandbox (Teatro viewer)
        let code = runProcess(launchPath: "/usr/bin/swift",
                              args: ["run", "--disable-sandbox"],
                              cwd: viewerPath,
                              showProgress: true,
                              title: "Viewer",
                              echoOutput: true,
                              statusFile: nil,
                              eventFile: nil,
                              command: "run",
                              jsonSummary: false,
                              ciMode: false,
                              midiEnabled: false,
                              midiName: nil,
                              extraEnv: ["TUTOR_DIR": dir])
        if code != 0 { exit(code) }
    }
}

final class LocalHTTPServer: @unchecked Sendable {
    private let port: Int
    private let statusPath: String
    private let eventsPath: String
    private let token: String?
    private let midi: MIDIBridge?
    private let socketPath: String?
    init(port: Int, statusPath: String, eventsPath: String, token: String?, midiName: String?, socketPath: String?) {
        self.port = port
        self.statusPath = statusPath
        self.eventsPath = eventsPath
        self.token = token
        if let name = midiName { self.midi = MIDIBridge.make(name: name) } else { self.midi = nil }
        self.socketPath = socketPath
    }
    enum ServeError: Error { case failedToBind }
    func start() throws -> Int {
#if canImport(Network)
        let p = try startNW()
        if let sp = socketPath { try startUnix(at: sp) }
        return p
#else
        if let sp = socketPath { try startUnix(at: sp); return 0 }
        return try startPOSIX()
#endif
    }

    // Fallback very tiny POSIX server not implemented for brevity in non-Apple platforms
    private func startPOSIX() throws -> Int { throw ServeError.failedToBind }

    #if canImport(Network)
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    private func startNW() throws -> Int {
        let params = NWParameters.tcp
        let p: NWEndpoint.Port = (port == 0 ? .any : NWEndpoint.Port(rawValue: UInt16(port))!)
        let l = try NWListener(using: params, on: p)
        listener = l
        l.newConnectionHandler = { [weak self] conn in self?.setupConnection(conn) }
        l.start(queue: .main)
        Thread.sleep(forTimeInterval: 0.2)
        let portValue = l.port?.rawValue ?? UInt16(self.port)
        return Int(portValue)
    }

    private func setupConnection(_ conn: NWConnection) {
        let id = ObjectIdentifier(conn)
        connections[id] = conn
        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .failed = state { self.connections.removeValue(forKey: id) }
            if case .cancelled = state { self.connections.removeValue(forKey: id) }
        }
        conn.start(queue: .global())
        receiveRequest(on: conn, buffer: Data())
    }

    private func receiveRequest(on conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 32 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var buf = buffer
            if let d = data { buf.append(d) }
            if error != nil { self.close(conn); return }
            if isComplete { self.close(conn); return }

            if let range = buf.range(of: Data("\r\n\r\n".utf8)) {
                let headerData = buf.subdata(in: 0..<range.lowerBound)
                let bodyData = buf.subdata(in: range.upperBound..<buf.count)
                self.handleRequest(conn: conn, headers: headerData, body: bodyData)
            } else {
                self.receiveRequest(on: conn, buffer: buf)
            }
        }
    }

    private func handleRequest(conn: NWConnection, headers: Data, body: Data) {
        guard let head = String(data: headers, encoding: .utf8) else { return close(conn) }
        let lines = head.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard let requestLine = lines.first else { return close(conn) }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return close(conn) }
        let method = String(parts[0])
        let urlPath = String(parts[1])

        var authOK = (token == nil)
        if let token {
            if let hdr = lines.first(where: { $0.lowercased().hasPrefix("authorization:") }) {
                let v = hdr.split(separator: ":", maxSplits: 1).last.map(String.init) ?? ""
                if v.lowercased().contains("bearer") && v.trimmingCharacters(in: .whitespaces).hasSuffix(token) { authOK = true }
            }
        }
        if !authOK { return respond(conn, status: 401, headers: ["Content-Type": "application/json"], body: Data("{\"error\":\"unauthorized\"}".utf8)) }

        switch (method, urlPath) {
        case ("GET", "/"):
            let json = "{""message"":""Tutor Serve — Use /health, /status, /summary, /events; run 'tutor viewer' for native UI""}"
            respond(conn, status: 200, headers: ["Content-Type": "application/json"], body: Data(json.utf8))
        case ("GET", "/health"):
            respond(conn, status: 200, headers: ["Content-Type": "application/json"], body: Data("{\"ok\":true}".utf8))
        case ("GET", "/status"):
            if let data = FileManager.default.contents(atPath: statusPath) {
                respond(conn, status: 200, headers: ["Content-Type": "application/json"], body: data)
            } else {
                respond(conn, status: 404, headers: ["Content-Type": "application/json"], body: Data("{\"error\":\"no status\"}".utf8))
            }
        // No browser UIs served; minimal agent endpoints only
        case ("GET", "/summary"):
            let sum = makeSummary(statusPath: statusPath, eventsPath: eventsPath)
            if let data = try? JSONSerialization.data(withJSONObject: sum, options: [.prettyPrinted]) {
                respond(conn, status: 200, headers: ["Content-Type": "application/json"], body: data)
                // Also broadcast via MIDI
                self.midi?.sendEvent(type: "summary", payload: sum)
            } else {
                respond(conn, status: 500, headers: ["Content-Type": "application/json"], body: Data("{\"error\":\"cannot summarize\"}".utf8))
            }
        case ("GET", "/events"):
            sse(conn: conn)
        default:
            respond(conn, status: 404, headers: ["Content-Type": "application/json"], body: Data("{\"error\":\"not found\"}".utf8))
        }
    }

    private func respond(_ conn: NWConnection, status: Int, headers: [String: String], body: Data) {
        var head = "HTTP/1.1 \(status) \(status == 200 ? "OK" : "ERR")\r\n"
        var hdrs = headers
        hdrs["Content-Length"] = String(body.count)
        hdrs["Connection"] = "close"
        for (k, v) in hdrs { head += "\(k): \(v)\r\n" }
        head += "\r\n"
        let out = Data(head.utf8) + body
        conn.send(content: out, completion: .contentProcessed { [weak self] _ in self?.close(conn) })
    }

    private func sse(conn: NWConnection) {
        let head = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\n\r\n"
        conn.send(content: Data(head.utf8), completion: .contentProcessed { _ in })
        // Send initial status if available
        if let data = FileManager.default.contents(atPath: statusPath), let text = String(data: data, encoding: .utf8) {
            self.sendSSE(conn: conn, event: "status", data: text + "\n\n")
        } else {
            // Send a comment to open the stream
            self.sendSSE(conn: conn, event: nil, data: ":ok\n\n")
        }

        // Start polling the events file
        let url = URL(fileURLWithPath: eventsPath)
        var lastSize: UInt64 = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: eventsPath), let n = attrs[.size] as? NSNumber { lastSize = n.uint64Value }
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now(), repeating: .milliseconds(500))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: self.eventsPath), let n = attrs[.size] as? NSNumber else { return }
            let size = n.uint64Value
            if size > lastSize {
                // Read new bytes
                if let h = try? FileHandle(forReadingFrom: url) {
                    defer { try? h.close() }
                    try? h.seek(toOffset: lastSize)
                    if let data = try? h.readToEnd(), let text = String(data: data, encoding: .utf8) {
                        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                            if line.isEmpty { continue }
                            let s = String(line)
                            // Peek type if present
                            var evt = "log"
                            if let obj = try? JSONSerialization.jsonObject(with: Data(s.utf8)) as? [String: Any], let t = obj["type"] as? String {
                                evt = t
                                self.sendSSE(conn: conn, event: evt, data: s + "\n\n")
                                self.midi?.sendEvent(type: evt, payload: obj)
                            } else {
                                self.sendSSE(conn: conn, event: evt, data: s + "\n\n")
                            }
                        }
                    }
                }
                lastSize = size
            }
        }
        timer.resume()
        // Keep the connection open; if it fails, cancel timer
        conn.stateUpdateHandler = { state in
            switch state {
            case .failed, .cancelled:
                timer.cancel()
            default: break
            }
        }
    }

    private func sendSSE(conn: NWConnection, event: String?, data: String) {
        var payload = ""
        if let e = event { payload += "event: \(e)\n" }
        payload += "data: "
        payload += data.replacingOccurrences(of: "\n", with: "\ndata: ")
        if !payload.hasSuffix("\n\n") { payload += "\n\n" }
        conn.send(content: Data(payload.utf8), completion: .contentProcessed { _ in })
    }

    private func close(_ conn: NWConnection) { conn.cancel() }
    #endif

    // MARK: Unix domain socket SSE
    private func startUnix(at path: String) throws {
        // Basic AF_UNIX stream socket broadcasting SSE lines (no HTTP headers)
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw ServeError.failedToBind }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxPath = MemoryLayout.size(ofValue: addr.sun_path)
        unlink(path)
        let bytes = Array(path.utf8)
        guard bytes.count < maxPath else { throw ServeError.failedToBind }
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let buf = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
            for (i, b) in bytes.enumerated() { buf[i] = b }
            buf[bytes.count] = 0
        }
        let len = socklen_t(MemoryLayout.size(ofValue: addr.sun_family) + bytes.count + 1)
        let bindRes = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, len) }
        }
        guard bindRes == 0, listen(fd, 8) == 0 else { _ = Darwin.close(fd); throw ServeError.failedToBind }
        let q = DispatchQueue.global()
        q.async {
            while true {
                var clientAddr = sockaddr()
                var clen: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
                let cfd = withUnsafeMutablePointer(to: &clientAddr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { accept(fd, $0, &clen) }
                }
                if cfd < 0 { continue }
                self.streamEventsPOSIX(fd: cfd)
            }
        }
    }

    private func streamEventsPOSIX(fd: Int32) {
        // Write initial status if available
        if let data = FileManager.default.contents(atPath: statusPath), let text = String(data: data, encoding: .utf8) {
            _ = text.withCString { cstr in write(fd, cstr, strlen(cstr)) }
            _ = write(fd, "\n\n", 2)
        }
        let url = URL(fileURLWithPath: eventsPath)
        var lastSize: UInt64 = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: eventsPath), let n = attrs[.size] as? NSNumber { lastSize = n.uint64Value }
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now(), repeating: .milliseconds(500))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: self.eventsPath), let n = attrs[.size] as? NSNumber else { return }
            let size = n.uint64Value
            if size > lastSize {
                if let h = try? FileHandle(forReadingFrom: url) {
                    defer { try? h.close() }
                    try? h.seek(toOffset: lastSize)
                    if let data = try? h.readToEnd(), let text = String(data: data, encoding: .utf8) {
                        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                            if line.isEmpty { continue }
                            let s = String(line) + "\n\n"
                            _ = s.withCString { cstr in write(fd, cstr, strlen(cstr)) }
                            if let obj = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any], let t = obj["type"] as? String {
                                self.midi?.sendEvent(type: t, payload: obj)
                            }
                        }
                    }
                }
                lastSize = size
            }
        }
        timer.resume()
    }
}

// Load embedded OpenAPI resources from SPM bundle
func loadOpenAPI(path: String) -> Data? {
    #if SWIFT_PACKAGE
    let bundle = Bundle.module
    if let url = bundle.url(forResource: path, withExtension: nil, subdirectory: "OpenAPI") {
        return try? Data(contentsOf: url)
    }
    #endif
    // Fallbacks for test/runtime environments where resources may not be bundled as expected
    let fm = FileManager.default
    let candidates = [
        "tools/tutor-cli/Sources/TutorCLI/OpenAPI/\(path)",
        "Sources/TutorCLI/OpenAPI/\(path)",
        "../Sources/TutorCLI/OpenAPI/\(path)",
        "../../Sources/TutorCLI/OpenAPI/\(path)",
        "../../../Sources/TutorCLI/OpenAPI/\(path)",
    ]
    for c in candidates {
        if fm.fileExists(atPath: c) { return try? Data(contentsOf: URL(fileURLWithPath: c)) }
    }
    let docs = [
        "docs/openapi/\(path)",
        "./docs/openapi/\(path)",
        "../../docs/openapi/\(path)",
        "../../../docs/openapi/\(path)",
        "../../../../docs/openapi/\(path)",
    ]
    for c in docs {
        if fm.fileExists(atPath: c) { return try? Data(contentsOf: URL(fileURLWithPath: c)) }
    }
    return nil
}

// Offline-friendly docs fallback HTML
func docsLiteHTML() -> String {
    return """
    <!doctype html><html><head><meta charset=\"utf-8\"><title>Tutor Serve API (Lite)</title>
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <style>body{font-family:-apple-system,system-ui,Segoe UI,Roboto,Helvetica,Arial,sans-serif;margin:1rem} pre{white-space:pre-wrap;word-wrap:break-word;background:#f6f8fa;padding:1rem;border-radius:8px}</style>
    </head><body>
    <h1>Tutor Serve API (Lite)</h1>
    <p>This minimal view fetches the OpenAPI spec served by the CLI and renders it as text. Use <code>/docs</code> or <code>/redoc</code> for full UI (requires CDN access). If those fail, this page still works offline.</p>
    <pre id=\"spec\">Loading /openapi.yaml ...</pre>
    <script>
    fetch('/openapi.yaml')
      .then(r=>r.text())
      .then(t=>{document.getElementById('spec').textContent=t})
      .catch(e=>{document.getElementById('spec').textContent='Failed to load: '+e});
    </script>
    </body></html>
    """
}

// Build a summary from status + events files (mirrors --json-summary output)
func makeSummary(statusPath: String, eventsPath: String) -> [String: Any] {
    var status: [String: Any] = [:]
    if let data = FileManager.default.contents(atPath: statusPath), let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { status = obj }
    let title = (status["title"] as? String) ?? "Work"
    let command = (status["command"] as? String) ?? ""
    let phase = (status["phase"] as? String) ?? ""
    let elapsed = (status["elapsed"] as? Int) ?? 0
    let exitCode = (status["exitCode"] as? Int) ?? 0

    var errors: [[String: Any]] = (status["errors"] as? [[String: Any]]) ?? []
    var warnings: [[String: Any]] = (status["warnings"] as? [[String: Any]]) ?? []

    // Augment with any events in NDJSON
    if let data = FileManager.default.contents(atPath: eventsPath), let text = String(data: data, encoding: .utf8) {
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let obj = try? JSONSerialization.jsonObject(with: Data(String(line).utf8)) as? [String: Any] else { continue }
            if let e = obj["error"] as? [String: Any] { errors.append(e) }
            if let w = obj["warning"] as? [String: Any] { warnings.append(w) }
        }
    }

    let sawTestFailure = false // could be derived by scanning events for test fails
    let sawLinkerError = errors.contains { ($0["message"] as? String)?.localizedCaseInsensitiveContains("linker command failed") == true || ($0["message"] as? String)?.localizedCaseInsensitiveContains("Undefined symbols") == true }
    let sawResolveError = errors.contains { ($0["message"] as? String)?.localizedCaseInsensitiveContains("resolve") == true }
    let sawNetworkError = errors.contains { ($0["message"] as? String)?.localizedCaseInsensitiveContains("network") == true || ($0["message"] as? String)?.localizedCaseInsensitiveContains("timed out") == true }

    let (category, hint) = categorizeFailure(command: command, phase: phase, code: Int32(exitCode), sawTestFailure: sawTestFailure, sawLinkerError: sawLinkerError, sawResolveError: sawResolveError, sawNetworkError: sawNetworkError, errors: errors)
    return [
        "title": title,
        "command": command,
        "phase": phase,
        "elapsed": elapsed,
        "exitCode": exitCode,
        "category": category,
        "hint": hint,
        "errorCount": errors.count,
        "warningCount": warnings.count,
        "errors": errors,
        "warnings": warnings
    ]
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
