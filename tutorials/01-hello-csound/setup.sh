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
let exportLily = (ProcessInfo.processInfo.environment["LY_EXPORT"] != nil)
let tempoBPM = Int(ProcessInfo.processInfo.environment["LY_TEMPO"] ?? "") ?? 120
let useTriad = (ProcessInfo.processInfo.environment["CS_TRIAD"] != nil)
let triadQuality = (ProcessInfo.processInfo.environment["TRIAD_QUALITY"] ?? "major").lowercased()
let exportDuo = (ProcessInfo.processInfo.environment["LY_DUO"] != nil)

do {
    if useTriad {
        // Triad: build a simple CSD with p4 as frequency and three voices
        let root: Double = 261.63 // C4 by default
        let d: Double = 1.0
        let csd = makeTriadCSD(rootHz: root, duration: d, quality: triadQuality)
        let result = try CsoundPlayer().play(csd: csd)
        print("Triad sample count: \(result.samples.count)")
        if shouldPlay { try play(samples: result.samples, sampleRate: result.sampleRate, seconds: result.durationSeconds) }
        if exportLily {
            let lily = makeLilyPondTriad(rootHz: root, duration: d, tempoBPM: tempoBPM, quality: triadQuality)
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("triad.ly")
            try lily.write(to: url, atomically: true, encoding: .utf8)
            print("Wrote LilyPond triad: \(url.path)")
        }
    } else if useMotif {
        // Exercise: tweak the motif in Motif.swift and re-run with CS_MOTIF=1
        let freqs: [Double] = [440, 494, 523]
        let durs:  [Double] = [0.40, 0.40, 0.60]
        let csd = makeMotifCSD(
            frequencies: freqs,
            durations:   durs
        )
        let result = try CsoundPlayer().play(csd: csd)
        print("Motif sample count: \(result.samples.count)")
        if shouldPlay { try play(samples: result.samples, sampleRate: result.sampleRate, seconds: result.durationSeconds) }
        if exportLily {
            let lily = makeLilyPond(frequencies: freqs, durations: durs, tempoBPM: tempoBPM)
            let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("motif.ly")
            try lily.write(to: url, atomically: true, encoding: .utf8)
            print("Wrote LilyPond score: \(url.path)")
            if exportDuo {
                // Simple accompaniment: pedal bass one octave below first note for the whole phrase
                let bassRoot = max(55.0, freqs.first ?? 440.0 / 2.0)
                let duo = makeLilyPondDuo(melodyFreqs: freqs, durations: durs, bassRootHz: bassRoot, tempoBPM: tempoBPM)
                let duoURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("motif_duo.ly")
                try duo.write(to: duoURL, atomically: true, encoding: .utf8)
                print("Wrote LilyPond duo score: \(duoURL.path)")
            }
        }
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

# Additional deterministic tests for duration mapping and LilyPond export behavior
LILY_TEST="$TEST_DIR/LilyPondMappingTests.swift"
if [[ ! -f "$LILY_TEST" ]]; then
  cat > "$LILY_TEST" <<'SWIFT'
import XCTest
@testable import HelloCsound

final class LilyPondMappingTests: XCTestCase {
    func testDurationTokensChangeWithTempo() {
        // Use exported helpers from setup (makeLilyPond) if present
        let freqs: [Double] = [440]
        let durs:  [Double] = [0.5]
        let ly60 = makeLilyPond(frequencies: freqs, durations: durs, tempoBPM: 60)
        let ly120 = makeLilyPond(frequencies: freqs, durations: durs, tempoBPM: 120)
        XCTAssertTrue(ly60.contains(" 8 ") || ly60.contains("8\n") || ly60.contains("8}"))
        XCTAssertTrue(ly120.contains(" 4 ") || ly120.contains("4\n") || ly120.contains("4}"))
    }
}
SWIFT
fi

NEG_TEST="$TEST_DIR/SystemNegativeTests.swift"
if [[ ! -f "$NEG_TEST" ]]; then
  cat > "$NEG_TEST" <<'SWIFT'
import XCTest
@testable import HelloCsound

final class SystemNegativeTests: XCTestCase {
    func testGatewayHealthInvalidURLReturnsFalse() async throws {
        let ok = await SystemCheck.gatewayHealthy(urlString: "http://127.0.0.1:65535/api/v1")
        XCTAssertFalse(ok)
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

# LilyPond export helper (optional): enable with LY_EXPORT=1
LILY="Sources/HelloCsound/LilyPond.swift"
cat > "$LILY" <<'SWIFT'
import Foundation

public func makeLilyPond(frequencies: [Double], durations: [Double], tempoBPM: Int = 120) -> String {
    // Map frequencies to nearest MIDI and then to LilyPond note names
    func midi(for freq: Double) -> Int {
        guard freq > 0 else { return 60 }
        return Int((69.0 + 12.0 * log2(freq / 440.0)).rounded())
    }
    let names = ["c","cis","d","dis","e","f","fis","g","gis","a","ais","b"]
    func lilyName(for midiNote: Int) -> String {
        let pc = (midiNote % 12 + 12) % 12
        let base = names[pc]
        // LilyPond: c' is middle C (MIDI 60). Compute relative marks.
        let d = (midiNote - 60) / 12 // integer division toward zero
        if d >= 0 {
            return base + String(repeating: "'", count: d + 1)
        } else {
            return base + String(repeating: ",", count: -d - 1)
        }
    }
    // Map durations in seconds to nearest LilyPond duration token (supports dotted)
    // assuming quarter note = 60/tempo seconds
    let quarter = 60.0 / Double(tempoBPM)
    let denoms: [Int] = [1,2,4,8,16]
    struct Cand { let ratio: Double; let label: String }
    func lilyDurToken(for sec: Double) -> String {
        let ratio = sec / quarter // in quarters
        var best = Cand(ratio: Double.greatestFiniteMagnitude, label: "4")
        var bestDiff = Double.greatestFiniteMagnitude
        for d in denoms {
            let base = 4.0 / Double(d)           // whole=1, half=2, quarter=4, etc.
            let plain = Cand(ratio: base, label: String(d))
            let dotted = Cand(ratio: base * 1.5, label: String(d) + ".")
            for c in [plain, dotted] {
                let diff = abs(ratio - c.ratio)
                if diff < bestDiff { bestDiff = diff; best = c }
            }
        }
        return best.label
    }
    let notes = zip(frequencies, durations).map { (f, d) -> String in
        let n = lilyName(for: midi(for: f))
        let token = lilyDurToken(for: d)
        return "\(n)\(token)"
    }.joined(separator: " ")
    let header = """
    % Generated by HelloCsound motif export
    \\version "2.24.0"
    \\header { title = "Motif" tagline = "FountainAI • Csound • LilyPond" }
    """
    let tempo = "\\tempo 4 = \(tempoBPM)"
    let body = "{ \n  \(tempo) \n  \(notes) \n}"
    return [header, body].joined(separator: "\n")
}
SWIFT

# Triad helpers (CS_TRIAD=1)
TRIAD="Sources/HelloCsound/Triad.swift"
cat > "$TRIAD" <<'SWIFT'
import Foundation

public func makeTriadCSD(rootHz: Double, duration: Double, quality: String = "major") -> String {
    let thirds: Double = (quality == "minor") ? pow(2.0, 3.0/12.0) : pow(2.0, 4.0/12.0)
    let fifth: Double = pow(2.0, 7.0/12.0)
    let f2 = rootHz * thirds
    let f3 = rootHz * fifth
    let instr = """
    instr 1
      kenv linseg 0, 0.05, 1, 0.85, 1, 0.10, 0
      a1 oscili 0.35 * kenv, p4
      out a1
    endin
    """
    let score = String(format: "i 1 0 %.2f %.2f\ni 1 0 %.2f %.2f\ni 1 0 %.2f %.2f\n", duration, rootHz, duration, f2, duration, f3)
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
    return String(format: csd, instr, score)
}

public func makeLilyPondTriad(rootHz: Double, duration: Double, tempoBPM: Int = 120, quality: String = "major") -> String {
    func midi(for freq: Double) -> Int { guard freq > 0 else { return 60 }; return Int((69.0 + 12.0 * log2(freq / 440.0)).rounded()) }
    let names = ["c","cis","d","dis","e","f","fis","g","gis","a","ais","b"]
    func lilyName(for midiNote: Int) -> String {
        let pc = (midiNote % 12 + 12) % 12
        let base = names[pc]
        let d = (midiNote - 60) / 12
        if d >= 0 { return base + String(repeating: "'", count: d + 1) }
        else { return base + String(repeating: ",", count: -d - 1) }
    }
    // durations
    let quarter = 60.0 / Double(tempoBPM)
    let denoms: [Int] = [1,2,4,8,16]
    struct Cand { let ratio: Double; let label: String }
    func lilyDurToken(for sec: Double) -> String {
        let ratio = sec / quarter
        var best = Cand(ratio: Double.greatestFiniteMagnitude, label: "4")
        var bestDiff = Double.greatestFiniteMagnitude
        for d in denoms {
            let base = 4.0 / Double(d)
            let plain = Cand(ratio: base, label: String(d))
            let dotted = Cand(ratio: base * 1.5, label: String(d) + ".")
            for c in [plain, dotted] {
                let diff = abs(ratio - c.ratio)
                if diff < bestDiff { bestDiff = diff; best = c }
            }
        }
        return best.label
    }

    let thirds: Double = (quality == "minor") ? pow(2.0, 3.0/12.0) : pow(2.0, 4.0/12.0)
    let fifth: Double = pow(2.0, 7.0/12.0)
    let chordMidis = [rootHz, rootHz * thirds, rootHz * fifth].map(midi(for:))
    let chordNames = chordMidis.map(lilyName(for:))
    let token = lilyDurToken(for: duration)
    let chord = "<" + chordNames.joined(separator: " ") + ">" + token

    let header = """
    % Generated by HelloCsound triad export
    \\version "2.24.0"
    \\header { title = "Triad" tagline = "FountainAI • Csound • LilyPond" }
    """
    let tempo = "\\tempo 4 = \(tempoBPM)"
    let body = "{ \n  \(tempo) \n  \(chord) \n}"
    return [header, body].joined(separator: "\n")
}
SWIFT

# Duo (two-voice) LilyPond helper (LY_DUO=1 with CS_MOTIF)
DUO="Sources/HelloCsound/Duo.swift"
cat > "$DUO" <<'SWIFT'
import Foundation

public func makeLilyPondDuo(melodyFreqs: [Double], durations: [Double], bassRootHz: Double, tempoBPM: Int = 120) -> String {
    func midi(for freq: Double) -> Int { guard freq > 0 else { return 60 }; return Int((69.0 + 12.0 * log2(freq / 440.0)).rounded()) }
    let names = ["c","cis","d","dis","e","f","fis","g","gis","a","ais","b"]
    func lilyName(for midiNote: Int) -> String {
        let pc = (midiNote % 12 + 12) % 12
        let base = names[pc]
        let d = (midiNote - 60) / 12
        if d >= 0 { return base + String(repeating: "'", count: d + 1) }
        else { return base + String(repeating: ",", count: -d - 1) }
    }
    // duration tokens with dotted support
    let quarter = 60.0 / Double(tempoBPM)
    let denoms: [Int] = [1,2,4,8,16]
    struct Cand { let ratio: Double; let label: String }
    func lilyDurToken(for sec: Double) -> String {
        let ratio = sec / quarter
        var best = Cand(ratio: Double.greatestFiniteMagnitude, label: "4")
        var bestDiff = Double.greatestFiniteMagnitude
        for d in denoms {
            let base = 4.0 / Double(d)
            let plain = Cand(ratio: base, label: String(d))
            let dotted = Cand(ratio: base * 1.5, label: String(d) + ".")
            for c in [plain, dotted] {
                let diff = abs(ratio - c.ratio)
                if diff < bestDiff { bestDiff = diff; best = c }
            }
        }
        return best.label
    }

    // melody line tokens
    let melody = zip(melodyFreqs, durations).map { (f, d) -> String in
        let n = lilyName(for: midi(for: f))
        let t = lilyDurToken(for: d)
        return "\(n)\(t)"
    }.joined(separator: " ")

    // bass: pedal tone for total duration of phrase
    let total = durations.reduce(0, +)
    let bassName = lilyName(for: midi(for: bassRootHz))
    let bassToken = lilyDurToken(for: total)
    let bass = "\(bassName)\(bassToken)"

    let header = """
    % Generated by HelloCsound duo export
    \\version "2.24.0"
    \\header { title = "Motif + Pedal" tagline = "FountainAI • Csound • LilyPond" }
    """
    let tempo = "\\tempo 4 = \(tempoBPM)"
    // Two voices in one staff
    let body = "<< \n  { \n    \(tempo) \n    \(melody) \n  } \\ \n  { \n    \(bass) \n  } \n>>"
    return [header, body].joined(separator: "\n")
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
