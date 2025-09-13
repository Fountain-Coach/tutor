import XCTest
@testable import TutorCLI
import Foundation
import Darwin

final class UnixSocketTests: XCTestCase {
    func testUnixSocketStreamsStatus() throws {
        // Create temp status/events
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let statusPath = tmpDir.appendingPathComponent("status.json").path
        let eventsPath = tmpDir.appendingPathComponent("events.ndjson").path
        _ = writeJSONAtomic(path: statusPath, object: ["title": "Sock", "command": "build", "phase": "resolving", "elapsed": 0, "exitCode": 0])

        // Socket path
        let sockPath = tmpDir.appendingPathComponent("tutor.sse").path

        // Start server (port 0 + socket)
        let server = LocalHTTPServer(port: 0, statusPath: statusPath, eventsPath: eventsPath, token: nil, midiName: nil, socketPath: sockPath)
        _ = try server.start()

        // Connect via AF_UNIX and read initial bytes
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        XCTAssertGreaterThanOrEqual(fd, 0)
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let bytes = [UInt8](sockPath.utf8)
        XCTAssertLessThan(bytes.count, MemoryLayout.size(ofValue: addr.sun_path))
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let buf = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: UInt8.self)
            for (i, b) in bytes.enumerated() { buf[i] = b }
            buf[bytes.count] = 0
        }
        let len = socklen_t(MemoryLayout.size(ofValue: addr.sun_family) + bytes.count + 1)
        var a = addr
        let res = withUnsafePointer(to: &a) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, len) }
        }
        XCTAssertEqual(res, 0)

        var buf = [UInt8](repeating: 0, count: 1024)
        let n = read(fd, &buf, buf.count)
        XCTAssertGreaterThan(n, 0)
        let s = String(bytes: buf.prefix(n), encoding: .utf8) ?? ""
        XCTAssertTrue(s.contains("phase") || s.contains("title"))
        _ = Darwin.close(fd)
    }
}
