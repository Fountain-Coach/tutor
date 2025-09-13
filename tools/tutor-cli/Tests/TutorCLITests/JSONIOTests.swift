import XCTest
@testable import TutorCLI

final class JSONIOTests: XCTestCase {
    func testWriteJSONAtomicAndAppendNDJSON() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let status = tmp.appendingPathComponent("status.json").path
        let events = tmp.appendingPathComponent("events.ndjson").path

        let obj1: [String: Any] = ["title": "Building", "phase": "resolving", "elapsed": 1]
        XCTAssertTrue(writeJSONAtomic(path: status, object: obj1))
        let read1 = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: status))) as? [String: Any]
        XCTAssertEqual(read1?["phase"] as? String, "resolving")

        XCTAssertTrue(appendNDJSON(path: events, object: ["type": "log", "line": "Compiling A"]))
        XCTAssertTrue(appendNDJSON(path: events, object: ["type": "warning", "warning": ["message": "be careful"]]))
        let text = try String(contentsOf: URL(fileURLWithPath: events))
        XCTAssertEqual(text.split(separator: "\n").count, 2)
    }
}

