import XCTest
@testable import HelloCsound

final class HelloCsoundTests: XCTestCase {
    func testPlayGeneratesSamples() throws {
        let samples = try CsoundPlayer().play()
        XCTAssertEqual(samples.count, 441)
        XCTAssertEqual(samples.first ?? 1.0, 0.0, accuracy: 1e-6)
    }
}
