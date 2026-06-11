#!/usr/bin/env python3
"""
KeyClick — procedural mechanical-keyboard sound generator.

Generates the full set of .caf sound assets for every sound profile.
These are *synthesized placeholders* — drop in real recordings later by
overwriting the files of the same name. Output format matches the spec:
mono, 16-bit, 44.1 kHz, Core Audio Format (.caf).

Usage:
    python3 generate_sounds.py [output_dir]

Default output_dir is ../Resources/Sounds relative to this script.
"""

import math
import os
import random
import struct
import sys
import zlib


def stable_seed(*parts):
    """Deterministic seed — Python's hash() is randomized per process."""
    return zlib.crc32('/'.join(parts).encode())

SAMPLE_RATE = 44100

# ---------------------------------------------------------------------------
# CAF writer (mono, 16-bit signed, big-endian LPCM)
# ---------------------------------------------------------------------------

def write_caf(path, samples):
    """samples: iterable of floats in [-1, 1]."""
    frames = len(samples)
    pcm = bytearray()
    for s in samples:
        v = int(max(-1.0, min(1.0, s)) * 32767.0)
        pcm += struct.pack('>h', v)

    with open(path, 'wb') as f:
        # File header: 'caff', version(1), flags(0)
        f.write(b'caff')
        f.write(struct.pack('>HH', 1, 0))

        # Audio Description chunk
        f.write(b'desc')
        f.write(struct.pack('>q', 32))
        f.write(struct.pack('>d', float(SAMPLE_RATE)))   # mSampleRate
        f.write(b'lpcm')                                  # mFormatID
        # flags: signed int(4) | big-endian(2) | packed(8) = 14
        f.write(struct.pack('>I', 14))                    # mFormatFlags
        f.write(struct.pack('>I', 2))                     # mBytesPerPacket
        f.write(struct.pack('>I', 1))                     # mFramesPerPacket
        f.write(struct.pack('>I', 1))                     # mChannelsPerFrame
        f.write(struct.pack('>I', 16))                    # mBitsPerChannel

        # Data chunk (size includes the 4-byte edit count)
        f.write(b'data')
        f.write(struct.pack('>q', len(pcm) + 4))
        f.write(struct.pack('>I', 0))                     # mEditCount
        f.write(pcm)
    return frames


# ---------------------------------------------------------------------------
# Tiny DSP helpers
# ---------------------------------------------------------------------------

def one_pole_lp(x, alpha):
    y = []
    prev = 0.0
    for v in x:
        prev = prev + alpha * (v - prev)
        y.append(prev)
    return y


def one_pole_hp(x, alpha):
    """High-pass = signal minus its low-passed version."""
    lp = one_pole_lp(x, alpha)
    return [a - b for a, b in zip(x, lp)]


def normalize(x, peak=0.85):
    m = max((abs(v) for v in x), default=0.0)
    if m < 1e-9:
        return x
    g = peak / m
    return [v * g for v in x]


def fade_out(x, ms=3.0):
    n = int(SAMPLE_RATE * ms / 1000.0)
    n = min(n, len(x))
    for i in range(n):
        x[-1 - i] *= i / n
    return x


# ---------------------------------------------------------------------------
# Voice synthesis: noise transient (the "click") + resonant body (the "thock")
# ---------------------------------------------------------------------------

def synth(seed, dur_ms, body_hz, noise_gain, tone_gain,
          noise_decay_ms, tone_decay_ms, brightness, gain=1.0):
    rng = random.Random(seed)
    n = int(SAMPLE_RATE * dur_ms / 1000.0)
    t = [i / SAMPLE_RATE for i in range(n)]

    # --- noise transient ---
    raw = [rng.uniform(-1.0, 1.0) for _ in range(n)]
    # brightness in [0,1] -> high-pass amount; brighter = more click
    raw = one_pole_hp(raw, 0.02 + 0.5 * brightness)
    raw = one_pole_lp(raw, 0.6)  # tame the very top end
    ndecay = noise_decay_ms / 1000.0
    noise = [raw[i] * math.exp(-t[i] / ndecay) for i in range(n)]

    # --- resonant body (two slightly detuned partials) ---
    tdecay = tone_decay_ms / 1000.0
    tone = []
    for i in range(n):
        env = math.exp(-t[i] / tdecay)
        s = (math.sin(2 * math.pi * body_hz * t[i])
             + 0.4 * math.sin(2 * math.pi * body_hz * 2.01 * t[i]))
        tone.append(s * env)

    mix = [noise[i] * noise_gain + tone[i] * tone_gain for i in range(n)]

    # soft attack to avoid a DC pop (~0.6 ms)
    a = int(SAMPLE_RATE * 0.0006)
    for i in range(min(a, n)):
        mix[i] *= i / a

    mix = normalize(mix, peak=0.85 * gain)
    mix = fade_out(mix, 3.0)
    return mix


def synth_chord(seed, profile):
    """Layered multi-note chord for the Hyper key / heavy combos."""
    base = profile['body_hz']
    layers = [
        synth(seed + 1, profile['dur'] * 1.4, base * 0.6,
              profile['noise_gain'] * 0.7, profile['tone_gain'] * 1.1,
              profile['noise_decay'], profile['tone_decay'] * 1.6,
              profile['brightness'], gain=0.9),
        synth(seed + 2, profile['dur'] * 1.2, base * 1.0,
              profile['noise_gain'], profile['tone_gain'],
              profile['noise_decay'], profile['tone_decay'],
              profile['brightness'], gain=0.8),
        synth(seed + 3, profile['dur'] * 1.0, base * 1.6,
              profile['noise_gain'] * 1.1, profile['tone_gain'] * 0.8,
              profile['noise_decay'], profile['tone_decay'] * 0.7,
              profile['brightness'], gain=0.7),
    ]
    n = max(len(l) for l in layers)
    out = [0.0] * n
    # stagger the notes slightly for a rapid-arpeggio feel
    offsets = [0, int(SAMPLE_RATE * 0.012), int(SAMPLE_RATE * 0.024)]
    for layer, off in zip(layers, offsets):
        for i, v in enumerate(layer):
            j = i + off
            if j < n:
                out[j] += v
    out = normalize(out, peak=0.9)
    out = fade_out(out, 4.0)
    return out


# ---------------------------------------------------------------------------
# Profiles + per-key variations
# ---------------------------------------------------------------------------

PROFILES = {
    'clicky-blue': dict(
        body_hz=380, dur=28, noise_gain=0.85, tone_gain=0.35,
        noise_decay=10, tone_decay=22, brightness=0.9),
    'tactile-brown': dict(
        body_hz=240, dur=36, noise_gain=0.6, tone_gain=0.55,
        noise_decay=14, tone_decay=34, brightness=0.55),
    'thocky-linear': dict(
        body_hz=150, dur=70, noise_gain=0.35, tone_gain=0.8,
        noise_decay=18, tone_decay=70, brightness=0.3),
}

# variation = (freq*, dur*, noise*, tone*, gain*)
VARIATIONS = {
    'base':           (1.00, 1.00, 1.00, 1.00, 1.00),
    'space':          (0.62, 1.65, 0.90, 1.15, 1.05),
    'enter':          (0.92, 1.05, 1.10, 1.00, 1.08),
    'backspace':      (0.72, 1.10, 0.70, 1.05, 0.85),
    'tab':            (0.85, 1.10, 1.00, 1.00, 0.95),
    'escape':         (1.12, 0.80, 1.20, 0.85, 1.00),
    'arrow':          (1.12, 0.70, 1.00, 0.90, 0.80),
    'function':       (0.95, 0.90, 0.80, 0.95, 0.62),
    'capslock-on':    (0.70, 1.50, 1.05, 1.10, 1.10),
    'capslock-off':   (1.05, 0.80, 0.95, 0.90, 0.78),
    'modifier-cmd':   (1.00, 0.90, 1.00, 0.95, 0.95),
    'modifier-opt':   (1.08, 0.80, 0.85, 0.90, 0.72),
    'modifier-ctrl':  (0.90, 1.00, 1.05, 1.00, 0.98),
    'modifier-shift': (1.12, 0.70, 0.90, 0.85, 0.72),
}


# ---------------------------------------------------------------------------
# Per-letter sounds (letter-a.caf … letter-z.caf)
#
# Each letter = its row's acoustic group character × a per-key tweak, plus a
# unique noise seed, modeling how switch position on the PCB, keycap size,
# and travel feel make every key on a real board sound slightly different.
# ---------------------------------------------------------------------------

# group = (freq*, dur*, noise*, tone*, gain*) relative to the profile's base
LETTER_GROUPS = {
    'thock': (0.84, 1.25, 0.90, 1.18, 1.04),  # home row: deep, long
    'click': (1.12, 0.88, 1.18, 0.88, 1.00),  # top row: sharp, quick
    'light': (1.24, 0.75, 0.95, 0.78, 0.84),  # bottom row: airy tap
}

# letter: (group, per-key tweak applied on top of the group)
LETTERS = {
    # --- home row: deep / thocky ---
    'a': ('thock', (0.96, 1.05, 0.92, 1.10, 1.00)),  # medium, slightly hollow
    's': ('thock', (1.00, 1.00, 1.00, 1.00, 1.02)),  # clean, satisfying
    'd': ('thock', (1.03, 0.98, 1.05, 0.98, 1.00)),  # fractionally sharper
    'f': ('thock', (0.97, 1.00, 0.78, 1.02, 0.94)),  # homing nub, muted
    'g': ('thock', (1.05, 0.90, 1.10, 0.95, 1.04)),  # center board, tight punch
    'h': ('thock', (1.05, 0.90, 1.10, 0.95, 1.04)),  # mirror of G
    'j': ('thock', (0.95, 1.00, 0.78, 1.02, 0.94)),  # homing nub like F
    'k': ('thock', (1.08, 0.95, 1.12, 0.92, 1.02)),  # clean, sharp click
    'l': ('thock', (0.98, 1.18, 0.88, 1.20, 1.00)),  # edge: resonant, open
    # --- top row: sharp / clicky ---
    'q': ('click', (0.96, 1.25, 0.85, 1.25, 0.98)),  # corner: hollow ring
    'w': ('click', (1.00, 1.00, 1.05, 1.00, 1.00)),  # clean sharp click
    'e': ('click', (1.03, 0.95, 1.08, 0.95, 1.00)),  # crisp
    'r': ('click', (1.02, 0.88, 1.05, 0.92, 0.98)),  # tight, quick
    't': ('click', (0.98, 0.95, 1.10, 1.00, 1.04)),  # center-ish, punchy
    'y': ('click', (1.00, 0.92, 1.02, 0.95, 0.94)),  # slightly lighter than T
    'u': ('click', (1.04, 0.88, 1.06, 0.92, 0.98)),  # crisp, quick return
    'i': ('click', (1.10, 0.85, 1.12, 0.85, 0.96)),  # very sharp, small cap
    'o': ('click', (0.94, 1.00, 0.92, 1.08, 0.98)),  # slightly rounded
    'p': ('click', (0.97, 1.20, 0.88, 1.20, 0.97)),  # edge: slight resonance
    # --- bottom row: light / airy ---
    'z': ('light', (0.96, 1.20, 0.85, 1.20, 0.92)),  # corner: hollow, light
    'x': ('light', (1.04, 0.90, 1.02, 0.90, 0.96)),  # light, quick tap
    'c': ('light', (1.00, 0.95, 1.05, 0.95, 1.00)),  # clean light click
    'v': ('light', (0.93, 1.00, 1.00, 1.05, 1.02)),  # slightly deeper than C
    'b': ('light', (0.86, 1.10, 1.08, 1.12, 1.10)),  # center bottom: punchy thock
    'n': ('light', (0.86, 1.10, 1.08, 1.12, 1.10)),  # mirror of B
    'm': ('light', (0.90, 1.05, 1.00, 1.05, 1.02)),  # slightly lighter than N
}


def letter_variation(letter):
    group, tweak = LETTERS[letter]
    return tuple(g * t for g, t in zip(LETTER_GROUPS[group], tweak))


def build_profile(name, params, out_root):
    folder = os.path.join(out_root, name)
    os.makedirs(folder, exist_ok=True)
    count = 0
    variations = dict(VARIATIONS)
    for letter in LETTERS:
        variations['letter-' + letter] = letter_variation(letter)
    for key, (vf, vd, vn, vt, vg) in variations.items():
        seed = stable_seed(name, key)
        samples = synth(
            seed,
            dur_ms=params['dur'] * vd,
            body_hz=params['body_hz'] * vf,
            noise_gain=params['noise_gain'] * vn,
            tone_gain=params['tone_gain'] * vt,
            noise_decay_ms=params['noise_decay'],
            tone_decay_ms=params['tone_decay'] * vd,
            brightness=params['brightness'],
            gain=vg,
        )
        write_caf(os.path.join(folder, key + '.caf'), samples)
        count += 1

    # layered combo chord
    chord_seed = stable_seed(name, 'combo-chord')
    write_caf(os.path.join(folder, 'combo-chord.caf'),
              synth_chord(chord_seed, params))
    count += 1
    return count


def main():
    if len(sys.argv) > 1:
        out_root = sys.argv[1]
    else:
        here = os.path.dirname(os.path.abspath(__file__))
        out_root = os.path.normpath(os.path.join(here, '..', 'Resources', 'Sounds'))
    os.makedirs(out_root, exist_ok=True)

    total = 0
    for name, params in PROFILES.items():
        c = build_profile(name, params, out_root)
        print(f"  {name}: {c} files")
        total += c
    print(f"Done. {total} .caf files written to {out_root}")


if __name__ == '__main__':
    main()
