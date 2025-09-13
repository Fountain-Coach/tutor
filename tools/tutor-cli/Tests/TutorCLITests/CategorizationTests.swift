import XCTest
@testable import TutorCLI

final class CategorizationTests: XCTestCase {
    func testCategorizeSuccess() {
        let (cat, hint) = categorizeFailure(command: "build", phase: "completed", code: 0, sawTestFailure: false, sawLinkerError: false, sawResolveError: false, sawNetworkError: false, errors: [])
        XCTAssertEqual(cat, "success")
        XCTAssertEqual(hint, "")
    }

    func testCategorizeResolve() {
        let (cat, _) = categorizeFailure(command: "build", phase: "resolving", code: 1, sawTestFailure: false, sawLinkerError: false, sawResolveError: true, sawNetworkError: false, errors: [])
        XCTAssertEqual(cat, "RESOLVE_GRAPH")
    }

    func testCategorizeCompile() {
        let errs: [[String: Any]] = [["file": "/tmp/A.swift", "line": 1, "column": 1, "message": "cannot find type 'X'"]]
        let (cat, _) = categorizeFailure(command: "build", phase: "compiling", code: 1, sawTestFailure: false, sawLinkerError: false, sawResolveError: false, sawNetworkError: false, errors: errs)
        XCTAssertEqual(cat, "COMPILE")
    }

    func testCategorizeTests() {
        let (cat, _) = categorizeFailure(command: "test", phase: "testing", code: 1, sawTestFailure: true, sawLinkerError: false, sawResolveError: false, sawNetworkError: false, errors: [])
        XCTAssertEqual(cat, "TEST")
    }

    func testCategorizeLink() {
        let errs: [[String: Any]] = [["message": "linker command failed with exit code 1"]]
        let (cat, _) = categorizeFailure(command: "build", phase: "linking", code: 1, sawTestFailure: false, sawLinkerError: true, sawResolveError: false, sawNetworkError: false, errors: errs)
        XCTAssertEqual(cat, "LINK")
    }

    func testCategorizeNetwork() {
        let errs: [[String: Any]] = [["message": "network timed out"]]
        let (cat, _) = categorizeFailure(command: "build", phase: "fetching", code: 1, sawTestFailure: false, sawLinkerError: false, sawResolveError: false, sawNetworkError: true, errors: errs)
        XCTAssertEqual(cat, "DEPENDENCY_NETWORK")
    }
}

