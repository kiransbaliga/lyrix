import AppKit
import SwiftUI

/// The floating lyrics overlay rendered inside the transparent NSWindow.
///
/// Features smooth vertical sliding transitions between lyric lines and native ProMotion window dragging with cursor feedback.
struct LyricsOverlayView: View {

    @ObservedObject var nowPlaying: NowPlayingService
    @ObservedObject var settings = UserSettings.shared

    var body: some View {
        ZStack {
            // Native Window Drag Area with custom cursor handling (openHand / closedHand)
            WindowDragView()

            // Frosted glass background card
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .opacity(settings.backgroundOpacity)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .allowsHitTesting(false) // Let drag events pass through to WindowDragView

            // Content
            VStack(spacing: 0) {
                // Top subtle drag grip
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)

                Spacer(minLength: 0)

                Group {
                    if let lyrics = nowPlaying.lyrics, !lyrics.isEmpty {
                        slidingLyricsView(lyrics)
                    } else {
                        statusView
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
            .allowsHitTesting(false) // Let drag events pass through
        }
        .frame(width: 520, height: 180)
    }

    // MARK: - Smooth Vertical Sliding Lyrics Display

    @ViewBuilder
    private func slidingLyricsView(_ lyrics: [LyricLine]) -> some View {
        let activeIdx = nowPlaying.activeLyricIndex
        let lineHeight: CGFloat = fontSizeConfig.lineHeight

        ZStack {
            ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                let offsetDistance = CGFloat(index - activeIdx)

                // Render visible lines within range
                if abs(offsetDistance) <= 2 {
                    let isCurrent = (index == activeIdx)

                    Text(line.text)
                        .font(isCurrent ? fontSizeConfig.activeFont : fontSizeConfig.fadedFont)
                        .foregroundStyle(isCurrent ? .white : .white.opacity(0.35))
                        .shadow(
                            color: isCurrent ? activeGlowColor.opacity(0.55) : .clear,
                            radius: isCurrent ? 14 : 0
                        )
                        .scaleEffect(isCurrent ? 1.04 : 0.95)
                        .opacity(isCurrent ? 1.0 : max(0.15, 0.45 - abs(offsetDistance) * 0.15))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .offset(y: offsetDistance * lineHeight)
                        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: activeIdx)
                }
            }
        }
        .frame(height: lineHeight * 3)
        .clipped()
    }

    // MARK: - Status Views

    @ViewBuilder
    private var statusView: some View {
        switch nowPlaying.lyricsStatus {
        case .idle:
            VStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.35))
                Text("Play music in Zen, Spotify, or Apple Music")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }

        case .searching:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                    .colorScheme(.dark)
                Text("Searching lyrics…")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

        case .notFound:
            VStack(spacing: 4) {
                Image(systemName: "text.page.slash")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.35))
                if let song = nowPlaying.currentSong {
                    Text("\(song.title) — \(song.artist)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
                Text("No synced lyrics available")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }

        case .found:
            Text("♪")
                .font(.title)
                .foregroundStyle(.white.opacity(0.4))

        case .error(let msg):
            Text("⚠️ \(msg)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.orange.opacity(0.7))
                .lineLimit(2)
        }
    }

    // MARK: - Appearance Helpers

    private var activeGlowColor: Color {
        switch settings.activeGlowColor {
        case "purple": return .purple
        case "gold": return .yellow
        case "green": return .green
        case "pink": return .pink
        case "white": return .white
        default: return .cyan
        }
    }

    private var fontSizeConfig: (activeFont: Font, fadedFont: Font, lineHeight: CGFloat) {
        switch settings.fontSize {
        case "small":
            return (
                .system(size: 18, weight: .bold, design: .rounded),
                .system(size: 13, weight: .medium, design: .rounded),
                32
            )
        case "large":
            return (
                .system(size: 25, weight: .bold, design: .rounded),
                .system(size: 17, weight: .medium, design: .rounded),
                44
            )
        default: // medium
            return (
                .system(size: 21, weight: .bold, design: .rounded),
                .system(size: 15, weight: .medium, design: .rounded),
                38
            )
        }
    }
}

// MARK: - Native Window Drag View with Cursor Feedback

struct WindowDragView: NSViewRepresentable {

    func makeNSView(context: Context) -> DragNSView {
        DragNSView()
    }

    func updateNSView(_ nsView: DragNSView, context: Context) {}

    class DragNSView: NSView {

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateTrackingAreas()
        }

        override func resetCursorRects() {
            discardCursorRects()
            addCursorRect(bounds, cursor: .openHand)
        }

        override func mouseDown(with event: NSEvent) {
            NSCursor.closedHand.push()
            window?.performDrag(with: event)
            NSCursor.pop()
        }
    }
}
