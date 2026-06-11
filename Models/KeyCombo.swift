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

    /// A–Z (ANSI virtual key codes) → that key's dedicated sound.
    static let letters: [Int64: SoundEvent] = [
        0: .letterA, 11: .letterB, 8: .letterC, 2: .letterD, 14: .letterE,
        3: .letterF, 5: .letterG, 4: .letterH, 34: .letterI, 38: .letterJ,
        40: .letterK, 37: .letterL, 46: .letterM, 45: .letterN, 31: .letterO,
        35: .letterP, 12: .letterQ, 15: .letterR, 1: .letterS, 17: .letterT,
        32: .letterU, 9: .letterV, 13: .letterW, 7: .letterX, 16: .letterY,
        6: .letterZ,
    ]
}
