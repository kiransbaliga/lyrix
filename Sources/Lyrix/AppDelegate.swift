import AppKit
import SwiftUI

/// Application delegate — wires services together and manages windows and shortcuts.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    let nowPlaying = NowPlayingService()
    let overlayController = OverlayWindowController()
    let settingsController = SettingsWindowController()
    private var shortcutManager: GlobalShortcutManager?

    @Published var isOverlayVisible = true
    @Published var isClickThrough = false

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock — menu bar only
        NSApp.setActivationPolicy(.accessory)

        // Setup global shortcuts
        setupShortcuts()

        // Show the lyrics overlay on launch
        showOverlay()
    }

    // MARK: - Global Shortcuts

    private func setupShortcuts() {
        let manager = GlobalShortcutManager()
        manager.onToggleOverlay = { [weak self] in
            self?.toggleOverlay()
        }
        manager.onToggleClickThrough = { [weak self] in
            self?.toggleClickThrough()
        }
        self.shortcutManager = manager
    }

    // MARK: - Actions

    func showOverlay() {
        let view = LyricsOverlayView(nowPlaying: nowPlaying)
        overlayController.showOverlay(with: view)
        isOverlayVisible = true
    }

    func toggleOverlay() {
        if overlayController.isVisible {
            overlayController.hideOverlay()
            isOverlayVisible = false
        } else {
            showOverlay()
        }
    }

    func toggleClickThrough() {
        isClickThrough = overlayController.toggleClickThrough()
    }

    func showSettings() {
        settingsController.showSettings()
    }
}
