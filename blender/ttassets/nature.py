"""Nature + dig nodes (vegetation-artist, sculpting, procedural-modeling, stylized-style).

Vegetation: stylized puff / folded-frond shapes (not botanical accuracy), 0.5-3k tris.
Rocks: noise-displaced icospheres whose high-frequency detail is baked into a normal
map from a displaced high-poly copy (sculpt -> bake), keeping the game mesh light.
Dig nodes are gameplay interactables: saturated accents + a marker flag so they read
against the desaturated beach (strategy-sim readability rule).
"""
import random

from tt.geo import *  # noqa
from tt.mats import *  # noqa
from tt.pipe import asset, single

ROCK_SCULPT = dict(strength=1.0, scale=2.5)


def _frond(p, top, yaw, ln, mats, droop=1.05, width=0.32):
    """Folded palm frond: a wide two-sided strip with a sawtooth outline + spine."""
    d = Vector((math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0))
    side = Vector((-d.y, d.x, 0))
    t = bmesh.new()
    rows = []
    segs = 10
    for i in range(segs + 1):
        u = i / segs
        c = top + d * ln * u + Vector((0, 0, 0.5 * ln * u - droop * ln * u * u + 0.12))
        w = width * math.sin(math.pi * min(0.97, 0.08 + u * 0.92)) * (1.0 if i % 2 == 0 else 0.78)
        fold = Vector((0, 0, -w * 0.45))
        rows.append([t.verts.new(c + side * w + fold), t.verts.new(c + Vector((0, 0, 0.01))), t.verts.new(c - side * w + fold),
                     t.verts.new(c + side * w + fold - Vector((0, 0, 0.012))), t.verts.new(c - Vector((0, 0, 0.004))), t.verts.new(c - side * w + fold - Vector((0, 0, 0.012)))])
    for i in range(segs):
        a, b = rows[i], rows[i + 1]
        t.faces.new((a[0], a[1], b[1], b[0]))
        t.faces.new((a[1], a[2], b[2], b[1]))
        t.faces.new((b[3], b[4], a[4], a[3]))
        t.faces.new((b[4], b[5], a[5], a[4]))
    _m(p, t, mats[0])
    spine = [top + d * ln * u + Vector((0, 0, 0.5 * ln * u - droop * ln * u * u + 0.13)) for u in (0.0, 0.3, 0.6, 1.0)]
    tube(p, mats[1], spine, [0.035, 0.026, 0.016, 0.004], seg=5, cap=False)


def _m(p, t, mat):
    from tt.geo import _merge
    _merge(p, t, mat)


@asset("palm_tree", tier="prop", group="nature", col=[("box", (0.2, 0, 2.0), (0.6, 0.6, 4.0))])
def palm_tree():
    def f(p):
        rnd = random.Random(1)
        pts = [Vector((0.45 * math.sin(i / 10 * 1.5) * (i / 10), 0, i * 0.62)) for i in range(11)]
        for i in range(10):  # ringed trunk segments, flaring at each ring
            r0 = 0.27 - i * 0.012
            tube(p, TRUNK if i % 2 == 0 else TRUNK2, [pts[i], pts[i].lerp(pts[i + 1], 0.82)], [r0 * 1.06, r0 * 0.9], seg=10)
            tube(p, TRUNK2, [pts[i].lerp(pts[i + 1], 0.78), pts[i + 1]], [r0 * 0.86, r0 * 1.0], seg=10)
        cyl(p, TRUNK2, 0.34, 0.25, loc=(0, 0, 0.1), seg=10, r2=0.26)
        top = pts[-1]
        sph(p, TRUNK2, 0.26, loc=top + Vector((0, 0, 0.05)), scale=(1.0, 1.0, 0.8), u=10, v=8)
        for k in range(10):
            yaw = k * 36 + rnd.uniform(-10, 10)
            _frond(p, top, yaw, rnd.uniform(2.3, 2.9), [LEAF if k % 2 else LEAF_LT, LEAF_DK], droop=rnd.uniform(0.9, 1.2))
        for k in range(3):  # young upright fronds in the crown
            _frond(p, top, k * 120 + 20, 1.2, [LEAF_LT, LEAF_DK], droop=0.2, width=0.2)
        for k in range(5):
            a = k * 1.3
            sph(p, COCONUT, 0.14, loc=top + Vector((0.2 * math.cos(a), 0.2 * math.sin(a), -0.2 - (k % 2) * 0.08)), u=10, v=8)
    return single("SM_PalmTree", f)


@asset("fern", tier="item", group="nature")
def fern():
    def f(p):
        rnd = random.Random(4)
        for k in range(9):
            yaw = k * 40 + rnd.uniform(-8, 8)
            ln = rnd.uniform(0.7, 1.0)
            d = Vector((math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0))
            arc = lambda u: d * ln * u + Vector((0, 0, 1.0 * ln * u - 1.15 * ln * u * u + 0.05))
            for j in range(1, 8):
                u = j / 8
                for side in (1, -1):
                    leaf(p, LEAF if j % 2 else GRASS, arc(u), yaw + side * 72, 0.24 * (1 - 0.6 * u), 0.05, rise=0.3, droop=0.8, segs=3, thick=0.006, fold=0.2)
            tube(p, LEAF_DK, [arc(u) for u in (0, 0.33, 0.66, 1.0)], [0.016, 0.012, 0.008, 0.003], seg=4)
        for k in range(3):  # fiddleheads
            a = k * 2.1
            spiral(p, [LEAF_LT], turns=1.4, a=0.01, growth=0.3, tube_k=0.5, ppt=10, center=(0.1 * math.cos(a), 0.1 * math.sin(a), 0.32), seg=5)
    return single("SM_Fern", f)


@asset("grass_tuft", tier="small", group="nature")
def grass_tuft():
    def f(p):
        rnd = random.Random(2)
        for k in range(12):
            a = k / 12 * TAU + rnd.uniform(-0.2, 0.2)
            h = rnd.uniform(0.35, 0.7)
            base = Vector((0.1 * math.cos(a), 0.1 * math.sin(a), 0))
            tip = base * 2.8 + Vector((0, 0, h))
            tube(p, (GRASS, LEAF, GRASS3)[k % 3], [base, base.lerp(tip, 0.55) + Vector((0, 0, 0.06)), tip], [0.026, 0.017, 0.002], seg=4)
        for k in range(2):  # seed heads
            sph(p, SAND_DK, 0.03, loc=(0.05 * k, 0.02, 0.72 - k * 0.1), scale=(0.6, 0.6, 1.6), u=6, v=4)
            cyl(p, GRASS3, 0.006, 0.7 - k * 0.1, loc=(0.05 * k, 0.02, 0.35 - k * 0.05), seg=3)
    return single("SM_GrassTuft", f)


@asset("rock_small", tier="item", sculpt=ROCK_SCULPT, group="nature", col=[("hull", None, 0.92)])
def rock_small():
    def f(p):
        rock(p, ROCK, 0.5, loc=(0, 0, 0.16), scale=(1.25, 1.0, 0.75), seed=3, sub=3)
        sph(p, GRASS2, 0.18, loc=(0.25, 0.15, 0.48), scale=(1.4, 1.0, 0.35), u=8, v=6)  # moss cap
    return single("SM_RockSmall", f, smooth=42)


@asset("rock_large", tier="prop", sculpt=ROCK_SCULPT, group="nature", col=[("hull", None, 0.9)])
def rock_large():
    def f(p):
        rock(p, ROCK, 1.2, loc=(0, 0, 0.55), scale=(1.4, 1.1, 0.95), seed=7, sub=3)
        rock(p, ROCK_DK, 0.62, loc=(1.25, 0.45, 0.28), seed=8, sub=3)
        rock(p, ROCK_LT, 0.45, loc=(-1.25, -0.55, 0.18), seed=9, sub=2)
        sph(p, GRASS2, 0.5, loc=(-0.2, 0.2, 1.35), scale=(1.5, 1.1, 0.3), u=10, v=6)
        rnd = random.Random(1)
        for i in range(7):
            cyl(p, GRASS, 0.035, 0.32, loc=(-0.7 + i * 0.25, -0.95, 0.12), r2=0.002, rot=(rnd.uniform(-15, 15), 0, 0), seg=4)
        # barnacles near the base: tide line story
        for i in range(10):
            a = i * 0.7
            cyl(p, ROCK_LT, 0.04, 0.04, loc=(1.6 * math.cos(a) * 0.8, 1.2 * math.sin(a) * 0.8, 0.2), r2=0.02, seg=6)
    return single("SM_RockLarge", f, smooth=42)


@asset("driftwood", tier="item", group="nature")
def driftwood():
    def f(p):
        tube(p, DRIFT, curve_pts((-1.2, 0, 0.12), (1.2, 0.15, 0.1), (0, 0.15, 0.05), 8), [0.12, 0.14, 0.13, 0.12, 0.1, 0.09, 0.07, 0.05], seg=10)
        tube(p, DRIFT_DK, curve_pts((0.1, 0.0, 0.15), (0.6, 0.65, 0.35), (0.1, 0, 0.05), 5), [0.065, 0.05, 0.04, 0.03, 0.015], seg=8)
        tube(p, DRIFT, curve_pts((-0.6, 0.0, 0.14), (-0.9, -0.5, 0.25), (0, -0.1, 0.05), 4), [0.05, 0.04, 0.03, 0.012], seg=8)
        for x in (-0.5, 0.35):
            sph(p, DRIFT_DK, 0.05, loc=(x, -0.12, 0.15), scale=(1.0, 0.5, 1.0), u=8, v=6)
        # snagged seaweed + a crab-claw shell
        tube(p, LEAF_DK, [(-0.2, 0.1, 0.25), (-0.1, 0.25, 0.08), (0.05, 0.35, 0.02)], [0.03, 0.025, 0.01], seg=5)
        tube(p, CORAL, [(0.8, -0.2, 0.03), (0.9, -0.25, 0.08), (0.95, -0.2, 0.06)], [0.025, 0.02, 0.008], seg=5)
    return single("SM_Driftwood", f)


@asset("shell_deco", tier="small", group="nature")
def shell_deco():
    def f(p):
        for k in range(9):  # scallop
            a = math.radians(-60 + k * 15)
            tube(p, PINK if k % 2 else SHELL, [(0, 0, 0.01), (0.14 * math.sin(a), 0.14 * math.cos(a), 0.035)], [0.012, 0.03], seg=6)
        rbox(p, PINK, (0.06, 0.04, 0.025), loc=(0, -0.01, 0.012), r=0.01)
        lathe(p, STRIPE_W, [(0.0, 0.0), (0.05, 0.02), (0.04, 0.08), (0.02, 0.13), (0.0, 0.15)], seg=10, loc=(0.2, 0.1, 0.03), rot=(80, 0, 30))
        for k in range(5):  # starfish
            a = math.radians(90 + k * 72)
            tube(p, CORAL, [(-0.2, 0.05, 0.015), (-0.2 + 0.1 * math.cos(a), 0.05 + 0.1 * math.sin(a), 0.012)], [0.03, 0.01], seg=5)
    return single("SM_ShellDeco", f)


# ---------------------------------------------------------------- dig nodes --
def _flag(p, x, y, mat=CORAL):
    cyl(p, WOOD_LT, 0.016, 0.75, loc=(x, y, 0.37), seg=6)
    prism(p, mat, [(0, 0), (0.22, -0.07), (0, -0.15)], 0.008, plane="XZ", loc=(x, y, 0.75))


@asset("node_sand", tier="item", group="nodes")
def node_sand():
    def f(p):
        rock(p, SAND_WET, 0.8, loc=(0, 0, 0), scale=(1, 1, 0.34), seed=1, sub=3, rough=0.12, floor=0.0)
        rock(p, SAND, 0.42, loc=(0.32, 0.22, 0.08), scale=(1, 1, 0.42), seed=2, sub=2, rough=0.15, floor=0.0)
        for k in range(3):  # raked lines
            tube(p, SAND_DK, [(-0.6 + k * 0.1, -0.5 + k * 0.3, 0.12), (-0.2 + k * 0.1, -0.6 + k * 0.3, 0.14)], 0.022, seg=4)
        sph(p, PINK, 0.065, loc=(-0.4, 0.3, 0.16), scale=(1, 0.8, 0.4), u=10, v=6)
        rock(p, ROCK_LT, 0.06, loc=(0.5, -0.35, 0.12), seed=5, sub=1)
        _flag(p, 0.55, 0.45)
    return single("SM_NodeSand", f, smooth=45)


@asset("node_dirt", tier="item", group="nodes")
def node_dirt():
    def f(p):
        rock(p, SAND_DK, 0.75, loc=(0, 0, 0), scale=(1, 1, 0.55), seed=4, sub=3, rough=0.2, floor=0.0)
        for k in range(6):
            a = k * 1.1
            rock(p, SOIL, 0.14, loc=(0.6 * math.cos(a), 0.6 * math.sin(a), 0.06), seed=k, sub=1, rough=0.3)
        tube(p, TRUNK2, curve_pts((-0.3, -0.2, 0.25), (0.2, -0.5, 0.15), (0, -0.1, 0.1), 5), [0.02, 0.018, 0.014, 0.01, 0.005], seg=5)
        for k in range(4):
            cyl(p, GRASS, 0.03, 0.34, loc=(0.15 * k - 0.2, 0.1, 0.46), r2=0.003, rot=(10 * k - 10, 0, 0), seg=4)
        _flag(p, -0.5, 0.45)
    return single("SM_NodeDirt", f, smooth=45)


@asset("node_cracked_rock", tier="item", sculpt=ROCK_SCULPT, group="nodes")
def node_cracked_rock():
    def f(p):
        rock(p, ROCK, 0.6, loc=(-0.28, 0, 0.35), scale=(1.0, 1.05, 0.95), seed=12, sub=3, rot=(0, -6, 0))
        rock(p, ROCK_LT, 0.55, loc=(0.34, 0.04, 0.3), scale=(1.0, 1.0, 0.9), seed=13, sub=3, rot=(0, 8, 0))
        for k in range(3):
            rock(p, ROCK_DK, 0.12, loc=(0.0 + k * 0.08, -0.62, 0.05), seed=30 + k, sub=1)
        spiral(p, [SHELL, SHELL2], turns=2.4, a=0.012, growth=0.22, tube_k=0.42, center=(0.05, -0.52, 0.45))
    return single("SM_NodeCrackedRock", f, smooth=42)


@asset("node_hard_rock", tier="item", sculpt=ROCK_SCULPT, group="nodes")
def node_hard_rock():
    def f(p):
        rock(p, ROCK_BLUE, 0.82, loc=(0, 0, 0.4), scale=(1.1, 1, 0.95), seed=14, sub=3)
        rnd = random.Random(3)
        for c in range(4):
            a = c * 1.6 + 0.4
            base = Vector((0.5 * math.cos(a), 0.45 * math.sin(a), 0.92))
            for k in range(3):
                h = rnd.uniform(0.35, 0.7)
                cyl(p, GEM2 if k % 2 else GLOW_CYAN, 0.1, h, loc=base + Vector((rnd.uniform(-0.08, 0.08), rnd.uniform(-0.08, 0.08), h / 2)), r2=0.0,
                    rot=(rnd.uniform(-30, 30), rnd.uniform(-30, 30), 0), seg=6)
    return single("SM_NodeHardRock", f, smooth=30)


@asset("node_deep_rock", tier="item", sculpt=ROCK_SCULPT, group="nodes")
def node_deep_rock():
    def f(p):
        for i in range(5):
            slab(p, SLATE[i % 5], (1.5 - i * 0.16, 1.2 - i * 0.1, 0.22), loc=(0.04 * i, 0.02 * i, 0.11 + i * 0.21), rot=(0, 0, i * 6), seed=60 + i, rough=0.03, cuts=3)
        sph(p, ROCK_DK, 0.2, loc=(0, -0.48, 0.56), scale=(0.75, 0.15, 1.0), u=12, v=8)
        for k in range(5):  # trilobite peeking out of the slate
            rbox(p, SLATE[3], (0.28 - k * 0.03, 0.03, 0.03), loc=(0, -0.53, 0.46 + k * 0.045), r=0.01)
        sph(p, SLATE[2], 0.08, loc=(0, -0.53, 0.7), scale=(1.4, 0.3, 0.8), u=8, v=6)
    return single("SM_NodeDeepRock", f, smooth=38)


@asset("node_buried", tier="item", group="nodes")
def node_buried():
    def f(p):
        rock(p, SAND, 0.65, loc=(0, 0, 0), scale=(1, 1, 0.22), seed=20, sub=3, rough=0.12, floor=0.0)
        tube(p, FBONE, [(-0.1, 0, 0.05), (0.15, 0.05, 0.25), (0.25, 0.08, 0.38)], [0.065, 0.05, 0.075], seg=10)
        sph(p, FBONE, 0.075, loc=(0.27, 0.08, 0.42), u=10, v=8)
        for sx in (1, -1):  # the X marks the spot
            rbox(p, CORAL, (0.48, 0.08, 0.05), loc=(-0.3, -0.2, 0.1), rot=(0, 0, sx * 45), r=0.02)
    return single("SM_NodeBuried", f, smooth=45)
