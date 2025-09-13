// Minimal HTTP SSE client for Tutor CLI /events
// Usage: swiftc sse_http_client.swift -o sse-http && ./sse-http http://127.0.0.1:53127/events

import Foundation

let urlStr = CommandLine.arguments.dropFirst().first ?? "http://127.0.0.1:53127/events"
guard let url = URL(string: urlStr) else { fatalError("Invalid URL") }

var req = URLRequest(url: url)
req.setValue("text/event-stream", forHTTPHeaderField: "Accept")

let sem = DispatchSemaphore(value: 0)

class SSEDelegate: NSObject, URLSessionDataDelegate {
    var buffer = Data()
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        let delim = Data("\n\n".utf8)
        while let range = buffer.range(of: delim) {
            let chunk = buffer.subdata(in: 0..<range.lowerBound)
            if let s = String(data: chunk, encoding: .utf8) {
                print(s)
            }
            buffer.removeSubrange(0..<range.upperBound)
        }
    }
}

let delegate = SSEDelegate()
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
let task = session.dataTask(with: req) { _, _, _ in }
task.resume()

// Keep process alive until interrupted
signal(SIGINT) { _ in exit(0) }
RunLoop.main.run()

