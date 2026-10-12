"""High-resolution, anti-aliased textures for RetroVision's pretty effects.

Every shape is rendered supersampled with numpy, then box-filtered down, so edges
are smooth. Particle sprites are written at several sizes (16..256) so the addon
can pick one close to the on-screen size instead of shrinking a big image
(which aliases, because addon textures have no mipmaps).
"""
import os, struct
import numpy as np

OUT = "/home/claude/RetroVision/Textures"
rng = np.random.default_rng(4242)
TAU = np.pi * 2


def write_tga(name, rgba):
    """rgba: float array (h, w, 4) in 0..1, row 0 = top."""
    h, w, _ = rgba.shape
    a = np.clip(rgba, 0, 1)
    px = (a[::-1, :, [2, 1, 0, 3]] * 255 + 0.5).astype(np.uint8)  # bottom-up BGRA
    hdr = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 8)
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(hdr + px.tobytes())


def down(img, f):
    """box-filter by integer factor f (img: h, w, c)."""
    h, w, c = img.shape
    return img.reshape(h // f, f, w // f, f, c).mean(axis=(1, 3))


def smooth(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


def grid(n, m=None):
    m = m or n
    y, x = np.mgrid[0:m, 0:n].astype(np.float64)
    return (x + 0.5) / n * 2 - 1, (y + 0.5) / m * 2 - 1


def premul_white(a):
    return np.stack([a, a, a, a], axis=-1)


def straight(rgb, a):
    return np.concatenate([rgb, a[..., None]], axis=-1)


# ---------------------------------------------------------------------------
# particle sprites (rendered at 1024, written at 256/128/64/32/16)
# ---------------------------------------------------------------------------
BIG = 1024
SIZES = [256, 128, 64, 32, 16]


def emit_sprite(name, rgba_premul, straight_alpha=False):
    for s in SIZES:
        img = down(rgba_premul, BIG // s)
        if straight_alpha:  # un-premultiply for BLEND sprites
            a = img[..., 3:4]
            rgb = np.where(a > 1e-4, img[..., :3] / np.maximum(a, 1e-4), 1.0)
            img = np.concatenate([np.clip(rgb, 0, 1), a], axis=-1)
        write_tga(f"{name}_{s}", img)


u, v = grid(BIG)
r = np.hypot(u, v)

# soft glow (fireflies, embers, dust, motes, light leaks)
a = np.exp(-r * r * 5.5) * (1 - smooth((r - 0.8) / 0.2))
emit_sprite("p_glow", premul_white(a))

# snow / ash dot
a = 1 - smooth((r - 0.35) / 0.6)
emit_sprite("p_dot", premul_white(a), True)

# 4-point sparkle
d0, d1 = (u + v) / 1.414, (u - v) / 1.414
a = np.exp(-r * r * 40) \
    + np.exp(-np.abs(u) * 26) * np.exp(-np.abs(v) * 2.2) + np.exp(-np.abs(v) * 26) * np.exp(-np.abs(u) * 2.2) \
    + 0.35 * (np.exp(-np.abs(d0) * 30) * np.exp(-np.abs(d1) * 4.5) + np.exp(-np.abs(d1) * 30) * np.exp(-np.abs(d0) * 4.5))
a = np.clip(a, 0, 1) * (1 - smooth((r - 0.85) / 0.15))
emit_sprite("p_star", premul_white(a))

# bubble: crisp rim, faint body, highlight
rim = np.clip(1 - np.abs(r - 0.8) / 0.075, 0, 1) ** 1.3
body = 0.07 * (r < 0.8)
inner = 0.18 * np.clip(1 - np.abs(r - 0.74) / 0.05, 0, 1)
hl = np.exp(-(((u + 0.33) / 0.15) ** 2 + ((v + 0.36) / 0.09) ** 2)) * 0.95
hl2 = np.exp(-(((u - 0.38) / 0.06) ** 2 + ((v - 0.4) / 0.06) ** 2)) * 0.5
a = np.clip(rim * 0.95 + body + inner + hl + hl2, 0, 1)
emit_sprite("p_ring", premul_white(a))

# cherry petal (BLEND, white with soft shading)
vv = (v + 1) / 2
width = np.sin(np.pi * np.clip(vv, 0, 1) ** 0.85) * 0.62
cleft = np.hypot(u / 0.7, (v + 1.05) / 0.45)
e1 = np.clip((width - np.abs(u)) / 0.04, 0, 1)
e2 = np.clip((cleft - 1) / 0.08, 0, 1)
a = e1 * e2 * (1 - smooth((np.abs(v) - 0.93) / 0.04))
shade = 0.82 + 0.18 * (1 - np.abs(u) / np.maximum(width, 0.01))
vein = 1 - 0.08 * np.exp(-(u / 0.02) ** 2) * (v > -0.6)
rgb = np.stack([shade * vein, shade * 0.97 * vein, shade * vein], -1)
emit_sprite("p_petal", np.concatenate([rgb * a[..., None], a[..., None]], -1), True)

# leaf (BLEND)
width = np.sin(np.pi * np.clip((v + 1) / 2, 0, 1)) * 0.55
inside = np.clip((width - np.abs(u)) / 0.03, 0, 1) * (np.abs(v) < 0.97)
stem = (np.abs(u) < 0.035) * (v > 0.8) * (v < 1.0)
a = np.clip(inside + stem, 0, 1)
mid = 1 - 0.28 * np.exp(-(u / 0.022) ** 2)
side = np.zeros_like(u)
for k in range(-4, 5):  # side veins
    side += np.exp(-((v - (k * 0.18) - np.abs(u) * 0.9) / 0.018) ** 2)
side = 1 - 0.13 * np.clip(side, 0, 1) * (np.abs(u) < width * 0.9)
s = (0.8 + 0.2 * (1 - np.abs(u) / np.maximum(width, 0.01))) * mid * side
s = np.where(stem > 0, 0.65, s)
rgb = np.stack([s, s, s], -1)
emit_sprite("p_leaf", np.concatenate([rgb * a[..., None], a[..., None]], -1), True)

# rain streak (tall: 1024 x 128 -> written at 4 sizes with 8:1 aspect)
yy, xx = np.mgrid[0:1024, 0:128].astype(np.float64)
su = (xx + 0.5) / 128 * 2 - 1
sv = (yy + 0.5) / 1024
a = (1 - smooth(np.abs(su) / 0.7)) * smooth(sv / 0.5) * (1 - smooth((sv - 0.88) / 0.12))
img = premul_white(a)
for h in [256, 128, 64, 32]:
    f = 1024 // h
    small = down(img, f)
    alpha = small[..., 3:4]
    write_tga(f"p_streak_{h}", np.concatenate([np.ones_like(small[..., :3]), alpha], -1))

# ---------------------------------------------------------------------------
# full-screen layers
# ---------------------------------------------------------------------------
# bokeh: 1024 tile shown at 1 texel = 1 screen pixel, rendered 2x supersampled
N, SS = 1024, 2
yy, xx = np.mgrid[0:N * SS, 0:N * SS].astype(np.float32) / SS
buf = np.zeros((N * SS, N * SS), np.float32)
for _ in range(42):
    cx, cy = rng.uniform(0, N, 2)
    rad = rng.uniform(14, 95)
    br = rng.uniform(0.25, 1)
    dx = (xx - cx + N / 2) % N - N / 2  # wrap so it tiles
    dy = (yy - cy + N / 2) % N - N / 2
    d = np.hypot(dx, dy)
    mask = d < rad + 3
    body = 1 - smooth((d - (rad - 1.2)) / 2.4)
    rimw = rad * 0.06 + 0.8
    rim = np.exp(-((d - rad * 0.92) / rimw) ** 2) * 0.6
    buf += np.where(mask, br * (0.33 * body + rim), 0)
buf = np.clip(buf, 0, 1)
write_tga("bokeh_hd", down(premul_white(buf), SS))

# caustics: 1024 tile, integer frequencies so it tiles, 2x supersampled
yy, xx = np.mgrid[0:N * SS, 0:N * SS].astype(np.float64) / SS
waves = []
while len(waves) < 6:
    fx, fy = rng.integers(-5, 6, 2)
    if fx or fy:
        waves.append((fx, fy, rng.uniform(0, TAU)))
s1 = sum(np.cos(TAU * (fx * xx + fy * yy) / N + ph) for fx, fy, ph in waves[:3])
s2 = sum(np.cos(TAU * (fx * xx + fy * yy) / N + ph) for fx, fy, ph in waves[3:])
c = (1 - np.minimum(1, np.abs(s1) / 1.4)) ** 7 + (1 - np.minimum(1, np.abs(s2) / 1.4)) ** 7
c = np.clip(c * 0.85, 0, 1)
write_tga("caustics_hd", down(premul_white(c), SS))

# god rays: 1024, soft streaks so upscaling stays smooth
M = 1024
u, v = grid(M)
r = np.hypot(u, v)
ang = (np.arctan2(v, u) % TAU) / TAU
noise = rng.random(360)
# smooth periodic noise via a few harmonics + interpolated random beams
idx = ang * 360
i0 = np.floor(idx).astype(int) % 360
f = idx - np.floor(idx)
f = f * f * (3 - 2 * f)
beams = noise[i0] * (1 - f) + noise[(i0 + 1) % 360] * f
beams = beams ** 3.2
fall = np.exp(-r * 2.0) * (1 - smooth((r - 0.75) / 0.25))
a = np.clip(beams * fall * 1.7 + np.exp(-r * r * 30) * 0.55, 0, 1)
write_tga("rays_hd", premul_white(a))

# aurora: 1024 x 256, tileable horizontally
W, H = 1024, 256
yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
t = xx / W
curt = [(rng.integers(1, 7), rng.uniform(0, TAU), rng.uniform(0.3, 1)) for _ in range(10)]
center = 0.62 + 0.12 * np.sin(TAU * 2 * t + 1.3) + 0.06 * np.sin(TAU * 5 * t + 0.4)
streaks = sum(amp * (0.5 + 0.5 * np.cos(TAU * fr * 4 * t + ph)) for fr, ph, amp in curt) / sum(c[2] for c in curt)
fine = 0.85 + 0.15 * sum(np.cos(TAU * k * t + k) for k in (37, 53, 71)) / 3
yn = yy / H
below = yn - center
inten = np.where(below > 0, np.exp(-(below / 0.045) ** 2), np.exp(-(-below / (0.35 + 0.2 * streaks))))
inten *= (0.35 + 0.9 * streaks ** 1.5) * fine * smooth(yn / 0.15)
up = np.clip(-below / 0.45, 0, 1)
rgb = np.stack([0.15 + 0.55 * up ** 2, 0.95 - 0.55 * up, 0.55 + 0.4 * up], -1)
a = np.clip(inten, 0, 1)
write_tga("aurora_hd", np.concatenate([rgb * a[..., None], a[..., None]], -1))

print("done")
