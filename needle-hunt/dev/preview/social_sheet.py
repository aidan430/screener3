from PIL import Image, ImageDraw, ImageFont
B = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf", s)
R = lambda s: ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Regular.otf", s)
PANEL, GOLD, TEXT, SOFT = (24, 28, 38), (255, 200, 70), (240, 242, 248), (168, 176, 196)
# 1. arrival + the join banner
a = Image.open("lobby_arrive.png").convert("RGBA")
lay = Image.new("RGBA", a.size); d = ImageDraw.Draw(lay)
x0, y0 = 640 - 260, 132
d.rounded_rectangle((x0, y0, x0 + 520, y0 + 150), 16, fill=PANEL + (245,), outline=GOLD, width=2)
a.alpha_composite(lay)
n = Image.open("needles/sailmaker_prism.png").convert("RGBA").resize((200, 122)); a.alpha_composite(n, (x0 + 0, y0 + 14))
d = ImageDraw.Draw(a)
d.text((x0 + 196, y0 + 28), "MOST VALUABLE NEEDLE IN THIS LOBBY", font=B(17), fill=GOLD, anchor="lm")
d.text((x0 + 196, y0 + 66), "Mythic Prism Sailmaker's Needle", font=B(21), fill=TEXT, anchor="lm")
d.text((x0 + 196, y0 + 112), "owned by StrawBossMax  ·  worth 5,400", font=R(17), fill=SOFT, anchor="lm")
d.rounded_rectangle((16, 720 - 74, 186, 720 - 20), 10, fill=(230, 120, 170)); d.text((101, 720 - 47), "Show off!", font=B(20), fill=(255, 255, 255), anchor="mm")
a = a.convert("RGB")
# 2. hover on a needle
h = Image.open("field_needle.png").convert("RGBA")
NX, NY = 640, 360
d = ImageDraw.Draw(h)
d.text((NX + 40, NY + 10), "Click to grab!", font=B(26), fill=GOLD, anchor="lm", stroke_width=3, stroke_fill=(30, 20, 10))
lay = Image.new("RGBA", h.size); dl = ImageDraw.Draw(lay)
dl.rounded_rectangle((640 - 230, 14, 640 + 230, 118), 16, fill=PANEL + (225,))
h.alpha_composite(lay); d = ImageDraw.Draw(h)
d.text((640, 38), "Find the needle!  0/1", font=B(28), fill=TEXT, anchor="mm"); d.text((640, 70), "2:14", font=B(28), fill=GOLD, anchor="mm"); d.text((640, 100), "Classic Haystack Field  ·  Normal", font=R(17), fill=SOFT, anchor="mm")
h = h.convert("RGB")
shots = [(a, "Arriving: you face the Champion's Needle (the most valuable needle anyone here owns), and a banner says whose it is. Tags over heads show each player's best needle; the champion wears a crown line. Show off! holds your needle up for everyone."),
         (Image.open("lobby_booths.png"), "Collector booths down both sides: every player gets one with their three best needles on show. Press E at a booth to open that player's Collection."),
         (Image.open("lobby_wide.png"), "The bigger lobby (170 x 170), enclosed by a hedge: 12 booths, the Champion's Needle by the spawn, benches, the Play pad, Hall of Needles, boards and stalls."),
         (Image.open("field_aerial.png"), "Every outdoor map now has a hedge all the way round, with invisible walls above it; fall off anywhere and you respawn."),
         (h, "Finding it: needles are bigger (2.8 studs on Normal) with a bigger grab box. Point at one in reach and it lights up with 'Click to grab!'; the banner counts 0/1, and once it's yours it vanishes from your screen.")]
W = 1280
out = Image.new("RGB", (W, 70 + len(shots) * (720 + 80)), PANEL)
d = ImageDraw.Draw(out)
d.text((20, 20), "The social lobby, map barriers and findable needles", font=B(32), fill=GOLD)
y = 70
for im, cap in shots:
    words, line, lines = cap.split(" "), "", []
    for w in words:
        if d.textlength(line + " " + w, font=R(20)) > W - 40:
            lines.append(line); line = w
        else:
            line = (line + " " + w).strip()
    lines.append(line)
    for i, l in enumerate(lines):
        d.text((20, y + 6 + i * 26), l, font=R(20), fill=TEXT)
    out.paste(im.convert("RGB").resize((W, 720)), (0, y + 70))
    y += 720 + 80
out.save("/home/user/screener3/needle-hunt/previews/social_lobby.png")
