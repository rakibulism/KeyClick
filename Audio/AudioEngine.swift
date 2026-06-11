import Foundation
import AVFoundation

/// Low-latency playback engine.
///
/// Pre-decoded buffers are scheduled on a pool of always-running player nodes
/// using `.interrupts`, so rapid keystrokes overlap cleanly and old sounds are
/// dropped rather than queued (per the spec's burst-input requirement).
final class AudioEngine {

    private let engine = AVAudioEngine()
    private let mixer  = AVAudioMixerNode()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let poolSize = 12

    private var current: SoundProfile?
    private let queue = DispatchQueue(label: "com.keyclick.audio", qos: .userInteractive)

    /// Independent of system volume. 0.0–1.0.
    var volume: Float = 0.7 {
        didSet { mixer.outputVolume = max(0, min(1, volume)) }
    }

    /// One-click mute. When false, `play` is a no-op.
    var isEnabled = true

    init() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        for _ in 0..<poolSize {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: nil)
            players.append(node)
        }
        mixer.outputVolume = volume
    }

    func start() {
        guard !engine.isRunning else { return }
        do {
            engine.prepare()
            try engine.start()
            players.forEach { $0.play() }
        } catch {
            NSLog("KeyClick: audio engine failed to start: \(error)")
        }
    }

    func stop() {
        players.forEach { $0.stop() }
        engine.stop()
    }

    /// Swap the active profile. Decoding happens off the main thread.
    func load(profile: Profile) {
        queue.async { [weak self] in
            self?.current = SoundProfile(profile: profile)
        }
    }

    /// Play one or more layered sound events with minimal latency.
    func play(_ events: [SoundEvent]) {
        guard isEnabled, !events.isEmpty else { return }
        queue.async { [weak self] in
            guard let self, let profile = self.current else { return }
            self.start()
            for event in events {
                guard let buffer = profile.buffers[event] else { continue }
                let player = self.players[self.nextPlayer]
                self.nextPlayer = (self.nextPlayer + 1) % self.players.count
                player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
                if !player.isPlaying { player.play() }
            }
        }
    }
}
