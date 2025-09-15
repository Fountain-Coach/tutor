import Foundation

public struct CsoundPlayer {
    private let sampleRate = 44100.0
    private let duration = 0.01

    public init() {}

    /// Loads the bundled Csound file and simulates a sine wave oscillator.
    /// - Returns: Generated sample values for the greeting tone.
    public func play() throws -> [Double] {
        guard let url = Bundle.module.url(forResource: "hello", withExtension: "csd") else {
            throw NSError(domain: "CsoundPlayer", code: 1, userInfo: [NSLocalizedDescriptionKey: "hello.csd not found"])
        }
        _ = try String(contentsOf: url, encoding: .utf8)
        let frequency = 440.0
        let frameCount = Int(sampleRate * duration)
        return (0..<frameCount).map { index in
            sin(2.0 * .pi * frequency * Double(index) / sampleRate) * 0.5
        }
    }
}
