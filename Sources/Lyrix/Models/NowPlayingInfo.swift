import Foundation

/// Snapshot of the currently playing track from macOS Now Playing.
struct NowPlayingInfo: Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval

    /// Elapsed playback time at the moment of `timestamp`.
    var elapsedTime: TimeInterval
    /// 0 = paused, 1 = normal playback, 2 = 2× speed, etc.
    var playbackRate: Double
    /// When `elapsedTime` was last sampled.
    var timestamp: Date

    // MARK: - Computed

    /// Interpolated current playback position, accounting for playback rate.
    var currentTime: TimeInterval {
        guard playbackRate > 0 else { return elapsedTime }
        return elapsedTime + playbackRate * Date().timeIntervalSince(timestamp)
    }

    /// Identity key for deduplicating song-change detection.
    var songID: String {
        "\(artist.lowercased())|\(title.lowercased())"
    }

    // MARK: - Equatable (by song identity, not position)

    static func == (lhs: NowPlayingInfo, rhs: NowPlayingInfo) -> Bool {
        lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
    }
}
