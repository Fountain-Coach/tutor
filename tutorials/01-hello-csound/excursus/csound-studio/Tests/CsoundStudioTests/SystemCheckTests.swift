import XCTest
@testable import CsoundStudioCore

final class SystemCheckTests: XCTestCase {
    func testGatewayHealthyReturnsFalseForInvalidURL() async throws {
        // Unlikely port to be open; method has a short timeout
        let ok = await SystemCheck.gatewayHealthy(urlString: "http://127.0.0.1:65535/api/v1")
        XCTAssertFalse(ok)
    }
}
