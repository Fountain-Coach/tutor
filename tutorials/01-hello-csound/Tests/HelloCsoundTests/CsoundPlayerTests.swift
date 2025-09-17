import XCTest
@testable import HelloCsound

final class CsoundPlayerTests: XCTestCase {
    func testGeneratesSamples() throws {
        let result = try CsoundPlayer().play()
        XCTAssertGreaterThan(result.samples.count, 1000)
    }
}
