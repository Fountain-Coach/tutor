import XCTest
@testable import CsoundStudioCore

final class LilyPondTempoTests: XCTestCase {
    func testDurationTokenChangesWithTempo() {
        // 0.5s duration maps to:
        // - 60 BPM (quarter = 1.0s) → 8 (eighth note)
        // - 120 BPM (quarter = 0.5s) → 4 (quarter note)
        let csd = """
        <CsoundSynthesizer>
        <CsInstruments>
        instr 1
          a1 oscili 0.5, 440
          out a1
        endin
        </CsInstruments>
        <CsScore>
        i 1 0 0.5
        e
        </CsScore>
        </CsoundSynthesizer>
        """
        let ly60 = LilyPondExporter.makeLily(from: csd, tempoBPM: 60)
        let ly120 = LilyPondExporter.makeLily(from: csd, tempoBPM: 120)

        // Extract body
        func body(_ ly: String) -> String {
            let s = ly.lastIndex(of: "{").map { ly.index(after: $0) } ?? ly.startIndex
            let e = ly.lastIndex(of: "}") ?? ly.endIndex
            return String(ly[s..<e])
        }
        let b60 = body(ly60)
        let b120 = body(ly120)

        XCTAssertTrue(b60.contains(" 8 ") || b60.contains("8\n") || b60.contains("8}"))
        XCTAssertTrue(b120.contains(" 4 ") || b120.contains("4\n") || b120.contains("4}"))
    }
}

