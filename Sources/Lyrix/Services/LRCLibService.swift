import Foundation

/// Async client for the LRCLIB API (https://lrclib.net/).
/// Fetches time-synced and plain lyrics for a given track.
actor LRCLibService {

    private let baseURL = "https://lrclib.net/api"
    private let clientID = "Lyrix/1.0.0 (https://github.com/lyrix)"

    // MARK: - Public API

    /// Fetches lyrics for a track. Tries exact match first, then falls back to search.
    func fetchLyrics(
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval? = nil
    ) async throws -> LyricsResult? {
        // 1. Try exact match
        if let result = try await fetchExact(
            title: title, artist: artist, album: album, duration: duration
        ) {
            return result
        }
        // 2. Fallback to search query
        return try await search(query: "\(title) \(artist)")
    }

    // MARK: - Private

    private func fetchExact(
        title: String, artist: String, album: String?, duration: TimeInterval?
    ) async throws -> LyricsResult? {
        var components = URLComponents(string: "\(baseURL)/get")!
        var items = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]
        if let album { items.append(URLQueryItem(name: "album_name", value: album)) }
        if let duration { items.append(URLQueryItem(name: "duration", value: "\(Int(duration))")) }
        components.queryItems = items

        var request = URLRequest(url: components.url!)
        request.setValue(clientID, forHTTPHeaderField: "Lrclib-Client")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { return nil }
        guard http.statusCode == 200 else { return nil }

        let decoded = try JSONDecoder().decode(LRCLibResponse.self, from: data)
        return decoded.toLyricsResult()
    }

    private func search(query: String) async throws -> LyricsResult? {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [URLQueryItem(name: "q", value: query)]

        var request = URLRequest(url: components.url!)
        request.setValue(clientID, forHTTPHeaderField: "Lrclib-Client")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let results = try JSONDecoder().decode([LRCLibResponse].self, from: data)
        // Prefer entries that have synced lyrics
        guard let best = results.first(where: { $0.syncedLyrics != nil }) ?? results.first else {
            return nil
        }
        return best.toLyricsResult()
    }
}

// MARK: - API response models

/// Represents the result of a lyrics lookup, ready for use by the app.
struct LyricsResult {
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: TimeInterval?
    let syncedLyrics: [LyricLine]?
    let plainLyrics: String?
    let instrumental: Bool
}

/// Raw JSON response from LRCLIB's `/api/get` and `/api/search` endpoints.
private struct LRCLibResponse: Codable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?

    func toLyricsResult() -> LyricsResult {
        LyricsResult(
            trackName: trackName,
            artistName: artistName,
            albumName: albumName,
            duration: duration,
            syncedLyrics: syncedLyrics.map { LRCParser.parse($0) },
            plainLyrics: plainLyrics,
            instrumental: instrumental ?? false
        )
    }
}
