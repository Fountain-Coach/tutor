import Foundation

func playTone() {
    do {
        let samples = try CsoundPlayer().play()
        print("Generated \(samples.count) samples from hello.csd")
    } catch {
        print("Playback failed: \(error)")
    }
}

// Play tone on launch
playTone()

// Allow user to trigger tone again via input
print("Press Enter to play again or type q to quit.")
while let input = readLine(), input.isEmpty {
    playTone()
    print("Press Enter to play again or type q to quit.")
}
