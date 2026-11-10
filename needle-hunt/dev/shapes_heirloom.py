"""Heirloom: the grade above Masterwork, from the owner's "Heirloom Rarity: Special Collection"
sheet. The centrepiece is The Eye of the Needle (a celestial compass for an eye, an engraved
shaft, an opal orb near the point); the rest are the sheet's antique set. Read by dev/shapes.py.
Same rule as every shape: the eye end at -X, a sharp point at +X. The shaft carries the skin.
"""
import math

GRADES = {}

GOLD, BRONZE, NAVY, CREAM, BROWN = (236, 186, 80), (176, 120, 60), (34, 44, 120), (238, 222, 176), (124, 72, 40)
RUBY, SAPPHIRE, OPAL, PINK, STEEL = (210, 40, 60), (50, 110, 230), (236, 242, 255), (240, 130, 180), (150, 156, 170)


def add(m):
    shape, shaft, tip, part, segments, bar, star = m.shape, m.shaft, m.tip, m.part, m.segments, m.bar, m.star

    def spike(o, x0, d=0.07):
        shaft(o, x0, 1.45, d, 6)
        tip(o, 1.45, d, 3)

    def ring(o, cx, cy, r, n, thick, colour, depth=None):
        for k in range(n):
            p, q = math.radians(360 * k / n), math.radians(360 * (k + 1) / n)
            bar(o, (cx + math.cos(p) * r, cy + math.sin(p) * r), (cx + math.cos(q) * r, cy + math.sin(q) * r), thick, depth or thick, colour, 3)

    def disc(o, x, y, d, colour, z=0.0, thick=0.06):
        part(o, (thick, d, d), (x, y, z), (0, 90, 0), colour, "C", 3)

    def gem(o, x, y, d, colour, z=0.04):
        part(o, (d, d, d), (x, y, z), colour=colour, kind="S", flags=3)

    @shape("eyeofneedle")
    def _(o):
        cx = -1.25
        part(o, (0.16, 0.12, 0.12), (-1.82, 0, 0), (0, 0, 45), GOLD, "B", 3)  # the finial
        disc(o, cx, 0, 1.0, BRONZE, z=-0.07)
        disc(o, cx, 0, 0.8, NAVY, z=-0.04)
        ring(o, cx, 0, 0.45, 16, 0.08, GOLD, 0.12)
        star(o, cx, 0, 0.34, 0.07, GOLD)
        for (dx, dy, d, c) in ((-0.17, 0.19, 0.11, PINK), (0.19, -0.18, 0.1, RUBY), (0.2, 0.2, 0.05, OPAL), (-0.22, -0.15, 0.05, OPAL)):
            gem(o, cx + dx, dy, d, c, 0.02)
        for (dx, dy, c) in ((0, 0.51, RUBY), (0, -0.51, SAPPHIRE), (-0.51, 0, SAPPHIRE)):
            gem(o, cx + dx, dy, 0.11, c, 0.03)
        segments(o, -0.8, -0.5, [0.26, 0.19, 0.23, 0.16], colours=[GOLD, BROWN, GOLD, GOLD])
        gem(o, -0.65, 0, 0.08, SAPPHIRE, 0.1)
        segments(o, -0.5, 0.72, [0.14] * 7)  # the engraved shaft, in the skin
        for x in (-0.3, 0.1, 0.5):
            part(o, (0.03, 0.15, 0.15), (x, 0, 0), colour=(90, 96, 112), kind="C")
        disc(o, 0.95, 0, 0.62, (220, 190, 255), z=-0.05, thick=0.02)  # the opal's soft halo
        disc(o, 0.95, 0, 0.44, SAPPHIRE, z=-0.03)
        ring(o, 0.95, 0, 0.24, 12, 0.06, GOLD, 0.09)
        gem(o, 0.95, 0, 0.22, OPAL, 0.03)
        part(o, (0.08, 0.2, 0.2), (0.72, 0, 0), colour=GOLD, kind="C")
        spike(o, 0.72, 0.08)

    @shape("treasuremap")
    def _(o):
        part(o, (0.6, 0.5, 0.03), (-1.3, 0, 0), colour=CREAM, kind="B", flags=3)
        for x in (-1.62, -0.98):
            part(o, (0.56, 0.1, 0.1), (x, 0, 0), (0, 0, 90), (214, 190, 140), "C", 3)
        for k in range(4):
            part(o, (0.07, 0.03, 0.02), (-1.48 + k * 0.08, -0.14 + k * 0.05, 0.03), colour=BROWN, kind="B", flags=3)
        for a in (45, -45):
            part(o, (0.14, 0.035, 0.02), (-1.12, 0.1, 0.03), (0, 0, a), RUBY, "B", 3)
        spike(o, -0.95)

    @shape("heirloomtome")
    def _(o):
        part(o, (0.52, 0.64, 0.16), (-1.3, 0, 0), colour=BROWN, kind="B", flags=3)
        part(o, (0.04, 0.58, 0.12), (-1.03, 0, 0), colour=CREAM, kind="B", flags=3)
        for sx in (-1, 1):
            for sy in (-1, 1):
                part(o, (0.1, 0.1, 0.03), (-1.3 + sx * 0.21, sy * 0.27, 0.08), (0, 0, 45), GOLD, "B", 3)
        disc(o, -1.3, 0, 0.24, GOLD, z=0.07)
        gem(o, -1.3, 0, 0.14, SAPPHIRE, 0.1)
        part(o, (0.05, 0.22, 0.02), (-1.18, -0.38, 0.06), colour=SAPPHIRE, kind="B", flags=3)
        spike(o, -1.03)

    @shape("starchart")
    def _(o):
        part(o, (0.5, 0.66, 0.04), (-1.3, 0, 0), colour=NAVY, kind="B", flags=3)
        for a, b in (((-1.55, 0.33), (-1.05, 0.33)), ((-1.55, -0.33), (-1.05, -0.33)), ((-1.55, 0.33), (-1.55, -0.33)), ((-1.05, 0.33), (-1.05, -0.33))):
            bar(o, a, b, 0.05, 0.06, GOLD)
        ring(o, -1.3, 0, 0.16, 10, 0.03, GOLD, 0.06)
        part(o, (0.12, 0.12, 0.04), (-1.3, 0, 0.03), (0, 0, 45), SAPPHIRE, "B", 3)
        for (x, y, d, c) in ((-1.44, 0.22, 0.06, PINK), (-1.16, -0.22, 0.05, RUBY), (-1.18, 0.24, 0.03, OPAL), (-1.45, -0.2, 0.03, OPAL)):
            gem(o, x, y, d, c, 0.03)
        spike(o, -1.05)

    @shape("crystalcluster")
    def _(o):
        base = (-1.0, 0)
        for ang, length, c in ((180, 0.8, SAPPHIRE), (152, 0.6, (160, 90, 230)), (208, 0.6, (60, 200, 120)), (126, 0.42, PINK), (234, 0.42, (240, 210, 70))):
            a = math.radians(ang)
            part(o, (length, 0.21, 0.21), (base[0] + math.cos(a) * length / 2, math.sin(a) * length / 2, 0), (45, 0, ang), c, "B", 3)
        for s in (-1, 1):
            part(o, (0.26, 0.12, 0.04), (-1.02, s * 0.14, 0), (0, 0, s * 35), GOLD, "B", 3)
        disc(o, -0.98, 0, 0.22, GOLD, thick=0.1)
        spike(o, -0.95)

    @shape("clockgear")
    def _(o):
        cx = -1.32
        disc(o, cx, 0, 0.66, GOLD, thick=0.08)
        for k in range(8):
            a = math.radians(k * 45)
            part(o, (0.15, 0.13, 0.08), (cx + math.cos(a) * 0.37, math.sin(a) * 0.37, 0), (0, 0, k * 45), GOLD, "B", 3)
        disc(o, cx, 0, 0.28, BRONZE, z=0.03)
        disc(o, cx, 0, 0.1, GOLD, z=0.05)
        spike(o, -1.05)

    @shape("astrolabe")
    def _(o):
        cx = -1.3
        disc(o, cx, 0, 0.84, NAVY, z=-0.04)
        ring(o, cx, 0, 0.43, 16, 0.07, GOLD, 0.1)
        ring(o, cx, 0, 0.25, 10, 0.03, GOLD, 0.06)
        for a in (30, 120):
            r = math.radians(a)
            bar(o, (cx - math.cos(r) * 0.41, -math.sin(r) * 0.41), (cx + math.cos(r) * 0.41, math.sin(r) * 0.41), 0.035, 0.06, GOLD)
        bar(o, (cx, 0), (cx + 0.22, 0.3), 0.06, 0.08, (250, 240, 200))
        gem(o, cx, 0, 0.09, GOLD, 0.05)
        gem(o, cx - 0.12, -0.18, 0.06, PINK, 0.02)
        spike(o, -0.97)

    @shape("brasscompass")
    def _(o):
        cx = -1.3
        ring(o, -1.75, 0, 0.08, 8, 0.04, GOLD, 0.05)  # the loop
        disc(o, cx, 0, 0.76, GOLD, z=-0.03, thick=0.08)
        disc(o, cx, 0, 0.62, (244, 236, 210), z=0.0, thick=0.06)
        r = math.radians(70)
        bar(o, (cx, 0), (cx + math.cos(r) * 0.26, math.sin(r) * 0.26), 0.06, 0.08, RUBY)
        bar(o, (cx, 0), (cx - math.cos(r) * 0.26, -math.sin(r) * 0.26), 0.06, 0.08, SAPPHIRE)
        gem(o, cx, 0, 0.06, GOLD, 0.05)
        spike(o, -1.0)

    @shape("heirloomkey")
    def _(o):
        cx = -1.45
        ring(o, cx, 0, 0.16, 10, 0.06, GOLD, 0.08)
        for a in (90, 180, 270):
            r = math.radians(a)
            ring(o, cx + math.cos(r) * 0.2, math.sin(r) * 0.2, 0.07, 8, 0.04, GOLD, 0.06)
        gem(o, cx, 0, 0.14, SAPPHIRE, 0.02)
        segments(o, -1.27, -0.2, [0.1] * 5, colours=[GOLD] * 5)
        for x in (-0.55, -0.4):
            part(o, (0.08, 0.16, 0.06), (x, -0.1, 0), colour=GOLD, kind="B", flags=0)
        part(o, (0.1, 0.16, 0.16), (-0.18, 0, 0), colour=GOLD, kind="C")
        spike(o, -0.15)

    for n in ("eyeofneedle", "treasuremap", "heirloomtome", "starchart", "crystalcluster", "clockgear", "astrolabe", "brasscompass", "heirloomkey"):
        GRADES[n] = "heirloom"
