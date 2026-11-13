"""Specimens, finds, living fossils and mega-skeletons (prop-artist + sculpting +
creature-artist proportions + stylized-style).

Fossil display models use the tint material "Fossil" (Godot recolours it per
species). Skeleton pieces are separate objects named Skull / Jaw / Neck / Back /
Ribs / Flippers|ForeFlipper / HindFlipper / Tail / Mount (the game toggles them as
pieces are found). Anatomy is stylized but true where it teaches something:
ichthyosaur + mosasaur tails bend DOWN into the lower fluke lobe (real tailbend),
ichthyosaurs have huge sclerotic eye rings, mosasaurs a double row of palate teeth.
"""
import random

from tt.geo import *  # noqa
from tt.mats import *  # noqa
from tt.pipe import asset, single, finish, empty

BONE_SCULPT = dict(strength=0.5, scale=6.0)


# ------------------------------------------------------------------ finds ---
@asset("gem", tier="small", group="specimens", res=256, paint=True)
def gem():
    def f(p):
        lathe(p, GEM, [(0.0, 0.0), (0.12, 0.13), (0.105, 0.17), (0.0, 0.2)], seg=8)
        lathe(p, GEM2, [(0.0, 0.17), (0.105, 0.17), (0.0, 0.207)], seg=8)
    return single("SM_Gem", f, smooth=5)


@asset("ore", tier="small", group="specimens", res=256)
def ore():
    def f(p):
        rock(p, ROCK_DK, 0.13, loc=(0, 0, 0.1), seed=5, sub=2, rough=0.3)
        rnd = random.Random(4)
        for k in range(8):
            a, b = rnd.uniform(0, 6.28), rnd.uniform(-0.6, 0.9)
            rock(p, FLECK, 0.042, loc=(0.12 * math.cos(a) * math.cos(b), 0.12 * math.sin(a) * math.cos(b), 0.1 + 0.12 * math.sin(b)), seed=k, sub=1, rough=0.4)
    return single("SM_Ore", f, smooth=40)


@asset("amber", tier="small", group="specimens", res=256)
def amber():
    """Baltic-style amber: a translucent resin drop with a trapped fungus gnat
    (Eocene, ~44 million years). A real fossil type, not a gem."""
    def f(p):
        rock(p, AMBER, 0.12, loc=(0, 0, 0.09), scale=(1.25, 0.95, 0.8), seed=12, sub=3, rough=0.12, floor=-0.6)
        sph(p, AMBER_DK, 0.02, loc=(0.0, 0, 0.1), scale=(1.8, 0.8, 0.8), u=8, v=6)
        sph(p, AMBER_DK, 0.012, loc=(0.042, 0, 0.104), u=6, v=4)
        for sy in (-1, 1):
            sph(p, GLASS, 0.022, loc=(-0.012, sy * 0.022, 0.118), scale=(1.6, 0.9, 0.12), rot=(0, -12, sy * 20), u=8, v=4)
            for k in range(3):
                tube(p, AMBER_DK, [(0.01 - k * 0.014, sy * 0.008, 0.096), (0.016 - k * 0.022, sy * 0.032, 0.08)], 0.0025, seg=3)
    return single("SM_Amber", f, smooth=60)


@asset("geode", tier="small", group="specimens", res=256, sculpt=dict(strength=1.2, scale=3.0))
def geode():
    def f(p):
        rock(p, ROCK, 0.14, loc=(0, 0, 0.12), scale=(1.1, 1, 0.9), seed=9, sub=3, rough=0.15)
        tube(p, ROCK_LT, [(0.14 * math.cos(a / 16 * TAU) * 1.1, 0.14 * math.sin(a / 16 * TAU), 0.12) for a in range(17)], 0.006, seg=4, cap=False)
    return single("SM_Geode", f, smooth=40)


@asset("geode_open", tier="small", group="specimens", res=256)
def geode_open():
    def f(p):
        sph(p, ROCK, 0.14, loc=(0, 0, 0.0), hemi=True, u=16, v=10)
        cyl(p, ROCK_LT, 0.13, 0.012, loc=(0, 0, 0.0), seg=16)
        pur = M("GemPurple", "#b47aff", rough=0.1, emit=0.6)
        rnd = random.Random(2)
        for k in range(16):
            a = rnd.uniform(0, TAU)
            r = rnd.uniform(0.0, 0.095)
            cyl(p, pur, 0.019, 0.055, loc=(r * math.cos(a), r * math.sin(a), 0.01), r2=0.0, rot=(rnd.uniform(-20, 20), rnd.uniform(-20, 20), 0), seg=6)
    return single("SM_GeodeOpen", f, smooth=20)


@asset("fossil_rock", tier="small", group="specimens", res=256, sculpt=dict(strength=1.2, scale=3.0))
def fossil_rock():
    def f(p):
        rock(p, MATRIX, 0.2, loc=(0, 0, 0.15), scale=(1.2, 1, 0.85), seed=11, sub=2, rough=0.3)
        rock(p, MATRIX2, 0.1, loc=(0.15, 0.1, 0.1), seed=12, sub=1, rough=0.3)
        tube(p, FBONE, [(-0.12, -0.12, 0.2), (0.05, -0.15, 0.25), (0.15, -0.12, 0.27)], [0.042, 0.036, 0.052], seg=8)
        sph(p, FBONE, 0.052, loc=(0.16, -0.12, 0.28), u=8, v=6)
        spiral(p, [SHELL2], turns=1.6, a=0.008, growth=0.25, tube_k=0.35, ppt=12, center=(-0.1, -0.18, 0.12), seg=5)
    return single("SM_FossilRock", f, smooth=40)


# --------------------------------------------------------- display fossils --
@asset("ammonite", tier="small", group="specimens", res=256, sculpt=BONE_SCULPT)
def ammonite():
    def f(p):
        spiral(p, [FOSSIL, FOSSIL], turns=3.0, a=0.008, growth=0.2, tube_k=0.45, center=(0, 0, 0.17), seg=12)
        # growth ribs on the outer whorl (low bumps, painted darker)
        for k in range(16):
            th = 2.1 * TAU + k / 16 * 0.9 * TAU
            r = 0.008 * math.exp(0.2 * th)
            c = Vector((r * math.cos(th), 0.0, 0.17 + r * math.sin(th)))
            sph(p, SHELL, r * 0.2, loc=c, scale=(1.0, 2.2, 1.0), u=6, v=4)
        tube(p, SHELL2, [(0.17 * math.cos(a / 24 * TAU), 0.0, 0.17 + 0.17 * math.sin(a / 24 * TAU)) for a in range(25)], 0.007, seg=5, cap=False)
    return single("SM_Ammonite", f)


@asset("trilobite", tier="small", group="specimens", res=256, sculpt=BONE_SCULPT)
def trilobite():
    """Three lobes (axial + two pleural) - the feature the name means."""
    def f(p):
        sph(p, FOSSIL, 0.1, loc=(0, -0.1, 0.02), hemi=True, scale=(1.25, 0.85, 0.5), u=18, v=10)  # cephalon
        sph(p, SHELL, 0.05, loc=(0, -0.11, 0.04), hemi=True, scale=(0.8, 1.0, 0.8), u=12, v=8)    # glabella
        for i in range(8):
            w = 0.1 - i * 0.008
            rbox(p, FOSSIL, (w * 2, 0.034, 0.045), loc=(0, -0.02 + i * 0.032, 0.03), r=0.014)
            rbox(p, SHELL, (0.045, 0.034, 0.05), loc=(0, -0.02 + i * 0.032, 0.036), r=0.016)  # axial lobe
        sph(p, FOSSIL, 0.05, loc=(0, 0.25, 0.02), hemi=True, scale=(1.2, 0.8, 0.5), u=12, v=8)  # pygidium
        for sx in (1, -1):
            sph(p, SHELL2, 0.022, loc=(sx * 0.05, -0.13, 0.058), u=8, v=6)   # compound calcite eyes
            tube(p, FOSSIL, [(sx * 0.11, -0.12, 0.01), (sx * 0.13, -0.02, 0.0), (sx * 0.12, 0.08, 0.0)], 0.009, seg=5)  # genal spines
    return single("SM_Trilobite", f)


@asset("tooth", tier="small", group="specimens", res=256)
def tooth():
    def f(p):
        n = 14
        zig = lambda i: 0.007 if (i % 2 and 0 < i < n) else 0.0  # serrations
        left = [(-0.1 + 0.1 * (i / n) - zig(i), 0.3 * (i / n)) for i in range(n + 1)]
        right = [(0.1 * (i / n) + zig(i), 0.3 * (1 - i / n)) for i in range(1, n + 1)]
        prism(p, FOSSIL, left + right, 0.05, plane="XZ", z=-0.025, loc=(0, 0, 0.06))
        rbox(p, SHELL2, (0.25, 0.075, 0.085), loc=(0, 0, 0.04), r=0.025)  # root
    return single("SM_Tooth", f, smooth=30)


@asset("bone", tier="small", group="specimens", res=256, sculpt=BONE_SCULPT)
def bone():
    def f(p):
        tube(p, FOSSIL, [(-0.22, 0, 0.06), (-0.1, 0, 0.068), (0, 0, 0.07), (0.1, 0, 0.068), (0.22, 0, 0.06)], [0.04, 0.032, 0.03, 0.032, 0.04], seg=10)
        for x in (-0.24, 0.24):
            sph(p, FOSSIL, 0.054, loc=(x, 0.03, 0.06), u=10, v=8)
            sph(p, FOSSIL, 0.054, loc=(x, -0.03, 0.06), u=10, v=8)
    return single("SM_Bone", f)


@asset("crinoid", tier="small", group="specimens", res=256)
def crinoid():
    """'Sea lily': star-shaped stem plates (St Cuthbert's beads) + feathery arms."""
    def f(p):
        for i in range(10):
            cyl(p, FOSSIL if i % 2 else SHELL, 0.03, 0.032, loc=(0, 0, 0.02 + i * 0.033), seg=10, r2=0.027)
        lathe(p, FOSSIL, [(0.03, 0.34), (0.07, 0.4), (0.06, 0.44), (0.0, 0.44)], seg=10)
        for k in range(5):
            a = k / 5 * TAU
            pts = [(0.04 * math.cos(a), 0.04 * math.sin(a), 0.42), (0.08 * math.cos(a), 0.08 * math.sin(a), 0.52), (0.05 * math.cos(a), 0.05 * math.sin(a), 0.63)]
            tube(p, SHELL, pts, [0.018, 0.012, 0.004], seg=6)
            for j in range(3):  # pinnules
                b = Vector(pts[1]) * (0.6 + j * 0.2)
                tube(p, FOSSIL, [b, b + Vector((0.03 * math.cos(a + 0.6), 0.03 * math.sin(a + 0.6), 0.02))], [0.006, 0.002], seg=4)
    return single("SM_Crinoid", f)


@asset("sand_dollar", tier="small", group="specimens", res=256)
def sand_dollar():
    def f(p):
        lathe(p, FOSSIL, [(0.0, 0.0), (0.14, 0.0), (0.146, 0.012), (0.12, 0.03), (0.0, 0.042)], seg=24)
        for k in range(5):  # five-fold petal pattern (echinoderm symmetry)
            a = k / 5 * TAU
            for sgn in (1, -1):
                tube(p, SHELL2, [(0.015 * math.cos(a), 0.015 * math.sin(a), 0.042), (0.06 * math.cos(a + sgn * 0.25), 0.06 * math.sin(a + sgn * 0.25), 0.038),
                                 (0.09 * math.cos(a), 0.09 * math.sin(a), 0.032)], 0.0065, seg=5)
    return single("SM_SandDollar", f)


@asset("snail_shell", tier="small", group="specimens", res=256)
def snail_shell():
    def f(p):
        pts, rad = [], []
        for i in range(60):
            u = i / 59
            a = u * 6 * TAU
            r = 0.085 * (1 - u * 0.92)
            pts.append((r * math.cos(a), r * math.sin(a), 0.02 + u * 0.33))
            rad.append(0.05 * (1 - u * 0.9))
        tube(p, FOSSIL, pts, rad, seg=10)
        for j in range(6, 59, 6):  # whorl sutures
            sph(p, SHELL2, rad[j] * 1.02, loc=pts[j], scale=(1.0, 1.0, 0.25), u=8, v=4)
        lathe(p, SHELL2, [(0.0, 0.0), (0.03, 0.0), (0.035, 0.02), (0.0, 0.025)], seg=10, loc=(0.06, -0.03, 0.02), rot=(70, 0, 0))  # aperture
    return single("SM_SnailShell", f)


# --------------------------------------------------------- living fossils ---
@asset("horseshoe_crab", tier="small", group="specimens", res=256)
def horseshoe_crab():
    def f(p):
        sh, sh2 = M("CrabShell", "#7a6a3a"), M("CrabShell2", "#5f522c")
        sph(p, sh, 0.16, loc=(0, -0.03, 0.0), hemi=True, scale=(1.0, 0.95, 0.42), u=20, v=10)
        sph(p, sh2, 0.11, loc=(0, 0.15, 0.0), hemi=True, scale=(1.0, 0.75, 0.38), u=16, v=8)
        tube(p, sh2, [(-0.12, -0.03, 0.02), (0, -0.15, 0.03), (0.12, -0.03, 0.02)], 0.01, seg=5)  # prosoma rim
        for sx in (1, -1):
            for k in range(3):
                cyl(p, sh2, 0.013, 0.045, loc=(sx * (0.09 - k * 0.012), 0.12 + k * 0.035, 0.02), r2=0.0, rot=(0, sx * 70, 0), seg=4)
        tube(p, sh2, [(0, 0.22, 0.01), (0, 0.38, 0.02), (0, 0.5, 0.0)], [0.017, 0.011, 0.003], seg=6)  # telson
        tube(p, sh2, [(-0.05, -0.08, 0.06), (0, -0.12, 0.068), (0.05, -0.08, 0.06)], 0.006, seg=5)
        for sx in (1, -1):
            sph(p, C_EYE, 0.015, loc=(sx * 0.075, -0.05, 0.055), u=8, v=6)
    return single("SM_HorseshoeCrab", f)


@asset("nautilus", tier="small", group="specimens", res=256)
def nautilus():
    def f(p):
        spiral(p, [STRIPE_W, SHELL2], turns=2.1, a=0.02, growth=0.3, tube_k=0.62, center=(0, 0, 0), ribs=False, seg=14)
        sph(p, M("NautHood", "#9a6a4a"), 0.065, loc=(0.1, 0, -0.01), scale=(0.8, 1.0, 0.8), u=10, v=8)
        for k in range(11):  # ~90 tentacles in life; a stylized bunch here
            a = math.radians(-50 + k * 10)
            tube(p, PINK, [(0.11, 0.02 * math.sin(a * 3), -0.03), (0.22 + 0.05 * math.cos(a), 0.06 * math.sin(a) * 3, -0.05 + 0.05 * math.sin(a))], [0.013, 0.004], seg=5)
        sph(p, C_EYE, 0.014, loc=(0.1, 0.055, 0.02), u=6, v=4)
    return single("SM_Nautilus", f)


# ------------------------------------------------------------ skeletons -----
def skeleton(name, L, neck, skull_len, body_r, h, mat, tail="fluke", teeth=0.05, n_parts=8, crest=False, sclerotic=False, palate=False):
    root = empty(name)
    s = body_r / 0.5

    def vert(p, x, z, r, spine=1.0):
        cyl(p, mat, r, r * 1.05, loc=(x, 0, z), rot=(0, 90, 0), seg=10, r2=r * 0.88)
        prism(p, mat, [(-r * 0.25, 0), (r * 0.25, 0), (r * 0.38, r * 1.5 * spine), (-r * 0.12, r * 1.75 * spine)], r * 0.36, z=-r * 0.18, plane="XZ", loc=(x, 0, z + r * 0.5))
        for sy in (1, -1):
            tube(p, mat, [(x, sy * r * 0.6, z + r * 0.2), (x, sy * r * 1.45, z + r * 0.38)], [r * 0.2, r * 0.08], seg=5)

    def spine_z(x):
        return h + 0.08 * math.sin(x * 1.3)

    back_x0, back_x1 = -L * 0.18, L * 0.15
    p = Part()
    x = back_x0
    while x <= back_x1:
        vert(p, x, spine_z(x), 0.1 * s)
        x += 0.19 * s
    finish(p, "Back", root)
    p = Part()
    x = back_x0 + 0.1
    while x <= back_x1:
        z = spine_z(x)
        for sy in (1, -1):
            tube(p, mat, [(x, sy * 0.08, z), (x - 0.03, sy * body_r * 0.92, z - 0.2 * s), (x - 0.06, sy * body_r * 1.02, z - body_r * 0.9), (x - 0.08, sy * body_r * 0.55, z - body_r * 1.6)],
                 [0.042 * s, 0.036 * s, 0.03 * s, 0.015 * s], seg=7)
        x += 0.19 * s
    # gastralia (belly ribs)
    x = back_x0 + 0.2
    while x < back_x1 - 0.1:
        tube(p, mat, [(x, -body_r * 0.5, spine_z(0) - body_r * 1.58), (x + 0.04, 0, spine_z(0) - body_r * 1.68), (x, body_r * 0.5, spine_z(0) - body_r * 1.58)], 0.016 * s, seg=5)
        x += 0.24 * s
    finish(p, "Ribs", root)
    p = Part()
    nx0 = back_x1 + 0.2 * s
    k = 0
    while k * 0.16 * s < neck:
        vert(p, nx0 + k * 0.16 * s, spine_z(back_x1) + 0.12 * k * s * 0.6, 0.085 * s, spine=0.7)
        k += 1
    finish(p, "Neck", root)
    head_x = nx0 + neck + 0.05
    head_z = spine_z(back_x1) + 0.12 * k * s * 0.6
    p = Part()
    rock(p, mat, 0.3 * s, loc=(head_x + 0.15 * s, 0, head_z), scale=(1.3, 0.85, 0.75), seed=3, sub=3, rough=0.05, floor=-2)
    tube(p, mat, [(head_x + 0.2 * s, 0, head_z), (head_x + skull_len * 0.6, 0, head_z - 0.03 * s), (head_x + skull_len, 0, head_z - 0.07 * s)],
         [0.2 * s, 0.12 * s, 0.05 * s], seg=12, scale=(1.0, 0.75))
    for sy in (1, -1):
        sph(p, SOCKET, 0.1 * s, loc=(head_x + 0.25 * s, sy * 0.2 * s, head_z + 0.06 * s), u=12, v=8)
        if sclerotic:  # bony eye ring: ichthyosaurs had the biggest eyes of any vertebrate
            for a in range(10):
                c = Vector((head_x + 0.25 * s + 0.1 * s * math.cos(a / 10 * TAU), sy * 0.24 * s, head_z + 0.06 * s + 0.1 * s * math.sin(a / 10 * TAU)))
                rbox(p, mat, (0.05 * s, 0.03 * s, 0.035 * s), loc=c, rot=(0, -a * 36, 0), r=0.008 * s)
        sph(p, SOCKET, 0.032 * s, loc=(head_x + skull_len * 0.8, sy * 0.05 * s, head_z), u=8, v=6)  # nostril
    if crest:
        prism(p, mat, [(0, 0), (0.6 * s, 0), (0.2 * s, 0.24 * s)], 0.045 * s, z=-0.022 * s, plane="XZ", loc=(head_x, 0, head_z + 0.18 * s))
    tx = head_x + 0.35 * s
    while tx < head_x + skull_len * 0.95:
        for sy in (1, -1):
            cyl(p, TOOTH, teeth * 0.45, teeth * 2, loc=(tx, sy * 0.07 * s, head_z - 0.12 * s), r2=0.0, rot=(180, 0, 0), seg=5)
            if palate and tx < head_x + skull_len * 0.6:  # mosasaur pterygoid teeth (2nd row in the palate)
                cyl(p, TOOTH, teeth * 0.3, teeth * 1.2, loc=(tx + 0.05, sy * 0.03 * s, head_z - 0.1 * s), r2=0.0, rot=(180, 0, 0), seg=5)
        tx += teeth * 2.4
    finish(p, "Skull", root)
    if n_parts >= 6:
        p = Part()
        jz = head_z - 0.2 * s
        tube(p, mat, [(head_x + 0.05 * s, 0, jz + 0.04), (head_x + skull_len * 0.6, 0, jz - 0.12 * s), (head_x + skull_len * 0.92, 0, jz - 0.2 * s)],
             [0.1 * s, 0.08 * s, 0.035 * s], seg=10, scale=(1.0, 0.8))
        tx = head_x + 0.35 * s
        while tx < head_x + skull_len * 0.85:
            zz = jz + 0.04 - (tx - head_x) / skull_len * 0.24 * s
            for sy in (1, -1):
                cyl(p, TOOTH, teeth * 0.45, teeth * 2, loc=(tx, sy * 0.06 * s, zz + teeth), r2=0.0, seg=5)
            tx += teeth * 2.4
        finish(p, "Jaw", root)

    def flipper(p, x, z, size, sy):
        base = Vector((x, sy * body_r * 0.7, z - body_r * 0.5))
        tube(p, mat, [base, base + Vector((0.05, sy * 0.25 * size, -0.15 * size))], [0.065 * s, 0.05 * s], seg=8)
        r2 = base + Vector((0.05, sy * 0.25 * size, -0.15 * size))
        sph(p, mat, 0.055 * s, loc=r2, u=10, v=8)
        for d in range(5):  # digits of many small bones (hyperphalangy)
            ang = math.radians(-36 + d * 16)
            tip = r2 + Vector((math.sin(ang) * 0.72 * size, sy * math.cos(ang) * 0.72 * size, -0.22 * size))
            for i in range(1, 6):
                q0 = r2 + (tip - r2) * ((i - 1) / 5)
                q1 = r2 + (tip - r2) * (i / 5)
                sph(p, mat, 0.03 * s * (1 - i / 7), loc=q0.lerp(q1, 0.5), scale=(1.3, 1.0, 0.7), u=6, v=4)

    p = Part()
    for sy in (1, -1):
        flipper(p, back_x1 - 0.15 * s, spine_z(back_x1), 1.0 * s, sy)
    finish(p, "ForeFlipper" if n_parts >= 7 else "Flippers", root)
    if n_parts >= 7:
        p = Part()
        for sy in (1, -1):
            flipper(p, back_x0 + 0.2 * s, spine_z(back_x0), 0.75 * s, sy)
        finish(p, "HindFlipper", root)
    p = Part()
    tx0 = back_x0 - 0.2 * s
    tail_len = L / 2 + back_x0
    n = max(8, int(tail_len / (0.14 * s)))
    pts = []
    for i in range(n):
        u = i / n
        xx = tx0 - u * tail_len
        bend = max(0.0, (u - 0.72) / 0.28)  # the tailbend: spine kinks DOWN into the lower lobe
        zz = spine_z(back_x0) - (u ** 2) * 0.25 * s - (bend ** 1.5) * 0.75 * s
        vert(p, xx, zz, 0.09 * s * (1 - u * 0.6), spine=1.0 - u * 0.6)
        pts.append((xx, zz))
    lx, lz = pts[-1]
    if tail == "fluke":
        # upper lobe was soft tissue: shown as a faint keel only
        tube(p, mat, curve_pts((lx + 0.15 * s, 0, lz + 0.35 * s), (lx - 0.45 * s, 0, lz + 0.9 * s), (-0.1 * s, 0, 0), 5), [0.02 * s, 0.018 * s, 0.014 * s, 0.01 * s, 0.004], seg=5)
    else:
        tube(p, mat, [(lx + 0.4 * s, 0, lz + 0.2 * s), (lx, 0, lz + 0.5 * s), (lx - 0.25 * s, 0, lz + 0.6 * s)], [0.012 * s, 0.018 * s, 0.004], seg=5)
    finish(p, "Tail", root)
    p = Part()
    for xx in (back_x0 * 0.6, back_x1 * 0.6, head_x - 0.1):
        hz = spine_z(xx) - 0.05
        cyl(p, METAL_DK, 0.034, hz, loc=(xx, 0, hz / 2), seg=10)
        cyl(p, METAL_DK, 0.21, 0.045, loc=(xx, 0, 0.022), seg=16)
        tube(p, METAL_DK, curve_pts((xx - 0.12, 0, hz - 0.05), (xx + 0.12, 0, hz - 0.05), (0, 0, 0.1), 5), 0.016, seg=6)
    finish(p, "Mount", root)
    return root


@asset("skeleton_ichthyosaur", tier="hero", res=1024, group="skeletons", sculpt=BONE_SCULPT)
def skeleton_ichthyosaur():
    return skeleton("SkeletonIchthyosaur", L=4.2, neck=0.15, skull_len=1.15, body_r=0.42, h=1.5, mat=BONE, tail="fluke", teeth=0.028, n_parts=5, sclerotic=True)


@asset("skeleton_mosasaur", tier="hero", res=1024, group="skeletons", sculpt=BONE_SCULPT)
def skeleton_mosasaur():
    return skeleton("SkeletonMosasaur", L=4.8, neck=0.35, skull_len=1.05, body_r=0.48, h=1.55, mat=FBONE, tail="paddle", teeth=0.05, n_parts=6, palate=True)


@asset("skeleton_apex", tier="hero", res=1024, group="skeletons", sculpt=BONE_SCULPT)
def skeleton_apex():
    return skeleton("SkeletonApex", L=5.4, neck=0.5, skull_len=1.5, body_r=0.62, h=1.9, mat=APEX, tail="fluke", teeth=0.07, n_parts=8, crest=True, palate=True)
