import json
from PIL import Image, ImageDraw, ImageFont
D = json.load(open("needles.json"))
B = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf", s)
R = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Regular.otf", s)
PANEL, CARD, LINE, TEXT, SOFT, GOLD, BLUE = (24, 28, 38), (38, 44, 58), (70, 78, 96), (240, 242, 248), (168, 176, 196), (255, 200, 70), (90, 150, 240)
rar = {r["id"]: r for r in D["rarities"]}
W, H = 1280, 720
def panel(im, box, r=16, alpha=0.95, outline=LINE, width=2):
    lay = Image.new("RGBA", im.size); ImageDraw.Draw(lay).rounded_rectangle(box, r, fill=PANEL + (int(255 * alpha),), outline=outline, width=width); im.alpha_composite(lay)
def button(d, box, text, colour, size=16):
    d.rounded_rectangle(box, 9, fill=colour); d.text(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2), text, font=B(size), fill=(255, 255, 255), anchor="mm")

# the Collection screen
im = Image.open("lobby_aerial.png").convert("RGBA").resize((W, H))
cx, cy, ww, wh = W / 2, H * 0.57, 760, 560
x0, y0 = cx - ww / 2, cy - wh / 2
panel(im, (x0, y0, x0 + ww, y0 + wh))
d = ImageDraw.Draw(im)
d.text((x0 + 22, y0 + 34), "Collection", font=B(30), fill=TEXT, anchor="lm")
button(d, (x0 + ww - 58, y0 + 14, x0 + ww - 14, y0 + 54), "X", CARD)
bx = x0 + 18
for name, val, on in [("You · 2,418", 1, True), ("StrawBossMax · 5,906", 0, False), ("Clover_99 · 1,120", 0, False)]:
    button(d, (bx, y0 + 66, bx + 176, y0 + 104), name, GOLD if on else CARD); bx += 182
d.text((x0 + 18, y0 + 128), "Your collection:  2,418 value  ·  41 / 384 needles", font=B(20), fill=GOLD, anchor="lm")
d.text((x0 + 18, y0 + 152), "On show: Aurora Darning Needle  (click any needle you own to show it instead)", font=R(15), fill=SOFT, anchor="lm")
bx = x0 + 18
for t, have, on in [("Sewing Needle 9/32", 0, False), ("Dressmaker's Pin 7/32", 0, False), ("Quilting Needle 4/32", 0, False), ("Darning Needle 11/32", 0, True)]:
    button(d, (bx, y0 + 168, bx + 172, y0 + 206), t, BLUE if on else CARD, 14); bx += 178
owned = {"steel": 3, "iron": 1, "brass": 2, "copper": 1, "bone": 1, "pewter": 1, "rosegold": 1, "jade": 2, "mint": 1, "bumblebee": 1, "aurora": 1}
gx, gy, cwid, chei = x0 + 18, y0 + 218, 132, 150
for i, s in enumerate(D["skins"][:15]):
    if s["id"] == "ink":
        pass
    col, row = i % 5, i // 5
    x, y = gx + col * (cwid + 8), gy + row * (chei + 8)
    if y + chei > y0 + wh - 10:
        break
    r = rar[s["rarity"]]
    on = s["id"] in owned
    d.rounded_rectangle((x, y, x + cwid, y + chei), 10, fill=CARD, outline=tuple(int(c) for c in r["colour"]), width=3 if s["id"] == "aurora" else 2)
    if on:
        n = Image.open(f"needles/darning_{s['id']}.png").convert("RGBA").resize((cwid - 8, int((cwid - 8) * 220 / 360)), Image.LANCZOS)
        im.alpha_composite(n, (int(x + 4), int(y + 6))); d = ImageDraw.Draw(im)
        d.text((x + cwid / 2, y + 100), s["name"] + (f"  x{owned[s['id']]}" if owned[s["id"]] > 1 else ""), font=B(15), fill=TEXT, anchor="mm")
        d.text((x + cwid / 2, y + 122), f"{r['name']} · {int(14 * r['mult'])}", font=R(13), fill=tuple(int(c) for c in r["colour"]), anchor="mm")
    else:
        d.text((x + cwid / 2, y + 50), "???", font=B(34), fill=LINE, anchor="mm")
        d.text((x + cwid / 2, y + 122), r["name"], font=R(13), fill=tuple(int(c) for c in r["colour"]), anchor="mm")
im.convert("RGB").save("ui_collection.png")

# the reveal: NEEDLE FOUND! with the needle you keep
im = Image.open("barn_needle.png").convert("RGBA").resize((W, H))
im.alpha_composite(Image.new("RGBA", im.size, (255, 255, 255, 50)))
cx, cy = W / 2, H * 0.42
panel(im, (cx - 280, cy - 150, cx + 280, cy + 150), r=22, alpha=0.96, outline=GOLD, width=3)
n = Image.open("needles/knitting_candycane.png").convert("RGBA").resize((330, 202), Image.LANCZOS)
im.alpha_composite(n, (int(cx - 165), int(cy - 160)))
d = ImageDraw.Draw(im)
d.text((cx, cy + 6), "NEEDLE FOUND!", font=B(50), fill=GOLD, anchor="mm")
r = rar["epic"]
d.text((cx, cy + 50), "NEW!  Epic Candy Cane Knitting Needle", font=B(24), fill=tuple(int(c) for c in r["colour"]), anchor="mm")
d.text((cx, cy + 86), "1st  ·  37.4 s  ·  +118 coins  ·  +139 XP", font=R(20), fill=TEXT, anchor="mm")
d.text((cx, cy + 120), "It's yours to keep: worth 264 in your Collection.", font=R(17), fill=SOFT, anchor="mm")
im.convert("RGB").save("ui_reveal.png")
print("ok")
