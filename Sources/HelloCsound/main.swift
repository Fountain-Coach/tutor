import Foundation

do {
    let samples = try CsoundPlayer().play()
    print("Generated \(samples.count) samples from hello.csd")
} catch {
    print("Playback failed: \(error)")
}
