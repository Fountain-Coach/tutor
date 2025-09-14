import SwiftUI
import Foundation

@main
struct TeatroViewerApp: App {
    @StateObject private var model = Model()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear { model.startPolling() }
        }
    }
}

@MainActor
final class Model: ObservableObject {
    @Published var status: [String: Any] = [:]
    @Published var events: [[String: Any]] = []
    private var timer: Timer?
    private var lastSize: UInt64 = 0
    private var statusPath: String
    private var eventsPath: String

    init() {
        let base = ProcessInfo.processInfo.environment["TUTOR_DIR"] ?? FileManager.default.currentDirectoryPath
        statusPath = (base as NSString).appendingPathComponent(".tutor/status.json")
        eventsPath = (base as NSString).appendingPathComponent(".tutor/events.ndjson")
    }
    func startPolling() {
        timer?.invalidate()
        // Use selector-based timer to avoid @Sendable capture issues
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        poll()
    }
    @objc private func tick() { poll() }
    private func poll() {
        if let data = FileManager.default.contents(atPath: statusPath),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            self.status = obj
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: eventsPath), let n = attrs[.size] as? NSNumber {
            let size = n.uint64Value
            if size > lastSize, let h = try? FileHandle(forReadingFrom: URL(fileURLWithPath: eventsPath)) {
                defer { try? h.close() }
                try? h.seek(toOffset: lastSize)
                if let data = try? h.readToEnd(), let text = String(data: data, encoding: .utf8) {
                    let new = text.split(separator: "\n").compactMap { line -> [String: Any]? in
                        guard let d = line.data(using: .utf8),
                              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return nil }
                        return obj
                    }
                    self.events.append(contentsOf: new)
                }
                lastSize = size
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var model: Model
    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 320)
                .background(Color(nsColor: .windowBackgroundColor))
                .border(Color(nsColor: .separatorColor), width: 1)
            Divider()
            MainView()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var model: Model
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 8) {
            Text("Status").font(.headline).padding(.top, 8)
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    row("Command", model.status["command"] as? String)
                    row("Phase", model.status["phase"] as? String)
                    row("Elapsed", "\(model.status["elapsed"] as? Int ?? 0)s")
                    row("Exit Code", "\(model.status["exitCode"] as? Int ?? 0)")
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("Errors").font(.headline)
            let errs = (model.status["errors"] as? [[String: Any]]) ?? []
            ForEach(Array(errs.enumerated()), id: \.offset) { idx, e in
                GroupBox { Text(formatDiag(e)).font(.system(.body, design: .monospaced)) }
            }
            Spacer()
        }.padding(12) }
    }
    func row(_ k: String, _ v: String?) -> some View { HStack { Text(k).foregroundColor(.secondary); Spacer(); Text(v ?? "—") } }
    func formatDiag(_ d: [String: Any]) -> String {
        let f = d["file"] as? String ?? ""
        let l = d["line"] as? Int ?? 0
        let m = d["message"] as? String ?? ""
        return "\(f):\(l): \(m)"
    }
}

struct MainView: View {
    @EnvironmentObject var model: Model
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Events").font(.title2)
            ScrollView { VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(model.events.enumerated()), id: \.offset) { _, e in
                    GroupBox { Text(oneLine(e)).font(.system(.body, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading) }
                }
            }.frame(maxWidth: .infinity, alignment: .leading) }
            Spacer()
        }.padding(16)
    }
    func oneLine(_ e: [String: Any]) -> String {
        if let t = e["type"] as? String, t == "warning", let w = e["warning"] as? [String: Any], let m = w["message"] as? String {
            return "warning: \(m)"
        }
        if let t = e["type"] as? String, t == "error", let w = e["error"] as? [String: Any], let m = w["message"] as? String {
            return "error: \(m)"
        }
        return (try? String(data: JSONSerialization.data(withJSONObject: e), encoding: .utf8)) ?? String(describing: e)
    }
}
