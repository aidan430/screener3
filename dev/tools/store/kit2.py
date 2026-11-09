"""More pieces for the promo videos: the story characters (Grandma Mabel, Patch the scarecrow,
Pip the crow), the game's dialogue box and found-it banner, machines, the Golden Straw Crown,
the Top Farmers board, confetti, letterbox bars, an end card, and a render loop with sound."""
import math
import random
import subprocess
import wave

from PIL import Image, ImageDraw, ImageFilter

from kit import (BLACK, BOLD, CREAM, EDGE, FPS, GOLD, H, INK, W, WHITE, back_out, clamp, ease_out, font,
                 pop_text, shadow_pill, synth)
from art import glow, haystack, sky

SERIF_B = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
REG = "/usr/share/fonts/opentype/inter/Inter-Regular.otf"


def render(seconds, frame_at, events, out):
    """Calls frame_at(t) for every frame and writes an mp4 with the synthesised sound."""
    pcm = synth(events, seconds)
    with wave.open("audio.wav", "wb") as wv:
        wv.setnchannels(1)
        wv.setsampwidth(2)
        wv.setframerate(44100)
        wv.writeframes(pcm.tobytes())
    proc = subprocess.Popen(["ffmpeg", "-y", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                             "-i", "audio.wav", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "medium",
                             "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", out], stdin=subprocess.PIPE)
    for fi in range(int(FPS * seconds)):
        proc.stdin.write(frame_at(fi / FPS).convert("RGB").tobytes())
    proc.stdin.close()
    proc.wait()


def person(layer, x, ground, s, shirt, legs, hair=None, bun=False, glasses=False, apron=None, face="smile"):
    """A blocky villager like the farmer: head s wide, shirt and legs colours, optional grey bun and glasses."""
    d = ImageDraw.Draw(layer)
    skin = (250, 206, 160)
    leg_h, torso_h = s * 1.2, s * 1.25
    hip = ground - leg_h
    sh_y = hip - torso_h
    for dx in (-0.5, 0.02):
        d.rounded_rectangle((x + dx * s, hip, x + (dx + 0.48) * s, ground - s * 0.12), s * 0.06, fill=legs)
        d.rounded_rectangle((x + (dx - 0.02) * s, ground - s * 0.2, x + (dx + 0.52) * s, ground), s * 0.06, fill=(92, 60, 36))
    d.rounded_rectangle((x - 0.62 * s, sh_y, x + 0.62 * s, hip + s * 0.05), s * 0.1, fill=shirt)
    if apron:
        d.rounded_rectangle((x - 0.42 * s, sh_y + torso_h * 0.3, x + 0.42 * s, hip + s * 0.3), s * 0.06, fill=apron)
    for dx in (-1.0, 0.62):
        d.rounded_rectangle((x + dx * s, sh_y + 0.05 * s, x + (dx + 0.38) * s, sh_y + 1.0 * s), s * 0.1, fill=shirt)
        d.rounded_rectangle((x + dx * s, sh_y + 0.95 * s, x + (dx + 0.38) * s, sh_y + 1.25 * s), s * 0.1, fill=skin)
    hx0, hy0 = x - 0.5 * s, sh_y - 1.0 * s
    if bun:
        d.ellipse((x - 0.25 * s, hy0 - 0.38 * s, x + 0.25 * s, hy0 + 0.1 * s), fill=hair)
    d.rounded_rectangle((hx0, hy0, hx0 + s, hy0 + s), s * 0.2, fill=skin)
    if hair:
        d.rounded_rectangle((hx0 - 0.03 * s, hy0 - 0.06 * s, hx0 + 1.03 * s, hy0 + 0.3 * s), s * 0.2, fill=hair)
    ey = hy0 + 0.48 * s
    for ex in (0.3, 0.7):
        d.ellipse((hx0 + (ex - 0.06) * s, ey - 0.08 * s, hx0 + (ex + 0.06) * s, ey + 0.08 * s), fill=(40, 30, 24))
        if glasses:
            d.ellipse((hx0 + (ex - 0.14) * s, ey - 0.14 * s, hx0 + (ex + 0.14) * s, ey + 0.14 * s), outline=(80, 60, 40), width=max(2, int(s * 0.03)))
    if glasses:
        d.line([(hx0 + 0.44 * s, ey), (hx0 + 0.56 * s, ey)], fill=(80, 60, 40), width=max(2, int(s * 0.03)))
    if face == "smile":
        d.arc((hx0 + 0.32 * s, hy0 + 0.58 * s, hx0 + 0.68 * s, hy0 + 0.82 * s), 20, 160, fill=(110, 40, 36), width=max(3, int(s * 0.05)))
    else:
        d.ellipse((hx0 + 0.4 * s, hy0 + 0.64 * s, hx0 + 0.6 * s, hy0 + 0.84 * s), fill=(110, 40, 36))
    for cxk in (0.16, 0.84):
        d.ellipse((hx0 + (cxk - 0.08) * s, hy0 + 0.58 * s, hx0 + (cxk + 0.08) * s, hy0 + 0.68 * s), fill=(250, 170, 150))
    return hy0


def scarecrow(layer, x, ground, s):
    """Patch: a pole, a sack head with stitched smile and button eye, a straw hat and a patched shirt."""
    d = ImageDraw.Draw(layer)
    d.rectangle((x - 0.08 * s, ground - 4.2 * s, x + 0.08 * s, ground), fill=(130, 90, 50))
    d.rectangle((x - 1.6 * s, ground - 3.1 * s, x + 1.6 * s, ground - 2.95 * s), fill=(130, 90, 50))
    d.polygon([(x - 0.9 * s, ground - 3.25 * s), (x + 0.9 * s, ground - 3.25 * s), (x + 0.7 * s, ground - 1.4 * s), (x - 0.7 * s, ground - 1.4 * s)], fill=(76, 106, 130))
    d.rectangle((x - 0.45 * s, ground - 2.6 * s, x - 0.05 * s, ground - 2.2 * s), fill=(176, 84, 60))
    d.rectangle((x + 0.15 * s, ground - 2.0 * s, x + 0.5 * s, ground - 1.7 * s), fill=(206, 152, 46))
    for side in (-1, 1):
        for k in range(5):
            d.line([(x + side * 1.6 * s, ground - 3.05 * s), (x + side * (1.75 + 0.05 * k) * s, ground - (3.3 - 0.12 * k) * s)], fill=(230, 186, 80), width=max(3, int(s * 0.05)))
    hy = ground - 4.2 * s
    d.ellipse((x - 0.65 * s, hy - 0.5 * s, x + 0.65 * s, hy + 0.85 * s), fill=(214, 186, 140))
    d.ellipse((x - 0.35 * s, hy - 0.05 * s, x - 0.15 * s, hy + 0.15 * s), fill=(176, 84, 60))  # the red button eye
    d.line([(x + 0.12 * s, hy - 0.02 * s), (x + 0.36 * s, hy + 0.18 * s)], fill=(60, 40, 24), width=max(3, int(s * 0.05)))
    d.line([(x + 0.36 * s, hy - 0.02 * s), (x + 0.12 * s, hy + 0.18 * s)], fill=(60, 40, 24), width=max(3, int(s * 0.05)))
    d.arc((x - 0.4 * s, hy + 0.2 * s, x + 0.4 * s, hy + 0.6 * s), 10, 170, fill=(60, 40, 24), width=max(3, int(s * 0.05)))
    for k in range(6):
        sx = x - 0.3 * s + k * 0.12 * s
        d.line([(sx, hy + 0.42 * s), (sx, hy + 0.55 * s)], fill=(60, 40, 24), width=max(2, int(s * 0.03)))
    d.ellipse((x - 1.1 * s, hy - 0.62 * s, x + 1.1 * s, hy - 0.3 * s), fill=(222, 180, 84))
    d.rounded_rectangle((x - 0.55 * s, hy - 1.15 * s, x + 0.55 * s, hy - 0.42 * s), s * 0.2, fill=(236, 196, 100))


def crow(layer, x, y, s, flap=0.0):
    """Pip: a round black crow with a yellow beak and a shiny eye."""
    d = ImageDraw.Draw(layer)
    body, wing = (40, 36, 48), (64, 58, 74)
    d.ellipse((x - 0.9 * s, y - 0.6 * s, x + 0.9 * s, y + 0.7 * s), fill=body)
    d.ellipse((x + 0.3 * s, y - 1.1 * s, x + 1.2 * s, y - 0.2 * s), fill=body)
    d.polygon([(x + 1.15 * s, y - 0.75 * s), (x + 1.75 * s, y - 0.6 * s), (x + 1.15 * s, y - 0.45 * s)], fill=(240, 180, 60))
    d.ellipse((x + 0.75 * s, y - 0.85 * s, x + 0.95 * s, y - 0.65 * s), fill=(255, 255, 255))
    d.ellipse((x + 0.81 * s, y - 0.8 * s, x + 0.91 * s, y - 0.7 * s), fill=(20, 20, 20))
    lift = math.sin(flap) * 0.5 * s
    d.polygon([(x - 0.4 * s, y - 0.2 * s), (x - 1.5 * s, y - 0.5 * s - lift), (x - 0.2 * s, y + 0.4 * s)], fill=wing)
    d.polygon([(x - 0.85 * s, y + 0.1 * s), (x - 1.5 * s, y + 0.5 * s), (x - 0.85 * s, y + 0.45 * s)], fill=body)
    for dx in (-0.2, 0.2):
        d.line([(x + dx * s, y + 0.65 * s), (x + dx * s, y + 1.0 * s)], fill=(240, 180, 60), width=max(3, int(s * 0.08)))


def dialogue(frame, who, colour, text, shown, t):
    """The game's dialogue card: paper, a round portrait with the speaker's initial, their name in their colour,
    the words typing out (shown = 0..1) and a Next button."""
    d = ImageDraw.Draw(frame)
    x0, y0, x1, y1 = W * 0.05, H * 0.62, W * 0.95, H * 0.62 + 330
    d.rounded_rectangle((x0, y0, x1, y1), 18, fill=CREAM, outline=(200, 182, 150), width=3)
    d.ellipse((x0 + 30, y0 + 50, x0 + 170, y0 + 190), fill=colour)
    d.text((x0 + 100, y0 + 120), who[0], font=font(SERIF_B, 70), fill=WHITE, anchor="mm")
    d.text((x0 + 200, y0 + 40), who, font=font(SERIF_B, 46), fill=colour)
    f = font(REG, 42)
    words_ = text.split(" ")
    lines, line = [], ""
    for wd in words_:
        trial = (line + " " + wd).strip()
        if d.textlength(trial, font=f) > x1 - x0 - 240:
            lines.append(line)
            line = wd
        else:
            line = trial
    lines.append(line)
    total = sum(len(l) for l in lines)
    left = int(total * clamp(shown))
    for i, l in enumerate(lines):
        d.text((x0 + 200, y0 + 110 + i * 54), l[:max(0, left)], font=f, fill=INK)
        left -= len(l)
    if shown >= 1:
        d.rounded_rectangle((x1 - 190, y1 - 80, x1 - 30, y1 - 24), 8, fill=INK)
        d.text((x1 - 110, y1 - 52), "Next", font=font(BOLD, 34), fill=WHITE, anchor="mm")


def found_card(frame, item, t0, t):
    """'Found in the hay:' and the item's name on a paper slip that springs up."""
    if t < t0:
        return
    k = back_out(clamp((t - t0) / 0.4))
    card = Image.new("RGBA", (860, 220))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle((0, 0, 859, 219), 18, fill=CREAM + (255,), outline=(200, 182, 150), width=3)
    d.text((430, 66), "FOUND IN THE HAY", font=font(BOLD, 40), fill=(206, 152, 46), anchor="mm")
    d.text((430, 146), item, font=font(SERIF_B, 64), fill=INK, anchor="mm")
    s = 0.4 + 0.6 * k
    card = card.resize((int(860 * s), int(220 * s)), Image.BILINEAR)
    frame.paste(card, (int(W / 2 - card.width / 2), int(H * 0.36 - card.height / 2)), card)


def banner(frame, title, body, t0, t):
    """The game's big banner: a cream card in the middle with a title and a line."""
    if t < t0:
        return
    k = back_out(clamp((t - t0) / 0.45))
    card = Image.new("RGBA", (980, 330))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle((0, 0, 979, 329), 22, fill=CREAM + (255,), outline=(200, 182, 150), width=4)
    tf = font(SERIF_B, 64)
    while d.textlength(title, font=tf) > 900:
        tf = font(SERIF_B, tf.size - 3)
    d.text((490, 110), title, font=tf, fill=INK, anchor="mm")
    d.text((490, 215), body, font=font(REG, 40), fill=(122, 98, 72), anchor="mm")
    s = 0.4 + 0.6 * k
    card = card.resize((int(980 * s), int(330 * s)), Image.BILINEAR)
    frame.paste(card, (int(W / 2 - card.width / 2), int(H * 0.42 - card.height / 2)), card)


def confetti(frame, t, t0, length=1.8):
    lt = t - t0
    if lt < 0 or lt > length:
        return
    d = ImageDraw.Draw(frame)
    cols = [(255, 206, 70), (240, 120, 80), (120, 200, 120), (110, 170, 240)]
    for i in range(80):
        x = (i * 137 + int(math.sin(i + lt * 3) * 40)) % W
        y = (lt * 1300 + (i * 61) % 900) - 300
        a = i * 0.7 + lt * 6
        dx, dy = math.cos(a) * 14, math.sin(a) * 14
        d.polygon([(x - dx, y - dy), (x + dy * 0.6, y - dx * 0.6), (x + dx, y + dy), (x - dy * 0.6, y + dx * 0.6)], fill=cols[i % 4])


def letterbox(frame, k):
    """Widescreen bars easing in (k = 0..1), like the game's cinematics."""
    d = ImageDraw.Draw(frame)
    h = int(H * 0.1 * k)
    d.rectangle((0, 0, W, h), fill=(14, 10, 6))
    d.rectangle((0, H - h, W, H), fill=(14, 10, 6))


def machine(layer, x, ground, s, spin):
    """A hay-eating machine: a red box on legs with a turning fan and a hopper."""
    d = ImageDraw.Draw(layer)
    d.rectangle((x - 0.9 * s, ground - 0.5 * s, x - 0.7 * s, ground), fill=(70, 70, 76))
    d.rectangle((x + 0.7 * s, ground - 0.5 * s, x + 0.9 * s, ground), fill=(70, 70, 76))
    d.rounded_rectangle((x - s, ground - 1.6 * s, x + s, ground - 0.45 * s), s * 0.12, fill=(196, 64, 50))
    d.polygon([(x - 0.7 * s, ground - 1.6 * s), (x + 0.7 * s, ground - 1.6 * s), (x + 0.45 * s, ground - 2.0 * s), (x - 0.45 * s, ground - 2.0 * s)], fill=(150, 154, 160))
    cx, cy, r = x, ground - 1.02 * s, 0.38 * s
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(60, 64, 72))
    for k in range(4):
        a = spin + k * math.pi / 2
        d.polygon([(cx, cy), (cx + math.cos(a) * r * 0.95, cy + math.sin(a) * r * 0.95), (cx + math.cos(a + 0.5) * r * 0.95, cy + math.sin(a + 0.5) * r * 0.95)], fill=(220, 224, 230))


def crown(layer, cx, cy, s, t=0.0):
    """The Golden Straw Crown: a gold band with points, gems and a soft shimmer."""
    d = ImageDraw.Draw(layer)
    pts = [(cx - s, cy)]
    for k in range(9):
        x = cx - s + k * (2 * s / 8)
        pts.append((x, cy - (0.9 * s if k % 2 == 0 else 0.45 * s)))
    pts.append((cx + s, cy))
    d.polygon(pts, fill=(250, 200, 60), outline=(170, 120, 20), width=max(3, int(s * 0.05)))
    d.rectangle((cx - s, cy - 0.3 * s, cx + s, cy), fill=(236, 176, 40))
    for k, col in enumerate([(200, 40, 50), (60, 120, 220), (60, 170, 90), (200, 40, 50)]):
        x = cx - 0.65 * s + k * 0.43 * s
        d.ellipse((x - 0.1 * s, cy - 0.25 * s, x + 0.1 * s, cy - 0.05 * s), fill=col)
    for k in range(0, 9, 2):
        x = cx - s + k * (2 * s / 8)
        d.ellipse((x - 0.08 * s, cy - 0.98 * s, x + 0.08 * s, cy - 0.82 * s), fill=(255, 248, 230))


def title_tag(layer, cx, y, text, colours):
    """A title above someone's head, like the game's cosmetic titles."""
    d = ImageDraw.Draw(layer)
    f = font(BLACK, 54)
    tw = d.textlength(text, font=f)
    d.text((cx, y), text, font=f, fill=colours, anchor="mm", stroke_width=6, stroke_fill=EDGE)


def top_board(frame, cx, cy, s, rows):
    """The Top Farmers sign: posts, a roof, cream paper, the top three bold in gold."""
    d = ImageDraw.Draw(frame)
    wood, board, roof = (120, 84, 48), (150, 108, 64), (92, 60, 36)
    bw, bh = 15 * s, 13 * s
    for px in (-8, 8):
        d.rectangle((cx + (px - 0.5) * s, cy - bh / 2 - 1.5 * s, cx + (px + 0.5) * s, cy + bh / 2 + 4 * s), fill=wood)
    d.rectangle((cx - bw / 2, cy - bh / 2, cx + bw / 2, cy + bh / 2), fill=board)
    d.rectangle((cx - 9 * s, cy - bh / 2 - 1.8 * s, cx + 9 * s, cy - bh / 2 - 1.2 * s), fill=roof)
    px0, py0 = cx - bw / 2 + 0.5 * s, cy - bh / 2 + 0.5 * s
    d.rectangle((px0, py0, cx + bw / 2 - 0.5 * s, cy + bh / 2 - 0.5 * s), fill=(244, 232, 204))
    d.text((cx, py0 + 1.0 * s), "TOP FARMERS", font=font(SERIF_B, 1.15 * s), fill=(60, 40, 22), anchor="mm")
    for i, (name, lvl) in enumerate(rows, 1):
        y = py0 + 1.75 * s + (i - 1) * 1.0 * s + 0.5 * s
        f = font(SERIF_B if i <= 3 else SERIF, 0.72 * s)
        d.text((px0 + 0.5 * s, y), f"{i}.  {name}  ·  Level {lvl}", font=f, fill=(176, 120, 20) if i <= 3 else (70, 52, 36), anchor="lm")


def end_card(frame, icon, mask, t, t0, line1="NEEDLE IN THE", line2="HAYSTACK", ask="Could YOU find it?"):
    """Sunburst, the icon springing in, the title, and PLAY FREE ON ROBLOX, clear of the app's captions."""
    lt = t - t0
    bg = sky(W, H, top=(60, 140, 232), bottom=(196, 230, 252))
    rays = Image.new("RGBA", bg.size)
    rd = ImageDraw.Draw(rays)
    for i in range(18):
        a0 = i / 18 * math.tau + lt * 0.3
        rd.polygon([(W / 2, H * 0.42), (W / 2 + math.cos(a0) * 2200, H * 0.42 + math.sin(a0) * 2200), (W / 2 + math.cos(a0 + 0.13) * 2200, H * 0.42 + math.sin(a0 + 0.13) * 2200)], fill=(255, 248, 210, 70))
    bg.paste(rays, (0, 0), rays)
    s = 0.3 + 0.7 * back_out(clamp(lt / 0.45))
    ic = icon.resize((max(1, int(560 * s)), max(1, int(560 * s))), Image.BILINEAR)
    m = mask.resize(ic.size, Image.BILINEAR)
    bg.paste(ic, (int(W / 2 - ic.width / 2), int(H * 0.42 - ic.height / 2)), m)
    pop_text(bg, line1, 110, W / 2, H * 0.12, t0 + 0.2, t, fill=WHITE, rot=3)
    pop_text(bg, line2, 170, W / 2, H * 0.21, t0 + 0.35, t, rot=3)
    pop_text(bg, ask, 90, W / 2, H * 0.6, t0 + 0.7, t, fill=WHITE, path=BOLD)
    pop_text(bg, "PLAY FREE ON ROBLOX", 84, W / 2, H * 0.68, t0 + 1.0, t, path=BLACK)
    return bg


def load_icon(path):
    icon = Image.open(path).convert("RGB").resize((560, 560), Image.LANCZOS)
    mask = Image.new("L", icon.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 559, 559), 100, fill=255)
    return icon, mask


def stack_layer(width, height, seed=3):
    """A haystack on its own transparent layer (to scale and move per frame)."""
    lay = Image.new("RGBA", (int(width * 1.3), int(height * 1.15)))
    haystack(lay, lay.width / 2, height * 1.08, width, height, random.Random(seed))
    return lay
