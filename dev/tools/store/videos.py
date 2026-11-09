"""Promo videos 2-5 (upright 1080 x 1920, 30 fps, with sound), drawn in the store art's style.
    python3 videos.py ICON OUTDIR [2 3 4 5]"""
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

from art import cloud, farmer, glow, hills, lerp, needle, sky, sparkle
from kit import (BLACK, BOLD, CREAM, GOLD, H, INK, W, WHITE, back_out, build_farmer, clamp, ease_out, font,
                 paste_scaled, pop_text, shadow_pill, words)
from kit2 import (banner, confetti, crow, crown, dialogue, end_card, found_card, letterbox, load_icon, machine,
                  person, render, scarecrow, stack_layer, title_tag, top_board)

ICON, MASK = load_icon(sys.argv[1])
OUTDIR = sys.argv[2]
MABEL, PATCH, PIP = (96, 128, 74), (206, 152, 46), (59, 52, 66)


def farm_bg(seed=2, dusk=0.0, storm=0.0):
    rnd = random.Random(seed)
    top = lerp(lerp((60, 140, 232), (240, 140, 90), dusk), (60, 66, 84), storm)
    bottom = lerp(lerp((196, 230, 252), (255, 214, 150), dusk), (120, 126, 140), storm)
    im = sky(W, H, top=top, bottom=bottom)
    if storm < 0.5:
        glow(im, W * 0.85, H * 0.08, 300, (255, 236, 170), int(200 * (1 - storm)))
        for cx, cy, s in [(W * 0.18, H * 0.1, 90), (W * 0.75, H * 0.2, 80)]:
            cloud(im, cx, cy, s, rnd)
    hills(im, H * 0.74, rnd)
    if storm:
        dark = Image.new("RGB", im.size, (30, 34, 46))
        im = Image.blend(im, dark, 0.35 * storm)
    return im


def place(frame, layer, cx, base, width):
    """A haystack layer scaled to `width`, sitting on y = base, centred on cx."""
    h = int(layer.height * width / layer.width)
    l = layer.resize((int(width), h), Image.BILINEAR)
    frame.paste(l, (int(cx - width / 2), int(base - h)), l)


def hay_burst(frame, x, y, age, seed, n=6):
    if age < 0 or age > 0.8:
        return
    d = ImageDraw.Draw(frame)
    r = random.Random(seed)
    for _ in range(n):
        a = r.uniform(-2.6, -0.5)
        sp = r.uniform(200, 420)
        px, py = x + math.cos(a) * sp * age, y + math.sin(a) * sp * age + 500 * age * age
        L = r.uniform(24, 46)
        b = r.uniform(0, math.tau)
        d.line([(px, py), (px + math.cos(b) * L, py + math.sin(b) * L)], fill=lerp((255, 236, 150), (210, 150, 40), r.random()), width=7)


def xp_bar(frame, y, level, share, glowing=False, right=None):
    d = ImageDraw.Draw(frame)
    bx0, bw, bh = W * 0.1, W * 0.8, 96
    d.rounded_rectangle((bx0 - 8, y - 8, bx0 + bw + 8, y + bh + 8), 56, fill=CREAM)
    d.rounded_rectangle((bx0, y, bx0 + bw, y + bh), 48, fill=INK)
    if share > 0:
        d.rounded_rectangle((bx0, y, bx0 + max(bh, bw * share), y + bh), 48, fill=(255, 226, 140) if glowing else (206, 152, 46))
    tc = INK if glowing else WHITE
    need = 10 + 2 * level
    d.text((bx0 + 40, y + bh / 2), f"Level {level}", font=font(BLACK, 56), fill=tc, anchor="lm")
    d.text((bx0 + bw - 40, y + bh / 2), right or ("LEVEL UP!" if glowing else f"{int(share * need)} / {need} XP"), font=font(BOLD, 44), fill=tc, anchor="rm")


FARMER = build_farmer()
FARMER_WAVE = build_farmer(True)
BIG_STACK = stack_layer(1400, 1100, 3)


# ---------------------------------------------------------------- video 2: LEVEL UP (15 s)
def video2():
    bg = farm_bg(3)
    place(bg, BIG_STACK, W * 0.62, H * 0.86, W * 1.3)
    lifts = [2.2 + i * 0.36 for i in range(11)] + [9.2 + i * 0.36 for i in range(7)]
    events = [(0.1, "chime"), (6.3, "pop"), (6.4, "sparkle"), (11.3, "chime"), (12.1, "whoosh"), (13.6, "chime")]
    events += [(x, "pop") for x in lifts]
    board_rows = [("HayDayHannah", 1284), ("StrawBossMax", 1102), ("PitchforkPete", 977), ("Clover_99", 812), ("BaleBuilder", 760), ("You", 741)]

    def frame_at(t):
        if t >= 13.6:
            return end_card(None, ICON, MASK, t, 13.6, ask="How high can YOU level?")
        if t >= 12.0:
            f = farm_bg(5)
            top_board(f, W / 2, H * 0.42, 62, board_rows)
            pop_text(f, "CAN YOU TOP", 120, W / 2, H * 0.1, 12.1, t, fill=WHITE, rot=3)
            pop_text(f, "THE BOARD?", 150, W / 2, H * 0.18, 12.25, t, rot=3)
            return f
        f = bg.copy()
        who = FARMER_WAVE if t < 2 or 11.2 <= t else FARMER
        f.paste(who, (int(W * 0.26 - who.width / 2), int(H - who.height + 60 + math.sin(t * 16) * 6)), who)
        n = sum(1 for x in lifts if x <= t)
        for i, x in enumerate(lifts):
            hay_burst(f, W * 0.62, H * 0.5, t - x, i)
            if 0 <= t - x < 0.7:
                paste_scaled(f, words("+1 XP" if i % 6 else "+2 XP", 70, fill=WHITE, path=BOLD), W * 0.66 + (i % 3 - 1) * 50, H * 0.46 - (t - x) * 220, 1, 1 - (t - x) / 0.7)
        # the bar: Level 9 fills to 10 by 2 s; 10 fills again; LEVEL UP at 11.2
        if t < 2.0:
            level, share, glowing = 10, 1.0, True
        elif t < 11.2:
            level, share, glowing = 10, min(0.98, (n - 0) * 0.055 + (0.06 if t > 6.3 else 0)), False
        else:
            level, share, glowing = 11, 1.0 if t < 11.9 else 0.05, t < 11.9
        xp_bar(f, H * 0.5, level, share, glowing)
        if t < 2.0:
            shadow_pill(f, W / 2, H * 0.27, 1000, 270)
            pop_text(f, "LEVEL 10!", 200, W / 2, H * 0.27, 0.05, t, rot=-3)
            confetti(f, t, 0.05)
        elif t < 6.2:
            pop_text(f, "EVERY LIFT = XP", 120, W / 2, H * 0.14, 2.2, t, fill=WHITE, rot=2)
        elif t < 11.2:
            shadow_pill(f, W * 0.62, H * 0.38, 560, 160)
            pop_text(f, "x2 XP!", 140, W * 0.62, H * 0.38, 6.3, t, rot=8)
            pop_text(f, "LUCKY LIFTS", 120, W / 2, H * 0.12, 6.4, t, fill=WHITE, rot=2)
            pop_text(f, "= DOUBLE XP", 120, W / 2, H * 0.2, 6.55, t, rot=2)
        else:
            shadow_pill(f, W / 2, H * 0.28, 1000, 260)
            pop_text(f, "LEVEL UP!", 190, W / 2, H * 0.26, 11.2, t, rot=-3)
            pop_text(f, "+1 STRENGTH", 80, W / 2, H * 0.35, 11.35, t, fill=WHITE)
            confetti(f, t, 11.2, 0.8)
        return f

    render(15, frame_at, events, f"{OUTDIR}/video-2-level-up.mp4")


# ---------------------------------------------------------------- video 3: Day 1 vs Day 30 (25 s)
def video3():
    bg = farm_bg(7)
    small_tool = Image.new("RGBA", (900, 1300))
    farmer(small_tool, 450, 1290, 220, fork=False)
    sd = ImageDraw.Draw(small_tool)  # a garden trowel in the hand
    hx, hy = 450 + 0.81 * 220, 1290 - 1.2 * 220 - 1.25 * 220 + 1.08 * 220
    sd.line([(hx, hy), (hx + 60, hy - 90)], fill=(120, 80, 40), width=18)
    sd.polygon([(hx + 50, hy - 90), (hx + 110, hy - 170), (hx + 120, hy - 110)], fill=(170, 176, 186))
    tools = [("GARDEN TROWEL", "+1"), ("PITCHFORK", "+6"), ("STEEL FORK", "+40"), ("HAY HARVESTER", "+250")]
    events = [(0.1, "whoosh"), (2.2, "pop"), (3.6, "pop"), (5.0, "pop"), (6.2, "chime"), (7.4, "chime"), (8.6, "chime"), (10.1, "whoosh"), (15.1, "whoosh"), (21.2, "chime")]
    events += [(15.5 + i * 0.5, "pop") for i in range(10)]

    def split(t):
        f = bg.copy()
        d = ImageDraw.Draw(f)
        place(f, BIG_STACK, W * 0.25, H * 0.8, W * 0.62)
        small = small_tool.resize((300, 433), Image.BILINEAR)
        f.paste(small, (int(W * 0.25 - 150), int(H * 0.95 - 433)), small)
        place(f, BIG_STACK, W * 0.75, H * 0.8, W * 0.36)
        for i, x in enumerate((W * 0.6, W * 0.9, W * 0.62, W * 0.88)):
            machine(f, x, H * (0.86 + (i // 2) * 0.08), 70, t * 8 + i)
        d.rectangle((W / 2 - 6, 0, W / 2 + 6, H), fill=WHITE)
        pop_text(f, "DAY 1", 110, W * 0.25, H * 0.12, 0.1, t)
        pop_text(f, "DAY 30", 110, W * 0.75, H * 0.12, 0.25, t)
        pop_text(f, "VS", 120, W / 2, H * 0.22, 0.4, t, fill=WHITE)
        return f

    def frame_at(t):
        if t >= 21.2:
            return end_card(None, ICON, MASK, t, 21.2, ask="Where are YOU on day 30?")
        if t < 2.0:
            return split(t)
        f = bg.copy()
        if t < 6.0:  # day 1: one trowel, a few straws
            place(f, BIG_STACK, W * 0.6, H * 0.86, W * 1.3)
            f.paste(small_tool, (int(W * 0.26 - 450), int(H - 1300 + 60)), small_tool)
            for i, x in enumerate((2.2, 3.6, 5.0)):
                hay_burst(f, W * 0.6, H * 0.52, t - x, i, 2)
                if 0 <= t - x < 0.8:
                    paste_scaled(f, words("+1", 80, fill=WHITE, path=BOLD), W * 0.64, H * 0.48 - (t - x) * 200, 1, 1 - (t - x) / 0.8)
            pop_text(f, "DAY 1:", 120, W / 2, H * 0.1, 2.1, t, fill=WHITE)
            pop_text(f, "A GARDEN TROWEL", 110, W / 2, H * 0.18, 2.25, t)
            return f
        if t < 10.0:  # better tools
            place(f, BIG_STACK, W * 0.6, H * 0.86, W * 1.3)
            f.paste(FARMER, (int(W * 0.26 - 450), int(H - 1300 + 60)), FARMER)
            k = min(3, int((t - 6.0) / 1.2) + 1)
            name, gain = tools[k]
            age = (t - 6.0) - (k - 1) * 1.2
            shadow_pill(f, W / 2, H * 0.33, 900, 220)
            pop_text(f, name, 100, W / 2, H * 0.3, t - age, t)
            pop_text(f, gain + " A LIFT", 110, W / 2, H * 0.38, t - age + 0.1, t, fill=WHITE)
            hay_burst(f, W * 0.62, H * 0.52, age, k, 6 + 6 * k)
            pop_text(f, "BETTER TOOLS...", 120, W / 2, H * 0.1, 6.1, t, fill=WHITE, rot=2)
            return f
        if t < 15.0:  # build your farm: stairs and a conveyor with bundles
            place(f, BIG_STACK, W * 0.62, H * 0.86, W * 1.3)
            d = ImageDraw.Draw(f)
            built = clamp((t - 10.0) / 2.0)
            for i in range(int(12 * built)):
                x, y = W * 0.18 + i * 34, H * 0.84 - i * 52
                d.rectangle((x, y - 16, x + 150, y), fill=(150, 100, 52), outline=(100, 64, 30), width=4)
            if t > 12.0:  # a conveyor along the bottom, bundles riding it
                y = H * 0.9
                d.rectangle((0, y, W, y + 40), fill=(70, 70, 76))
                for k in range(14):
                    xx = (k * 90 + (t - 12) * 260) % (W + 90) - 90
                    d.line([(xx, y + 4), (xx + 40, y + 36)], fill=(110, 110, 118), width=6)
                for k in range(4):
                    xx = (k * 300 + (t - 12) * 260) % (W + 200) - 200
                    d.rounded_rectangle((xx, y - 70, xx + 120, y), 18, fill=(230, 180, 70), outline=(170, 120, 30), width=4)
                    d.line([(xx + 60, y - 70), (xx + 60, y)], fill=(170, 60, 40), width=8)
            pop_text(f, "...BUILD YOUR FARM...", 100, W / 2, H * 0.1, 10.1, t, fill=WHITE, rot=2)
            return f
        # the machines eat the stack from the outside in; coins count up
        k = clamp((t - 15.0) / 6.0)
        place(f, BIG_STACK, W * 0.5, H * 0.84, W * (1.25 - 0.7 * k))
        for i, (x, y) in enumerate([(0.12, 0.9), (0.88, 0.9), (0.22, 0.97), (0.78, 0.97), (0.5, 0.99)]):
            machine(f, W * x, H * y, 90, t * 10 + i)
        d = ImageDraw.Draw(f)
        for i in range(30):  # a stream of straw into the machines
            a = (i * 0.37 + t * 2) % 1
            sx, sy = W * 0.5 + (i % 2 * 2 - 1) * W * 0.25 * a, H * 0.6 + H * 0.28 * a
            d.line([(sx, sy), (sx + 30, sy + 14)], fill=(236, 190, 80), width=6)
        coins = int(12000 * (10 ** (k * 2.4)))
        shadow_pill(f, W / 2, H * 0.24, 960, 200)
        paste_scaled(f, words(f"{coins:,} COINS", 110, path=BLACK), W / 2, H * 0.24, 1)
        pop_text(f, "...AND LET THE", 100, W / 2, H * 0.08, 15.1, t, fill=WHITE)
        pop_text(f, "MACHINES DIG!", 120, W / 2, H * 0.14, 15.25, t)
        return f

    render(25, frame_at, events, f"{OUTDIR}/video-3-day1-vs-day30.mp4")


# ---------------------------------------------------------------- video 4: the story (30 s)
def video4():
    storm = farm_bg(9, storm=1.0)
    place(storm, BIG_STACK, W * 0.5, H * 0.86, W * 1.25)
    calm = farm_bg(9)
    place(calm, BIG_STACK, W * 0.62, H * 0.82, W * 1.25)
    dusk = farm_bg(9, dusk=1.0)
    place(dusk, BIG_STACK, W * 0.5, H * 0.86, W * 1.1)
    lines = [
        (3.0, 8.0, "Grandma Mabel", MABEL, "Somewhere in there is my silver needle. My gran's needle!"),
        (8.0, 12.0, "Patch", PATCH, "Oi! Mind where you're digging, that's my boot under there!"),
        (17.0, 23.0, "Patch", PATCH, "That's Pip. He says the thimble is his. Finders keepers, he says."),
    ]
    events = [(0.2, "whoosh"), (1.2, "whoosh"), (3.0, "pop"), (8.0, "pop"), (12.2, "sparkle"), (14.6, "sparkle"), (17.0, "pop"), (17.4, "pop"), (23.2, "whoosh"), (25.5, "sparkle"), (27.0, "chime")]

    def frame_at(t):
        if t >= 27.0:
            return end_card(None, ICON, MASK, t, 27.0, ask="Help Grandma find it!")
        if t < 3.0:  # the storm: wind and rain, bars ease in, the title card
            f = storm.copy()
            d = ImageDraw.Draw(f)
            r = random.Random(int(t * 12))
            for i in range(160):
                x = (i * 53 + t * 900) % (W + 200) - 100
                y = (i * 131 + t * 2200) % H
                d.line([(x, y), (x - 26, y + 60)], fill=(200, 210, 230), width=3)
            for i in range(12):  # hay blowing in on the wind
                x = (i * 170 + t * 700) % (W + 200) - 100
                y = H * 0.3 + (i * 97) % 500 + math.sin(t * 4 + i) * 40
                d.line([(x, y), (x + 40, y + 10)], fill=(236, 190, 80), width=7)
            letterbox(f, ease_out(clamp(t / 0.8)))
            pop_text(f, "THE STORM", 150, W / 2, H * 0.3, 0.6, t, fill=WHITE, path=BLACK)
            return f
        f = calm.copy()
        if t < 8.0:
            person(f, W * 0.24, H * 0.6, 170, MABEL, (110, 96, 130), hair=(205, 205, 210), bun=True, glasses=True, apron=(240, 230, 210))
        elif t < 12.0:
            scarecrow(f, W * 0.26, H * 0.6, 110)
        elif t < 17.0:  # found in the hay
            place(f, BIG_STACK, W * 0.5, H * 0.95, W * 1.6)
            d = ImageDraw.Draw(f)
            if t < 14.6:
                d.ellipse((W / 2 - 60, H * 0.55 - 60, W / 2 + 60, H * 0.55 + 60), fill=(200, 40, 50), outline=(140, 20, 30), width=8)
                for dx, dy in ((-18, -18), (18, -18), (-18, 18), (18, 18)):
                    d.ellipse((W / 2 + dx - 8, H * 0.55 + dy - 8, W / 2 + dx + 8, H * 0.55 + dy + 8), fill=(120, 10, 20))
                sparkle(f, W / 2 + 70, H * 0.5, 90)
                found_card(f, "A red button", 12.2, t)
            else:
                d.polygon([(W * 0.3, H * 0.5), (W * 0.7, H * 0.47), (W * 0.72, H * 0.62), (W * 0.32, H * 0.64)], fill=(244, 232, 200), outline=(180, 160, 120), width=5)
                d.text((W * 0.36, H * 0.53), "Mend Patch... by", font=font("/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf", 44), fill=(80, 60, 40))
                d.text((W * 0.36, H * 0.57), "moonlight... top", font=font("/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf", 44), fill=(80, 60, 40))
                sparkle(f, W * 0.7, H * 0.47, 80)
                found_card(f, "A torn note", 14.6, t)
            pop_text(f, "EVERY CLUMP HIDES", 100, W / 2, H * 0.1, 12.2, t, fill=WHITE)
            pop_text(f, "SOMETHING...", 120, W / 2, H * 0.17, 12.35, t)
            return f
        elif t < 23.0:  # Pip and the thimble
            scarecrow(f, W * 0.26, H * 0.6, 110)
            crow(f, W * 0.62, H * 0.3 + math.sin(t * 3) * 20, 90, t * 8)
            d = ImageDraw.Draw(f)
            tx, ty = W * 0.72, H * 0.34 + math.sin(t * 3) * 20
            d.rounded_rectangle((tx - 30, ty - 40, tx + 30, ty + 30), 14, fill=(200, 206, 216), outline=(130, 136, 146), width=5)
            sparkle(f, tx + 30, ty - 40, 50)
        else:  # dusk: the stack, the needle twinkling
            f = dusk.copy()
            needle(f, W * 0.58, H * 0.42, 160, -0.75)
            sparkle(f, W * 0.62, H * 0.39, 110 + 30 * math.sin(t * 6))
            pop_text(f, "THE NEEDLE IS", 110, W / 2, H * 0.12, 23.2, t, fill=WHITE)
            pop_text(f, "STILL IN THERE...", 110, W / 2, H * 0.19, 23.35, t)
            return f
        for a, b, who, col, text in lines:
            if a <= t < b:
                dialogue(f, who, col, text, (t - a) / 1.6, t)
        return f

    render(30, frame_at, events, f"{OUTDIR}/video-4-grandmas-needle.mp4")


# ---------------------------------------------------------------- video 5: the moment you find it (20 s)
def video5():
    bg = farm_bg(11)
    small_stack = stack_layer(500, 260, 6)
    events = [(0.2, "whoosh"), (2.2, "pop"), (3.0, "pop"), (3.8, "whoosh"), (4.8, "pop"), (5.6, "pop"), (9.3, "pop"), (9.35, "sparkle"), (11.0, "chime"), (11.3, "chime"), (15.0, "sparkle"), (17.6, "chime")]

    def frame_at(t):
        if t >= 17.6:
            return end_card(None, ICON, MASK, t, 17.6, ask="Could YOU find it?")
        f = bg.copy()
        if t < 2.0:  # circling the stack, bars in
            k = t / 2.0
            place(f, BIG_STACK, W * (0.5 + 0.2 * math.sin(k * 2.4)), H * 0.86, W * (1.1 + 0.15 * math.cos(k * 2.4)))
            letterbox(f, ease_out(clamp(t / 0.6)))
            pop_text(f, "THE MOMENT", 140, W / 2, H * 0.2, 0.3, t, fill=WHITE)
            pop_text(f, "YOU FIND IT...", 140, W / 2, H * 0.28, 0.45, t)
            return f
        if t < 7.0:  # quick cuts: the stack getting smaller
            k = clamp((t - 2.0) / 5.0)
            place(f, BIG_STACK, W * 0.5, H * 0.86, W * (1.25 - 0.95 * k))
            f.paste(FARMER, (int(W * 0.22 - 450), int(H - 1300 + 60)), FARMER)
            for i, x in enumerate((2.2, 3.0, 4.8, 5.6)):
                hay_burst(f, W * 0.55, H * 0.6, t - x, i, 10)
            if t > 3.8:
                machine(f, W * 0.82, H * 0.95, 90, t * 10)
            pop_text(f, "AFTER 5,000,000", 110, W / 2, H * 0.1, 2.1, t, fill=WHITE)
            pop_text(f, "STRAWS...", 120, W / 2, H * 0.17, 2.25, t)
            return f
        if t < 11.0:  # the last clump wobbles, then pops
            shake = math.sin(t * 40) * 10 * clamp((t - 7.5) / 1.5) if t < 9.3 else 0
            if t < 9.3:
                place(f, small_stack, W * 0.5 + shake, H * 0.8, W * 0.55)
            else:
                d = ImageDraw.Draw(f)
                k = clamp((t - 9.3) / 0.4)
                r = 60 + 500 * k
                d.ellipse((W / 2 - r, H * 0.72 - r, W / 2 + r, H * 0.72 + r), outline=(255, 236, 170), width=max(2, int(30 * (1 - k))))
                hay_burst(f, W / 2, H * 0.72, t - 9.3, 3, 30)
                needle(f, W / 2, H * 0.62, 300, -0.75, glint=False)
                sparkle(f, W / 2 + 70, H * 0.57, 160 + 20 * math.sin(t * 8))
            return f
        if t < 15.0:  # YOU FOUND THE NEEDLE!
            needle(f, W / 2, H * 0.72, 300, -0.75, glint=False)
            sparkle(f, W / 2 + 70, H * 0.67, 160)
            banner(f, "YOU FOUND THE NEEDLE!", "+20% coins forever", 11.0, t)
            confetti(f, t, 11.0, 2.5)
            if t > 12.6:
                dialogue(f, "Grandma Mabel", MABEL, "You found it! Oh, come here, you.", (t - 12.6) / 1.2, t)
            return f
        # show it off: the crown and a title
        lay = Image.new("RGBA", (W, H))
        farmer(lay, W * 0.5, H * 0.95, 260, fork=False, wave=True)
        f.paste(lay, (0, 0), lay)
        head_top = H * 0.95 - 1.2 * 260 - 1.25 * 260 - 1.0 * 260
        bob = math.sin(t * 3) * 10
        crown(f, W * 0.5, head_top - 120 + bob, 150)
        glow(f, W * 0.5, head_top - 160 + bob, 220, (255, 230, 150), 90)
        title_tag(f, W * 0.5, head_top - 330, "Haystack Hero", (255, 180, 60))
        pop_text(f, "SHOW IT OFF!", 150, W / 2, H * 0.1, 15.1, t)
        return f

    render(20, frame_at, events, f"{OUTDIR}/video-5-found-it.mp4")


if __name__ == "__main__":
    which = sys.argv[3:] or ["2", "3", "4", "5"]
    for v in which:
        {"2": video2, "3": video3, "4": video4, "5": video5}[v]()
        print("done", v, flush=True)
