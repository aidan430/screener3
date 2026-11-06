"""Draws a seamless 1024x1024 texture for each tool skin (assets/skins/<id>.png): upload them
in Studio and put their IDs in Config.Wheel (texture = "rbxassetid://...")."""
import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024
OUT = "/home/user/screener3/assets/skins"
rng = np.random.default_rng(7)

def tile_noise(scale, octaves=4, seed=0):
    """Truly seamless value noise in 0..1: each octave's grid is tiled 3x3, smoothly enlarged,
    and the middle third kept, so the left edge continues the right and the top the bottom."""
    r = np.random.default_rng(seed)
    out = np.zeros((S, S))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        n = scale * 2 ** o
        grid = np.tile(r.random((n, n)), (3, 3))
        big = Image.fromarray((grid * 255).astype(np.uint8)).resize((S * 3, S * 3), Image.BICUBIC)
        out += amp * np.asarray(big, dtype=float)[S:2 * S, S:2 * S] / 255
        total += amp
        amp *= 0.5
    out /= total
    return (out - out.min()) / (out.max() - out.min())

def colourise(t, stops):
    t = np.clip(t, 0, 1)
    pos = np.array([s[0] for s in stops])
    out = np.zeros((S, S, 3))
    for c in range(3):
        out[..., c] = np.interp(t, pos, [s[1][c] for s in stops])
    return Image.fromarray(out.clip(0, 255).astype(np.uint8))

def save(img, name):
    img.convert("RGB").save(f"{OUT}/{name}.png")

# Rose Gold: brushed metal (fine horizontal streaks) with soft swirling filigree
streak = np.tile(rng.random((S, 1)), (1, S))
streak = np.asarray(Image.fromarray((streak * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), float) / 255
base = 0.6 * tile_noise(3, 3, 1) + 0.4 * streak
img = colourise(base, [(0, (150, 88, 80)), (0.5, (226, 156, 146)), (1, (255, 214, 204))])
d = ImageDraw.Draw(img)
for i in range(4):
    for j in range(4):
        cx, cy = i * 256 + 128, j * 256 + 128
        for k in range(3):
            r = 40 + k * 26
            d.arc([cx - r, cy - r, cx + r, cy + r], 30 + k * 40, 250 + k * 40, fill=(255, 228, 210), width=5)
save(img, "rose")

# Ice: pale blue with frost crystals branching
img = colourise(tile_noise(4, 4, 2), [(0, (150, 200, 235)), (0.6, (205, 236, 252)), (1, (245, 252, 255))])
d = ImageDraw.Draw(img)
random.seed(3)
for _ in range(70):
    x, y = random.randrange(S), random.randrange(S)
    size = random.randint(14, 46)
    for a in range(6):
        ang = a * math.pi / 3 + random.random() * 0.2
        ex, ey = x + math.cos(ang) * size, y + math.sin(ang) * size
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                d.line([(x + ox, y + oy), (ex + ox, ey + oy)], fill=(255, 255, 255), width=3)
                mx, my = (x + ex) / 2 + ox, (y + ey) / 2 + oy
                for side in (-1, 1):
                    b = ang + side * 0.7
                    d.line([(mx, my), (mx + math.cos(b) * size * 0.35, my + math.sin(b) * size * 0.35)], fill=(235, 248, 255), width=2)
save(img.filter(ImageFilter.GaussianBlur(0.6)), "ice")

# Lava: dark cracked rock with glowing veins along the cracks
n = tile_noise(5, 5, 3)
veins = np.abs(np.sin(n * math.pi * 7))  # thin bright lines where the noise crosses bands
glow = np.clip(1 - veins * 6, 0, 1)
rock = colourise(tile_noise(8, 3, 4), [(0, (30, 18, 14)), (1, (80, 50, 40))])
hot = colourise(glow, [(0, (0, 0, 0)), (0.5, (255, 90, 20)), (1, (255, 230, 120))])
rock_a = np.asarray(rock, float)
hot_a = np.asarray(hot.filter(ImageFilter.GaussianBlur(2)), float)
save(Image.fromarray(np.clip(rock_a + hot_a, 0, 255).astype(np.uint8)), "lava")

# Candy Cane: diagonal red and white stripes with a soft sheen (stripes wrap: period divides S)
yy, xx = np.mgrid[0:S, 0:S]
stripe = ((xx + yy) // 64) % 2
img = np.where(stripe[..., None] == 1, np.array([230, 40, 60]), np.array([250, 248, 244])).astype(float)
thin = ((xx + yy + 32) % 128 < 10)
img[thin] = [255, 170, 180]
sheen = 0.85 + 0.15 * np.sin(yy / S * math.pi * 4)[..., None]
save(Image.fromarray(np.clip(img * sheen, 0, 255).astype(np.uint8)), "candy")

# Galaxy: deep purple nebula clouds and scattered stars
neb = tile_noise(3, 5, 5)
img = colourise(neb, [(0, (12, 6, 30)), (0.45, (60, 20, 110)), (0.7, (140, 70, 220)), (1, (255, 150, 230))])
d = ImageDraw.Draw(img)
random.seed(9)
for _ in range(900):
    x, y, r = random.randrange(S), random.randrange(S), random.choice([1, 1, 1, 2, 2, 3])
    d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255))
for _ in range(25):
    x, y = random.randrange(S), random.randrange(S)
    d.line([(x - 9, y), (x + 9, y)], fill=(255, 250, 220), width=2)
    d.line([(x, y - 9), (x, y + 9)], fill=(255, 250, 220), width=2)
save(img, "galaxy")

# Diamond: pale crystal facets (a triangle grid with shaded faces and bright edges)
img = Image.new("RGB", (S, S))
d = ImageDraw.Draw(img)
random.seed(11)
step = 128
for j in range(-1, S // step + 1):
    for i in range(-1, S // step + 2):
        x0 = i * step + (step // 2 if j % 2 else 0)
        y0 = j * step
        for tri in ([(x0, y0), (x0 + step, y0), (x0 + step // 2, y0 + step)], [(x0 + step // 2, y0 + step), (x0 + step, y0), (x0 + step * 1.5, y0 + step)]):
            t = random.random()
            col = (int(170 + 70 * t), int(215 + 35 * t), 255)
            d.polygon(tri, fill=col, outline=(255, 255, 255))
save(img.filter(ImageFilter.GaussianBlur(0.8)), "diamond")
print("ok")
