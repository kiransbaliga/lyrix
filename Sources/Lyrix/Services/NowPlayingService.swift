import AppKit
import Combine
import Foundation

/// Central service that reads Now Playing metadata from macOS and manages lyrics state.
///
/// **Primary engine**: `media-control stream` subprocess (supports macOS 15.4+ and macOS 27+ with all browsers/apps).
/// **Fallback engine**: In-process `MediaRemote.framework` and AppleScript.
@MainActor
final class NowPlayingService: ObservableObject {

    // MARK: - Published state

    @Published var currentSong: NowPlayingInfo?
    @Published var lyrics: [LyricLine]?
    @Published var lyricsStatus: LyricsStatus = .idle
    @Published var activeLyricIndex: Int = 0

    enum LyricsStatus: Equatable {
        case idle
        case searching
        case found
        case notFound
        case error(String)
    }

    // MARK: - Private

    private let lrcLib = LRCLibService()
    private let cache = LyricsCache()
    private var syncTimer: Timer?
    private var streamProcess: Process?
    private var lastSongID: String?
    private let isoFormatter = ISO8601DateFormatter()

    // MARK: - Lifecycle

    init() {
        startSyncTimer()
        startNowPlayingStream()
    }

    deinit {
        syncTimer?.invalidate()
        streamProcess?.terminate()
    }

    // MARK: - 100ms Sync Timer for smooth lyric interpolation

    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateActiveLyricIndex()
            }
        }
    }

    private func updateActiveLyricIndex() {
        guard let lyrics = self.lyrics, !lyrics.isEmpty,
              let song = self.currentSong,
              song.playbackRate > 0 else { return }

        let time = song.currentTime
        let newIndex = findIndex(in: lyrics, at: time)
        if newIndex != self.activeLyricIndex {
            self.activeLyricIndex = newIndex
        }
    }

    private func findIndex(in lyrics: [LyricLine], at time: TimeInterval) -> Int {
        var lo = 0
        var hi = lyrics.count - 1
        var result = 0

        while lo <= hi {
            let mid = (lo + hi) / 2
            if lyrics[mid].time <= time {
                result = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return result
    }

    // MARK: - Media-Control Streaming Engine

    private func startNowPlayingStream() {
        guard let binaryPath = findMediaControlBinary() else {
            print("[Lyrix] ⚠️ media-control binary not found — falling back to in-process poll")
            startInProcessFallback()
            return
        }

        print("[Lyrix] 🚀 Starting media-control stream at \(binaryPath)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [binaryPath, "stream", "--no-artwork", "--no-diff"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                print("[Lyrix] ⚠️ Stream process terminated — restarting in 2 seconds...")
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self?.startNowPlayingStream()
            }
        }

        do {
            try process.run()
            self.streamProcess = process
            readStream(from: pipe.fileHandleForReading)
        } catch {
            print("[Lyrix] ❌ Failed to start media-control stream: \(error)")
            startInProcessFallback()
        }
    }

    private func readStream(from fileHandle: FileHandle) {
        Task.detached { [weak self] in
            do {
                for try await line in fileHandle.bytes.lines {
                    guard let data = line.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let payload = json["payload"] as? [String: Any] else {
                        continue
                    }

                    await self?.handleStreamPayload(payload)
                }
            } catch {
                print("[Lyrix] Stream reading finished: \(error)")
            }
        }
    }

    private func handleStreamPayload(_ payload: [String: Any]) {
        guard let title = payload["title"] as? String, !title.isEmpty else {
            handleNoMusic()
            return
        }

        let artist = payload["artist"] as? String ?? "Unknown Artist"
        let album = payload["album"] as? String ?? ""
        let duration = payload["duration"] as? Double ?? 0
        let elapsed = payload["elapsedTime"] as? Double ?? 0
        let isPlaying = payload["playing"] as? Bool ?? true
        let playbackRate = isPlaying ? (payload["playbackRate"] as? Double ?? 1.0) : 0.0

        var timestamp = Date()
        if let timeStr = payload["timestamp"] as? String,
           let parsedDate = isoFormatter.date(from: timeStr) {
            timestamp = parsedDate
        }

        print("[Lyrix] 🎵 Now Playing: \"\(title)\" by \(artist) (elapsed: \(String(format: "%.1f", elapsed))s/\(String(format: "%.1f", duration))s, playing: \(isPlaying))")

        let song = NowPlayingInfo(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsed,
            playbackRate: playbackRate,
            timestamp: timestamp
        )

        updateSong(song)
    }

    private func findMediaControlBinary() -> String? {
        var candidates: [String] = []

        // 1. Inside App Bundle (same folder as executable or Resources)
        if let bundleDir = Bundle.main.executableURL?.deletingLastPathComponent().path {
            candidates.append("\(bundleDir)/media-control")
        }
        if let resURL = Bundle.main.url(forResource: "media-control", withExtension: nil)?.path {
            candidates.append(resURL)
        }

        // 2. System / Homebrew paths
        candidates.append(contentsOf: [
            "/opt/homebrew/bin/media-control",
            "/usr/local/bin/media-control",
            "/usr/bin/media-control"
        ])

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    // MARK: - In-Process Fallback (MediaRemote / AppleScript)

    private func startInProcessFallback() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollAppleScript()
            }
        }
    }

    private func pollAppleScript() {
        let src = """
        tell application "System Events"
            if exists process "Spotify" then
                tell application "Spotify"
                    if player state is playing then
                        return name of current track & "||" & artist of current track & "||" & album of current track & "||" & (player position as string) & "||" & ((duration of current track / 1000) as string)
                    end if
                end tell
            end if
            if exists process "Music" then
                tell application "Music"
                    if player state is playing then
                        return name of current track & "||" & artist of current track & "||" & album of current track & "||" & (player position as string) & "||" & (duration of current track as string)
                    end if
                end tell
            end if
        end tell
        return "NOT_PLAYING"
        """
        guard let script = NSAppleScript(source: src) else { return }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        guard error == nil, let output = result.stringValue, output != "NOT_PLAYING" else {
            handleNoMusic()
            return
        }

        let parts = output.components(separatedBy: "||")
        guard parts.count >= 5 else { return }

        let song = NowPlayingInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            duration: Double(parts[4]) ?? 0,
            elapsedTime: Double(parts[3]) ?? 0,
            playbackRate: 1.0,
            timestamp: Date()
        )
        updateSong(song)
    }

    // MARK: - State Management & Lyrics Loading

    private func updateSong(_ song: NowPlayingInfo) {
        let songID = song.songID
        currentSong = song

        guard songID != lastSongID else { return }
        lastSongID = songID
        loadLyrics(for: song)
    }

    private func handleNoMusic() {
        if currentSong != nil {
            currentSong = nil
            lyrics = nil
            lyricsStatus = .idle
            lastSongID = nil
        }
    }

    private func loadLyrics(for song: NowPlayingInfo) {
        lyrics = nil
        lyricsStatus = .searching
        print("[Lyrix] 🔍 Fetching lyrics for: \(song.title) - \(song.artist)...")

        Task {
            // 1. Check cache
            if let cached = await cache.get(artist: song.artist, title: song.title) {
                self.lyrics = cached
                self.lyricsStatus = cached.isEmpty ? .notFound : .found
                print("[Lyrix] 📦 Loaded from cache: \(cached.count) lines")
                return
            }

            // 2. Fetch from LRCLIB
            do {
                guard let result = try await lrcLib.fetchLyrics(
                    title: song.title,
                    artist: song.artist,
                    album: song.album.isEmpty ? nil : song.album,
                    duration: song.duration > 0 ? song.duration : nil
                ) else {
                    self.lyricsStatus = .notFound
                    print("[Lyrix] ❌ No lyrics found on LRCLIB")
                    await cache.set(artist: song.artist, title: song.title, lyrics: [])
                    return
                }

                if let synced = result.syncedLyrics, !synced.isEmpty {
                    self.lyrics = synced
                    self.lyricsStatus = .found
                    print("[Lyrix] ✅ Found \(synced.count) synced lyric lines!")
                    await cache.set(artist: song.artist, title: song.title, lyrics: synced)
                } else if result.instrumental {
                    self.lyricsStatus = .notFound
                    print("[Lyrix] 🎼 Instrumental track")
                    await cache.set(artist: song.artist, title: song.title, lyrics: [])
                } else {
                    self.lyricsStatus = .notFound
                    print("[Lyrix] ⚠️ Only plain/unsynced lyrics found")
                    await cache.set(artist: song.artist, title: song.title, lyrics: [])
                }
            } catch {
                print("[Lyrix] ❌ Lyrics fetch error: \(error)")
                self.lyricsStatus = .error(error.localizedDescription)
            }
        }
    }
}
