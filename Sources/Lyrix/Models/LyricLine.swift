import Foundation

/// A single time-stamped lyric line parsed from LRC format.
struct LyricLine: Identifiable, Codable, Equatable {
    let id: UUID
    let time: TimeInterval   // seconds from track start
    let text: String

    init(time: TimeInterval, text: String) {
        self.id = UUID()
        self.time = time
        self.text = text
    }
}
