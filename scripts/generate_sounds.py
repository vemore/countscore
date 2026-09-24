#!/usr/bin/env python3
"""Writes the board's three sounds into assets/sounds/, from nothing but arithmetic.

The sounds are synthesised here rather than downloaded, so their provenance is this
file: no sample, no third-party recording. They are dedicated to the public domain
(CC0 1.0), like the rest of what the script writes, and need no credit.

    python3 scripts/generate_sounds.py

- elimination.wav: a descending "wah-wah-wah-waah", the classic losing trombone
- victory.wav: a rising major arpeggio and a held chord
- timer_end.wav: three short beeps, the turn timer reaching zero

Mono, 16-bit PCM, 22050 Hz: WAV plays on Android's MediaPlayer and in every browser.
Deterministic: the same run writes the same bytes.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freqs: list[float], seconds: float, *, volume: float = 0.5,
         slide_to: float | None = None, vibrato: float = 0.0) -> list[float]:
    """A note: the sum of [freqs] with a soft attack and release, optionally
    sliding its pitch by the ratio [slide_to] and wobbling by [vibrato] Hz."""
    n = int(RATE * seconds)
    attack = min(int(RATE * 0.01), n // 4)
    release = min(int(RATE * 0.08), n // 2)
    out: list[float] = []
    phases = [0.0] * len(freqs)
    for i in range(n):
        t = i / RATE
        ratio = 1.0 if slide_to is None else 1.0 + (slide_to - 1.0) * (i / n)
        wobble = 1.0 + (0.012 * math.sin(2 * math.pi * vibrato * t) if vibrato else 0.0)
        sample = 0.0
        for k, f in enumerate(freqs):
            phases[k] += 2 * math.pi * f * ratio * wobble / RATE
            # A little of the second and third harmonic: warmer than a pure sine.
            sample += (math.sin(phases[k]) + 0.3 * math.sin(2 * phases[k])
                       + 0.15 * math.sin(3 * phases[k]))
        sample /= len(freqs) * 1.45
        env = 1.0
        if i < attack:
            env = i / attack
        elif i > n - release:
            env = (n - i) / release
        out.append(sample * env * volume)
    return out


def silence(seconds: float) -> list[float]:
    return [0.0] * int(RATE * seconds)


def write(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


def main() -> None:
    # G3, F#3, F3, then E3 held and wobbling: the losing trombone.
    write("elimination.wav",
          tone([196.0], 0.28) + silence(0.04)
          + tone([185.0], 0.28) + silence(0.04)
          + tone([174.6], 0.28) + silence(0.04)
          + tone([164.8], 0.9, slide_to=0.97, vibrato=6.0))
    # C5, E5, G5, then the C major chord an octave up.
    write("victory.wav",
          tone([523.3], 0.12) + tone([659.3], 0.12) + tone([784.0], 0.12)
          + tone([1046.5, 784.0, 659.3], 0.8, volume=0.55))
    # Three A5 beeps.
    beep = tone([880.0], 0.16, volume=0.55)
    write("timer_end.wav", beep + silence(0.1) + beep + silence(0.1) + beep)


if __name__ == "__main__":
    main()
