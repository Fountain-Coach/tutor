import XCTest
@testable import OpenAPI

final class OpenAPITests: XCTestCase {
    func testGreetReturnsHello() {
        XCTAssertEqual(greet(), "Hello, FountainAI!")
    }
}
