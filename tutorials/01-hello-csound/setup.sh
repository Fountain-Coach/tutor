#!/usr/bin/env bash
# Usage: ./setup.sh [BundleID]
../../Scripts/setup-tutorial.sh HelloCsound "$@"

# Ensure the Csound file is present in the generated package (prefer committed asset)
mkdir -p Sources/HelloCsound
if [[ -f hello.csd && ! -f Sources/HelloCsound/hello.csd ]]; then
  cp hello.csd Sources/HelloCsound/hello.csd
fi

CSWIFT="Sources/HelloCsound/CsoundPlayer.swift"
cat > "$CSWIFT" <<'SWIFT'
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
SWIFT

# Generate main.swift that uses the player if absent
MAIN="Sources/HelloCsound/main.swift"
cat > "$MAIN" <<'SWIFT'
import Foundation

let useMotif = (ProcessInfo.processInfo.environment["CS_MOTIF"] != nil)
let shouldPlay = (ProcessInfo.processInfo.environment["CS_PLAY"] != nil)

do {
    if useMotif {
        // Exercise: tweak the motif in Motif.swift and re-run with CS_MOTIF=1
        let csd = makeMotifCSD(
            frequencies: [440, 494, 523],
            durations:   [0.40, 0.40, 0.60]
        )
        let result = try CsoundPlayer().play(csd: csd)
        print("Motif sample count: \(result.samples.count)")
        if shouldPlay { try play(samples: result.samples, sampleRate: result.sampleRate, seconds: result.durationSeconds) }
    } else {
        let result = try CsoundPlayer().play()
        print("Generated sample count: \(result.samples.count)")
        if shouldPlay { try play(samples: result.samples, sampleRate: result.sampleRate, seconds: result.durationSeconds) }
    }
} catch {
    fputs("Csound simulation error: \(error)\n", stderr)
}
SWIFT

# Add an extra test that validates sample generation (keeps original greet test intact)
# Add an extra test that validates sample generation (keeps original greet test intact)
TEST_DIR="Tests/HelloCsoundTests"
mkdir -p "$TEST_DIR"
PLAYER_TEST="$TEST_DIR/CsoundPlayerTests.swift"
if [[ ! -f "$PLAYER_TEST" ]]; then
  cat > "$PLAYER_TEST" <<'SWIFT'
import XCTest
@testable import HelloCsound

final class CsoundPlayerTests: XCTestCase {
    func testGeneratesSamples() throws {
        let result = try CsoundPlayer().play()
        XCTAssertGreaterThan(result.samples.count, 1000)
    }
}
SWIFT
fi

# Motif helper for the exercise mode (CS_MOTIF=1)
MOTIF="Sources/HelloCsound/Motif.swift"
if [[ ! -f "$MOTIF" ]]; then
  cat > "$MOTIF" <<'SWIFT'
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
SWIFT
fi

# Lightweight playback helper (optional): enable with CS_PLAY=1
PLAYBACK="Sources/HelloCsound/Playback.swift"
cat > "$PLAYBACK" <<'SWIFT'
import Foundation

public func play(samples: [Float], sampleRate: Int, seconds: Double) throws {
    // Write a small WAV to a temp file and try to play via 'afplay' (macOS).
    // If playback isn't available, we still leave the file for manual audition.
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("hello_csound_\(UUID().uuidString).wav")
    try writeWAV(samples: samples, sampleRate: sampleRate, url: url)

    // Try to launch /usr/bin/afplay; if it fails, just print the path
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
    task.arguments = [url.path]
    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        print("Saved WAV to: \(url.path) (audio playback not available)")
    }
}

private func writeWAV(samples: [Float], sampleRate: Int, url: URL) throws {
    // 16-bit PCM mono
    let numChannels: UInt16 = 1
    let bitsPerSample: UInt16 = 16
    let byteRate: UInt32 = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bitsPerSample / 8)
    let blockAlign: UInt16 = numChannels * (bitsPerSample / 8)

    // Convert float [-1,1] to Int16 little-endian
    var pcm = Data()
    pcm.reserveCapacity(samples.count * 2)
    for s in samples {
        let v = Int16(max(-1.0, min(1.0, s)) * 32767.0)
        var le = UInt16(bitPattern: v).littleEndian
        withUnsafeBytes(of: &le) { pcm.append(contentsOf: $0) }
    }

    var data = Data()
    func append(_ s: String) { data.append(s.data(using: .ascii)!) }
    func append32(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }
    func append16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }

    // RIFF header
    append("RIFF")
    append32(UInt32(36 + pcm.count))
    append("WAVE")
    // fmt chunk
    append("fmt ")
    append32(16) // PCM chunk size
    append16(1)  // PCM format
    append16(numChannels)
    append32(UInt32(sampleRate))
    append32(byteRate)
    append16(blockAlign)
    append16(bitsPerSample)
    // data chunk
    append("data")
    append32(UInt32(pcm.count))
    data.append(pcm)

    try data.write(to: url)
}
SWIFT

# Ensure Package.swift declares the hello.csd resource for the HelloCsound target
if grep -q 'name: "HelloCsound"' Package.swift; then
  if ! grep -q '\.copy("hello.csd")' Package.swift; then
    # Replace the simple target with one that includes resources
    perl -0777 -pe 's/\.executableTarget\(name: \"HelloCsound\"\)/.executableTarget(name: \"HelloCsound\", resources: [.copy(\"hello.csd\")])/' -i Package.swift
    echo "Patched Package.swift to include hello.csd as a resource"
  fi
fi
