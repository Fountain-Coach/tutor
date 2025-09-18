import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Binding var gatewayOK: Bool
    @Binding var lilyOK: Bool
    @State private var checking = false
    @State private var starting = false
    @State private var stopping = false
    @State private var openingLogs = false
    @State private var note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.title2)
            Form {
                Section("Gateway") {
                    TextField("Gateway URL", text: $settings.gatewayURL)
                        .disableAutocorrection(true)
                    SecureField("Gateway Token (FOUNTAIN_AI_KEY)", text: $settings.apiToken)
                    HStack(spacing: 12) {
                        Button(checking ? "Checking…" : "Check") { Task { await checkNow() } }
                            .disabled(checking)
                        if checking { ProgressView().scaleEffect(0.7) }
                        Label(gatewayOK ? "OK" : "Unavailable", systemImage: gatewayOK ? "checkmark.seal" : "exclamationmark.triangle")
                            .foregroundStyle(gatewayOK ? .green : .orange)
                        Spacer()
                    }
                    HStack(spacing: 12) {
                        Button(starting ? "Starting…" : "Start Gateway") { Task { await startGateway() } }
                            .disabled(starting)
                        if starting { ProgressView().scaleEffect(0.7) }
                        Button(stopping ? "Stopping…" : "Stop Gateway") {
                            stopping = true
                            Task {
                                let ok = SystemCheck.stopGateway()
                                gatewayOK = await SystemCheck.gatewayHealthy(urlString: settings.gatewayURL)
                                note = ok ? "Sent stop signal to Gateway" : "Could not stop Gateway (no pid?)"
                                stopping = false
                            }
                        }.disabled(stopping)
                        Button(openingLogs ? "Opening…" : "Open Logs") {
                            openingLogs = true
                            Task {
                                _ = SystemCheck.openGatewayLogs()
                                openingLogs = false
                            }
                        }.disabled(openingLogs)
                    }
                }
                Section("Provider (OpenAI)") {
                    SecureField("OPENAI_API_KEY (used by local Gateway)", text: $settings.openAIKey)
                    Text("Note: The Gateway reads this key from its own process environment. Update your shell and restart the Gateway to apply.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Engraving") {
                    HStack {
                        Button(checking ? "Checking…" : "Check LilyPond") { Task { await checkNow() } }.disabled(checking)
                        Label(lilyOK ? "Installed" : "Missing", systemImage: lilyOK ? "music.note" : "xmark.octagon")
                            .foregroundStyle(lilyOK ? .green : .red)
                    }
                    Text("Install LilyPond from lilypond.org or your package manager. Export still writes .ly if LilyPond is missing.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let note { Text(note).foregroundStyle(.secondary) }
            HStack { Spacer(); Button("Close") { /* dismissed by parent */ } }
        }
        .padding()
        .task { await checkNow() }
    }

    func checkNow() async {
        checking = true; defer { checking = false }
        gatewayOK = await SystemCheck.gatewayHealthy(urlString: settings.gatewayURL)
        lilyOK = SystemCheck.lilypondInstalled()
        note = "Refreshed at \(Date().formatted(date: .omitted, time: .shortened))"
    }
    func startGateway() async {
        starting = true; defer { starting = false }
        let (_, msg) = SystemCheck.startGateway(openAIKey: settings.openAIKey, urlString: settings.gatewayURL)
        note = msg
        gatewayOK = await SystemCheck.gatewayHealthy(urlString: settings.gatewayURL)
    }
}
