import XCTest
@testable import CsoundStudioCore

final class CsoundStudioTests: XCTestCase {
    func testSynthesizesSamplesFromMinimalCSD() throws {
        let csd = """
        <CsoundSynthesizer>
        <CsInstruments>
        instr 1
          a1 oscili 0.5, 440
          out a1
        endin
        </CsInstruments>
        <CsScore>
        i 1 0 0.2
        e
        </CsScore>
        </CsoundSynthesizer>
        """
        let result = try CsoundPlayer().play(csd: csd)
        XCTAssertGreaterThan(result.samples.count, 1000)
    }
}
