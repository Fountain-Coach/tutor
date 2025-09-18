import SwiftUI

struct DropZoneView: View {
    @Binding var csdText: String
    @Binding var status: String
    @State private var isTargeted = false

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
        let ok = LilyPondExporter.engrave(lyURL: lyURL)
        status = ok ? "Engraved PDF via lilypond" : "lilypond not available — used .ly only"
    }
}

import UniformTypeIdentifiers
