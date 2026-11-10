"""The needle shapes kept as data. Run after changing a shape:

    python3 needle-hunt/dev/shapes.py

It writes src/shared/ShapesA.luau and ShapesB.luau (read by shared/NeedleLook) and
dev/preview/shapes_data.js (the same shapes for the preview pages), so the game and the
previews always draw the same thing.

A needle lies along X: the eye end at -X, the point at +X, about -1.7 to 1.6. Each shape is a list
of ops:
    shaft(x0, x1, d, n, y)       a patterned shaft in n segments (the skin's pattern runs along it)
    tip(x, d, steps)             a tapering point
    part(size, pos, turn, colour, kind, flags)
        size (x, y, z); pos (x, y, z); turn (x, y, z) in degrees
        colour: "a" the skin's accent, "c<i>/<n>" the skin's pattern at step i of n, or (r, g, b)
        kind: "B" block, "C" cylinder (along X), "S" ball
        flags: 1 = keep its place (not spread out when the needle is drawn thick), 2 = keep its
               size (a fin stays a fin), 3 = both
"""
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OPS: dict[str, list] = {}


def shape(name):
    def wrap(fn):
        ops: list = []
        fn(ops)
        OPS[name] = ops
        return fn
    return wrap


def r(v):
    return round(v, 3)


def shaft(ops, x0, x1, d, n, y=0):
    ops.append(["s", r(x0), r(x1), r(d), n, r(y)])


def tip(ops, x, d, steps):
    ops.append(["t", r(x), r(d), steps])


def part(ops, size, pos, turn=(0, 0, 0), colour="a", kind="B", flags=0):
    ops.append(["p", *[r(v) for v in size], *[r(v) for v in pos], *[r(v) for v in turn], list(colour) if isinstance(colour, tuple) else colour, kind, flags])


def segments(ops, x0, x1, dias, kind="C", y=0, flags=0, squash=1.0, colours=None):
    """A row of cylinders from x0 to x1 with the given diameters, coloured along the pattern."""
    n = len(dias)
    step = (x1 - x0) / n
    for i, d in enumerate(dias, 1):
        c = colours[i - 1] if colours else f"c{i}/{n}"
        part(ops, (step + 0.01, d, d * squash), (x0 + (i - 0.5) * step, y, 0), colour=c, kind=kind, flags=flags)


def bar(ops, a, b, thick, depth, colour="a", flags=3):
    """A flat bar from point a to point b (x, y), in the needle's own plane."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy)
    part(ops, (length + 0.02, thick, depth), ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, 0), (0, 0, math.degrees(math.atan2(dy, dx))), colour, "B", flags)


def star(ops, cx, cy, arm, thick, colour="a"):
    for k in range(5):
        a = math.radians(90 + k * 72)
        part(ops, (arm, thick, 0.06), (cx + math.cos(a) * arm / 2, cy + math.sin(a) * arm / 2, 0), (0, 0, math.degrees(a)), colour, "B", 3)
    part(ops, (thick * 1.6,) * 3, (cx, cy, 0), colour=colour, kind="S", flags=3)


WOOD, DARK, METAL, GREEN, WHITE = (222, 184, 135), (40, 40, 48), (190, 192, 204), (86, 164, 74), (246, 246, 246)
FLAME = [(255, 140, 40), (255, 190, 60), (255, 230, 120), (255, 250, 215)]


# ---------- Fancy ----------
@shape("pencil")
def _(o):
    for turn in (0, 45):  # two square blocks at 45 degrees make the eight-sided body
        for i in range(6):
            part(o, (0.33, 0.22, 0.22), (-1.12 + (i + 0.5) * 0.31, 0, 0), (turn, 0, 0), f"c{i + 1}/6")
    for k in range(1, 6):  # the sharpened wood
        part(o, (0.1, 0.24 * (1 - k / 6), 0.24 * (1 - k / 6)), (0.72 + k * 0.09, 0, 0), colour=WOOD, kind="C")
    part(o, (0.07, 0.05, 0.05), (1.27, 0, 0), colour=DARK, kind="C")
    part(o, (0.07, 0.025, 0.025), (1.33, 0, 0), colour=DARK, kind="C")
    part(o, (0.14, 0.25, 0.25), (-1.2, 0, 0), colour=METAL, kind="C")  # the metal band
    part(o, (0.22, 0.23, 0.23), (-1.38, 0, 0), colour=(240, 140, 160), kind="C")  # the eraser


@shape("candle")
def _(o):
    segments(o, -1.5, 0.55, [0.22] * 6)
    part(o, (0.08, 0.27, 0.27), (0.52, 0, 0), colour="c6/6", kind="C")  # the melted rim
    for x in (0.3, -0.05):  # wax running down, hugging the side
        part(o, (0.2, 0.05, 0.05), (x, 0.11, 0.06), colour="c6/6", kind="C")
    part(o, (0.14, 0.03, 0.03), (0.68, 0, 0), colour=DARK, kind="C")  # the wick
    for k, (d, x) in enumerate(((0.2, 0.84), (0.15, 0.97), (0.1, 1.08), (0.05, 1.17))):  # the flame is the point
        part(o, (d, d, d), (x, 0, 0), colour=FLAME[k], kind="S", flags=2)


@shape("wand")
def _(o):
    segments(o, -1.5, 0.85, [0.13 - k * 0.008 for k in range(8)])
    for k in range(6):  # a ribbon wound round the handle
        part(o, (0.12, 0.05, 0.02), (-1.4 + k * 0.11, 0.07 if k % 2 == 0 else -0.07, 0.02), (0, 0, 35 if k % 2 == 0 else -35), "a", "B", 1)
    star(o, 1.08, 0, 0.28, 0.09)


@shape("paintbrush")
def _(o):
    segments(o, -1.6, 0.2, [0.1, 0.11, 0.12, 0.13, 0.15, 0.16])
    part(o, (0.36, 0.18, 0.18), (0.38, 0, 0), colour=METAL, kind="C")  # the ferrule
    bristles = [0.2, 0.19, 0.17, 0.14, 0.11, 0.08, 0.05, 0.03]
    for k, d in enumerate(bristles):
        part(o, (0.1, d, d), (0.61 + k * 0.09, 0, 0), colour=(214, 184, 134) if k < 5 else "a", kind="C")


@shape("lollipop")
def _(o):
    shaft(o, -0.9, 1.4, 0.05, 6)
    tip(o, 1.4, 0.05, 2)
    for k, (d, c) in enumerate(((0.75, "c1/2"), (0.58, "c2/2"), (0.42, "c1/2"), (0.26, "c2/2"), (0.11, "c1/2"))):
        part(o, (0.1 + k * 0.012, d, d), (-1.32, 0, k * 0.012), (0, 90, 0), c, "C", 3)  # the swirl, rings stacked front to back


@shape("fork")
def _(o):
    segments(o, -1.6, 0.1, [0.15] * 6, kind="B", squash=0.35)
    part(o, (0.25, 0.1, 0.05), (0.22, 0, 0), colour="c6/6")  # the neck
    part(o, (0.22, 0.4, 0.05), (0.43, 0, 0), colour="a")  # the head
    shaft(o, 0.5, 1.45, 0.05, 4)  # the middle prong is the needle
    tip(o, 1.45, 0.05, 2)
    for s in (-1, 1):
        part(o, (0.75, 0.05, 0.05), (0.9, s * 0.15, 0), colour="a")


@shape("umbrella")
def _(o):
    segments(o, -0.6, 1.0, [0.2, 0.3, 0.36, 0.36, 0.32, 0.26, 0.19, 0.12])
    part(o, (0.5, 0.04, 0.04), (1.25, 0, 0), colour=METAL, kind="C")  # the ferrule
    tip(o, 1.5, 0.04, 2)
    part(o, (0.6, 0.06, 0.06), (-0.9, 0, 0), colour=DARK, kind="C")
    for k in range(6):  # the hook handle: a half circle opening forwards
        a1, a2 = math.radians(90 + k * 30), math.radians(90 + (k + 1) * 30)
        cx, cy, rr = -1.2, -0.17, 0.17
        bar(o, (cx + math.cos(a1) * rr, cy + math.sin(a1) * rr), (cx + math.cos(a2) * rr, cy + math.sin(a2) * rr), 0.07, 0.07, (96, 64, 42), 1)


@shape("carrot")
def _(o):
    segments(o, -1.0, 1.35, [0.4, 0.38, 0.34, 0.3, 0.25, 0.2, 0.15, 0.1, 0.06])
    tip(o, 1.35, 0.06, 2)
    for k, a in enumerate((150, 165, 180, 195, 210)):  # the leafy top, fanning out
        rad = math.radians(a)
        part(o, (0.55, 0.1, 0.03), (-1.05 + math.cos(rad) * 0.3, math.sin(rad) * 0.3, 0), (0, 0, a), GREEN if k % 2 == 0 else (110, 190, 90), "B", 3)


@shape("pitchfork")
def _(o):
    shaft(o, -1.65, 0.4, 0.09, 7)
    part(o, (0.12, 0.6, 0.08), (0.45, 0, 0), colour="a", flags=1)  # the crossbar
    shaft(o, 0.45, 1.45, 0.05, 4)
    tip(o, 1.45, 0.05, 2)
    for s in (-1, 1):
        part(o, (0.8, 0.05, 0.05), (0.88, s * 0.26, 0), colour="a", kind="C", flags=1)
        part(o, (0.1, 0.03, 0.03), (1.32, s * 0.26, 0), colour="a", kind="C", flags=1)


@shape("icecream")
def _(o):
    cone = [0.6, 0.53, 0.46, 0.39, 0.32, 0.25, 0.18, 0.11, 0.05]
    for k, d in enumerate(cone):  # the waffle cone, its point first
        part(o, (0.2, d, d), (-0.3 + (k + 0.5) * 0.19, 0, 0), colour=(222, 172, 104) if k % 2 == 0 else (196, 146, 82), kind="C", flags=2)
    for k, (d, x) in enumerate(((0.7, -0.55), (0.6, -1.0), (0.5, -1.38))):
        part(o, (d, d, d), (x, 0, 0), colour=f"c{k + 1}/3", kind="S", flags=3)  # three scoops
    part(o, (0.2, 0.2, 0.2), (-1.68, 0, 0), colour=(220, 30, 50), kind="S", flags=3)  # a cherry on top


# ---------- Exotic ----------
@shape("narwhal")
def _(o):
    segments(o, 0.25, 1.5, [0.1 - k * 0.008 for k in range(9)])  # the spiral tusk is the needle
    tip(o, 1.5, 0.03, 2)
    segments(o, -1.45, 0.25, [0.16, 0.3, 0.42, 0.48, 0.48, 0.42, 0.3], squash=0.85, colours=["a"] * 7)
    for s in (-1, 1):
        part(o, (0.42, 0.15, 0.03), (-1.58, s * 0.18, 0), (0, 0, s * 40), "a", "B", 3)  # the tail fluke
    part(o, (0.26, 0.09, 0.03), (-0.4, -0.26, 0.05), (0, 0, -30), "a", "B", 3)  # a flipper
    part(o, (0.07, 0.07, 0.07), (0.05, 0.08, 0.2), colour=DARK, kind="S", flags=1)


@shape("hummingbird")
def _(o):
    shaft(o, 0.36, 1.5, 0.04, 5)  # the long beak is the needle
    tip(o, 1.5, 0.04, 2)
    part(o, (0.28, 0.28, 0.28), (0.24, 0.02, 0), colour="c1/3", kind="S")
    segments(o, -0.9, 0.12, [0.18, 0.26, 0.3, 0.26], colours=["c2/3", "c2/3", "c3/3", "c3/3"])
    for s in (-1, 1):
        part(o, (0.42, 0.08, 0.02), (-1.08, s * 0.06, 0), (0, 0, s * 14), "a", "B", 3)  # tail feathers
    for k, (ln, a) in enumerate(((0.62, 62), (0.56, 78), (0.48, 94))):  # the wings, raised: three long feathers each
        part(o, (ln, 0.08, 0.02), (-0.38 - k * 0.06 + ln / 2 * math.cos(math.radians(a)), 0.12 + ln / 2 * math.sin(math.radians(a)), 0.03), (0, 0, a), "a", "B", 3)
    part(o, (0.06, 0.06, 0.06), (0.32, 0.07, 0.12), colour=DARK, kind="S", flags=1)


@shape("porcupine")
def _(o):
    shaft(o, -0.35, 1.5, 0.07, 7)  # one striped quill is the needle
    tip(o, 1.5, 0.07, 3)
    part(o, (0.62, 0.62, 0.62), (-0.95, 0, 0), colour=(120, 92, 70), kind="S", flags=3)
    for k in range(9):  # quills all round the back
        a = math.radians(40 + k * 18)
        cx, cy = -0.95 + math.cos(a) * 0.42, math.sin(a) * 0.42
        part(o, (0.34, 0.03, 0.03), (cx, cy, 0), (0, 0, math.degrees(a)), "a" if k % 2 else "c1/2", "C", 3)
    part(o, (0.14, 0.14, 0.14), (-0.62, -0.12, 0.05), colour=DARK, kind="S", flags=3)  # a nose


@shape("icicle")
def _(o):
    dias = [0.2, 0.24, 0.15, 0.2, 0.12, 0.16, 0.09, 0.11, 0.06, 0.05]  # jagged: thick, thin, thick
    for turn in (0, 45):
        for i, d in enumerate(dias):
            part(o, (0.29, d, d), (-1.45 + (i + 0.5) * 0.28, 0, 0), (turn, 0, 0), f"c{i + 1}/10")
    tip(o, 1.35, 0.05, 2)
    for x, y, a, ln in ((-1.1, 0.12, 120, 0.3), (-0.6, -0.1, -110, 0.24), (-0.1, 0.08, 110, 0.18)):  # drips of ice hanging off
        part(o, (ln, 0.05, 0.05), (x, y, 0), (0, 0, a), "a", "B", 3)
    part(o, (0.12, 0.34, 0.3), (-1.55, 0, 0), colour="a", kind="B")  # where it broke off the roof


@shape("thornyrose")
def _(o):
    shaft(o, -0.95, 1.5, 0.06, 8)  # the stem is the needle
    tip(o, 1.5, 0.06, 2)
    for k, x in enumerate((-0.6, -0.1, 0.4, 0.9)):  # thorns
        s = 1 if k % 2 == 0 else -1
        part(o, (0.1, 0.05, 0.02), (x, s * 0.06, 0), (0, 0, s * 40), "c1/2", "B", 3)
    for s in (-1, 1):
        part(o, (0.32, 0.13, 0.02), (-0.45, s * 0.14, 0), (0, 0, s * 35), GREEN, "B", 3)  # leaves
    part(o, (0.44, 0.44, 0.44), (-1.12, 0, 0), colour="a", kind="S", flags=3)  # the bloom
    for k in range(5):
        a = math.radians(k * 72 + 18)
        part(o, (0.24, 0.24, 0.24), (-1.12 + math.cos(a) * 0.2, math.sin(a) * 0.2, 0.04), colour="a", kind="S", flags=3)
    part(o, (0.16, 0.16, 0.16), (-1.12, 0, 0.18), colour="c2/2", kind="S", flags=3)


# ---------- Masterwork ----------
@shape("lightning")
def _(o):
    pts = [(-1.55, 0.55), (-0.55, -0.1), (-0.75, 0.38), (0.35, -0.22), (0.12, 0.2), (1.55, -0.12)]
    thick = [0.34, 0.3, 0.26, 0.22, 0.14]
    for k in range(5):
        bar(o, pts[k], pts[k + 1], thick[k], 0.12, f"c{k + 1}/5", 3)
    tip(o, 1.55, 0.08, 2)


@shape("rocketship")
def _(o):
    segments(o, -0.9, 0.8, [0.42] * 5)
    for k in range(1, 6):  # the nose cone is the point
        f = 1 - k / 6
        part(o, (0.1, 0.42 * f, 0.42 * f), (0.82 + k * 0.09, 0, 0), colour="a", kind="C")
    for x in (-0.45, -0.05, 0.35):  # portholes along the top
        part(o, (0.04, 0.13, 0.13), (x, 0.21, 0), (0, 0, 90), (170, 220, 255), "C")
    for s in (-1, 1):
        part(o, (0.48, 0.42, 0.03), (-0.7, s * 0.5, 0), (0, 0, s * -35), "a", "B", 3)
    for k, (d, x) in enumerate(((0.32, -1.05), (0.24, -1.3), (0.16, -1.5), (0.09, -1.66))):  # the flame
        part(o, (d, d, d), (x, 0, 0), colour=FLAME[k], kind="S", flags=2)


@shape("cometspear")
def _(o):
    part(o, (0.34, 0.34, 0.34), (1.12, 0, 0), colour="a", kind="S", flags=2)  # the glowing head
    tip(o, 1.25, 0.12, 3)
    segments(o, -1.6, 0.98, [0.03 + 0.012 * k for k in range(9)])
    for s in (-1, 1):  # the split tail
        for k in range(6):
            x = 0.85 - k * 0.42
            part(o, (0.44, 0.04, 0.04), (x, s * (0.06 + k * 0.035), 0), (0, 0, s * 5), f"c{9 - k}/9", "C", 1)


@shape("dragontooth")
def _(o):
    cx, cy, rr = -0.1, -1.2, 1.5
    n = 8
    angles = [125 - i * (90 / n) for i in range(n + 1)]
    for i in range(n):  # the curved fang, thick at the root
        a1, a2 = math.radians(angles[i]), math.radians(angles[i + 1])
        p1, p2 = (cx + math.cos(a1) * rr, cy + math.sin(a1) * rr), (cx + math.cos(a2) * rr, cy + math.sin(a2) * rr)
        d = 0.3 - i * 0.032
        mid = ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
        ang = math.degrees(math.atan2(p2[1] - p1[1], p2[0] - p1[0]))
        part(o, (math.hypot(p2[0] - p1[0], p2[1] - p1[1]) + 0.02, d, d), (mid[0], mid[1], 0), (0, 0, ang), f"c{i + 1}/{n}", "C", 1)
    start = (cx + math.cos(math.radians(125)) * rr, cy + math.sin(math.radians(125)) * rr)
    dx, dy = math.cos(math.radians(35)), math.sin(math.radians(35))
    part(o, (0.6, 0.22, 0.22), (start[0] - dx * 0.33, start[1] - dy * 0.33, 0), (0, 0, 35), (236, 228, 206), "C", 1)  # bone handle
    for s in (-1, 1):
        part(o, (0.24, 0.24, 0.24), (start[0] - dx * 0.66 - s * dy * 0.09, start[1] - dy * 0.66 + s * dx * 0.09, 0), colour=(236, 228, 206), kind="S", flags=1)


@shape("crystalshard")
def _(o):
    prof = [0.18, 0.24, 0.26, 0.25, 0.22, 0.17, 0.11, 0.06]
    for turn in (0, 45):
        for i, d in enumerate(prof):
            part(o, (0.29, d, d), (-0.85 + (i + 0.5) * 0.28, 0, 0), (turn, 0, 0), f"c{i + 1}/8")
    tip(o, 1.4, 0.06, 2)
    for x, y, a, ln in ((-1.0, 0.28, 140, 0.6), (-1.05, -0.26, 220, 0.55), (-1.25, 0.05, 180, 0.5)):  # smaller crystals at the base
        part(o, (ln, 0.16, 0.16), (x, y, 0), (45, 0, a), "a", "B", 3)
    part(o, (0.5, 0.3, 0.3), (-1.3, 0, 0), colour=(100, 92, 112), kind="S", flags=3)


A = ["pencil", "candle", "wand", "paintbrush", "lollipop", "fork", "umbrella", "carrot", "pitchfork", "icecream"]


def luau(value) -> str:
    if isinstance(value, str):
        return f'"{value}"'
    if isinstance(value, list):
        return "{ " + ", ".join(luau(v) for v in value) + " }"
    return str(int(value)) if float(value).is_integer() else str(value)


def write(path: Path, names: list[str], title: str):
    lines = [f"-- {title}: needle shapes kept as data. Made by dev/shapes.py: change them there and run it.",
             "-- Each op: shaft { \"s\", x0, x1, d, n, y }, tip { \"t\", x, d, steps }, or one part",
             "-- { \"p\", size x/y/z, position x/y/z, turn x/y/z (degrees), colour, part, flags } (shared/NeedleLook).",
             "return {"]
    for name in names:
        lines.append(f"\t{name} = {{")
        ops = OPS[name]
        for i in range(0, len(ops), 2):  # two ops a line keeps the files short
            lines.append("\t\t" + " ".join(luau(op) + "," for op in ops[i:i + 2]))
        lines.append("\t},")
    lines.append("}")
    path.write_text("\n".join(lines) + "\n")
    return len(lines)


FILES = ["ShapesA", "ShapesB", "ShapesC", "ShapesD", "ShapesE", "ShapesF"]  # shared/NeedleLook reads these


if __name__ == "__main__":
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import shapes_more  # the owner's Gemini sheets, built
    shapes_more.add(sys.modules[__name__])
    import shapes_heirloom  # the Heirloom collection, the grade above Masterwork
    shapes_heirloom.add(sys.modules[__name__])
    names, sizes, part = list(OPS), [], 0
    while names:  # fill each file up to about 260 lines, so every one stays well under 300
        take, lines = [], 4
        while names and (not take or lines + 2 + (len(OPS[names[0]]) + 1) // 2 <= 260):
            lines += 2 + (len(OPS[names[0]]) + 1) // 2
            take.append(names.pop(0))
        sizes.append(write(ROOT / "src" / "shared" / (FILES[part] + ".luau"), take, f"Needle shapes, part {part + 1}"))
        part += 1
    for extra in FILES[part:]:
        (ROOT / "src" / "shared" / (extra + ".luau")).unlink(missing_ok=True)
    (ROOT / "dev" / "preview" / "shapes_data.js").write_text("window.SHAPES = " + json.dumps(OPS) + ";\n")
    print(f"{len(OPS)} shapes in {part} files: {sizes} lines")
