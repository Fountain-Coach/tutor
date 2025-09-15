import Foundation

/// Minimal local persistence utility to simulate FountainStore.
/// Stores JSON files in the current working directory by filename.
public struct FountainStore<T: Codable> {
    private let filename: String
    private let url: URL

    public init(filename: String) {
        self.filename = filename
        self.url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(filename)
    }

    public func save(_ value: T) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    public func load() throws -> [T] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        // Try decoding an array first; if it fails, fall back to a single value
        if let arr = try? JSONDecoder().decode([T].self, from: data) {
            return arr
        } else {
            let single = try JSONDecoder().decode(T.self, from: data)
            return [single]
        }
    }
}

