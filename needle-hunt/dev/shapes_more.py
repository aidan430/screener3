"""The owner's Gemini sheets, built as needle shapes: 49 of them (the repeats, the plain handles and
the two we already had are left out). Read by dev/shapes.py, which passes in its helpers:

    shape, shaft, tip, part, segments, bar, star, and the colours WOOD, DARK, METAL, GREEN, FLAME

Every one keeps the needle rule: the eye end at -X, a sharp point at +X. Most carry their object at
the eye end and a long spike (the skin's pattern) to the point.
"""
import math

GRADES = {}  # shape id -> grade, read by dev/shapes.py's caller (Needles.luau is written by hand)


def add(m):
    shape, shaft, tip, part, segments, bar, star = m.shape, m.shaft, m.tip, m.part, m.segments, m.bar, m.star
    WOOD, DARK, METAL, GREEN, FLAME = m.WOOD, m.DARK, m.METAL, m.GREEN, m.FLAME
    YELLOW, CREAM, BROWN, RED, BLUE, PINK, GREY, PURPLE, GOLD = (250, 210, 60), (244, 232, 206), (128, 84, 52), (220, 60, 50), (120, 170, 220), (240, 140, 160), (150, 156, 166), (150, 110, 220), (240, 190, 70)

    def spike(o, x0, d=0.06):
        shaft(o, x0, 1.45, d, 6)
        tip(o, 1.45, d, 3)

    def ring(o, cx, cy, r, n, a0, a1, thick, colour, flags=3):
        for k in range(n):
            p, q = math.radians(a0 + (a1 - a0) * k / n), math.radians(a0 + (a1 - a0) * (k + 1) / n)
            bar(o, (cx + math.cos(p) * r, cy + math.sin(p) * r), (cx + math.cos(q) * r, cy + math.sin(q) * r), thick, thick, colour, flags)

    def disc(o, x, y, d, colour, z=0.0, thick=0.08):
        part(o, (thick, d, d), (x, y, z), (0, 90, 0), colour, "C", 3)

    # ---------- Farm (Fancy) ----------
    @shape("corn")
    def _(o):
        segments(o, -1.55, -0.3, [0.3, 0.4, 0.43, 0.4, 0.3], colours=[YELLOW] * 5)
        for k in range(5):
            part(o, (0.06, 0.06, 0.06), (-1.45 + k * 0.24, 0.12, 0.1), colour=(255, 232, 120), kind="S", flags=1)
        for s in (-1, 1):
            part(o, (0.8, 0.16, 0.03), (-0.75, s * 0.2, 0), (0, 0, s * -18), GREEN, "B", 3)
        spike(o, -0.3)

    @shape("rollingpin")
    def _(o):
        part(o, (0.18, 0.18, 0.18), (-1.62, 0, 0), colour=WOOD, kind="S")
        part(o, (0.2, 0.08, 0.08), (-1.45, 0, 0), colour=WOOD, kind="C")
        segments(o, -1.35, 0.2, [0.34] * 5)
        part(o, (0.2, 0.08, 0.08), (0.3, 0, 0), colour=WOOD, kind="C")
        spike(o, 0.4)

    @shape("broom")
    def _(o):
        segments(o, -1.65, -1.1, [0.5, 0.44, 0.34, 0.24], colours=[(222, 190, 120)] * 4)
        for k in range(5):  # bristle ends, splayed
            part(o, (0.22, 0.04, 0.03), (-1.68, -0.2 + k * 0.1, 0), (0, 0, (k - 2) * 8), (200, 166, 96), "B", 3)
        part(o, (0.08, 0.22, 0.22), (-1.06, 0, 0), colour=DARK, kind="C")
        shaft(o, -1.0, 1.3, 0.09, 7)
        tip(o, 1.3, 0.09, 3)

    @shape("trowel")
    def _(o):
        part(o, (0.7, 0.62, 0.05), (-1.3, 0, 0), colour=METAL, kind="B", flags=2)
        part(o, (0.44, 0.44, 0.05), (-1.65, 0, 0), (0, 0, 45), METAL, "B", 2)
        part(o, (0.14, 0.14, 0.14), (-0.98, 0, 0), colour=METAL, kind="C")
        segments(o, -0.9, -0.4, [0.18, 0.19, 0.18])
        spike(o, -0.4)

    @shape("wheat")
    def _(o):
        for k in range(4):
            for s in (-1, 1):
                part(o, (0.3, 0.16, 0.16), (-1.55 + k * 0.2, s * 0.12, 0), (0, 0, s * 30), (222, 180, 100), "S", 3)
        part(o, (0.3, 0.18, 0.18), (-1.72, 0, 0), colour=(222, 180, 100), kind="S", flags=3)
        spike(o, -0.85, 0.05)

    @shape("milkbottle")
    def _(o):
        shaft(o, -1.65, -1.1, 0.05, 2)
        segments(o, -1.1, -0.3, [0.36] * 4, colours=[(244, 244, 248)] * 4)
        part(o, (0.2, 0.16, 0.16), (-0.2, 0, 0), colour=(244, 244, 248), kind="C")
        part(o, (0.08, 0.2, 0.2), (-0.06, 0, 0), colour="a", kind="C")
        spike(o, 0.0)

    @shape("awl")
    def _(o):
        shaft(o, -1.6, -0.6, 0.05, 3)
        segments(o, -0.6, -0.1, [0.14, 0.2, 0.26, 0.3], colours=["a"] * 4)
        spike(o, -0.1, 0.055)

    @shape("horseshoe")
    def _(o):
        ring(o, -1.32, 0, 0.38, 9, -140, 140, 0.15, "c1/2")
        for s in (-1, 1):
            part(o, (0.07, 0.07, 0.07), (-1.55, s * 0.28, 0.06), colour=DARK, kind="S", flags=3)
        spike(o, -1.04)

    @shape("wateringcan")
    def _(o):
        segments(o, -1.45, -0.75, [0.44] * 3, colours=["a"] * 3)
        bar(o, (-1.32, 0.22), (-1.18, 0.4), 0.06, 0.06, "a", 1)
        bar(o, (-1.18, 0.4), (-0.92, 0.4), 0.06, 0.06, "a", 1)
        bar(o, (-0.92, 0.4), (-0.82, 0.22), 0.06, 0.06, "a", 1)
        bar(o, (-0.78, 0.0), (-0.42, 0.26), 0.07, 0.07, "a", 1)
        part(o, (0.1, 0.16, 0.16), (-0.38, 0.29, 0), (0, 0, 35), "a", "C", 1)
        spike(o, -0.75)

    @shape("sunflower")
    def _(o):
        for k in range(12):
            a = math.radians(k * 30)
            part(o, (0.2, 0.11, 0.05), (-1.32 + math.cos(a) * 0.24, math.sin(a) * 0.24, 0), (0, 0, k * 30), YELLOW, "B", 3)
        part(o, (0.28, 0.28, 0.28), (-1.32, 0, 0.04), colour=BROWN, kind="S", flags=3)
        shaft(o, -1.06, 1.45, 0.05, 7)
        tip(o, 1.45, 0.05, 2)
        for s in (-1, 1):
            part(o, (0.28, 0.12, 0.02), (-0.5 + s * 0.1, s * 0.12, 0), (0, 0, s * 35), GREEN, "B", 3)

    @shape("woodenspoon")
    def _(o):
        disc(o, -1.38, 0, 0.72, WOOD, 0, 0.12)
        disc(o, -1.38, 0, 0.54, (196, 150, 98), 0.07, 0.04)
        shaft(o, -1.06, 1.3, 0.09, 7)
        tip(o, 1.3, 0.09, 3)

    # ---------- Kitchen and toys (Fancy) ----------
    @shape("chopsticks")
    def _(o):
        for y in (-0.06, 0.06):
            shaft(o, -1.55, 1.3, 0.05, 6, y)
        tip(o, 1.3, 0.05, 2)
        part(o, (0.56, 0.56, 0.56), (-1.2, 0, 0.08), colour=CREAM, kind="S", flags=3)
        part(o, (0.18, 0.18, 0.18), (-1.2, 0.26, 0.08), colour=(232, 216, 186), kind="S", flags=3)

    @shape("whisk")
    def _(o):
        for h in (0.14, 0.28, 0.42):
            pts = [(-0.78, 0), (-1.05, h), (-1.42, h * 0.9), (-1.62, 0), (-1.42, -h * 0.9), (-1.05, -h), (-0.78, 0)]
            for a, b in zip(pts, pts[1:]):
                bar(o, a, b, 0.025, 0.025, METAL, 1)
        part(o, (0.14, 0.12, 0.12), (-0.74, 0, 0), colour="a", kind="C")
        spike(o, -0.7)

    @shape("crayon")
    def _(o):
        segments(o, -1.5, 0.6, [0.26] * 7)
        for x in (-1.2, 0.3):
            part(o, (0.08, 0.28, 0.28), (x, 0, 0), colour="a", kind="C")
        for k in range(1, 5):
            part(o, (0.1, 0.26 * (1 - k / 5), 0.26 * (1 - k / 5)), (0.6 + k * 0.09, 0, 0), colour="c7/7", kind="C")
        tip(o, 1.0, 0.05, 2)

    @shape("spool")
    def _(o):
        shaft(o, -1.6, -0.9, 0.05, 3)
        disc(o, -0.86, 0, 0.42, WOOD, 0, 0.08)
        part(o, (0.4, 0.3, 0.3), (-0.62, 0, 0), colour="a", kind="C")
        disc(o, -0.38, 0, 0.42, WOOD, 0, 0.08)
        spike(o, -0.34, 0.05)

    @shape("partyhorn")
    def _(o):
        disc(o, -1.45, 0, 0.56, "c1/2", 0, 0.16)
        disc(o, -1.45, 0, 0.32, "c2/2", 0.09, 0.06)
        segments(o, -1.3, 0.9, [0.14] * 8)
        part(o, (0.14, 0.18, 0.18), (0.95, 0, 0), colour="a", kind="C")
        spike(o, 1.0, 0.04)

    @shape("straw")
    def _(o):
        segments(o, -1.55, 1.2, [0.11] * 12)
        tip(o, 1.2, 0.11, 3)

    @shape("spinningtop")
    def _(o):
        tip(o, -1.5, 0.05, 2)
        segments(o, -1.35, -0.6, [0.12, 0.3, 0.44, 0.4, 0.22])
        part(o, (0.18, 0.18, 0.18), (-0.5, 0, 0), colour="a", kind="S")
        spike(o, -0.42, 0.05)

    @shape("toothbrush")
    def _(o):
        segments(o, -1.6, 0.65, [0.1, 0.12, 0.13, 0.12, 0.1, 0.09], squash=0.6)
        part(o, (0.36, 0.1, 0.07), (0.82, 0, 0), colour="c6/6")
        part(o, (0.3, 0.12, 0.08), (0.84, 0.1, 0), colour=(250, 250, 252), kind="B", flags=1)
        spike(o, 1.0, 0.03)

    @shape("woodsword")
    def _(o):
        for i in range(6):
            part(o, (0.27, 0.22, 0.05), (-0.25 + (i + 0.5) * 0.26, 0, 0), colour=f"c{i + 1}/6")
        for s in (-1, 1):
            part(o, (0.24, 0.07, 0.05), (1.36, s * 0.05, 0), (0, 0, s * -35), "c6/6", "B", 0)
        tip(o, 1.42, 0.05, 2)
        part(o, (0.1, 0.5, 0.1), (-0.3, 0, 0), colour="a", flags=0)
        part(o, (0.4, 0.1, 0.1), (-0.6, 0, 0), colour=BROWN, kind="C")
        part(o, (0.18, 0.18, 0.18), (-0.86, 0, 0), colour="a", kind="S")

    # ---------- Nature and weather (Exotic) ----------
    @shape("pinecone")
    def _(o):
        segments(o, -1.6, -0.7, [0.2, 0.34, 0.42, 0.4, 0.3], colours=[BROWN] * 5)
        for k in range(6):
            s = 1 if k % 2 else -1
            part(o, (0.14, 0.08, 0.06), (-1.5 + k * 0.15, s * 0.16, 0.06), (0, 0, s * 35), (160, 108, 66), "B", 2)
        spike(o, -0.7)

    @shape("cactus")
    def _(o):
        segments(o, -1.45, -0.35, [0.28] * 4, colours=[(90, 170, 80)] * 4)
        bar(o, (-1.0, 0.1), (-1.0, 0.38), 0.12, 0.12, (90, 170, 80), 0)
        bar(o, (-0.65, -0.1), (-0.65, -0.34), 0.12, 0.12, (90, 170, 80), 0)
        for x, y in ((-1.3, 0.16), (-0.9, -0.16), (-0.55, 0.16), (-1.0, 0.42)):
            part(o, (0.08, 0.03, 0.03), (x, y, 0.04), (0, 0, 60), (240, 220, 140), "B", 3)
        spike(o, -0.35)

    @shape("raindrop")
    def _(o):
        part(o, (0.46, 0.46, 0.46), (-1.3, 0, 0), colour="a", kind="S", flags=0)
        segments(o, -1.15, -0.6, [0.42, 0.32, 0.2, 0.1], colours=["a"] * 4)
        spike(o, -0.6, 0.05)

    @shape("snowflake")
    def _(o):
        segments(o, -1.6, 1.3, [0.14 - k * 0.009 for k in range(10)])
        tip(o, 1.3, 0.05, 2)
        for k in range(6):
            a = math.radians(k * 60)
            part(o, (0.56, 0.06, 0.04), (0.3 + math.cos(a) * 0.28, math.sin(a) * 0.28, 0.06), (0, 0, k * 60), (190, 220, 245), "B", 3)
            for s in (-1, 1):
                b = a + s * math.radians(40)
                part(o, (0.14, 0.04, 0.03), (0.3 + math.cos(a) * 0.36 + math.cos(b) * 0.06, math.sin(a) * 0.36 + math.sin(b) * 0.06, 0.06), (0, 0, math.degrees(b)), (190, 220, 245), "B", 3)

    @shape("volcano")
    def _(o):
        segments(o, -1.65, -0.8, [0.62, 0.52, 0.4, 0.3], colours=[(110, 80, 64)] * 4)
        for x, y, ln in ((-0.95, 0.12, 0.3), (-1.1, -0.15, 0.36), (-0.88, -0.05, 0.2)):
            part(o, (ln, 0.06, 0.05), (x, y, 0.08), (0, 0, 70 if y > 0 else -70), (250, 120, 40), "B", 1)
        part(o, (0.16, 0.3, 0.3), (-0.8, 0, 0), colour=(250, 120, 40), kind="C")
        spike(o, -0.75)

    @shape("tornado")
    def _(o):
        dias = [0.08, 0.14, 0.2, 0.27, 0.34, 0.42, 0.48]
        for i, d in enumerate(dias):
            part(o, (0.18, d, d), (-1.6 + i * 0.16, (0.03 if i % 2 else -0.03), 0), colour=f"c{i + 1}/7", kind="C")
        spike(o, -0.5)

    @shape("mushroom")
    def _(o):
        segments(o, -1.6, -1.0, [0.16, 0.18, 0.2], colours=[CREAM] * 3)
        part(o, (0.62, 0.62, 0.62), (-0.82, 0, 0), colour=RED, kind="S", flags=3)
        for x, y in ((-0.95, 0.18), (-0.72, -0.16), (-0.66, 0.12), (-0.9, -0.08)):
            part(o, (0.1, 0.1, 0.1), (x, y, 0.27), colour=(250, 250, 250), kind="S", flags=3)
        spike(o, -0.55)

    @shape("coral")
    def _(o):
        for a, b in (((-1.6, 0), (-1.15, 0)), ((-1.15, 0), (-0.85, 0.26)), ((-1.15, 0), (-0.85, -0.26)), ((-0.85, 0.26), (-0.62, 0.4)),
                     ((-0.85, 0.26), (-0.64, 0.18)), ((-0.85, -0.26), (-0.62, -0.4)), ((-1.35, 0), (-1.2, 0.22)), ((-1.35, 0), (-1.2, -0.22))):
            bar(o, a, b, 0.09, 0.09, PINK, 1)
        spike(o, -1.05)

    @shape("seashell")
    def _(o):
        dias = [0.14, 0.24, 0.32, 0.36, 0.32, 0.26]
        for i, d in enumerate(dias):
            part(o, (0.16, d, d), (-1.6 + i * 0.15, 0, 0), colour=(232, 196, 156) if i % 2 else (206, 156, 112), kind="C")
        spike(o, -0.7)

    # ---------- Creatures (Exotic) ----------
    @shape("unicorn")
    def _(o):
        dias = [0.34 - k * 0.026 for k in range(11)]
        for i, d in enumerate(dias):
            part(o, (0.28, d, d), (-1.55 + i * 0.27, (0.02 if i % 2 else -0.02), 0), (0, 0, 0), f"c{i + 1}/11", "C")
        tip(o, 1.4, 0.06, 3)

    @shape("stingray")
    def _(o):
        part(o, (0.9, 0.9, 0.07), (-1.15, 0, 0), (0, 0, 45), "a", "B", 3)
        part(o, (0.42, 0.42, 0.08), (-0.82, 0, 0.01), (0, 0, 45), "a", "B", 3)
        for s in (-1, 1):
            part(o, (0.05, 0.05, 0.05), (-0.82, s * 0.07, 0.05), colour=DARK, kind="S", flags=3)
        spike(o, -0.72, 0.05)

    @shape("woodpecker")
    def _(o):
        part(o, (0.62, 0.62, 0.62), (-1.25, 0, 0), colour=CREAM, kind="S", flags=3)
        part(o, (0.4, 0.4, 0.4), (-1.35, 0.2, 0), colour=RED, kind="S", flags=3)
        part(o, (0.08, 0.08, 0.08), (-1.08, 0.1, 0.28), colour=DARK, kind="S", flags=3)
        segments(o, -0.98, 1.3, [0.18 - k * 0.016 for k in range(9)])
        tip(o, 1.3, 0.04, 2)

    @shape("dragonfly")
    def _(o):
        segments(o, -1.55, 0.15, [0.06, 0.07, 0.07, 0.08, 0.09, 0.1, 0.12])
        part(o, (0.2, 0.2, 0.2), (0.28, 0, 0), colour=DARK, kind="S")
        for x, s in ((0.0, 1), (0.0, -1), (-0.2, 1), (-0.2, -1)):
            part(o, (0.9, 0.22, 0.02), (x - 0.35, s * 0.32, 0.02), (0, 0, s * (20 if x == 0 else 35)), (200, 222, 240), "B", 3)
        spike(o, 0.38, 0.04)

    @shape("seahorse")
    def _(o):
        pts = [(-0.3, 0.1), (-0.5, 0.0), (-0.62, -0.18), (-0.82, -0.3), (-1.05, -0.32), (-1.22, -0.22), (-1.25, -0.08), (-1.15, 0.0)]
        for i, (a, b) in enumerate(zip(pts, pts[1:])):
            bar(o, a, b, 0.2 - i * 0.02, 0.12, "a", 1)
        part(o, (0.3, 0.3, 0.3), (-0.32, 0.14, 0), colour="a", kind="S", flags=1)
        part(o, (0.2, 0.12, 0.02), (-0.66, 0.02, 0), (0, 0, 40), "c1/2", "B", 3)
        spike(o, -0.2, 0.05)

    @shape("hedgehog")
    def _(o):
        part(o, (0.56, 0.56, 0.56), (-1.1, 0, 0), colour=BROWN, kind="S", flags=3)
        for k in range(10):
            a = math.radians(70 + k * 25)
            part(o, (0.26, 0.05, 0.05), (-1.1 + math.cos(a) * 0.36, math.sin(a) * 0.36, 0), (0, 0, math.degrees(a)), (98, 64, 40), "C", 3)
        spike(o, -0.82)

    @shape("beetle")
    def _(o):
        part(o, (0.56, 0.56, 0.56), (-1.3, 0, 0), colour="a", kind="S", flags=3)
        part(o, (0.46, 0.46, 0.46), (-0.92, 0, 0), colour="a", kind="S", flags=3)
        part(o, (0.3, 0.3, 0.3), (-0.62, 0, 0), colour="c1/2", kind="S", flags=3)
        for x in (-1.35, -1.05, -0.8):
            for s in (-1, 1):
                bar(o, (x, s * 0.2), (x - 0.14, s * 0.46), 0.06, 0.06, "c1/2", 3)
        spike(o, -0.5)

    @shape("scorpion")
    def _(o):
        pts = [(-0.45, 0), (-0.7, -0.06), (-0.95, -0.14), (-1.15, -0.26), (-1.3, -0.12), (-1.28, 0.08)]
        for i, (x, y) in enumerate(pts):
            part(o, (0.4 - i * 0.03,) * 3, (x * 1.15 + 0.07, y * 1.5, 0), colour="a", kind="S", flags=3)
        bar(o, (-1.4, 0.12), (-1.26, 0.36), 0.09, 0.09, "c1/2", 3)
        spike(o, -0.4)

    @shape("sharkfin")
    def _(o):
        part(o, (0.7, 0.1, 0.06), (-1.1, 0, 0), colour="a")
        bar(o, (-1.42, 0.02), (-0.95, 0.46), 0.12, 0.06, "a", 1)
        bar(o, (-0.95, 0.46), (-0.78, 0.02), 0.12, 0.06, "a", 1)
        part(o, (0.4, 0.24, 0.06), (-0.98, 0.18, 0), colour="a", kind="B", flags=1)
        shaft(o, -0.75, 1.3, 0.06, 6)
        for s in (-1, 1):
            part(o, (0.22, 0.05, 0.04), (1.32, s * 0.06, 0), (0, 0, s * -40), "c6/6", "B", 0)
        tip(o, 1.3, 0.06, 3)

    @shape("snail")
    def _(o):
        disc(o, -1.3, 0.08, 0.78, (196, 140, 96), 0, 0.14)
        disc(o, -1.3, 0.08, 0.52, (226, 176, 126), 0.08, 0.04)
        disc(o, -1.3, 0.08, 0.24, (196, 140, 96), 0.11, 0.03)
        part(o, (0.8, 0.16, 0.16), (-1.2, -0.32, 0), colour=CREAM, kind="C", flags=3)
        spike(o, -1.05)

    # ---------- Legendary (Masterwork) ----------
    @shape("cometgem")
    def _(o):
        part(o, (0.3, 0.3, 0.3), (-1.4, 0, 0), (45, 45, 0), (180, 220, 250), "B", 3)
        cone = [0.46, 0.4, 0.32, 0.24, 0.16, 0.1]
        for i, d in enumerate(cone):
            part(o, (0.24, d, d), (-1.2 + i * 0.22, 0, 0), colour=FLAME[min(i, 3)], kind="C")
        for y, a in ((0.24, 12), (-0.22, -10)):
            part(o, (0.5, 0.07, 0.04), (-0.7, y, 0), (0, 0, a), FLAME[1], "B", 3)
        spike(o, 0.05)

    @shape("planet")
    def _(o):
        shaft(o, -1.6, -0.85, 0.05, 3)
        part(o, (0.75, 0.75, 0.75), (-0.6, 0, 0), colour="a", kind="S", flags=3)
        part(o, (0.06, 1.35, 1.35), (-0.6, 0, 0), (0, 70, 20), "c1/2", "C", 3)
        spike(o, -0.35, 0.05)

    @shape("phoenixfeather")
    def _(o):
        shaft(o, -1.55, 1.4, 0.05, 8)
        tip(o, 1.4, 0.05, 2)
        for k in range(7):
            x = -1.25 + k * 0.2
            ln = 0.42 - abs(k - 2) * 0.05
            for s in (-1, 1):
                part(o, (ln, 0.07, 0.03), (x, s * ln * 0.38, 0), (0, 0, s * 35), FLAME[(k + (s > 0)) % 3], "B", 3)

    @shape("sceptre")
    def _(o):
        segments(o, -1.55, -0.45, [0.1] * 5, colours=[BROWN, GOLD, BROWN, BROWN, GOLD])
        part(o, (0.22, 0.3, 0.3), (-0.32, 0, 0), colour=GOLD, kind="C")
        for k in range(4):
            a = math.radians(-60 + k * 40)
            part(o, (0.2, 0.06, 0.06), (-0.12 + math.cos(a) * 0.1, math.sin(a) * 0.2, 0), (0, 0, math.degrees(a)), GOLD, "B", 3)
        part(o, (0.14, 0.14, 0.14), (-0.3, 0.17, 0.12), colour=(200, 40, 70), kind="S", flags=3)
        part(o, (0.12, 0.12, 0.12), (-0.05, 0, 0.1), colour=PURPLE, kind="S", flags=3)
        spike(o, -0.05)

    @shape("trident")
    def _(o):
        shaft(o, -1.6, 0.55, 0.07, 8)
        part(o, (0.08, 0.6, 0.06), (0.6, 0, 0), colour="a", flags=1)
        shaft(o, 0.6, 1.45, 0.06, 3)
        tip(o, 1.45, 0.06, 3)
        for s in (-1, 1):
            part(o, (0.6, 0.06, 0.06), (0.92, s * 0.28, 0), colour="a", kind="C", flags=1)
            part(o, (0.2, 0.05, 0.05), (1.24, s * 0.24, 0), (0, 0, s * -30), "a", "B", 1)

    @shape("hourglass")
    def _(o):
        shaft(o, -1.65, -0.95, 0.05, 3)
        disc(o, -0.92, 0, 0.5, BROWN, 0, 0.08)
        disc(o, -0.1, 0, 0.5, BROWN, 0, 0.08)
        for s in (-1, 1):
            part(o, (0.8, 0.05, 0.05), (-0.51, s * 0.22, 0.04), colour=BROWN, kind="C", flags=1)
        segments(o, -0.88, -0.14, [0.36, 0.26, 0.12, 0.26, 0.36], colours=[(214, 236, 246)] * 5)
        part(o, (0.12, 0.12, 0.12), (-0.33, 0, 0.02), colour=(232, 200, 120), kind="S")
        spike(o, -0.05, 0.05)

    @shape("rainbowarrow")
    def _(o):
        for k, c in enumerate(((230, 70, 70), (245, 150, 60), (250, 220, 70), (90, 190, 100), (80, 150, 230), (150, 100, 220))):
            part(o, (2.0, 0.035, 0.05), (-0.3, -0.09 + k * 0.035, 0), colour=c, kind="B", flags=0)
        for s in (-1, 1):
            part(o, (0.4, 0.14, 0.03), (-1.2, s * 0.14, 0), (0, 0, s * 30), "a", "B", 3)
        for s in (-1, 1):
            part(o, (0.36, 0.08, 0.06), (0.82, s * 0.1, 0), (0, 0, s * -30), "a", "B", 1)
        spike(o, 0.7, 0.05)

    @shape("moonwand")
    def _(o):
        segments(o, -1.6, -0.3, [0.12, 0.14, 0.12, 0.12], colours=["c1/2", "a", "c1/2", "a"])
        ring(o, 0.05, 0.0, 0.42, 8, 70, 290, 0.15, (236, 226, 196))
        spike(o, -0.3, 0.05)

    @shape("treasurekey")
    def _(o):
        ring(o, -1.35, 0, 0.2, 8, 0, 360, 0.08, GOLD)
        part(o, (0.2, 0.2, 0.2), (-1.35, 0.32, 0.03), (45, 45, 0), (180, 220, 250), "B", 3)
        shaft(o, -1.15, 0.6, 0.09, 6)
        for x in (0.25, 0.45):
            part(o, (0.1, 0.16, 0.06), (x, -0.1, 0), colour="a", flags=0)
        spike(o, 0.6, 0.06)

    @shape("lighthouse")
    def _(o):
        dias = [0.42, 0.4, 0.37, 0.34, 0.31, 0.28]
        for i, d in enumerate(dias):
            part(o, (0.2, d, d), (-1.45 + i * 0.19, 0, 0), colour=RED if i % 2 else (244, 244, 244), kind="C")
        part(o, (0.12, 0.46, 0.46), (-1.6, 0, 0), colour=DARK, kind="C")
        part(o, (0.2, 0.26, 0.26), (-0.27, 0, 0), colour=(255, 236, 140), kind="C")
        for k in range(4):
            part(o, (0.08, 0.3 * (1 - k / 4), 0.3 * (1 - k / 4)), (-0.13 + k * 0.06, 0, 0), colour=RED, kind="C")
        for s in (-1, 1):
            for a in (25, 50):
                part(o, (0.3, 0.04, 0.03), (-0.25, s * 0.38, 0), (0, 0, s * a), (255, 226, 110), "B", 3)
        spike(o, 0.08, 0.05)

    for n in ("corn", "rollingpin", "broom", "trowel", "wheat", "milkbottle", "awl", "horseshoe", "wateringcan", "sunflower", "woodenspoon",
              "chopsticks", "whisk", "crayon", "spool", "partyhorn", "straw", "spinningtop", "toothbrush", "woodsword"):
        GRADES[n] = "fancy"
    for n in ("pinecone", "cactus", "raindrop", "snowflake", "volcano", "tornado", "mushroom", "coral", "seashell",
              "unicorn", "stingray", "woodpecker", "dragonfly", "seahorse", "hedgehog", "beetle", "scorpion", "sharkfin", "snail"):
        GRADES[n] = "exotic"
    for n in ("cometgem", "planet", "phoenixfeather", "sceptre", "trident", "hourglass", "rainbowarrow", "moonwand", "treasurekey", "lighthouse"):
        GRADES[n] = "masterwork"
