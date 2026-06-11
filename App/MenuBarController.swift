import Foundation
import Combine
import ServiceManagement

/// Central coordinator. Wires together settings, the audio engine, the global
/// key listener, and the Accessibility permission flow.
final class MenuBarController: ObservableObject {

    let settings: SettingsStore

    /// Reflected in the menu bar UI so we can show a permission banner.
    @Published var hasPermission = false

    private let engine = AudioEngine()
    private let listener = GlobalKeyListener()
    private let mapper = KeySoundMapper()
    private let permissions = PermissionManager()
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsStore) {
        self.settings = settings

        engine.isEnabled = settings.isEnabled
        engine.volume = settings.volume
        engine.load(profile: settings.activeProfile)

        configureListener()
        bindSettings()
        checkPermissionAndStart()
    }

    // MARK: - Wiring

    private func configureListener() {
        listener.onKeyDown = { [weak self] keyCode, mods in
            guard let self else { return }
            self.engine.play(self.mapper.events(forKeyDown: keyCode, modifiers: mods))
        }
        listener.onModifierChange = { [weak self] added, capsToggled, capsOn in
            guard let self else { return }
            if let event = self.mapper.event(forModifierChange: added,
                                             capsLockToggled: capsToggled,
                                             capsLockOn: capsOn) {
                self.engine.play([event])
            }
        }
        listener.onTapDisabled = {
            NSLog("KeyClick: event tap was disabled and re-enabled automatically.")
        }
    }

    private func bindSettings() {
        settings.$isEnabled
            .sink { [weak self] in self?.engine.isEnabled = $0 }
            .store(in: &cancellables)
        settings.$volume
            .sink { [weak self] in self?.engine.volume = $0 }
            .store(in: &cancellables)
        settings.$activeProfile
            .sink { [weak self] in self?.engine.load(profile: $0) }
            .store(in: &cancellables)
        settings.$launchAtLogin
            .sink { [weak self] in self?.applyLaunchAtLogin($0) }
            .store(in: &cancellables)
    }

    // MARK: - Permission flow

    func checkPermissionAndStart() {
        hasPermission = permissions.isTrusted
        if hasPermission {
            startListening()
        } else {
            permissions.requestAccess()
            permissions.openSystemSettings()
            permissions.pollUntilTrusted { [weak self] in
                self?.hasPermission = true
                self?.startListening()
            }
        }
    }

    /// Re-trigger the permission flow from the menu bar banner.
    func reRequestPermission() {
        permissions.openSystemSettings()
        permissions.pollUntilTrusted { [weak self] in
            self?.hasPermission = true
            self?.startListening()
        }
    }

    private func startListening() {
        engine.start()
        if !listener.start() {
            NSLog("KeyClick: failed to start event tap — check Accessibility permission.")
            hasPermission = false
        }
    }

    // MARK: - Launch at login

    private func applyLaunchAtLogin(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("KeyClick: launch-at-login update failed: \(error)")
        }
    }
}
