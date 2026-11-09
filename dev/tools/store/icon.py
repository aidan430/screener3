import random, sys
sys.path.insert(0, ".")
from art import *
S = 2048
rnd = random.Random(8)
im = sky(S, S, top=(52, 136, 232), bottom=(170, 220, 252))
glow(im, S * 0.5, S * 0.4, 900, (255, 236, 170), 180)
rays = Image.new("RGBA", im.size)
rd = ImageDraw.Draw(rays)
for i in range(14):
    a0 = i / 14 * math.tau
    rd.polygon([(S / 2, S * 0.42), (S / 2 + math.cos(a0) * 2000, S * 0.42 + math.sin(a0) * 2000), (S / 2 + math.cos(a0 + 0.14) * 2000, S * 0.42 + math.sin(a0 + 0.14) * 2000)], fill=(255, 248, 210, 60))
im.paste(rays, (0, 0), rays)
hills(im, S * 0.78, rnd)
haystack(im, S * 0.5, S * 1.02, S * 1.3, S * 0.74, rnd)
needle(im, S * 0.52, S * 0.47, 900, -0.72, glint=False)
sparkle(im, S * 0.67, S * 0.3, 360)
for x, y, r in [(S * 0.2, S * 0.22, 70), (S * 0.86, S * 0.58, 55)]:
    sparkle(im, x, y, r)
im.resize((512, 512), Image.LANCZOS).save("icon.png")
im.resize((128, 128), Image.LANCZOS).save("icon_small_check.png")
