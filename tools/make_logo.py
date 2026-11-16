"""Tide & Trove logo + app icons (flat "Stylistic" look, same Cooper Black face as
the in-game signs). Runs inside Blender's Python:

    blender -b --factory-startup --python tools/make_logo.py -- OUT_DIR

Writes:
  logo.png         1200x900  wordmark: teal "Tide", coral "&", gold "Trove" with an
                   ammonite as the "o" (main menu + boot splash)
  emblem.png       1024x1024 ammonite on a teal badge (app icon source)
  icon_<n>.png     16..256 px icons, icon.ico (multi-size), boot_splash.png

Shapes are drawn flat (Workbench, flat lighting, Standard view transform so the
hex colours come out exact); the warm-brown ink outline and the soft drop shadow
are added afterwards in numpy by dilating the alpha mask.
"""
import math
import os
import struct
import sys

import bpy
import bmesh
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0] if argv else "logo_out")
os.makedirs(OUT, exist_ok=True)

FONT_PATHS = ["C:/Windows/Fonts/COOPBL.TTF", "/System/Library/Fonts/Supplemental/Cooper Black.ttf"]

INK = "#3b2618"        # warm-brown outline (matches the in-game ink outline)
CREAM = "#fff3d6"
GOLD = "#f7b740"
GOLD_DK = "#cf7f24"
CORAL = "#ff7a59"
TEAL = "#2f9c9a"
TEAL_LT = "#5cc4b8"


def lin(h):
    h = h.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


def srgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float32)


_mats = {}


def mat(h):
    if h not in _mats:
        m = bpy.data.materials.new("C" + h)
        m.diffuse_color = (*lin(h), 1.0)
        _mats[h] = m
    return _mats[h]


def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)


def setup(res_x, res_y, ortho):
    scn = bpy.context.scene
    try:
        scn.render.engine = "BLENDER_WORKBENCH"
    except TypeError:
        pass
    scn.display.shading.light = "FLAT"
    scn.display.shading.color_type = "MATERIAL"
    scn.display.shading.show_object_outline = False
    try:
        scn.display.render_aa = "32"
    except TypeError:
        pass
    scn.render.film_transparent = True
    scn.view_settings.view_transform = "Standard"
    scn.view_settings.look = "None"
    scn.render.resolution_x, scn.render.resolution_y = res_x, res_y
    scn.render.resolution_percentage = 100
    scn.render.image_settings.file_format = "PNG"
    scn.render.image_settings.color_mode = "RGBA"
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = ortho
    cam = bpy.data.objects.new("cam", cam_d)
    cam.location = (0, 0, 10)
    scn.collection.objects.link(cam)
    scn.camera = cam


def poly(points, h, z=0.0, name="poly"):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, z)) for x, y in points]
    bm.faces.new(vs)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat(h))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def strip(left, right, h, z=0.0, name="strip"):
    """Quad strip between two polylines (same length)."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    a = [bm.verts.new((x, y, z)) for x, y in left]
    b = [bm.verts.new((x, y, z)) for x, y in right]
    for i in range(len(a) - 1):
        bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat(h))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def disc(cx, cy, r, h, z=0.0, seg=96):
    return poly([(cx + r * math.cos(t), cy + r * math.sin(t)) for t in (2 * math.pi * i / seg for i in range(seg))], h, z, "disc")


_font = None


def text(body, h, size, x, y, z=0.0):
    global _font
    if _font is None:
        for p in FONT_PATHS:
            if os.path.exists(p):
                _font = bpy.data.fonts.load(p)
                break
    cu = bpy.data.curves.new("t", "FONT")
    cu.body = body
    if _font:
        cu.font = _font
    cu.size = size
    cu.align_x = "CENTER"
    cu.resolution_u = 24
    cu.materials.append(mat(h))
    ob = bpy.data.objects.new("t", cu)
    ob.location = (x, y, z)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def bounds(ob):
    bpy.context.view_layer.update()
    xs = [(ob.matrix_world @ __import__("mathutils").Vector(c)).x for c in ob.bound_box]
    ys = [(ob.matrix_world @ __import__("mathutils").Vector(c)).y for c in ob.bound_box]
    return min(xs), max(xs), min(ys), max(ys)


def stroke(pts, widths, h, z=0.0, name="stroke"):
    """Thick polyline with a width per point (round-ish ends via the ink pass)."""
    left, right = [], []
    n = len(pts)
    for i, (x, y) in enumerate(pts):
        j, k = min(i + 1, n - 1), max(i - 1, 0)
        dx, dy = pts[j][0] - pts[k][0], pts[j][1] - pts[k][1]
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        w = widths[i] / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return strip(left, right, h, z, name)


def ammonite(cx, cy, R, z=0.0, turns=4.0, ribs=14, line=None):
    """Flat ammonite: a gold shell (the last whorl's outline), the coil drawn as
    one tapering ink spiral, and short ink ribs across the outer whorl."""
    k = math.log(1.72) / (2 * math.pi)
    t_end = turns * 2 * math.pi
    a = R / math.exp(k * t_end)
    rot = math.radians(-60)
    lw = line or R * 0.085

    def pt(r, t):
        return (cx + r * math.cos(t + rot), cy + r * math.sin(t + rot))

    def r_at(t):
        return a * math.exp(k * t)

    # round shell (stylized: a clean disc, not the notched true silhouette) with
    # its own ink rim, since the badge background is not transparent
    disc(cx, cy, R + lw * 0.9, INK, z - 0.001, 120)
    disc(cx, cy, R, GOLD, z, 120)
    # the coil: one tapering ink spiral sweeping out until it merges with the rim
    ts = np.linspace(2.0 * math.pi, t_end, 360)
    pts = [pt(r_at(t) - lw * 0.5 * (1.0 - ((t - ts[0]) / (ts[-1] - ts[0])) ** 4), t) for t in ts]
    ws = [lw * (0.45 + 0.55 * (t - ts[0]) / (ts[-1] - ts[0])) for t in ts]
    stroke(pts, ws, INK, z + 0.003, "coil")
    # ribs across the outer whorl (slightly curved, like the real thing)
    for whorl, n, wk in ((0, ribs, 0.55), (1, int(ribs * 0.8), 0.42)):
        for i in range(n):
            t = t_end - 2 * math.pi * (whorl + 1) + (i + 0.6) * (2 * math.pi - 0.4) / n
            r0, r1 = r_at(t - 2 * math.pi), r_at(t)
            seg = [pt(r0 + (r1 - r0) * u, t + 0.12 * math.sin(u * math.pi)) for u in np.linspace(0.2, 0.8, 12)]
            stroke(seg, [lw * wk] * len(seg), GOLD_DK, z + 0.002, "rib")
    # the centre
    disc(*pt(0, 0), r_at(2.0 * math.pi) * 0.95, INK, z + 0.003, 32)


def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


# ------------------------------------------------------------ image tools --
def load_rgba(path):
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return px.reshape(h, w, 4)


def save_rgba(arr, path, size=None):
    h, w = arr.shape[:2]
    img = bpy.data.images.new("o", w, h, alpha=True)
    img.pixels.foreach_set(np.clip(arr, 0, 1).astype(np.float32).ravel())
    if size:
        img.scale(size[0], size[1])
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def dilate(a, r):
    out = a.copy()
    for i in range(r):
        s = out
        m = s.copy()
        m[1:, :] = np.maximum(m[1:, :], s[:-1, :])
        m[:-1, :] = np.maximum(m[:-1, :], s[1:, :])
        m[:, 1:] = np.maximum(m[:, 1:], s[:, :-1])
        m[:, :-1] = np.maximum(m[:, :-1], s[:, 1:])
        if i % 2:
            m[1:, 1:] = np.maximum(m[1:, 1:], s[:-1, :-1])
            m[:-1, :-1] = np.maximum(m[:-1, :-1], s[1:, 1:])
            m[1:, :-1] = np.maximum(m[1:, :-1], s[:-1, 1:])
            m[:-1, 1:] = np.maximum(m[:-1, 1:], s[1:, :-1])
        out = m
    return out


def over(top, bot):
    """Straight-alpha 'over'."""
    ta, ba = top[..., 3:4], bot[..., 3:4]
    oa = ta + ba * (1 - ta)
    rgb = (top[..., :3] * ta + bot[..., :3] * ba * (1 - ta)) / np.maximum(oa, 1e-6)
    return np.concatenate([rgb, oa], axis=-1)


def ink(art, r, shadow_dy, shadow_alpha=0.30):
    a = art[..., 3]
    o = dilate(a, r)
    outline = np.zeros_like(art)
    outline[..., :3] = srgb(INK)
    outline[..., 3] = o
    sh = np.zeros_like(art)
    sh[..., :3] = srgb(INK)
    # image rows are bottom-up: a drop shadow below = shift toward row 0
    s = np.zeros_like(o)
    s[:-shadow_dy, :] = o[shadow_dy:, :]
    sh[..., 3] = s * shadow_alpha
    return over(art, over(outline, sh))


def save_ico(pngs, path):
    data = [open(p, "rb").read() for _, p in pngs]
    head = struct.pack("<HHH", 0, 1, len(pngs))
    off = 6 + 16 * len(pngs)
    ents = b""
    for (sz, _), d in zip(pngs, data):
        ents += struct.pack("<BBBBHHII", sz % 256, sz % 256, 0, 0, 1, 32, len(d), off)
        off += len(d)
    with open(path, "wb") as f:
        f.write(head + ents + b"".join(data))


# ----------------------------------------------------------------- logo ----
def build_logo():
    reset()
    setup(2400, 1800, 12.0)  # 12 x 9 units
    size = 3.5
    tide = text("Tide", TEAL, size, -0.7, 0.55, 0.0)
    # "Trove" = "Tr" + an ammonite for the "o" + "ve"
    tr = text("Tr", GOLD, size, 0, -2.7, 0.0)
    ve = text("ve", GOLD, size, 0, -2.7, 0.0)
    x0, x1, _, _ = bounds(tr)
    v0, v1, _, _ = bounds(ve)
    o_w = 1.85
    gap = 0.1
    total = (x1 - x0) + gap + o_w + gap + (v1 - v0)
    left = -total / 2 + 0.35
    tr.location.x = left + (x1 - x0) / 2
    o_cx = left + (x1 - x0) + gap + o_w / 2
    ve.location.x = o_cx + o_w / 2 + gap + (v1 - v0) / 2
    ammonite(o_cx, -2.7 + 0.86, o_w / 2, 0.02)
    tx0, tx1, ty0, ty1 = bounds(tide)
    text("&", CORAL, 2.1, tx1 + 0.85, -0.55, 0.05)
    path = os.path.join(OUT, "_logo_raw.png")
    render(path)
    art = load_rgba(path)
    art = ink(art, 22, 16)
    save_rgba(art, os.path.join(OUT, "logo.png"), (1200, 900))
    os.remove(path)


def build_emblem():
    reset()
    setup(2048, 2048, 10.0)
    disc(0, 0, 4.6, TEAL, -0.2)
    ammonite(0, 0.0, 3.35, 0.0, ribs=12)
    path = os.path.join(OUT, "_emblem_raw.png")
    render(path)
    art = load_rgba(path)
    art = ink(art, 26, 18, 0.0)
    save_rgba(art, os.path.join(OUT, "emblem.png"), (1024, 1024))
    os.remove(path)


build_logo()
build_emblem()

# icons + ico + boot splash
emb = load_rgba(os.path.join(OUT, "emblem.png"))
icons = []
for sz in (16, 32, 48, 64, 128, 256):
    p = os.path.join(OUT, "icon_%d.png" % sz)
    save_rgba(emb, p, (sz, sz))
    icons.append((sz, p))
save_ico(icons, os.path.join(OUT, "icon.ico"))
logo = load_rgba(os.path.join(OUT, "logo.png"))
splash = np.zeros((640, 640, 4), dtype=np.float32)
save_rgba(logo, os.path.join(OUT, "_l.png"), (640, 480))
small = load_rgba(os.path.join(OUT, "_l.png"))
splash[80:560, :, :] = small
save_rgba(splash, os.path.join(OUT, "boot_splash.png"))
os.remove(os.path.join(OUT, "_l.png"))
print("LOGO DONE", OUT)
