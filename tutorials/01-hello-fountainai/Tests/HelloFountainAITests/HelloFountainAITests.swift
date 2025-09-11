import XCTest
@testable import HelloFountainAI

final class HelloFountainAITests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
