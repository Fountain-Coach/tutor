import XCTest
@testable import TutorCLI

final class OpenAPIDocsTests: XCTestCase {
    func testOpenAPIAndDocsLiteServe() async throws {
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let statusPath = tmpDir.appendingPathComponent("status.json").path
        let eventsPath = tmpDir.appendingPathComponent("events.ndjson").path
        _ = writeJSONAtomic(path: statusPath, object: ["title": "Docs", "command": "build", "phase": "resolving", "elapsed": 0, "exitCode": 0])
        _ = appendNDJSON(path: eventsPath, object: ["type": "log", "line": "init"]) 

        let server = LocalHTTPServer(port: 0, statusPath: statusPath, eventsPath: eventsPath, token: nil, midiName: nil, socketPath: nil)
        let port = try server.start()

        // OpenAPI spec
        let yurl = URL(string: "http://127.0.0.1:\(port)/openapi.yaml")!
        let (ydata, yresp) = try await URLSession.shared.data(from: yurl)
        XCTAssertEqual((yresp as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertTrue(String(data: ydata, encoding: .utf8)?.contains("openapi:") == true)

        // Docs lite
        let durl = URL(string: "http://127.0.0.1:\(port)/docs-lite")!
        let (ddata, dresp) = try await URLSession.shared.data(from: durl)
        XCTAssertEqual((dresp as? HTTPURLResponse)?.statusCode, 200)
        let html = String(data: ddata, encoding: .utf8) ?? ""
        XCTAssertTrue(html.contains("Tutor Serve API (Lite)"))
    }
}

