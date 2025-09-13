import XCTest
@testable import TutorCLI

final class SummaryBuilderTests: XCTestCase {
    func testMakeSummaryAggregates() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let status = tmp.appendingPathComponent("status.json").path
        let events = tmp.appendingPathComponent("events.ndjson").path

        let statusObj: [String: Any] = [
            "title": "Building",
            "command": "build",
            "phase": "compiling",
            "elapsed": 3,
            "exitCode": 1,
        ]
        _ = writeJSONAtomic(path: status, object: statusObj)
        _ = appendNDJSON(path: events, object: ["type": "warning", "warning": ["message": "minor"]])
        _ = appendNDJSON(path: events, object: ["type": "error", "error": ["file": "/tmp/A.swift", "line": 1, "column": 1, "message": "cannot find type 'X'"]])

        let summary = makeSummary(statusPath: status, eventsPath: events)
        XCTAssertEqual(summary["command"] as? String, "build")
        XCTAssertEqual(summary["phase"] as? String, "compiling")
        XCTAssertEqual(summary["category"] as? String, "COMPILE")
        XCTAssertEqual(summary["errorCount"] as? Int, 1)
        XCTAssertEqual(summary["warningCount"] as? Int, 1)
    }
}

