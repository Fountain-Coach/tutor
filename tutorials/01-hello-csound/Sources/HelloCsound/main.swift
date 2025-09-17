import Foundation

do {
    let result = try CsoundPlayer().play()
    print("Generated sample count: \(result.samples.count)")
} catch {
    fputs("Csound simulation error: \(error)\n", stderr)
}
