import SwiftUI
import AppKit

@main
struct KeyClickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("KeyClick", systemImage: "keyboard") {
            MenuBarView(controller: appDelegate.controller)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Owns the long-lived app objects and keeps the app running as a menu bar
/// agent (no dock icon — see `LSUIElement` in Info.plist).
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()
    lazy var controller = MenuBarController(settings: settings)

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = controller // instantiate and wire everything up at launch
    }
}
