import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct DropZoneView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var csdText: String
    @Binding var status: String
    @Binding var lilyOK: Bool
    @State private var isTargeted = false
    @State private var copiedNote: String?

    private var lyPreview: String {
        LilyPondExporter.makeLily(from: csdText, tempoBPM: 120)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drop • Play • Export").font(.title2)
            HStack(spacing: 8) {
                Button("Play") { playCSD() }.disabled(csdText.isEmpty)
                Button("Export Score (.ly)") { exportLily() }.disabled(csdText.isEmpty)
                Button("Engrave PDF") { engravePDF() }.disabled(csdText.isEmpty)
            }
            Text(status)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
            if !lilyOK {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Copy-Ready LilyPond (.ly) — LilyPond Not Installed", systemImage: "doc.on.doc")
                            .font(.headline)
                        Spacer()
                        Button("Copy .ly") { copy(lyPreview) }
                    }
                    TextEditor(text: .constant(lyPreview))
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, minHeight: 140)
                        .disabled(true)
                        .background(Color.gray.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(6)
                    if let copiedNote { Text(copiedNote).font(.footnote).foregroundStyle(.secondary) }
                }
                .padding(.vertical, 4)
            }
            TextEditor(text: $csdText)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isTargeted ? Color.accentColor : Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
                .padding(.top, 4)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                }
        }
        .padding(8)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let p = providers.first, p.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { return false }
        p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, _) in
            let url = (item as? URL)
            DispatchQueue.main.async {
                if let url, url.pathExtension.lowercased() == "csd", let txt = try? String(contentsOf: url) {
                    self.csdText = txt
                    self.status = "Loaded: \(url.lastPathComponent)"
                }
            }
        }
        return true
    }

    private func playCSD() {
        // Prefer Toolsmith VM if configured
        if settings.useToolsmithVM, !settings.toolImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, ToolsmithIntegration.isAvailable() {
            let (ok, wav, note) = ToolsmithIntegration.synthesizeCsdToWav(csdText: csdText, imagePath: settings.toolImagePath)
            if ok, let wav { playFile(url: wav); status = note }
            else { status = note }
            return
        }
        // Fallback to simulator
        do {
            let result = try CsoundPlayer().play(csd: csdText)
            try play(samples: result.samples, sampleRate: result.sampleRate, seconds: result.durationSeconds)
            status = "Played audio (\(result.samples.count) samples)"
        } catch {
            status = "Error: \(error)"
        }
    }

    private func exportLily() {
        let ly = LilyPondExporter.makeLily(from: csdText, tempoBPM: 120)
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("composition.ly")
        do { try ly.write(to: url, atomically: true, encoding: .utf8); status = "Wrote: \(url.lastPathComponent)" }
        catch { status = "Write failed: \(error)" }
    }

    private func engravePDF() {
        let lyURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("composition.ly")
        guard FileManager.default.fileExists(atPath: lyURL.path) else { status = "No composition.ly — export first"; return }
        if lilyOK {
            let ok = LilyPondExporter.engrave(lyURL: lyURL)
            status = ok ? "Engraved PDF via lilypond" : "Engrave failed — see console/logs"
            return
        }
        // Try Toolsmith VM if configured
        if settings.useToolsmithVM, !settings.toolImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, ToolsmithIntegration.isAvailable() {
            let (ok, note) = ToolsmithIntegration.engraveLily(lyURL: lyURL, imagePath: settings.toolImagePath)
            status = note
            if !ok { status += " — falling back to .ly only" }
        } else {
            status = "lilypond not available — used .ly only"
        }
    }

    private func copy(_ text: String) {
#if canImport(AppKit)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        copiedNote = "Copied .ly to clipboard."
#else
        copiedNote = "Copy unsupported on this platform."
#endif
    }
}

import UniformTypeIdentifiers
