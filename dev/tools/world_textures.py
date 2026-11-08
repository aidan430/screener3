"""Seamless 1024x1024 textures for the farm (upload each in Studio, put the IDs in Config):
  assets/hay/hay-normal.png        a normal map for the owner's hay (assets/hay/hay-texture.png)
  assets/grass/grass.png           the fields and plot floors, and grass-normal.png
  assets/portal/portal-flow.png    white flowing wisps on transparent; every portal tints it
Run: python3 dev/tools/world_textures.py"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024
ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "assets")


def tile_noise(scale, octaves=4, seed=0):
    """Seamless value noise in 0..1: each octave's grid is tiled 3x3, enlarged, and the middle kept."""
    r = np.random.default_rng(seed)
    out, amp, total = np.zeros((S, S)), 1.0, 0.0
    for o in range(octaves):
        n = scale * 2 ** o
        grid = np.tile(r.random((n, n)), (3, 3))
        big = Image.fromarray((grid * 255).astype(np.uint8)).resize((S * 3, S * 3), Image.BICUBIC)
        out += amp * np.asarray(big, dtype=float)[S:2 * S, S:2 * S] / 255
        total += amp
        amp *= 0.5
    out /= total
    return (out - out.min()) / (out.max() - out.min())


def tile_noise_xy(nx, ny, octaves=4, seed=0):
    """Like tile_noise, but with nx cells across and ny down (ny < nx stretches it tall)."""
    r = np.random.default_rng(seed)
    out, amp, total = np.zeros((S, S)), 1.0, 0.0
    for o in range(octaves):
        gx, gy = nx * 2 ** o, ny * 2 ** o
        grid = np.tile(r.random((gy, gx)), (3, 3))
        big = Image.fromarray((grid * 255).astype(np.uint8)).resize((S * 3, S * 3), Image.BICUBIC)
        out += amp * np.asarray(big, dtype=float)[S:2 * S, S:2 * S] / 255
        total += amp
        amp *= 0.5
    out /= total
    return (out - out.min()) / (out.max() - out.min())


def wrap_blur(arr, radius):
    """A Gaussian blur that wraps round the edges (so a seamless image stays seamless)."""
    big = np.tile(arr, (3, 3))
    img = Image.fromarray((big * 255).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(radius))
    return np.asarray(img, float)[S:2 * S, S:2 * S] / 255


def normal_map(height, strength):
    """A tangent-space normal map from a seamless height field (0..1), wrapping at the edges."""
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * strength
    n = np.dstack([-dx, dy, np.ones_like(height)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8))


def hay_normal():
    img = Image.open(os.path.join(ROOT, "hay", "hay-texture.png")).convert("L").resize((S, S))
    height = wrap_blur(np.asarray(img, float) / 255, 1.2)
    normal_map(height, 6).save(os.path.join(ROOT, "hay", "hay-normal.png"))


def wrapped(draw_fn):
    """Draws a mark nine times, a tile apart, so marks crossing an edge come back on the other side."""
    for dx in (-S, 0, S):
        for dy in (-S, 0, S):
            draw_fn(dx, dy)


def grass():
    rnd = random.Random(11)
    # ground: a few greens in soft patches, with a little earth showing through
    patches = tile_noise(6, 4, seed=3)
    fine = tile_noise(40, 3, seed=4)
    t = 0.3 + 0.4 * (0.45 * patches + 0.55 * fine)  # gentle variation: no patch should stand out when tiled
    stops = [(0.0, (58, 86, 34)), (0.35, (78, 112, 42)), (0.7, (104, 138, 56)), (1.0, (128, 156, 70))]
    base = np.zeros((S, S, 3))
    for c in range(3):
        base[..., c] = np.interp(t, [s[0] for s in stops], [s[1][c] for s in stops])
    img = Image.fromarray(base.astype(np.uint8))
    height = Image.new("L", (S, S), 90)
    d, h = ImageDraw.Draw(img), ImageDraw.Draw(height)
    greens = [(70, 104, 38), (92, 130, 48), (112, 150, 58), (136, 170, 72), (154, 182, 88), (60, 92, 34)]
    for i in range(26000):  # short blades, leaning a little, darker ones first
        x, y = rnd.random() * S, rnd.random() * S
        col = greens[min(len(greens) - 1, int(i / 26000 * len(greens) + rnd.random() * 1.5))]
        length = 6 + rnd.random() * 12
        a = -math.pi / 2 + (rnd.random() - 0.5) * 1.3
        ex, ey = x + math.cos(a) * length, y + math.sin(a) * length
        w = 1 if rnd.random() < 0.7 else 2
        shade = int(110 + 120 * i / 26000)
        wrapped(lambda dx, dy: (d.line((x + dx, y + dy, ex + dx, ey + dy), fill=col, width=w), h.line((x + dx, y + dy, ex + dx, ey + dy), fill=shade, width=w)))
    for _ in range(160):  # clover leaves and a few tiny flowers, sparse
        x, y = rnd.random() * S, rnd.random() * S
        if rnd.random() < 0.7:
            for k in range(3):
                a = k * 2.1 + rnd.random()
                cx, cy = x + math.cos(a) * 3, y + math.sin(a) * 3
                wrapped(lambda dx, dy: d.ellipse((cx + dx - 3, cy + dy - 3, cx + dx + 3, cy + dy + 3), fill=(84, 128, 52)))
        else:
            col = rnd.choice([(250, 246, 232), (246, 214, 92), (226, 196, 226)])
            wrapped(lambda dx, dy: d.ellipse((x + dx - 2, y + dy - 2, x + dx + 2, y + dy + 2), fill=col))
    out = os.path.join(ROOT, "grass")
    os.makedirs(out, exist_ok=True)
    img.save(os.path.join(out, "grass.png"))
    normal_map(wrap_blur(np.asarray(height, float) / 255, 0.8), 4).save(os.path.join(out, "grass-normal.png"))


def portal_flow():
    """White veils that flow upwards on a clear background: tall noise, warped sideways, banded."""
    tall = tile_noise_xy(7, 2, 3, seed=21)  # long vertical streaks
    sway = tile_noise_xy(3, 3, 3, seed=22)
    yy, xx = np.mgrid[0:S, 0:S]
    warped = tall[yy, (xx + ((sway - 0.5) * 140).astype(int)) % S]
    bands = 0.5 + 0.5 * np.cos(warped * 4 * 2 * math.pi)  # whole turns only, so it stays seamless
    glow = tile_noise_xy(4, 2, 3, seed=23)
    alpha = np.clip(bands ** 4 * 1.2 + glow * 0.25, 0, 1)
    alpha = wrap_blur(alpha, 1.5)
    rgba = np.dstack([np.full((S, S), 255), np.full((S, S), 255), np.full((S, S), 255), (alpha * 255).astype(int)]).astype(np.uint8)
    out = os.path.join(ROOT, "portal")
    os.makedirs(out, exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(os.path.join(out, "portal-flow.png"))


if __name__ == "__main__":
    hay_normal()
    grass()
    portal_flow()
    print("done")
