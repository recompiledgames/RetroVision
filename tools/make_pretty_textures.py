import os, math, random, struct, colorsys

OUT = "/home/claude/RetroVision/Textures"
random.seed(4242)
TAU = math.pi * 2


def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def write_tga(name, w, h, px):
    data = bytearray()
    for y in range(h - 1, -1, -1):
        for x in range(w):
            r, g, b, a = px(x, y)
            data += bytes((int(clamp(b) * 255 + .5), int(clamp(g) * 255 + .5),
                           int(clamp(r) * 255 + .5), int(clamp(a) * 255 + .5)))
    hdr = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 8)
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(hdr + data)


def smooth(t):
    t = clamp(t)
    return t * t * (3 - 2 * t)


def uv(x, y, n):
    return (x + .5) / n * 2 - 1, (y + .5) / n * 2 - 1


# ---- particle sprites ------------------------------------------------------
def glow(x, y, n=128):  # premultiplied soft glow
    u, v = uv(x, y, n)
    r = math.hypot(u, v)
    a = math.exp(-r * r * 5.5) * (1 - smooth((r - .8) / .2))
    return (a, a, a, a)
write_tga("p_glow", 128, 128, glow)


def dot(x, y, n=32):  # straight-alpha white soft disc (snow)
    u, v = uv(x, y, n)
    r = math.hypot(u, v)
    return (1, 1, 1, 1 - smooth((r - .35) / .6))
write_tga("p_dot", 32, 32, dot)


def streak(x, y, w=16, h=64):  # straight-alpha rain streak
    u = (x + .5) / w * 2 - 1
    v = (y + .5) / h
    a = (1 - smooth(abs(u) / .9)) * smooth(v / .5) * (1 - smooth((v - .85) / .15))
    return (1, 1, 1, a)
write_tga("p_streak", 16, 64, streak)


def petal(x, y, n=64):
    u, v = uv(x, y, n)
    # rounded teardrop (point at the bottom) with a soft cleft at the top
    vv = (v + 1) / 2
    width = math.sin(math.pi * clamp(vv) ** .85) * .62
    cleft = math.hypot(u / .7, (v + 1.05) / .45)
    e1 = clamp((width - abs(u)) / .1)
    e2 = clamp((cleft - 1) / .25)
    a = e1 * e2 * (1 - smooth((abs(v) - .9) / .08))
    shade = .82 + .18 * (1 - abs(u) / max(width, .01))
    return (shade, shade * .97, shade, a)
write_tga("p_petal", 64, 64, petal)


def leaf(x, y, n=64):
    u, v = uv(x, y, n)
    width = math.sin(math.pi * clamp((v + 1) / 2)) * .55
    if abs(u) > width or abs(v) > .97:
        if abs(u) < .04 and v > .85:  # stem
            return (.7, .7, .7, 1)
        return (0, 0, 0, 0)
    edge = clamp((width - abs(u)) / .1)
    vein = 1 - .25 * math.exp(-(u / .035) ** 2)
    side = 1 - .12 * math.exp(-((abs(u) - (v + 1) * .1) / .03) ** 2)
    s = (.8 + .2 * (1 - abs(u) / max(width, .01))) * vein * side
    return (s, s, s, edge)
write_tga("p_leaf", 64, 64, leaf)


def star(x, y, n=64):  # premultiplied 4-point sparkle
    u, v = uv(x, y, n)
    r = math.hypot(u, v)
    core = math.exp(-r * r * 40)
    spikes = math.exp(-abs(u) * 26) * math.exp(-abs(v) * 2.2) + math.exp(-abs(v) * 26) * math.exp(-abs(u) * 2.2)
    d = (u + v) / 1.414, (u - v) / 1.414
    spikes2 = .35 * (math.exp(-abs(d[0]) * 30) * math.exp(-abs(d[1]) * 4.5) + math.exp(-abs(d[1]) * 30) * math.exp(-abs(d[0]) * 4.5))
    a = clamp(core + spikes + spikes2) * (1 - smooth((r - .85) / .15))
    return (a, a, a, a)
write_tga("p_star", 64, 64, star)


def ring(x, y, n=64):  # premultiplied bubble
    u, v = uv(x, y, n)
    r = math.hypot(u, v)
    a = .9 * math.exp(-((r - .78) / .07) ** 2) + .08 * (1 - smooth((r - .7) / .1))
    hl = .9 * math.exp(-(((u + .32) / .14) ** 2 + ((v + .36) / .1) ** 2))
    a = clamp(a + hl)
    return (a, a, a, a)
write_tga("p_ring", 64, 64, ring)


# ---- full-screen layers ----------------------------------------------------
def edgeglow(x, y, n=256):  # premultiplied white vignette (for colored aura)
    u, v = uv(x, y, n)
    d = max(abs(u), abs(v)) * .55 + math.hypot(u, v) / 1.414 * .45
    a = smooth((d - .45) / .55) ** 1.6
    return (a, a, a, a)
write_tga("edgeglow", 256, 256, edgeglow)

# god rays: streaks radiating from the center
ray_noise = [random.random() for _ in range(720)]
def rays(x, y, n=512):
    u, v = uv(x, y, n)
    r = math.hypot(u, v)
    ang = (math.atan2(v, u) % TAU) / TAU * 720
    i = int(ang)
    f = ang - i
    rn = ray_noise[i % 720] * (1 - f) + ray_noise[(i + 1) % 720] * f
    beam = rn ** 3.5
    fall = math.exp(-r * 2.2) * (1 - smooth((r - .75) / .25))
    a = clamp(beam * fall * 1.6 + math.exp(-r * r * 30) * .6)
    return (a, a, a, a)
write_tga("rays", 512, 512, rays)


def holo(x, y, n=256):  # premultiplied tileable diagonal rainbow
    t = ((x + y) / n) % 1.0
    r, g, b = colorsys.hsv_to_rgb(t, .65, 1)
    band = .55 + .45 * math.sin(TAU * ((x - y) / n * 3))
    a = .55 * band
    return (r * a, g * a, b * a, a)
write_tga("holo", 256, 256, holo)

# caustics: integer-frequency waves so the texture tiles
waves = [((random.randint(-5, 5), random.randint(-5, 5)), random.random() * TAU) for _ in range(7)]
waves = [w for w in waves if w[0] != (0, 0)]
def caustic(x, y, n=256):
    s1 = sum(math.cos(TAU * (fx * x + fy * y) / n + ph) for (fx, fy), ph in waves[:len(waves) // 2])
    s2 = sum(math.cos(TAU * (fx * x + fy * y) / n + ph) for (fx, fy), ph in waves[len(waves) // 2:])
    a = (1 - min(1, abs(s1) / 1.4)) ** 6 + (1 - min(1, abs(s2) / 1.4)) ** 6
    a = clamp(a * .8)
    return (a, a, a, a)
write_tga("caustics", 256, 256, caustic)

# aurora curtains, tileable horizontally
curt = [(random.randint(1, 6), random.random() * TAU, random.random()) for _ in range(9)]
def aurora(x, y, w=512, h=128):
    t = x / w
    center = .62 + .12 * math.sin(TAU * (2 * t) + 1.3) + .06 * math.sin(TAU * (5 * t) + .4)
    streaks = sum(a * (.5 + .5 * math.cos(TAU * f * 4 * t + p)) for f, p, a in curt) / sum(c[2] for c in curt)
    yy = y / h  # 0 top, 1 bottom
    below = yy - center
    if below > 0:
        inten = math.exp(-(below / .05) ** 2)
    else:
        inten = math.exp(-(-below / (.35 + .2 * streaks)))
    inten *= .35 + .9 * streaks ** 1.5
    inten *= smooth(yy / .15)
    up = clamp(-below / .45)
    r, g, b = (.15 + .55 * up ** 2, .95 - .55 * up, .55 + .4 * up)
    a = clamp(inten)
    return (r * a, g * a, b * a, a)
write_tga("aurora", 512, 128, aurora)

# bokeh / lens dust, tileable
circles = []
for _ in range(38):
    circles.append((random.random() * 512, random.random() * 512, random.uniform(8, 46), random.uniform(.25, 1)))
bokeh_buf = [[0.0] * 512 for _ in range(512)]
for cx, cy, r, br in circles:
    for yy in range(int(cy - r - 2), int(cy + r + 3)):
        for xx in range(int(cx - r - 2), int(cx + r + 3)):
            d = math.hypot(xx - cx, yy - cy)
            if d > r + 1.5:
                continue
            body = 1 - smooth((d - (r - 1.5)) / 3)
            rim = math.exp(-((d - r * .9) / (r * .08 + .8)) ** 2) * .6
            val = br * (.35 * body + rim)
            px, py = xx % 512, yy % 512
            bokeh_buf[py][px] = min(1, bokeh_buf[py][px] + val)
write_tga("bokeh", 512, 512, lambda x, y: (bokeh_buf[y][x],) * 4)

print("done")
