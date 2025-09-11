import XCTest
@testable import ScreenplayEditor

final class ScreenplayEditorTests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
