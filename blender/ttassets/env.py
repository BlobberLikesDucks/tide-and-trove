"""Environment kit (environment-artist + procedural-modeling + geometry-nodes +
genre-strategy-sim + stylized-style).

Museum = modular 2 m kit (wall / window / door / corner / floor) on the game's
CELL = 2 m grid, WALL_H = 3.2 m. Buildings get an iconic roof read (strategy-sim:
"iconic buildings, readable at camera distance"): a cupola + fish weathervane on
the museum, a giant shovel on the tool shop. Cliffs carry relief fossils of their
era so geology is learned by looking (GDD "visual discovery").
"""
import random

from tt.geo import *  # noqa
from tt.geo import _merge  # noqa
from tt.mats import *  # noqa
from tt import procgen
from tt.pipe import asset, single, finish, empty

WALL_H = 3.2


# ------------------------------------------------------------ museum kit ----
def _boards(p, x0, x1, z0, z1, y=-0.12, mats=(SIDING, SIDING2, SIDING3), seed=1):
    """Chunky lap siding: each board tilted out at the bottom, slightly uneven."""
    rnd = random.Random(seed)
    z = z0
    k = 0
    while z < z1 - 0.01:
        h = min(0.32, z1 - z)
        rbox(p, mats[rnd.randrange(len(mats))], (x1 - x0 - 0.004, 0.05, h + 0.03),
             loc=((x0 + x1) / 2, y - 0.005 * (k % 2), z + h / 2), rot=(6 + rnd.uniform(-1.5, 1.5), 0, rnd.uniform(-0.3, 0.3)), r=0.012, seg=1)
        z += h
        k += 1


def _wainscot(p, x0, x1):
    box(p, WOOD, (x1 - x0, 0.03, 1.0), loc=((x0 + x1) / 2, 0.13, 0.55))
    n = max(1, int(round((x1 - x0) / 0.5)))
    for i in range(n):
        cx = x0 + (i + 0.5) * (x1 - x0) / n
        rbox(p, WOOD_LT, ((x1 - x0) / n - 0.09, 0.025, 0.62), loc=(cx, 0.15, 0.55), r=0.014, seg=2)
    rbox(p, WOOD_DK, (x1 - x0, 0.06, 0.07), loc=((x0 + x1) / 2, 0.145, 1.08), r=0.015)
    rbox(p, WOOD_DK, (x1 - x0, 0.06, 0.15), loc=((x0 + x1) / 2, 0.145, 0.075), r=0.015)


def _core(p, segs):
    for (x0, x1, z0, z1) in segs:
        box(p, PLASTER, (x1 - x0, 0.2, z1 - z0), loc=((x0 + x1) / 2, 0, (z0 + z1) / 2))


def _cap(p):
    rbox(p, TRIM, (2.0, 0.36, 0.16), loc=(0, 0, WALL_H), r=0.03)
    rbox(p, TRIM, (2.0, 0.1, 0.14), loc=(0, -0.16, 0.07), r=0.02)
    # dentil row under the cap (oversized stylized trim)
    for i in range(8):
        rbox(p, TRIM, (0.12, 0.08, 0.08), loc=(-0.875 + i * 0.25, -0.17, WALL_H - 0.12), r=0.012)


WALL_COL = [("box", (0, 0, WALL_H / 2), (2.0, 0.3, WALL_H))]


@asset("wall", tier="building", col=WALL_COL, group="env")
def wall():
    def f(p):
        _core(p, [(-1, 1, 0, WALL_H)])
        _boards(p, -1.0, 1.0, 0.0, WALL_H, seed=3)
        _wainscot(p, -1.0, 1.0)
        _cap(p)
    return single("SM_Wall", f)


@asset("wall_poster", tier="building", col=WALL_COL, group="env")
def wall_poster():
    def f(p):
        _core(p, [(-1, 1, 0, WALL_H)])
        _boards(p, -1.0, 1.0, 0.0, WALL_H, seed=12)
        _wainscot(p, -1.0, 1.0)
        _cap(p)
        # interior: one framed ammonite print, shell centred in the mat
        rbox(p, WOOD_DK, (0.8, 0.03, 0.62), loc=(0, 0.14, 1.85), r=0.015)
        rbox(p, PAPER2, (0.68, 0.02, 0.5), loc=(0, 0.155, 1.85), r=0.008)
        spiral(p, [SHELL, SHELL2], turns=2.2, a=0.016, growth=0.22, tube_k=0.3, center=(0, 0.17, 1.87), seg=8, centered=True)
        text3d(p, WOOD_DK, "AMMONITE", size=0.05, loc=(0, 0.167, 1.66), rot=(90, 0, 180), depth=0.002, max_w=0.5, res=1)
    return single("SM_WallPoster", f)


@asset("wall_window", tier="building", col=WALL_COL, group="env")
def wall_window():
    def f(p):
        _core(p, [(-1, 1, 0, 1.2), (-1, 1, 2.2, WALL_H), (-1, -0.5, 1.2, 2.2), (0.5, 1, 1.2, 2.2)])
        _boards(p, -1.0, 1.0, 0.0, 1.2, seed=4)
        _boards(p, -1.0, 1.0, 2.2, WALL_H, seed=5)
        _boards(p, -1.0, -0.5, 1.2, 2.2, seed=6)
        _boards(p, 0.5, 1.0, 1.2, 2.2, seed=7)
        _wainscot(p, -1.0, 1.0)
        for x in (-0.55, 0.55):
            rbox(p, TRIM, (0.1, 0.32, 1.12), loc=(x, 0, 1.7), r=0.02)
        rbox(p, TRIM, (1.3, 0.44, 0.1), loc=(0, -0.05, 1.15), r=0.025)
        # arched head
        rbox(p, TRIM, (1.24, 0.32, 0.12), loc=(0, 0, 2.25), r=0.025)
        lathe(p, TRIM, [(0.0, 0.0), (0.6, 0.0), (0.6, 0.06), (0.0, 0.06)], seg=24, loc=(0, 0.0, 2.31), rot=(90, 0, 0), scale=(1.0, 0.35, 1.0))
        rbox(p, TRIM, (0.045, 0.07, 1.0), loc=(0, 0, 1.7), r=0.012)
        rbox(p, TRIM, (1.0, 0.07, 0.045), loc=(0, 0, 1.75), r=0.012)
        box(p, GLASS, (1.0, 0.02, 1.0), loc=(0, 0, 1.7))
        for sx in (-1, 1):  # louvred shutters
            rbox(p, SHUTTER, (0.38, 0.05, 1.08), loc=(sx * 0.81, -0.17, 1.7), r=0.016)
            for k in range(6):
                rbox(p, TRIM, (0.3, 0.035, 0.035), loc=(sx * 0.81, -0.2, 1.33 + k * 0.15), rot=(28, 0, 0), r=0.008, seg=1)
        _cap(p)
        # flower box
        rbox(p, TERRACOTTA, (1.1, 0.26, 0.2), loc=(0, -0.29, 1.03), r=0.03)
        rbox(p, SOIL, (1.0, 0.2, 0.04), loc=(0, -0.29, 1.13), r=0.01)
        rnd = random.Random(2)
        for i in range(7):
            x = -0.42 + i * 0.14
            sph(p, LEAF, 0.075, loc=(x, -0.29, 1.19), scale=(1.0, 0.9, 0.8), u=8, v=6)
            sph(p, (PINK, YELLOW, CORAL)[i % 3], 0.045, loc=(x + rnd.uniform(-0.03, 0.03), -0.33, 1.26), u=8, v=6)
    return single("SM_WallWindow", f)


@asset("wall_door", tier="building", group="env",
       col=[("box", (-0.85, 0, WALL_H / 2), (0.32, 0.3, WALL_H)), ("box", (0.85, 0, WALL_H / 2), (0.32, 0.3, WALL_H)),
            ("box", (0, 0, 2.8), (1.4, 0.3, 0.8)),
            ("box", (-1.0, -0.43, 1.17), (0.24, 0.66, 2.3)), ("box", (1.0, -0.43, 1.17), (0.24, 0.66, 2.3))])
def wall_door():
    def f(p):
        _core(p, [(-1, -0.7, 0, WALL_H), (0.7, 1, 0, WALL_H), (-0.7, 0.7, 2.4, WALL_H)])
        _boards(p, -1.0, -0.7, 0.0, WALL_H, seed=8)
        _boards(p, 0.7, 1.0, 0.0, WALL_H, seed=9)
        _boards(p, -0.7, 0.7, 2.4, WALL_H, seed=10)
        for x in (-0.74, 0.74):
            rbox(p, TRIM, (0.14, 0.36, 2.46), loc=(x, 0, 1.22), r=0.025)
        rbox(p, TRIM, (1.66, 0.38, 0.18), loc=(0, 0, 2.48), r=0.03)
        # keystone + fanlight
        rbox(p, TRIM, (0.2, 0.4, 0.26), loc=(0, 0, 2.62), r=0.03)
        _cap(p)
        for sx in (-1, 1):  # open panelled doors (welcoming, swung outwards)
            ang = sx * -72
            cx, cy = sx * 1.0, -0.43
            rbox(p, TEAL, (0.66, 0.07, 2.3), loc=(cx, cy, 1.17), rot=(0, 0, ang), r=0.02)
            for k in range(3):
                rbox(p, SIDING3, (0.48, 0.03, 0.56), loc=(cx, cy, 0.5 + k * 0.7), rot=(0, 0, ang), r=0.012)
            sph(p, BRASS, 0.04, loc=(sx * 0.8, -0.72, 1.1), u=8, v=6)
        # hanging "MUSEUM" plaque over the door
        rbox(p, TEAL, (0.95, 0.05, 0.34), loc=(0, -0.2, 2.86), r=0.04)
        rbox(p, BRASS, (1.0, 0.035, 0.38), loc=(0, -0.18, 2.86), r=0.04)
        text3d(p, CREAM, "MUSEUM", size=0.2, loc=(0, -0.226, 2.86), depth=0.008, max_w=0.82, max_h=0.22)
        # doormat
        rbox(p, CORAL, (1.2, 0.6, 0.02), loc=(0, -0.55, 0.01), r=0.01)
    return single("SM_WallDoor", f)


@asset("wall_corner", tier="prop", group="env", col=[("box", (0, 0, WALL_H / 2), (0.34, 0.34, WALL_H))])
def wall_corner():
    def f(p):
        rbox(p, TRIM, (0.36, 0.36, WALL_H + 0.1), loc=(0, 0, (WALL_H + 0.1) / 2), r=0.04)
        rbox(p, TRIM, (0.46, 0.46, 0.16), loc=(0, 0, 0.08), r=0.035)
        rbox(p, TRIM, (0.46, 0.46, 0.12), loc=(0, 0, WALL_H + 0.06), r=0.035)
        for z in (1.08, 2.2):
            rbox(p, TRIM, (0.4, 0.4, 0.06), loc=(0, 0, z), r=0.02)
    return single("SM_WallCorner", f)


@asset("floor_tile", tier="prop", group="env")
def floor_tile():
    def f(p):
        rnd = random.Random(11)
        for i in range(5):
            mat = (WOOD_LT, WOOD, WOOD_LT, WOOD_RED, WOOD)[i]
            off = rnd.uniform(-0.6, 0.6)
            for (a, b) in ((-1.0, off), (off, 1.0)):
                rbox(p, mat, (b - a - 0.014, 0.386, 0.1), loc=((a + b) / 2, -0.8 + i * 0.4, -0.05 + rnd.uniform(-0.003, 0.003)), r=0.014, seg=1)
                for e in (a + 0.08, b - 0.08):  # nail heads
                    sph(p, IRON, 0.012, loc=(e, -0.8 + i * 0.4, 0.0), scale=(1, 1, 0.4), u=6, v=4)
    return single("SM_FloorTile", f, smooth=30)


def _roof(W, D):
    """Fish-scale shingled gable roof + cupola with fish weathervane (iconic read)."""
    root = empty("SM_MuseumRoof")
    ow, od = W * 2 + 1.2, D * 2 + 1.2
    half = od / 2
    rise = half * 0.58
    ang = math.atan2(rise, half)
    slope_len = math.hypot(half, rise)
    p = Part()
    for sy in (1, -1):
        mid = Vector((0, sy * half / 2, WALL_H + rise / 2))
        box(p, WOOD_DK, (ow, slope_len, 0.08), loc=mid, rot=(sy * -math.degrees(ang), 0, 0))
    finish(p, "SM_Roof_Deck", root)
    p = Part()
    rnd = random.Random(W * 31 + D)
    rows = int(slope_len / 0.4) + 1
    for sy in (1, -1):
        for r in range(rows):
            u = (r + 0.5) / rows
            yy = sy * half * (1 - u)
            zz = WALL_H + rise * u + 0.07
            off = 0.0 if r % 2 == 0 else 0.3
            x = -ow / 2 + off
            band = r % 5 == 2
            while x < ow / 2 - 0.05:
                w = min(0.6, ow / 2 - x)
                mat = (ROOF, ROOF2, ROOF3)[rnd.randrange(3)] if not band else ROOF2
                box(p, mat, (w - 0.035, 0.46, 0.05), loc=(x + w / 2, yy, zz), rot=(sy * -math.degrees(ang) + rnd.uniform(-2.5, 2.5), 0, rnd.uniform(-1.2, 1.2)))
                x += w
    finish(p, "SM_Roof_Shingles", root, smooth=20)
    p = Part()
    rbox(p, TRIM, (ow + 0.12, 0.22, 0.22), loc=(0, 0, WALL_H + rise + 0.09), rot=(45, 0, 0), r=0.03)
    for sy in (1, -1):
        rbox(p, TRIM, (ow + 0.12, 0.07, 0.22), loc=(0, sy * (half + 0.01), WALL_H - 0.04), r=0.02)
    for sx in (1, -1):
        for sy in (1, -1):
            mid = Vector((sx * (ow / 2 + 0.03), sy * half / 2, WALL_H + rise / 2 + 0.04))
            rbox(p, TRIM, (0.08, slope_len + 0.1, 0.22), loc=mid, rot=(sy * -math.degrees(ang), 0, 0), r=0.02)
    finish(p, "SM_Roof_Fascia", root)
    p = Part()  # gable ends: siding + round attic window
    gx = W * 1.0
    for sx in (1, -1):
        z = WALL_H
        k = 0
        while z < WALL_H + rise - 0.05:
            frac = 1 - (z - WALL_H + 0.17) / rise
            wdt = max(0.1, D * 2 * frac)
            box(p, SIDING if k % 2 == 0 else SIDING2, (0.05, wdt, 0.34), loc=(sx * (gx + 0.02), 0, z + 0.17))
            z += 0.34
            k += 1
        cyl(p, TRIM, 0.36, 0.08, loc=(sx * (gx + 0.06), 0, WALL_H + rise * 0.42), rot=(0, 90, 0), seg=24)
        cyl(p, GLASS, 0.27, 0.09, loc=(sx * (gx + 0.06), 0, WALL_H + rise * 0.42), rot=(0, 90, 0), seg=24)
        cyl(p, TRIM, 0.03, 0.1, loc=(sx * (gx + 0.07), 0, WALL_H + rise * 0.42), rot=(0, 90, 0), seg=8, scale=(1, 9.0, 1))
        cyl(p, TRIM, 0.03, 0.1, loc=(sx * (gx + 0.07), 0, WALL_H + rise * 0.42), rot=(90, 90, 0), seg=8, scale=(1, 9.0, 1))
    finish(p, "SM_Roof_Gables", root)
    # cupola + weathervane on the ridge
    p = Part()
    top = WALL_H + rise
    rbox(p, SIDING2, (1.1, 1.1, 0.9), loc=(0, 0, top + 0.25), r=0.04)
    for sx in (-1, 1):
        for sy in (-1, 1):
            rbox(p, TRIM, (0.12, 0.12, 0.95), loc=(sx * 0.5, sy * 0.5, top + 0.26), r=0.02)
    for a in range(4):
        d = Vector((math.cos(a * math.pi / 2), math.sin(a * math.pi / 2), 0))
        rbox(p, GLASS, (0.5 if abs(d.y) > 0.5 else 0.02, 0.5 if abs(d.x) > 0.5 else 0.02, 0.45), loc=d * 0.56 + Vector((0, 0, top + 0.35)), r=0.0)
        rbox(p, TRIM, (0.6 if abs(d.y) > 0.5 else 0.04, 0.6 if abs(d.x) > 0.5 else 0.04, 0.05), loc=d * 0.565 + Vector((0, 0, top + 0.35)), r=0.01)
    rbox(p, TRIM, (1.35, 1.35, 0.1), loc=(0, 0, top + 0.74), r=0.03)
    lathe(p, ROOF2, [(0.0, 0.0), (0.72, 0.0), (0.0, 0.7)], seg=4, loc=(0, 0, top + 0.79), rot=(0, 0, 45))
    sph(p, BRASS, 0.07, loc=(0, 0, top + 1.52), u=10, v=8)
    cyl(p, IRON, 0.015, 0.75, loc=(0, 0, top + 1.85), seg=6)
    for d in ((1, 0), (0, 1)):
        cyl(p, IRON, 0.008, 0.5, loc=(0, 0, top + 1.65), rot=(90 if d[1] else 0, 90 if d[0] else 0, 0), seg=4)
    # the fish
    sph(p, BRASS, 0.16, loc=(0.05, 0, top + 2.1), scale=(1.6, 0.18, 0.75), u=12, v=8)
    prism(p, BRASS, [(0, 0), (0.22, 0.14), (0.22, -0.14)], 0.02, plane="XZ", z=-0.01, loc=(0.28, 0, top + 2.1))
    prism(p, BRASS, [(0, 0), (-0.22, 0.14), (-0.22, -0.14)], 0.02, plane="XZ", z=-0.01, loc=(-0.2, 0, top + 2.1))
    finish(p, "SM_Roof_Cupola", root)
    return root


for _lvl, (_w, _d) in enumerate(((5, 4), (7, 5), (9, 6), (11, 7))):
    def _mk(w=_w, d=_d):
        return _roof(w, d)
    asset("museum_roof_%d" % _lvl, tier="building", res=1024, group="env")(_mk)


@asset("porch", tier="prop", group="env",
       col=[("box", (sx * 1.95, -0.05, 0.75), (0.18, 1.85, 1.4)) for sx in (-1, 1)])
def porch():
    def f(p):
        rbox(p, WOOD_DK, (4.1, 2.1, 0.2), loc=(0, 0, 0.1), r=0.025)
        for i in range(10):
            rbox(p, WOOD_LT if i % 2 else WOOD, (0.385, 2.08, 0.05), loc=(-1.8 + i * 0.4, 0, 0.225), rot=(0, random.Random(i).uniform(-0.6, 0.6), 0), r=0.012, seg=1)
        rbox(p, WOOD, (2.3, 0.48, 0.12), loc=(0, -1.27, 0.06), r=0.02)
        for x in (-1.95, 1.95):
            rbox(p, WOOD_DK, (0.15, 0.15, 1.1), loc=(x, -0.95, 0.75), r=0.025)
            sph(p, TRIM, 0.1, loc=(x, -0.95, 1.37), u=12, v=8)
            rbox(p, WOOD, (0.11, 1.8, 0.09), loc=(x, -0.05, 1.05), r=0.02)
            for k in range(6):
                lathe(p, TRIM, [(0.0, 0.0), (0.03, 0.0), (0.02, 0.1), (0.035, 0.38), (0.02, 0.66), (0.03, 0.75), (0.0, 0.75)], seg=8, loc=(x, -0.8 + k * 0.32, 0.27))
    return single("SM_Porch", f)


@asset("open_sign", tier="item", group="env")
def open_sign():
    root = empty("OpenSign")
    p = Part()
    cyl(p, WOOD_DK, 0.05, 1.7, loc=(0, 0, 0.85), seg=12)
    rbox(p, WOOD_DK, (0.95, 0.07, 0.07), loc=(0.37, 0, 1.6), r=0.02)
    rbox(p, STONE2, (0.32, 0.32, 0.1), loc=(0, 0, 0.05), r=0.03)
    tube(p, WOOD_DK, [(0.05, 0, 1.3), (0.2, 0, 1.58)], 0.025, seg=8)
    for x in (0.12, 0.62):
        tube(p, BRASS, [(x, 0, 1.58), (x, 0, 1.4)], 0.008, seg=6)
    sph(p, BRASS, 0.04, loc=(0, 0, 1.73), u=8, v=6)
    finish(p, "Post", root)
    b = Part()
    rbox(b, WOOD_LT, (0.74, 0.05, 0.42), r=0.035)
    rbox(b, GREEN, (0.64, 0.012, 0.32), loc=(0, -0.028, 0), r=0.025)
    rbox(b, RED, (0.64, 0.012, 0.32), loc=(0, 0.028, 0), r=0.025)
    for sx in (-1, 1):
        sph(b, BRASS, 0.018, loc=(sx * 0.3, -0.035, 0.15), u=6, v=4)
    text3d(b, CREAM, "OPEN", size=0.17, loc=(0, -0.034, -0.01), depth=0.006, max_w=0.56, max_h=0.22)
    text3d(b, CREAM, "CLOSED", size=0.15, loc=(0, 0.034, -0.01), rot=(90, 0, 180), depth=0.006, max_w=0.56, max_h=0.2)
    finish(b, "Board", root, loc=(0.37, 0, 1.2))
    return root


@asset("museum_sign", tier="building", group="env",
       col=[("box", (-2.63, 0, 1.75), (0.3, 0.3, 3.5)), ("box", (2.63, 0, 1.75), (0.3, 0.3, 3.5))])
def museum_sign():
    def f(p):
        for x in (-2.63, 2.63):
            rbox(p, WOOD_DK, (0.24, 0.24, 3.4), loc=(x, 0, 1.7), r=0.035)
            rock(p, STONE2, 0.3, loc=(x, 0, 0.12), scale=(1.1, 1.1, 0.7), seed=int(x * 10) + 50, sub=2, rough=0.15)
        rbox(p, WOOD, (5.04, 0.2, 1.18), loc=(0, 0, 2.6), r=0.06)
        rbox(p, TEAL, (4.7, 0.22, 0.92), loc=(0, 0, 2.6), r=0.05)
        tube(p, ROPE, [(-2.5, -0.11, 3.2), (2.5, -0.11, 3.2)], 0.038, seg=8)
        tube(p, ROPE, [(-2.5, -0.11, 2.0), (2.5, -0.11, 2.0)], 0.038, seg=8)
        prism(p, ROOF, [(-2.95, 0), (2.95, 0), (0, 0.55)], 0.55, z=-0.275, plane="XZ", loc=(0, 0, 3.4))
        spiral(p, [SHELL, SHELL2], turns=2.6, a=0.012, growth=0.2, tube_k=0.38, center=(-2.0, -0.16, 2.6), centered=True)
        text3d(p, CREAM, "TIDE & TROVE", size=0.36, loc=(0.12, -0.11, 2.76), depth=0.014, max_w=3.2, max_h=0.42)
        text3d(p, YELLOW, "Natural History Museum", size=0.16, loc=(0.12, -0.11, 2.36), depth=0.01, max_w=3.0, max_h=0.2)
        # starfish + rope knots: seaside storytelling
        for k in range(5):
            a = math.radians(90 + k * 72)
            tube(p, CORAL, [(1.95, -0.14, 2.55), (1.95 + 0.2 * math.cos(a), -0.14, 2.55 + 0.2 * math.sin(a))], [0.05, 0.015], seg=6)
        for x in (-2.5, 2.5):
            sph(p, ROPE, 0.07, loc=(x, -0.11, 3.2), u=8, v=6)
            sph(p, ROPE, 0.07, loc=(x, -0.11, 2.0), u=8, v=6)
    return single("SM_MuseumSign", f)


@asset("path_stones", tier="prop", group="env")
def path_stones():
    def f(p):
        rnd = random.Random(5)
        box(p, SAND_DK, (2.8, 4.4, 0.02), loc=(0, 0, 0.01))
        y = -2.0
        while y < 2.1:
            x = -1.0
            while x < 1.05:
                s = rnd.uniform(0.36, 0.5)
                rock(p, STONE2 if rnd.random() < 0.6 else ROCK_LT, s * 0.5, loc=(x + rnd.uniform(-0.05, 0.05), y + rnd.uniform(-0.05, 0.05), 0.0),
                     scale=(1.0, 1.0, 0.22), seed=rnd.randint(0, 999), sub=2, rough=0.12, floor=-0.9)
                x += s + 0.06
            y += 0.5
    return single("SM_PathStones", f, smooth=50)


# ------------------------------------------------------------------- town ---
@asset("tool_shop", tier="building", res=1024, group="env",
       col=[("box", (0, 0, 2.25), (6.0, 5.0, 4.5)), ("box", (0, -2.85, 0.55), (3.0, 0.9, 1.1)),
            ("box", (-2.6, -3.4, 0.45), (0.75, 0.75, 0.9)), ("box", (2.6, -3.05, 0.5), (1.3, 1.3, 1.0))])
def tool_shop():
    """Equipment & Supplies. The gable roof starts exactly on the wall plates
    (eaves overhang 0.5 m) and the gable triangles match the roof pitch."""
    def f(p):
        W, D, H = 6.0, 5.0, 3.6
        box(p, SHOP_WALL, (W, D, H), loc=(0, 0, H / 2))
        for i in range(13):
            rbox(p, SHOP_WALL2 if i % 2 else WOOD_LT, (0.08, D + 0.06, H), loc=(-W / 2 + i * 0.5, 0, H / 2), r=0.015, seg=1)
        rbox(p, STONE2, (W + 0.24, D + 0.24, 0.32), loc=(0, 0, 0.16), r=0.05)
        ang = 26
        k = math.tan(math.radians(ang))
        half = D / 2
        ridge = half * k
        eave = half + 0.5

        def zroof(y):
            return H + (half - abs(y)) * k

        rows = 10
        for sy in (1, -1):
            for r in range(rows):
                u = (r + 0.5) / rows
                yy = sy * eave * (1 - u)
                rbox(p, SHOP_ROOF if r % 2 else SHOP_ROOF2, (W + 0.8, (eave / rows) / math.cos(math.radians(ang)) + 0.06, 0.07),
                     loc=(0, yy, zroof(yy) + 0.06), rot=(sy * -ang, 0, 0), r=0.02, seg=1)
            rbox(p, TRIM, (W + 0.86, 0.06, 0.2), loc=(0, sy * (eave + 0.02), zroof(eave) - 0.02), r=0.015)
        rbox(p, TRIM, (W + 0.9, 0.22, 0.22), loc=(0, 0, H + ridge + 0.12), rot=(45, 0, 0), r=0.03)
        for sx in (1, -1):
            prism(p, SHOP_WALL, [(-half, 0), (half, 0), (0, ridge)], 0.06, z=-0.03, plane="XZ", loc=(sx * (W / 2 - 0.03), 0, H), rot=(0, 0, 90))
            for sy in (1, -1):
                y0 = sy * eave
                tube(p, TRIM, [(sx * (W / 2 + 0.41), y0, zroof(y0) + 0.06), (sx * (W / 2 + 0.41), 0.0, zroof(0.0) + 0.06)], 0.05, seg=6)
            cyl(p, TRIM, 0.3, 0.07, loc=(sx * (W / 2 + 0.02), 0, H + ridge * 0.42), rot=(0, 90, 0), seg=20)
            cyl(p, GLASS, 0.22, 0.08, loc=(sx * (W / 2 + 0.03), 0, H + ridge * 0.42), rot=(0, 90, 0), seg=20)
        rbox(p, ROCK_DK, (0.6, 0.6, 1.8), loc=(1.8, 1.2, H + 1.0), r=0.05)
        rbox(p, DARK, (0.72, 0.72, 0.12), loc=(1.8, 1.2, H + 1.9), r=0.03)
        rbox(p, DARK, (2.6, 0.1, 1.2), loc=(0, -D / 2 - 0.01, 1.75), r=0.02)
        for x in (-1.35, 1.35):
            rbox(p, TRIM, (0.14, 0.22, 1.38), loc=(x, -D / 2 - 0.05, 1.75), r=0.025)
        rbox(p, WOOD_DK, (3.0, 0.75, 0.12), loc=(0, -D / 2 - 0.32, 1.12), r=0.035)
        rbox(p, WOOD, (3.0, 0.2, 1.06), loc=(0, -D / 2 - 0.58, 0.55), r=0.035)
        for i in range(5):
            rbox(p, WOOD_LT, (0.5, 0.03, 0.8), loc=(-1.2 + i * 0.6, -D / 2 - 0.69, 0.55), r=0.012)
        lathe(p, GLASS, [(0.0, 0), (0.1, 0), (0.11, 0.2), (0.06, 0.26), (0.0, 0.26)], seg=12, loc=(-0.9, -D / 2 - 0.35, 1.18))
        for i in range(5):
            sph(p, (GEM2, YELLOW, PINK, GREEN, BLUE)[i], 0.03, loc=(-0.9 + (i - 2) * 0.03, -D / 2 - 0.35, 1.24 + (i % 2) * 0.03), u=6, v=4)
        lathe(p, BRASS, [(0.0, 0.0), (0.08, 0.0), (0.06, 0.08), (0.02, 0.1), (0.0, 0.12)], seg=12, loc=(0.9, -D / 2 - 0.35, 1.18))
        for i in range(8):
            mat = STRIPE_R if i % 2 == 0 else STRIPE_W
            box(p, mat, (0.42, 1.3, 0.05), loc=(-1.47 + i * 0.42, -D / 2 - 0.62, 2.57), rot=(-22, 0, 0))
            sph(p, mat, 0.21, loc=(-1.47 + i * 0.42, -D / 2 - 1.22, 2.31), scale=(1.0, 0.2, 0.5), u=12, v=8)
        for x in (-1.6, 1.6):
            tube(p, IRON, [(x, -D / 2, 2.15), (x, -D / 2 - 0.9, 2.4)], 0.02, seg=5)
        SZ = 3.13  # sign centre: between the awning hinge (2.81) and the eave (3.52 at the board face)
        rbox(p, WOOD_DK, (3.9, 0.16, 0.66), loc=(0, -D / 2 - 0.08, SZ), r=0.05)
        rbox(p, TEAL, (3.7, 0.17, 0.5), loc=(0, -D / 2 - 0.08, SZ), r=0.04)
        text3d(p, CREAM, "EQUIPMENT & SUPPLIES", size=0.22, loc=(0.2, -D / 2 - 0.165, SZ), depth=0.01, max_w=3.0, max_h=0.27)
        for s in (-1, 1):
            tube(p, C_HANDLE, [(-1.62 - 0.11 * s, -D / 2 - 0.17, SZ - 0.16), (-1.62 + 0.11 * s, -D / 2 - 0.17, SZ + 0.16)], 0.018, seg=6)
        prism(p, METAL, [(-0.07, 0), (0.07, 0), (0.0, -0.11)], 0.01, plane="XZ", z=-0.01, loc=(-1.51, -D / 2 - 0.175, SZ + 0.18), rot=(0, 34, 0))
        tube(p, METAL, [(-1.85, -D / 2 - 0.175, SZ + 0.13), (-1.72, -D / 2 - 0.175, SZ + 0.2), (-1.59, -D / 2 - 0.175, SZ + 0.15)], 0.016, seg=5)
        rbox(p, WOOD, (0.08, 1.0, 2.1), loc=(W / 2 + 0.03, 0.8, 1.05), r=0.025)
        sph(p, BRASS, 0.04, loc=(W / 2 + 0.09, 0.45, 1.05), u=8, v=6)
        rbox(p, STONE2, (0.6, 1.2, 0.18), loc=(W / 2 + 0.3, 0.8, 0.09), r=0.04)
        tube(p, IRON, [(-W / 2 + 0.25, -D / 2, 2.62), (-W / 2 + 0.25, -D / 2 - 0.32, 2.62), (-W / 2 + 0.25, -D / 2 - 0.32, 2.52)], 0.018, seg=5)
        rbox(p, IRON, (0.16, 0.16, 0.05), loc=(-W / 2 + 0.25, -D / 2 - 0.32, 2.5), r=0.01)
        cyl(p, GLOW_WARM, 0.055, 0.14, loc=(-W / 2 + 0.25, -D / 2 - 0.32, 2.4), seg=10)
        rbox(p, IRON, (0.14, 0.14, 0.03), loc=(-W / 2 + 0.25, -D / 2 - 0.32, 2.31), r=0.008)
        lathe(p, WOOD, [(0.0, 0), (0.3, 0), (0.36, 0.45), (0.3, 0.9), (0.0, 0.9)], seg=18, loc=(-2.6, -D / 2 - 0.9, 0))
        for z in (0.15, 0.75):
            cyl(p, IRON, 0.335, 0.04, loc=(-2.6, -D / 2 - 0.9, z), seg=18)
        for (x, y, z, s, r) in ((2.4, -D / 2 - 0.8, 0.35, 0.7, 10), (2.45, -D / 2 - 0.8, 0.98, 0.56, -6), (2.95, -D / 2 - 0.1, 0.3, 0.6, 40)):
            rbox(p, WOOD_LT, (s, s, s), loc=(x, y, z), rot=(0, 0, r), r=0.035)
            rbox(p, WOOD_DK, (s + 0.02, s * 0.15, s + 0.02), loc=(x, y, z), rot=(0, 0, r), r=0.025)
    return single("SM_ToolShop", f)


@asset("street_lamp", tier="prop", group="env", col=[("box", (0, 0, 2.0), (0.3, 0.3, 4.0))])
def street_lamp():
    def f(p):
        lathe(p, IRON, [(0.0, 0), (0.2, 0), (0.2, 0.07), (0.13, 0.13), (0.1, 0.36), (0.07, 0.42), (0.0, 0.42)], seg=16)
        cyl(p, IRON, 0.06, 3.8, loc=(0, 0, 2.3), seg=12, r2=0.045)
        for k in range(8):
            cyl(p, IRON, 0.013, 3.5, loc=(0.055 * math.cos(k / 8 * TAU), 0.055 * math.sin(k / 8 * TAU), 2.2), seg=6)
        tube(p, IRON, [(0, 0, 4.1), (0.05, 0, 4.4), (0.4, 0, 4.55), (0.75, 0, 4.48)], 0.038, seg=8)
        tube(p, IRON, [(0.0, 0, 3.9), (0.15, 0, 4.15), (0.3, 0, 4.2), (0.35, 0, 4.1)], 0.016, seg=6)
        rbox(p, IRON, (0.3, 0.3, 0.06), loc=(0.8, 0, 4.42), r=0.025)
        lathe(p, IRON, [(0.0, 0.0), (0.2, 0.0), (0.05, 0.16), (0.0, 0.18)], seg=8, loc=(0.8, 0, 4.44))
        rbox(p, GLASS, (0.24, 0.24, 0.32), loc=(0.8, 0, 4.24), r=0.02)
        for sx in (-1, 1):
            for sy in (-1, 1):
                cyl(p, IRON, 0.013, 0.34, loc=(0.8 + sx * 0.12, sy * 0.12, 4.24), seg=6)
        sph(p, GLOW_WARM, 0.08, loc=(0.8, 0, 4.24), u=10, v=8)
        rbox(p, IRON, (0.28, 0.28, 0.04), loc=(0.8, 0, 4.06), r=0.012)
        # hanging flower basket + bunting hook
        lathe(p, WOOD_DK, [(0.0, 0.0), (0.16, 0.05), (0.2, 0.18), (0.0, 0.18)], seg=12, loc=(0, -0.25, 3.0))
        sph(p, LEAF, 0.2, loc=(0, -0.25, 3.22), scale=(1, 1, 0.7), u=10, v=8)
        for k in range(6):
            sph(p, (PINK, CORAL, YELLOW)[k % 3], 0.045, loc=(0.15 * math.cos(k), -0.25 + 0.15 * math.sin(k), 3.27), u=6, v=4)
        tube(p, IRON, [(0, -0.06, 3.5), (0, -0.25, 3.45), (0, -0.25, 3.2)], 0.012, seg=5)
    return single("SM_StreetLamp", f)


@asset("bus_stop", tier="prop", group="env",
       col=[("box", (1.2, 0.9, 1.2), (2.5, 0.1, 2.4)), ("box", (1.2, 0.62, 0.27), (1.9, 0.46, 0.54)),
            ("box", (0, 0, 1.2), (0.12, 0.12, 2.4)), ("box", (2.4, 0, 1.2), (0.12, 0.12, 2.4)),
            ("box", (-0.3, -0.1, 1.4), (0.12, 0.12, 2.8)), ("box", (-0.85, 0.45, 0.3), (0.44, 0.44, 0.6))])
def bus_stop():
    def f(p):
        for x in (0.0, 2.4):
            for y in (0.0, 0.9):
                cyl(p, METAL_DK, 0.045, 2.4, loc=(x, y, 1.2), seg=10)
        rbox(p, TEAL, (2.8, 1.25, 0.1), loc=(1.2, 0.45, 2.43), rot=(-5, 0, 0), r=0.04)
        box(p, GLASS, (2.4, 0.03, 1.6), loc=(1.2, 0.9, 1.3))
        rbox(p, METAL_DK, (2.45, 0.05, 0.06), loc=(1.2, 0.9, 2.1), r=0.012)
        for i in range(3):
            rbox(p, WOOD, (1.9, 0.13, 0.05), loc=(1.2, 0.47 + i * 0.15, 0.5), r=0.02)
        rbox(p, WOOD, (1.9, 0.05, 0.28), loc=(1.2, 0.84, 0.76), r=0.02)
        for x in (0.45, 1.95):
            rbox(p, METAL_DK, (0.06, 0.4, 0.05), loc=(x, 0.62, 0.45), r=0.01)
            rbox(p, METAL_DK, (0.06, 0.06, 0.45), loc=(x, 0.62, 0.225), r=0.01)
            rbox(p, METAL_DK, (0.2, 0.32, 0.03), loc=(x, 0.62, 0.015), r=0.01)
        rbox(p, METAL_DK, (0.98, 0.03, 0.86), loc=(1.75, 0.865, 1.52), r=0.012)
        rbox(p, CORAL, (0.9, 0.02, 0.78), loc=(1.75, 0.85, 1.52), r=0.01)
        spiral(p, [CREAM], turns=2.2, a=0.012, growth=0.24, tube_k=0.3, center=(1.75, 0.835, 1.6), seg=6, centered=True)
        text3d(p, CREAM, "VISIT THE MUSEUM", size=0.07, loc=(1.75, 0.84, 1.25), depth=0.003, max_w=0.8)
        cyl(p, METAL_DK, 0.04, 2.8, loc=(-0.3, -0.1, 1.4), seg=10)
        rbox(p, BLUE, (0.72, 0.07, 0.52), loc=(-0.3, -0.1, 2.6), r=0.05)
        rbox(p, TRIM, (0.62, 0.075, 0.42), loc=(-0.3, -0.1, 2.6), r=0.04)
        rbox(p, BLUE, (0.56, 0.08, 0.36), loc=(-0.3, -0.1, 2.6), r=0.035)
        text3d(p, CREAM, "BUS", size=0.2, loc=(-0.3, -0.142, 2.6), depth=0.008, max_w=0.46, max_h=0.24)
        text3d(p, CREAM, "BUS", size=0.2, loc=(-0.3, -0.058, 2.6), rot=(90, 0, 180), depth=0.008, max_w=0.46, max_h=0.24)
        lathe(p, METAL_DK, [(0.0, 0.0), (0.18, 0.0), (0.2, 0.6), (0.0, 0.6)], seg=12, loc=(-0.85, 0.45, 0))
        cyl(p, DARK, 0.17, 0.02, loc=(-0.85, 0.45, 0.6), seg=12)
    return single("SM_BusStop", f)


@asset("street", tier="env", res=1024, group="env")
def street():
    """Road, lane dashes, crosswalk, curbs, sidewalks, drains and a manhole (56 x 10 m)."""
    def f(p):
        L = 56.0
        box(p, ASPHALT, (L, 6.0, 0.06), loc=(0, 0, 0.0))
        rnd = random.Random(2)
        for i in range(36):
            rbox(p, ASPHALT2, (rnd.uniform(0.5, 2.2), rnd.uniform(0.3, 1.2), 0.006), loc=(rnd.uniform(-27, 27), rnd.uniform(-2.6, 2.6), 0.032), r=0.003, seg=1)
        x = -26.0
        while x < 27.0:
            if abs(x) > 2.4:
                rbox(p, PAINT_W, (2.2, 0.2, 0.012), loc=(x, 0, 0.035), r=0.005, seg=1)
            x += 4.0
        for i in range(6):
            rbox(p, PAINT_W, (0.5, 5.4, 0.012), loc=(-1.75 + i * 0.7, 0, 0.036), r=0.005, seg=1)
        for sy in (1, -1):
            rbox(p, CURB, (L, 0.24, 0.17), loc=(0, sy * 3.05, 0.065), r=0.035)
            box(p, CONCRETE, (L, 1.8, 0.1), loc=(0, sy * 4.05, 0.05))
            for dx in (-18.0, 9.0):  # drain grates
                rbox(p, IRON, (0.6, 0.3, 0.02), loc=(dx, sy * 2.78, 0.035), r=0.01)
                for k in range(5):
                    box(p, DARK, (0.04, 0.24, 0.022), loc=(dx - 0.2 + k * 0.1, sy * 2.78, 0.037))
        cyl(p, IRON, 0.38, 0.02, loc=(7.0, 1.4, 0.035), seg=20)
        cyl(p, METAL_DK, 0.3, 0.022, loc=(7.0, 1.4, 0.036), seg=20)
    return single("SM_Street", f, smooth=20)


# ---------------------------------------------------------------- grounds ---
def _tuft(name, mats, blades=6, h=(0.16, 0.32), seed=0):
    def f(p):
        rnd = random.Random(seed)
        for k in range(blades):
            a = k / blades * TAU + rnd.uniform(-0.3, 0.3)
            hh = rnd.uniform(*h)
            base = Vector((0.04 * math.cos(a), 0.04 * math.sin(a), 0))
            tip = base * 3.0 + Vector((0, 0, hh))
            tube(p, mats[k % len(mats)], [base, base.lerp(tip, 0.5) + Vector((0, 0, 0.03)), tip], [0.02, 0.012, 0.002], seg=3, cap=False)
    return single(name, f)


def _pebble(name, mat, r, seed):
    return single(name, lambda p: rock(p, mat, r, loc=(0, 0, r * 0.2), scale=(1.2, 1.0, 0.55), seed=seed, sub=1, rough=0.25))


def _shell(name, seed):
    def f(p):
        for k in range(7):
            a = math.radians(-55 + k * 18)
            tube(p, PINK if k % 2 else SHELL, [(0, 0, 0.005), (0.1 * math.sin(a), 0.1 * math.cos(a), 0.022)], [0.008, 0.02], seg=4)
    return single(name, f)


def _ground_base(name, w, d, mats, seed, wet_band=0.0):
    def f(p):
        t = bmesh.new()
        bmesh.ops.create_grid(t, x_segments=int(w / 2.5), y_segments=int(d / 2.5), size=0.5)
        for v in t.verts:
            x, y = v.co.x * w, v.co.y * d
            edge = min(1.0, (w / 2 - abs(x)) / 3.0, (d / 2 - abs(y)) / 3.0)
            # stays just below 0 so buildings, floors and the street always sit on top
            v.co = Vector((x, y, -0.045 + max(0.0, edge) * 0.03 * noise.noise(Vector((x * 0.15, y * 0.15, seed)))))
        _merge(p, t, mats[0])
        rnd = random.Random(seed)
        if wet_band > 0:
            box(p, SAND_WET, (w, wet_band, 0.01), loc=(0, -d / 2 + wet_band / 2, -0.005))
        box(p, mats[0], (w, d, 0.08), loc=(0, 0, -0.14))  # base slab sits below the displaced grid (no z-fighting)
    return single(name, f, smooth=25)


def _ground_scatter(g, items, density, seed, up=0.6, scale=(0.7, 1.3), min_dist=0.4):
    procgen.scatter(g, items, density=density, seed=seed, scale=scale, min_dist=min_dist, up=up)
    return g


@asset("ground_grass", tier="env", res=1024, group="env")
def ground_grass():
    g = _ground_base("SM_GroundGrass", 50, 54, [GRASS, GRASS2], 7)
    tufts = [_tuft("t%d" % i, [GRASS, GRASS3, CLOVER], seed=i) for i in range(3)]
    flowers = [single("fl", lambda p: (cyl(p, LEAF_DK, 0.008, 0.18, loc=(0, 0, 0.09), seg=3), sph(p, YELLOW, 0.03, loc=(0, 0, 0.19), u=6, v=4)))]
    _ground_scatter(g, tufts, 0.09, 3)
    _ground_scatter(g, flowers, 0.02, 9, min_dist=1.2)
    # keep scatter out from under buildings + roads (Godot places this ground at z=-37;
    # Blender y = -(godot_z + 37)): museum + porch, street, tool shop, prep lab
    _clear_scatter(g, [(-12.5, 12.5, -30.0, -8.5), (-30.0, 30.0, -9.8, 1.8), (-4.5, 4.5, 2.5, 11.0), (12.5, 23.5, -23.5, -14.5)])
    return g


def _clear_scatter(g, rects):
    from tt.paint import face_flags
    flags = face_flags(g.data)
    if not flags:
        return
    bm = bmesh.new()
    bm.from_mesh(g.data)
    bm.faces.ensure_lookup_table()
    dead = []
    for i, f in enumerate(bm.faces):
        if flags[i]:
            c = f.calc_center_median()
            if any(x0 < c.x < x1 and y0 < c.y < y1 for (x0, x1, y0, y1) in rects):
                dead.append(f)
    bmesh.ops.delete(bm, geom=dead, context="FACES")
    bm.to_mesh(g.data)
    bm.free()


def _zone(name, w, d, mats, seed, extras):
    g = _ground_base(name, w, d, mats, seed, wet_band=7.0)
    _ground_scatter(g, extras, 0.05, seed, min_dist=0.8)
    return g


@asset("ground_shore", tier="env", res=1024, group="env")
def ground_shore():
    return _zone("SM_GroundShore", 50, 56, [SAND, SAND2], 21,
                 [_shell("s1", 1), _pebble("p1", ROCK_LT, 0.06, 2), _pebble("p2", SHELL, 0.04, 3), _tuft("dune", [GRASS3, SAND_DK], 5, (0.2, 0.4), 4)])


@asset("ground_cliffs", tier="env", res=1024, group="env")
def ground_cliffs():
    return _zone("SM_GroundCliffs", 40, 80, [SAND_CLIFF, SAND2], 22,
                 [_pebble("p1", ROCK_LT, 0.08, 5), _pebble("p2", STRATA[1], 0.06, 6), _shell("s1", 7)])


@asset("ground_caves", tier="env", res=1024, group="env")
def ground_caves():
    return _zone("SM_GroundCaves", 40, 80, [SAND_CAVE, SAND_DK], 23,
                 [_pebble("p1", ROCK_DK, 0.09, 8), _pebble("p2", ROCK, 0.06, 9)])


@asset("ground_reef", tier="env", res=1024, group="env")
def ground_reef():
    def coral(p):
        for k in range(5):
            a = k * 1.25
            tube(p, CORAL if k % 2 else PINK, [(0, 0, 0), (0.06 * math.cos(a), 0.06 * math.sin(a), 0.12), (0.1 * math.cos(a), 0.1 * math.sin(a), 0.2)], [0.03, 0.022, 0.012], seg=5)
    return _zone("SM_GroundReef", 45, 80, [SAND_REEF, SAND2], 24,
                 [_pebble("p1", SLATE[0], 0.08, 10), single("c1", coral), _shell("s1", 11)])


@asset("ground_slope", tier="env", res=1024, group="env")
def ground_slope():
    def f(p):
        t = bmesh.new()
        bmesh.ops.create_grid(t, x_segments=60, y_segments=10, size=0.5)
        for v in t.verts:
            x, y = v.co.x * 200, v.co.y * 30.4
            v.co = Vector((x, y, 0.03 * noise.noise(Vector((x * 0.2, y * 0.2, 3.0)))))
        _merge(p, t, SAND_WET)
        rnd = random.Random(3)
        for i in range(170):  # ripple marks left by the tide
            rbox(p, SAND_DK, (rnd.uniform(1.0, 4.0), 0.12, 0.02), loc=(rnd.uniform(-98, 98), rnd.uniform(-14, 14), 0.02), rot=(0, 0, rnd.uniform(-5, 5)), r=0.01, seg=1)
        box(p, SAND_WET, (200, 30.4, 0.06), loc=(0, 0, -0.03))
    return single("SM_GroundSlope", f, smooth=20)


@asset("water_plane", tier="env", paint=False, group="env")
def water_plane():
    def f(p):
        t = bmesh.new()
        bmesh.ops.create_grid(t, x_segments=160, y_segments=70, size=1.0)
        bmesh.ops.scale(t, vec=(160, 70, 1), verts=t.verts)
        _merge(p, t, SEA)
    return single("SM_WaterPlane", f, smooth=80)


@asset("ground_fill", tier="env", res=512, group="env")
def ground_fill():
    """Map-wide underlay (230 x 120 m) a few cm below every ground tile (stops at the waterline slope)."""
    def f(p):
        t = bmesh.new()
        bmesh.ops.create_grid(t, x_segments=46, y_segments=24, size=0.5)
        for v in t.verts:
            x, y = v.co.x * 230, v.co.y * 120
            v.co = Vector((x, y, 0.02 * noise.noise(Vector((x * 0.1, y * 0.1, 5.0)))))
        _merge(p, t, SAND2)
    return single("SM_GroundFill", f, smooth=30)


# --------------------------------------------------------------------- lab ---
@asset("lab_pavilion", tier="building", res=1024, group="env",
       col=[("box", (sx * 4.3, sy * 3.5, 1.7), (0.3, 0.3, 3.4)) for sx in (-1, 1) for sy in (-1, 1)]
       + [("box", (sx * 4.3, 0, 0.6), (0.16, 6.7, 1.2)) for sx in (-1, 1)]
       + [("box", (0, 3.45, 1.0), (2.7, 0.7, 2.0))])
def lab_pavilion():
    def f(p):
        rbox(p, WOOD_DK, (9.2, 7.7, 0.18), loc=(0, 0, -0.02), r=0.035)
        for i in range(23):
            rbox(p, WOOD_LT if i % 2 else WOOD, (0.385, 7.6, 0.05), loc=(-4.4 + i * 0.4, 0, 0.09), r=0.01, seg=1)
        for sx in (-1, 1):
            for sy in (-1, 1):
                rbox(p, WOOD_DK, (0.3, 0.3, 3.4), loc=(sx * 4.3, sy * 3.5, 1.75), r=0.045)
                rbox(p, STONE2, (0.46, 0.46, 0.28), loc=(sx * 4.3, sy * 3.5, 0.14), r=0.045)
                tube(p, WOOD_DK, [(sx * 4.3, sy * 3.5, 2.8), (sx * 3.7, sy * 3.5, 3.35)], 0.065, seg=8)
            rbox(p, WOOD_DK, (0.26, 7.5, 0.28), loc=(sx * 4.3, 0, 3.4), r=0.035)
        for k in range(8):
            rbox(p, WOOD, (9.0, 0.15, 0.19), loc=(0, -3.4 + k * 0.97, 3.58 + (3.4 - k * 0.97) * 0.08), r=0.025)
        ang = math.degrees(math.atan(0.08))
        for r in range(26):
            yy = -4.2 + r * 0.33
            rbox(p, SHOP_ROOF if r % 2 else SHOP_ROOF2, (10.0, 0.39, 0.07), loc=(0, yy, 3.72 + (-yy) * 0.08), rot=(ang, 0, 0), r=0.02, seg=1)
        rbox(p, TRIM, (10.1, 0.09, 0.26), loc=(0, -4.35, 4.0), r=0.025)
        # name board standing on the front fascia, on two short posts
        for x in (-1.3, 1.3):
            rbox(p, WOOD_DK, (0.1, 0.1, 0.5), loc=(x, -4.36, 4.2), r=0.02)
        rbox(p, WOOD_DK, (3.2, 0.13, 0.72), loc=(0, -4.42, 4.5), r=0.035)
        rbox(p, TEAL, (3.0, 0.14, 0.56), loc=(0, -4.42, 4.5), r=0.035)
        text3d(p, CREAM, "PREP LAB", size=0.34, loc=(0, -4.492, 4.5), depth=0.012, max_w=2.6, max_h=0.4)
        # rails: solid rail + balusters (collide; see col)
        for sx in (-1, 1):
            rbox(p, WOOD, (0.1, 6.6, 0.11), loc=(sx * 4.3, 0, 1.0), r=0.02)
            rbox(p, WOOD, (0.08, 6.6, 0.08), loc=(sx * 4.3, 0, 0.2), r=0.015)
            for k in range(9):
                rbox(p, TRIM, (0.06, 0.06, 0.78), loc=(sx * 4.3, -3.0 + k * 0.75, 0.6), r=0.012, seg=1)
        # back wall: tool cabinet on the deck, jar shelf on it, pegboard on two posts
        rbox(p, WOOD, (2.6, 0.6, 0.9), loc=(0, 3.45, 0.55), r=0.03)
        for k in range(3):
            rbox(p, WOOD_LT, (0.76, 0.02, 0.7), loc=(-0.85 + k * 0.85, 3.14, 0.55), r=0.012)
            sph(p, BRASS, 0.025, loc=(-0.85 + k * 0.85, 3.12, 0.72), u=8, v=6)
        rbox(p, WOOD_DK, (2.7, 0.66, 0.06), loc=(0, 3.45, 1.03), r=0.02)
        for k, c in enumerate((BLUE, RED, GREEN, YELLOW)):
            lathe(p, GLASS, [(0.0, 0), (0.06, 0), (0.06, 0.18), (0.03, 0.22), (0.0, 0.22)], seg=10, loc=(-0.8 + k * 0.5, 3.35, 1.06))
            cyl(p, c, 0.05, 0.1, loc=(-0.8 + k * 0.5, 3.35, 1.12), seg=10)
        for x in (-1.25, 1.25):
            rbox(p, WOOD_DK, (0.1, 0.1, 2.0), loc=(x, 3.7, 2.0), r=0.02)
        rbox(p, WOOD_LT, (2.4, 0.05, 0.9), loc=(0, 3.66, 2.35), r=0.02)
        for k in range(6):
            x = -0.95 + k * 0.38
            sph(p, METAL_DK, 0.015, loc=(x, 3.62, 2.62), u=6, v=4)
            cyl(p, C_HANDLE, 0.015, 0.36, loc=(x, 3.61, 2.42), seg=6)
            prism(p, METAL, [(-0.05, 0), (0.05, 0), (0.0, -0.12)], 0.01, plane="XZ", z=-0.005, loc=(x, 3.61, 2.24))
        for x in (-2.0, 2.0):
            cyl(p, IRON, 0.008, 0.6, loc=(x, 0, 3.25), seg=4)
            lathe(p, TEAL, [(0.0, 0.0), (0.22, 0.0), (0.06, 0.18), (0.0, 0.2)], seg=12, loc=(x, 0, 2.75))
            sph(p, GLOW_WARM, 0.07, loc=(x, 0, 2.74), u=8, v=6)
        rbox(p, CONCRETE, (0.9, 0.6, 0.85), loc=(3.4, 2.9, 0.48), r=0.04)
        rbox(p, METAL_DK, (0.7, 0.45, 0.06), loc=(3.4, 2.9, 0.9), r=0.02)
        tube(p, METAL, [(3.4, 3.15, 0.92), (3.4, 3.15, 1.2), (3.4, 2.95, 1.25)], 0.02, seg=6)
        lathe(p, TEAL, [(0.0, 0.0), (0.16, 0.0), (0.2, 0.32), (0.0, 0.32)], seg=12, loc=(2.7, 3.1, 0.1))
    return single("SM_LabPavilion", f)


# ---------------------------------------------------------- cliffs & cave ---
def _relief_trilobite(p, mat, c, s):
    c = Vector(c)
    sph(p, mat, 0.16 * s, loc=c, scale=(0.75, 0.25, 1.0), u=12, v=8)
    sph(p, mat, 0.11 * s, loc=c + Vector((0, -0.01, 0.13 * s)), scale=(1.0, 0.25, 0.6), u=10, v=6)
    for k in range(6):
        rbox(p, mat, (0.24 * s - k * 0.02 * s, 0.05 * s, 0.025 * s), loc=c + Vector((0, -0.035 * s, 0.06 * s - k * 0.04 * s)), r=0.008 * s)


def _relief_vertebrae(p, mat, c, s, n=6):
    c = Vector(c)
    for k in range(n):
        cyl(p, mat, 0.06 * s, 0.07 * s, loc=c + Vector((k * 0.11 * s, 0, math.sin(k * 0.6) * 0.04 * s)), rot=(0, 90, 0), seg=8)
        rbox(p, mat, (0.03 * s, 0.04 * s, 0.1 * s), loc=c + Vector((k * 0.11 * s, -0.01, 0.08 * s + math.sin(k * 0.6) * 0.04 * s)), r=0.01 * s)


def _cliff(p, mats, seed, w=9.0, d=5.0, layers=6, lh=1.15, era="meso"):
    rnd = random.Random(seed)
    for i in range(layers):
        sw = w - i * rnd.uniform(0.25, 0.6)
        sd = d - i * rnd.uniform(0.15, 0.35)
        slab(p, mats[i % len(mats)], (sw, sd, lh), loc=(rnd.uniform(-0.3, 0.3), rnd.uniform(-0.2, 0.2), lh / 2 + i * lh * 0.96), seed=seed + i, rough=0.08, cuts=6)
        if rnd.random() < 0.6:
            slab(p, mats[(i + 2) % len(mats)], (sw * 0.3, 0.4, lh * 0.4), loc=(rnd.uniform(-w / 3, w / 3), -sd / 2 - 0.1, lh * 0.3 + i * lh * 0.96), seed=seed + 40 + i, rough=0.05, cuts=2)
        # relief fossils of this era peeking out of the strata
        if i in (1, 3) and i < layers:
            fx = rnd.uniform(-w / 4, w / 4)
            fz = lh * 0.5 + i * lh * 0.96
            fy = -sd / 2 - 0.02
            if era == "meso":
                if i == 1:
                    spiral(p, [FBONE, SHELL2], turns=3.0, a=0.03, growth=0.19, tube_k=0.42, center=(fx, fy - 0.05, fz), seg=8)
                else:
                    _relief_vertebrae(p, FBONE, (fx - 0.6, fy - 0.05, fz), 2.6, n=8)
            elif era == "paleo":
                _relief_trilobite(p, ROCK_LT, (fx, fy - 0.08, fz), 3.2)
            else:
                for k in range(3):
                    lathe(p, SHELL, [(0.0, 0.0), (0.12, 0.04), (0.1, 0.2), (0.04, 0.32), (0.0, 0.36)], seg=8, loc=(fx + k * 0.45, fy - 0.05, fz), rot=(90, 0, k * 20))
    top = layers * lh * 0.96
    slab(p, GRASS2, (w - layers * 0.45, d - layers * 0.25, 0.28), loc=(0, 0, top + 0.06), seed=seed + 90, rough=0.06, cuts=4)
    for k in range(12):
        x, y = rnd.uniform(-w / 3, w / 3), rnd.uniform(-d / 3, d / 3)
        for j in range(4):
            cyl(p, GRASS3, 0.045, 0.38, loc=(x + j * 0.06, y, top + 0.32), r2=0.003, rot=(rnd.uniform(-25, 25), rnd.uniform(-25, 25), 0), seg=4)
    for k in range(3):  # overhanging grass lip (stylized cartoon read)
        sph(p, GRASS, 0.5, loc=(rnd.uniform(-w / 3, w / 3), -(d - layers * 0.25) / 2, top + 0.1), scale=(1.4, 0.6, 0.45), u=10, v=6)
    for k in range(6):
        rock(p, mats[(k + 1) % len(mats)], rnd.uniform(0.3, 0.7), loc=(rnd.uniform(-w / 2, w / 2), -d / 2 - 0.4, 0.2), seed=seed + 20 + k, sub=2)


SCULPT_ROCK = dict(strength=0.8, scale=3.0)


@asset("cliff_meso", tier="env", res=1024, sculpt=SCULPT_ROCK, group="env", col=[("hull", None, 1.0)])
def cliff_meso():
    return single("SM_CliffMeso", lambda p: _cliff(p, STRATA, 11, era="meso"), smooth=40)


@asset("cliff_paleo", tier="env", res=1024, sculpt=SCULPT_ROCK, group="env", col=[("hull", None, 1.0)])
def cliff_paleo():
    return single("SM_CliffPaleo", lambda p: _cliff(p, SLATE, 21, era="paleo"), smooth=40)


@asset("cliff_ceno", tier="env", res=1024, sculpt=SCULPT_ROCK, group="env", col=[("hull", None, 1.0)])
def cliff_ceno():
    return single("SM_CliffCeno", lambda p: _cliff(p, SANDST, 31, layers=4, era="ceno"), smooth=40)


@asset("cave_arch", tier="env", res=1024, sculpt=SCULPT_ROCK, group="env", col=[("hull", None, 1.0)])
def cave_arch():
    def f(p):
        rnd = random.Random(5)
        for i in range(17):
            a = math.pi * i / 16
            x, z = 3.0 * math.cos(a), 3.4 * math.sin(a)
            rock(p, STRATA[i % 4] if i % 3 else ROCK_DK, rnd.uniform(1.0, 1.3), loc=(x, 0, z + 0.4), scale=(1, 1.4, 1), seed=40 + i, sub=2)
        box(p, CAVE_DK, (5.2, 0.4, 4.6), loc=(0, 1.8, 2.1))
        box(p, CAVE_DK, (5.2, 3.2, 0.2), loc=(0, 0.4, -0.05))
        for i in range(9):
            cyl(p, ROCK_DK, rnd.uniform(0.08, 0.16), rnd.uniform(0.4, 0.9), loc=(rnd.uniform(-1.8, 1.8), rnd.uniform(0.2, 1.4), 3.4), r2=0.01, rot=(180, 0, 0), seg=6)
        for i in range(6):  # glowing cave crystals: the "something's in here" lure
            cyl(p, GLOW_CYAN, 0.07, 0.3, loc=(rnd.uniform(-2, 2), 1.2, rnd.uniform(0.2, 1.0)), r2=0.0, rot=(rnd.uniform(-30, 30), rnd.uniform(-30, 30), 0), seg=6)
        # lantern + warning sign at the entrance
        cyl(p, WOOD_DK, 0.04, 1.4, loc=(-2.4, -1.6, 0.7), seg=6)
        rbox(p, STRIPE_Y, (0.5, 0.04, 0.4), loc=(-2.4, -1.63, 1.25), r=0.02)
        rbox(p, IRON, (0.14, 0.14, 0.2), loc=(2.3, -1.4, 0.1), r=0.02)
        cyl(p, GLOW_WARM, 0.045, 0.12, loc=(2.3, -1.4, 0.12), seg=8)
    return single("SM_CaveArch", f, smooth=42)


@asset("fence_barrier", tier="prop", group="env", col=[("box", (0, 0, 0.8), (4.0, 0.3, 1.6))])
def fence_barrier():
    def f(p):
        for x in (-1.9, 0, 1.9):
            cyl(p, WOOD_DK, 0.085, 1.4, loc=(x, 0, 0.7), seg=10)
            cyl(p, WOOD_DK, 0.085, 0.16, loc=(x, 0, 1.48), r2=0.0, seg=10)
        for x0, x1 in ((-1.9, 0), (0, 1.9)):
            tube(p, ROPE, curve_pts((x0, 0, 1.25), (x1, 0, 1.25), (0, 0, -0.2), 8), 0.027, seg=6)
        rbox(p, WOOD, (4.0, 0.09, 0.17), loc=(0, 0, 0.5), r=0.025)
        rbox(p, STRIPE_Y, (1.35, 0.065, 0.62), loc=(0, -0.08, 0.85), r=0.035)
        text3d(p, DARK, "PERMIT\nREQUIRED", size=0.2, loc=(0, -0.113, 0.86), depth=0.006, max_w=1.15, max_h=0.5, res=1)
        text3d(p, DARK, "PERMIT\nREQUIRED", size=0.2, loc=(0, -0.047, 0.86), rot=(90, 0, 180), depth=0.006, max_w=1.15, max_h=0.5, res=1)
        tube(p, WOOD_DK, [(1.9, 0, 1.5), (1.9, 0, 2.0)], 0.022, seg=6)
        prism(p, RED, [(0, 0), (0.35, -0.1), (0, -0.2)], 0.012, plane="XZ", loc=(1.9, 0, 2.0))
        # padlock: "permit required"
        rbox(p, BRASS, (0.12, 0.05, 0.12), loc=(0.0, -0.13, 0.42), r=0.02)
        tube(p, METAL, [(-0.035, -0.13, 0.47), (-0.035, -0.13, 0.53), (0.035, -0.13, 0.53), (0.035, -0.13, 0.47)], 0.01, seg=5)
    return single("SM_FenceBarrier", f)
