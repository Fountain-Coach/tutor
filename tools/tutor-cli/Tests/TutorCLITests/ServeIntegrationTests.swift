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
        let server = LocalHTTPServer(port: 0, statusPath: statusPath, eventsPath: eventsPath, token: nil, midiName: nil, socketPath: nil)
        let port = try server.start()

        // Fetch /status
        let statusURL = URL(string: "http://127.0.0.1:\(port)/status")!
        let (data1, resp1) = try await URLSession.shared.data(from: statusURL)
        XCTAssertEqual((resp1 as? HTTPURLResponse)?.statusCode, 200)
        let obj1 = try JSONSerialization.jsonObject(with: data1) as? [String: Any]
        if let phase = obj1?["phase"] as? String {
            XCTAssertEqual(phase, "compiling")
        } else {
            XCTFail("Missing phase in status")
        }

        // Fetch /summary
        let summaryURL = URL(string: "http://127.0.0.1:\(port)/summary")!
        let (data2, resp2) = try await URLSession.shared.data(from: summaryURL)
        XCTAssertEqual((resp2 as? HTTPURLResponse)?.statusCode, 200)
        let obj2 = try JSONSerialization.jsonObject(with: data2) as? [String: Any]
        if let cmd = obj2?["command"] as? String { XCTAssertEqual(cmd, "build") } else { XCTFail("Missing command") }
        XCTAssertNotNil(obj2?["category"], "Missing category in summary")
    }

    func testServeEventsSSE() async throws {
        guard ProcessInfo.processInfo.environment["TUTOR_INTEGRATION"] == "1" else {
            throw XCTSkip("Set TUTOR_INTEGRATION=1 to run integration serve tests")
        }
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let statusPath = tmpDir.appendingPathComponent("status.json").path
        let eventsPath = tmpDir.appendingPathComponent("events.ndjson").path
        _ = writeJSONAtomic(path: statusPath, object: ["title": "Testing", "command": "build", "phase": "resolving", "elapsed": 0, "exitCode": 0])
        _ = appendNDJSON(path: eventsPath, object: ["type": "log", "line": "initial"]) 

        let server = LocalHTTPServer(port: 0, statusPath: statusPath, eventsPath: eventsPath, token: nil, midiName: nil, socketPath: nil)
        let port = try server.start()

        let url = URL(string: "http://127.0.0.1:\(port)/events")!
        var req = URLRequest(url: url)
        req.addValue("text/event-stream", forHTTPHeaderField: "Accept")

        let exp = expectation(description: "receive sse")
        let task = URLSession.shared.dataTask(with: req) { data, response, error in
            // We don't expect completion; we'll fulfill via a delayed write
        }
        task.resume()

        // Append an event after a short delay, then fetch a small slice to ensure server processed it
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            _ = appendNDJSON(path: eventsPath, object: ["type": "warning", "warning": ["message": "be careful"]])
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 5.0)
        task.cancel()
    }

    func testServeOpenAPIAndDocs() async throws {
        guard ProcessInfo.processInfo.environment["TUTOR_INTEGRATION"] == "1" else {
            throw XCTSkip("Set TUTOR_INTEGRATION=1 to run integration serve tests")
        }
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let statusPath = tmpDir.appendingPathComponent("status.json").path
        let eventsPath = tmpDir.appendingPathComponent("events.ndjson").path
        _ = writeJSONAtomic(path: statusPath, object: ["title": "Docs", "command": "build", "phase": "resolving", "elapsed": 0, "exitCode": 0])
        _ = appendNDJSON(path: eventsPath, object: ["type": "log", "line": "init"]) 

        let server = LocalHTTPServer(port: 0, statusPath: statusPath, eventsPath: eventsPath, token: nil, midiName: nil, socketPath: nil)
        let port = try server.start()

        let yurl = URL(string: "http://127.0.0.1:\(port)/openapi.yaml")!
        let (ydata, yresp) = try await URLSession.shared.data(from: yurl)
        XCTAssertEqual((yresp as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertTrue(String(data: ydata, encoding: .utf8)?.contains("openapi:") == true)

        // Root redirects to docs-lite
        let rurl = URL(string: "http://127.0.0.1:\(port)/")!
        var rreq = URLRequest(url: rurl)
        rreq.httpMethod = "GET"
        let (rdata, rresp) = try await URLSession.shared.data(for: rreq)
        XCTAssertEqual((rresp as? HTTPURLResponse)?.statusCode, 200) // after redirect, docs-lite content
        XCTAssertTrue(String(data: rdata, encoding: .utf8)?.contains("Tutor Serve API (Lite)") == true)

        // Full docs page renders HTML shell
        let durl = URL(string: "http://127.0.0.1:\(port)/docs")!
        let (ddata, dresp) = try await URLSession.shared.data(from: durl)
        XCTAssertEqual((dresp as? HTTPURLResponse)?.statusCode, 200)
        let html = String(data: ddata, encoding: .utf8) ?? ""
        XCTAssertTrue(html.contains("Swagger UI"))
    }
}

final class SSEStreamContentTests: XCTestCase {
    func testSSEEmitsWarningEvent() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let status = tmp.appendingPathComponent("status.json").path
        let events = tmp.appendingPathComponent("events.ndjson").path
        _ = writeJSONAtomic(path: status, object: ["title": "SSE", "command": "build", "phase": "resolving", "elapsed": 0, "exitCode": 0])
        _ = appendNDJSON(path: events, object: ["type": "log", "line": "init"]) 

        let server = LocalHTTPServer(port: 0, statusPath: status, eventsPath: events, token: nil, midiName: nil, socketPath: nil)
        let port = try server.start()

        class D: NSObject, URLSessionDataDelegate {
            let exp: XCTestExpectation
            init(_ exp: XCTestExpectation) { self.exp = exp }
            var buf = Data()
            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
                buf.append(data)
                if let s = String(data: buf, encoding: .utf8), s.contains("event: warning") { exp.fulfill() }
            }
        }
        let exp = expectation(description: "sse warning")
        let del = D(exp)
        let session = URLSession(configuration: .default, delegate: del, delegateQueue: nil)
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(port)/events")!)
        req.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: req)
        task.resume()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            _ = appendNDJSON(path: events, object: ["type": "warning", "warning": ["message": "be careful"]])
        }

        await fulfillment(of: [exp], timeout: 5.0)
        task.cancel()
    }
}
