"""Props, exhibits, attractions and tools (prop-artist + set-dressing + stylized-style).

Each buildable reads by silhouette at management-camera distance (strategy-sim):
cases are tall + glassy, food carts have big striped canopies, attractions carry a
glowing or oversized signature element. Props carry small story details (a half-
cleaned fossil on the bench, a spilled popcorn trail, a tip jar) per set-dressing.
Pivots: floor centre for furniture; held tools pivot at the grip (hand) point.
"""
import random

from tt.geo import *  # noqa
from tt.mats import *  # noqa
from tt.pipe import asset, single, finish, empty

BOUNDS = [("bounds", 0.9)]


# ------------------------------------------------------------ lab & museum --
@asset("workbench", tier="prop", group="props", col=BOUNDS)
def workbench():
    def f(p):
        rbox(p, WOOD_DK, (2.0, 1.0, 0.1), loc=(0, 0, 0.9), r=0.03)
        for x in (-0.9, 0.9):
            for y in (-0.42, 0.42):
                rbox(p, WOOD, (0.1, 0.1, 0.85), loc=(x, y, 0.43), r=0.025)
        rbox(p, WOOD, (1.8, 0.85, 0.05), loc=(0, 0, 0.25), r=0.02)
        for k in range(3):
            rbox(p, WOOD_LT, (0.5, 0.05, 0.18), loc=(-0.55 + k * 0.55, -0.45, 0.72), r=0.02)
            sph(p, BRASS, 0.022, loc=(-0.55 + k * 0.55, -0.48, 0.72), u=8, v=6)
        # specimen mid-preparation: block of matrix with a half-exposed vertebra
        rbox(p, MATRIX, (0.6, 0.45, 0.05), loc=(0, -0.05, 0.98), r=0.02)
        rock(p, MATRIX, 0.18, loc=(0, -0.05, 1.07), seed=2, sub=2)
        tube(p, FBONE, [(-0.1, -0.05, 1.1), (0.12, -0.02, 1.16)], 0.045, seg=8)
        for k in range(6):
            sph(p, MATRIX2, 0.018, loc=(0.2 + k * 0.03, -0.2 + (k % 2) * 0.04, 0.98), u=5, v=4)
        # vise
        rbox(p, METAL_DK, (0.18, 0.2, 0.14), loc=(-0.75, -0.3, 1.02), r=0.025)
        rbox(p, METAL_DK, (0.18, 0.05, 0.16), loc=(-0.75, -0.42, 1.05), r=0.012)
        cyl(p, METAL, 0.012, 0.3, loc=(-0.75, -0.48, 1.0), rot=(0, 90, 0), seg=6)
        # magnifier lamp
        cyl(p, METAL_DK, 0.1, 0.05, loc=(0.75, 0.3, 0.97), seg=14)
        tube(p, METAL_DK, [(0.75, 0.3, 0.98), (0.75, 0.3, 1.45)], 0.022, seg=8)
        tube(p, METAL_DK, [(0.75, 0.3, 1.45), (0.45, 0.15, 1.65)], 0.02, seg=8)
        sph(p, METAL_DK, 0.035, loc=(0.75, 0.3, 1.45), u=8, v=6)
        lathe(p, TEAL, [(0.0, 0.0), (0.17, 0.0), (0.17, 0.06), (0.0, 0.06)], seg=20, loc=(0.4, 0.12, 1.57), rot=(10, -25, 0))
        cyl(p, GLASS, 0.14, 0.02, loc=(0.4, 0.12, 1.555), rot=(10, -25, 0), seg=20)
        cyl(p, GLOW_WARM, 0.155, 0.01, loc=(0.4, 0.12, 1.6), rot=(10, -25, 0), seg=20)
        # brush jar, air scribe, notebook
        lathe(p, GLASS, [(0.0, 0), (0.06, 0), (0.065, 0.16), (0.0, 0.16)], seg=12, loc=(-0.6, 0.25, 0.95))
        for k in range(4):
            cyl(p, C_HANDLE, 0.012, 0.28, loc=(-0.6 + (k - 1.5) * 0.02, 0.25, 1.12), rot=(0, (k - 1.5) * 8, 0), seg=6)
            cyl(p, YELLOW, 0.016, 0.05, loc=(-0.6 + (k - 1.5) * 0.03, 0.25, 1.27), seg=6)
        cyl(p, METAL, 0.025, 0.3, loc=(-0.3, 0.3, 0.98), rot=(0, 90, 30), seg=10)
        tube(p, RUBBER, curve_pts((-0.45, 0.33, 0.97), (-0.95, 0.4, 0.3), (0, 0.15, 0.2), 6), 0.01, seg=5)
        rbox(p, TEAL, (0.25, 0.32, 0.03), loc=(0.3, 0.3, 0.97), rot=(0, 0, 15), r=0.01)
        rbox(p, PAPER, (0.22, 0.29, 0.01), loc=(0.3, 0.3, 0.99), rot=(0, 0, 15), r=0.004)
    return single("SM_Workbench", f)


@asset("curator_desk", tier="prop", group="props", col=[("box", (0, 0, 0.5), (1.7, 0.85, 1.0))])
def curator_desk():
    def f(p):
        rbox(p, WOOD_DK, (1.75, 0.88, 0.08), loc=(0, 0, 0.78), r=0.025)
        for x in (-0.6, 0.6):
            rbox(p, WOOD, (0.48, 0.82, 0.74), loc=(x, 0, 0.37), r=0.025)
            for z in (0.22, 0.48):
                rbox(p, WOOD_LT, (0.4, 0.02, 0.2), loc=(x, -0.41, z), r=0.012)
                rbox(p, BRASS, (0.1, 0.03, 0.025), loc=(x, -0.43, z), r=0.008)
        # giant open Field Guide (the claim desk)
        for sx in (-1, 1):
            rbox(p, TEAL, (0.5, 0.66, 0.05), loc=(sx * 0.24, -0.02, 0.84), rot=(0, sx * 8, 0), r=0.012)
            for k in range(4):
                rbox(p, PAPER if k % 2 else PAPER2, (0.46 - k * 0.01, 0.61, 0.012), loc=(sx * 0.235, -0.02, 0.87 + k * 0.012), rot=(0, sx * (8 - k * 1.5), 0), r=0.005)
        spiral(p, [SHELL2], turns=2.0, a=0.008, growth=0.24, tube_k=0.25, center=(-0.24, -0.08, 0.93), seg=5)
        tube(p, PAPER2, [(0.0, -0.33, 0.9), (0.05, -0.33, 0.97), (0.12, -0.33, 0.95)], 0.006, seg=5)
        lathe(p, DARK, [(0.0, 0), (0.04, 0), (0.045, 0.05), (0.02, 0.07), (0.0, 0.07)], seg=10, loc=(0.7, 0.25, 0.82))
        tube(p, TRIM, [(0.7, 0.25, 0.86), (0.72, 0.27, 1.0), (0.76, 0.31, 1.12)], [0.004, 0.012, 0.02], seg=6)
        # globe
        cyl(p, BRASS, 0.07, 0.03, loc=(-0.65, 0.25, 0.835), seg=12)
        cyl(p, BRASS, 0.012, 0.12, loc=(-0.65, 0.25, 0.9), seg=6)
        sph(p, BLUE, 0.13, loc=(-0.65, 0.25, 1.04), u=16, v=12)
        sph(p, GREEN, 0.131, loc=(-0.65, 0.25, 1.04), scale=(0.6, 0.9, 0.5), u=12, v=8)
        tube(p, BRASS, [(-0.65 + 0.15 * math.cos(a / 12 * math.pi - math.pi / 2), 0.25, 1.04 + 0.15 * math.sin(a / 12 * math.pi - math.pi / 2)) for a in range(13)], 0.008, seg=5, cap=False)
        # desk bell + chair
        lathe(p, BRASS, [(0.0, 0.0), (0.06, 0.0), (0.05, 0.05), (0.015, 0.07), (0.0, 0.08)], seg=12, loc=(0.45, -0.3, 0.82))
        rbox(p, WOOD, (0.52, 0.5, 0.06), loc=(0, 0.75, 0.48), r=0.025)
        rbox(p, CUSHION, (0.46, 0.44, 0.07), loc=(0, 0.75, 0.53), r=0.03)
        rbox(p, WOOD, (0.5, 0.06, 0.6), loc=(0, 1.0, 0.82), r=0.025)
        for x in (-0.22, 0.22):
            for y in (0.53, 0.97):
                rbox(p, WOOD_DK, (0.05, 0.05, 0.46), loc=(x, y, 0.23), r=0.012)
    return single("SM_CuratorDesk", f)


@asset("storage_crate", tier="prop", group="props", col=[("hull", None, 0.92)])
def storage_crate():
    def f(p):
        for (x, y, z, s, rz) in ((0, 0, 0.35, 0.7, 0), (0.75, 0.05, 0.3, 0.6, 8), (0.3, 0.0, 1.0, 0.6, -10)):
            rbox(p, WOOD_LT, (s, s, s), loc=(x, y, z), rot=(0, 0, rz), r=0.025)
            for dz in (-s / 2 + 0.06, s / 2 - 0.06):
                rbox(p, WOOD_DK, (s + 0.02, s + 0.02, 0.07), loc=(x, y, z + dz), rot=(0, 0, rz), r=0.018)
            rbox(p, WOOD_DK, (s * 1.3, 0.04, 0.07), loc=(x, y - s / 2 - 0.01, z), rot=(0, 45, rz), r=0.012)
            rbox(p, PAPER, (0.22, 0.01, 0.12), loc=(x + 0.12, y - s / 2 - 0.02, z + 0.12), rot=(0, 0, rz), r=0.004)
        tube(p, ROPE, curve_pts((-0.3, -0.36, 0.7), (0.3, -0.36, 0.7), (0, -0.06, -0.15), 6), 0.022, seg=6)
        rbox(p, IRON, (0.14, 0.14, 0.22), loc=(0.85, 0.0, 0.72), r=0.025)
        cyl(p, GLOW_WARM, 0.045, 0.12, loc=(0.85, 0.0, 0.72), seg=10)
        # backpack slumped against the crates ("unload here")
        rbox(p, C_PACK, (0.32, 0.2, 0.4), loc=(-0.55, -0.2, 0.2), rot=(10, 0, 20), r=0.07)
        rbox(p, CORAL, (0.2, 0.06, 0.12), loc=(-0.55, -0.32, 0.15), rot=(10, 0, 20), r=0.03)
    return single("SM_StorageCrate", f)


@asset("display_case", tier="prop", group="props", col=[("box", (0, 0, 0.9), (1.05, 1.05, 1.8))])
def display_case():
    def f(p):
        rbox(p, WOOD_DK, (1.12, 1.12, 0.12), loc=(0, 0, 0.06), r=0.035)
        rbox(p, WOOD, (0.96, 0.96, 0.8), loc=(0, 0, 0.52), r=0.03)
        for sx in (-1, 1):
            rbox(p, WOOD_LT, (0.02, 0.7, 0.55), loc=(sx * 0.48, 0, 0.52), r=0.012)
            rbox(p, WOOD_LT, (0.7, 0.02, 0.55), loc=(0, sx * 0.48, 0.52), r=0.012)
        rbox(p, TRIM, (1.06, 1.06, 0.08), loc=(0, 0, 0.94), r=0.025)
        box(p, GLASS, (0.9, 0.9, 0.75), loc=(0, 0, 1.36))
        rbox(p, BRASS, (0.98, 0.98, 0.06), loc=(0, 0, 1.75), r=0.02)
        lathe(p, BRASS, [(0.0, 0.0), (0.08, 0.0), (0.05, 0.05), (0.0, 0.1)], seg=10, loc=(0, 0, 1.78))
        for x in (-0.45, 0.45):
            for y in (-0.45, 0.45):
                rbox(p, BRASS, (0.04, 0.04, 0.78), loc=(x, y, 1.36), r=0.01)
                sph(p, BRASS, 0.035, loc=(x, y, 1.8), u=8, v=6)
        rbox(p, VELVET, (0.7, 0.7, 0.04), loc=(0, 0, 1.0), r=0.018)
        lathe(p, VELVET, [(0.0, 0.0), (0.2, 0.0), (0.15, 0.04), (0.0, 0.05)], seg=16, loc=(0, 0, 1.02))
        # angled plaque (the plaque the player fills in)
        rbox(p, BRASS, (0.44, 0.05, 0.25), loc=(0, -0.53, 0.65), rot=(-20, 0, 0), r=0.018)
        rbox(p, PAPER, (0.37, 0.01, 0.19), loc=(0, -0.555, 0.655), rot=(-20, 0, 0), r=0.006)
    return single("SM_DisplayCase", f)


@asset("mega_podium", tier="hero", res=1024, group="props", col=[("box", (0, 0, 0.6), (5.4, 3.4, 1.2))])
def mega_podium():
    def f(p):
        rbox(p, STONE2, (5.6, 3.6, 0.22), loc=(0, 0, 0.11), r=0.05)
        rbox(p, STONE, (5.3, 3.3, 0.18), loc=(0, 0, 0.3), r=0.05)
        rbox(p, TRIM, (5.4, 3.4, 0.05), loc=(0, 0, 0.39), r=0.02)
        rbox(p, STONE2, (2.0, 0.6, 0.18), loc=(0, -2.05, 0.09), r=0.035)
        # sand "excavation" bed under the skeleton
        rock(p, SAND, 2.0, loc=(0, 0, 0.38), scale=(1.2, 0.7, 0.06), seed=9, sub=3, rough=0.1, floor=0.0)
        posts = [(-2.7, -1.75), (0, -1.75), (2.7, -1.75), (2.7, 1.75), (0, 1.75), (-2.7, 1.75)]
        for (x, y) in posts:
            lathe(p, BRASS, [(0.0, 0.4), (0.13, 0.4), (0.06, 0.48), (0.045, 1.25), (0.075, 1.3), (0.0, 1.4)], seg=12, loc=(x, y, 0))
            sph(p, BRASS, 0.06, loc=(x, y, 1.42), u=8, v=6)
        for i in range(len(posts)):
            a, b = posts[i], posts[(i + 1) % len(posts)]
            tube(p, VELVET, curve_pts((a[0], a[1], 1.24), (b[0], b[1], 1.24), (0, 0, -0.2), 8), 0.035, seg=8)
        # info lectern
        rbox(p, BRASS, (0.8, 0.06, 0.4), loc=(-1.8, -2.0, 0.6), rot=(-25, 0, 0), r=0.025)
        rbox(p, PAPER, (0.7, 0.01, 0.3), loc=(-1.8, -2.03, 0.61), rot=(-25, 0, 0), r=0.006)
        rbox(p, WOOD_DK, (0.1, 0.1, 0.5), loc=(-1.8, -1.95, 0.3), r=0.018)
        # scale bar human silhouette plaque (size comparison: learn by looking)
        rbox(p, TEAL, (0.5, 0.05, 0.7), loc=(1.8, -2.0, 0.55), r=0.03)
        sph(p, CREAM, 0.05, loc=(1.8, -2.03, 0.78), u=8, v=6)
        rbox(p, CREAM, (0.06, 0.02, 0.28), loc=(1.8, -2.03, 0.58), r=0.02)
    return single("SM_MegaPodium", f)


# -------------------------------------------------------------- attractions --
@asset("aquarium", tier="hero", group="props", col=BOUNDS)
def aquarium():
    def f(p):
        rbox(p, WOOD_DK, (3.6, 1.4, 0.8), loc=(0, 0, 0.4), r=0.035)
        for k in range(3):
            rbox(p, WOOD, (1.05, 0.02, 0.6), loc=(-1.15 + k * 1.15, -0.71, 0.4), r=0.018)
            sph(p, BRASS, 0.025, loc=(-1.15 + k * 1.15, -0.73, 0.55), u=8, v=6)
        rbox(p, TRIM, (3.7, 1.5, 0.06), loc=(0, 0, 0.82), r=0.02)
        box(p, SAND, (3.4, 1.2, 0.12), loc=(0, 0, 0.91))
        box(p, WATER, (3.36, 1.16, 1.2), loc=(0, 0, 1.5))
        box(p, GLASS, (3.44, 1.24, 1.4), loc=(0, 0, 1.55))
        for x in (-1.72, 1.72):
            for y in (-0.62, 0.62):
                rbox(p, METAL_DK, (0.05, 0.05, 1.42), loc=(x, y, 1.55), r=0.012)
        rbox(p, METAL_DK, (3.5, 1.3, 0.12), loc=(0, 0, 2.3), r=0.025)
        rbox(p, GLOW_CYAN, (3.0, 0.1, 0.03), loc=(0, 0, 2.23), r=0.012)
        rock(p, ROCK, 0.25, loc=(-1.2, 0.2, 1.0), seed=1, sub=2)
        rock(p, ROCK_LT, 0.18, loc=(1.1, -0.1, 0.98), seed=2, sub=2)
        for k in range(3):  # coral
            base = Vector((0.6 + k * 0.2, 0.3, 0.97))
            for j in range(4):
                a = j * 1.6 + k
                tube(p, PINK if k % 2 else CORAL, curve_pts(base, base + Vector((0.12 * math.cos(a), 0.12 * math.sin(a), 0.3)), (0, 0, 0.04), 4), [0.032, 0.026, 0.02, 0.012], seg=6)
        for k in range(6):  # seaweed
            x = -1.5 + k * 0.55
            tube(p, LEAF_DK, [(x, 0.4, 0.97), (x + 0.05, 0.4, 1.2), (x - 0.04, 0.4, 1.45), (x + 0.03, 0.4, 1.7)], [0.045, 0.035, 0.025, 0.008], seg=5, scale=(1.0, 0.35))
        # sunken treasure chest + air stone
        rbox(p, WOOD_RED, (0.3, 0.2, 0.18), loc=(-0.5, 0.3, 1.06), rot=(0, 0, 15), r=0.03)
        rbox(p, BRASS, (0.32, 0.22, 0.03), loc=(-0.5, 0.3, 1.12), rot=(0, 0, 15), r=0.01)
        rbox(p, BRASS, (0.5, 0.05, 0.25), loc=(0, -0.72, 0.62), r=0.02)
    return single("SM_Aquarium", f)


@asset("dig_pit", tier="prop", group="props", col=[("box", (0, 0, 0.25), (3.9, 3.9, 0.5))])
def dig_pit():
    def f(p):
        for (x, y, sx, sy) in ((0, -1.85, 3.9, 0.22), (0, 1.85, 3.9, 0.22), (-1.85, 0, 0.22, 3.5), (1.85, 0, 0.22, 3.5)):
            rbox(p, WOOD, (sx, sy, 0.45), loc=(x, y, 0.225), r=0.035)
            rbox(p, WOOD_LT, (sx + 0.04, sy + 0.04, 0.06), loc=(x, y, 0.47), r=0.018)
        box(p, SAND, (3.5, 3.5, 0.3), loc=(0, 0, 0.15))
        rock(p, SAND, 0.7, loc=(0.6, 0.5, 0.3), scale=(1, 1, 0.35), seed=3, sub=2, rough=0.1, floor=0.0)
        rock(p, SAND2, 0.5, loc=(-0.7, -0.6, 0.3), scale=(1, 1, 0.3), seed=4, sub=2, rough=0.1, floor=0.0)
        for k, (mat, x, y) in enumerate(((RED, -1.1, -1.0), (BLUE, 1.2, -1.1), (YELLOW, -1.0, 1.1))):
            lathe(p, mat, [(0.0, 0.0), (0.09, 0.0), (0.13, 0.22), (0.12, 0.23), (0.0, 0.23)], seg=14, loc=(x, y, 0.3))
            tube(p, mat, [(x - 0.12, y, 0.5), (x, y, 0.62), (x + 0.12, y, 0.5)], 0.009, seg=5)
        prism(p, GREEN, [(-0.05, 0), (0.05, 0), (0.06, -0.12), (0, -0.18), (-0.06, -0.12)], 0.015, plane="XY", loc=(0.2, -0.6, 0.31))
        cyl(p, GREEN, 0.012, 0.25, loc=(0.2, -0.45, 0.33), rot=(90, 0, 0), seg=6)
        # plastic "dino bones" half buried + a toy T-rex skull
        tube(p, CREAM, [(-0.4, 0.3, 0.3), (-0.1, 0.4, 0.33)], 0.055, seg=8)
        sph(p, CREAM, 0.065, loc=(-0.42, 0.3, 0.32), u=8, v=6)
        sph(p, CREAM, 0.16, loc=(0.9, 0.9, 0.34), scale=(1.4, 0.9, 0.7), u=12, v=8)
        for k in range(4):
            cyl(p, CREAM, 0.02, 0.06, loc=(1.05 + k * 0.04, 0.85, 0.28), r2=0.0, rot=(180, 0, 0), seg=5)
        cyl(p, WOOD_DK, 0.05, 1.3, loc=(-1.85, -1.85, 0.65), seg=8)
        rbox(p, STRIPE_Y, (0.8, 0.05, 0.4), loc=(-1.85, -1.88, 1.2), r=0.035)
    return single("SM_DigPit", f)


@asset("gift_shop", tier="prop", group="props", col=BOUNDS)
def gift_shop():
    def f(p):
        rbox(p, WOOD, (3.6, 0.8, 1.0), loc=(0, -0.4, 0.5), r=0.035)
        rbox(p, WOOD_DK, (3.7, 0.9, 0.06), loc=(0, -0.4, 1.03), r=0.018)
        for k in range(4):
            rbox(p, TEAL, (0.8, 0.02, 0.7), loc=(-1.35 + k * 0.9, -0.81, 0.5), r=0.018)
        rbox(p, DARK, (0.42, 0.36, 0.25), loc=(-1.2, -0.4, 1.18), r=0.035)
        rbox(p, SCREEN, (0.3, 0.02, 0.14), loc=(-1.2, -0.58, 1.26), rot=(-15, 0, 0), r=0.012)
        for i in range(3):
            for j in range(3):
                rbox(p, TRIM, (0.06, 0.06, 0.02), loc=(-1.28 + i * 0.08, -0.5 + j * 0.06, 1.31), r=0.008)
        rbox(p, WOOD_DK, (3.6, 0.42, 2.2), loc=(0, 0.75, 1.1), r=0.035)
        for z in (0.5, 1.1, 1.7):
            rbox(p, WOOD_LT, (3.5, 0.46, 0.05), loc=(0, 0.6, z), r=0.015)
        gems = [GEM2, PINK, GREEN, ORANGE]
        for i in range(8):
            cyl(p, gems[i % 4], 0.06, 0.08, loc=(-1.5 + i * 0.42, 0.55, 1.17), r2=0.075, seg=6)
            cyl(p, gems[i % 4], 0.075, 0.12, loc=(-1.5 + i * 0.42, 0.55, 1.27), r2=0.0, seg=6)
        for i in range(6):  # plush dinos
            x = -1.4 + i * 0.55
            g = GREEN if i % 2 else PURPLE
            sph(p, g, 0.13, loc=(x, 0.55, 0.65), scale=(1.1, 0.9, 1.0), u=12, v=8)
            sph(p, g, 0.08, loc=(x + 0.08, 0.45, 0.82), u=10, v=8)
            sph(p, C_EYE, 0.013, loc=(x + 0.12, 0.38, 0.85), u=6, v=4)
        for i in range(5):  # uncracked geodes for sale
            rock(p, ROCK, 0.11, loc=(-1.3 + i * 0.6, 0.55, 1.85), seed=i, sub=2)
        # geode cracker machine
        rbox(p, RED, (0.5, 0.5, 0.5), loc=(1.25, -0.4, 1.3), r=0.05)
        rbox(p, METAL, (0.32, 0.32, 0.12), loc=(1.25, -0.4, 1.6), r=0.025)
        tube(p, METAL_DK, [(1.5, -0.4, 1.4), (1.7, -0.4, 1.7)], 0.025, seg=8)
        sph(p, DARK, 0.065, loc=(1.7, -0.4, 1.72), u=8, v=6)
        rbox(p, TRIM, (1.5, 0.06, 0.4), loc=(0, 0.95, 2.4), r=0.035)
        lathe(p, GLASS, [(0.0, 0.0), (0.07, 0.0), (0.08, 0.14), (0.0, 0.14)], seg=10, loc=(0.4, -0.5, 1.06))  # tip jar
        cyl(p, BRASS, 0.05, 0.03, loc=(0.4, -0.5, 1.08), seg=8)
    return single("SM_GiftShop", f)


@asset("holo_theater", tier="prop", group="props", col=[("box", (0, 0, 0.17), (3.4, 3.4, 0.34))])
def holo_theater():
    def f(p):
        lathe(p, METAL_DK, [(0.0, 0.0), (1.8, 0.0), (1.82, 0.2), (1.72, 0.3), (0.0, 0.3)], seg=40)
        cyl(p, DARK, 1.6, 0.04, loc=(0, 0, 0.31), seg=40)
        for r in (0.6, 1.0, 1.4):
            tube(p, GLOW_CYAN, [(r * math.cos(a / 40 * TAU), r * math.sin(a / 40 * TAU), 0.335) for a in range(41)], 0.015, seg=5, cap=False)
        tube(p, GLOW_CYAN, [(1.65 * math.cos(a / 40 * TAU), 1.65 * math.sin(a / 40 * TAU), 0.33) for a in range(41)], 0.04, seg=6, cap=False)
        for k in range(4):
            a = k * math.pi / 2 + math.pi / 4
            x, y = 1.75 * math.cos(a), 1.75 * math.sin(a)
            lathe(p, METAL, [(0.0, 0.0), (0.14, 0.0), (0.1, 0.1), (0.08, 1.5), (0.12, 1.55), (0.0, 1.6)], seg=12, loc=(x, y, 0))
            sph(p, GLOW_CYAN, 0.09, loc=(x * 0.95, y * 0.95, 1.6), u=10, v=8)
        cyl(p, HOLO, 1.2, 2.0, loc=(0, 0, 1.35), r2=0.15, seg=24)
        # control console
        rbox(p, METAL_DK, (0.6, 0.35, 0.8), loc=(0, -2.1, 0.4), r=0.04)
        rbox(p, SCREEN, (0.45, 0.02, 0.2), loc=(0, -2.28, 0.75), rot=(-30, 0, 0), r=0.01)
    return single("SM_HoloTheater", f)


def _cart(p, body_mat, stripe_mat):
    rbox(p, body_mat, (1.3, 0.8, 0.9), loc=(0, 0, 0.62), r=0.05)
    for i in range(6):
        box(p, stripe_mat, (0.12, 0.82, 0.86), loc=(-0.55 + i * 0.22, 0, 0.62))
    for x in (-0.5, 0.5):
        for y in (-0.43, 0.43):
            cyl(p, DARK, 0.18, 0.07, loc=(x, y, 0.18), rot=(90, 0, 0), seg=16)
            cyl(p, METAL, 0.06, 0.08, loc=(x, y, 0.18), rot=(90, 0, 0), seg=10)
            for k in range(6):
                a = k / 6 * math.pi
                box(p, METAL, (0.3, 0.02, 0.015), loc=(x, y * 1.0, 0.18), rot=(0, math.degrees(a), 0))
    rbox(p, WOOD_DK, (1.42, 0.92, 0.06), loc=(0, 0, 1.1), r=0.018)
    tube(p, METAL_DK, [(-0.7, -0.45, 1.0), (-0.95, -0.45, 1.05), (-0.95, 0.45, 1.05), (-0.7, 0.45, 1.0)], 0.022, seg=6)


@asset("popcorn_stand", tier="prop", group="props", col=BOUNDS)
def popcorn_stand():
    def f(p):
        _cart(p, RED, STRIPE_W)
        box(p, GLASS, (0.8, 0.6, 0.7), loc=(0, 0, 1.48))
        for x in (-0.4, 0.4):
            for y in (-0.3, 0.3):
                rbox(p, RED, (0.04, 0.04, 0.72), loc=(x, y, 1.48), r=0.012)
        rnd = random.Random(1)
        for k in range(40):
            sph(p, POPCORN, 0.045, loc=(rnd.uniform(-0.33, 0.33), rnd.uniform(-0.24, 0.24), 1.17 + rnd.uniform(0, 0.25)), u=6, v=4)
        for k in range(8):  # spilled trail (a kid was here)
            sph(p, POPCORN, 0.04, loc=(-0.3 + k * 0.12, -0.6 - (k % 3) * 0.05, 0.03), u=6, v=4)
        rbox(p, RED, (0.88, 0.68, 0.08), loc=(0, 0, 1.86), r=0.025)
        lathe(p, YELLOW, [(0.0, 0), (0.25, 0), (0.0, 0.25)], seg=12, loc=(0, 0, 1.9))
        rbox(p, YELLOW, (0.92, 0.05, 0.3), loc=(0, -0.36, 2.06), r=0.025)
        for k in range(3):  # striped bags
            lathe(p, STRIPE_R if k % 2 else STRIPE_W, [(0.0, 0.0), (0.05, 0.0), (0.07, 0.16), (0.0, 0.16)], seg=8, loc=(0.5 - k * 0.12, -0.3, 1.13))
    return single("SM_PopcornStand", f)


@asset("dinodog_stand", tier="prop", group="props", col=BOUNDS)
def dinodog_stand():
    def f(p):
        _cart(p, GREEN, STRIPE_Y)
        cyl(p, METAL_DK, 0.03, 1.4, loc=(0.4, 0.2, 1.75), seg=8)
        for k in range(10):
            a0, a1 = k / 10 * TAU, (k + 1) / 10 * TAU
            mat = STRIPE_G if k % 2 else STRIPE_Y
            prism(p, mat, [(0, 0), (0.95 * math.cos(a0), 0.95 * math.sin(a0)), (0.95 * math.cos(a1), 0.95 * math.sin(a1))], 0.03, z=0.0, loc=(0.4, 0.2, 2.42))
        lathe(p, STRIPE_G, [(0.0, 0), (0.95, 0), (0.0, 0.35)], seg=10, loc=(0.4, 0.2, 2.42))
        rbox(p, METAL_DK, (0.72, 0.42, 0.05), loc=(-0.25, -0.1, 1.15), r=0.012)
        for k in range(5):
            box(p, IRON, (0.7, 0.01, 0.01), loc=(-0.25, -0.28 + k * 0.09, 1.18))
        for k in range(3):  # dino-shaped sausages
            tube(p, WOOD_LT, [(-0.45, -0.2 + k * 0.12, 1.2), (-0.05, -0.2 + k * 0.12, 1.2)], 0.037, seg=8)
            tube(p, ORANGE, [(-0.42, -0.2 + k * 0.12, 1.22), (-0.08, -0.2 + k * 0.12, 1.22)], 0.023, seg=8)
            for j in range(3):
                cyl(p, ORANGE, 0.012, 0.03, loc=(-0.3 + j * 0.08, -0.2 + k * 0.12, 1.25), r2=0.0, seg=4)
        # ketchup + mustard bottles
        for i, m in enumerate((RED, YELLOW)):
            lathe(p, m, [(0.0, 0.0), (0.04, 0.0), (0.04, 0.14), (0.01, 0.2), (0.0, 0.2)], seg=10, loc=(0.45 + i * 0.1, -0.3, 1.13))
    return single("SM_DinoDogStand", f)


@asset("lemonade_stand", tier="prop", group="props", col=BOUNDS)
def lemonade_stand():
    def f(p):
        rbox(p, WOOD_LT, (1.4, 0.8, 1.0), loc=(0, 0, 0.5), r=0.035)
        for k in range(4):
            rbox(p, WOOD, (1.38, 0.02, 0.2), loc=(0, -0.41, 0.15 + k * 0.24), r=0.01)
        rbox(p, YELLOW, (1.2, 0.035, 0.4), loc=(0, -0.43, 0.65), r=0.035)
        for k in range(3):  # painted lemons on the sign
            sph(p, CREAM, 0.06, loc=(-0.35 + k * 0.35, -0.455, 0.65), scale=(1.3, 0.3, 1.0), u=8, v=6)
        for x in (-0.65, 0.65):
            rbox(p, WOOD_DK, (0.08, 0.08, 1.25), loc=(x, 0.3, 1.6), r=0.018)
        for i in range(7):
            rbox(p, STRIPE_Y if i % 2 == 0 else STRIPE_W, (0.22, 1.1, 0.04), loc=(-0.66 + i * 0.22, -0.05, 2.2), rot=(-15, 0, 0), r=0.012)
            sph(p, STRIPE_Y if i % 2 == 0 else STRIPE_W, 0.11, loc=(-0.66 + i * 0.22, -0.6, 2.06), scale=(1.0, 0.2, 0.5), u=10, v=6)
        lathe(p, LEMONADE, [(0.0, 0), (0.13, 0), (0.15, 0.3), (0.11, 0.35), (0.0, 0.35)], seg=16, loc=(-0.3, 0, 1.0))
        lathe(p, GLASS, [(0.0, 0), (0.14, 0), (0.16, 0.31), (0.12, 0.37), (0.0, 0.37)], seg=16, loc=(-0.3, 0, 1.0))
        tube(p, GLASS, [(-0.15, 0, 1.3), (-0.08, 0, 1.25), (-0.12, 0, 1.08)], 0.015, seg=6)
        for k in range(4):
            sph(p, YELLOW, 0.065, loc=(0.2 + k * 0.12, 0.1, 1.07), scale=(1.25, 1, 1), u=10, v=8)
        for k in range(3):
            lathe(p, GLASS, [(0.0, 0), (0.04, 0), (0.05, 0.12), (0.0, 0.12)], seg=10, loc=(0.25 + k * 0.12, -0.2, 1.0))
            cyl(p, LEMONADE, 0.04, 0.08, loc=(0.25 + k * 0.12, -0.2, 1.05), seg=10)
    return single("SM_LemonadeStand", f)


@asset("restroom", tier="prop", group="props", col=BOUNDS)
def restroom():
    def f(p):
        rbox(p, TILE, (1.7, 1.7, 2.5), loc=(0, 0, 1.25), r=0.035)
        for k in range(8):
            box(p, TILE2, (1.72, 1.72, 0.02), loc=(0, 0, 0.3 + k * 0.28))
        rbox(p, TRIM, (1.85, 1.85, 0.12), loc=(0, 0, 2.55), r=0.035)
        lathe(p, TILE2, [(0.0, 0), (1.0, 0), (0.0, 0.4)], seg=4, loc=(0, 0, 2.6), rot=(0, 0, 45))
        rbox(p, WOOD, (0.82, 0.06, 2.0), loc=(0, -0.86, 1.0), r=0.025)
        for k in range(2):
            rbox(p, WOOD_DK, (0.6, 0.02, 0.7), loc=(0, -0.9, 0.55 + k * 0.85), r=0.012)
        sph(p, BRASS, 0.04, loc=(0.3, -0.92, 1.0), u=8, v=6)
        rbox(p, TRIM, (0.5, 0.04, 0.3), loc=(0, -0.89, 2.25), r=0.025)
        sph(p, BLUE, 0.05, loc=(0, -0.92, 2.32), u=8, v=6)  # person icon
        rbox(p, BLUE, (0.06, 0.02, 0.1), loc=(0, -0.92, 2.2), r=0.02)
        cyl(p, METAL, 0.1, 0.4, loc=(0.5, 0.5, 2.9), seg=12)
        cyl(p, METAL, 0.14, 0.04, loc=(0.5, 0.5, 3.1), seg=12)
    return single("SM_Restroom", f)


# ------------------------------------------------------------------- decor --
@asset("trash_bin", tier="item", group="props", col=BOUNDS)
def trash_bin():
    def f(p):
        lathe(p, GREEN, [(0.0, 0.0), (0.26, 0.0), (0.31, 0.82), (0.0, 0.82)], seg=20)
        for z in (0.2, 0.6):
            cyl(p, LEAF_DK, 0.3 if z > 0.4 else 0.28, 0.045, loc=(0, 0, z), seg=20)
        lathe(p, METAL_DK, [(0.0, 0.82), (0.34, 0.82), (0.34, 0.9), (0.2, 0.98), (0.0, 1.0)], seg=20)
        rbox(p, DARK, (0.24, 0.05, 0.08), loc=(0, -0.24, 0.92), rot=(-30, 0, 0), r=0.02)
        for k in range(3):  # recycle arrows
            a = math.radians(90 + k * 120)
            prism(p, STRIPE_W, [(0, 0.05), (0.05, -0.03), (-0.05, -0.03)], 0.01, plane="XZ", z=-0.29, loc=(0.07 * math.cos(a), 0, 0.45 + 0.07 * math.sin(a)))
    return single("SM_TrashBin", f)


@asset("bench", tier="item", group="props",
       col=[("box", (0, 0.02, 0.26), (1.7, 0.5, 0.52)), ("box", (0, 0.27, 0.72), (1.7, 0.1, 0.4))])
def bench():
    """Park bench: slatted seat + back on two plain cast-iron side frames (no scroll
    hooks). Collision is just the seat and the backrest, so it can be jumped onto."""
    def f(p):
        for i in range(4):
            rbox(p, WOOD, (1.7, 0.11, 0.05), loc=(0, -0.18 + i * 0.12, 0.47), r=0.018)
        for i in range(3):
            rbox(p, WOOD, (1.7, 0.05, 0.11), loc=(0, 0.26 + i * 0.012, 0.62 + i * 0.14), rot=(-10, 0, 0), r=0.018)
        for x in (-0.66, 0.66):
            rbox(p, IRON, (0.06, 0.06, 0.44), loc=(x, -0.2, 0.22), r=0.015)      # front leg
            rbox(p, IRON, (0.06, 0.06, 0.92), loc=(x, 0.24, 0.46), rot=(-10, 0, 0), r=0.015)  # back leg + back post
            rbox(p, IRON, (0.06, 0.5, 0.05), loc=(x, 0.02, 0.43), r=0.015)       # seat rail
            rbox(p, IRON, (0.07, 0.42, 0.05), loc=(x, 0.0, 0.66), r=0.02)        # armrest
            rbox(p, IRON, (0.05, 0.05, 0.2), loc=(x, -0.2, 0.55), r=0.015)       # armrest post
            rbox(p, IRON, (0.14, 0.1, 0.02), loc=(x, -0.2, 0.01), r=0.008)       # feet
            rbox(p, IRON, (0.14, 0.1, 0.02), loc=(x, 0.2, 0.01), r=0.008)
        rbox(p, BRASS, (0.2, 0.02, 0.06), loc=(0, 0.25, 0.9), rot=(-10, 0, 0), r=0.01)  # memorial plaque
    return single("SM_Bench", f)


@asset("plant_pot", tier="item", group="props", col=[("box", (0, 0, 0.3), (0.7, 0.7, 0.6))])
def plant_pot():
    def f(p):
        lathe(p, TERRACOTTA, [(0.0, 0.0), (0.26, 0.0), (0.36, 0.48), (0.42, 0.5), (0.42, 0.58), (0.0, 0.58)], seg=20)
        for k in range(3):  # painted band
            cyl(p, CREAM, 0.33 + k * 0.001, 0.03, loc=(0, 0, 0.3), seg=20)
        cyl(p, SOIL, 0.36, 0.02, loc=(0, 0, 0.57), seg=20)
        rnd = random.Random(7)
        for k in range(9):  # cycad / tree-fern: a "living fossil" plant
            yaw = k * 40
            ln = rnd.uniform(0.6, 0.85)
            d = Vector((math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0))
            for j in range(1, 8):
                u = j / 8
                base = Vector((0, 0, 0.57)) + d * ln * u + Vector((0, 0, 1.3 * ln * u - 1.4 * ln * u * u))
                for side in (1, -1):
                    leaf(p, LEAF if j % 2 else LEAF_DK, base, yaw + side * 75, 0.2 * (1 - 0.5 * u), 0.045, rise=0.3, droop=0.8, segs=3, thick=0.006, fold=0.2)
        cyl(p, TRUNK2, 0.08, 0.2, loc=(0, 0, 0.66), seg=8, r2=0.06)
    return single("SM_PlantPot", f)


@asset("floor_lamp", tier="item", group="props", col=[("box", (0, 0, 0.9), (0.3, 0.3, 1.8))])
def floor_lamp():
    def f(p):
        lathe(p, BRASS, [(0.0, 0.0), (0.22, 0.0), (0.2, 0.04), (0.06, 0.08), (0.0, 0.08)], seg=18)
        cyl(p, BRASS, 0.024, 1.55, loc=(0, 0, 0.85), seg=10)
        sph(p, BRASS, 0.04, loc=(0, 0, 0.9), u=8, v=6)
        prof = []
        for i in range(9):
            r = 0.28 - i * 0.015
            prof.append((r + (0.012 if i % 2 else 0.0), 1.52 + i * 0.045))
        lathe(p, M("LampShade", "#f7e3b5", emit=0.6), [(0.0, 1.52)] + prof + [(0.0, 1.88)], seg=24)
        sph(p, GLOW_WARM, 0.08, loc=(0, 0, 1.6), u=10, v=8)
        for k in range(8):  # fringe
            a = k / 8 * TAU
            sph(p, BRASS, 0.015, loc=(0.29 * math.cos(a), 0.29 * math.sin(a), 1.49), u=5, v=4)
    return single("SM_FloorLamp", f)


@asset("banner", tier="item", group="props", col=[("box", (0, 0, 1.2), (0.3, 0.3, 2.4))])
def banner():
    def f(p):
        lathe(p, IRON, [(0.0, 0.0), (0.25, 0.0), (0.22, 0.05), (0.0, 0.05)], seg=16)
        cyl(p, IRON, 0.032, 2.4, loc=(0, 0, 1.2), seg=10)
        rbox(p, IRON, (0.95, 0.04, 0.04), loc=(0, 0, 2.35), r=0.012)
        for k in range(2):
            sph(p, BRASS, 0.045, loc=(-0.47 + k * 0.94, 0, 2.35), u=8, v=6)
        pts = [(-0.4, 0), (0.4, 0), (0.4, -1.4), (0.2, -1.5), (0.0, -1.4), (-0.2, -1.5), (-0.4, -1.4)]
        prism(p, CLOTH, pts, 0.03, plane="XZ", z=-0.045, loc=(0, 0, 2.32))
        rbox(p, YELLOW, (0.8, 0.035, 0.07), loc=(0, -0.03, 1.08), r=0.012)
        spiral(p, [STRIPE_W], turns=2.2, a=0.012, growth=0.24, tube_k=0.3, center=(0, -0.06, 1.75))
        for x in (-0.3, 0.3):  # tassels
            tube(p, YELLOW, [(x, -0.03, 0.95), (x, -0.03, 0.82)], [0.015, 0.03], seg=5)
    return single("SM_Banner", f)


@asset("rug", tier="item", group="props")
def rug():
    def f(p):
        rbox(p, VELVET, (2.4, 1.6, 0.025), loc=(0, 0, 0.0125), r=0.012, seg=1)
        rbox(p, YELLOW, (2.1, 1.3, 0.028), loc=(0, 0, 0.014), r=0.012, seg=1)
        rbox(p, TEAL, (1.95, 1.15, 0.03), loc=(0, 0, 0.015), r=0.012, seg=1)
        pts = [(0.012 * math.exp(0.2 * t) * math.cos(t), 0.012 * math.exp(0.2 * t) * math.sin(t), 0.036) for t in [i * 0.25 for i in range(66)]]
        tube(p, YELLOW, pts, [0.006 + 0.02 * i / 66 for i in range(66)], seg=5, scale=(1.0, 1.0, 0.3))
        for x in (-1.2, 1.2):
            for k in range(8):
                cyl(p, YELLOW, 0.01, 0.12, loc=(x * 1.04, -0.7 + k * 0.2, 0.01), rot=(0, 90, 0), seg=4)
    return single("SM_Rug", f)


@asset("dino_statue", tier="prop", group="props", col=BOUNDS)
def dino_statue():
    """Friendly sauropod-ish mascot: round shapes = approachable (shape language)."""
    def f(p):
        rbox(p, ROCK_LT, (1.5, 0.9, 0.3), loc=(0, 0, 0.15), r=0.06)
        rbox(p, BRASS, (0.5, 0.03, 0.16), loc=(0, -0.46, 0.15), r=0.012)
        g = M("StatueGreen", "#69b86a")
        g2 = M("StatueBelly", "#cfe8a8")
        sph(p, g, 0.42, loc=(0, 0, 0.78), scale=(1.35, 0.92, 0.82), u=20, v=14)
        sph(p, g2, 0.36, loc=(0.05, 0, 0.66), scale=(1.3, 0.85, 0.6), u=16, v=10)
        tube(p, g, [(0.35, 0, 0.88), (0.55, 0, 1.3), (0.62, 0, 1.72), (0.78, 0, 1.86)], [0.17, 0.13, 0.1, 0.09], seg=14)
        sph(p, g, 0.17, loc=(0.82, 0, 1.9), scale=(1.4, 1.0, 0.9), u=16, v=12)
        for sy in (1, -1):
            sph(p, C_WHITE, 0.04, loc=(0.9, sy * 0.09, 1.96), u=10, v=8)
            sph(p, C_EYE, 0.022, loc=(0.93, sy * 0.1, 1.96), u=8, v=6)
            sph(p, C_BLUSH, 0.03, loc=(0.92, sy * 0.13, 1.88), scale=(1, 0.4, 0.7), u=8, v=6)
        for k in range(5):
            cyl(p, ORANGE, 0.05, 0.1, loc=(0.15 - k * 0.22, 0, 1.12 - k * 0.04), r2=0.0, seg=6)
        tube(p, C_MOUTH, [(1.0, -0.05, 1.86), (1.03, 0, 1.84), (1.0, 0.05, 1.86)], 0.012, seg=5)
        tube(p, g, [(-0.42, 0, 0.78), (-0.85, 0, 0.6), (-1.15, 0.12, 0.42)], [0.2, 0.11, 0.03], seg=12)
        for (x, y) in ((0.25, 0.24), (0.25, -0.24), (-0.25, 0.24), (-0.25, -0.24)):
            cyl(p, g, 0.11, 0.46, loc=(x, y, 0.5), seg=12)
            sph(p, g2, 0.06, loc=(x, y - 0.0, 0.3), scale=(1.2, 1.2, 0.4), u=8, v=6)
    return single("SM_DinoStatue", f, subsurf=1)


# ---------------------------------------------------------- floor litter ----
@asset("trash", tier="small", group="props", res=256)
def trash():
    def f(p):
        lathe(p, STRIPE_W, [(0.0, 0.0), (0.045, 0.0), (0.065, 0.15), (0.0, 0.15)], seg=12, loc=(0, 0, 0.06), rot=(80, 0, 20))
        rbox(p, STRIPE_R, (0.1, 0.03, 0.05), loc=(0.02, -0.03, 0.06), rot=(80, 0, 20), r=0.012)
        cyl(p, TRIM, 0.068, 0.012, loc=(-0.03, 0.12, 0.08), rot=(80, 0, 20), seg=12)
        tube(p, RED, [(-0.02, 0.1, 0.08), (-0.04, 0.2, 0.1)], 0.006, seg=5)
        rock(p, PAPER, 0.06, loc=(0.14, 0.09, 0.04), scale=(1.2, 1, 0.6), seed=3, sub=1, rough=0.4)
        for k in range(4):
            sph(p, POPCORN, 0.025, loc=(-0.12 + k * 0.05, -0.12, 0.02), u=5, v=4)
    return single("SM_Trash", f, smooth=40)


@asset("sand_pile", tier="small", group="props", res=256)
def sand_pile():
    def f(p):
        rock(p, SAND, 0.36, loc=(0, 0, 0), scale=(1.3, 1, 0.25), seed=31, sub=2, rough=0.2, floor=0.0)
        for k in range(5):
            sph(p, SAND2, 0.04, loc=(0.4 * math.cos(k * 1.3), 0.3 * math.sin(k * 1.3), 0.01), scale=(1, 1, 0.4), u=6, v=4)
    return single("SM_SandPile", f, smooth=50)


@asset("plushie", tier="item", group="props", res=256)
def plushie():
    def f(p):
        g, b = M("Plush", "#7ac56b"), M("PlushBelly", "#e8f2c0")
        sph(p, g, 0.12, loc=(0, 0, 0.12), scale=(1.2, 0.95, 1.0), u=16, v=12)
        sph(p, b, 0.09, loc=(0.06, 0, 0.1), scale=(1.0, 0.85, 1.0), u=12, v=8)
        sph(p, g, 0.085, loc=(0.13, 0, 0.26), u=16, v=12)
        for sy in (1, -1):
            sph(p, C_EYE, 0.017, loc=(0.2, sy * 0.04, 0.29), u=8, v=6)
            sph(p, g, 0.04, loc=(0.0, sy * 0.1, 0.03), u=8, v=6)
        for k in range(3):
            cyl(p, YELLOW, 0.026, 0.055, loc=(-0.02 - k * 0.07, 0, 0.24 - k * 0.025), r2=0.003, seg=6)
        tube(p, g, [(-0.12, 0, 0.1), (-0.2, 0, 0.07), (-0.26, 0.03, 0.04)], [0.05, 0.03, 0.01], seg=8)
    return single("SM_Plushie", f, subsurf=1)


# ------------------------------------------------------------------- tools --
# Pivot = the hand: the tool hangs down -Z from the grip (matches hold_tool + GripR/L).
@asset("shovel", tier="item", group="tools", res=256)
def shovel():
    def f(p):
        cyl(p, C_HANDLE, 0.022, 0.92, loc=(0, 0, -0.42), seg=12)
        tube(p, C_GRIP, [(-0.07, 0, 0.04), (-0.07, 0, 0.11), (0.07, 0, 0.11), (0.07, 0, 0.04)], 0.017, seg=8)
        cyl(p, C_GRIP, 0.025, 0.07, loc=(0, 0, 0.05), seg=12)
        cyl(p, C_BLADE, 0.031, 0.16, loc=(0, 0, -0.9), seg=12, r2=0.025)
        for z in (-0.86, -0.94):
            sph(p, METAL_DK, 0.009, loc=(0, -0.03, z), u=6, v=4)
        t = [(-0.13, 0), (0.13, 0), (0.13, -0.2), (0.0, -0.33), (-0.13, -0.2)]
        prism(p, C_BLADE, t, 0.022, z=-0.011, plane="XZ", loc=(0, 0.0, -0.98), rot=(8, 0, 0))
        rbox(p, C_BLADE, (0.27, 0.04, 0.03), loc=(0, -0.012, -0.985), r=0.012)
        for k in range(3):  # wrap tape on the handle
            cyl(p, CORAL, 0.025, 0.03, loc=(0, 0, -0.15 - k * 0.05), seg=12)
    return single("SM_Shovel", f, bevel=0.004)


@asset("pickaxe", tier="item", group="tools", res=256)
def pickaxe():
    def f(p):
        cyl(p, C_HANDLE, 0.024, 0.86, loc=(0, 0, -0.38), seg=12)
        cyl(p, C_GRIP, 0.028, 0.2, loc=(0, 0, -0.05), seg=12)
        rbox(p, C_BLADE, (0.075, 0.11, 0.095), loc=(0, 0, -0.83), r=0.018)
        tube(p, C_BLADE, curve_pts((0, -0.04, -0.83), (0, -0.37, -0.9), (0, 0, 0.05), 6), [0.044, 0.04, 0.034, 0.025, 0.015, 0.004], seg=8)
        tube(p, C_BLADE, curve_pts((0, 0.04, -0.83), (0, 0.33, -0.88), (0, 0, 0.04), 6), [0.044, 0.042, 0.038, 0.034, 0.031, 0.027], seg=8, scale=(1.5, 0.7))
        rbox(p, METAL_DK, (0.055, 0.115, 0.03), loc=(0, 0, -0.785), r=0.01)
    return single("SM_Pickaxe", f, bevel=0.004)


@asset("detector", tier="item", group="tools", res=256)
def detector():
    def f(p):
        cyl(p, METAL_DK, 0.018, 0.95, loc=(0, 0, -0.45), seg=10)
        rbox(p, C_HANDLE, (0.095, 0.115, 0.135), loc=(0, -0.05, -0.13), r=0.03)
        rbox(p, SCREEN, (0.068, 0.01, 0.062), loc=(0, -0.108, -0.115), r=0.01)
        for i, c in enumerate((RED, YELLOW)):
            cyl(p, c, 0.013, 0.02, loc=(-0.02 + i * 0.04, -0.108, -0.175), rot=(90, 0, 0), seg=10)
        tube(p, C_GRIP, [(0, 0.04, 0.03), (0, 0.09, -0.02), (0, 0.09, -0.1)], 0.021, seg=8)
        lathe(p, C_BLADE, [(0.0, 0.0), (0.15, 0.0), (0.157, 0.016), (0.14, 0.032), (0.0, 0.032)], seg=24, loc=(0, -0.06, -0.97), rot=(12, 0, 0))
        cyl(p, SCREEN, 0.06, 0.037, loc=(0, -0.06, -0.955), rot=(12, 0, 0), seg=18)
        tube(p, C_GRIP, [(0, 0.0, -0.6), (0, -0.04, -0.8), (0, -0.06, -0.94)], 0.009, seg=6)
        sph(p, GLOW_RED, 0.012, loc=(0.03, -0.11, -0.07), u=6, v=4)
    return single("SM_Detector", f, bevel=0.003)


@asset("broom", tier="item", group="tools", res=256)
def broom():
    def f(p):
        cyl(p, WOOD_LT, 0.02, 1.12, loc=(0, 0, -0.5), seg=10)
        rbox(p, RED, (0.3, 0.085, 0.065), loc=(0, 0, -1.05), r=0.025)
        for i in range(14):
            x = -0.13 + i * 0.02
            cyl(p, YELLOW, 0.013, 0.21, loc=(x, 0, -1.18), r2=0.008, rot=(0, (i - 7) * 1.5, 0), seg=6)
        cyl(p, CORAL, 0.026, 0.06, loc=(0, 0, 0.0), seg=10)
    return single("SM_Broom", f)


# ----------------------------------------------------------- stand service --
# Held serving props for the concession minigame (grab -> fill -> serve).
# Pivot at the hand. The "Fill" child is hidden until the cup/bag is filled.
@asset("held_cup", tier="small", group="props", res=256)
def held_cup():
    root = empty("HeldCup")
    p = Part()
    lathe(p, GLASS, [(0.0, 0.0), (0.04, 0.0), (0.05, 0.13), (0.052, 0.135), (0.0, 0.135)], seg=14, loc=(0, 0, -0.06), close_top=False)
    rbox(p, YELLOW, (0.004, 0.06, 0.03), loc=(0.05, 0, 0.0), r=0.002)
    tube(p, STRIPE_R, [(0.015, 0, 0.0), (0.03, 0, 0.12)], 0.005, seg=5)
    finish(p, "Cup", root)
    f = Part()
    lathe(f, LEMONADE, [(0.0, 0.0), (0.037, 0.0), (0.046, 0.11), (0.0, 0.11)], seg=14, loc=(0, 0, -0.055))
    sph(f, YELLOW, 0.022, loc=(0.025, 0.0, 0.06), scale=(1.0, 0.35, 1.0), u=8, v=6)
    finish(f, "Fill", root)
    return root


@asset("held_bag", tier="small", group="props", res=256)
def held_bag():
    root = empty("HeldBag")
    p = Part()
    lathe(p, STRIPE_R, [(0.0, 0.0), (0.04, 0.0), (0.055, 0.16), (0.0, 0.16)], seg=8, loc=(0, 0, -0.08), close_top=False)
    for k in range(4):
        rbox(p, STRIPE_W, (0.012, 0.004, 0.15), loc=(0.047 * math.cos(k * 1.57), 0.047 * math.sin(k * 1.57), 0.0), rot=(0, 0, math.degrees(k * 1.57) + 90), r=0.002)
    finish(p, "Bag", root)
    f = Part()
    rnd = random.Random(4)
    for k in range(14):
        sph(f, POPCORN, 0.022, loc=(rnd.uniform(-0.035, 0.035), rnd.uniform(-0.035, 0.035), 0.07 + rnd.uniform(0, 0.04)), u=6, v=4)
    finish(f, "Fill", root)
    return root


@asset("held_dog", tier="small", group="props", res=256)
def held_dog():
    root = empty("HeldDog")
    p = Part()
    rbox(p, PAPER, (0.2, 0.08, 0.012), loc=(0, 0, -0.03), r=0.004)
    for sy in (-1, 1):
        sph(p, WOOD_LT, 0.035, loc=(0, sy * 0.022, 0.0), scale=(2.6, 0.7, 0.8), u=12, v=8)
    finish(p, "Bun", root)
    f = Part()
    tube(f, ORANGE, [(-0.1, 0, 0.012), (0.1, 0, 0.012)], 0.02, seg=8)
    for j in range(3):
        cyl(f, ORANGE, 0.009, 0.025, loc=(-0.04 + j * 0.04, 0, 0.035), r2=0.0, seg=4)
    tube(f, YELLOW, [(-0.08, 0, 0.034), (-0.02, 0.006, 0.036), (0.04, -0.006, 0.036), (0.08, 0, 0.034)], 0.005, seg=4)
    finish(f, "Fill", root)
    return root


# ------------------------------------------------------------ tool station --
@asset("tool_station", tier="prop", group="props", col=[("box", (0, 0.1, 1.0), (1.8, 0.5, 2.0))])
def tool_station():
    """Gear locker: a pegboard rack with outlines for every tool. Walk up to it to
    re-equip any tool you own (lost or dropped ones are re-issued)."""
    def f(p):
        rbox(p, WOOD_DK, (1.8, 0.45, 0.1), loc=(0, 0.1, 0.05), r=0.02)
        for x in (-0.85, 0.85):
            rbox(p, WOOD_DK, (0.1, 0.12, 2.0), loc=(x, 0.25, 1.0), r=0.02)
        rbox(p, WOOD_LT, (1.6, 0.05, 1.5), loc=(0, 0.27, 1.15), r=0.02)
        rbox(p, TEAL, (1.8, 0.16, 0.3), loc=(0, 0.22, 2.06), r=0.03)
        text3d(p, CREAM, "GEAR", size=0.16, loc=(0, 0.138, 2.06), depth=0.008, max_w=1.2, max_h=0.2)
        # painted tool silhouettes + hooks
        for k, x in enumerate((-0.5, 0.0, 0.5)):
            sph(p, METAL_DK, 0.02, loc=(x, 0.23, 1.75), u=6, v=4)
            rbox(p, DARK, (0.04, 0.005, 0.9), loc=(x, 0.243, 1.25), r=0.01)
            if k == 0:
                prism(p, DARK, [(-0.12, 0), (0.12, 0), (0.12, -0.18), (0.0, -0.3), (-0.12, -0.18)], 0.005, plane="XZ", z=-0.002, loc=(x, 0.243, 0.8))
            elif k == 1:
                rbox(p, DARK, (0.5, 0.005, 0.07), loc=(x, 0.243, 0.82), r=0.02)
            else:
                cyl(p, DARK, 0.13, 0.005, loc=(x, 0.243, 0.72), rot=(90, 0, 0), seg=16)
        # a little shelf with a spare brush and a lamp
        rbox(p, WOOD, (1.6, 0.3, 0.05), loc=(0, 0.1, 0.4), r=0.015)
        lathe(p, TEAL, [(0.0, 0.0), (0.12, 0.0), (0.14, 0.28), (0.0, 0.28)], seg=12, loc=(-0.55, 0.1, 0.43))
        cyl(p, C_HANDLE, 0.012, 0.25, loc=(0.4, 0.1, 0.45), rot=(0, 90, 0), seg=6)
    return single("SM_ToolStation", f)


# ------------------------------------------------------------ plaque check --
@asset("plaque_checker", tier="prop", group="props", col=[("box", (0, 0, 0.75), (0.9, 0.7, 1.5))])
def plaque_checker():
    """Curator's Fact-Check Kiosk: a lectern with a brass magnifier and a light that
    flags exhibits with wrong plaques. Cheap and available on day one."""
    def f(p):
        rbox(p, WOOD_DK, (0.8, 0.6, 0.08), loc=(0, 0, 0.04), r=0.02)
        rbox(p, WOOD, (0.5, 0.4, 1.0), loc=(0, 0, 0.58), r=0.03)
        for k in range(3):
            rbox(p, WOOD_LT, (0.42, 0.02, 0.24), loc=(0, -0.205, 0.3 + k * 0.3), r=0.01)
        rbox(p, WOOD_DK, (0.8, 0.62, 0.06), loc=(0, -0.05, 1.18), rot=(-20, 0, 0), r=0.02)
        rbox(p, PAPER, (0.62, 0.42, 0.012), loc=(0, -0.06, 1.215), rot=(-20, 0, 0), r=0.006)
        for k in range(4):
            rbox(p, INK, (0.4 - k * 0.05, 0.02, 0.008), loc=(0, -0.13 + k * 0.06, 1.2 + k * 0.021), rot=(-20, 0, 0), r=0.002)
        tube(p, BRASS, [(0.3, 0.15, 1.25), (0.3, 0.15, 1.55), (0.15, 0.0, 1.65)], 0.015, seg=6)
        lathe(p, BRASS, [(0.0, 0.0), (0.1, 0.0), (0.1, 0.025), (0.0, 0.025)], seg=16, loc=(0.1, -0.05, 1.6), rot=(70, 0, 0))
        cyl(p, GLASS, 0.085, 0.02, loc=(0.1, -0.05, 1.6), rot=(70, 0, 0), seg=16)
        # status lamp (Godot recolours the "Lamp" tint: green = all correct, red = a wrong plaque)
        cyl(p, BRASS, 0.07, 0.06, loc=(-0.28, 0.18, 1.27), seg=12)
        sph(p, LAMP_TINT, 0.07, loc=(-0.28, 0.18, 1.34), u=12, v=8)
        text3d(p, CREAM, "FACT CHECK", size=0.06, loc=(0, -0.211, 0.92), depth=0.003, max_w=0.42)
    return single("SM_PlaqueChecker", f)
