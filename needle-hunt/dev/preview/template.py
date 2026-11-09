# A printable design sheet for new needle skins: six cards, each with a big needle outline split
# into the parts the game colours (shaft segments, eye, tip), boxes for the two colours, and
# tick boxes for pattern, material, rarity and effects. Fill it in, send it back, and it becomes
# a line in shared/Needles.luau.
from PIL import Image, ImageDraw, ImageFont
B = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf", s)
R = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Regular.otf", s)
INK, SOFT, LINE, PAPER = (40, 40, 48), (120, 124, 136), (190, 194, 204), (255, 255, 255)
W, H = 2480, 3508  # A4 at 300 dpi
im = Image.new("RGB", (W, H), PAPER)
d = ImageDraw.Draw(im)
d.text((120, 110), "Needle Skin Design Sheet", font=B(96), fill=INK)
d.text((120, 230), "A Needle in a Haystack · draw or colour a skin in each card · every skin works on all 12 needle types", font=R(44), fill=SOFT)

def tick(x, y, label, on=False):
    d.rectangle((x, y, x + 40, y + 40), outline=INK, width=4)
    if on:
        d.line([(x + 6, y + 20), (x + 17, y + 33), (x + 36, y + 6)], fill=(200, 80, 60), width=7)
    d.text((x + 56, y + 20), label, font=R(38), fill=INK, anchor="lm")
    return x + 56 + d.textlength(label, font=R(38)) + 50

def card(x0, y0, w, h, example=None):
    d.rounded_rectangle((x0, y0, x0 + w, y0 + h), 30, outline=LINE, width=6)
    d.text((x0 + 50, y0 + 60), "Skin name:", font=B(46), fill=INK, anchor="lm")
    d.line((x0 + 330, y0 + 85, x0 + w - 60, y0 + 85), fill=LINE, width=4)
    if example:
        d.text((x0 + 340, y0 + 58), example["name"], font=B(46), fill=(200, 80, 60), anchor="lm")
    # the needle: eye, 6 shaft segments, tip
    nx, ny, nl, nh = x0 + 120, y0 + 260, w - 300, 110
    seg = (nl - 160) / 6
    d.rounded_rectangle((nx, ny - nh * 0.7, nx + 150, ny + nh * 0.7), 40, outline=INK, width=6)
    d.rounded_rectangle((nx + 40, ny - 18, nx + 120, ny + 18), 14, outline=INK, width=5)
    for i in range(6):
        sx = nx + 150 + i * seg
        fill = None
        if example:
            fill = example["seg"][i]
        d.rectangle((sx, ny - nh / 2, sx + seg, ny + nh / 2), outline=INK, width=6, fill=fill)
        d.text((sx + seg / 2, ny + nh / 2 + 40), str(i + 1), font=R(34), fill=SOFT, anchor="mm")
    tx = nx + 150 + 6 * seg
    d.polygon([(tx, ny - nh / 2), (tx + 160, ny), (tx, ny + nh / 2)], outline=INK, fill=example["accent"] if example else None)
    d.line([(tx, ny - nh / 2), (tx + 160, ny), (tx, ny + nh / 2)], fill=INK, width=6)
    if example:
        d.rounded_rectangle((nx, ny - nh * 0.7, nx + 150, ny + nh * 0.7), 40, outline=INK, width=6, fill=example["accent"])
        d.rounded_rectangle((nx + 40, ny - 18, nx + 120, ny + 18), 14, outline=INK, width=5, fill=PAPER)
    d.text((nx + 75, ny - nh * 0.7 - 34), "eye", font=R(34), fill=SOFT, anchor="mm")
    d.text((tx + 80, ny - nh / 2 - 34), "point", font=R(34), fill=SOFT, anchor="mm")
    d.text((nx + 150 + 3 * seg, ny - nh / 2 - 34), "shaft (6 segments: stripes and gradients run along these)", font=R(34), fill=SOFT, anchor="mm")
    # colours
    y = y0 + 470
    for i, label in enumerate(["Colour 1 (shaft)", "Colour 2 (eye, point, stripes)"]):
        cx = x0 + 50 + i * (w / 2 - 20)
        d.rounded_rectangle((cx, y, cx + 120, y + 120), 18, outline=INK, width=5, fill=(example["c"][i] if example else None))
        d.text((cx + 150, y + 40), label, font=B(38), fill=INK, anchor="lm")
        d.text((cx + 150, y + 90), "R ____  G ____  B ____" if not example else "R %d  G %d  B %d" % example["c"][i], font=R(36), fill=SOFT if not example else (200, 80, 60), anchor="lm")
    # options
    y = y0 + 650
    d.text((x0 + 50, y), "Pattern", font=B(38), fill=INK)
    x = x0 + 260
    for opt in ["solid", "two-tone", "stripes", "gradient", "rainbow"]:
        x = tick(x, y + 2, opt, bool(example) and opt in ('stripes', 'plastic', 'Epic'))
    y += 80
    d.text((x0 + 50, y), "Material", font=B(38), fill=INK)
    x = x0 + 260
    for opt in ["metal", "plastic", "glass", "neon (glows)", "wood", "ice"]:
        x = tick(x, y + 2, opt, bool(example) and opt in ('stripes', 'plastic', 'Epic'))
    y += 80
    d.text((x0 + 50, y), "Rarity", font=B(38), fill=INK)
    x = x0 + 260
    for opt in ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]:
        x = tick(x, y + 2, opt, bool(example) and opt in ('stripes', 'plastic', 'Epic'))
    y += 80
    d.text((x0 + 50, y), "Extras", font=B(38), fill=INK)
    x = x0 + 260
    for opt in ["sparkles", "soft light", "notes: ______________________________"]:
        x = tick(x, y + 2, opt)

ex = {"name": "Candy Cane (example)", "c": [(230, 40, 50), (255, 255, 255)], "seg": [(230, 40, 50), (255, 255, 255)] * 3, "accent": (255, 255, 255)}
cw, ch = W - 240, 1000
for i in range(3):
    card(120, 340 + i * (ch + 40), cw, ch, ex if i == 0 else None)
im.save("needle_skin_template.png")
im.resize((W // 3, H // 3), Image.LANCZOS).save("needle_skin_template_small.png")
print("ok")
