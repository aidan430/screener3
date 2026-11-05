"""Draws a 512x512 icon for each Robux item (game passes and developer products): a warm
round badge with a simple symbol, in the game's farm colours. Original art."""
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = "/home/user/screener3/assets/marketing/robux"
FONT = ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Black.otf", 120)
S = 512
GOLD, HAY, WOOD, CREAM, INK = (255, 206, 70), (242, 196, 82), (122, 78, 44), (255, 246, 226), (70, 40, 20)

def badge(top, bottom):
    img = Image.new("RGB", (S, S))
    d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / S
        d.line([(0, y), (S, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    ring = Image.new("L", (S, S), 0)
    ImageDraw.Draw(ring).ellipse([18, 18, S - 18, S - 18], outline=255, width=14)
    img.paste((255, 240, 200), (0, 0), ring.filter(ImageFilter.GaussianBlur(1)))
    return img, ImageDraw.Draw(img)

def label(d, text, y=360, size=120, fill=CREAM):
    f = FONT.font_variant(size=size)
    w = d.textlength(text, font=f)
    d.text(((S - w) / 2, y), text, font=f, fill=fill, stroke_width=10, stroke_fill=INK)

def star(d, cx, cy, r, fill):
    pts = []
    for i in range(10):
        a = math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + math.cos(a) * rr, cy - math.sin(a) * rr))
    d.polygon(pts, fill=fill, outline=INK, width=8)

def coin(d, cx, cy, r):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD, outline=INK, width=10)
    d.ellipse([cx - r * 0.7, cy - r * 0.7, cx + r * 0.7, cy + r * 0.7], outline=(200, 140, 30), width=8)

def haystack(d, cx, base, r, h):
    pts = [(cx + math.cos(math.radians(a)) * r, base - math.sin(math.radians(a)) ** 0.75 * h) for a in range(0, 181, 6)]
    d.polygon(pts, fill=HAY, outline=INK)
    d.line(pts, fill=INK, width=10)
    for i in range(-3, 4):
        d.line([(cx + i * r * 0.22, base - 8), (cx + i * r * 0.18, base - h * 0.55)], fill=(200, 150, 60), width=6)

def bolt(d, cx, cy, s):
    pts = [(cx + 0.1 * s, cy - s), (cx - 0.45 * s, cy + 0.1 * s), (cx - 0.05 * s, cy + 0.1 * s), (cx - 0.2 * s, cy + s), (cx + 0.45 * s, cy - 0.15 * s), (cx + 0.05 * s, cy - 0.15 * s)]
    d.polygon(pts, fill=GOLD, outline=INK, width=10)

def gear(d, cx, cy, r, fill):
    pts = []
    for i in range(32):
        a = i * math.pi / 16
        rr = r if (i // 2) % 2 == 0 else r * 0.78
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.polygon(pts, fill=fill, outline=INK, width=8)
    d.ellipse([cx - r * 0.3, cy - r * 0.3, cx + r * 0.3, cy + r * 0.3], fill=(90, 90, 100), outline=INK, width=8)

icons = {}

img, d = badge((250, 200, 80), (214, 120, 40))  # VIP: a crown
d.polygon([(110, 330), (130, 170), (190, 250), (256, 140), (322, 250), (382, 170), (402, 330)], fill=GOLD, outline=INK, width=12)
d.rectangle([110, 320, 402, 360], fill=(230, 170, 40), outline=INK, width=10)
for x in (190, 256, 322):
    d.ellipse([x - 16, 324, x + 16, 356], fill=(196, 72, 56), outline=INK, width=4)
label(d, "VIP", 365, 110)
icons["vip"] = img

img, d = badge((140, 190, 110), (70, 120, 70))  # Auto Sell: hay flying into a basket
d.polygon([(130, 270), (382, 270), (350, 420), (162, 420)], fill=(170, 116, 62), outline=INK, width=12)
for y in (310, 350, 390):
    d.line([(150, y), (362, y)], fill=(120, 76, 40), width=6)
d.ellipse([170, 210, 342, 300], fill=HAY, outline=INK, width=10)
d.line([(256, 90), (256, 190)], fill=CREAM, width=26)
d.polygon([(210, 175), (302, 175), (256, 230)], fill=CREAM, outline=INK, width=6)
label(d, "AUTO", 40, 90)
icons["autosell"] = img

img, d = badge((150, 170, 200), (70, 80, 110))  # Double Machines: two gears
gear(d, 200, 230, 110, (200, 205, 215))
gear(d, 330, 300, 80, (245, 160, 40))
label(d, "2x", 360, 130)
icons["doublemachines"] = img

img, d = badge((120, 180, 240), (60, 100, 180))  # Jetpack: a pack with two flames
d.rounded_rectangle([170, 110, 342, 330], 40, fill=(196, 72, 56), outline=INK, width=12)
d.rounded_rectangle([200, 140, 312, 200], 16, fill=(240, 220, 200), outline=INK, width=8)
for x in (205, 307):
    d.polygon([(x - 34, 330), (x + 34, 330), (x, 450)], fill=(255, 170, 60), outline=INK, width=8)
    d.polygon([(x - 16, 340), (x + 16, 340), (x, 410)], fill=(255, 240, 150))
icons["jetpack"] = img

img, d = badge((255, 220, 120), (240, 140, 50))  # Speed Boost: lightning
bolt(d, 256, 220, 150)
label(d, "2x", 360, 130)
icons["speedboost"] = img

img, d = badge((255, 225, 120), (210, 150, 40))  # Coin Boost: a stack of coins
for i, (x, y) in enumerate([(200, 250), (312, 250), (256, 175)]):
    coin(d, x, y, 85)
label(d, "2x", 360, 130)
icons["coinboost"] = img

img, d = badge((150, 220, 140), (60, 140, 70))  # Lucky Charm: a four-leaf clover
for a in range(4):
    ang = math.radians(45 + a * 90)
    cx, cy = 256 + math.cos(ang) * 70, 220 + math.sin(ang) * 70
    d.ellipse([cx - 75, cy - 75, cx + 75, cy + 75], fill=(90, 190, 90), outline=INK, width=10)
d.line([(256, 240), (300, 420)], fill=(60, 120, 50), width=22)
star(d, 400, 110, 50, GOLD)
icons["luckycharm"] = img

img, d = badge((255, 210, 140), (220, 110, 60))  # Straw Blast: a haystack bursting
haystack(d, 256, 430, 170, 200)
for i in range(12):
    a = math.radians(20 + i * 12)
    x0, y0 = 256 + math.cos(a) * 120, 250 - math.sin(a) * 110
    d.line([(x0, y0), (x0 + math.cos(a) * 90, y0 - math.sin(a) * 90)], fill=(255, 236, 160), width=12)
star(d, 256, 120, 60, (255, 240, 200))
icons["strawblast"] = img

img, d = badge((200, 230, 250), (90, 150, 200))  # Merchant's Whistle
d.rounded_rectangle([110, 200, 330, 320], 60, fill=(220, 200, 90), outline=INK, width=12)
d.rectangle([300, 215, 420, 265], fill=(220, 200, 90), outline=INK, width=12)
d.ellipse([150, 230, 210, 290], fill=(90, 70, 40))
for i, r in enumerate((60, 100)):
    d.arc([380 - r, 120 - r, 380 + r, 120 + r], 200, 290, fill=CREAM, width=12)
label(d, "x10", 360, 120)
icons["whistle"] = img

img, d = badge((240, 180, 220), (140, 80, 170))  # Wheel Spin: a colourful wheel
cols = [(196, 72, 56), (245, 200, 66), (90, 170, 90), (70, 130, 200), (240, 140, 50), (150, 90, 200)]
for i in range(12):
    d.pieslice([96, 86, 416, 406], i * 30, (i + 1) * 30, fill=cols[i % 6], outline=INK, width=6)
d.ellipse([226, 216, 286, 276], fill=CREAM, outline=INK, width=8)
d.polygon([(236, 60), (276, 60), (256, 110)], fill=CREAM, outline=INK, width=8)
icons["wheelspin"] = img

for name, im in icons.items():
    im.save(f"{OUT}/{name}.png")
sheet = Image.new("RGB", (5 * 260, 2 * 260), (255, 255, 255))
for i, im in enumerate(icons.values()):
    sheet.paste(im.resize((250, 250)), ((i % 5) * 260 + 5, (i // 5) * 260 + 5))
sheet.save("/tmp/claude-0/-home-user-screener3/58693bae-13a9-5ef3-95b8-b9e36f9effe2/scratchpad/robux_sheet.png")
print("ok", len(icons))
