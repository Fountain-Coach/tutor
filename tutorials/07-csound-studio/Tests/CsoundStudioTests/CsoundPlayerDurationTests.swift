import XCTest
@testable import CsoundStudioCore

final class CsoundPlayerDurationTests: XCTestCase {
    func testDefaultDurationWhenNoILines() throws {
        let csd = """
        <CsoundSynthesizer>
        <CsInstruments>
        instr 1
          a1 oscili 0.2, 440
          out a1
        endin
        </CsInstruments>
        <CsScore>
        ; no score events
        e
        </CsScore>
        </CsoundSynthesizer>
        """
        let r = try CsoundPlayer().play(csd: csd)
        XCTAssertEqual(r.sampleRate, 44_100)
        XCTAssertEqual(r.samples.count, 44_100, "Expected 1.0s default duration")
    }

    func testMaxEndTimeFromMultipleILines() throws {
        let csd = """
        <CsoundSynthesizer>
        <CsInstruments>
        instr 1
          a1 oscili 0.2, 220
          out a1
        endin
        </CsInstruments>
        <CsScore>
        i 1 0.0 0.2
        i 1 0.5 0.3
        i 1 0.9 0.4
        e
        </CsScore>
        </CsoundSynthesizer>
        """
        let r = try CsoundPlayer().play(csd: csd)
        // Last end: 0.9 + 0.4 = 1.3s; sample count should be approx 1.3 * 44100
        XCTAssertGreaterThanOrEqual(r.durationSeconds, 1.29)
        XCTAssertLessThanOrEqual(r.durationSeconds, 1.31)
        XCTAssertGreaterThan(r.samples.count, 57_000)
    }
}

