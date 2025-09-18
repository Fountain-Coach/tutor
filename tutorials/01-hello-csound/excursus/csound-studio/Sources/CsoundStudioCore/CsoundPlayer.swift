import Foundation

public enum StudioError: Error, LocalizedError {
    case invalidCSD
    public var errorDescription: String? { "Invalid or unsupported .csd" }
}

public struct CsoundPlayer {
    public struct Result { public let sampleRate: Int; public let durationSeconds: Double; public let samples: [Float] }
    public init() {}

    public func play(csd: String) throws -> Result {
        var amp: Double = 0.2
        var freq: Double = 440.0
        var duration: Double = 1.0
        let sampleRate = 44_100
        // Parse first oscili line
        if let osc = csd.components(separatedBy: .newlines).first(where: { $0.contains("oscili") }) {
            let nums = osc.replacingOccurrences(of: ",", with: " ")
                .components(separatedBy: CharacterSet(charactersIn: " -\t\n")).compactMap(Double.init)
            if nums.count >= 2 { amp = nums[0]; freq = nums[1] }
        }
        // Duration from score (max end time)
        var endTime: Double = 0
        for line in csd.components(separatedBy: .newlines) where line.trimmingCharacters(in: .whitespaces).hasPrefix("i ") {
            let parts = line.split(whereSeparator: { $0.isWhitespace })
            // Csound i-line: i <instr> <start> <dur> [...]
            if parts.count >= 4, let start = Double(parts[2]), let dur = Double(parts[3]) {
                endTime = max(endTime, start + dur)
            }
        }
        duration = max(duration, endTime)
        let total = Int((duration * Double(sampleRate)).rounded())
        var samples = [Float]()
        samples.reserveCapacity(total)
        let twoPi = 2.0 * Double.pi
        for n in 0..<total { let t = Double(n) / Double(sampleRate); samples.append(Float(amp * sin(twoPi * freq * t))) }
        return Result(sampleRate: sampleRate, durationSeconds: duration, samples: samples)
    }
}
