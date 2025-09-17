import Foundation

public func makeMotifCSD(frequencies: [Double], durations: [Double]) -> String {
    let pairs = zip(frequencies, durations)
    let scoreLines = pairs.enumerated().map { (idx, pair) in
        let (f, d) = pair
        let start = pairs.prefix(idx).map { $0.1 }.reduce(0, +)
        return String(format: "i 1 %.2f %.2f", start, d)
    }.joined(separator: "\n")

    let instrument = """
    instr 1
      kenv linseg 0, 0.05, 1, 0.8, 1, 0.15, 0
      a1   oscili 0.4 * kenv, %.2f
      out  a1
    endin
    """
    .replacingOccurrences(of: "%.2f", with: String(format: "%.2f", frequencies.first ?? 440.0))

    let csd = """
    <CsoundSynthesizer>
    <CsOptions>
    -odac
    </CsOptions>
    <CsInstruments>
    %@
    </CsInstruments>
    <CsScore>
    %@
    e
    </CsScore>
    </CsoundSynthesizer>
    """

    return String(format: csd, instrument, scoreLines)
}
