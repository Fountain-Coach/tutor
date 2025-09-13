import XCTest
@testable import TutorCLI

final class ServeIntegrationTests: XCTestCase {
    func testServeStatusAndSummary() async throws {
        guard ProcessInfo.processInfo.environment["TUTOR_INTEGRATION"] == "1" else {
            throw XCTSkip("Set TUTOR_INTEGRATION=1 to run integration serve tests")
        }

        // Prepare temp dir with status + events
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let statusPath = tmpDir.appendingPathComponent("status.json").path
        let eventsPath = tmpDir.appendingPathComponent("events.ndjson").path
        _ = writeJSONAtomic(path: statusPath, object: [
            "title": "Testing",
            "command": "build",
            "phase": "compiling",
            "elapsed": 1,
            "exitCode": 0
        ])
        _ = appendNDJSON(path: eventsPath, object: ["type": "log", "line": "hello"])

        // Start server without auth on random port
        let server = LocalHTTPServer(port: 0, statusPath: statusPath, eventsPath: eventsPath, token: nil, midiName: nil)
        let port = try server.start()

        // Fetch /status
        let statusURL = URL(string: "http://127.0.0.1:\(port)/status")!
        let (data1, resp1) = try await URLSession.shared.data(from: statusURL)
        XCTAssertEqual((resp1 as? HTTPURLResponse)?.statusCode, 200)
        let obj1 = try JSONSerialization.jsonObject(with: data1) as? [String: Any]
        XCTAssertEqual(obj1?["phase"] as? String, "compiling")

        // Fetch /summary
        let summaryURL = URL(string: "http://127.0.0.1:\(port)/summary")!
        let (data2, resp2) = try await URLSession.shared.data(from: summaryURL)
        XCTAssertEqual((resp2 as? HTTPURLResponse)?.statusCode, 200)
        let obj2 = try JSONSerialization.jsonObject(with: data2) as? [String: Any]
        XCTAssertEqual(obj2?["command"] as? String, "build")
        XCTAssertNotNil(obj2?["category"])
    }
}

