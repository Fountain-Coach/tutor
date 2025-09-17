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
