"""Shader-grade textures for the retro filters, based on techniques from
CRT-Royale / CRT-Lottes / Guest-Advanced (Gaussian beams, sub-pixel masks),
film grain models (zero-mean Gaussian grain) and VHS simulators.
Prints the average brightness each mask/scanline keeps, for brightness compensation."""
import os, struct, json
import numpy as np

OUT = "/home/claude/RetroVision/Textures"
rng = np.random.default_rng(2024)


def write_tga(name, rgba, dither=False):
    h, w, _ = rgba.shape
    a = np.clip(rgba, 0, 1) * 255
    if dither:
        a = np.clip(a + (rng.random((h, w, 1)) - rng.random((h, w, 1))), 0, 255)
    px = (a[::-1, :, [2, 1, 0, 3]] + 0.5).astype(np.uint8)
    hdr = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 8)
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(hdr + px.tobytes())


def black_alpha(a):
    return np.stack([np.zeros_like(a)] * 3 + [a], -1)


def premul(a):
    return np.stack([a, a, a, a], -1)


def smooth(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


info = {}

# ---- Gaussian scanline beams: one scanline period = 64 texels (sampled with
# linear filtering, so any line height works). alpha = how dark between beams.
# hardness 1..5 = beam sigma, like Lottes' hardScan.
y = (np.arange(64) + 0.5) / 64           # 0..1 across one line
d = np.minimum(np.abs(y - 0.5), 1 - np.abs(y - 0.5))  # distance from beam center
SIG = {1: 0.34, 2: 0.28, 3: 0.23, 4: 0.18, 5: 0.14}
info["scan"] = {}
for h, sg in SIG.items():
    # generalized gaussian beam (shape 2..3 gets flatter tops when harder)
    p = 2 + 0.25 * (h - 1)
    beam = np.exp(-(np.abs(y - 0.5) / sg) ** p)
    beam = beam / beam.max()
    dark = 1 - beam
    img = black_alpha(np.tile(dark[:, None], (1, 4)))
    write_tga(f"scanbeam_{h}", img)
    info["scan"][h] = float(dark.mean())   # average darkening at full strength

# ---- phosphor masks (MOD blend), 20 strength levels each
R, G, B = np.array([1, .18, .18]), np.array([.18, 1, .18]), np.array([.18, .18, 1])
M = np.array([1, .18, 1])   # magenta = R+B
GR = np.array([.18, 1, .18])
info["mask"] = {}


def emit_mask(name, cells, linear_period=None):
    """cells: (h, w, 3) at full strength. If linear_period, the pattern is
    oversampled (64 texels per period) for use with linear filtering."""
    full = cells
    lum = (0.3 * full[..., 0] + 0.59 * full[..., 1] + 0.11 * full[..., 2]).mean()
    info["mask"][name] = float(lum)
    for lvl in range(1, 21):
        k = lvl / 20
        img = 1 - (1 - full) * k
        write_tga(f"mask_{name}_{lvl}", np.concatenate([img, np.ones(img.shape[:2] + (1,))], -1))


# 2-px magenta/green (Lottes-style, great for 1080p-1440p)
emit_mask("mg2", np.array([[M, GR], [M, GR]]))
# 3-px RGB aperture grille: 64 texels = one triad, read with linear filtering
xs = (np.arange(64) + 0.5) / 64
third = np.floor(xs * 3).astype(int)
row = np.array([R, G, B])[third]
emit_mask("rgb3", np.tile(row[None, :, :], (4, 1, 1)))

# record existing masks' brightness (same formula as make_textures.py)
Rr, Gg, Bb, K, D = (1, .2, .2), (.2, 1, .2), (.2, .2, 1), (.55, .55, .55), (.4, .4, .4)
for nm, pat in {"grille": [[Rr, Gg, Bb, K]] * 4,
                "dots": [[Rr, Gg, Bb, K], [K] * 4, [Bb, K, Rr, Gg], [K] * 4]}.items():
    a = np.array(pat, float)
    info["mask"][nm] = float((0.3 * a[..., 0] + 0.59 * a[..., 1] + 0.11 * a[..., 2]).mean())
slot = []
for yy in range(4):
    r_ = []
    for xx in range(8):
        cell, col = divmod(xx, 4)
        r_.append(D if yy == (3 if cell == 0 else 1) else [Rr, Gg, Bb, K][col])
    slot.append(r_)
a = np.array(slot, float)
info["mask"]["slot"] = float((0.3 * a[..., 0] + 0.59 * a[..., 1] + 0.11 * a[..., 2]).mean())
# the old masks were baked as 1-(1-c)*0.8*k ; normalise their info the same way as new ones
for nm in ("grille", "dots", "slot"):
    info["mask"][nm] = 1 - (1 - info["mask"][nm]) * 0.8 / 0.8

# ---- film grain: zero-mean Gaussian, lightly blurred (~0.7px), 4 frames
def blur(img, s):
    f = np.fft.fftfreq(img.shape[0])
    fx, fy = np.meshgrid(f, f)
    return np.real(np.fft.ifft2(np.fft.fft2(img) * np.exp(-2 * (np.pi * s) ** 2 * (fx ** 2 + fy ** 2))))


N = 256
for i in range(1, 5):
    n = blur(rng.normal(size=(N, N)), 0.7)
    n = n / n.std() * 0.33
    write_tga(f"grainD_{i}", black_alpha(np.clip(-n, 0, 1)))
    write_tga(f"grainL_{i}", premul(np.clip(n, 0, 1)))
    c = np.stack([blur(rng.normal(size=(N, N)), 0.8) for _ in range(3)], -1)
    c = np.clip(c / c.std() * 0.33, 0, 1)
    write_tga(f"grainC_{i}", np.concatenate([c, c.max(-1, keepdims=True)], -1))

# ---- VHS snow: sparse bright specks, slightly stretched horizontally
sn = rng.random((N, N))
sn = np.where(sn > 0.985, rng.uniform(0.5, 1, (N, N)), 0)
sn = np.maximum(sn, np.roll(sn, 1, axis=1) * 0.6)
write_tga("snow", premul(sn))

# ---- film damage: dust speck and scratch
u, v = np.meshgrid((np.arange(64) + .5) / 32 - 1, (np.arange(64) + .5) / 32 - 1)
ang = np.arctan2(v, u)
rr = np.hypot(u, v) / (0.55 + 0.12 * np.sin(3 * ang + 1) + 0.08 * np.sin(5 * ang + 2))
write_tga("dust", black_alpha(1 - smooth((rr - 0.8) / 0.25)))
sy = (np.arange(256) + .5) / 256
sx = (np.arange(8) + .5) / 4 - 1
scr = np.exp(-(sx[None, :] / 0.35) ** 2) * (0.6 + 0.4 * np.sin(sy[:, None] * 40) ** 2) * smooth(sy[:, None] / .1) * smooth((1 - sy[:, None]) / .1)
write_tga("scratch", premul(np.clip(scr, 0, 1)))

# ---- ordered dither 8x8 Bayer, and blue noise 64x64 (dark + light halves)
def bayer(n):
    if n == 1:
        return np.array([[0]])
    b = bayer(n // 2)
    return np.block([[4 * b, 4 * b + 2], [4 * b + 3, 4 * b + 1]])


b8 = (bayer(8) + 0.5) / 64 - 0.5
write_tga("dither8_dark", black_alpha(np.clip(-b8 * 2, 0, 1)))
write_tga("dither8_light", premul(np.clip(b8 * 2, 0, 1)))
w = rng.normal(size=(64, 64))
f = np.fft.fftfreq(64)
fx, fy = np.meshgrid(f, f)
k = np.hypot(fx, fy)
bn = np.real(np.fft.ifft2(np.fft.fft2(w) * np.clip(k / 0.25, 0, 1) ** 2))
order = bn.ravel().argsort().argsort().reshape(64, 64)
bn = (order + 0.5) / 4096 - 0.5
write_tga("bluenoise_dark", black_alpha(np.clip(-bn * 2, 0, 1)))
write_tga("bluenoise_light", premul(np.clip(bn * 2, 0, 1)))

# ---- LCD pixel grid: one virtual pixel = 64 texels, dark gaps at the cell edges
c = (np.arange(64) + .5) / 64
edge = np.minimum(c, 1 - c)
gap = 1 - smooth((edge - 0.03) / 0.07)
grid = np.maximum(gap[None, :], gap[:, None])
write_tga("lcdgrid", black_alpha(grid))

# ---- CRT glass glare (soft diagonal reflection), 512, dithered
u, v = np.meshgrid((np.arange(512) + .5) / 512, (np.arange(512) + .5) / 512)
g = np.exp(-(((u - 0.18) * 1.2 + (v - 0.12)) / 0.16) ** 2 - ((u - 0.25) / 0.35) ** 2) * 0.9
g += 0.25 * np.exp(-((u - 0.8) ** 2 + (v - 0.85) ** 2) / 0.05)
write_tga("glare", premul(np.clip(g, 0, 1)), dither=True)

# ---- rolling refresh bar: soft vertical band
yb = (np.arange(256) + .5) / 256
band = np.exp(-((yb - 0.5) / 0.18) ** 2)
write_tga("rollbar", premul(np.tile(band[:, None], (1, 4))), dither=True)

# ---- vignette: natural cos^4 style falloff, 512, dithered (no banding)
u, v = np.meshgrid((np.arange(512) + .5) / 256 - 1, (np.arange(512) + .5) / 256 - 1)
r = np.hypot(u, v) / np.sqrt(2)
vig = 1 - np.cos(np.clip(r, 0, 1) * np.pi / 2 * 0.95) ** 4
vig = smooth((vig - 0.05) / 0.95) ** 1.1
write_tga("vignette_hd", black_alpha(vig), dither=True)

with open("/home/claude/crt_info.json", "w") as f:
    json.dump(info, f, indent=1)
print(json.dumps(info))
