import Foundation

/// Identifies which sound to play. Each case maps 1:1 to a `.caf` file name
/// inside a profile folder (e.g. `space` → `space.caf`).
enum SoundEvent: String, CaseIterable {
    case base
    // Letter keys, grouped by acoustic character — switch position on the
    // PCB, keycap size, and travel feel make each region sound different.
    case baseThock  = "base-thock"   // home row: larger caps, deeper, longer
    case baseClick  = "base-click"   // top row: smaller caps, faster actuation
    case baseLight  = "base-light"   // bottom row: lightest, airy
    case baseEdge   = "base-edge"    // corner/edge keys: hollow resonance
    case baseHoming = "base-homing"  // F/J homing nubs: slightly muted
    case space
    case enter
    case backspace
    case tab
    case escape
    case arrow
    case function
    case capsLockOn      = "capslock-on"
    case capsLockOff     = "capslock-off"
    case modifierCommand = "modifier-cmd"
    case modifierOption  = "modifier-opt"
    case modifierControl = "modifier-ctrl"
    case modifierShift   = "modifier-shift"
    case comboChord      = "combo-chord"

    /// File name (without extension) for this event.
    var fileName: String { rawValue }
}
