import XCTest
@testable import TutorCLI

final class ProgressReporterTests: XCTestCase {
    func testTicksAndPercent() {
        let pr = ProgressReporter(enabled: true, title: "Building")
        pr.start()
        pr.set(status: "Resolving package graph")
        pr.testTick() // should bump to >=10
        pr.set(status: "Compiling Foo")
        pr.bumpCompile()
        pr.testTick() // bump percent via compile
        pr.set(status: "Linking targets")
        pr.testTick() // >=95
        pr.stop(final: true, elapsed: 0.01)
    }
}

