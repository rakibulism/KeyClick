import Foundation
import Combine

/// User-facing settings, persisted via `UserDefaults`.
/// Defaults match the spec: enabled, Tactile Brown, 70% volume, no autostart.
final class SettingsStore: ObservableObject {

    private enum Keys {
        static let isEnabled      = "isEnabled"
        static let activeProfile  = "activeProfile"
        static let volume         = "volume"
        static let launchAtLogin  = "launchAtLogin"
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }
    @Published var activeProfile: Profile {
        didSet { defaults.set(activeProfile.rawValue, forKey: Keys.activeProfile) }
    }
    @Published var volume: Float {
        didSet { defaults.set(volume, forKey: Keys.volume) }
    }
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    private let defaults = UserDefaults.standard

    init() {
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.volume: 0.7,
            Keys.launchAtLogin: false,
            Keys.activeProfile: Profile.default.rawValue,
        ])
        isEnabled     = defaults.bool(forKey: Keys.isEnabled)
        volume        = defaults.float(forKey: Keys.volume)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        activeProfile = Profile(rawValue: defaults.string(forKey: Keys.activeProfile) ?? "")
            ?? .default
    }
}
