"""Textures for the stylized looks and the new crisp god-ray beams."""
import os, struct
import numpy as np

OUT = "/home/claude/RetroVision/Textures"
rng = np.random.default_rng(777)
TAU = np.pi * 2


def write_tga(name, rgba, dither=False):
    h, w, _ = rgba.shape
    a = np.clip(rgba, 0, 1) * 255
    if dither:  # triangular noise hides 8-bit banding in smooth gradients
        n = (rng.random((h, w, 1)) - rng.random((h, w, 1)))
        a = np.clip(a + n, 0, 255)
    px = (a[::-1, :, [2, 1, 0, 3]] + 0.5).astype(np.uint8)
    hdr = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 8)
    with open(os.path.join(OUT, name + ".tga"), "wb") as f:
        f.write(hdr + px.tobytes())


def down2(a, f):
    h, w = a.shape
    return a.reshape(h // f, f, w // f, f).mean(axis=(1, 3))


def smooth(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


def white_alpha(a):  # straight alpha, white rgb (tinted in game)
    return np.stack([np.ones_like(a)] * 3 + [a], -1)


def premul(a):
    return np.stack([a, a, a, a], -1)


def periodic_noise(n, power=2.0, seed=0):
    """tileable fractal noise via FFT filtering, 0..1"""
    r = np.random.default_rng(seed)
    f = np.fft.fftfreq(n)
    fx, fy = np.meshgrid(f, f)
    k = np.hypot(fx, fy)
    k[0, 0] = 1
    spec = (r.normal(size=(n, n)) + 1j * r.normal(size=(n, n))) / k ** power
    spec[0, 0] = 0
    img = np.real(np.fft.ifft2(spec))
    img = (img - img.min()) / (img.max() - img.min())
    return img


# --- light beam (for god rays): x = along the beam (left = source), y = across
W, H = 512, 128
y, x = np.mgrid[0:H, 0:W].astype(np.float64)
u = (x + 0.5) / W
v = (y + 0.5) / H * 2 - 1
half = 0.12 + 0.88 * u            # widens away from the source
a = np.exp(-(v / (half * 0.5)) ** 2) * smooth(u / 0.06) * np.exp(-u * 2.4) * (1 - smooth((u - 0.55) / 0.45))
write_tga("beam", premul(np.clip(a, 0, 1)), dither=True)

# --- speed line: thick at the outer edge (left), tapering to a point (right)
W, H = 512, 32
y, x = np.mgrid[0:H * 4, 0:W].astype(np.float64)
u = (x + 0.5) / W
v = (y + 0.5) / (H * 4) * 2 - 1
half = 0.9 * (1 - u) ** 1.2 + 0.02
a = np.clip((half - np.abs(v)) / 0.18, 0, 1) * smooth(u / 0.02)
a = a.reshape(H, 4, W).mean(axis=1)
write_tga("speedline", white_alpha(a))

# --- rain line (horizontal streak for line-drawn rain)
W, H = 256, 16
y, x = np.mgrid[0:H, 0:W].astype(np.float64)
u = (x + 0.5) / W
v = (y + 0.5) / H * 2 - 1
a = np.exp(-(v / 0.45) ** 2) * smooth(u / 0.5) * (1 - smooth((u - 0.9) / 0.1))
write_tga("p_line", white_alpha(a))

# --- halftone: 45-degree dot lattice, 256 tile, 4x supersampled
N, S = 256, 4
y, x = np.mgrid[0:N * S, 0:N * S].astype(np.float64) / S
sp = 32.0
# distance to nearest lattice point of {(0,0),(16,16)} + 32-periodic
dx1 = (x % sp) - sp / 2
dy1 = (y % sp) - sp / 2
dx2 = ((x + sp / 2) % sp) - sp / 2
dy2 = ((y + sp / 2) % sp) - sp / 2
d = np.minimum(np.hypot(dx1, dy1), np.hypot(dx2, dy2))
a = (d < sp * 0.27).astype(np.float64)
write_tga("halftone", white_alpha(down2(a, S)))

# --- crosshatch: two diagonal line sets, 256 tile
y, x = np.mgrid[0:N * S, 0:N * S].astype(np.float64) / S
pitch = 8.0
l1 = np.abs(((x + y) % pitch) - pitch / 2) < 0.75
l2 = np.abs(((x - y) % pitch) - pitch / 2) < 0.6
jit = periodic_noise(N * S, 1.4, 5) > 0.42  # break lines up like pen strokes
a = np.clip(l1 * 1.0 + l2 * 0.75 * jit, 0, 1)
write_tga("hatch", white_alpha(down2(a, S)))

# --- paper grain: 1024 tile (dark specks + fibers + soft blotches)
N = 1024
blot = periodic_noise(N, 1.6, 11)
grain = periodic_noise(N, 0.6, 12)
fib = np.zeros((N, N))
for _ in range(700):
    x0, y0 = rng.uniform(0, N, 2)
    ang = rng.uniform(0, TAU)
    ln = rng.uniform(10, 60)
    t = np.linspace(0, 1, int(ln * 2))
    curve = rng.uniform(-0.4, 0.4)
    xs = (x0 + np.cos(ang + curve * t) * ln * t).astype(int) % N
    ys = (y0 + np.sin(ang + curve * t) * ln * t).astype(int) % N
    fib[ys, xs] += rng.uniform(0.3, 0.9)
fib = np.clip(fib, 0, 1)
a = np.clip(0.55 * (blot - 0.35) + 0.5 * (grain - 0.45) + 0.45 * fib, 0, 1)
write_tga("paper", white_alpha(a))

# --- comic ink frame: 2048x1024, rough brushy black border
W, H = 2048, 1024
y, x = np.mgrid[0:H, 0:W].astype(np.float64)
dl, dr, dt, db = x / H, (W - 1 - x) / H, y / H, (H - 1 - y) / H   # distances in "height" units
d = np.minimum(np.minimum(dl, dr), np.minimum(dt, db))
# perimeter coordinate for roughness, so each edge has its own wobble
per = np.where(d == dt, x / W, np.where(d == db, 2 + x / W, np.where(d == dl, 4 + y / H, 6 + y / H)))
wob = np.zeros_like(per)
for k, amp in [(7, 0.012), (19, 0.008), (53, 0.005), (131, 0.003), (311, 0.0018)]:
    wob += amp * np.sin(TAU * k * per / 2 + rng.uniform(0, TAU))
thick = 0.085 + wob
edge = np.clip((thick - d) * H / 1.5, 0, 1)            # ~1.5px soft edge
# dry-brush streaks near the inner edge
streak = (periodic_noise(1024, 1.0, 3)[np.clip((y * 1024 / H).astype(int), 0, 1023), np.clip((x * 1024 / W).astype(int), 0, 1023)] > 0.62)
inner = (d > thick) & (d < thick + 0.018)
a = np.clip(edge + inner * streak * 0.85 * np.clip(1 - (d - thick) / 0.018, 0, 1), 0, 1)
write_tga("inkframe", white_alpha(a))

# --- graffiti paint splatter for a corner (top-left), 1024, 2x supersampled
N, S = 1024, 2
y, x = np.mgrid[0:N * S, 0:N * S].astype(np.float64) / S
a = np.zeros_like(x)
r = np.hypot(x, y)
ang = np.arctan2(y, x)
rough = sum(rng.uniform(0.02, 0.06) * np.sin(k * ang * 4 + rng.uniform(0, TAU)) for k in range(2, 14))
a = np.maximum(a, (r < N * (0.36 + rough)).astype(float))
for _ in range(24):  # spikes / splashes radiating out
    th = rng.uniform(0.02, np.pi / 2 - 0.02)
    ln = N * rng.uniform(0.42, 0.75)
    wd = rng.uniform(6, 22)
    px, py = np.cos(th), np.sin(th)
    along = x * px + y * py
    across = np.abs(-x * py + y * px)
    taper = wd * np.clip(1 - along / ln, 0, 1) ** 0.7
    a = np.maximum(a, ((across < taper) & (along > 0)).astype(float))
    cx, cy = px * (ln + wd * 1.5), py * (ln + wd * 1.5)
    a = np.maximum(a, (np.hypot(x - cx, y - cy) < wd * 0.9).astype(float))
for _ in range(90):  # droplets
    th = rng.uniform(0, np.pi / 2)
    rr = N * rng.uniform(0.38, 0.95)
    cx, cy = np.cos(th) * rr, np.sin(th) * rr
    rad = rng.uniform(2, 12) * (1.2 - rr / N)
    a = np.maximum(a, (np.hypot(x - cx, y - cy) < rad).astype(float))
for _ in range(9):  # drips running down from the blob
    xx0 = rng.uniform(0.05, 0.36) * N
    top = np.sqrt(max((N * 0.34) ** 2 - xx0 ** 2, 0))
    ln = rng.uniform(0.08, 0.3) * N
    wd = rng.uniform(4, 9)
    m = (np.abs(x - xx0) < wd) & (y > top - 5) & (y < top + ln)
    a = np.maximum(a, m.astype(float))
    a = np.maximum(a, (np.hypot(x - xx0, y - (top + ln)) < wd * 1.35).astype(float))
write_tga("splatter", white_alpha(down2(a, S)))

# --- chromatic fringe: horizontal falloff from the left edge
W, H = 256, 8
x = (np.arange(W) + 0.5) / W
a = np.tile(((1 - x) ** 2.2)[None, :], (H, 1))
write_tga("fringe", premul(a))

print("done")
