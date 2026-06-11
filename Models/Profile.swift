import Foundation

/// A built-in mechanical switch sound profile. Each case maps to a folder
/// under `Resources/Sounds/` containing that profile's complete sound set.
enum Profile: String, CaseIterable, Identifiable {
    case clickyBlue   = "clicky-blue"
    case tactileBrown = "tactile-brown"
    case thockyLinear = "thocky-linear"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clickyBlue:   return "Clicky Blue"
        case .tactileBrown: return "Tactile Brown"
        case .thockyLinear: return "Thocky Linear"
        }
    }

    var subtitle: String {
        switch self {
        case .clickyBlue:   return "Sharp, high-pitched click — Cherry MX Blue"
        case .tactileBrown: return "Softer bump, medium pitch — Cherry MX Brown"
        case .thockyLinear: return "Deep, low thud — Holy Pandas / Boba U4T"
        }
    }

    /// Folder name under `Resources/Sounds`.
    var folder: String { rawValue }

    static var `default`: Profile { .tactileBrown }
}
