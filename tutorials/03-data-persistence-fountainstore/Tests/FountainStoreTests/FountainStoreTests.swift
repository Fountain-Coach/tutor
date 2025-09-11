import XCTest
@testable import FountainStore

final class FountainStoreTests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
