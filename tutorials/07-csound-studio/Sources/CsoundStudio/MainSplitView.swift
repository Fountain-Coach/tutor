import SwiftUI

struct MainSplitView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var csdText: String = ""
    @State private var status: String = "Drop a .csd on the right, or ask the AI to draft one."
    @State private var showSettings = false
    @State private var gatewayOK: Bool = false
    @State private var lilyOK: Bool = false

    var body: some View {
        GeometryReader { geo in
            HSplitView {
                ChatView(onInsert: { text in
                    csdText = text
                    status = "Inserted .csd from chat."
                })
                .frame(minWidth: geo.size.width * 0.45)

                DropZoneView(csdText: $csdText, status: $status)
                    .frame(minWidth: geo.size.width * 0.55)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Settings") { showSettings = true }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(gatewayOK: $gatewayOK, lilyOK: $lilyOK)
                    .environmentObject(settings)
                    .frame(minWidth: 520, minHeight: 380)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Label(gatewayOK ? "Gateway: OK" : "Gateway: Unavailable", systemImage: gatewayOK ? "checkmark.seal" : "exclamationmark.triangle")
                        .foregroundStyle(gatewayOK ? .green : .orange)
                    Label(lilyOK ? "LilyPond: Installed" : "LilyPond: Missing", systemImage: lilyOK ? "music.note" : "xmark.octagon")
                        .foregroundStyle(lilyOK ? .green : .red)
                    Spacer()
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
                .padding(8)
                .background(.thinMaterial)
                .onAppear { Task { await refreshStatus() } }
            }
        }
    }

    func refreshStatus() async {
        gatewayOK = await SystemCheck.gatewayHealthy(urlString: settings.gatewayURL)
        lilyOK = SystemCheck.lilypondInstalled()
    }
}

struct MainSplitView_Previews: PreviewProvider {
    static var previews: some View { MainSplitView() }
}
