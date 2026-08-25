import AppKit
import Foundation

/// Listens for system-wide and local keyboard shortcuts and dispatches actions.
@MainActor
final class GlobalShortcutManager {

    private var globalMonitor: Any?
    private var localMonitor: Any?

    var onToggleOverlay: (() -> Void)?
    var onToggleClickThrough: (() -> Void)?

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        stopMonitoring()

        // 1. Global monitor: triggers when other applications are focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleKeyEvent(event)
            }
        }

        // 2. Local monitor: triggers when Lyrix itself or its windows are focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // consume event
            }
            return event
        }
    }

    func stopMonitoring() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let settings = UserSettings.shared
        let eventFlags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let currentKey = ShortcutKey(keyCode: event.keyCode, modifierFlags: eventFlags)

        if currentKey == settings.toggleOverlayShortcut {
            onToggleOverlay?()
            return true
        } else if currentKey == settings.toggleClickThroughShortcut {
            onToggleClickThrough?()
            return true
        }

        return false
    }
}
