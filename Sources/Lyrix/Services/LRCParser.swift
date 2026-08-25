import Foundation

/// Parses LRC-format lyric strings into an array of `LyricLine`.
///
/// Example LRC input:
/// ```
/// [00:12.34] Hello world
/// [00:15.67] Second line
/// ```
enum LRCParser {

    /// Parses raw LRC text into sorted `[LyricLine]`.
    static func parse(_ lrcText: String) -> [LyricLine] {
        let lines = lrcText.components(separatedBy: .newlines)
        // Matches [mm:ss.xx] or [mm:ss.xxx]
        let pattern = #"\[(\d{1,3}):(\d{2})\.(\d{2,3})\]"#
        let regex = try! NSRegularExpression(pattern: pattern)
        var result: [LyricLine] = []

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)

            guard let match = regex.firstMatch(in: line, range: range) else {
                continue
            }

            let minutes = Int(nsLine.substring(with: match.range(at: 1)))!
            let seconds = Int(nsLine.substring(with: match.range(at: 2)))!
            let fractionStr = nsLine.substring(with: match.range(at: 3))

            let fraction: Double
            if fractionStr.count <= 2 {
                fraction = Double(fractionStr)! / 100.0
            } else {
                fraction = Double(fractionStr)! / 1000.0
            }

            let totalTime = Double(minutes) * 60.0 + Double(seconds) + fraction

            // Strip the timestamp tag(s) to get the lyric text
            let text = regex.stringByReplacingMatches(
                in: line,
                range: range,
                withTemplate: ""
            ).trimmingCharacters(in: .whitespaces)

            // Skip blank lines and metadata tags like [ti:...], [ar:...]
            guard !text.isEmpty, !text.hasPrefix("[") else { continue }

            result.append(LyricLine(time: totalTime, text: text))
        }

        return result.sorted { $0.time < $1.time }
    }
}
