import Foundation

public enum CsoundError: Error, LocalizedError {
    case resourceNotFound
    case loadFailed

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound: return "hello.csd not found in bundle"
        case .loadFailed: return "Failed to load hello.csd contents"
        }
    }
}

public struct CsoundPlayer {
    public init() {}

    public struct Result {
        public let sampleRate: Int
        public let durationSeconds: Double
        public let samples: [Float]
    }

    // Play the bundled hello.csd
    public func play() throws -> Result {
        guard let url = Bundle.module.url(forResource: "hello", withExtension: "csd") else {
            throw CsoundError.resourceNotFound
        }
        guard let csd = try? String(contentsOf: url) else { throw CsoundError.loadFailed }
        return try play(csd: csd)
    }

    // Play from an inline CSD string (exercise/demo path)
    public func play(csd: String) throws -> Result {
        var amp: Double = 0.2, freq: Double = 440.0, duration: Double = 1.0
        let sampleRate = 44_100
        if let oscLine = csd.components(separatedBy: .newlines).first(where: { $0.contains("oscili") }) {
            let numbers = oscLine.replacingOccurrences(of: ",", with: " ")
                .components(separatedBy: CharacterSet(charactersIn: " -\t\n"))
                .compactMap { Double($0) }
            if numbers.count >= 2 { amp = numbers[0]; freq = numbers[1] }
        }
        // If there are multiple score events, use total end time as approx duration
        var endTime: Double = 0
        for line in csd.components(separatedBy: .newlines) where line.trimmingCharacters(in: .whitespaces).hasPrefix("i ") {
            let parts = line.split(whereSeparator: { $0.isWhitespace })
            if parts.count >= 4, let start = Double(parts[1]), let dur = Double(parts[3]) {
                endTime = max(endTime, start + dur)
            }
        }
        duration = max(duration, endTime)
        let total = Int((duration * Double(sampleRate)).rounded())
        var samples = [Float]()
        samples.reserveCapacity(total)
        let twoPi = 2.0 * Double.pi
        for n in 0..<total {
            let t = Double(n) / Double(sampleRate)
            samples.append(Float(amp * sin(twoPi * freq * t)))
        }
        return Result(sampleRate: sampleRate, durationSeconds: duration, samples: samples)
    }
}
