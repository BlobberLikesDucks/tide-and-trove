"""Tide & Trove - music + SFX synthesizer (numpy only, v2).

    "<blender>/5.2/python/bin/python.exe" tools/gen_audio.py game/assets/audio

44.1 kHz stereo. Every music track is rendered into a circular buffer and its
reverb is a circular FFT convolution, so loops repeat with no seam and the reverb
tail of the last bar rings into the first. All three tracks share one melodic
motif (the "Tide & Trove" theme) so the score feels like one game:

  music_prep     morning beach, time paused   92 bpm  D major  ukulele, marimba lead,
                                                       plucked bass, shaker, surf, gulls
  music_open     museum open, busy day       116 bpm  F major  steel-pan lead (FM), uke
                                                       chops, calypso bass + drum kit
  music_closing  sunset reviews + ledger      76 bpm  F maj7   e-piano (FM), music-box
                                                       theme, warm pad, brushes, surf

Instruments: Karplus-Strong plucks (ukulele / bass), 2-operator FM (steel pan, e-piano,
marimba, bells), detuned additive pads, synthesized kit (kick, snare, clap, hats,
shaker, congas, brushes). SFX are layered (transient + body + tail) and share the
same reverb space so they sit in the mix.
"""
import os
import sys
import wave

import numpy as np

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(20261112)


# ----------------------------------------------------------------- basics ---
def hz(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def tv(n):
    return np.arange(n) / SR


def nsamp(sec):
    return max(1, int(round(sec * SR)))


def env(n, a=0.005, d=0.1, s=0.6, r=0.2, hold=None):
    """ADSR envelope of n samples; `hold` = seconds before release starts."""
    t = tv(n)
    hold = (n / SR - r) if hold is None else hold
    e = np.where(t < a, t / max(a, 1e-6), s + (1 - s) * np.exp(-(t - a) / max(d, 1e-6)))
    rel = np.clip((t - hold) / max(r, 1e-6), 0, 1)
    return e * (1 - rel)


def perc(n, a=0.002, decay=0.3):
    t = tv(n)
    return np.minimum(1.0, t / a) * np.exp(-t / decay)


def lowpass(x, fc, order=2):
    X = np.fft.rfft(x, axis=0)
    f = np.fft.rfftfreq(x.shape[0], 1 / SR)
    h = 1.0 / np.sqrt(1.0 + (f / fc) ** (2 * order))
    return np.fft.irfft(X * (h if x.ndim == 1 else h[:, None]), n=x.shape[0], axis=0)


def highpass(x, fc, order=2):
    return x - lowpass(x, fc, order)


def bandpass(x, lo, hi):
    return highpass(lowpass(x, hi), lo)


def noise(n):
    return rng.standard_normal(n)


def pan(x, p=0.0, gain=1.0):
    """Equal-power pan, p in [-1, 1] -> (n, 2)."""
    a = (p + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)], axis=1) * gain


def softclip(x, drive=1.0):
    return np.tanh(x * drive) / np.tanh(drive)


# ------------------------------------------------------------ instruments ---
def ks_pluck(f, dur, bright=0.6, decay=0.996, body=0.0):
    """Karplus-Strong string, vectorised one period at a time, retuned by resampling."""
    n = nsamp(dur)
    P = max(2, int(round(SR / f)))
    f0 = SR / P
    m = int(n * f / f0) + P + 2
    y = np.zeros(m)
    burst = noise(P)
    burst = lowpass(burst, 1500 + 7000 * bright) if P > 16 else burst
    y[:P] = burst / (np.max(np.abs(burst)) + 1e-9)
    k = 1
    while k * P < m:
        prev = y[(k - 1) * P:k * P]
        nxt = 0.5 * (prev + np.roll(prev, 1)) * decay
        end = min(m, (k + 1) * P)
        y[k * P:end] = nxt[:end - k * P]
        k += 1
    src = np.arange(n) * (f / f0)
    out = np.interp(src, np.arange(m), y)
    if body:
        out += body * np.sin(2 * np.pi * f * tv(n)) * perc(n, 0.003, 0.08)
    return out * env(n, 0.001, 0.4, 1.0, 0.03)


def fm(f, dur, ratio=1.0, index=2.0, idecay=0.3, a=0.002, decay=0.6, sustain=0.0, r=0.05, ratio2=None, index2=0.0):
    n = nsamp(dur)
    t = tv(n)
    I = index * np.exp(-t / idecay)
    mod = I * np.sin(2 * np.pi * f * ratio * t)
    if ratio2:
        mod += index2 * np.exp(-t / (idecay * 0.4)) * np.sin(2 * np.pi * f * ratio2 * t)
    y = np.sin(2 * np.pi * f * t + mod)
    e = np.minimum(1, t / a) * (sustain + (1 - sustain) * np.exp(-t / decay))
    rel = np.clip((t - (n / SR - r)) / r, 0, 1)
    return y * e * (1 - rel)


def steelpan(f, dur):
    # bright metallic attack that settles into a near-harmonic tone (2:1 + 4.2 shimmer)
    return 0.8 * fm(f, dur, ratio=2.0, index=1.6, idecay=0.12, decay=0.45, ratio2=4.2, index2=0.6) + \
        0.25 * fm(f * 2, dur, ratio=1.0, index=0.4, idecay=0.1, decay=0.25)


def marimba(f, dur):
    return fm(f, dur, ratio=4.0, index=1.4, idecay=0.025, decay=0.32) + 0.3 * fm(f * 4.0, dur, ratio=1, index=0, decay=0.05)


def epiano(f, dur):
    tine = fm(f, dur, ratio=1.0, index=1.2, idecay=0.5, decay=1.4, sustain=0.15, r=0.25)
    bell = fm(f, dur, ratio=14.0, index=0.9, idecay=0.03, decay=0.08)
    return tine + 0.25 * bell


def musicbox(f, dur):
    return fm(f, dur, ratio=3.5, index=1.0, idecay=0.08, decay=0.9) + 0.4 * fm(f * 2, dur, ratio=1, index=0.0, decay=0.4)


def bell(f, dur, decay=1.5):
    return fm(f, dur, ratio=1.4, index=2.4, idecay=0.6, decay=decay) + 0.3 * fm(f * 2.76, dur, ratio=1, index=0.3, decay=decay * 0.5)


def pad(f, dur, a=0.6, r=0.8, bright=1800):
    n = nsamp(dur)
    t = tv(n)
    y = np.zeros(n)
    for det in (-0.09, 0.0, 0.08):
        ff = f * 2 ** (det / 12)
        for h in range(1, 9):  # band-limited saw
            y += np.sin(2 * np.pi * ff * h * t + det * 7 * h) / h
    y = lowpass(y, bright)
    return y / 6.0 * env(n, a, 0.5, 0.85, r)


def bass(f, dur):
    n = nsamp(dur)
    t = tv(n)
    y = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) + 0.12 * np.sin(6 * np.pi * f * t)
    pl = ks_pluck(f, dur, bright=0.15, decay=0.998)
    return (0.7 * y * env(n, 0.004, 0.25, 0.5, 0.06) + 0.6 * pl)


# ------------------------------------------------------------------ drums ---
def kick(dur=0.45, f0=150, f1=48):
    n = nsamp(dur)
    t = tv(n)
    fr = f1 + (f0 - f1) * np.exp(-t / 0.04)
    ph = 2 * np.pi * np.cumsum(fr) / SR
    click = lowpass(noise(n), 3000) * perc(n, 0.0005, 0.004) * 0.4
    return np.sin(ph) * perc(n, 0.001, 0.22) + click


def snare(dur=0.3, tone=190):
    n = nsamp(dur)
    t = tv(n)
    body = np.sin(2 * np.pi * tone * t) * perc(n, 0.001, 0.06)
    sn = bandpass(noise(n), 1200, 9000) * perc(n, 0.001, 0.12)
    return 0.6 * body + 0.8 * sn


def clap(dur=0.25):
    n = nsamp(dur)
    e = np.zeros(n)
    for k, off in enumerate((0.0, 0.011, 0.022, 0.034)):
        i = nsamp(off)
        e[i:] += perc(n - i, 0.0005, 0.012 if k < 3 else 0.09)
    return bandpass(noise(n), 900, 6000) * e


def hat(dur=0.06, open_=False):
    n = nsamp(0.3 if open_ else dur)
    return highpass(noise(n), 7000) * perc(n, 0.0005, 0.12 if open_ else 0.022)


def shaker(dur=0.09):
    n = nsamp(dur)
    return bandpass(noise(n), 4500, 12000) * env(n, 0.012, 0.03, 0.0, 0.03)


def conga(f=200, dur=0.35):
    n = nsamp(dur)
    t = tv(n)
    fr = f * (1 + 0.25 * np.exp(-t / 0.01))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    slap = bandpass(noise(n), 800, 4000) * perc(n, 0.0005, 0.006) * 0.4
    return np.sin(ph) * perc(n, 0.001, 0.16) + slap


def brush(dur=0.5):
    n = nsamp(dur)
    return bandpass(noise(n), 2500, 9000) * env(n, 0.08, 0.15, 0.3, 0.2) * 0.5


def surf(n, period, depth=0.75):
    """Ocean bed: filtered noise with wave-shaped swells that loop exactly."""
    t = np.arange(n) / n
    sw = 0.5 - 0.5 * np.cos(2 * np.pi * t * period)
    sw = sw ** 1.6 * depth + (1 - depth) * 0.25
    l = lowpass(noise(n), 900) * sw
    r = lowpass(noise(n), 900) * np.roll(sw, n // (period * 3))
    return np.stack([l, r], axis=1)


def gull(dur=0.5):
    n = nsamp(dur)
    t = tv(n)
    fr = 1500 + 900 * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 0.5 - 600 * t / dur
    ph = 2 * np.pi * np.cumsum(fr) / SR
    y = np.sin(ph) + 0.4 * np.sin(2 * ph) + 0.2 * np.sin(3.1 * ph)
    am = 0.6 + 0.4 * np.sin(2 * np.pi * 28 * t)
    return y * am * env(n, 0.02, 0.1, 0.7, 0.12) * 0.25


# ------------------------------------------------------------ mix + reverb ---
def reverb_ir(sec=2.2, tone=5000, predelay=0.012):
    n = nsamp(sec)
    t = tv(n)
    d = np.exp(-t * 6.9 / sec)
    irs = []
    for _ in range(2):
        x = noise(n) * d
        x = lowpass(x, tone)
        x[:nsamp(predelay)] = 0
        irs.append(x / np.sqrt(np.sum(x ** 2)))
    return np.stack(irs, axis=1)


def circ_reverb(x, ir, mix=0.25):
    """Circular (loop-seamless) stereo convolution reverb."""
    n = x.shape[0]
    irp = np.zeros((n, 2))
    m = min(n, ir.shape[0])
    irp[:m] = ir[:m]
    wet = np.zeros_like(x)
    for c in range(2):
        wet[:, c] = np.fft.irfft(np.fft.rfft(x[:, c]) * np.fft.rfft(irp[:, c]), n=n)
    return x * (1 - mix * 0.5) + wet * mix


def lin_reverb(x, ir, mix=0.2):
    """Linear convolution for one-shots (pads with the tail)."""
    n = x.shape[0] + ir.shape[0]
    out = np.zeros((n, 2))
    out[:x.shape[0]] = x * (1 - mix * 0.5)
    for c in range(2):
        out[:, c] += mix * np.fft.irfft(np.fft.rfft(x[:, c], n) * np.fft.rfft(ir[:, c], n), n=n)
    # trim the silent end of the tail
    e = np.max(np.abs(out), axis=1)
    last = np.nonzero(e > 1e-3 * e.max())[0]
    return out[:last[-1] + 1] if len(last) else out


class Loop:
    def __init__(self, bpm, bars, beats=4):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.n = nsamp(bars * beats * self.beat)
        self.buf = np.zeros((self.n, 2))

    def at(self, beat):
        return int(round(beat * self.beat * SR)) % self.n

    def add(self, beat, mono, p=0.0, gain=1.0, swing=0.0):
        x = pan(mono, p, gain)
        i = self.at(beat + (swing if (beat * 2) % 2 == 1 else 0))
        idx = (np.arange(x.shape[0]) + i) % self.n
        np.add.at(self.buf, idx, x)

    def add_st(self, beat, st, gain=1.0):
        i = self.at(beat)
        idx = (np.arange(st.shape[0]) + i) % self.n
        np.add.at(self.buf, idx, st * gain)


def write(name, x, peak_db=-1.0, stereo=True):
    x = np.asarray(x, dtype=np.float64)
    if x.ndim == 1:
        x = pan(x, 0.0) * np.sqrt(2)
    x = x - np.mean(x, axis=0)
    m = np.max(np.abs(x)) + 1e-12
    x = softclip(x / m * 1.15, 1.3) * (10 ** (peak_db / 20))
    # 3 ms fades on one-shots
    if not name.startswith("music"):
        f = min(nsamp(0.003), x.shape[0] // 4)
        x[:f] *= np.linspace(0, 1, f)[:, None]
        x[-f:] *= np.linspace(1, 0, f)[:, None]
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote %-16s %6.2fs" % (name, x.shape[0] / SR))


# ------------------------------------------------------------------ theme ---
# The "Tide & Trove" motif as (beat offset, length, scale degree) over 2 bars.
# Rising like a wave, falling back like the tide, ending on a question.
THEME = [(0, 0.5, 5), (0.5, 0.5, 6), (1, 1, 8), (2, 0.5, 7), (2.5, 0.5, 6), (3, 1, 5),
         (4, 0.5, 3), (4.5, 0.5, 5), (5, 1.5, 6), (6.5, 0.5, 5), (7, 1, 2)]
ANSWER = [(0, 0.5, 5), (0.5, 0.5, 6), (1, 1, 8), (2, 0.5, 9), (2.5, 0.5, 8), (3, 1, 6),
          (4, 0.5, 5), (4.5, 0.5, 3), (5, 1.5, 2), (6.5, 0.5, 2), (7, 1, 1)]
MAJOR = [0, 2, 4, 5, 7, 9, 11]


def degree(root, d):
    d -= 1
    return root + MAJOR[d % 7] + 12 * (d // 7)


def chord_notes(root, kind):
    iv = {"maj": [0, 4, 7], "min": [0, 3, 7], "maj7": [0, 4, 7, 11], "min7": [0, 3, 7, 10], "dom7": [0, 4, 7, 10], "sus": [0, 5, 7, 10]}[kind]
    return [root + i for i in iv]


# ------------------------------------------------------------- music_prep ---
def music_prep():
    L = Loop(92, 16)
    key = 62  # D
    prog = [(62, "maj"), (59, "min"), (55, "maj"), (57, "maj"), (62, "maj"), (54, "min"), (55, "maj"), (57, "maj")] * 2
    for bar, (root, kind) in enumerate(prog):
        b0 = bar * 4
        notes = chord_notes(root, kind)
        uke = [n + 12 if n < 60 else n for n in notes] + [notes[0] + 12]
        uke = sorted(set(uke))[:4]
        # strum pattern: D . D U . U D U
        for beat, down, g in ((0, True, 1.0), (1, True, 0.7), (1.5, False, 0.45), (2.5, False, 0.5), (3, True, 0.7), (3.5, False, 0.45)):
            order = uke if down else uke[::-1]
            for k, n in enumerate(order):
                L.add(b0 + beat + k * 0.018 / L.beat * 1.0, ks_pluck(hz(n), 1.2, bright=0.55, decay=0.994), p=-0.35 + k * 0.08, gain=0.16 * g)
        L.add(b0, bass(hz(root - 12 if root >= 55 else root), 1.6), gain=0.45)
        L.add(b0 + 2, bass(hz(root - 5 if root >= 55 else root + 7), 1.2), gain=0.32)
        for e in range(8):
            L.add(b0 + e * 0.5, shaker(), p=0.4, gain=0.09 if e % 2 else 0.05)
    # marimba theme (bars 1-4 theme, 5-8 answer, 9-12 theme up an octave, 13-16 answer)
    for sec, (phrase, oct_) in enumerate(((THEME, 0), (ANSWER, 0), (THEME, 12), (ANSWER, 0))):
        for rep in range(2):
            b0 = sec * 16 + rep * 8
            if rep == 1 and sec % 2 == 0:
                continue
            for (bo, ln, d) in phrase:
                L.add(b0 + bo, marimba(hz(degree(key, d) + oct_), ln * L.beat + 0.4), p=0.15, gain=0.32)
    # counter-melody pads on the second half
    for bar, (root, kind) in enumerate(prog[8:]):
        for n in chord_notes(root, kind)[:3]:
            L.add(32 + bar * 4, pad(hz(n), 4 * L.beat, a=0.8, r=0.6, bright=1200), p=0.0, gain=0.05)
    for b in (14, 47):
        L.add(b, gull(0.55), p=-0.7, gain=0.5)
        L.add(b + 0.6, gull(0.4), p=-0.6, gain=0.35)
    mix = circ_reverb(L.buf, reverb_ir(2.4, 4500), 0.28)
    mix += surf(L.n, 4) * 0.06
    write("music_prep", mix, -3.0)


# ------------------------------------------------------------- music_open ---
def music_open():
    L = Loop(116, 16)
    key = 65  # F
    prog = [(65, "maj"), (62, "min"), (58, "maj"), (60, "maj"), (65, "maj"), (57, "min"), (58, "maj"), (60, "dom7")] * 2
    sw = 0.06  # light calypso swing on offbeats
    for bar, (root, kind) in enumerate(prog):
        b0 = bar * 4
        notes = chord_notes(root, kind)
        # uke chops on every "and"
        for e in (0.5, 1.5, 2.5, 3.5):
            for k, n in enumerate(sorted(set([x + 12 if x < 62 else x for x in notes]))[:4]):
                L.add(b0 + e, ks_pluck(hz(n), 0.25, bright=0.7, decay=0.985), p=-0.4 + k * 0.1, gain=0.12, swing=sw)
        # calypso bass: 1 . (2&) 3 . (4&)
        r = root - 12 if root >= 60 else root
        for (bt, iv, g) in ((0, 0, 0.5), (1.5, 7, 0.38), (2, 0, 0.45), (3.5, 12 if bar % 2 else 7, 0.36)):
            L.add(b0 + bt, bass(hz(r + iv), 0.45), gain=g)
        # kit
        L.add(b0, kick(), gain=0.55)
        L.add(b0 + 2, kick(), gain=0.5)
        L.add(b0 + 2.75, kick(0.3), gain=0.3)
        for bt in (1, 3):
            L.add(b0 + bt, snare(), p=0.1, gain=0.32)
            L.add(b0 + bt, clap(), p=-0.1, gain=0.2)
        for e in range(8):
            L.add(b0 + e * 0.5, hat(open_=(e == 7)), p=0.35, gain=0.13 if e % 2 else 0.08, swing=sw)
        for e in range(16):
            L.add(b0 + e * 0.25, shaker(0.06), p=-0.45, gain=0.035 + 0.02 * (e % 4 == 2))
        for (bt, f, p) in ((0.5, 220, 0.6), (1.5, 260, 0.65), (2.0, 220, 0.6), (3.0, 180, 0.55), (3.5, 260, 0.65)):
            L.add(b0 + bt, conga(f), p=p, gain=0.22, swing=sw)
        if bar in (7, 15):  # conga fill into the next phrase
            for k in range(6):
                L.add(b0 + 2.5 + k * 0.25, conga(300 - k * 22, 0.2), p=0.5 - k * 0.15, gain=0.28)
    # steel-pan theme, syncopated, then the answer; second time with harmony thirds
    for sec in range(4):
        phrase = THEME if sec % 2 == 0 else ANSWER
        for rep in range(2):
            b0 = sec * 16 + rep * 8
            for (bo, ln, d) in phrase:
                syn = 0.5 if (rep == 1 and bo in (1, 5)) else 0.0
                n = degree(key, d) + 12
                L.add(b0 + bo + syn, steelpan(hz(n), ln * L.beat + 0.3), p=0.2, gain=0.3)
                if sec >= 2:
                    L.add(b0 + bo + syn, steelpan(hz(degree(key, d - 2) + 12), ln * L.beat + 0.3), p=-0.2, gain=0.16)
    mix = circ_reverb(L.buf, reverb_ir(1.6, 6000), 0.18)
    write("music_open", mix, -3.0)


# ---------------------------------------------------------- music_closing ---
def music_closing():
    L = Loop(76, 16)
    key = 65
    prog = [(65, "maj7"), (64, "min7"), (62, "min7"), (60, "maj7"), (58, "maj7"), (57, "min7"), (55, "min7"), (60, "sus")] * 2
    for bar, (root, kind) in enumerate(prog):
        b0 = bar * 4
        notes = chord_notes(root, kind)
        voic = [notes[0] - 12] + notes[1:]
        for k, n in enumerate(voic):
            L.add(b0 + k * 0.02, epiano(hz(n), 2.6 * L.beat), p=-0.25 + k * 0.15, gain=0.13)
            L.add(b0 + 2.5 + k * 0.02, epiano(hz(n), 1.4 * L.beat), p=-0.25 + k * 0.15, gain=0.08)
        for n in notes[:3]:
            L.add(b0, pad(hz(n - 12), 4 * L.beat + 0.5, a=1.2, r=1.0, bright=900), gain=0.05)
        L.add(b0, bass(hz(root - 24 if root >= 60 else root - 12), 3.2), gain=0.35)
        L.add(b0, kick(0.5, 110, 45), gain=0.25)
        L.add(b0 + 1, brush(0.6), p=0.3, gain=0.35)
        L.add(b0 + 3, brush(0.6), p=-0.3, gain=0.35)
        for e in range(4):
            L.add(b0 + e + 0.5, hat(0.04), p=0.4, gain=0.04)
    # music-box theme, slow and sparse, an octave up
    for sec in range(4):
        if sec == 0:
            continue
        phrase = THEME if sec != 2 else ANSWER
        b0 = sec * 16
        for (bo, ln, d) in phrase:
            L.add(b0 + bo * 2, musicbox(hz(degree(key, d) + 12), ln * 2 * L.beat + 0.6), p=0.25, gain=0.2)
    L.add(30, gull(0.6), p=0.8, gain=0.25)
    mix = circ_reverb(L.buf, reverb_ir(3.2, 3800), 0.38)
    mix += surf(L.n, 4, depth=0.6) * 0.07
    write("music_closing", mix, -3.5)


# -------------------------------------------------------------------- SFX ---
IR_ROOM = None


def oneshot(name, mono_or_st, mix=0.12, peak=-1.0, ir=None):
    x = mono_or_st if np.ndim(mono_or_st) == 2 else pan(mono_or_st, 0.0) * np.sqrt(2)
    x = lin_reverb(x, ir if ir is not None else IR_ROOM, mix) if mix > 0 else x
    write(name, x, peak)


def place(total, parts):
    """Mix (start_sec, mono, pan, gain) parts into a stereo buffer."""
    n = nsamp(total)
    out = np.zeros((n, 2))
    for st, x, p, g in parts:
        i = nsamp(st) if st > 0 else 0
        seg = pan(x, p, g)[: n - i]
        out[i:i + seg.shape[0]] += seg
    return out


def sweep(f0, f1, dur, shape="sin", curve=1.0):
    n = nsamp(dur)
    t = np.linspace(0, 1, n) ** curve
    fr = f0 + (f1 - f0) * t
    ph = 2 * np.pi * np.cumsum(fr) / SR
    if shape == "sin":
        return np.sin(ph)
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    return np.sign(np.sin(ph)) * 0.6


def sfx_all():
    global IR_ROOM
    IR_ROOM = reverb_ir(0.9, 5000, 0.006)
    n = lambda s: nsamp(s)  # noqa

    # digging -----------------------------------------------------------------
    d = 0.4
    scrape = bandpass(noise(n(d)), 600, 5000) * env(n(d), 0.01, 0.08, 0.3, 0.15)
    thump = np.sin(2 * np.pi * 90 * tv(n(d))) * perc(n(d), 0.002, 0.05)
    grit = highpass(noise(n(d)), 3000) * (rng.random(n(d)) < 0.02) * perc(n(d), 0.01, 0.2)
    oneshot("sfx_dig_sand", place(d, [(0, scrape, -0.1, 0.8), (0, thump, 0, 0.9), (0.03, grit, 0.2, 1.5)]))
    d = 0.55
    clink = sum(np.sin(2 * np.pi * f * tv(n(d))) * perc(n(d), 0.0005, 0.12 / (i + 1)) for i, f in enumerate((1850, 3120, 4870, 6600)))
    crack_ = bandpass(noise(n(d)), 800, 7000) * perc(n(d), 0.0005, 0.03)
    rattle = sum(np.roll(bandpass(noise(n(0.05)), 1500, 6000) * perc(n(0.05), 0.001, 0.01), 0) for _ in range(1))
    parts = [(0, clink, 0.1, 0.5), (0, crack_, -0.1, 1.0)]
    for k in range(6):
        parts.append((0.08 + k * 0.045 + rng.random() * 0.02, rattle, rng.uniform(-0.6, 0.6), 0.35))
    oneshot("sfx_dig_rock", place(d, parts))
    # coins / UI ----------------------------------------------------------------
    oneshot("sfx_coin", place(0.6, [(0, bell(hz(83), 0.5, 0.25), -0.1, 0.5), (0.075, bell(hz(88), 0.5, 0.35), 0.1, 0.6)]), mix=0.15)
    d = 0.7
    ping = np.sin(2 * np.pi * np.cumsum(1400 - 300 * np.linspace(0, 1, n(d)) ** 0.3) / SR) * perc(n(d), 0.002, 0.18)
    oneshot("sfx_ping", place(d, [(0, ping, 0, 0.7), (0.16, ping, -0.4, 0.25), (0.3, ping, 0.4, 0.12)]), mix=0.2)
    oneshot("sfx_click", place(0.06, [(0, bandpass(noise(n(0.06)), 1800, 6000) * perc(n(0.06), 0.0003, 0.006), 0, 1.0),
                                      (0, np.sin(2 * np.pi * 1200 * tv(n(0.06))) * perc(n(0.06), 0.0005, 0.01), 0, 0.4)]), mix=0.0)
    d = 0.5
    wn = noise(n(d))
    sw = env(n(d), 0.18, 0.1, 1.0, 0.3, hold=0.18)
    wh = np.stack([lowpass(wn, 2500) * sw * np.linspace(1.0, 0.3, n(d)), lowpass(wn[::-1].copy(), 2500) * sw * np.linspace(0.3, 1.0, n(d))], axis=1)
    oneshot("sfx_whoosh", wh, mix=0.1)
    d = 0.45
    bonk = sweep(520, 160, d, "tri", 0.5) * perc(n(d), 0.001, 0.12)
    knock = bandpass(noise(n(d)), 300, 1800) * perc(n(d), 0.0005, 0.02)
    oneshot("sfx_bonk", place(d, [(0, bonk, 0, 0.9), (0, knock, 0, 0.7)]))
    # progression stingers -----------------------------------------------------------
    parts = []
    for k, m in enumerate((72, 76, 79, 84, 88)):
        parts.append((k * 0.09, bell(hz(m), 1.2, 0.6), -0.5 + k * 0.25, 0.4))
    sparkle = highpass(noise(n(1.2)), 6000) * (rng.random(n(1.2)) < 0.004) * env(n(1.2), 0.3, 0.3, 0.4, 0.6)
    parts.append((0.3, sparkle, 0, 2.0))
    oneshot("sfx_star_up", place(1.8, parts), mix=0.25)
    d = 0.5
    chirp = np.concatenate([sweep(900, 1300, 0.07, "sq"), np.zeros(n(0.03)), sweep(1300, 900, 0.07, "sq")])
    chirp = bandpass(np.pad(chirp, (0, n(d) - chirp.shape[0])), 400, 3200)
    static = bandpass(noise(n(d)), 1000, 4000) * env(n(d), 0.005, 0.05, 0.25, 0.1, hold=0.3) * 0.25
    oneshot("sfx_alert", place(d, [(0, chirp, 0, 0.9), (0, static, 0, 1.0)]), mix=0.05)
    d = 0.32
    cr = bandpass(noise(n(d)), 1200, 9000) * perc(n(d), 0.0003, 0.02)
    res = sum(np.sin(2 * np.pi * f * tv(n(d))) * perc(n(d), 0.001, 0.04) for f in (420, 760, 1310))
    oneshot("sfx_crack", place(d, [(0, cr, 0, 1.0), (0.004, res, 0, 0.3), (0.05, cr * 0.4, 0.3, 0.6)]))
    oneshot("sfx_chip", place(0.08, [(0, bandpass(noise(n(0.08)), 2500, 9000) * perc(n(0.08), 0.0003, 0.008), 0, 1.0)]), mix=0.05)
    d = 0.22
    br = bandpass(noise(n(d)), 2000, 8000) * env(n(d), 0.03, 0.05, 0.6, 0.08) * (0.7 + 0.3 * np.sin(2 * np.pi * 40 * tv(n(d))))
    oneshot("sfx_brush", br, mix=0.05)
    oneshot("sfx_bell", place(1.8, [(0, bell(hz(79), 1.8, 1.2), -0.1, 0.6), (0.02, bell(hz(91), 1.4, 0.8), 0.1, 0.25)]), mix=0.3)
    d = 0.8
    clunk = lowpass(noise(n(0.1)), 1500) * perc(n(0.1), 0.001, 0.02)
    drawer = bandpass(noise(n(0.25)), 300, 2500) * env(n(0.25), 0.02, 0.05, 0.6, 0.08)
    ching = bell(hz(93), 0.6, 0.35) + 0.6 * bell(hz(100), 0.6, 0.3)
    oneshot("sfx_register", place(d, [(0, clunk, -0.2, 1.0), (0.04, drawer, -0.1, 0.6), (0.16, ching, 0.15, 0.55)]), mix=0.15)
    d = 0.4
    er = 0.6 * sweep(330, 300, 0.18, "tri") * env(n(0.18), 0.005, 0.05, 0.7, 0.05)
    er2 = 0.6 * sweep(250, 200, 0.2, "tri") * env(n(0.2), 0.005, 0.05, 0.7, 0.08)
    oneshot("sfx_error", place(d, [(0, lowpass(er, 1500), 0, 1.0), (0.17, lowpass(er2, 1200), 0, 1.0)]), mix=0.08)
    d = 0.28
    pg = bandpass(noise(n(d)), 1500, 7000) * env(n(d), 0.02, 0.04, 0.5, 0.1) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 18 * tv(n(d)))))
    oneshot("sfx_page", pg, mix=0.05)
    d = 0.2
    pop = np.sin(2 * np.pi * np.cumsum(np.linspace(500, 1400, n(d))) / SR) * perc(n(d), 0.001, 0.06)
    oneshot("sfx_pickup", place(d, [(0, pop, 0, 1.0), (0.05, np.sin(2 * np.pi * 1760 * tv(n(0.1))) * perc(n(0.1), 0.001, 0.04), 0.2, 0.4)]), mix=0.1)
    # characters --------------------------------------------------------------------
    d = 0.7
    t = tv(n(d))
    f0 = 520 + 120 * np.sin(2 * np.pi * 7 * t) - 180 * t
    ph = 2 * np.pi * np.cumsum(f0) / SR
    saw = sum(np.sin(h * ph) / h for h in range(1, 10))
    vow = bandpass(saw, 700, 1300) + 0.5 * bandpass(saw, 2200, 3000)
    oneshot("sfx_tantrum", vow * env(n(d), 0.03, 0.1, 0.8, 0.2), mix=0.1)
    # fanfare: brass-ish stacked saws + timpani
    parts = []
    for (st, notes, ln) in ((0.0, (67, 71, 74), 0.18), (0.2, (67, 71, 74), 0.18), (0.4, (72, 76, 79), 0.9), (1.35, (74, 77, 81), 0.25), (1.6, (76, 79, 84), 0.9)):
        for k, m in enumerate(notes):
            nn = n(ln + 0.2)
            tt = tv(nn)
            vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * tt) * np.clip(tt / 0.2, 0, 1)
            ph = 2 * np.pi * np.cumsum(hz(m) * vib) / SR
            br = sum(np.sin(h * ph) / h ** 1.1 for h in range(1, 12))
            br = lowpass(br * env(nn, 0.04, 0.2, 0.75, 0.15), 2600)
            parts.append((st, br, -0.4 + k * 0.4, 0.22))
    for st in (0.4, 1.6):
        parts.append((st, kick(0.8, 120, 60), 0, 0.7))
    parts.append((1.6, highpass(noise(n(1.0)), 5000) * perc(n(1.0), 0.002, 0.3), 0.3, 0.2))
    oneshot("sfx_fanfare", place(2.8, parts), mix=0.3)
    parts = []
    for k, m in enumerate((65, 64, 63, 62)):
        ln = 0.36 if k < 3 else 0.9
        nn = n(ln + 0.15)
        tt = tv(nn)
        bend = 1 - (0.03 * tt / ln if k == 3 else 0)
        wob = 1 + (0.01 * np.sin(2 * np.pi * 6 * tt) if k == 3 else 0)
        ph = 2 * np.pi * np.cumsum(hz(m - 12) * bend * wob) / SR
        tb = sum(np.sin(h * ph) / h ** 1.3 for h in range(1, 10))
        parts.append((k * 0.38, lowpass(tb * env(nn, 0.03, 0.2, 0.8, 0.12), 1500), 0, 0.5))
    oneshot("sfx_gameover", place(2.3, parts), mix=0.25)
    d = 0.25
    thud = np.sin(2 * np.pi * 70 * tv(n(d))) * perc(n(d), 0.002, 0.03)
    grit = bandpass(noise(n(d)), 1500, 6000) * env(n(d), 0.004, 0.03, 0.2, 0.06)
    oneshot("sfx_step", place(d, [(0, thud, 0, 0.8), (0.005, grit, 0, 0.45)]), mix=0.03)
    # crowd cheer: many formant voices + clapping
    d = 1.4
    parts = []
    for k in range(14):
        nn = n(d)
        tt = tv(nn)
        f0 = rng.uniform(180, 420)
        ph = 2 * np.pi * np.cumsum(f0 * (1 + 0.06 * np.sin(2 * np.pi * rng.uniform(4, 7) * tt)) * (1 + 0.15 * tt)) / SR
        src = sum(np.sin(h * ph) / h for h in range(1, 8)) + 0.3 * noise(nn)
        lo, hi = rng.choice([(600, 1100), (300, 900), (800, 1600)])
        v = bandpass(src, lo, hi) * env(nn, rng.uniform(0.02, 0.15), 0.3, 0.6, 0.5)
        parts.append((rng.uniform(0, 0.12), v, rng.uniform(-0.8, 0.8), 0.12))
    for k in range(26):
        parts.append((rng.uniform(0.05, 1.1), clap(0.12), rng.uniform(-0.9, 0.9), rng.uniform(0.15, 0.35)))
    oneshot("sfx_cheer", place(d, parts), mix=0.2)


if __name__ == "__main__":
    sfx_all()
    music_prep()
    music_open()
    music_closing()
