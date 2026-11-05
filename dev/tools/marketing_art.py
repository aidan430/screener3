"""Draws the game's icon (512x512) and thumbnail (1920x1080): an autumn sunset farm, a big
golden haystack wearing the game's hay texture, a glinting needle, and the title."""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

ROOT = "/home/user/screener3"
HAY = Image.open(f"{ROOT}/assets/hay/garden-hay-golden.jpg").convert("RGB")
FONT = "/usr/share/fonts/opentype/inter/" + (sys.argv[1] if len(sys.argv) > 1 else "Inter-Black.otf")

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def scene(w, h, stack_cx, stack_base, stack_r, stack_h, seed=3):
    rnd = random.Random(seed)
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    # sunset sky: deep blue at the top to warm orange near the horizon
    horizon = int(h * 0.62)
    for y in range(horizon + 1):
        t = y / horizon
        c = lerp((58, 92, 168), (250, 170, 96), t ** 1.4) if t < 0.85 else lerp((250, 170, 96), (255, 210, 140), (t - 0.85) / 0.15)
        d.line([(0, y), (w, y)], fill=c)
    # the sun, soft
    sun = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(sun)
    sx, sy, sr = int(w * 0.18), int(horizon * 0.82), int(h * 0.11)
    sd.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=255)
    glow = sun.filter(ImageFilter.GaussianBlur(h * 0.06))
    img = Image.composite(Image.new("RGB", (w, h), (255, 236, 180)), img, ImageChops.lighter(glow.point(lambda v: v * 0.8), sun))
    d = ImageDraw.Draw(img)
    # far hills and near field
    for layer, (col, amp, base) in enumerate([((150, 120, 80), 0.05, 0.60), ((118, 128, 62), 0.035, 0.66), ((96, 116, 52), 0.02, 0.72)]):
        pts = [(0, h)]
        phase = rnd.random() * 6
        for x in range(0, w + 8, 8):
            y = h * base - h * amp * (math.sin(x / w * 5 + phase) * 0.6 + math.sin(x / w * 11 + phase * 2) * 0.4)
            pts.append((x, y))
        pts.append((w, h))
        d.polygon(pts, fill=col)
    # little autumn trees on the far hills
    for _ in range(int(w / 70)):
        tx = rnd.uniform(0, w)
        if abs(tx - stack_cx) < stack_r * 1.3:
            continue
        ty = h * 0.62 + rnd.uniform(-h * 0.03, h * 0.04)
        tr = rnd.uniform(h * 0.018, h * 0.04)
        d.rectangle([tx - tr * 0.12, ty, tx + tr * 0.12, ty + tr * 1.2], fill=(90, 60, 40))
        d.ellipse([tx - tr, ty - tr * 1.4, tx + tr, ty + tr * 0.4], fill=rnd.choice([(214, 120, 40), (196, 72, 44), (232, 176, 54)]))
    # the haystack: a beehive shape filled with the hay texture, shaded round
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    pts = []
    for i in range(0, 181):
        a = math.radians(i)
        x = stack_cx + math.cos(a) * stack_r * (1 - 0.06 * math.sin(a * 7) * rnd.random())
        y = stack_base - math.sin(a) ** 0.75 * stack_h
        pts.append((x, y))
    md.polygon(pts + [(stack_cx - stack_r, stack_base + h * 0.02), (stack_cx + stack_r, stack_base + h * 0.02)], fill=255)
    tex = HAY.resize((int(stack_r * 1.2), int(stack_r * 1.2)))
    tiled = Image.new("RGB", (w, h))
    for ty in range(0, h, tex.size[1]):
        for tx in range(0, w, tex.size[0]):
            tiled.paste(tex, (tx, ty))
    shade = Image.new("L", (w, h), 0)
    sdraw = ImageDraw.Draw(shade)
    for k in range(40):  # light from the sun side (left), darker to the right
        t = k / 40
        sdraw.ellipse([stack_cx - stack_r * (1 - t) - stack_r * 0.35 * t, stack_base - stack_h * (1 - t * 0.6), stack_cx + stack_r * (1 - t) - stack_r * 0.35 * t, stack_base + stack_h * 0.4], fill=int(255 * (0.55 + 0.45 * t)))
    shade = shade.filter(ImageFilter.GaussianBlur(stack_r * 0.15))
    lit = ImageChops.multiply(tiled, Image.merge("RGB", (shade, shade, shade)))
    # a shadow on the ground, then the stack
    sh = Image.new("L", (w, h), 0)
    ImageDraw.Draw(sh).ellipse([stack_cx - stack_r * 1.15, stack_base - h * 0.02, stack_cx + stack_r * 1.35, stack_base + h * 0.05], fill=120)
    sh = sh.filter(ImageFilter.GaussianBlur(h * 0.015))
    img = Image.composite(Image.new("RGB", (w, h), (50, 60, 30)), img, sh)
    img = Image.composite(lit, img, mask)
    d = ImageDraw.Draw(img)
    # loose straws sticking out of the outline
    for _ in range(int(stack_r * 1.2)):
        a = math.radians(rnd.uniform(4, 176))
        x = stack_cx + math.cos(a) * stack_r * 0.98
        y = stack_base - math.sin(a) ** 0.75 * stack_h * 0.99
        ang = a + rnd.uniform(-0.6, 0.6)
        ln = rnd.uniform(h * 0.012, h * 0.035)
        d.line([(x, y), (x + math.cos(ang) * ln, y - math.sin(ang) * ln * 0.8)], fill=rnd.choice([(240, 205, 110), (214, 170, 80), (250, 226, 150)]), width=max(1, int(h / 500)))
    return img

def needle(img, x, y, length, angle):
    """A silver needle half in the hay, with a soft star glint at its eye."""
    d = ImageDraw.Draw(img)
    dx, dy = math.cos(angle) * length, -math.sin(angle) * length
    wdt = max(2, int(length / 28))
    d.line([(x, y), (x + dx, y + dy)], fill=(70, 74, 86), width=wdt + 2)
    d.line([(x, y), (x + dx, y + dy)], fill=(225, 230, 240), width=wdt)
    ex, ey = x + dx * 0.92, y + dy * 0.92
    d.ellipse([ex - wdt * 0.6, ey - wdt * 1.2, ex + wdt * 0.6, ey + wdt * 1.2], outline=(70, 74, 86), width=max(1, wdt // 2))
    gl = Image.new("L", img.size, 0)
    g = ImageDraw.Draw(gl)
    s = length * 0.55
    g.polygon([(ex - s, ey), (ex, ey - s * 0.08), (ex + s, ey), (ex, ey + s * 0.08)], fill=255)
    g.polygon([(ex, ey - s * 0.7), (ex + s * 0.07, ey), (ex, ey + s * 0.7), (ex - s * 0.07, ey)], fill=255)
    g.ellipse([ex - s * 0.12, ey - s * 0.12, ex + s * 0.12, ey + s * 0.12], fill=255)
    gl = gl.filter(ImageFilter.GaussianBlur(length / 60))
    return Image.composite(Image.new("RGB", img.size, (255, 252, 220)), img, gl)

def title(img, lines, cx, top, size, gap):
    d = ImageDraw.Draw(img)
    y = top
    for text, scale in lines:
        f = ImageFont.truetype(FONT, int(size * scale))
        tw = d.textlength(text, font=f)
        x = cx - tw / 2
        d.text((x + size * 0.06, y + size * 0.08), text, font=f, fill=(60, 30, 14))  # drop shadow
        d.text((x, y), text, font=f, fill=(255, 226, 120), stroke_width=max(2, int(size * scale * 0.09)), stroke_fill=(92, 50, 22))
        y += size * scale * gap
    return img

# thumbnail 1920x1080
W, H = 1920, 1080
t = scene(W, H, stack_cx=W * 0.62, stack_base=H * 0.93, stack_r=W * 0.24, stack_h=H * 0.62)
t = needle(t, W * 0.70, H * 0.60, H * 0.22, math.radians(40))
t = title(t, [("NEEDLE IN THE", 0.55), ("HAYSTACK", 1.0)], W * 0.27, H * 0.08, H * 0.16, 1.1)
f = ImageFont.truetype(FONT, int(H * 0.045))
d = ImageDraw.Draw(t)
for i, line in enumerate(["5,000,000 straws.", "One needle.", "Build your farm and find it."]):
    d.text((W * 0.27 - d.textlength(line, font=f) / 2, H * 0.45 + i * H * 0.065), line, font=f, fill=(255, 248, 230), stroke_width=4, stroke_fill=(70, 40, 20))
t.save(f"{ROOT}/assets/marketing/thumbnail.png")

# icon 512x512: the haystack and the needle, a short title
S = 512
i = scene(S, S, stack_cx=S * 0.5, stack_base=S * 0.97, stack_r=S * 0.44, stack_h=S * 0.66, seed=5)
i = needle(i, S * 0.56, S * 0.62, S * 0.3, math.radians(50))
i = title(i, [("NEEDLE IN THE", 0.5), ("HAYSTACK", 0.82)], S * 0.5, S * 0.04, S * 0.17, 1.1)
i.save(f"{ROOT}/assets/marketing/icon.png")
print("ok")
