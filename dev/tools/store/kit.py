"""Shared kit for the promo videos (from video 1): "1 needle. 5,000,000 straws." Upright 1080 x 1920, 30 fps, 20 s, with sound.
Scenes: pull back from the needle to the giant haystack; lifting hay with the combo climbing;
the XP bar filling into LEVEL UP! and x2 XP!; climbing the stairs; a magnifying glass finds the
needle; an end card with the icon and title."""
import math
import random
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, ".")
from art import (BLACK, BOLD, EDGE, cloud, farmer, font, glow, haystack, hills, lerp, needle,
                 sky, sparkle)

W, H, FPS, SECONDS = 1080, 1920, 30, 20
GOLD, WHITE, CREAM, INK = (255, 214, 72), (255, 255, 255), (246, 237, 218), (59, 42, 26)


def ease_out(t):
    return 1 - (1 - t) ** 3


def back_out(t):
    c1 = 1.70158
    c3 = c1 + 1
    return 1 + c3 * (t - 1) ** 3 + c1 * (t - 1) ** 2


def clamp(t):
    return max(0.0, min(1.0, t))


# ---------- words: rendered once per text, scaled per frame ----------
_text_cache = {}


def words(text, size, fill=GOLD, path=BLACK, rot=0):
    key = (text, size, fill, path, rot)
    if key not in _text_cache:
        f = font(path, size)
        probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
        while probe.textlength(text, font=f) > W * 0.82:
            size = int(size * 0.94)
            f = font(path, size)
        sw = max(4, int(size * 0.11))
        tw, th = int(probe.textlength(text, font=f)) + sw * 4, int(size * 1.4) + sw * 4
        layer = Image.new("RGBA", (tw, th))
        d = ImageDraw.Draw(layer)
        d.text((tw / 2 + size * 0.05, th / 2 + size * 0.08), text, font=f, fill=(0, 0, 0, 110), anchor="mm", stroke_width=sw, stroke_fill=(0, 0, 0, 110))
        d.text((tw / 2, th / 2), text, font=f, fill=fill, anchor="mm", stroke_width=sw, stroke_fill=EDGE)
        if rot:
            layer = layer.rotate(rot, resample=Image.BICUBIC, expand=True)
        _text_cache[key] = layer
    return _text_cache[key]


def paste_scaled(frame, layer, cx, cy, scale, alpha=1.0):
    if scale <= 0.01 or alpha <= 0.01:
        return
    lw, lh = max(1, int(layer.width * scale)), max(1, int(layer.height * scale))
    l = layer.resize((lw, lh), Image.BILINEAR)
    if alpha < 1:
        a = l.split()[3].point(lambda v: int(v * alpha))
        l.putalpha(a)
    frame.paste(l, (int(cx - lw / 2), int(cy - lh / 2)), l)


def pop_text(frame, text, size, cx, cy, t0, t, fill=GOLD, rot=0, hold=99, path=BLACK):
    """Words that spring in at t0 (Back ease), and fade after `hold` seconds."""
    if t < t0:
        return
    k = clamp((t - t0) / 0.35)
    scale = 0.3 + 0.7 * back_out(k)
    alpha = 1.0 - clamp((t - t0 - hold) / 0.3)
    paste_scaled(frame, words(text, size, fill, path, rot), cx, cy, scale, alpha)


def shadow_pill(frame, cx, cy, w, h, alpha=0.5):
    layer = Image.new("RGBA", (int(w), int(h)))
    mask = Image.new("L", layer.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), h / 2, fill=255)
    grad = np.zeros((int(h), int(w)), np.float32)
    xs = np.linspace(0, 1, int(w))
    grad[:] = np.minimum(np.minimum(xs / 0.25, 1), (1 - xs) / 0.25) * alpha * 255
    a = Image.fromarray(np.clip(grad, 0, 255).astype(np.uint8)) .point(lambda v: v)
    from PIL import ImageChops
    layer.paste((28, 18, 8), (0, 0) + layer.size, ImageChops.multiply(mask, a))
    frame.paste(layer, (int(cx - w / 2), int(cy - h / 2)), layer)


# ---------- the world, drawn once ----------
def build_scene():
    """A tall scene at 2x (2160 x 3840): sky, hills, the giant haystack, the needle, stairs."""
    SW, SH = W * 2, H * 2
    rnd = random.Random(4)
    im = sky(SW, SH, top=(60, 140, 232), bottom=(196, 230, 252))
    glow(im, SW * 0.82, SH * 0.07, 520, (255, 236, 170), 220)
    for cx, cy, s in [(SW * 0.15, SH * 0.1, 150), (SW * 0.8, SH * 0.2, 130), (SW * 0.25, SH * 0.36, 120)]:
        cloud(im, cx, cy, s, rnd)
    hills(im, SH * 0.72, rnd)
    haystack(im, SW * 0.5, SH * 0.9, SW * 1.05, SH * 0.68, rnd)
    # stairs zig-zagging up the left flank
    d = ImageDraw.Draw(im)
    wood, dark = (150, 100, 52), (100, 64, 30)
    x0, y0 = SW * 0.12, SH * 0.9
    for i in range(16):
        x = x0 + i * SW * 0.018
        y = y0 - i * SH * 0.026
        d.rectangle((x, y - SH * 0.008, x + SW * 0.09, y), fill=wood, outline=dark, width=4)
    d.line([(x0 - 10, y0), (x0 + 16 * SW * 0.018 - 10, y0 - 16 * SH * 0.026)], fill=dark, width=10)
    needle(im, SW * 0.58, SH * 0.36, 260, -0.75)
    return im


def needle_point():
    return W * 2 * 0.58, H * 2 * 0.36


def camera(scene, cx, cy, zoom):
    """The part of the 2x scene centred at (cx, cy) zoomed by `zoom` (1 = whole width)."""
    cw, ch = scene.width / zoom, scene.height / zoom
    cx = min(max(cx, cw / 2), scene.width - cw / 2)
    cy = min(max(cy, ch / 2), scene.height - ch / 2)
    box = (cx - cw / 2, cy - ch / 2, cx + cw / 2, cy + ch / 2)
    camera.box = box
    return scene.resize((W, H), Image.BILINEAR, box=box)


def on_screen(sx, sy):
    """Where a point of the 2x scene is in the last camera frame."""
    x0, y0, x1, y1 = camera.box
    return (sx - x0) / (x1 - x0) * W, (sy - y0) / (y1 - y0) * H


def stair(i):
    """The top middle of step i (0..15) in scene pixels, matching build_scene."""
    SW, SH = W * 2, H * 2
    return SW * 0.12 + i * SW * 0.018 + SW * 0.045, SH * 0.9 - i * SH * 0.026 - SH * 0.008


# ---------- the farmer, drawn once ----------
def build_farmer(wave_arm=False):
    layer = Image.new("RGBA", (900, 1300))
    farmer(layer, 450, 1290, 220, wave=wave_arm)
    return layer


# ---------- audio ----------
def synth(events, seconds, rate=44100):
    n = int(seconds * rate)
    out = np.zeros(n, np.float32)
    t = np.arange(n) / rate
    # a light, bouncy backing: plucked chords on the beat, 112 bpm, C - G - Am - F
    beat = 60 / 112
    chords = [(261.6, 329.6, 392.0), (196.0, 246.9, 293.7), (220.0, 261.6, 329.6), (174.6, 220.0, 261.6)]
    i = 0
    while i * beat < seconds:
        start = int(i * beat * rate)
        ln = int(beat * 0.9 * rate)
        seg = np.arange(min(ln, n - start)) / rate
        env = np.exp(-seg * 5.5) * 0.08
        for f in chords[(i // 4) % 4]:
            out[start:start + len(seg)] += env * (np.sin(2 * np.pi * f * seg) + 0.3 * np.sin(4 * np.pi * f * seg))
        if i % 2 == 0:  # a soft kick
            kick = np.sin(2 * np.pi * (90 - 40 * seg[: int(0.12 * rate)]) * seg[: int(0.12 * rate)]) * np.exp(-seg[: int(0.12 * rate)] * 30) * 0.25
            out[start:start + len(kick)] += kick
        i += 1
    for at, kind in events:
        start = int(at * rate)
        if start >= n:
            continue
        if kind == "pop":
            ln = int(0.09 * rate)
            seg = np.arange(min(ln, n - start)) / rate
            out[start:start + len(seg)] += np.sin(2 * np.pi * (700 + 900 * seg / 0.09) * seg) * np.exp(-seg * 40) * 0.22
        elif kind == "chime":
            ln = int(0.9 * rate)
            seg = np.arange(min(ln, n - start)) / rate
            for k, f in enumerate((784, 988, 1175, 1568)):
                s0 = int(k * 0.07 * rate)
                if s0 < len(seg):
                    s = seg[: len(seg) - s0]
                    out[start + s0:start + s0 + len(s)] += np.sin(2 * np.pi * f * s) * np.exp(-s * 5) * 0.12
        elif kind == "whoosh":
            ln = int(0.5 * rate)
            seg = np.arange(min(ln, n - start)) / rate
            noise = np.random.RandomState(1).randn(len(seg)).astype(np.float32)
            noise = np.convolve(noise, np.ones(30) / 30, mode="same")
            out[start:start + len(seg)] += noise * np.sin(np.pi * seg / 0.5) * 0.5
        elif kind == "sparkle":
            ln = int(0.6 * rate)
            seg = np.arange(min(ln, n - start)) / rate
            out[start:start + len(seg)] += np.sin(2 * np.pi * 2093 * seg) * np.exp(-seg * 7) * 0.1 * (1 + np.sin(2 * np.pi * 18 * seg)) / 2
    out = np.clip(out, -1, 1)
    return (out * 32000).astype(np.int16)


