import Foundation

/// Translates raw key events into the sound event(s) that should play.
///
/// Combos are detected purely from the modifier flags active at the time of a
/// `keyDown`, exactly as the spec describes — no stateful key tracking needed.
struct KeySoundMapper {

    /// Sound(s) for a `keyDown` of `keyCode` while `modifiers` are held.
    /// May return multiple events to be layered for a richer combo feel.
    func events(forKeyDown keyCode: Int64, modifiers: ModifierSet) -> [SoundEvent] {
        let key = baseEvent(for: keyCode)
        let mods = modifiers.soundShaping

        // Hyper chord or any 2+ modifier combo → distinctive layered chord.
        if mods.isHyper || mods.count >= 2 {
            return [.comboChord]
        }

        // A single modifier held → layer its click under the key sound,
        // e.g. ⌘ + any key = command click + base key sound.
        if mods.count == 1, let mod = modifierEvent(for: mods) {
            return [mod, key]
        }

        return [key]
    }

    /// Sound for a `flagsChanged` event.
    /// - Parameters:
    ///   - added: modifiers newly pressed since the previous event.
    ///   - capsLockToggled: whether Caps Lock just changed state.
    ///   - capsLockOn: the new Caps Lock state.
    func event(forModifierChange added: ModifierSet,
               capsLockToggled: Bool,
               capsLockOn: Bool) -> SoundEvent? {
        if capsLockToggled {
            return capsLockOn ? .capsLockOn : .capsLockOff
        }
        // Fire only on the *press* of a modifier (ignore releases → `added` empty).
        return modifierEvent(for: added.soundShaping)
    }

    // MARK: - Helpers

    private func baseEvent(for keyCode: Int64) -> SoundEvent {
        switch keyCode {
        case KeyCode.space:                       return .space
        case KeyCode.returnKey:                   return .enter
        case KeyCode.delete, KeyCode.forwardDelete: return .backspace
        case KeyCode.tab:                         return .tab
        case KeyCode.escape:                      return .escape
        default:
            if KeyCode.arrows.contains(keyCode)       { return .arrow }
            if KeyCode.functionKeys.contains(keyCode) { return .function }
            if let letter = KeyCode.letters[keyCode]  { return letter }
            return .base
        }
    }

    /// Pick a single modifier sound, in priority order, from a modifier set.
    private func modifierEvent(for mods: ModifierSet) -> SoundEvent? {
        if mods.contains(.command) { return .modifierCommand }
        if mods.contains(.control) { return .modifierControl }
        if mods.contains(.option)  { return .modifierOption }
        if mods.contains(.shift)   { return .modifierShift }
        return nil
    }
}
