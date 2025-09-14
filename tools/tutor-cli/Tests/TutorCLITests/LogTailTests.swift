import XCTest
@testable import TutorCLI

final class LogTailTests: XCTestCase {
    func testLastEventsFiltersAndLimits() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let events = tmp.appendingPathComponent("events.ndjson").path
        _ = appendNDJSON(path: events, object: ["type": "log", "line": "A"]) // ignored when errorsOnly
        _ = appendNDJSON(path: events, object: ["type": "warning", "warning": ["message": "w1"]])
        _ = appendNDJSON(path: events, object: ["type": "error", "error": ["message": "e1"]])
        _ = appendNDJSON(path: events, object: ["type": "error", "error": ["message": "e2"]])

        let all = lastEvents(path: events, count: nil, errorsOnly: false)
        XCTAssertEqual(all.count, 4)
        let errors = lastEvents(path: events, count: nil, errorsOnly: true)
        XCTAssertEqual(errors.count, 2)
        let last1 = lastEvents(path: events, count: 1, errorsOnly: true)
        XCTAssertEqual((last1.first?["error"] as? [String: Any])?["message"] as? String, "e2")
    }

    func testOneLineEventFormatting() throws {
        let w = oneLineEvent(["type": "warning", "warning": ["message": "be careful"]])
        XCTAssertTrue(w.contains("warning: be careful"))
        let e = oneLineEvent(["type": "error", "error": ["message": "boom"]])
        XCTAssertTrue(e.contains("error: boom"))
        let l = oneLineEvent(["line": "Compiling Foo"]) // passthrough
        XCTAssertTrue(l.contains("Compiling Foo"))
    }
}

