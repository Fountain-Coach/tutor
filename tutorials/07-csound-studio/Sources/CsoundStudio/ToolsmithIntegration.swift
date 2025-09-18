import Foundation
#if canImport(SandboxRunner)
import SandboxRunner
#endif

enum ToolsmithIntegration {
    static func isAvailable() -> Bool {
        #if canImport(SandboxRunner)
        return true
        #else
        return false
        #endif
    }

    static func engraveLily(lyURL: URL, imagePath: String, timeout: TimeInterval = 90) -> (ok: Bool, note: String) {
        #if canImport(SandboxRunner)
        let runner = QemuRunner(image: URL(fileURLWithPath: imagePath))
        let work = lyURL.deletingLastPathComponent()
        do {
            let result = try runner.run(
                executable: "/usr/bin/lilypond",
                arguments: [lyURL.lastPathComponent],
                inputs: [],
                workDirectory: work,
                allowNetwork: false,
                timeout: timeout,
                limits: nil
            )
            let ok = (result.exitCode == 0)
            let note = ok ? "Engraved via Toolsmith VM" : "VM engrave failed (exit \(result.exitCode))\n\(result.stderr)"
            return (ok, note)
        } catch {
            return (false, "VM engrave error: \(error)")
        }
        #else
        return (false, "Toolsmith not available at build time")
        #endif
    }

    static func synthesizeCsdToWav(csdText: String, imagePath: String, timeout: TimeInterval = 90) -> (ok: Bool, wavURL: URL?, note: String) {
        #if canImport(SandboxRunner)
        let runner = QemuRunner(image: URL(fileURLWithPath: imagePath))
        let work = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("csound_vm_\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            let csdURL = work.appendingPathComponent("input.csd")
            try csdText.write(to: csdURL, atomically: true, encoding: .utf8)
            let outURL = work.appendingPathComponent("output.wav")
            let result = try runner.run(
                executable: "/usr/bin/csound",
                arguments: ["-o", outURL.lastPathComponent, csdURL.lastPathComponent],
                inputs: [],
                workDirectory: work,
                allowNetwork: false,
                timeout: timeout,
                limits: nil
            )
            let ok = (result.exitCode == 0) && FileManager.default.fileExists(atPath: outURL.path)
            let note = ok ? "Synthesized via Toolsmith VM" : "VM csound failed (exit \(result.exitCode))\n\(result.stderr)"
            return (ok, ok ? outURL : nil, note)
        } catch {
            return (false, nil, "VM synth error: \(error)")
        }
        #else
        return (false, nil, "Toolsmith not available at build time")
        #endif
    }

    static func verifyLilypond(imagePath: String, timeout: TimeInterval = 30) -> (ok: Bool, output: String) {
        #if canImport(SandboxRunner)
        let runner = QemuRunner(image: URL(fileURLWithPath: imagePath))
        let work = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("verify_vm_\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            let result = try runner.run(
                executable: "/usr/bin/lilypond",
                arguments: ["--version"],
                inputs: [],
                workDirectory: work,
                allowNetwork: false,
                timeout: timeout,
                limits: nil
            )
            let text = (result.stdout + "\n" + result.stderr).trimmingCharacters(in: .whitespacesAndNewlines)
            return (result.exitCode == 0 || !text.isEmpty, text)
        } catch { return (false, String(describing: error)) }
        #else
        return (false, "Toolsmith not available at build time")
        #endif
    }

    static func verifyCsound(imagePath: String, timeout: TimeInterval = 30) -> (ok: Bool, output: String) {
        #if canImport(SandboxRunner)
        let runner = QemuRunner(image: URL(fileURLWithPath: imagePath))
        let work = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("verify_vm_\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            let result = try runner.run(
                executable: "/usr/bin/csound",
                arguments: ["--version"],
                inputs: [],
                workDirectory: work,
                allowNetwork: false,
                timeout: timeout,
                limits: nil
            )
            let text = (result.stdout + "\n" + result.stderr).trimmingCharacters(in: .whitespacesAndNewlines)
            return (result.exitCode == 0 || !text.isEmpty, text)
        } catch { return (false, String(describing: error)) }
        #else
        return (false, "Toolsmith not available at build time")
        #endif
    }
}
