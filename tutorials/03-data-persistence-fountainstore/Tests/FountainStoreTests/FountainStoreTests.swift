import XCTest
@testable import TutorialFountainStore

final class TutorialFountainStoreTests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
