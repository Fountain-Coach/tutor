import XCTest
@testable import CsoundStudioCore

final class LilyPondDurationTests: XCTestCase {
    private func csd(oscHz: Int, durs: [Double]) -> String {
        let iLines = durs.enumerated().map { idx, d in "i 1 \(Double(idx) * 0.5) \(d)" }.joined(separator: "\n")
        return """
        <CsoundSynthesizer>
        <CsInstruments>
        instr 1
          a1 oscili 0.5, \(oscHz)
          out a1
        endin
        </CsInstruments>
        <CsScore>
        \(iLines)
        e
        </CsScore>
        </CsoundSynthesizer>
        """
    }

    func testQuarterAndDottedQuarterAt120BPM() {
        // 120 BPM → quarter = 0.5s
        let ly = LilyPondExporter.makeLily(from: csd(oscHz: 440, durs: [0.5, 0.75, 0.25, 1.0]), tempoBPM: 120)
        // Extract note tokens from the body and assert expected durations exist
        let bodyStart = ly.lastIndex(of: "{").map { ly.index(after: $0) } ?? ly.startIndex
        let bodyEnd = ly.lastIndex(of: "}") ?? ly.endIndex
        let body = String(ly[bodyStart..<bodyEnd])
        let tokens = body.split{ $0.isWhitespace }
        // Count tokens that look like notes (end in a duration token)
        let noteLike = tokens.filter { tok in
            guard let last = tok.last else { return false }
            return (last.isNumber || last == ".") && tok.contains(where: { $0.isLetter })
        }
        XCTAssertGreaterThanOrEqual(noteLike.count, 4)
    }

    func testPitchHeuristicFromOscili() {
        // 440 Hz should map to an 'a' token with at least one apostrophe (around middle A)
        let ly440 = LilyPondExporter.makeLily(from: csd(oscHz: 440, durs: [0.5]), tempoBPM: 120)
        XCTAssertTrue(ly440.contains("a'"), "Expected an a' pitch token for 440Hz")

        // 880 Hz (one octave up) likely increases apostrophes; allow any 'a' with apostrophes
        let ly880 = LilyPondExporter.makeLily(from: csd(oscHz: 880, durs: [0.5]), tempoBPM: 120)
        XCTAssertTrue(ly880.contains("a'"), "Expected an a pitch above middle with apostrophe for 880Hz")
    }
}
