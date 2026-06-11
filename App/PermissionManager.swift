import Foundation
import ApplicationServices
import AppKit

/// Manages the Accessibility (AX) permission required to listen to global key
/// events. The app stores or transmits nothing — this permission is used
/// solely to receive key-press notifications for audio playback.
final class PermissionManager {

    /// Whether the process is currently trusted for Accessibility.
    var isTrusted: Bool { AXIsProcessTrusted() }

    /// Triggers the system permission prompt and returns the current state.
    @discardableResult
    func requestAccess() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings → Privacy & Security → Accessibility.
    func openSystemSettings() {
        guard let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        else { return }
        NSWorkspace.shared.open(url)
    }

    /// Polls trust state and invokes `onGranted` once permission is granted.
    func pollUntilTrusted(interval: TimeInterval = 1.0, _ onGranted: @escaping () -> Void) {
        if isTrusted { onGranted(); return }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if self.isTrusted {
                timer.invalidate()
                onGranted()
            }
        }
    }
}
