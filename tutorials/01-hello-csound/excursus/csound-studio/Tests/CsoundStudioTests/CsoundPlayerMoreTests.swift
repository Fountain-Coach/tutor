import XCTest
@testable import CsoundStudioCore

final class CsoundPlayerMoreTests: XCTestCase {
    func testSampleRateDurationAndAmplitudeBounds() throws {
        let csd = """
        <CsoundSynthesizer>
        <CsInstruments>
        instr 1
          a1 oscili 0.2, 220
          out a1
        endin
        </CsInstruments>
        <CsScore>
        i 1 0 0.1
        e
        </CsScore>
        </CsoundSynthesizer>
        """
        let result = try CsoundPlayer().play(csd: csd)
        XCTAssertEqual(result.sampleRate, 44_100)
        XCTAssertGreaterThanOrEqual(result.durationSeconds, 0.1 - 0.001)
        // amplitude should be within a small epsilon around 0.2
        let maxAmp = result.samples.map { abs($0) }.max() ?? 0
        XCTAssertLessThanOrEqual(maxAmp, 0.21)
    }
}
