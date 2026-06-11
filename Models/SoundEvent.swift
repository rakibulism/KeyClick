import Foundation

/// Identifies which sound to play. Each case maps 1:1 to a `.caf` file name
/// inside a profile folder (e.g. `space` → `space.caf`).
enum SoundEvent: String, CaseIterable {
    case base
    // One sound per letter key — switch position on the PCB, keycap size,
    // and travel feel make every key on a real board sound slightly
    // different. Synthesis params live in Scripts/generate_sounds.py.
    case letterA = "letter-a", letterB = "letter-b", letterC = "letter-c"
    case letterD = "letter-d", letterE = "letter-e", letterF = "letter-f"
    case letterG = "letter-g", letterH = "letter-h", letterI = "letter-i"
    case letterJ = "letter-j", letterK = "letter-k", letterL = "letter-l"
    case letterM = "letter-m", letterN = "letter-n", letterO = "letter-o"
    case letterP = "letter-p", letterQ = "letter-q", letterR = "letter-r"
    case letterS = "letter-s", letterT = "letter-t", letterU = "letter-u"
    case letterV = "letter-v", letterW = "letter-w", letterX = "letter-x"
    case letterY = "letter-y", letterZ = "letter-z"
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
