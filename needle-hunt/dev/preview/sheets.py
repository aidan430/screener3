import json
from PIL import Image, ImageDraw, ImageFont
D = json.load(open("needles.json"))
B = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf", s)
R = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Regular.otf", s)
BG, CARD, TEXT, SOFT, GOLD = (24, 28, 38), (38, 44, 58), (240, 242, 248), (168, 176, 196), (255, 200, 70)
rar = {r["id"]: r for r in D["rarities"]}
typ = {t["id"]: t for t in D["types"]}
def card(im, x, y, w, h, img, title, sub, colour):
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((x, y, x + w, y + h), 14, fill=CARD, outline=tuple(int(c) for c in colour), width=3)
    n = Image.open(img).convert("RGBA").resize((w - 16, int((w - 16) * 220 / 360)), Image.LANCZOS)
    im.paste(n, (x + 8, y + 6), n)
    d.text((x + w / 2, y + h - 46), title, font=B(18), fill=TEXT, anchor="mm")
    d.text((x + w / 2, y + h - 20), sub, font=R(15), fill=tuple(int(c) for c in colour), anchor="mm")
W, CW, CH = 6, 250, 210
im = Image.new("RGB", (W * (CW + 14) + 14, 80 + 2 * (CH + 14)), BG)
ImageDraw.Draw(im).text((16, 24), "12 needle types (all shown in the Steel skin)", font=B(30), fill=GOLD)
for i, t in enumerate(D["types"]):
    card(im, 14 + (i % W) * (CW + 14), 76 + (i // W) * (CH + 14), CW, CH, f"needles/{t['id']}_steel.png", t["name"], f"base value {int(t['value'])}", (120, 130, 150))
im.save("sheet_types.png")
W, CW, CH = 8, 220, 196
rows = []
for r in D["rarities"]:
    rows.append(("head", r))
    skins = [s for s in D["skins"] if s["rarity"] == r["id"]]
    for k in range(0, len(skins), W):
        rows.append(("row", skins[k:k + W]))
height = 76 + sum(46 if kind == "head" else CH + 12 for kind, _ in rows) + 10
im = Image.new("RGB", (W * (CW + 12) + 14, height), BG)
d = ImageDraw.Draw(im)
d.text((16, 24), "32 skins, here on the Darning Needle (every type comes in every skin: 384 to collect)", font=B(28), fill=GOLD)
y = 76
for kind, val in rows:
    if kind == "head":
        r = val
        pct = r["weight"] / sum(x["weight"] for x in D["rarities"]) * 100
        d.text((16, y + 22), r["name"], font=B(26), fill=tuple(int(c) for c in r["colour"]), anchor="lm")
        d.text((200, y + 22), f"{pct:.1f}% of finds  ·  worth x{int(r['mult'])}", font=R(18), fill=SOFT, anchor="lm")
        y += 46
    else:
        for i, s in enumerate(val):
            r = rar[s["rarity"]]
            card(im, 14 + i * (CW + 12), y, CW, CH, f"needles/darning_{s['id']}.png", s["name"], f"{r['name']} · {int(typ['darning']['value'] * r['mult'])}", r["colour"])
        y += CH + 12
im.save("sheet_skins.png")
mix = [("knitting", "candycane"), ("safety", "golden"), ("crochet", "aurora"), ("curved", "galaxy"), ("pin", "rainbow"), ("embroidery", "sakura"), ("bodkin", "lava"), ("sailmaker", "prism")]
W, CW, CH = 4, 300, 240
im = Image.new("RGB", (W * (CW + 14) + 14, 80 + 2 * (CH + 14)), BG)
ImageDraw.Draw(im).text((16, 24), "Mix and match: any type in any skin", font=B(30), fill=GOLD)
for i, (t, s) in enumerate(mix):
    skin = next(x for x in D["skins"] if x["id"] == s)
    r = rar[skin["rarity"]]
    card(im, 14 + (i % W) * (CW + 14), 76 + (i // W) * (CH + 14), CW, CH, f"needles/{t}_{s}.png", f"{skin['name']} {typ[t]['name']}", f"{r['name']} · worth {int(typ[t]['value'] * r['mult']):,}", r["colour"])
im.save("sheet_mix.png")
