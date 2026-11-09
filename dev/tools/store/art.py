"""Promo art kit for Needle in the Haystack: sky, hills, barn, a giant haystack, the needle,
a blocky farmer and big outlined titles. Everything is drawn at 2x and scaled down."""
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

BLACK = "/usr/share/fonts/opentype/inter/InterDisplay-Black.otf"
BOLD = "/usr/share/fonts/opentype/inter/InterDisplay-ExtraBold.otf"
EDGE = (58, 34, 12)


def font(path, size):
    return ImageFont.truetype(path, int(size))


def lerp(a, b, t):
    return tuple(int(x + (y - x) * t) for x, y in zip(a, b))


def sky(w, h, top=(70, 150, 235), bottom=(200, 232, 252)):
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, bottom, y / h))
    return im


def glow(im, cx, cy, r, colour, strength=160):
    """A soft light added on top (screen blend), so it brightens instead of greying."""
    layer = Image.new("RGB", im.size, (0, 0, 0))
    k = strength / 255
    ImageDraw.Draw(layer).ellipse((cx - r, cy - r, cx + r, cy + r), fill=tuple(int(c * k) for c in colour))
    layer = layer.filter(ImageFilter.GaussianBlur(r * 0.5))
    im.paste(ImageChops.screen(im, layer))


def cloud(im, cx, cy, s, rnd):
    layer = Image.new("RGBA", im.size)
    d = ImageDraw.Draw(layer)
    puffs = [(-1.2, 0.2, 0.7), (-0.5, -0.25, 0.9), (0.35, -0.35, 1.0), (1.1, 0.05, 0.75), (0, 0.3, 0.8)]
    for dx, dy, r in puffs:
        d.ellipse((cx + (dx - r) * s, cy + (dy - r * 0.8) * s + 0.12 * s, cx + (dx + r) * s, cy + (dy + r * 0.8) * s + 0.12 * s), fill=(176, 206, 236, 255))
    for dx, dy, r in puffs:
        d.ellipse((cx + (dx - r) * s, cy + (dy - r * 0.8) * s, cx + (dx + r) * s, cy + (dy + r * 0.8) * s), fill=(255, 255, 255, 255))
    layer = layer.filter(ImageFilter.GaussianBlur(s * 0.02))
    im.paste(layer, (0, 0), layer)


def hills(im, horizon, rnd):
    w, h = im.size
    d = ImageDraw.Draw(im)
    for i, (col, dy, amp) in enumerate([((120, 190, 96), -0.06, 0.05), ((96, 170, 76), 0.0, 0.035)]):
        pts = [(0, h)]
        phase = rnd.random() * 6
        for x in range(0, w + 20, 20):
            y = horizon + dy * h - amp * h * (0.6 * math.sin(x / w * 5 + phase) + 0.4 * math.sin(x / w * 11 + phase * 2))
            pts.append((x, y))
        pts.append((w, h))
        d.polygon(pts, fill=col)
    # ground with soft grass flecks
    d.rectangle((0, horizon + 0.05 * h, w, h), fill=(88, 160, 70))
    for _ in range(int(w * h / 900)):
        x, y = rnd.random() * w, horizon + 0.05 * h + rnd.random() * (h - horizon)
        L = 6 + 14 * (y - horizon) / h * 3
        d.line([(x, y), (x + rnd.uniform(-3, 3), y - L)], fill=lerp((70, 140, 56), (130, 200, 96), rnd.random()), width=2)


def barn(im, x, y, s):
    d = ImageDraw.Draw(im)
    red, dark, white = (196, 52, 44), (140, 34, 30), (250, 244, 232)
    d.rectangle((x, y - 0.9 * s, x + 1.4 * s, y), fill=red)
    d.polygon([(x - 0.1 * s, y - 0.9 * s), (x + 0.7 * s, y - 1.5 * s), (x + 1.5 * s, y - 0.9 * s)], fill=dark)
    d.rectangle((x + 0.45 * s, y - 0.55 * s, x + 0.95 * s, y), fill=dark, outline=white, width=max(2, int(s * 0.04)))
    d.line([(x + 0.45 * s, y - 0.55 * s), (x + 0.95 * s, y)], fill=white, width=max(2, int(s * 0.04)))
    d.line([(x + 0.95 * s, y - 0.55 * s), (x + 0.45 * s, y)], fill=white, width=max(2, int(s * 0.04)))
    d.rectangle((x + 0.55 * s, y - 0.8 * s, x + 0.85 * s, y - 0.65 * s), fill=white)


def haystack(im, cx, base, width, height, rnd):
    """A big round dome of golden hay, lit from the upper left like a 3D ball, with fine straw
    texture, loose wisps round the edge and a soft shadow on the ground."""
    import numpy as np
    w, h = im.size
    a, b = width / 2, height
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    u = (xs - cx) / a
    v = (base - ys) / b  # 0 at the base, 1 at the top
    # a dome: |u|^2.1 + v^2 <= 1, plus a little bulge at the foot so it sits like a mound
    inside = (np.abs(u) ** 2.1 + np.clip(v, 0, None) ** 2) <= 1.0
    inside &= v >= -0.012
    # a normal on an ellipsoid, lit from the upper left and a little in front
    nz = np.sqrt(np.clip(1 - u * u - np.clip(v, 0, 1) ** 2, 0, 1))
    n = np.stack([u, np.clip(v, 0, 1) * 0.9, nz + 0.35], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True) + 1e-6
    light = np.array([-0.55, 0.55, 0.65], np.float32)
    light /= np.linalg.norm(light)
    lam = np.clip((n * light).sum(-1), 0, 1)
    shade = 0.38 + 0.75 * lam ** 1.1
    shade *= 1 - 0.28 * np.clip(0.18 - v, 0, 0.18) / 0.18  # darker right at the foot
    gold = np.array([236, 178, 58], np.float32)
    rgb = np.clip(gold[None, None, :] * shade[..., None] * np.array([1.0, 0.98, 0.9]), 0, 255)
    # a warm highlight on the lit shoulder
    hi = np.clip(lam - 0.82, 0, 1) / 0.18
    rgb = rgb + (np.array([255, 244, 200]) - rgb) * (hi[..., None] * 0.55)
    hay = Image.fromarray(rgb.astype(np.uint8), "RGB")
    mask = Image.fromarray((inside * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.5))
    # ground shadow
    sh = Image.new("RGBA", im.size)
    ImageDraw.Draw(sh).ellipse((cx - a * 1.08, base - b * 0.05, cx + a * 1.18, base + b * 0.07), fill=(24, 60, 16, 130))
    sh = sh.filter(ImageFilter.GaussianBlur(b * 0.03))
    im.paste(sh, (0, 0), sh)
    # straw texture: short strokes tinted by the local shade, following the dome
    tex = Image.new("RGBA", im.size)
    td = ImageDraw.Draw(tex)
    sw = max(2, int(width / 900))
    for k_band in range(9):  # soft curved bands, like layers of a hand-built stack
        vv = 0.08 + k_band * 0.1
        pts_band = []
        for i in range(0, 101):
            uu = (i / 100 * 2 - 1) * max(0.0, 1 - vv ** 2) ** (1 / 2.1)
            pts_band.append((cx + uu * a, base - vv * b + math.sin(i * 0.4 + k_band) * b * 0.006))
        td.line(pts_band, fill=(120, 76, 14, 46), width=max(3, int(width / 300)))
    for _ in range(int(width * height / 150)):
        x = cx + (rnd.random() * 2 - 1) * a
        uu = (x - cx) / a
        vmax = max(0.0, 1 - abs(uu) ** 2.1) ** 0.5
        vv = rnd.random() * vmax
        y = base - vv * b
        xi, yi = int(min(max(x, 0), w - 1)), int(min(max(y, 0), h - 1))
        base_col = rgb[yi, xi]
        k = rnd.uniform(-0.5, 0.38)
        col = tuple(int(min(255, max(0, c * (1 + k)))) for c in base_col)
        ang = math.atan2(-uu * 1.4, 1.0) + rnd.uniform(-0.7, 0.7) + math.pi / 2 * (1 if rnd.random() < 0.5 else 0) * 0.3
        L = rnd.uniform(14, 40) * (width / 1500)
        td.line([(x, y), (x + math.cos(ang) * L, y + math.sin(ang) * L)], fill=col + (235,), width=sw)
    hay_rgba = hay.convert("RGBA")
    hay_rgba = Image.alpha_composite(hay_rgba, tex)
    im.paste(hay_rgba.convert("RGB"), (0, 0), mask)
    # loose wisps round the outline, pointing outwards
    d = ImageDraw.Draw(im)
    for i in range(0, 400):
        t = i / 399 * 2 - 1
        vmax = max(0.0, 1 - abs(t) ** 2.1) ** 0.5
        x, y = cx + t * a, base - vmax * b
        out = math.atan2(-vmax * 1.0, t * 0.8)
        for _ in range(2):
            ang = out + rnd.uniform(-0.7, 0.7)
            L = rnd.uniform(12, 40) * (width / 1500)
            col = lerp((255, 228, 130), (196, 138, 40), rnd.random())
            d.line([(x, y), (x + math.cos(ang) * L, y + math.sin(ang) * L)], fill=col, width=sw)
    return a, b


def sparkle(im, cx, cy, r, colour=(255, 255, 255)):
    """A four-pointed star with a soft glow."""
    glow(im, cx, cy, r * 1.4, (255, 250, 220), 170)
    layer = Image.new("RGBA", im.size)
    d = ImageDraw.Draw(layer)
    for ax, ay, L, wdt in [(1, 0, r, r * 0.16), (0, 1, r, r * 0.16), (0.7, 0.7, r * 0.5, r * 0.1), (0.7, -0.7, r * 0.5, r * 0.1)]:
        px, py = -ay, ax
        d.polygon([(cx + ax * L, cy + ay * L), (cx + px * wdt, cy + py * wdt), (cx - ax * L, cy - ay * L), (cx - px * wdt, cy - py * wdt)], fill=colour + (255,))
    im.paste(layer, (0, 0), layer)


def needle(im, x, y, length, angle, glint=True):
    """A silver sewing needle (eye at the top end) with a trailing red thread."""
    d = ImageDraw.Draw(im)
    ax, ay = math.cos(angle), math.sin(angle)
    tip = (x + ax * length / 2, y + ay * length / 2)
    eye = (x - ax * length / 2, y - ay * length / 2)
    wdt = max(4, length * 0.045)
    px, py = -ay, ax
    d.polygon([tip, (eye[0] + px * wdt, eye[1] + py * wdt), (eye[0] - px * wdt, eye[1] - py * wdt)], fill=(200, 208, 220))
    d.line([(tip[0] - px * wdt * 0.2, tip[1] - py * wdt * 0.2), (eye[0] + px * wdt * 0.35, eye[1] + py * wdt * 0.35)], fill=(250, 252, 255), width=max(2, int(wdt * 0.35)))
    d.ellipse((eye[0] - wdt * 0.7, eye[1] - wdt * 0.7, eye[0] + wdt * 0.7, eye[1] + wdt * 0.7), outline=(120, 128, 140), width=max(2, int(wdt * 0.3)))
    # red thread looping out of the eye
    th = [eye]
    for i in range(1, 14):
        t = i / 13
        th.append((eye[0] - ax * length * 0.5 * t + math.sin(t * 5) * length * 0.12, eye[1] - ay * length * 0.5 * t + t * length * 0.18))
    d.line(th, fill=(200, 40, 40), width=max(3, int(wdt * 0.6)), joint="curve")
    if glint:
        sparkle(im, tip[0] - ax * length * 0.15, tip[1] - ay * length * 0.15, length * 0.42)


def farmer(im, x, ground, s, look_up=True, fork=True, hay_on_fork=True, wave=False):
    """A blocky farmer: straw hat, red shirt, blue overalls, holding a pitchfork with hay. s = head size."""
    d = ImageDraw.Draw(im)
    skin, shirt, denim, denim_d, boot = (250, 206, 160), (206, 58, 50), (60, 104, 180), (44, 78, 140), (92, 60, 36)
    leg_h, torso_h = s * 1.2, s * 1.25
    hip = ground - leg_h
    sh_y = hip - torso_h
    # legs and boots
    for dx in (-0.5, 0.02):
        d.rounded_rectangle((x + dx * s, hip, x + (dx + 0.48) * s, ground - s * 0.12), s * 0.06, fill=denim_d)
        d.rounded_rectangle((x + (dx - 0.02) * s, ground - s * 0.2, x + (dx + 0.52) * s, ground), s * 0.06, fill=boot)
    # torso: shirt, then overall bib and straps
    d.rounded_rectangle((x - 0.62 * s, sh_y, x + 0.62 * s, hip + s * 0.05), s * 0.1, fill=shirt)
    d.rounded_rectangle((x - 0.5 * s, sh_y + torso_h * 0.42, x + 0.5 * s, hip + s * 0.08), s * 0.06, fill=denim)
    for dx in (-0.36, 0.22):
        d.rectangle((x + dx * s, sh_y, x + (dx + 0.14) * s, sh_y + torso_h * 0.45), fill=denim)
        d.ellipse((x + (dx + 0.02) * s, sh_y + torso_h * 0.42 - s * 0.05, x + (dx + 0.12) * s, sh_y + torso_h * 0.42 + s * 0.05), fill=(240, 200, 80))
    d.rectangle((x - 0.18 * s, sh_y + torso_h * 0.55, x + 0.18 * s, sh_y + torso_h * 0.72), outline=denim_d, width=max(2, int(s * 0.03)))
    # arms: left arm hangs or waves, right arm holds the fork across the body
    if wave:
        d.rounded_rectangle((x - 1.0 * s, sh_y - 0.7 * s, x - 0.62 * s, sh_y + 0.3 * s), s * 0.1, fill=shirt)
        d.rounded_rectangle((x - 1.0 * s, sh_y - 0.95 * s, x - 0.62 * s, sh_y - 0.62 * s), s * 0.1, fill=skin)
    else:
        d.rounded_rectangle((x - 1.0 * s, sh_y + 0.05 * s, x - 0.62 * s, sh_y + 1.0 * s), s * 0.1, fill=shirt)
        d.rounded_rectangle((x - 1.0 * s, sh_y + 0.95 * s, x - 0.62 * s, sh_y + 1.25 * s), s * 0.1, fill=skin)
    d.rounded_rectangle((x + 0.62 * s, sh_y + 0.05 * s, x + 1.0 * s, sh_y + 1.0 * s), s * 0.1, fill=shirt)
    hand = (x + 0.81 * s, sh_y + 1.08 * s)
    if fork:
        # pitchfork: handle from low right to high left-up, tines at the top
        top = (hand[0] + 0.75 * s, hand[1] - 2.3 * s)
        bot = (hand[0] - 0.3 * s, hand[1] + 0.95 * s)
        d.line([bot, top], fill=(150, 100, 52), width=max(4, int(s * 0.1)))
        ang = math.atan2(top[1] - bot[1], top[0] - bot[0])
        ax, ay = math.cos(ang), math.sin(ang)
        px, py = -ay, ax
        cx_, cy_ = top
        d.line([(cx_ + px * 0.3 * s, cy_ + py * 0.3 * s), (cx_ - px * 0.3 * s, cy_ - py * 0.3 * s)], fill=(150, 154, 160), width=max(4, int(s * 0.07)))
        for k in (-0.28, -0.09, 0.09, 0.28):
            sx, sy = cx_ + px * k * s, cy_ + py * k * s
            d.line([(sx, sy), (sx + ax * 0.6 * s, sy + ay * 0.6 * s)], fill=(190, 194, 200), width=max(3, int(s * 0.055)))
        if hay_on_fork:
            hx, hy = cx_ + ax * 0.45 * s, cy_ + ay * 0.45 * s
            rnd = random.Random(7)
            d.ellipse((hx - 0.55 * s, hy - 0.42 * s, hx + 0.55 * s, hy + 0.32 * s), fill=(236, 186, 70))
            for _ in range(70):
                a = rnd.uniform(0, math.tau)
                rr = rnd.uniform(0.1, 0.55) * s
                sx, sy = hx + math.cos(a) * rr, hy + math.sin(a) * rr * 0.7
                d.line([(sx, sy), (sx + rnd.uniform(-0.25, 0.25) * s, sy + rnd.uniform(-0.2, 0.15) * s)], fill=lerp((255, 232, 140), (170, 110, 26), rnd.random()), width=max(2, int(s * 0.03)))
    d.rounded_rectangle((hand[0] - 0.19 * s, hand[1] - 0.15 * s, hand[0] + 0.19 * s, hand[1] + 0.17 * s), s * 0.08, fill=skin)
    # head
    hx0, hy0 = x - 0.5 * s, sh_y - 1.0 * s
    d.rounded_rectangle((hx0, hy0, hx0 + s, hy0 + s), s * 0.2, fill=skin)
    ey = hy0 + (0.4 if look_up else 0.48) * s
    for ex in (0.3, 0.7):
        d.ellipse((hx0 + (ex - 0.07) * s, ey - 0.1 * s, hx0 + (ex + 0.07) * s, ey + 0.1 * s), fill=(40, 30, 24))
        d.ellipse((hx0 + (ex - 0.03) * s, ey - 0.08 * s, hx0 + (ex + 0.01) * s, ey - 0.03 * s), fill=(255, 255, 255))
    for ex in (0.3, 0.7):  # eyebrows up: amazed
        d.arc((hx0 + (ex - 0.11) * s, ey - 0.3 * s, hx0 + (ex + 0.11) * s, ey - 0.12 * s), 200, 340, fill=(90, 60, 30), width=max(2, int(s * 0.035)))
    d.ellipse((hx0 + 0.38 * s, hy0 + 0.62 * s, hx0 + 0.62 * s, hy0 + 0.86 * s), fill=(110, 40, 36))  # "O" mouth
    d.ellipse((hx0 + 0.44 * s, hy0 + 0.74 * s, hx0 + 0.56 * s, hy0 + 0.84 * s), fill=(230, 110, 110))
    for cxk in (0.16, 0.84):
        d.ellipse((hx0 + (cxk - 0.08) * s, hy0 + 0.58 * s, hx0 + (cxk + 0.08) * s, hy0 + 0.68 * s), fill=(250, 170, 150))
    # straw hat
    d.ellipse((hx0 - 0.45 * s, hy0 - 0.05 * s, hx0 + 1.45 * s, hy0 + 0.28 * s), fill=(222, 180, 84))
    d.rounded_rectangle((hx0 + 0.08 * s, hy0 - 0.5 * s, hx0 + 0.92 * s, hy0 + 0.12 * s), s * 0.2, fill=(236, 196, 100))
    d.rectangle((hx0 + 0.08 * s, hy0 - 0.08 * s, hx0 + 0.92 * s, hy0 + 0.06 * s), fill=(196, 52, 44))
    rnd = random.Random(3)
    for _ in range(40):
        sx = hx0 + rnd.uniform(-0.4, 1.4) * s
        sy = hy0 + rnd.uniform(0.0, 0.22) * s
        d.line([(sx, sy), (sx + rnd.uniform(-0.1, 0.1) * s, sy + rnd.uniform(-0.03, 0.03) * s)], fill=(196, 150, 60), width=max(1, int(s * 0.015)))


def title(im, text, cx, cy, size, fill=(255, 214, 72), edge=EDGE, rot=0, path=BLACK, shade=True, max_w=None):
    """Big chunky outlined words with a drop shadow, optionally tilted."""
    f = font(path, size)
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    while max_w and probe.textlength(text, font=f) > max_w:
        size *= 0.95
        f = font(path, size)
    sw = max(4, int(size * 0.11))
    tw = int(probe.textlength(text, font=f)) + sw * 4
    th = int(size * 1.4) + sw * 4
    layer = Image.new("RGBA", (tw, th))
    d = ImageDraw.Draw(layer)
    if shade:
        d.text((tw / 2 + size * 0.05, th / 2 + size * 0.08), text, font=f, fill=(0, 0, 0, 110), anchor="mm", stroke_width=sw, stroke_fill=(0, 0, 0, 110))
    d.text((tw / 2, th / 2), text, font=f, fill=fill, anchor="mm", stroke_width=sw, stroke_fill=edge)
    # a lighter top half on the letters (a simple gloss)
    gloss = Image.new("RGBA", layer.size)
    ImageDraw.Draw(gloss).text((tw / 2, th / 2), text, font=f, fill=(255, 255, 255, 70), anchor="mm")
    cut = Image.new("L", layer.size, 0)
    ImageDraw.Draw(cut).rectangle((0, 0, tw, th / 2 - size * 0.05), fill=255)
    gloss.putalpha(ImageChops.multiply(gloss.split()[3], cut))
    layer = Image.alpha_composite(layer, gloss)
    if rot:
        layer = layer.rotate(rot, resample=Image.BICUBIC, expand=True)
    im.paste(layer, (int(cx - layer.width / 2), int(cy - layer.height / 2)), layer)


def flying_hay(im, cx, cy, spread, n, rnd, scale=1.0):
    d = ImageDraw.Draw(im)
    for _ in range(n):
        x, y = cx + rnd.uniform(-spread, spread), cy + rnd.uniform(-spread * 0.6, spread * 0.6)
        a = rnd.uniform(0, math.tau)
        L = rnd.uniform(14, 34) * scale
        d.line([(x, y), (x + math.cos(a) * L, y + math.sin(a) * L)], fill=lerp((255, 236, 150), (210, 150, 40), rnd.random()), width=max(2, int(4 * scale)))
