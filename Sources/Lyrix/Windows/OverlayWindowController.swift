import AppKit
import SwiftUI

/// Manages the transparent, borderless, always-on-top overlay window.
@MainActor
final class OverlayWindowController {

    private(set) var window: NSWindow?
    private let positionKey = "lyrix.overlay.position"
    private var isClickThrough = false

    // MARK: - Show / Hide

    func showOverlay<Content: View>(with rootView: Content) {
        if let window {
            ensureOnScreen(window)
            window.orderFrontRegardless()
            return
        }

        let hosting = NSHostingView(rootView: rootView)
        hosting.layer?.isOpaque = false

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 180),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // --- Transparency ---
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false

        // --- Always on top, visible on all Spaces ---
        win.level = .floating
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // --- Mouse and Drag Settings ---
        win.isMovableByWindowBackground = false
        win.ignoresMouseEvents = false

        // --- Content ---
        win.contentView = hosting
        win.isReleasedWhenClosed = false

        // Restore saved position or center on screen safely
        restorePosition(for: win)
        win.orderFrontRegardless()

        self.window = win

        // Persist position on move
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: win,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.savePosition()
            }
        }
    }

    func hideOverlay() {
        savePosition()
        window?.orderOut(nil)
    }

    func toggleVisibility<Content: View>(with rootView: Content) {
        if let window, window.isVisible {
            hideOverlay()
        } else {
            showOverlay(with: rootView)
        }
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    // MARK: - Click-through

    func toggleClickThrough() -> Bool {
        isClickThrough.toggle()
        window?.ignoresMouseEvents = isClickThrough
        return isClickThrough
    }

    func setClickThrough(_ enabled: Bool) {
        isClickThrough = enabled
        window?.ignoresMouseEvents = enabled
    }

    // MARK: - Position Management & Safe Screen Clamping

    func resetPositionToCenter() {
        guard let window else { return }
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (window.frame.width / 2)
            let y = screenFrame.maxY - window.frame.height - 80
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }
        window.orderFrontRegardless()
        savePosition()
    }

    func savePosition() {
        guard let origin = window?.frame.origin else { return }
        UserDefaults.standard.set(
            "\(origin.x),\(origin.y)",
            forKey: positionKey
        )
    }

    private func restorePosition(for window: NSWindow) {
        if let saved = UserDefaults.standard.string(forKey: positionKey) {
            let parts = saved.components(separatedBy: ",")
            if parts.count == 2,
               let x = Double(parts[0]),
               let y = Double(parts[1]) {
                let targetRect = NSRect(x: x, y: y, width: window.frame.width, height: window.frame.height)
                
                // Validate that this saved coordinate is on one of the currently active screens
                let isVisibleOnAnyScreen = NSScreen.screens.contains { screen in
                    screen.visibleFrame.intersects(targetRect)
                }
                
                if isVisibleOnAnyScreen {
                    window.setFrameOrigin(NSPoint(x: x, y: y))
                    return
                }
            }
        }

        // Default: Top-center of primary screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (window.frame.width / 2)
            let y = screenFrame.maxY - window.frame.height - 80
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }
    }

    private func ensureOnScreen(_ window: NSWindow) {
        let isVisibleOnAnyScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(window.frame)
        }
        if !isVisibleOnAnyScreen {
            resetPositionToCenter()
        }
    }
}
