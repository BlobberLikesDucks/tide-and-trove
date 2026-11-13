"""Turn the Canva UI exports (white background) into game-ready PNGs.

Runs inside Blender's Python (numpy + image IO, no extra installs):
    blender -b --factory-startup --python tools/process_ui_art.py -- art/canva_raw game/assets/ui

* flood-fills the white background from the image border and converts it to
  soft alpha (anti-aliased edges are un-premultiplied against white)
* crops to content, slices the 4x3 icon sheet, downsizes for the UI
"""
import os
import sys

import bpy
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = os.path.abspath(argv[0]), os.path.abspath(argv[1])
os.makedirs(DST, exist_ok=True)
ICON_NAMES = ["coin", "star", "ammonite", "backpack", "shovel", "pickaxe", "research", "happy", "plant", "broom", "walkie", "calendar"]


def load(name):
    img = bpy.data.images.load(os.path.join(SRC, name + ".png"))
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    return px.reshape(h, w, 4)[::-1].copy()  # top-left origin


def save(arr, name, size=None):
    arr = np.clip(arr, 0.0, 1.0)
    h, w = arr.shape[:2]
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels.foreach_set(arr[::-1].astype(np.float32).ravel())
    if size:
        img.scale(size[0], size[1])
    img.filepath_raw = os.path.join(DST, name + ".png")
    img.file_format = "PNG"
    img.save()
    print("saved", name, img.size[0], img.size[1])


def shift(m, dy, dx):
    out = np.zeros_like(m)
    h, w = m.shape
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    out[yd, xd] = m[ys, xs]
    return out


def dilate(m, n=1):
    for _ in range(n):
        m = m | shift(m, 1, 0) | shift(m, -1, 0) | shift(m, 0, 1) | shift(m, 0, -1)
    return m


def knock_out(px, thresh=0.90):
    rgb = px[:, :, :3]
    mn = rgb.min(axis=2)
    whiteish = mn > thresh
    bg = np.zeros_like(whiteish)
    bg[0, :] = whiteish[0, :]
    bg[-1, :] = whiteish[-1, :]
    bg[:, 0] = whiteish[:, 0]
    bg[:, -1] = whiteish[:, -1]
    for _ in range(4000):
        grown = dilate(bg) & whiteish
        if grown.sum() == bg.sum():
            break
        bg = grown
    edge = dilate(bg, 2)
    a = np.ones(mn.shape, dtype=np.float32)
    soft = np.clip((1.0 - mn) / (1.0 - 0.80), 0.0, 1.0)
    a[edge] = soft[edge]
    a[bg] = 0.0
    out = px.copy()
    safe = np.maximum(a, 1e-3)[:, :, None]
    out[:, :, :3] = np.where(a[:, :, None] > 0.0, (rgb - (1.0 - a[:, :, None])) / safe, rgb)
    out[:, :, 3] = a
    return out


def crop(px, pad=6):
    ys, xs = np.where(px[:, :, 3] > 0.04)
    y0, y1 = max(0, ys.min() - pad), min(px.shape[0], ys.max() + pad + 1)
    x0, x1 = max(0, xs.min() - pad), min(px.shape[1], xs.max() + pad + 1)
    return px[y0:y1, x0:x1]


def fit(px, size):
    h, w = px.shape[:2]
    k = size / max(h, w)
    return (max(1, int(round(w * k))), max(1, int(round(h * k))))


logo = crop(knock_out(load("logo")))
save(logo, "logo", fit(logo, 900))

ribbon = crop(knock_out(load("ribbon")))
save(ribbon, "ribbon", fit(ribbon, 700))

panel = crop(knock_out(load("panel")), pad=0)
ph, pw = panel.shape[:2]
save(panel, "panel", (int(pw * 0.42), int(ph * 0.42)))

sheet = knock_out(load("icons"))
H, W = sheet.shape[:2]
for i, n in enumerate(ICON_NAMES):
    r, c = divmod(i, 4)
    cell = sheet[int(r * H / 3):int((r + 1) * H / 3), int(c * W / 4):int((c + 1) * W / 4)]
    ic = crop(cell, pad=4)
    h, w = ic.shape[:2]
    s = max(h, w)
    sq = np.zeros((s, s, 4), dtype=np.float32)
    sq[(s - h) // 2:(s - h) // 2 + h, (s - w) // 2:(s - w) // 2 + w] = ic
    save(sq, "icon_" + n, (128, 128))

def scaled(px, k):
    h, w = px.shape[:2]
    return (max(1, int(w * k)), max(1, int(h * k)))


# --- AI-generated pieces ------------------------------------------------------
buttons = knock_out(load("buttons"))
rows = np.where(buttons[:, :, 3].max(axis=1) > 0.05)[0]
bands, start = [], rows[0]
for a, b in zip(rows, rows[1:]):
    if b - a > 8:
        bands.append((start, a))
        start = b
bands.append((start, rows[-1]))
for (y0, y1), nm in zip(bands, ["teal", "coral", "green", "gold", "grey"]):
    b = crop(buttons[y0:y1 + 1], pad=3)
    save(b, "btn_" + nm, scaled(b, 0.36))

card = crop(knock_out(load("card")), pad=2)
save(card, "card", scaled(card, 0.3))
pill = crop(knock_out(load("pill")), pad=2)
save(pill, "pill", scaled(pill, 0.3))

# --- Canva vector pieces (known layout on the page) ----------------------------
ctrl = load("controls")
RECTS = {
    "bar_track": (40, 40, 720, 90), "bar_gold": (40, 170, 720, 80), "bar_coral": (40, 280, 720, 80),
    "bar_purple": (40, 390, 720, 80), "bar_sky": (40, 500, 720, 80), "bar_green": (40, 610, 720, 80),
    "slider_track": (40, 760, 720, 44), "star_empty": (880, 40, 200, 200), "star_full": (1120, 40, 200, 200),
    "crosshair": (1380, 60, 160, 160), "check_off": (880, 300, 150, 150), "check_on": (1070, 300, 150, 150),
    "knob": (1260, 290, 170, 170), "btn_close": (1440, 290, 150, 150), "arrow_left": (880, 520, 150, 150),
    "arrow_right": (1070, 520, 150, 150),
}
for nm, (x, y, w, h) in RECTS.items():
    piece = ctrl[max(0, y - 8):y + h + 8, max(0, x - 8):x + w + 8]
    piece = crop(knock_out(piece), pad=2)
    k = 0.4 if nm.startswith(("bar", "slider")) else 0.5
    save(piece, "ui_" + nm, scaled(piece, k))

# icons3 = AI-generated Canva sheet (replaces the earlier vector icons2 page)
ICONS2 = ["check", "clock", "gear", "save", "ticket", "trash", "warning", "heart", "lock", "staff", "gem", "bone"]
sheet2 = load("icons3")
for i, n in enumerate(ICONS2):
    r, c = divmod(i, 4)
    cell = knock_out(sheet2[r * 400:(r + 1) * 400, c * 400:(c + 1) * 400])
    ic = crop(cell, pad=4)
    h, w = ic.shape[:2]
    s = max(h, w)
    sq = np.zeros((s, s, 4), dtype=np.float32)
    sq[(s - h) // 2:(s - h) // 2 + h, (s - w) // 2:(s - w) // 2 + w] = ic
    save(sq, "icon_" + n, (128, 128))

walkie = crop(knock_out(load("walkie")), pad=2)
save(walkie, "walkie", scaled(walkie, 0.3))
