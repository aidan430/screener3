import random, sys
sys.path.insert(0, ".")
from art import *
W, H = 3840, 2160
rnd = random.Random(11)
im = sky(W, H)
glow(im, W * 0.9, H * 0.08, 600, (255, 236, 170), 230)
for cx, cy, s in [(W * 0.08, H * 0.5, 150), (W * 0.66, H * 0.1, 120), (W * 0.93, H * 0.42, 160)]:
    cloud(im, cx, cy, s, rnd)
hills(im, H * 0.66, rnd)
barn(im, W * 0.03, H * 0.76, 280)
haystack(im, W * 0.5, H * 0.95, W * 0.62, H * 0.84, rnd)
needle(im, W * 0.56, H * 0.33, 420, -0.7)
flying_hay(im, W * 0.86, H * 0.28, 220, 40, rnd, 2.0)
farmer(im, W * 0.8, H * 0.97, 290)
title(im, "NEEDLE IN THE", W * 0.27, H * 0.11, 200, fill=(255, 255, 255), rot=4, max_w=W * 0.46)
title(im, "HAYSTACK!", W * 0.27, H * 0.28, 300, rot=4, max_w=W * 0.48)
im.resize((1920, 1080), Image.LANCZOS).save("thumb1.png")  # copied to assets/marketing/store
