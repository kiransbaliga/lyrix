import AppKit
import Combine
import Foundation

/// Observable settings store persisted in UserDefaults.
@MainActor
final class UserSettings: ObservableObject {

    static let shared = UserSettings()

    // MARK: - Published Settings

    @Published var toggleOverlayShortcut: ShortcutKey {
        didSet { saveShortcut(toggleOverlayShortcut, forKey: "shortcut.toggleOverlay") }
    }

    @Published var toggleClickThroughShortcut: ShortcutKey {
        didSet { saveShortcut(toggleClickThroughShortcut, forKey: "shortcut.toggleClickThrough") }
    }

    @Published var activeGlowColor: String {
        didSet { UserDefaults.standard.set(activeGlowColor, forKey: "appearance.glowColor") }
    }

    @Published var fontSize: String {
        didSet { UserDefaults.standard.set(fontSize, forKey: "appearance.fontSize") }
    }

    @Published var backgroundOpacity: Double {
        didSet { UserDefaults.standard.set(backgroundOpacity, forKey: "appearance.bgOpacity") }
    }

    // MARK: - Initialization

    init() {
        // Load shortcuts or use defaults
        self.toggleOverlayShortcut = Self.loadShortcut(
            forKey: "shortcut.toggleOverlay",
            defaultVal: .defaultToggleOverlay
        )
        self.toggleClickThroughShortcut = Self.loadShortcut(
            forKey: "shortcut.toggleClickThrough",
            defaultVal: .defaultToggleClickThrough
        )

        // Load appearance
        self.activeGlowColor = UserDefaults.standard.string(forKey: "appearance.glowColor") ?? "cyan"
        self.fontSize = UserDefaults.standard.string(forKey: "appearance.fontSize") ?? "medium"
        let savedOpacity = UserDefaults.standard.double(forKey: "appearance.bgOpacity")
        self.backgroundOpacity = savedOpacity > 0 ? savedOpacity : 0.75
    }

    // MARK: - Persistence helpers

    private func saveShortcut(_ shortcut: ShortcutKey, forKey key: String) {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadShortcut(forKey key: String, defaultVal: ShortcutKey) -> ShortcutKey {
        guard let data = UserDefaults.standard.data(forKey: key),
              let loaded = try? JSONDecoder().decode(ShortcutKey.self, from: data) else {
            return defaultVal
        }
        return loaded
    }

    func resetShortcutsToDefaults() {
        toggleOverlayShortcut = .defaultToggleOverlay
        toggleClickThroughShortcut = .defaultToggleClickThrough
    }
}
