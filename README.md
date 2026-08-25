# Lyrix

A lightweight, transparent floating lyrics overlay for macOS. Lyrix passively listens to system-wide media playback events and displays time-synced lyrics with sub-second timeline interpolation and hardware-accelerated animations.

Author: [Kiran S Baliga](https://baliga.dev)  
License: [MIT](LICENSE)

---

## Overview

Lyrix operates as a menu bar accessory application with an always-on-top, borderless floating window. It detects active audio playback from web browsers and desktop media players, queries synchronized LRC lyrics, and renders a 3-line rolling lyrics display.

### Key Capabilities

- **Passive Event Streaming**: Connects directly to the macOS `mediaremoted` subsystem via a lightweight daemon. Captures playback state without recording system audio or requesting microphone permissions.
- **Universal Player Support**: Works out of the box with Zen Browser, Google Chrome, Arc, Brave, Spotify, Apple Music, and other MPRemoteCommandCenter-compliant players.
- **Sub-Second Timeline Interpolation**: Compensates for variable playback reporting intervals using high-precision timestamp interpolation: `current_time = elapsed + (playback_rate * (now - timestamp))`.
- **Hardware-Accelerated Window Movement**: Native AppKit `performDrag(with:)` integration ensures 120Hz ProMotion window dragging with zero input lag.
- **Click-Through Mode**: Toggle mouse event pass-through (`ignoresMouseEvents`) to interact with background applications without moving or hiding the overlay.
- **Local LRCLIB Cache**: Fetches synced lyrics via LRCLIB REST endpoints and caches parsed timelines to `~/Library/Caches/Lyrix/` to eliminate redundant network requests.
- **Zero-Configuration Standalone Bundle**: All helper frameworks and runtime dependencies are bundled directly inside the application bundle.

---

## System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M-series) or Intel processor
- Active internet connection for initial lyric lookups (subsequent plays use disk cache)

---

## Installation

### Pre-Built Disk Image (.dmg)

1. Download the latest `Lyrix-Installer.dmg` from the [Releases](https://github.com/narix/lyrix/releases) page.
2. Open the downloaded `.dmg` file.
3. Drag **Lyrix.app** into your **Applications** folder.
4. Launch **Lyrix** from Applications or Spotlight.

### Building from Source

Ensure you have Xcode Command Line Tools installed (`xcode-select --install`).

```bash
# Clone the repository
git clone https://github.com/narix/lyrix.git
cd lyrix

# Build the release binary
swift build -c release

# Build the standalone application bundle and DMG installer
./scripts/build_dmg.sh
```

The resulting bundle and disk image will be available in the `dist/` directory:
- `dist/Lyrix.app`
- `dist/Lyrix-Installer.dmg`

---

## Architecture

```
                                +---------------------------+
                                |  Desktop Media Sources    |
                                |  (Zen, Chrome, Spotify)   |
                                +-------------+-------------+
                                              |
                                              v
                                  macOS mediaremoted daemon
                                              |
                                              v
+-----------------------+           +-----------------------+
|   LRCLIB REST API     |           | NowPlayingService     |
|   (https://lrclib.net)|           | (Subprocess stream)   |
+-----------+-----------+           +-----------+-----------+
            |                                   |
            v                                   v
+-----------------------+           +-----------------------+
| LRCParser & Cache     |---------->| LyricsOverlayView     |
| (~/Library/Caches/...) |           | (SwiftUI / AppKit)    |
+-----------------------+           +-----------+-----------+
                                                |
                                                v
                                    +-----------------------+
                                    | OverlayWindowController|
                                    | (Floating NSWindow)   |
                                    +-----------------------+
```

### Core Components

1. **`NowPlayingService`**: Manages the child process stream monitoring macOS media state. Emits reactive updates containing title, artist, album, duration, elapsed position, and playback state.
2. **`LRCLIBService`**: REST client querying synced lyrics with query sanitization (stripping remaster tags, feature tags, and extraneous punctuation).
3. **`LRCParser`**: Regex engine converting standard timestamped LRC strings (`[mm:ss.xx] line`) into indexed `[LyricLine]` models with millisecond accuracy.
4. **`LyricsOverlayView`**: SwiftUI hierarchy rendering the active line, preceding line, and upcoming line with spring-interpolated vertical offset animations.
5. **`GlobalShortcutManager`**: Intercepts configurable global hotkeys via `NSEvent.addGlobalMonitorForEvents` and local monitors.
6. **`OverlayWindowController`**: Controls the borderless `NSWindow` instance, floating window level (`.floating`), multi-space collection behaviors, and frame persistence in `UserDefaults`.

---

## Keyboard Shortcuts

Default shortcuts can be customized via the Settings window (accessible from the Menu Bar extra or Preferences):

| Action | Default Shortcut | Description |
|:---|:---|:---|
| **Toggle Visibility** | `Ctrl + Option + L` | Shows or hides the floating lyrics window |
| **Toggle Click-Through** | `Ctrl + Option + K` | Toggles mouse interaction on and off |

---

## Configuration & Customization

The Settings window provides controls for:
- **Active Lyric Glow Color**: Cyan, Purple, Gold, Green, Pink, White
- **Font Size**: Small (18pt), Medium (21pt), Large (25pt)
- **Background Opacity**: Adjustable glassmorphism frost level (0.0 to 1.0)
- **Shortcut Recorder**: Interactive key-combination capturer for custom hotkey bindings

---

## Resource Utilization

| Metric | Typical Measurement | Implementation Detail |
|:---|:---|:---|
| **CPU Usage** | 0.0% – 0.2% | Passive event model; 100ms math timer only during active playback |
| **Memory (RSS)** | ~80 MB | Native AppKit / SwiftUI framebuffer and local memory cache |
| **Network** | ~5 KB per new track | Single HTTP GET on track change; 0 KB on subsequent plays |
| **Disk Footprint** | ~5.5 MB | Standalone application bundle |

---

## Project Structure

```
lyrix/
├── Package.swift               # Swift Package Manager definition
├── Sources/
│   └── Lyrix/
│       ├── LyrixApp.swift      # Application entry point & MenuBarExtra
│       ├── AppDelegate.swift   # Lifecycle and service orchestration
│       ├── Models/             # LyricLine, NowPlayingInfo, UserSettings, ShortcutKey
│       ├── Services/           # NowPlayingService, LRCLIBService, LRCParser, Cache
│       ├── Views/              # LyricsOverlayView, SettingsView
│       └── Windows/            # OverlayWindowController, SettingsWindowController
├── scripts/
│   ├── build_dmg.sh            # End-to-end DMG packaging script
│   ├── prepare_assets.py       # Multi-resolution icon & background generator
│   └── dmgbuild_settings.py    # Native .DS_Store layout specification
└── docs/                       # Static website for GitHub Pages
```

---

## License

This project is open source and available under the [MIT License](LICENSE).

Developed by [Kiran S Baliga](https://baliga.dev).
