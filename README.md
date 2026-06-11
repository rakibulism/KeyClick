# ⌨️ KeyClick

**Make your Mac sound like a mechanical keyboard.**

KeyClick is a tiny, free menu bar app for macOS that plays a satisfying
mechanical keyboard sound every time you press a key — on any keyboard,
in any app. Every letter A–Z has its own unique sound, just like a real
mechanical board where each key sounds slightly different.

> 🔒 **Private by design.** KeyClick never records, stores, or transmits
> anything you type. It only listens for key *presses* to play a sound —
> nothing is written to disk or sent over the network. Ever.

---

## ✨ Features

- 🎧 **Three switch profiles** — choose your sound:
  - **Clicky Blue** — sharp, high-pitched click (Cherry MX Blue style)
  - **Tactile Brown** — softer bump, medium pitch (Cherry MX Brown style)
  - **Thocky Linear** — deep, muted *thock* (lubed linear style)
- 🔤 **A unique sound for every letter A–Z** — home-row keys thock deeper,
  the top row clicks sharper, the bottom row taps lighter. F and J are
  subtly muted by their homing bumps, and corner keys like Q, Z, P, L
  ring slightly hollow — just like a physical board.
- ⌘ **Combo sounds** — modifier keys layer their own click under the key
  sound, and big combos (⌘⌥⌃⇧) trigger a distinctive chord.
- 🎚 **Independent volume** — keyboard sounds have their own volume slider,
  separate from your system volume.
- 🚀 **Zero lag, zero clutter** — sounds play in under 15 ms, the app lives
  quietly in your menu bar, and there's no Dock icon.
- 🔁 **Launch at Login** — set it once and forget it.

---

## 📥 Install

**Requires macOS 13 (Ventura) or later.**

1. **Download** [`KeyClick.zip`](https://github.com/rakibulism/KeyClick/raw/main/KeyClick.zip)
2. **Unzip it** — double-click the file in your Downloads folder. You'll get
   `KeyClick.app`.
3. **Move `KeyClick.app` to your `Applications` folder.**
4. **Allow the app to open.** KeyClick is free and isn't signed with a paid
   Apple Developer certificate, so macOS will block the first launch.
   Open **Terminal** (⌘ Space, type "Terminal") and paste this one line:

   ```bash
   xattr -d com.apple.quarantine /Applications/KeyClick.app
   ```

   This removes the download quarantine flag so macOS will run the app.
5. **Open KeyClick** from Applications. A ⌨️ icon appears in your menu bar
   (top-right of the screen).

### First launch: allow Accessibility

To hear your keystrokes, KeyClick needs the **Accessibility** permission —
this is the standard macOS permission for apps that respond to keys
system-wide. On first launch KeyClick will open
**System Settings → Privacy & Security → Accessibility** for you:

1. Find **KeyClick** in the list and turn it **on**.
2. That's it — sounds start instantly. No restart needed.

---

## 🎛 Using KeyClick

Click the **⌨️ icon** in your menu bar:

| Control | What it does |
|---|---|
| **Enabled** | Master switch — instantly mute/unmute all key sounds |
| **Sound Profile** | Pick Clicky Blue, Tactile Brown, or Thocky Linear |
| **Volume** | Key sound volume, independent of system volume |
| **Launch at Login** | Start KeyClick automatically when you log in |
| **Quit KeyClick** | Stop the app completely |

---

## 🛟 Troubleshooting

**“KeyClick is damaged and can't be opened”**
That's the quarantine flag from step 4 — run the `xattr` command above,
then open the app again.

**No sound while typing**
- Click the ⌨️ menu bar icon — if you see an orange *"Accessibility access
  needed"* banner, click **Open Settings…** and enable KeyClick in the list.
- Make sure the **Enabled** toggle is on and the volume slider isn't at zero.

**The permission is enabled but the banner won't go away**
Remove KeyClick from the Accessibility list (− button), then re-add it
(+ button → Applications → KeyClick), or toggle it off and on.

**Sounds stop after updating the app**
Re-grant Accessibility as above — macOS sometimes ties the permission to
the exact copy of the app you downloaded.

---

## 🔐 Privacy

KeyClick is built so it *can't* leak what you type:

- It uses a **listen-only** event tap — it never modifies, consumes, or
  records key events.
- It maps each key press to a sound and plays it. **No text is ever
  reconstructed, logged, stored, or transmitted.**
- The app makes **zero network connections** and writes nothing to disk
  except its own settings (volume, chosen profile).
- It's fully **open source** — audit every line in this repository.

---

## 🧑‍💻 For developers

KeyClick is written in Swift (SwiftUI + AVAudioEngine + CGEventTap) and
builds without Xcode — just the Command Line Tools:

```bash
git clone https://github.com/rakibulism/KeyClick.git
cd KeyClick
./Scripts/build_app.sh   # produces build/KeyClick.app
```

The bundled sounds are procedurally synthesized by
`Scripts/generate_sounds.py` (pure Python, no dependencies) — each letter's
sound is derived from its row's acoustic character plus a per-key tweak.
Swap in real recordings by overwriting the `.caf` files in
`Resources/Sounds/<profile>/` and rebuilding.
