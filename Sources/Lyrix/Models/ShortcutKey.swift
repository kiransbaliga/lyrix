import AppKit
import Foundation

/// A representation of a keyboard shortcut (modifiers + key code).
struct ShortcutKey: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlags: UInt

    init(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        // Keep only standard modifier bits
        let sanitized = modifierFlags.intersection([.command, .option, .control, .shift])
        self.modifierFlags = sanitized.rawValue
    }

    var flags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    /// Human-readable representation, e.g. "⌃⌥L" or "⌥Space"
    var displayString: String {
        var result = ""
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        result += Self.keyName(for: keyCode)
        return result
    }

    /// Converts a macOS virtual key code to a friendly character string.
    static func keyName(for code: UInt16) -> String {
        switch code {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        case 49: return "Space"
        case 36: return "↩"
        case 48: return "⇥"
        case 51: return "⌫"
        case 53: return "⎋"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key \(code)"
        }
    }

    // Default shortcuts
    static let defaultToggleOverlay = ShortcutKey(keyCode: 37, modifierFlags: [.control, .option]) // ⌃⌥L
    static let defaultToggleClickThrough = ShortcutKey(keyCode: 40, modifierFlags: [.control, .option]) // ⌃⌥K
}
