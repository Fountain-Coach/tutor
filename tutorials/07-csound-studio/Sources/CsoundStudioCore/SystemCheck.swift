import Foundation

public enum SystemCheck {
    public static func lilypondInstalled() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["lilypond", "--version"]
        let pipe = Pipe(); task.standardOutput = pipe; task.standardError = pipe
        do { try task.run(); task.waitUntilExit(); return task.terminationStatus == 0 } catch { return false }
    }

    public static func gatewayHealthy(urlString: String) async -> Bool {
        var base = urlString
        if base.hasSuffix("/") { base.removeLast() }
        guard let url = URL(string: base.replacingOccurrences(of: "/api/v1", with: "") + "/health") else { return false }
        var req = URLRequest(url: url); req.httpMethod = "GET"; req.timeoutInterval = 3
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    public static func startGateway(openAIKey: String, urlString: String) -> (Bool, String) {
        // Try to locate Scripts/run-gateway-source.sh by walking up to 3 levels
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let candidates = [
            cwd.appendingPathComponent("Scripts/run-gateway-source.sh").path,
            cwd.appendingPathComponent("../../Scripts/run-gateway-source.sh").standardized.path,
            cwd.appendingPathComponent("../Scripts/run-gateway-source.sh").standardized.path
        ]
        guard let script = candidates.first(where: { fm.isReadableFile(atPath: $0) }) else {
            return (false, "Could not locate Scripts/run-gateway-source.sh. Run from the repo checkout.")
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [script, "start", "--dev", "--no-auth"]
        var env = ProcessInfo.processInfo.environment
        if !openAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            env["OPENAI_API_KEY"] = openAIKey
        }
        task.environment = env
        let pipe = Pipe(); task.standardOutput = pipe; task.standardError = pipe
        do { try task.run(); task.waitUntilExit() } catch { return (false, "Failed to start Gateway: \(error)") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8) ?? ""
        let ok = task.terminationStatus == 0
        return (ok, ok ? "Gateway start attempted. Check status/health." : "Gateway exited with code \(task.terminationStatus). See logs.\n\(out)")
    }

    public static func openGatewayLogs() -> Bool {
        // Try to open .tutor/gateway.log from repo root by walking up
        let fm = FileManager.default
        var dir = URL(fileURLWithPath: fm.currentDirectoryPath)
        for _ in 0..<4 {
            let log = dir.appendingPathComponent(".tutor/gateway.log").path
            if fm.isReadableFile(atPath: log) {
                let task = Process(); task.executableURL = URL(fileURLWithPath: "/usr/bin/open"); task.arguments = [log]
                do { try task.run(); return true } catch { return false }
            }
            dir.deleteLastPathComponent()
        }
        return false
    }

    public static func stopGateway() -> Bool {
        // Look for .tutor/gateway.pid and kill it gracefully
        let fm = FileManager.default
        var dir = URL(fileURLWithPath: fm.currentDirectoryPath)
        for _ in 0..<4 {
            let pidPath = dir.appendingPathComponent(".tutor/gateway.pid").path
            if let pidStr = try? String(contentsOfFile: pidPath).trimmingCharacters(in: .whitespacesAndNewlines), !pidStr.isEmpty {
                let task = Process(); task.executableURL = URL(fileURLWithPath: "/bin/kill"); task.arguments = [pidStr]
                do { try task.run(); task.waitUntilExit(); return task.terminationStatus == 0 } catch { return false }
            }
            dir.deleteLastPathComponent()
        }
        return false
    }
}
