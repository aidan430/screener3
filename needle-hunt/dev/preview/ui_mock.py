from PIL import Image, ImageDraw, ImageFont, ImageFilter
B = "/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf"; R = "/usr/share/fonts/opentype/inter/Inter-Regular.otf"
def f(p, s): return ImageFont.truetype(p, s)
PANEL, CARD, LINE, TEXT, SOFT = (24, 28, 38), (38, 44, 58), (70, 78, 96), (240, 242, 248), (168, 176, 196)
GOLD, GREEN, RED, BLUE, PURPLE = (255, 200, 70), (80, 190, 120), (230, 90, 80), (90, 150, 240), (160, 120, 240)
W, H = 1280, 720

def base(name):
    return Image.open(name).convert("RGBA").resize((W, H))

def panel(im, box, r=14, alpha=0.85, outline=LINE, width=2):
    lay = Image.new("RGBA", im.size); d = ImageDraw.Draw(lay)
    d.rounded_rectangle(box, r, fill=PANEL + (int(255 * alpha),), outline=outline, width=width)
    im.alpha_composite(lay)

def button(d, box, text, colour, size=20):
    d.rounded_rectangle(box, 10, fill=colour)
    d.text(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2), text, font=f(B, size), fill=(255, 255, 255), anchor="mm")

def hud(im, phase, headline, timer, info, coins="1,240", level=7, xp=(180, 250), hint=False, timer_col=GOLD):
    panel(im, (16, 16, 266, 100))
    d = ImageDraw.Draw(im)
    d.text((30, 38), "● " + coins + " Haystack Coins", font=f(B, 19), fill=GOLD, anchor="lm")
    d.text((30, 66), f"Level {level}  ·  {xp[0]} / {xp[1]} XP", font=f(R, 17), fill=TEXT, anchor="lm")
    d.rounded_rectangle((30, 82, 252, 90), 4, fill=LINE); d.rounded_rectangle((30, 82, 30 + 222 * xp[0] / xp[1], 90), 4, fill=GOLD)
    panel(im, (W / 2 - 230, 14, W / 2 + 230, 118), r=16)
    d = ImageDraw.Draw(im)
    d.text((W / 2, 38), headline, font=f(B, 28), fill=TEXT, anchor="mm")
    d.text((W / 2, 70), timer, font=f(B, 28), fill=timer_col, anchor="mm")
    d.text((W / 2, 100), info, font=f(R, 17), fill=SOFT, anchor="mm")
    for i, (t, c) in enumerate([("Shop", GOLD), ("Inventory", PURPLE), ("Quests", GREEN), ("Leaderboard", BLUE), ("Settings", CARD)]):
        y = H / 2 - 155 + i * 64
        button(d, (W - 164, y, W - 14, y + 54), t, c)
    if hint:
        button(d, (W / 2 - 85, H - 74, W / 2 + 85, H - 20), "Hint", PURPLE, 22)
    return d

def toast(im, y, text, colour):
    panel(im, (W / 2 - 220, y, W / 2 + 220, y + 44), r=10, alpha=0.9, outline=colour)
    ImageDraw.Draw(im).text((W / 2 - 206, y + 22), text, font=f(R, 18), fill=TEXT, anchor="lm")

# 1. the lobby
im = base("lobby_player.png")
hud(im, "lobby", "Next round in", "0:12", "Get ready to search!")
toast(im, 130, "Day 3 login bonus: +75 coins, +0 XP", GREEN)
im.convert("RGB").save("ui_lobby.png")

# 2. searching
im = base("field_player.png")
hud(im, "search", "Find the needle!", "2:41", "Classic Haystack Field  ·  Normal", hint=True)
toast(im, 130, "The needle is not far, ahead, to your left.", GREEN)
im.convert("RGB").save("ui_search.png")

# 3. NEEDLE FOUND!
im = base("barn_needle.png")
hud(im, "search", "Find the needle!", "2:03", "Barn Interior  ·  Normal")
glow = Image.new("RGBA", im.size, (255, 255, 255, 60)); im.alpha_composite(glow)
cx, cy = W / 2, H * 0.42
panel(im, (cx - 260, cy - 115, cx + 260, cy + 115), r=22, alpha=0.95, outline=GOLD, width=3)
d = ImageDraw.Draw(im)
needle = Image.new("RGBA", (260, 60)); nd = ImageDraw.Draw(needle)
nd.rounded_rectangle((10, 24, 250, 36), 6, fill=(236, 170, 160)); nd.rounded_rectangle((2, 21, 28, 39), 9, fill=(200, 130, 120)); nd.rounded_rectangle((9, 27, 21, 33), 3, fill=PANEL)
needle = needle.rotate(18, expand=True, resample=Image.BICUBIC)
im.alpha_composite(needle, (int(cx - needle.width / 2), int(cy - 115 + 40 - needle.height / 2)))
d = ImageDraw.Draw(im)
d.text((cx, cy + 10), "NEEDLE FOUND!", font=f(B, 58), fill=GOLD, anchor="mm")
d.text((cx, cy + 72), "1st  ·  37.4 s  ·  +118 coins  ·  +139 XP", font=f(R, 22), fill=TEXT, anchor="mm")
import random
rnd = random.Random(3)
for i in range(40):
    x, y = rnd.random() * W, rnd.random() * H * 0.9
    d.rounded_rectangle((x, y, x + 8, y + 14), 3, fill=[GOLD, RED, GREEN, BLUE][i % 4])
im.convert("RGB").save("ui_found.png")

# 4. results
im = base("forest_aerial.png")
panel(im, (W / 2 - 280, H / 2 - 220, W / 2 + 280, H / 2 + 220), r=18, alpha=0.94)
d = ImageDraw.Draw(im)
x0, y0 = W / 2 - 262, H / 2 - 206
d.text((x0 + 4, y0 + 20), "Round results", font=f(B, 30), fill=TEXT, anchor="lm")
button(d, (W / 2 + 280 - 58, y0 + 2, W / 2 + 280 - 14, y0 + 42), "X", CARD)
d.text((x0 + 4, y0 + 70), "Night Forest", font=f(R, 18), fill=SOFT, anchor="lm")
rows = [("1st", "You", "41.2 s  ·  +112 coins", GOLD, True), ("2nd", "StrawBossMax", "46.8 s  ·  +78 coins", (200, 206, 216), False), ("3rd", "Clover_99", "49.9 s  ·  +58 coins", (205, 140, 90), False)]
for i, (pl, name, rest, medal, me) in enumerate(rows):
    y = y0 + 96 + i * 62
    d.rounded_rectangle((x0, y, x0 + 516, y + 52), 10, fill=LINE if me else CARD)
    d.text((x0 + 36, y + 26), pl, font=f(B, 22), fill=medal, anchor="mm")
    d.text((x0 + 80, y + 26), name, font=f(R, 21), fill=TEXT, anchor="lm")
    d.text((x0 + 500, y + 26), rest, font=f(R, 18), fill=SOFT, anchor="rm")
im.convert("RGB").save("ui_results.png")

# 5. the shop
im = base("lobby_aerial.png")
hud(im, "lobby", "Next round in", "0:09", "Get ready to search!")
panel(im, (W / 2 - 310, H * 0.57 - 250, W / 2 + 310, H * 0.57 + 250), r=18, alpha=0.96)
d = ImageDraw.Draw(im)
x0, y0 = W / 2 - 292, H * 0.57 - 236
d.text((x0 + 4, y0 + 20), "Shop", font=f(B, 30), fill=TEXT, anchor="lm")
button(d, (W / 2 + 310 - 58, y0 + 2, W / 2 + 310 - 14, y0 + 42), "X", CARD)
d.text((x0 + 4, y0 + 70), "Needle Skins", font=f(B, 22), fill=GOLD, anchor="lm")
items = [("Copper", (196, 116, 70), (150, 84, 50), "Equipped", PURPLE), ("Rose Gold", (236, 170, 160), (200, 130, 120), "● 900", GREEN), ("Frost", (170, 225, 255), (120, 190, 240), "● 1,600", RED), ("Midnight", (70, 60, 120), (140, 120, 230), "● 2,500", RED), ("Rainbow", (255, 120, 120), (120, 160, 255), "● 4,000", RED)]
for i, (name, a, b, btn, col) in enumerate(items):
    y = y0 + 92 + i * 76
    d.rounded_rectangle((x0, y, x0 + 576, y + 68), 12, fill=CARD)
    d.rounded_rectangle((x0 + 8, y + 6, x0 + 64, y + 62), 10, fill=PANEL)
    nd = Image.new("RGBA", (56, 56)); ndd = ImageDraw.Draw(nd)
    ndd.rounded_rectangle((4, 25, 52, 31), 3, fill=a); ndd.rounded_rectangle((3, 23, 14, 33), 4, fill=b)
    nd = nd.rotate(35, resample=Image.BICUBIC); im.alpha_composite(nd, (int(x0 + 8), int(y + 6))); d = ImageDraw.Draw(im)
    d.text((x0 + 80, y + 22), name, font=f(B, 21), fill=TEXT, anchor="lm")
    d.text((x0 + 80, y + 48), "Needle Skins", font=f(R, 15), fill=SOFT, anchor="lm")
    button(d, (x0 + 576 - 170, y + 10, x0 + 576 - 10, y + 58), btn, col, 20)
im.convert("RGB").save("ui_shop.png")
print("ok")
