import Foundation

public func play(samples: [Float], sampleRate: Int, seconds: Double) throws {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("csound_studio_\(UUID().uuidString).wav")
    try writeWAV(samples: samples, sampleRate: sampleRate, url: url)
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
    task.arguments = [url.path]
    do { try task.run(); task.waitUntilExit() } catch {
        print("Saved WAV to: \(url.path) (audio playback not available)")
    }
}

public func playFile(url: URL) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
    task.arguments = [url.path]
    do { try task.run(); task.waitUntilExit() } catch {
        print("Saved WAV to: \(url.path) (audio playback not available)")
    }
}

private func writeWAV(samples: [Float], sampleRate: Int, url: URL) throws {
    let numChannels: UInt16 = 1
    let bitsPerSample: UInt16 = 16
    let byteRate: UInt32 = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bitsPerSample / 8)
    let blockAlign: UInt16 = numChannels * (bitsPerSample / 8)

    var pcm = Data(); pcm.reserveCapacity(samples.count * 2)
    for s in samples {
        let v = Int16(max(-1.0, min(1.0, s)) * 32767.0)
        var le = UInt16(bitPattern: v).littleEndian
        withUnsafeBytes(of: &le) { pcm.append(contentsOf: $0) }
    }
    var data = Data()
    func append(_ s: String) { data.append(s.data(using: .ascii)!) }
    func append32(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }
    func append16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }
    append("RIFF"); append32(UInt32(36 + pcm.count)); append("WAVE")
    append("fmt "); append32(16); append16(1); append16(numChannels); append32(UInt32(sampleRate)); append32(byteRate); append16(blockAlign); append16(bitsPerSample)
    append("data"); append32(UInt32(pcm.count)); data.append(pcm)
    try data.write(to: url)
}
