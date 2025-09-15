import XCTest
@testable import HelloCsound

final class HelloCsoundTests: XCTestCase {
    func testCsoundPlayerExecutesCsdWithoutThrowing() {
        XCTAssertNoThrow(try CsoundPlayer().play())
    }
}
