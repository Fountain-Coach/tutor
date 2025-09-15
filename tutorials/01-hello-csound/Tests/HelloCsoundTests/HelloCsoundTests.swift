import XCTest
@testable import HelloCsound

final class HelloCsoundTests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
