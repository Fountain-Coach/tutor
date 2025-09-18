import Foundation
import SwiftUI

final class AppSettings: ObservableObject {
    @AppStorage("gatewayURL") var gatewayURL: String = "http://127.0.0.1:8080/api/v1" { willSet { objectWillChange.send() } }
    @AppStorage("apiToken") var apiToken: String = "" { willSet { objectWillChange.send() } }
    @AppStorage("openAIKey") var openAIKey: String = "" { willSet { objectWillChange.send() } }
}

