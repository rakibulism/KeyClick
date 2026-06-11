import Foundation
import AVFoundation

/// Loads and holds the decoded PCM buffers for a single `Profile`.
/// Buffers are pre-decoded into memory so playback adds no decode latency.
final class SoundProfile {

    let profile: Profile
    private(set) var buffers: [SoundEvent: AVAudioPCMBuffer] = [:]
    private(set) var format: AVAudioFormat?

    init(profile: Profile) {
        self.profile = profile
        load()
    }

    private func load() {
        for event in SoundEvent.allCases {
            guard let url = Self.url(for: event, profile: profile) else {
                NSLog("KeyClick: missing asset \(event.fileName).caf for \(profile.folder)")
                continue
            }
            do {
                let file = try AVAudioFile(forReading: url)
                let fmt = file.processingFormat
                let frames = AVAudioFrameCount(file.length)
                guard frames > 0,
                      let buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames)
                else { continue }
                try file.read(into: buffer)
                buffers[event] = buffer
                if format == nil { format = fmt }
            } catch {
                NSLog("KeyClick: failed to load \(url.lastPathComponent): \(error)")
            }
        }
    }

    /// Resolve a sound file inside the app bundle. The `Sounds` directory must
    /// be added to the target as a *folder reference* so the per-profile
    /// subdirectories are preserved at build time.
    static func url(for event: SoundEvent, profile: Profile) -> URL? {
        Bundle.main.url(forResource: event.fileName,
                        withExtension: "caf",
                        subdirectory: "Sounds/\(profile.folder)")
    }
}
