# KeyClick — Product Specification
**Document Type:** Product Requirements Document (PRD)  
**Version:** 1.0  
**Platform:** macOS  
**Owner:** Rakibul Islam  
**Status:** Ready for Development

---

## Overview

KeyClick is a lightweight macOS menu bar app that plays mechanical keyboard sounds on every keystroke. It is built for designers, developers, and keyboard enthusiasts who want the tactile audio experience of a high-end mechanical keyboard — regardless of what physical keyboard they are using.

Every key press triggers a realistic sound. Combo keys (⌘+Shift, ⌥+⌘, Caps Lock, etc.) trigger distinct layered or unique sounds. The app runs silently in the background with zero performance impact.

---

## Problem

Software keyboards — built-in MacBook keyboards and most external membranes — produce no satisfying feedback. Mechanical keyboard enthusiasts who work in sound-restricted environments (offices, shared spaces) or use quiet keyboards lose the tactile audio pleasure entirely. There is no dedicated, high-quality macOS app that solves this with mechanical fidelity and per-key granularity.

---

## Goals

- Play realistic mechanical keyboard sounds on every key press
- Support distinct sounds for combo/modifier key combinations
- Let users choose from multiple switch sound profiles (Cherry MX, Topre, Clicky, Thocky, etc.)
- Run as a lightweight menu bar app — no dock icon, no setup friction
- Zero noticeable CPU/RAM overhead

---

## Non-Goals (v1.0)

- Windows or Linux support
- Custom sound upload (planned for v2)
- MIDI output
- Recording or looping functionality

---

## Target User

- Design engineers and developers who love mechanical keyboards
- People working in quiet environments (offices, cafes)
- Keyboard hobbyists and enthusiasts
- Remote workers who want a richer typing experience

---

## Platform Requirements

| Requirement | Detail |
|---|---|
| **OS** | macOS 13 Ventura and above |
| **Architecture** | Universal Binary (Apple Silicon + Intel) |
| **Distribution** | Direct download (.dmg) — Mac App Store optional in v2 |
| **Permissions** | Accessibility API (for global key event listening) |

---

## Core Features

### 1. Global Key Listening

The app must listen to all key events system-wide using the macOS Accessibility API (`CGEventTap` or equivalent). It must capture key events from any app — browser, code editor, Terminal, etc. — without requiring focus.

**Requirements:**
- Capture `keyDown` events for all standard keys
- Capture `flagsChanged` events for modifier keys (⌘, ⌥, ⌃, ⇧, Caps Lock, Fn)
- No key logging or storage — audio only, no data written to disk

---

### 2. Sound Playback Engine

**Requirements:**
- Sounds must play with < 15ms latency from key press
- Use AVFoundation or CoreAudio for low-latency audio
- Sounds must not overlap in a distracting way — short sounds should duck or finish before retriggering
- Volume controlled independently from system volume
- Mute toggle accessible from the menu bar in one click

---

### 3. Key Sound Mapping

#### 3a. Standard Key Sounds

All standard keys (A–Z, 0–9, symbols, punctuation) play the **base switch sound** for the active profile. The base sound is the same for all standard keys in v1 (no per-key variation required at launch).

#### 3b. Special Key Sounds

The following keys must each have a **distinct sound** — different from the base and from each other:

| Key | Sound Behavior |
|---|---|
| **Space** | Deeper, longer thock — spacebar has the longest travel |
| **Enter / Return** | Firm, decisive click — slightly louder |
| **Backspace / Delete** | Soft thud — distinct from Enter |
| **Tab** | Medium click, similar to standard but slightly deeper |
| **Escape** | Sharp single click |
| **Caps Lock** | Mechanical toggle sound — on/off states sound different |
| **Arrow Keys** | Shorter, lighter click |
| **Function Keys (F1–F12)** | Quieter, slightly hollow sound |

#### 3c. Combo / Modifier Key Sounds

When modifier keys are held and combined with other keys, the sound profile must reflect the combo. See full combo map below.

---

### 4. Combo Key Sound System

This is a key differentiator. Combos must feel distinct and satisfying — not just the same click repeated.

#### Modifier Key States

| Modifier | Behavior |
|---|---|
| **⌘ (Command)** | Single clean click on press |
| **⌥ (Option/Alt)** | Softer, shorter click |
| **⌃ (Control)** | Medium firm click |
| **⇧ (Shift)** | Light quick click |
| **Fn** | Near-silent click |

#### Combo Sound Rules

| Combo | Sound Behavior |
|---|---|
| **⌘ + any key** | Command click + base key sound, slight reverb tail |
| **⇧ + any key** | Shift down sound + base key — feels like two rapid clicks |
| **⌘ + ⇧ + any key** | Layered: Command + Shift + key — 3-note rapid sequence |
| **⌘ + ⌥ + any key** | Low + high layered tone |
| **⌃ + any key** | Heavier base + key click |
| **⌘ + ⌥ + ⌃ + ⇧ (Hyper Key)** | Full mechanical chord — distinct multi-layer sound |
| **Caps Lock toggle ON** | Heavy satisfying toggle click |
| **Caps Lock toggle OFF** | Lighter release click |
| **⌘ + Space (Spotlight)** | Signature sound — punchy double-click |
| **⌘ + Tab (App Switch)** | Smooth click sequence |
| **⌘ + Q / ⌘ + W** | Standard combo sound |
| **⌘ + Z (Undo)** | Standard combo sound |
| **⌘ + C / ⌘ + V** | Standard combo sound |

**Implementation note:** Combos are detected by tracking which modifier flags are active at the time of each `keyDown` event. The sound played is determined by the combination of active modifiers + the key pressed.

---

### 5. Sound Profiles

Users can select from a set of built-in mechanical switch profiles. Each profile is a complete set of sounds (base, special keys, modifiers).

**v1.0 Profiles (minimum 3 required):**

| Profile Name | Character | Real-World Equivalent |
|---|---|---|
| **Clicky Blue** | Sharp, high-pitched click | Cherry MX Blue |
| **Tactile Brown** | Softer bump, medium pitch | Cherry MX Brown / Gateron Brown |
| **Thocky Linear** | Deep, low thud — satisfying | Holy Pandas / Boba U4T |

**Future profiles (v2):** Topre, Buckling Spring, Low-Profile, Custom Upload.

---

### 6. Menu Bar UI

The app lives entirely in the menu bar. No dock icon. The menu bar item is a small keyboard icon (⌨).

**Menu Bar Dropdown:**

```
⌨ KeyClick
─────────────────
● Enabled          [Toggle]
─────────────────
Sound Profile
  ○ Clicky Blue
  ● Tactile Brown   (active)
  ○ Thocky Linear
─────────────────
Volume
  ────────────── [Slider: 0–100%]
─────────────────
Launch at Login    [Toggle]
─────────────────
About KeyClick
Quit KeyClick
```

**Requirements:**
- Active profile shown with a filled dot
- Volume slider updates in real time (user hears change as they drag)
- "Enabled" toggle is the primary on/off — one-click mute
- Launch at Login uses `SMLoginItemSetEnabled` or `LaunchAgent` plist

---

### 7. Permissions & Privacy

The app requires **Accessibility permission** to listen to global key events. This must be handled gracefully.

**Flow:**
1. On first launch, show a one-time permission prompt explaining why the permission is needed
2. Open System Settings → Privacy & Security → Accessibility automatically
3. If permission is denied, show a non-intrusive menu bar indicator and a re-prompt option
4. No key data is ever stored, logged, or transmitted — audio playback only

**Privacy Statement (shown in onboarding):**
> "KeyClick listens to your key presses to play sounds. Nothing is recorded, stored, or sent anywhere. Ever."

---

### 8. Performance Requirements

| Metric | Target |
|---|---|
| Sound latency | < 15ms from keydown |
| CPU usage (idle typing) | < 1% |
| Memory footprint | < 30MB |
| App launch time | < 1 second |
| Background battery impact | Negligible |

---

## Technical Stack (Recommended)

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI (menu bar) |
| Audio Engine | AVAudioEngine or CoreAudio |
| Key Event Capture | CGEventTap (via Accessibility API) |
| Sound Assets | Pre-recorded .wav or .caf files (16-bit, 44.1kHz) |
| Launch at Login | ServiceManagement framework |
| Build Target | macOS 13+ Universal Binary |

**Sound Asset Notes:**
- All sounds should be pre-recorded from real mechanical keyboards
- Format: .caf (Core Audio Format) preferred for lowest latency on macOS
- Each profile needs: 1 base sound + ~8 special key sounds + 3–4 modifier sounds = ~12–15 files per profile
- Total sound assets (3 profiles): ~40–45 files

---

## File & Folder Structure (Suggested)

```
KeyClick/
├── App/
│   ├── KeyClickApp.swift
│   ├── MenuBarController.swift
│   └── PermissionManager.swift
├── Audio/
│   ├── AudioEngine.swift
│   ├── SoundProfile.swift
│   └── KeySoundMapper.swift
├── KeyListener/
│   └── GlobalKeyListener.swift
├── Models/
│   ├── Profile.swift
│   └── KeyCombo.swift
├── Resources/
│   └── Sounds/
│       ├── clicky-blue/
│       │   ├── base.caf
│       │   ├── space.caf
│       │   ├── enter.caf
│       │   ├── backspace.caf
│       │   ├── capslock-on.caf
│       │   ├── capslock-off.caf
│       │   ├── modifier-cmd.caf
│       │   ├── modifier-shift.caf
│       │   ├── modifier-opt.caf
│       │   └── combo-chord.caf
│       ├── tactile-brown/
│       └── thocky-linear/
└── UI/
    └── MenuBarView.swift
```

---

## User Settings (Persisted via UserDefaults)

| Key | Type | Default |
|---|---|---|
| `isEnabled` | Bool | true |
| `activeProfile` | String | "tactile-brown" |
| `volume` | Float | 0.7 |
| `launchAtLogin` | Bool | false |

---

## Edge Cases to Handle

| Scenario | Expected Behavior |
|---|---|
| App loses Accessibility permission | Show warning in menu bar, no crash |
| System audio is muted | KeyClick volume operates independently — still plays |
| Very fast typing (burst input) | Sounds play without queue buildup — drop old sounds if needed |
| Key held down (key repeat) | Play sound only on initial `keyDown`, not on repeat events |
| External keyboard connected/disconnected | No change in behavior — event tap is system-level |
| Machine goes to sleep | App resumes correctly on wake |
| Multiple displays / spaces | Works globally regardless of active space |

---

## Out of Scope for v1.0

- Per-key custom sound assignment
- Sound recording / import
- Equalizer or audio effects (reverb, delay)
- iOS / iPadOS companion app
- Cloud sync of settings
- Mac App Store distribution (due to Accessibility API sandbox restrictions)

---

## Delivery Checklist

- [ ] Global key listener working across all apps
- [ ] Base sound playing on all standard keys < 15ms
- [ ] Special key sounds (Space, Enter, Backspace, Caps Lock, etc.)
- [ ] Modifier key sounds (⌘, ⌥, ⌃, ⇧)
- [ ] Combo detection + layered sounds
- [ ] 3 sound profiles implemented and selectable
- [ ] Menu bar UI — toggle, profile select, volume slider, launch at login
- [ ] Accessibility permission flow — onboarding + graceful denial handling
- [ ] Universal Binary build (Apple Silicon + Intel)
- [ ] Performance targets met (< 1% CPU, < 30MB RAM, < 15ms latency)
- [ ] No key data stored or transmitted — verified

---

## Open Questions for Developer

1. **Sound assets** — Will you source/record the .caf files, or should we provide them?
2. **CoreAudio vs AVAudioEngine** — Preferred approach for < 15ms latency target?
3. **Mac App Store** — Accessibility API requires a special entitlement and Apple review. Confirm we are going direct download (.dmg) for v1.
4. **Key repeat threshold** — Confirm: sound plays once per physical key press, ignores system key-repeat events?
5. **Estimated timeline** — What is the expected delivery for v1.0 MVP?

---

*Document prepared by Rakibul Islam. All questions → [your contact].*
