import Foundation
import CoreGraphics
import AppKit

/// System-wide key event listener built on `CGEventTap`.
///
/// Operates in **listen-only** mode — it never consumes or modifies events, and
/// performs **no logging or storage** of key data. It emits high-level
/// callbacks describing *what kind* of key was pressed, never the actual text.
final class GlobalKeyListener {

    /// Called on a fresh physical key press (auto-repeat is filtered out).
    var onKeyDown: ((_ keyCode: Int64, _ modifiers: ModifierSet) -> Void)?

    /// Called when modifier flags change (including Caps Lock).
    var onModifierChange: ((_ added: ModifierSet, _ capsToggled: Bool, _ capsOn: Bool) -> Void)?

    /// Called if the OS disables the tap (timeout / heavy input).
    var onTapDisabled: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var previousFlags = CGEventFlags(rawValue: 0)
    private(set) var isRunning = false

    /// Returns false if the tap could not be created (usually missing
    /// Accessibility permission).
    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }

        let mask = (1 << CGEventType.keyDown.rawValue) |
                   (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let listener = Unmanaged<GlobalKeyListener>.fromOpaque(refcon).takeUnretainedValue()
            listener.handle(type: type, event: event)
            return Unmanaged.passUnretained(event) // passive — never consume
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        return true
    }

    func stop() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
    }

    // MARK: - Event handling

    private func handle(type: CGEventType, event: CGEvent) {
        switch type {
        case .keyDown:
            // Ignore OS key-repeat — sound fires only on the initial press.
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return }
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            onKeyDown?(keyCode, ModifierSet(flags: event.flags))

        case .flagsChanged:
            let new = event.flags
            let old = previousFlags
            previousFlags = new

            let capsToggled = new.contains(.maskAlphaShift) != old.contains(.maskAlphaShift)
            let capsOn = new.contains(.maskAlphaShift)

            // Modifiers newly pressed since the last event (releases → empty).
            let added = ModifierSet(flags: new).subtracting(ModifierSet(flags: old))
            onModifierChange?(added, capsToggled, capsOn)

        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            onTapDisabled?()

        default:
            break
        }
    }
}
