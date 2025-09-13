import XCTest
@testable import TutorCLI

final class RunContextTests: XCTestCase {
    func testProcessLinesAndCIMessages() {
        // Capture stdout
        let pipe = Pipe(); let orig = dup(STDOUT_FILENO); dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        defer { fflush(stdout); dup2(orig, STDOUT_FILENO); close(orig) }

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let status = tmp.appendingPathComponent("status.json").path
        let events = tmp.appendingPathComponent("events.ndjson").path

        let pr = ProgressReporter(enabled: false, title: "Build")
        let ctx = RunContext(title: "Build", command: "build", statusPath: status, eventPath: events, reporter: pr, midi: nil, ciMode: true, start: Date())
        ctx.onStart()
        [
            "Fetching xxx",
            "Updating yyy",
            "Resolving dependencies",
            "Compiling Foo foo.swift",
            "Linking Foo",
            "Testing FooTests",
            "building for macOS",
            "Build complete!",
            "Executing Foo"
        ].forEach { ctx.process(line: $0) }

        // Emit a warning and error to exercise CI annotations
        ctx.process(line: "/tmp/A.swift:1:2: warning: be careful")
        ctx.process(line: "/tmp/A.swift:1:2: error: oops")
        ctx.process(line: "Test Suite 'All tests' failed")
        ctx.onFinish(exitCode: 1)

        pipe.fileHandleForWriting.closeFile()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertTrue(out.contains("::warning"))
        XCTAssertTrue(out.contains("::error"))

        // Ensure summary json is built
        let summary = ctx.makeSummaryJSON() ?? ""
        XCTAssertTrue(summary.contains("\"errorCount\""))
        XCTAssertTrue(FileManager.default.fileExists(atPath: status))
        XCTAssertTrue(FileManager.default.fileExists(atPath: events))
    }
}

