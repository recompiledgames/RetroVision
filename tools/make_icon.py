from PIL import Image, ImageDraw
import struct

S = 512  # draw big, downsample for smooth edges


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# antenna
d.line([(256, 120), (170, 30)], fill=(210, 200, 185, 255), width=16)
d.line([(256, 120), (345, 22)], fill=(210, 200, 185, 255), width=16)
d.ellipse([155, 15, 185, 45], fill=(255, 179, 71, 255))
d.ellipse([330, 7, 360, 37], fill=(255, 179, 71, 255))
d.ellipse([226, 100, 286, 140], fill=(120, 95, 80, 255))

# TV body
d.rounded_rectangle([28, 118, 484, 476], radius=60, fill=(60, 40, 34, 255))
d.rounded_rectangle([40, 128, 472, 462], radius=52, fill=(196, 132, 74, 255))
d.rounded_rectangle([40, 128, 472, 300], radius=52, fill=(214, 150, 88, 255))
d.rectangle([40, 250, 472, 300], fill=(196, 132, 74, 255))

# screen (sunset gradient + sun + scanlines)
sx0, sy0, sx1, sy1 = 66, 152, 380, 440
scr = Image.new("RGBA", (sx1 - sx0, sy1 - sy0))
sd = ImageDraw.Draw(scr)
h = sy1 - sy0
top, mid, bot = (40, 18, 80), (220, 70, 120), (255, 180, 70)
for y in range(h):
    t = y / h
    c = lerp(top, mid, t / 0.6) if t < 0.6 else lerp(mid, bot, (t - 0.6) / 0.4)
    sd.line([(0, y), (sx1 - sx0, y)], fill=c + (255,))
cx, cy, r = (sx1 - sx0) // 2, int(h * 0.62), 92
sd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 220, 110, 255))
sd.rectangle([0, int(h * 0.72), sx1 - sx0, h], fill=(30, 12, 60, 255))
for i, y in enumerate(range(int(h * 0.74), h, 14)):  # grid floor
    sd.line([(0, y), (sx1 - sx0, y)], fill=(127, 212, 255, 255), width=3)
for x in range(-300, 600, 46):
    sd.line([(cx, int(h * 0.72)), (x, h)], fill=(127, 212, 255, 255), width=3)
for y in range(0, h, 12):  # scanlines
    sd.rectangle([0, y + 7, sx1 - sx0, y + 11], fill=(0, 0, 0, 70))
# round the screen corners
mask = Image.new("L", scr.size, 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, scr.size[0] - 1, scr.size[1] - 1], radius=48, fill=255)
img.paste(scr, (sx0, sy0), mask)
d.rounded_rectangle([sx0, sy0, sx1, sy1], radius=48, outline=(40, 26, 22, 255), width=10)
# glare


# knobs + speaker
d.ellipse([398, 168, 456, 226], fill=(60, 40, 34, 255))
d.ellipse([408, 178, 446, 216], fill=(240, 220, 190, 255))
d.ellipse([398, 244, 456, 302], fill=(60, 40, 34, 255))
d.ellipse([408, 254, 446, 292], fill=(240, 220, 190, 255))
for y in range(330, 440, 22):
    d.rounded_rectangle([402, y, 452, y + 10], radius=5, fill=(90, 60, 45, 255))

# feet
d.rectangle([90, 476, 130, 500], fill=(60, 40, 34, 255))
d.rectangle([382, 476, 422, 500], fill=(60, 40, 34, 255))

img.save("/home/claude/icon_preview.png")


def save_tga(im, path):
    w, h = im.size
    px = im.load()
    data = bytearray()
    for y in range(h - 1, -1, -1):
        for x in range(w):
            r, g, b, a = px[x, y]
            data += bytes((b, g, r, a))
    hdr = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 8)
    open(path, "wb").write(hdr + data)


small = img.resize((64, 64), Image.LANCZOS)
save_tga(small, "/home/claude/RetroVision/Textures/icon.tga")
img.resize((128, 128), Image.LANCZOS).resize((512, 512), Image.NEAREST).save("/home/claude/icon_preview_small.png")
print("ok")
