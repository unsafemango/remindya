"""Synthesizes the Remindya 'woof woof' bark as a 16-bit mono WAV.

Usage (needs numpy and ffmpeg):

    python3 tool/make_bark.py /tmp/bark_raw.wav
    ffmpeg -y -i /tmp/bark_raw.wav \
        -af "highpass=f=120,lowpass=f=6000,loudnorm=I=-12:TP=-1" \
        -ar 44100 -ac 1 -sample_fmt s16 bark.wav
    cp bark.wav android/app/src/main/res/raw/bark.wav
    cp bark.wav ios/Runner/bark.wav
"""
import sys, wave
import numpy as np

SR = 44100
rng = np.random.default_rng(7)

def resonator(x, freq, bw):
    # 2-pole resonant bandpass (Klatt-style formant).
    r = np.exp(-np.pi * bw / SR)
    c = -r * r
    b = 2 * r * np.cos(2 * np.pi * freq / SR)
    a = 1 - b - c
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    for i, v in enumerate(x):
        y0 = a * v + b * y1 + c * y2
        y[i] = y0
        y2, y1 = y1, y0
    return y

def bark(dur, f_start, f_peak, f_end, formants):
    n = int(dur * SR)
    t = np.arange(n) / SR
    # Pitch: quick rise then a fall, the classic "wuh-OOF" contour.
    peak_t = 0.035
    f0 = np.where(
        t < peak_t,
        f_start + (f_peak - f_start) * (t / peak_t),
        f_peak + (f_end - f_peak) * np.clip((t - peak_t) / (dur - peak_t), 0, 1) ** 0.7,
    )
    f0 *= 1 + 0.02 * rng.standard_normal(n).cumsum() / np.sqrt(np.arange(1, n + 1))
    phase = 2 * np.pi * np.cumsum(f0) / SR
    voice = sum(np.sin(k * phase) / k ** 0.9 for k in range(1, 30))
    # Growl: fast amplitude roughness.
    voice *= 1 + 0.35 * np.sin(2 * np.pi * 38 * t + 1.3)
    noise = rng.standard_normal(n)
    src = voice + 0.9 * noise * np.exp(-t / 0.05) + 0.25 * noise

    out = sum(g * resonator(src, f, bw) for f, bw, g in formants)
    env = np.minimum(t / 0.006, 1) * np.exp(-np.maximum(t - 0.03, 0) / (dur * 0.25))
    # Raised-cosine fade so the bark ends without a click.
    fade = int(0.04 * SR)
    env[-fade:] *= 0.5 * (1 + np.cos(np.linspace(0, np.pi, fade)))
    out *= env
    return np.tanh(2.2 * out / np.abs(out).max())

formants = [(650, 140, 1.0), (1150, 180, 0.6), (2500, 300, 0.25), (3600, 400, 0.1)]
b1 = bark(0.22, 420, 620, 300, formants)
b2 = bark(0.20, 400, 580, 280, [(f * 0.95, bw, g) for f, bw, g in formants])
gap = np.zeros(int(0.12 * SR))
tail = np.zeros(int(0.05 * SR))
sig = np.concatenate([np.zeros(int(0.01 * SR)), b1, gap, b2, tail])
sig = 0.89 * sig / np.abs(sig).max()

with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((sig * 32767).astype("<i2").tobytes())
print(f"{len(sig) / SR:.2f}s")
