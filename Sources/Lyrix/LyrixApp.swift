import SwiftUI

/// Lyrix — a transparent, always-on-top lyrics overlay for macOS.
@main
struct LyrixApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Lyrix", systemImage: "music.note.list") {
            LyrixMenuContent(
                nowPlaying: appDelegate.nowPlaying,
                appDelegate: appDelegate
            )
        }
    }
}

// MARK: - Menu bar content

/// The dropdown menu shown when clicking the 🎵 menu bar icon.
private struct LyrixMenuContent: View {

    @ObservedObject var nowPlaying: NowPlayingService
    @ObservedObject var appDelegate: AppDelegate
    @ObservedObject var settings = UserSettings.shared

    var body: some View {
        // Current song info
        if let song = nowPlaying.currentSong {
            Button {} label: {
                Text("🎵 \(song.title)")
            }
            .disabled(true)

            Button {} label: {
                Text("    \(song.artist)")
            }
            .disabled(true)
        } else {
            Button {} label: {
                Text("No music playing")
            }
            .disabled(true)
        }

        Divider()

        // Lyrics status
        switch nowPlaying.lyricsStatus {
        case .found:
            Button {} label: {
                Text("✅ Synced lyrics loaded")
            }
            .disabled(true)
        case .searching:
            Button {} label: {
                Text("⏳ Searching lyrics…")
            }
            .disabled(true)
        case .notFound:
            Button {} label: {
                Text("❌ No lyrics found")
            }
            .disabled(true)
        case .error:
            Button {} label: {
                Text("⚠️ Lyrics error")
            }
            .disabled(true)
        case .idle:
            Button {} label: {
                Text("💤 Waiting for music")
            }
            .disabled(true)
        }

        Divider()

        // Toggle overlay visibility with dynamic shortcut hint
        Button("\(appDelegate.isOverlayVisible ? "Hide Overlay" : "Show Overlay")   (\(settings.toggleOverlayShortcut.displayString))") {
            appDelegate.toggleOverlay()
        }

        // Center overlay on screen
        Button("Center Overlay on Screen") {
            appDelegate.overlayController.resetPositionToCenter()
            appDelegate.isOverlayVisible = true
        }

        // Toggle click-through with dynamic shortcut hint
        Button("\(appDelegate.isClickThrough ? "Disable Click-Through" : "Enable Click-Through")   (\(settings.toggleClickThroughShortcut.displayString))") {
            appDelegate.toggleClickThrough()
        }

        Divider()

        // Settings
        Button("Settings…") {
            appDelegate.showSettings()
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Quit Lyrix") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
