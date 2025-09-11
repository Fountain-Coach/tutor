import XCTest
@testable import Midi2

final class Midi2Tests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
