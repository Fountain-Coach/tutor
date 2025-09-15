import XCTest
@testable import BasicTeatro

final class BasicTeatroTests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
