# KeyClick

A lightweight macOS menu bar app that plays mechanical keyboard sounds on every
keystroke. Every key press triggers a realistic sound; combo keys (⌘+Shift,
⌥+⌘, Caps Lock, etc.) trigger distinct layered or unique sounds. The app runs
silently in the background with zero performance impact and **never records,
stores, or transmits any key data — audio playback only.**

This repository contains the complete Swift source and a full set of
synthesized `.caf` sound assets. It is ready to be assembled into an Xcode
project (see setup below).

---

## Project layout

```
KeyClick/
├── App/
│   ├── KeyClickApp.swift        # @main entry, MenuBarExtra scene, AppDelegate
│   ├── MenuBarController.swift  # Coordinator: settings ↔ engine ↔ listener ↔ permissions
│   ├── PermissionManager.swift  # Accessibility (AX) permission flow
│   ├── SettingsStore.swift      # UserDefaults-backed settings
│   ├── Info.plist               # LSUIElement (menu-bar agent), bundle metadata
│   └── KeyClick.entitlements    # App Sandbox disabled (required for event tap)
├── Audio/
│   ├── AudioEngine.swift        # AVAudioEngine player-node pool, low-latency playback
│   ├── SoundProfile.swift       # Pre-decodes a profile's buffers into memory
│   └── KeySoundMapper.swift     # keyCode + modifiers → SoundEvent(s)
├── KeyListener/
│   └── GlobalKeyListener.swift  # CGEventTap (listen-only) for system-wide keys
├── Models/
│   ├── Profile.swift            # The 3 built-in switch profiles
│   ├── SoundEvent.swift         # Sound identifiers ↔ .caf file names
│   └── KeyCombo.swift           # ModifierSet + special key codes
├── UI/
│   └── MenuBarView.swift        # SwiftUI dropdown
├── Resources/
│   └── Sounds/                  # 123 .caf files (3 profiles × 41 sounds)
│       ├── clicky-blue/
│       ├── tactile-brown/
│       └── thocky-linear/
└── Scripts/
    └── generate_sounds.py       # Regenerates all sound assets
```

---

## Setting up the Xcode project

The source is organized but does not include an `.xcodeproj`. To build:

1. **Create the target.** Xcode → *New Project* → **App**, macOS. Product name
   `KeyClick`, Interface **SwiftUI**, Language **Swift**. Delete the auto-created
   `ContentView.swift` and the default `@main` struct.
2. **Add the source.** Drag the `App`, `Audio`, `KeyListener`, `Models`, and
   `UI` folders into the project ("Create groups", add to the KeyClick target).
3. **Add the sounds as a folder reference.** Drag `Resources/Sounds` in and
   choose **"Create folder references"** (blue folder, *not* yellow group). This
   preserves the per-profile subdirectories that `SoundProfile.url(for:)`
   expects (`Sounds/<profile>/<event>.caf`).
4. **Info.plist.** Use the provided `App/Info.plist`, or set in Build Settings:
   `Application is agent (UIElement) = YES` (`LSUIElement`), and
   `Minimum Deployments = macOS 13.0`.
5. **Entitlements.** Add `App/KeyClick.entitlements` and point
   *Code Signing Entitlements* at it. App Sandbox **must be off** — a global
   `CGEventTap` cannot run in the sandbox.
6. **Signing.** Use a Developer ID certificate and enable the **Hardened
   Runtime** (required for notarization).
7. **Architectures.** Set *Build Active Architecture Only = No* for Release to
   produce a Universal (Apple Silicon + Intel) binary.

Build and run. KeyClick appears as a ⌨ icon in the menu bar.

---

## Permissions

On first launch the app requests **Accessibility** access (the only permission
needed) via `AXIsProcessTrustedWithOptions` and opens
*System Settings → Privacy & Security → Accessibility*. Enable KeyClick there.
The app polls and starts listening automatically once granted; if access is
revoked later, a banner in the menu lets you re-grant it.

> During development, every fresh build can be treated as a new binary by macOS,
> so you may need to remove and re-add KeyClick in the Accessibility list after
> rebuilding.

---

## Sound assets

The 123 bundled `.caf` files are **procedurally synthesized placeholders**
(mono, 16-bit, 44.1 kHz) so the app makes sound out of the box. Each profile
has 41 sounds: `base`, one `letter-a` … `letter-z` per letter key, `space`,
`enter`, `backspace`, `tab`, `escape`, `arrow`, `function`, `capslock-on`,
`capslock-off`, `modifier-cmd`, `modifier-opt`, `modifier-ctrl`,
`modifier-shift`, `combo-chord`.

### Per-key acoustic variation

On a real board every key sounds slightly different — switch position on the
PCB, keycap size, and travel feel all shift the acoustics. Every letter A–Z
has its **own sound file**, synthesized as its row's acoustic group character
plus a per-key tweak and a unique noise grain (see `LETTERS` in
`Scripts/generate_sounds.py` for all 26 parameter sets):

| Group / row              | Keys                | Character                       |
|--------------------------|---------------------|---------------------------------|
| Deep / thocky (home row) | A S D F G H J K L   | larger caps, deeper, longer     |
| Sharp / clicky (top row) | Q W E R T Y U I O P | smaller caps, faster actuation  |
| Light / airy (bottom)    | Z X C V B N M       | lightest taps                   |

Standout keys within the groups: `F`/`J` are muted by their homing nubs,
corner/edge keys `Q` `Z` `P` `L` ring slightly hollow, `G`/`H` are tight and
punchy at board center, `B`/`N` get a punchier bottom-row thock, and `I` is
the sharpest small-cap click.

Non-letter keys without a dedicated sound (digits, punctuation) fall back to
`base.caf`.

Swap in real recordings by overwriting files of the same name. To regenerate or
tweak the placeholders:

```bash
python3 Scripts/generate_sounds.py
```

(Pure Python, no dependencies. Edit `PROFILES` / `VARIATIONS` in the script to
adjust character.)

---

## How combos map to sounds

Combos are detected from the modifier flags active at each `keyDown` — no
keylogging or stateful tracking. See `KeySoundMapper`:

- **Plain key** → its base or special sound (Space, Enter, Backspace, Tab,
  Escape, arrows, F-keys each distinct).
- **One modifier held** → modifier click layered under the key sound
  (e.g. ⌘ + key = command click + base).
- **Two or more modifiers** (incl. the ⌘⌥⌃⇧ Hyper chord) → the distinctive
  layered `combo-chord`.
- **Caps Lock** → separate on/off toggle sounds.
- OS key-repeat events are ignored — sound fires once per physical press.

---

## Spec compliance notes

- Latency: buffers are pre-decoded and scheduled on a pool of always-running
  `AVAudioPlayerNode`s with `.interrupts`, targeting the <15 ms goal. Measure on
  device and adjust `poolSize` if needed.
- Burst typing: new hits interrupt the oldest node rather than queueing.
- Volume is independent of system volume (engine mixer `outputVolume`).
- Launch at Login uses `SMAppService` (macOS 13+).
- Privacy: listen-only event tap, nothing written to disk or network.

Distribution is direct download (`.dmg`); the Mac App Store is not viable
because the global event tap requires running outside the App Sandbox.
