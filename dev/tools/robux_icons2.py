"""Icons for the Robux passes added later (Super Tool, Hay Tornado, Rainbow Hay, Sparkle Trail),
in the same style as robux_icons.py."""
import math, sys
sys.path.insert(0, "/home/user/screener3/dev/tools")
from robux_icons import badge, label, star, haystack, OUT, GOLD, HAY, INK, CREAM

img, d = badge((255, 225, 120), (210, 140, 40))  # Super Tool: a glowing golden fork
d.line([(170, 400), (330, 150)], fill=(150, 104, 58), width=26)
d.line([(170, 400), (330, 150)], fill=INK, width=6)
for i, (dx, dy) in enumerate([(-34, -22), (0, 0), (34, 22)]):
    x0, y0 = 330 + dx, 150 + dy
    d.line([(x0, y0), (x0 + 50, y0 - 78)], fill=GOLD, width=16)
d.line([(296, 128), (364, 172)], fill=GOLD, width=18)
for s, (x, y) in [(40, (150, 150)), (28, (390, 330)), (22, (120, 300))]:
    star(d, x, y, s, (255, 245, 200))
label(d, "SUPER", 380, 92)
img.save(f"{OUT}/supertool.png")

img, d = badge((200, 220, 240), (110, 140, 180))  # Hay Tornado: a swirl lifting hay
for i in range(9):
    w = 60 + i * 26
    y = 380 - i * 32
    d.ellipse([256 - w / 2, y - 14, 256 + w / 2, y + 14], outline=(245, 230, 170), width=12)
    d.ellipse([256 - w / 2, y - 14, 256 + w / 2, y + 14], outline=INK, width=3)
for x, y in [(150, 120), (360, 150), (330, 90), (180, 200)]:
    d.ellipse([x - 14, y - 9, x + 14, y + 9], fill=HAY, outline=INK, width=4)
icons = img.save(f"{OUT}/haytornado.png")

img, d = badge((150, 200, 250), (90, 120, 200))  # Rainbow Hay: a rainbow over a haystack
cols = [(230, 70, 60), (245, 150, 50), (245, 215, 60), (90, 190, 90), (70, 140, 220), (150, 90, 210)]
for i, c in enumerate(cols):
    r = 190 - i * 18
    d.arc([256 - r, 300 - r, 256 + r, 300 + r], 180, 360, fill=c, width=18)
haystack(d, 256, 430, 130, 150)
img.save(f"{OUT}/rainbowhay.png")

img, d = badge((250, 200, 230), (170, 90, 160))  # Sparkle Trail: a curving trail of stars
pts = [(110 + t * 300, 380 - math.sin(t * math.pi) * 220) for t in [i / 30 for i in range(31)]]
d.line(pts, fill=(255, 226, 140), width=22)
d.line(pts, fill=(255, 250, 220), width=8)
for (x, y), s in zip(pts[::6], (24, 32, 40, 48, 56, 60)):
    star(d, x, y, s, (255, 236, 160))
img.save(f"{OUT}/sparkletrail.png")
print("ok")
