import SwiftUI

@main
struct CsoundStudioApp: App {
    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .frame(minWidth: 900, minHeight: 600)
        }
    }
}

