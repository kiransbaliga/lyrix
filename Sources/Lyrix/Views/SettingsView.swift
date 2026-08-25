import AppKit
import Combine
import SwiftUI

/// View model managing settings UI state without @State macros.
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedTab: SettingsTab = .shortcuts
    @Published var recordingShortcutType: String? = nil // "toggleOverlay" or "toggleClickThrough"

    private var localEventMonitor: Any?

    enum SettingsTab: String, CaseIterable, Identifiable {
        case shortcuts = "Shortcuts"
        case appearance = "Appearance"
        case about = "About"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .shortcuts: return "keyboard"
            case .appearance: return "paintpalette"
            case .about: return "info.circle"
            }
        }
    }

    func startRecording(for type: String) {
        stopRecording()
        recordingShortcutType = type

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let type = self.recordingShortcutType else { return event }

            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])

            // Escape key cancels
            if event.keyCode == 53 {
                self.stopRecording()
                return nil
            }

            // Modifier + key
            if !modifiers.isEmpty && event.keyCode != 55 && event.keyCode != 56 && event.keyCode != 58 && event.keyCode != 59 {
                let newShortcut = ShortcutKey(keyCode: event.keyCode, modifierFlags: modifiers)
                if type == "toggleOverlay" {
                    UserSettings.shared.toggleOverlayShortcut = newShortcut
                } else if type == "toggleClickThrough" {
                    UserSettings.shared.toggleClickThroughShortcut = newShortcut
                }
                self.stopRecording()
                return nil
            }

            return nil
        }
    }

    func stopRecording() {
        recordingShortcutType = nil
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
}

/// Settings window with tabs for Shortcuts, Appearance, and About.
struct SettingsView: View {

    @ObservedObject var settings = UserSettings.shared
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker header
            HStack(spacing: 20) {
                ForEach(SettingsViewModel.SettingsTab.allCases) { tab in
                    Button {
                        viewModel.selectedTab = tab
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                        }
                        .font(.system(size: 13, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(viewModel.selectedTab == tab ? .accentColor : .secondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            viewModel.selectedTab == tab
                                ? RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.12))
                                : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Content Area
            Group {
                switch viewModel.selectedTab {
                case .shortcuts:
                    shortcutsTab
                case .appearance:
                    appearanceTab
                case .about:
                    aboutTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
        }
        .frame(width: 480, height: 340)
    }

    // MARK: - Shortcuts Tab

    @ViewBuilder
    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Global Keyboard Shortcuts")
                .font(.headline)

            VStack(spacing: 12) {
                shortcutRow(
                    title: "Toggle Overlay",
                    description: "Show or hide the floating lyrics window",
                    shortcutString: settings.toggleOverlayShortcut.displayString,
                    type: "toggleOverlay"
                )

                Divider()

                shortcutRow(
                    title: "Toggle Click-Through",
                    description: "Pass mouse clicks through to apps behind the lyrics",
                    shortcutString: settings.toggleClickThroughShortcut.displayString,
                    type: "toggleClickThrough"
                )
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))

            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    settings.resetShortcutsToDefaults()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func shortcutRow(
        title: String,
        description: String,
        shortcutString: String,
        type: String
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            let isRec = (viewModel.recordingShortcutType == type)
            Button {
                if isRec {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording(for: type)
                }
            } label: {
                Text(isRec ? "Type keys…" : shortcutString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(isRec ? .accentColor : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRec ? Color.accentColor.opacity(0.15) : Color(nsColor: .quaternaryLabelColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRec ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Appearance Tab

    @ViewBuilder
    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Overlay Appearance")
                .font(.headline)

            VStack(spacing: 14) {
                // Glow Color
                HStack {
                    Text("Highlight Color")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Picker("", selection: $settings.activeGlowColor) {
                        Text("Cyan").tag("cyan")
                        Text("Purple").tag("purple")
                        Text("Gold").tag("gold")
                        Text("Green").tag("green")
                        Text("Pink").tag("pink")
                        Text("White").tag("white")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                Divider()

                // Font Size
                HStack {
                    Text("Font Size")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Picker("", selection: $settings.fontSize) {
                        Text("Compact").tag("small")
                        Text("Standard").tag("medium")
                        Text("Large").tag("large")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                Divider()

                // Background Opacity
                HStack {
                    Text("Background Blur")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Slider(value: $settings.backgroundOpacity, in: 0.2...1.0, step: 0.05)
                        .frame(width: 150)
                    Text("\(Int(settings.backgroundOpacity * 100))%")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 40, alignment: .trailing)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))

            Spacer()
        }
    }

    // MARK: - About Tab

    @ViewBuilder
    private var aboutTab: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.cyan.gradient)

            VStack(spacing: 4) {
                Text("Lyrix")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Version 1.0.0")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Text("A minimal, transparent, always-on-top lyrics overlay for macOS. Designed to let you glance at time-synced lyrics while you continue your work.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 40)

            VStack(spacing: 6) {
                HStack(spacing: 16) {
                    Link("LRCLIB Database", destination: URL(string: "https://lrclib.net")!)
                        .font(.system(size: 11))
                    Text("•").foregroundColor(.secondary)
                    Link("media-control Engine", destination: URL(string: "https://github.com/ungive/media-control")!)
                        .font(.system(size: 11))
                }
                Text("Supports YouTube Music (Zen/Chrome), Spotify & Apple Music")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))
            }

            Spacer()
        }
    }
}
