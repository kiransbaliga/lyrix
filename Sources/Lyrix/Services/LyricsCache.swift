import Foundation

/// File-based cache for lyrics stored in ~/Library/Caches/Lyrix/.
/// Keyed by a hash of artist + title to avoid repeated API calls.
actor LyricsCache {

    private let cacheDirectory: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("Lyrix", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Returns cached lyrics for the given song, or `nil` if not cached.
    func get(artist: String, title: String) -> [LyricLine]? {
        let fileURL = fileURL(artist: artist, title: title)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([LyricLine].self, from: data)
    }

    /// Caches parsed lyrics for the given song.
    func set(artist: String, title: String, lyrics: [LyricLine]) {
        let fileURL = fileURL(artist: artist, title: title)
        guard let data = try? JSONEncoder().encode(lyrics) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Checks whether lyrics are cached (without loading them).
    func has(artist: String, title: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(artist: artist, title: title).path)
    }

    // MARK: - Private

    private func fileURL(artist: String, title: String) -> URL {
        let key = cacheKey(artist: artist, title: title)
        return cacheDirectory.appendingPathComponent("\(key).json")
    }

    private func cacheKey(artist: String, title: String) -> String {
        let combined = "\(artist.lowercased())|\(title.lowercased())"
        // DJB2 hash — fast, simple, good distribution for filenames
        var hash: UInt64 = 5381
        for byte in combined.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(byte)
        }
        return String(hash, radix: 16)
    }
}
