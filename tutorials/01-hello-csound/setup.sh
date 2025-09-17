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

do {
    if useMotif {
        // Exercise: tweak the motif in Motif.swift and re-run with CS_MOTIF=1
        let csd = makeMotifCSD(
            frequencies: [440, 494, 523],
            durations:   [0.40, 0.40, 0.60]
        )
        let result = try CsoundPlayer().play(csd: csd)
        print("Motif sample count: \(result.samples.count)")
    } else {
        let result = try CsoundPlayer().play()
        print("Generated sample count: \(result.samples.count)")
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

# Ensure Package.swift declares the hello.csd resource for the HelloCsound target
if grep -q 'name: "HelloCsound"' Package.swift; then
  if ! grep -q '\.copy("hello.csd")' Package.swift; then
    # Replace the simple target with one that includes resources
    perl -0777 -pe 's/\.executableTarget\(name: \"HelloCsound\"\)/.executableTarget(name: \"HelloCsound\", resources: [.copy(\"hello.csd\")])/' -i Package.swift
    echo "Patched Package.swift to include hello.csd as a resource"
  fi
fi
