import XCTest
@testable import TutorCLI

final class ArgParsingTests: XCTestCase {
    func testParseDirAndPassThrough() {
        var args = ["--dir", "/tmp/myproj", "--", "-c", "release", "--jobs", "8"]
        let (dir, pass) = TutorCLI.parseDir(args: &args)
        XCTAssertEqual(dir, "/tmp/myproj")
        XCTAssertEqual(pass, ["-c", "release", "--jobs", "8"])
        XCTAssertTrue(args.isEmpty)
    }
}

