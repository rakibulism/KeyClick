import SwiftUI
import AppKit

/// The dropdown shown from the menu bar item.
struct MenuBarView: View {
    @ObservedObject var controller: MenuBarController
    @ObservedObject var settings: SettingsStore

    init(controller: MenuBarController) {
        self.controller = controller
        self.settings = controller.settings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if !controller.hasPermission {
                permissionBanner
                Divider()
            }

            Toggle("Enabled", isOn: $settings.isEnabled)
                .toggleStyle(.switch)

            Divider()

            Text("Sound Profile")
                .font(.caption).foregroundStyle(.secondary)
            Picker("Sound Profile", selection: $settings.activeProfile) {
                ForEach(Profile.allCases) { profile in
                    Text(profile.displayName).tag(profile)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Divider()

            HStack {
                Text("Volume").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(settings.volume * 100))%")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill").font(.caption2).foregroundStyle(.secondary)
                Slider(value: $settings.volume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill").font(.caption2).foregroundStyle(.secondary)
            }

            Divider()

            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .toggleStyle(.switch)

            Divider()

            Button("About KeyClick", action: showAbout)
                .buttonStyle(.plain)
            Button("Quit KeyClick") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 250)
    }

    private var header: some View {
        Label("KeyClick", systemImage: "keyboard")
            .font(.headline)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Accessibility access needed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption.bold())
            Text("KeyClick needs permission to hear your keystrokes. Nothing is ever recorded or stored.")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Settings…") { controller.reRequestPermission() }
                .font(.caption)
        }
        .padding(8)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "KeyClick",
            .applicationVersion: "1.0",
            .credits: NSAttributedString(
                string: "Mechanical keyboard sounds for every keystroke.\n\nKeyClick listens to your key presses to play sounds. Nothing is recorded, stored, or sent anywhere. Ever.",
                attributes: [.font: NSFont.systemFont(ofSize: 11)])
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}
