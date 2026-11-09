import random, sys
sys.path.insert(0, ".")
from art import *
W, H = 3840, 2160
rnd = random.Random(21)
im = sky(W, H, top=(60, 140, 232))
glow(im, W * 0.5, H * 0.3, 900, (255, 230, 150), 150)
for cx, cy, s in [(W * 0.1, H * 0.2, 130), (W * 0.9, H * 0.16, 150)]:
    cloud(im, cx, cy, s, rnd)
hills(im, H * 0.7, rnd)
# a burst of light rays behind the farmer
rays = Image.new("RGBA", im.size)
rd = ImageDraw.Draw(rays)
fx, fy = W * 0.32, H * 0.6
for i in range(16):
    a0 = i / 16 * math.tau
    rd.polygon([(fx, fy), (fx + math.cos(a0) * 3000, fy + math.sin(a0) * 3000), (fx + math.cos(a0 + 0.12) * 3000, fy + math.sin(a0 + 0.12) * 3000)], fill=(255, 245, 200, 70))
rays = rays.filter(ImageFilter.GaussianBlur(8))
im.paste(rays, (0, 0), rays)
haystack(im, W * 0.72, H * 0.98, W * 0.5, H * 0.72, rnd)
farmer(im, W * 0.3, H * 1.0, 330, wave=True)
flying_hay(im, W * 0.42, H * 0.3, 520, 160, rnd, 2.4)
for x, y, r in [(W * 0.15, H * 0.42, 70), (W * 0.5, H * 0.5, 55), (W * 0.2, H * 0.75, 45)]:
    sparkle(im, x, y, r)
title(im, "LEVEL UP!", W * 0.62, H * 0.2, 420, rot=-4, max_w=W * 0.6)
# the game's XP bar, big
d = ImageDraw.Draw(im)
bx0, by0, bw, bh = W * 0.47, H * 0.4, W * 0.42, 150
d.rounded_rectangle((bx0 - 10, by0 - 10, bx0 + bw + 10, by0 + bh + 10), 85, fill=(246, 237, 218))
d.rounded_rectangle((bx0, by0, bx0 + bw, by0 + bh), 75, fill=(255, 226, 140))
d.text((bx0 + 70, by0 + bh / 2), "Level 99", font=font(BLACK, 92), fill=(59, 42, 26), anchor="lm")
d.text((bx0 + bw - 70, by0 + bh / 2), "+1 STRENGTH", font=font(BOLD, 70), fill=(59, 42, 26), anchor="rm")
# an "x2 XP!" sticker on a soft dark shadow, like in the game
tag = Image.new("RGBA", (1100, 420))
td = ImageDraw.Draw(tag)
td.rounded_rectangle((60, 90, 1040, 330), 120, fill=(28, 18, 8, 120))
tag = tag.filter(ImageFilter.GaussianBlur(26))
im.paste(tag.rotate(8, resample=Image.BICUBIC), (int(W * 0.52), int(H * 0.53)), tag.rotate(8, resample=Image.BICUBIC))
title(im, "x2 XP!", W * 0.66, H * 0.62, 260, rot=8)
im.resize((1920, 1080), Image.LANCZOS).save("thumb3.png")  # copied to assets/marketing/store
