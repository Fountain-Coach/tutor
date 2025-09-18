import SwiftUI

@main
struct CsoundStudioApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .environmentObject(settings)
                .frame(minWidth: 900, minHeight: 600)
        }
    }
}
