"""Promo video 1: "1 needle. 5,000,000 straws." Upright 1080 x 1920, 30 fps, 20 s, with sound.
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
ICON = sys.argv[1]
OUT = sys.argv[2]


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


# ---------- the video ----------
def main():
    scene = build_scene()
    farm = build_farmer()
    farm_wave = build_farmer(True)
    icon = Image.open(ICON).convert("RGB").resize((560, 560), Image.LANCZOS)
    icon_mask = Image.new("L", icon.size)
    ImageDraw.Draw(icon_mask).rounded_rectangle((0, 0, 559, 559), 100, fill=255)
    rnd = random.Random(9)
    nx, ny = needle_point()
    events = [(0.7, "pop"), (2.6, "whoosh")]
    lifts = [3.0 + i * 0.32 for i in range(10)]
    events += [(x, "pop") for x in lifts]
    events += [(7.2, "chime"), (8.4, "pop"), (9.4, "chime"), (10.6, "whoosh"), (14.4, "whoosh"), (15.4, "sparkle"), (17.5, "chime")]
    proc = subprocess.Popen(["ffmpeg", "-y", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                             "-i", "audio.wav", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "medium",
                             "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", OUT], stdin=subprocess.PIPE)
    pcm = synth(events, SECONDS)
    with wave.open("audio.wav", "wb") as wv:
        wv.setnchannels(1)
        wv.setsampwidth(2)
        wv.setframerate(44100)
        wv.writeframes(pcm.tobytes())
    # (the audio file must exist before ffmpeg reads it: restart ffmpeg now that it does)
    proc.stdin.close()
    proc.wait()
    proc = subprocess.Popen(["ffmpeg", "-y", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                             "-i", "audio.wav", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "medium",
                             "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", OUT], stdin=subprocess.PIPE)
    hay_bits = [(rnd.uniform(-1, 1), rnd.uniform(0.6, 1.4), rnd.uniform(0, math.tau), rnd.uniform(20, 46)) for _ in range(40)]
    for fi in range(FPS * SECONDS):
        t = fi / FPS
        if t < 2.6:  # 1. pull back from the needle to the whole stack
            k = ease_out(clamp(t / 2.4))
            zoom = 5.0 + (1.0 - 5.0) * k
            frame = camera(scene, nx + (W - nx) * k, ny + (H - ny) * k, zoom)
            sp = Image.new("RGB", frame.size)
            if k < 0.6:
                glow(frame, W / 2, H / 2 - 40, 220 * (1 - k), (255, 250, 220), 160)
            pop_text(frame, "THERE'S 1 NEEDLE", 120, W / 2, H * 0.13, 0.7, t, fill=WHITE, rot=3)
            pop_text(frame, "IN HERE!", 170, W / 2, H * 0.22, 0.85, t, rot=3)
        elif t < 6.6:  # 2. lifting hay, the combo climbing
            lt = t - 2.6
            frame = camera(scene, W * 1.0, H * 1.45, 1.6)
            bob = math.sin(lt * 18) * 8
            frame.paste(farm, (int(W * 0.28 - farm.width / 2), int(H - farm.height + 60 + bob)), farm)
            d = ImageDraw.Draw(frame)
            for i, lift in enumerate(lifts):
                age = t - lift
                if 0 <= age < 0.8:  # a burst of straw and a "+6" floating up
                    for bx, by, ba, bl in hay_bits[i * 4:i * 4 + 4]:
                        px = W * 0.62 + bx * 160 + math.cos(ba) * age * 300
                        py = H * 0.48 - age * 260 * by + age * age * 400
                        d.line([(px, py), (px + math.cos(ba) * bl, py + math.sin(ba) * bl)], fill=lerp((255, 236, 150), (210, 150, 40), (i % 3) / 3), width=7)
                    paste_scaled(frame, words("+6", 80, fill=WHITE, path=BOLD), W * 0.63 + (i % 3 - 1) * 40, H * 0.44 - age * 220, 1, 1 - age / 0.8)
            n = sum(1 for x in lifts if x <= t)
            if n >= 3:
                label = f"x{n * 2}" + (" GREAT!" if n * 2 >= 20 else "")
                shadow_pill(frame, W * 0.5, H * 0.3, 520, 150)
                last = max(x for x in lifts if x <= t)
                paste_scaled(frame, words(label, 110, fill=lerp(GOLD, (255, 130, 60), min(n * 2 / 30, 1)), path=BLACK), W * 0.5, H * 0.3, 1 + 0.25 * (1 - clamp((t - last) / 0.2)))
            pop_text(frame, "5,000,000 STRAWS", 110, W / 2, H * 0.12, 2.75, t, fill=WHITE, rot=-2)
        elif t < 10.6:  # 3. the XP bar fills: LEVEL UP!, x2 XP!
            lt = t - 6.6
            frame = camera(scene, W * 1.0, H * 1.2, 1.25)
            frame.paste(farm_wave, (int(W * 0.25 - farm_wave.width / 2), int(H - farm_wave.height + 60)), farm_wave)
            d = ImageDraw.Draw(frame)
            bx0, by0, bw, bh = W * 0.1, H * 0.58, W * 0.8, 96
            share = clamp(lt / 0.6) if lt < 0.6 else (1.0 if lt < 1.2 else clamp((lt - 1.2) / 1.6) * 0.7)
            level = 41 if lt < 0.6 else 42
            glowing = 0.6 <= lt < 1.2 or 2.8 <= lt < 3.3
            d.rounded_rectangle((bx0 - 8, by0 - 8, bx0 + bw + 8, by0 + bh + 8), 56, fill=CREAM)
            d.rounded_rectangle((bx0, by0, bx0 + bw, by0 + bh), 48, fill=(59, 42, 26))
            if share > 0:
                d.rounded_rectangle((bx0, by0, bx0 + max(bh, bw * share), by0 + bh), 48, fill=(255, 226, 140) if glowing else (206, 152, 46))
            tc = INK if glowing else WHITE
            d.text((bx0 + 40, by0 + bh / 2), f"Level {level}", font=font(BLACK, 56), fill=tc, anchor="lm")
            d.text((bx0 + bw - 40, by0 + bh / 2), "LEVEL UP!" if glowing else f"{int(share * 94)} / 94 XP", font=font(BOLD, 44), fill=tc, anchor="rm")
            if 0.6 <= lt:
                shadow_pill(frame, W / 2, H * 0.3, 1000, 260)
                pop_text(frame, "LEVEL UP!", 190, W / 2, H * 0.28, 7.2, t, rot=-3)
                pop_text(frame, "+1 STRENGTH", 80, W / 2, H * 0.37, 7.35, t, fill=WHITE)
            if 1.8 <= lt:
                shadow_pill(frame, W * 0.68, H * 0.47, 520, 150)
                pop_text(frame, "x2 XP!", 130, W * 0.68, H * 0.47, 8.4, t, rot=8)
            if lt >= 0.6 and lt < 1.6:  # confetti
                cr = random.Random(int(t * 10))
                for i in range(60):
                    x = (i * 97) % W
                    y = ((lt - 0.6) * 1400 + (i * 53) % 700) - 200
                    d.rounded_rectangle((x, y, x + 16, y + 28), 4, fill=[(255, 206, 70), (240, 120, 80), (120, 200, 120), (110, 170, 240)][i % 4])
        elif t < 14.6:  # 4. climb the stairs, up to the top
            lt = t - 10.6
            k = ease_out(clamp(lt / 3.6))
            step = 15 * k
            sx0, sy0 = stair(int(step))
            sx1, sy1 = stair(min(15, int(step) + 1))
            f = step - int(step)
            sx, sy = sx0 + (sx1 - sx0) * f, sy0 + (sy1 - sy0) * f
            frame = camera(scene, sx + W * 0.35, sy - H * 0.15, 1.6)
            fx, fy = on_screen(sx, sy)  # the farmer stands on the step, bobbing as he climbs
            small = farm.resize((int(farm.width / 2.6), int(farm.height / 2.6)), Image.BILINEAR)
            frame.paste(small, (int(fx - small.width / 2), int(fy - small.height + 4 - abs(math.sin(lt * 9)) * 14)), small)
            pop_text(frame, "CLIMB UP...", 130, W / 2, H * 0.12, 10.8, t, fill=WHITE, rot=-3)
            pop_text(frame, "...AND DIG IN!", 140, W / 2, H * 0.22, 12.2, t, rot=-3)
        elif t < 17.4:  # 5. the magnifying glass finds it
            lt = t - 14.6
            frame = camera(scene, nx, ny, 2.2)
            mr = 300
            mx = W * 0.5 + (1 - ease_out(clamp(lt / 0.7))) * W * 0.6
            my = H * 0.5
            lens_src = camera(scene, nx, ny, 5.5).crop((int(W / 2 - mr), int(H / 2 - mr), int(W / 2 + mr), int(H / 2 + mr)))
            d = ImageDraw.Draw(frame)
            d.line([(mx + mr * 0.7, my + mr * 0.7), (mx + mr * 1.5, my + mr * 1.5)], fill=(110, 66, 30), width=90)
            d.ellipse((mx - mr - 34, my - mr - 34, mx + mr + 34, my + mr + 34), fill=(60, 64, 72))
            d.ellipse((mx - mr - 22, my - mr - 22, mx + mr + 22, my + mr + 22), fill=(170, 176, 186))
            circle = Image.new("L", lens_src.size)
            ImageDraw.Draw(circle).ellipse((0, 0, mr * 2, mr * 2), fill=255)
            frame.paste(lens_src, (int(mx - mr), int(my - mr)), circle)
            if lt > 0.8:
                sparkle(frame, mx + 40, my - 60, 120 + 30 * math.sin(lt * 9))
            pop_text(frame, "FOUND IT!", 170, W / 2, H * 0.16, 15.5, t, rot=-3)
        else:  # 6. end card
            lt = t - 17.4
            frame = sky(W, H, top=(60, 140, 232), bottom=(196, 230, 252))
            rays = Image.new("RGBA", frame.size)
            rd = ImageDraw.Draw(rays)
            for i in range(18):
                a0 = i / 18 * math.tau + lt * 0.3
                rd.polygon([(W / 2, H * 0.42), (W / 2 + math.cos(a0) * 2200, H * 0.42 + math.sin(a0) * 2200), (W / 2 + math.cos(a0 + 0.13) * 2200, H * 0.42 + math.sin(a0 + 0.13) * 2200)], fill=(255, 248, 210, 70))
            frame.paste(rays, (0, 0), rays)
            s = 0.3 + 0.7 * back_out(clamp(lt / 0.45))
            ic = icon.resize((int(560 * s), int(560 * s)), Image.BILINEAR)
            m = icon_mask.resize(ic.size, Image.BILINEAR)
            frame.paste(ic, (int(W / 2 - ic.width / 2), int(H * 0.42 - ic.height / 2)), m)
            pop_text(frame, "NEEDLE IN THE", 110, W / 2, H * 0.12, 17.6, t, fill=WHITE, rot=3)
            pop_text(frame, "HAYSTACK", 170, W / 2, H * 0.21, 17.75, t, rot=3)
            pop_text(frame, "Could YOU find it?", 90, W / 2, H * 0.6, 18.1, t, fill=WHITE, path=BOLD)
            pop_text(frame, "PLAY FREE ON ROBLOX", 84, W / 2, H * 0.68, 18.4, t, path=BLACK)
        proc.stdin.write(frame.convert("RGB").tobytes())
    proc.stdin.close()
    proc.wait()


if __name__ == "__main__":
    main()
