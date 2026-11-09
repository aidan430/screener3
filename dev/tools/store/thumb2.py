import random, sys
sys.path.insert(0, ".")
from art import *
W, H = 3840, 2160
rnd = random.Random(5)
im = sky(W, H)
glow(im, W * 0.1, H * 0.05, 500, (255, 236, 170), 200)
cloud(im, W * 0.86, H * 0.12, 140, rnd)
hills(im, H * 0.8, rnd)
# a huge stack filling the frame
haystack(im, W * 0.5, H * 1.25, W * 1.25, H * 1.3, rnd)
# magnifying glass: a zoomed patch of hay with a big needle in it
mx, my, mr = W * 0.6, H * 0.56, 560
lens = Image.new("RGB", (int(mr * 2), int(mr * 2)))
patch = im.crop((int(mx - mr / 2.6), int(my - mr / 2.6), int(mx + mr / 2.6), int(my + mr / 2.6))).resize(lens.size, Image.LANCZOS)
lens.paste(patch)
glow(lens, mr, mr, mr * 0.9, (255, 240, 200), 60)
needle(lens, mr * 1.02, mr * 1.0, mr * 1.25, -0.6, glint=False)
sparkle(lens, mr * 1.4, mr * 0.7, mr * 0.45)
circle = Image.new("L", lens.size, 0)
ImageDraw.Draw(circle).ellipse((0, 0, mr * 2, mr * 2), fill=255)
d = ImageDraw.Draw(im)
# handle, then rim, then the lens
hx, hy = mx + mr * 0.72, my + mr * 0.72
d.line([(hx, hy), (hx + mr * 0.75, hy + mr * 0.75)], fill=(110, 66, 30), width=150)
d.line([(hx, hy), (hx + mr * 0.75, hy + mr * 0.75)], fill=(150, 96, 48), width=110)
sh = Image.new("RGBA", im.size)
ImageDraw.Draw(sh).ellipse((mx - mr - 60, my - mr - 30, mx + mr + 90, my + mr + 120), fill=(40, 20, 0, 120))
sh = sh.filter(ImageFilter.GaussianBlur(50))
im.paste(sh, (0, 0), sh)
d = ImageDraw.Draw(im)
d.ellipse((mx - mr - 60, my - mr - 60, mx + mr + 60, my + mr + 60), fill=(60, 64, 72))
d.ellipse((mx - mr - 40, my - mr - 40, mx + mr + 40, my + mr + 40), fill=(170, 176, 186))
im.paste(lens, (int(mx - mr), int(my - mr)), circle)
glare = Image.new("RGBA", im.size)
ImageDraw.Draw(glare).arc((mx - mr * 0.8, my - mr * 0.8, mx + mr * 0.8, my + mr * 0.8), 200, 250, fill=(255, 255, 255, 150), width=40)
glare = glare.filter(ImageFilter.GaussianBlur(6))
im.paste(glare, (0, 0), glare)
farmer(im, W * 0.15, H * 1.02, 280, fork=False)
title(im, "5,000,000 STRAWS", W * 0.32, H * 0.13, 230, fill=(255, 255, 255), rot=3, max_w=W * 0.58)
title(im, "1 NEEDLE!", W * 0.3, H * 0.33, 340, rot=3, max_w=W * 0.5)
title(im, "CAN YOU FIND IT?", W * 0.62, H * 0.92, 170, fill=(255, 255, 255), rot=-2, max_w=W * 0.6)
im.resize((1920, 1080), Image.LANCZOS).save("thumb2.png")  # copied to assets/marketing/store
