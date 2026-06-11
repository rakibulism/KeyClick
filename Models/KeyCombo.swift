import Foundation
import CoreGraphics

/// The set of modifier keys active at the moment of a key event.
struct ModifierSet: OptionSet {
    let rawValue: Int

    static let command = ModifierSet(rawValue: 1 << 0)
    static let shift   = ModifierSet(rawValue: 1 << 1)
    static let option  = ModifierSet(rawValue: 1 << 2)
    static let control = ModifierSet(rawValue: 1 << 3)
    static let fn      = ModifierSet(rawValue: 1 << 4)

    init(rawValue: Int) { self.rawValue = rawValue }

    /// Build a modifier set from raw Core Graphics event flags.
    init(flags: CGEventFlags) {
        var set = ModifierSet()
        if flags.contains(.maskCommand)     { set.insert(.command) }
        if flags.contains(.maskShift)       { set.insert(.shift) }
        if flags.contains(.maskAlternate)   { set.insert(.option) }
        if flags.contains(.maskControl)     { set.insert(.control) }
        if flags.contains(.maskSecondaryFn) { set.insert(.fn) }
        self = set
    }

    /// Modifiers that meaningfully shape the sound. Fn is near-silent per the
    /// spec, so it is excluded from combo counting.
    var soundShaping: ModifierSet { subtracting(.fn) }

    /// True when ⌘ + ⌥ + ⌃ + ⇧ are all held (the "Hyper" chord).
    var isHyper: Bool {
        soundShaping.isSuperset(of: [.command, .option, .control, .shift])
    }

    /// Number of sound-shaping modifiers active.
    var count: Int { soundShaping.rawValue.nonzeroBitCount }
}

/// macOS virtual key codes (CGKeyCode) for keys that get a distinct sound.
enum KeyCode {
    static let returnKey: Int64 = 36
    static let tab: Int64       = 48
    static let space: Int64     = 49
    static let delete: Int64    = 51   // Backspace
    static let forwardDelete: Int64 = 117
    static let escape: Int64    = 53
    static let capsLock: Int64  = 57

    /// ← → ↓ ↑
    static let arrows: Set<Int64> = [123, 124, 125, 126]

    /// F1–F12
    static let functionKeys: Set<Int64> = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111]

    // MARK: Letter keys by acoustic group (ANSI virtual key codes).
    // F/J homing nubs and corner/edge keys override their row's group.

    /// F J — homing-bump keys, slightly muted.
    static let homingKeys: Set<Int64> = [3, 38]

    /// Q Z P L — corner/edge keys with a hollow resonance.
    static let edgeKeys: Set<Int64> = [12, 6, 35, 37]

    /// A S D G H K — home row (minus homing/edge), deep and thocky.
    static let thockKeys: Set<Int64> = [0, 1, 2, 5, 4, 40]

    /// W E R T Y U I O — top row (minus edge), sharp and clicky.
    static let clickKeys: Set<Int64> = [13, 14, 15, 17, 16, 32, 34, 31]

    /// X C V B N M — bottom row (minus edge), light and airy.
    static let lightKeys: Set<Int64> = [7, 8, 9, 11, 45, 46]
}
