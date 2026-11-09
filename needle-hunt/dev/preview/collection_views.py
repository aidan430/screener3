import json
from PIL import Image, ImageDraw, ImageFont
D = json.load(open("needles.json"))
B = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf", s)
R = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Regular.otf", s)
PANEL, CARD, LINE, TEXT, SOFT, GOLD, BLUE = (24, 28, 38), (38, 44, 58), (70, 78, 96), (240, 242, 248), (168, 176, 196), (255, 200, 70), (90, 150, 240)
rar = {r["id"]: r for r in D["rarities"]}
typ = {t["id"]: t for t in D["types"]}
W, H = 1280, 760
def col(c): return tuple(int(x) for x in c)
def button(d, box, text, colour, size=15):
    d.rounded_rectangle(box, 9, fill=colour); d.text(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2), text, font=B(size), fill=(255, 255, 255), anchor="mm")

def screen(viewing, tab, owned, showcase, value, count, people, scroll=0, tabcounts=None):
    im = Image.open("lobby_aerial.png").convert("RGBA").resize((W, H))
    im.alpha_composite(Image.new("RGBA", im.size, (0, 0, 0, 70)))
    bg = im.copy()
    ww, wh = 760, 640
    x0, y0 = W / 2 - ww / 2, H / 2 - wh / 2 + 20
    lay = Image.new("RGBA", im.size); ImageDraw.Draw(lay).rounded_rectangle((x0, y0, x0 + ww, y0 + wh), 18, fill=PANEL + (245,), outline=LINE, width=2); im.alpha_composite(lay)
    d = ImageDraw.Draw(im)
    d.text((x0 + 22, y0 + 34), "Collection", font=B(30), fill=TEXT, anchor="lm")
    button(d, (x0 + ww - 58, y0 + 14, x0 + ww - 14, y0 + 54), "X", CARD, 18)
    bx = x0 + 18
    for name, val in people:
        button(d, (bx, y0 + 66, bx + 176, y0 + 104), f"{name} · {val}", GOLD if name == viewing else CARD); bx += 182
    mine = viewing == "You"
    d.text((x0 + 18, y0 + 128), (f"Your collection" if mine else f"{viewing}'s collection") + f":  {value} value  ·  {count} / 384 needles", font=B(20), fill=GOLD, anchor="lm")
    st, ss = showcase
    skin = next(s for s in D["skins"] if s["id"] == ss)
    d.text((x0 + 18, y0 + 152), f"On show: {skin['name']} {typ[st]['name']}" + ("  (click any needle you own to show it instead)" if mine else ""), font=R(15), fill=SOFT, anchor="lm")
    bx = x0 + 18
    for t in D["types"][:4] if tab in [x["id"] for x in D["types"][:4]] else D["types"][6:10]:
        have = (tabcounts or {}).get(t["id"], sum(1 for k in owned if k[0] == t["id"]))
        label = f"{t['name']}  {have}/32"
        w = 172
        button(d, (bx, y0 + 168, bx + w, y0 + 206), label, BLUE if t["id"] == tab else CARD, 13); bx += w + 6
    gx, gy, cw, ch = x0 + 18, y0 + 218, 138, 150
    skins = D["skins"][scroll:scroll + 15]
    for i, s in enumerate(skins):
        x, y = gx + (i % 5) * (cw + 7), gy + (i // 5) * (ch + 8)
        r = rar[s["rarity"]]
        key = (tab, s["id"])
        n = owned.get(key, 0)
        on_show = key == showcase
        d.rounded_rectangle((x, y, x + cw, y + ch), 10, fill=CARD, outline=col(r["colour"]), width=4 if on_show else 2)
        if n:
            img = Image.open(f"needles/{tab}_{s['id']}.png" if __import__("os").path.exists(f"needles/{tab}_{s['id']}.png") else f"needles/darning_{s['id']}.png").convert("RGBA").resize((cw - 8, int((cw - 8) * 220 / 360)), Image.LANCZOS)
            im.alpha_composite(img, (int(x + 4), int(y + 4))); d = ImageDraw.Draw(im)
            d.text((x + cw / 2, y + 98), s["name"] + (f"  x{n}" if n > 1 else ""), font=B(15), fill=TEXT, anchor="mm")
            d.text((x + cw / 2, y + 119), f"{r['name']} · {int(typ[tab]['value'] * r['mult']):,}", font=R(13), fill=col(r["colour"]), anchor="mm")
            if on_show:
                d.text((x + cw / 2, y + 138), "ON SHOW", font=B(12), fill=GOLD, anchor="mm")
        else:
            d.text((x + cw / 2, y + 50), "???", font=B(34), fill=LINE, anchor="mm")
            d.text((x + cw / 2, y + 119), r["name"], font=R(13), fill=col(r["colour"]), anchor="mm")
    clip = y0 + wh - 8  # the list scrolls inside the window
    im.paste(bg.crop((0, int(clip), W, H)), (0, int(clip)))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((x0, y0, x0 + ww, y0 + wh), 18, outline=LINE, width=2)
    # a scroll bar hint
    d.rounded_rectangle((x0 + ww - 12, y0 + 220, x0 + ww - 6, y0 + 300), 3, fill=LINE)
    return im.convert("RGB")

people = [("You", "2,418"), ("StrawBossMax", "5,906"), ("Clover_99", "1,120")]
mine = {("darning", s): n for s, n in {"steel": 3, "iron": 1, "brass": 2, "copper": 1, "bone": 1, "pewter": 1, "rosegold": 1, "jade": 2, "mint": 1, "bumblebee": 1, "frost": 1, "aurora": 1}.items()}
a = screen("You", "darning", mine, ("darning", "aurora"), "2,418", 41, people, tabcounts={"sewing": 11, "pin": 9, "quilting": 6})
theirs = {("knitting", s): 1 for s in ["steel", "iron", "brass", "oak", "ink", "rosegold", "cobalt", "lavender", "bumblebee", "ember", "ocean", "zebra", "toxic"]}
theirs[("knitting", "steel")] = 4
b = screen("StrawBossMax", "knitting", theirs, ("knitting", "ember"), "5,906", 97, people, tabcounts={"safety": 12, "crochet": 7, "bodkin": 4, "knitting": 16})
c = screen("StrawBossMax", "knitting", {**theirs, ("knitting", "candycane"): 1, ("knitting", "midnight"): 2, ("knitting", "phoenix"): 1}, ("knitting", "phoenix"), "5,906", 97, people, scroll=15, tabcounts={"safety": 12, "crochet": 7, "bodkin": 4, "knitting": 16})
a.save("col_mine.png"); b.save("col_theirs.png"); c.save("col_rare.png")
