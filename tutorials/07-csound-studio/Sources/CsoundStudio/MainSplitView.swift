import SwiftUI

struct MainSplitView: View {
    @State private var csdText: String = ""
    @State private var status: String = "Drop a .csd on the right, or ask the AI to draft one."

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
        }
    }
}

struct MainSplitView_Previews: PreviewProvider {
    static var previews: some View { MainSplitView() }
}

