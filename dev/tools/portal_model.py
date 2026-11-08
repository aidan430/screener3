"""Writes assets/portal/Portal.rbxmx: the built-in moon-gate portal (server/WorldsPortal.luau's
numbers) as a Studio model the owner can open, change and use as their own portal design.
In Studio: right-click ServerStorage > Designs > Insert from File... and pick Portal.rbxmx.
Run: python3 dev/tools/portal_model.py"""
import math, os
from xml.sax.saxutils import escape

RADIUS, FLOOR = 5.6, 1.1
CENTRE = FLOOR + RADIUS - 1.2
STONE, STONE2, WOOD, GOLD, DARK = (84, 78, 92), (104, 98, 110), (92, 66, 44), (242, 196, 82), (40, 34, 48)
MATERIAL = {"Slate": 800, "Neon": 288, "Wood": 512, "SmoothPlastic": 272}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}


def rx(t): c, s = math.cos(t), math.sin(t); return [[1, 0, 0], [0, c, -s], [0, s, c]]
def ry(t): c, s = math.cos(t), math.sin(t); return [[c, 0, s], [0, 1, 0], [-s, 0, c]]
def rz(t): c, s = math.cos(t), math.sin(t); return [[c, -s, 0], [s, c, 0], [0, 0, 1]]
def mul(a, b): return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
I = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]


class CF:
    """Just enough CFrame: position + rotation, composed the way Roblox composes them."""
    def __init__(self, p=(0, 0, 0), r=I): self.p, self.r = list(p), r
    def __mul__(self, o): return CF([sum(self.r[i][k] * o.p[k] for k in range(3)) + self.p[i] for i in range(3)], mul(self.r, o.r))


def at(x, y, z): return CF((x, y, z))
def angles(x, y, z): return CF((0, 0, 0), mul(mul(rx(x), ry(y)), rz(z)))


parts = []
def part(name, size, cf, colour, material="Slate", shape="Block", transparency=0.0, collide=True):
    parts.append((name, size, cf, colour, material, shape, transparency, collide))


UPRIGHT = angles(0, 0, math.radians(90))
part("Base", (2, 0.2, 2), at(0, 0.1, 0), (255, 255, 255), "SmoothPlastic", transparency=0.5, collide=False)
part("Step", (0.6, 16, 16), at(0, 0.3, 0) * UPRIGHT, STONE, shape="Cylinder")
part("Step", (0.5, 13, 13), at(0, 0.85, 0) * UPRIGHT, STONE2, shape="Cylinder")
centre = at(0, CENTRE, 0)
def ring(radius, count, thick, depth, name, colour_of, material, transparency=0.0):
    length = 2 * radius * math.tan(math.pi / count) + thick * 0.5
    for i in range(count):
        a = (i + 0.5) / count * math.pi * 2
        y = radius * math.sin(a)
        if CENTRE + y > FLOOR - 0.2:
            part(name, (thick, length, depth), centre * at(radius * math.cos(a), y, 0) * angles(0, 0, a), colour_of(i), material, transparency=transparency, collide=material != "Neon")
ring(RADIUS, 22, 1.5, 1.8, "Stone", lambda i: STONE if i % 2 == 0 else STONE2, "Slate")
ring(RADIUS - 0.82, 28, 0.2, 0.6, "GlowLip", lambda i: GOLD, "Neon", 0.15)
opening = 2 * (RADIUS - 0.9)
part("Opening", (0.2, opening, opening), centre * angles(0, math.radians(90), 0), GOLD, "Neon", "Cylinder", 0.55, False)
part("GlowGem", (1.4, 1.8, 1.4), centre * at(0, RADIUS + 0.9, 0) * angles(0, math.radians(45), 0), GOLD, "Neon")
for x in (-6.6, 6.6):
    part("Post", (0.4, 3.2, 0.4), at(x, FLOOR + 1.6, -2.6), WOOD, "Wood")
    part("GlowLantern", (0.8, 0.9, 0.8), at(x, FLOOR + 3.6, -2.6), GOLD, "Neon", collide=False)
    part("LanternCap", (1, 0.2, 1), at(x, FLOOR + 4.15, -2.6), WOOD, "Wood")
part("Sign", (11, 3.2, 0.4), at(0, CENTRE + RADIUS + 3.4, 0), DARK, "Slate")


def item(ref, name, size, cf, colour, material, shape, transparency, collide):
    r, p = cf.r, cf.p
    rgb = (255 << 24) | (colour[0] << 16) | (colour[1] << 8) | colour[2]
    cframe = "".join(f"<{k}>{v:.5f}</{k}>" for k, v in zip(["X", "Y", "Z"], p)) + "".join(f"<R{i}{j}>{r[i][j]:.6f}</R{i}{j}>" for i in range(3) for j in range(3))
    return (f'\t\t<Item class="Part" referent="RBX{ref}"><Properties>'
            f'<string name="Name">{escape(name)}</string><bool name="Anchored">true</bool>'
            f'<bool name="CanCollide">{"true" if collide else "false"}</bool>'
            f'<CoordinateFrame name="CFrame">{cframe}</CoordinateFrame>'
            f'<Color3uint8 name="Color3uint8">{rgb}</Color3uint8>'
            f'<token name="Material">{MATERIAL[material]}</token><token name="shape">{SHAPE[shape]}</token>'
            f'<Vector3 name="size"><X>{size[0]}</X><Y>{size[1]}</Y><Z>{size[2]}</Z></Vector3>'
            f'<float name="Transparency">{transparency}</float>'
            f'<token name="TopSurface">0</token><token name="BottomSurface">0</token>'
            f'</Properties></Item>')


body = "\n".join(item(i + 1, *p) for i, p in enumerate(parts))
xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">\n'
       '\t<Item class="Model" referent="RBX0"><Properties><string name="Name">Portal</string></Properties>\n'
       + body + '\n\t</Item>\n</roblox>\n')
out = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "portal", "Portal.rbxmx")
open(out, "w").write(xml)
print("wrote", os.path.normpath(out), len(parts), "parts")
