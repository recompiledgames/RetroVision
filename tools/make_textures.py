import os, math, random, struct

OUT = "/home/claude/RetroVision/Textures"
os.makedirs(OUT, exist_ok=True)
random.seed(1337)

def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))

def write_tga(name, w, h, px):
    """px(x, y) -> (r, g, b, a) floats 0..1, y=0 is the TOP row."""
    data = bytearray()
    for y in range(h - 1, -1, -1):          # TGA stores bottom row first
        for x in range(w):
            r, g, b, a = px(x, y)
            data += bytes((int(clamp(b) * 255 + .5), int(clamp(g) * 255 + .5),
                           int(clamp(r) * 255 + .5), int(clamp(a) * 255 + .5)))
    hdr = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 8)
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(hdr + data)

# --- scanlines: black, alpha profile per row --------------------------------
for name, rows in {
    "scan_fine":   [0, 1],
    "scan_medium": [0, .25, 1, .25],
    "scan_chunky": [0, 0, .15, .55, 1, 1, .55, .15],
}.items():
    write_tga(name, 8, len(rows), lambda x, y, r=rows: (0, 0, 0, r[y]))

# --- phosphor masks (used with MOD blend, so baked at 5 strengths) ----------
R, G, B, K, D = (1, .2, .2), (.2, 1, .2), (.2, .2, 1), (.55, .55, .55), (.4, .4, .4)
grille = [[R, G, B, K]] * 4
slot = []
for y in range(4):
    row = []
    for x in range(8):
        cell, col = divmod(x, 4)
        dark_row = 3 if cell == 0 else 1
        row.append(D if y == dark_row else [R, G, B, K][col])
    slot.append(row)
dots = [[R, G, B, K], [K] * 4, [B, K, R, G], [K] * 4]
for mname, pat in {"grille": grille, "slot": slot, "dots": dots}.items():
    h, w = len(pat), len(pat[0])
    for lvl in range(1, 21):
        s = 0.8 * lvl / 20
        def px(x, y, pat=pat, s=s):
            c = pat[y][x]
            return (1 - (1 - c[0]) * s, 1 - (1 - c[1]) * s, 1 - (1 - c[2]) * s, 1)
        write_tga(f"mask_{mname}_{lvl}", w, h, px)

# --- ordered dither (Bayer 4x4), dark (BLEND) + light (ADD, premultiplied) --
bayer = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
def dark(x, y):
    a = clamp((7.5 - bayer[y][x]) / 7.5)
    return (0, 0, 0, a)
def light(x, y):
    a = clamp((bayer[y][x] - 7.5) / 7.5)
    return (a, a, a, a)
write_tga("dither_dark", 4, 4, dark)
write_tga("dither_light", 4, 4, light)

# --- film grain noise (premultiplied white) ---------------------------------
noise = [[random.random() ** 1.6 for _ in range(128)] for _ in range(128)]
write_tga("noise", 128, 128, lambda x, y: (noise[y][x],) * 4)

# --- vignette ---------------------------------------------------------------
def vig(x, y, n=256):
    u = (x + .5) / n * 2 - 1
    v = (y + .5) / n * 2 - 1
    r = math.sqrt(u * u + v * v) / math.sqrt(2)
    t = clamp((r - .35) / .65)
    t = t * t * (3 - 2 * t)
    return (0, 0, 0, t ** 1.3)
write_tga("vignette", 256, 256, vig)

# --- CRT corner (top-left; opaque outside quarter circle, anti-aliased) ------
def corner(x, y, n=128):
    best = 0
    for sx in (.25, .75):
        for sy in (.25, .75):
            d = math.hypot(x + sx - n, y + sy - n)
            best += 1 if d > n else 0
    return (0, 0, 0, best / 4)
write_tga("corner", 128, 128, corner)

# --- VHS tracking band (premultiplied white streaks) -------------------------
streak = []
for y in range(32):
    row, x = [0.0] * 128, 0
    while x < 128:
        ln = random.randint(2, 30)
        val = random.random() ** 3 if random.random() < .55 else 0
        for i in range(x, min(128, x + ln)):
            row[i] = val
        x += ln
    streak.append(row)
def vhs(x, y):
    prof = math.exp(-((y - 15.5) / 8.5) ** 2)
    a = clamp(prof * (.25 + .9 * streak[y][x]))
    return (a, a, a, a)
write_tga("vhs", 128, 32, vhs)

print(sorted(os.listdir(OUT)))
