import SwiftUI
import CsoundStudioCore

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
    @State private var provisionLog: String = ""
    // Provisioning (Toolsmith)
    @State private var confirmProvision = false
    @State private var provisioning = false
    @State private var provisioningProcess: Process?
    @State private var showProvisionSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.title2)
            Form {
                Section("Gateway") {
                    TextField("Gateway URL", text: $settings.gatewayURL)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .font(.system(size: 14))
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity)
                    SecureField("Gateway Token (FOUNTAIN_AI_KEY)", text: $settings.apiToken)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .font(.system(size: 14))
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity)
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
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .font(.system(size: 14))
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity)
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
                Section("Toolsmith (Optional)") {
                    Toggle("Use Toolsmith VM for Engraving/Synthesis", isOn: $settings.useToolsmithVM)
                    TextField("Tool VM Image Path (.qcow2/.img)", text: $settings.toolImagePath)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .font(.system(size: 14))
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity)
                    HStack(spacing: 12) {
                        Button("Prepare Toolsmith VM…") { confirmProvision = true }
                        if provisioning { ProgressView().scaleEffect(0.8) }
                    }
                    #if canImport(SandboxRunner)
                    Text("Toolsmith Sandbox available at build time.")
                        .font(.footnote).foregroundStyle(.secondary)
                    #else
                    Text("Build without Toolsmith; enable by adding the Toolsmith package (SandboxRunner/QemuRunner). Feature is safe to leave toggled for future builds.")
                        .font(.footnote).foregroundStyle(.secondary)
                    #endif
                }
            }
            .formStyle(.grouped)
            if let note { Text(note).font(.footnote).foregroundStyle(.secondary) }
            HStack { Spacer(); Button("Close") { dismiss() } }
        }
        .padding()
        .task { await checkNow() }
        .alert("Prepare Toolsmith VM?", isPresented: $confirmProvision) {
            Button("Cancel", role: .cancel) {}
            Button("Agree & Run") { startProvision() }
        } message: {
            Text("This will download an Ubuntu image (~1GB) and install LilyPond + Csound inside a local VM. You can cancel anytime.")
        }
        .sheet(isPresented: $showProvisionSheet) {
            VStack(spacing: 16) {
                Text("Provisioning Toolsmith VM…").font(.headline)
                ProgressView().scaleEffect(1.2)
                Text("Downloading base image and installing packages. This can take several minutes.")
                    .font(.footnote).foregroundStyle(.secondary)
                ScrollView {
                    Text(provisionLog.isEmpty ? "(waiting for output…)" : provisionLog)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                HStack { Spacer(); Button("Cancel") { cancelProvision() } }
            }
            .padding()
            .frame(minWidth: 420)
        }
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

    private func startProvision() {
        let script = findProvisionScript()
        guard let script else { note = "Provision script not found. Run from repo root or open README."; return }
        provisioning = true
        showProvisionSheet = true
        let process = Process()
        provisioningProcess = process
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script]
        let pipe = Pipe(); process.standardOutput = pipe; process.standardError = pipe
        provisionLog = ""
        let fh = pipe.fileHandleForReading
        fh.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                let chunk = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async { provisionLog.append(chunk) }
            }
        }
        Task {
            do {
                try process.run(); process.waitUntilExit()
                fh.readabilityHandler = nil
                let lines = provisionLog.split(separator: "\n").map(String.init)
                if let last = lines.last, last.hasPrefix("/") {
                    settings.toolImagePath = last
                    note = "Prepared Toolsmith VM: \(last)"
                    // Auto-verify inside VM
                    if ToolsmithIntegration.isAvailable() {
                        provisionLog.append("\nVerifying lilypond --version…\n")
                        let (lok, lout) = ToolsmithIntegration.verifyLilypond(imagePath: last)
                        provisionLog.append(lout + "\n")
                        provisionLog.append("\nVerifying csound --version…\n")
                        let (cok, cout) = ToolsmithIntegration.verifyCsound(imagePath: last)
                        provisionLog.append(cout + "\n")
                        let summary = "VM verify: lilypond=\(lok ? "OK" : "FAIL"), csound=\(cok ? "OK" : "FAIL")"
                        note = note.map { $0 + " — " + summary } ?? summary
                    }
                } else {
                    note = "Provisioning finished. Review console output for details."
                }
            } catch {
                note = "Provisioning failed: \(error.localizedDescription)"
            }
            provisioning = false
            showProvisionSheet = false
            provisioningProcess = nil
        }
    }

    private func cancelProvision() {
        provisioningProcess?.terminate()
        provisioning = false
        showProvisionSheet = false
        provisioningProcess = nil
        note = "Provisioning cancelled by user."
    }

    private func findProvisionScript() -> String? {
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let candidates = [
            // New excursus location (current directory)
            cwd.appendingPathComponent("Scripts/prepare-toolsmith-vm.sh").path,
            // New excursus absolute path from repo root
            cwd.appendingPathComponent("tutorials/01-hello-csound/excursus/csound-studio/Scripts/prepare-toolsmith-vm.sh").standardized.path,
            cwd.appendingPathComponent("../tutorials/01-hello-csound/excursus/csound-studio/Scripts/prepare-toolsmith-vm.sh").standardized.path,
            cwd.appendingPathComponent("../../tutorials/01-hello-csound/excursus/csound-studio/Scripts/prepare-toolsmith-vm.sh").standardized.path,
            // Legacy path (pre-move)
            cwd.appendingPathComponent("tutorials/07-csound-studio/Scripts/prepare-toolsmith-vm.sh").path,
            cwd.appendingPathComponent("../tutorials/07-csound-studio/Scripts/prepare-toolsmith-vm.sh").standardized.path,
            cwd.appendingPathComponent("../../tutorials/07-csound-studio/Scripts/prepare-toolsmith-vm.sh").standardized.path
        ]
        return candidates.first(where: { fm.isReadableFile(atPath: $0) })
    }
}
