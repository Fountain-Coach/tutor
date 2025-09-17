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
