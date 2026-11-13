"""VFX particle meshes (vfx-fx) + set-dressing clusters (set-dressing, scene-assembly).

FX: tiny stylized meshes the game instances through GPU/CPU particles - sand puff,
rock chips, sparkle star, water droplet, confetti, dust motes. Emissive where they
should glow; all low tri.

Dressing clusters: narrative groupings placed as one asset each (one draw call per
cluster after the material collapse). Each tells a small story about the bay:
a family beach camp, a tide-pool study spot with a field notebook, a beached
rowboat with lobster pots, a lifeguard chair, a zone signpost, a dig-site camp.
"""
import random

from tt.geo import *  # noqa
from tt.mats import *  # noqa
from tt.pipe import asset, single, finish, empty

GLOW_GEM = M("GlowGem", "#bff6ff", emit=2.5)
GLOW_GOLD = M("GlowGold", "#ffe08a", emit=2.5)


# --------------------------------------------------------------------- fx ---
@asset("fx_puff", tier="small", group="fx", res=128)
def fx_puff():
    def f(p):
        for k, (x, y, z, r) in enumerate(((0, 0, 0, 0.12), (0.09, 0.02, 0.03, 0.08), (-0.08, 0.03, 0.02, 0.085), (0.0, -0.06, 0.06, 0.07))):
            sph(p, SAND2, r, loc=(x, y, z), u=10, v=6)
    return single("SM_FxPuff", f, smooth=60)


@asset("fx_chip", tier="small", group="fx", res=128)
def fx_chip():
    return single("SM_FxChip", lambda p: rock(p, ROCK, 0.05, scale=(1.2, 0.8, 0.5), seed=4, sub=1, rough=0.5), smooth=20)


@asset("fx_sparkle", tier="small", group="fx", paint=False)
def fx_sparkle():
    def f(p):
        prism(p, GLOW_GOLD, star_path(0, 0, 0.12, 0.04, n=4), 0.01, plane="XZ", z=-0.005)
    return single("SM_FxSparkle", f, smooth=5)


@asset("fx_gem_glint", tier="small", group="fx", paint=False)
def fx_gem_glint():
    def f(p):
        prism(p, GLOW_GEM, star_path(0, 0, 0.1, 0.025, n=4), 0.008, plane="XZ", z=-0.004)
    return single("SM_FxGemGlint", f, smooth=5)


@asset("fx_droplet", tier="small", group="fx", paint=False)
def fx_droplet():
    def f(p):
        lathe(p, WATER, [(0.0, 0.0), (0.03, 0.015), (0.025, 0.05), (0.0, 0.08)], seg=8)
    return single("SM_FxDroplet", f)


@asset("fx_confetti", tier="small", group="fx", paint=False)
def fx_confetti():
    def f(p):
        for k, m in enumerate((CORAL, YELLOW, TEAL, PINK)):
            box(p, m, (0.05, 0.004, 0.03), loc=(k * 0.07, 0, 0), rot=(k * 30, k * 45, 0))
    return single("SM_FxConfetti", f, smooth=5)


@asset("fx_dust", tier="small", group="fx", res=128)
def fx_dust():
    return single("SM_FxDust", lambda p: sph(p, CREAM, 0.04, u=8, v=6), smooth=60)


# ---------------------------------------------------------------- dressing --
@asset("dress_beach_camp", tier="prop", group="dress", col=[("box", (0, 0.6, 0.15), (1.6, 0.9, 0.3))])
def dress_beach_camp():
    """A family's spot: striped umbrella, towel, cooler, bucket & spade, sandcastle."""
    def f(p):
        cyl(p, WOOD_LT, 0.025, 2.2, loc=(0, 0, 1.0), rot=(8, 0, 0), seg=8)
        for k in range(8):
            a0, a1 = k / 8 * TAU, (k + 1) / 8 * TAU
            prism(p, STRIPE_R if k % 2 else STRIPE_W, [(0, 0), (1.1 * math.cos(a0), 1.1 * math.sin(a0)), (1.1 * math.cos(a1), 1.1 * math.sin(a1))], 0.02, z=0.0,
                  loc=(0, -0.3, 2.05), rot=(8, 0, 0))
        lathe(p, STRIPE_R, [(0.0, 0.0), (1.1, 0.0), (0.0, 0.25)], seg=8, loc=(0, -0.3, 2.07), rot=(8, 0, 22.5))
        rbox(p, TEAL, (0.8, 1.6, 0.02), loc=(0.6, 0.5, 0.01), rot=(0, 0, 12), r=0.01, seg=1)
        for k in range(4):
            rbox(p, STRIPE_Y, (0.8, 0.12, 0.022), loc=(0.6 + 0.04 * k, 0.0 + k * 0.35, 0.012), rot=(0, 0, 12), r=0.005, seg=1)
        rbox(p, BLUE, (0.5, 0.32, 0.32), loc=(-0.7, 0.6, 0.16), r=0.05)
        rbox(p, TRIM, (0.52, 0.34, 0.06), loc=(-0.7, 0.6, 0.33), r=0.03)
        lathe(p, YELLOW, [(0.0, 0.0), (0.1, 0.0), (0.13, 0.18), (0.0, 0.18)], seg=12, loc=(-0.6, -0.4, 0))
        tube(p, YELLOW, [(-0.72, -0.4, 0.2), (-0.6, -0.4, 0.28), (-0.48, -0.4, 0.2)], 0.008, seg=4)
        cyl(p, RED, 0.012, 0.35, loc=(-0.35, -0.5, 0.15), rot=(30, 0, 0), seg=6)
        prism(p, RED, [(-0.05, 0), (0.05, 0), (0.05, -0.08), (0, -0.12), (-0.05, -0.08)], 0.01, plane="XZ", loc=(-0.35, -0.6, 0.0))
        # sandcastle with a shell flag
        for (x, y, r, h) in ((1.4, -0.6, 0.18, 0.25), (1.62, -0.45, 0.1, 0.32), (1.2, -0.42, 0.1, 0.3), (1.45, -0.85, 0.1, 0.28)):
            lathe(p, SAND2, [(0.0, 0.0), (r, 0.0), (r * 0.85, h), (0.0, h)], seg=10, loc=(x, y, 0))
        cyl(p, WOOD_LT, 0.006, 0.25, loc=(1.62, -0.45, 0.45), seg=4)
        prism(p, PINK, [(0, 0), (0.1, -0.03), (0, -0.06)], 0.004, plane="XZ", loc=(1.62, -0.45, 0.57))
    return single("SM_DressBeachCamp", f)


@asset("dress_tidepool", tier="prop", group="dress")
def dress_tidepool():
    """Rock-ringed pool with starfish, anemones, and a dropped field notebook + magnifier."""
    def f(p):
        rnd = random.Random(3)
        for k in range(11):
            a = k / 11 * TAU
            rock(p, ROCK if k % 3 else ROCK_DK, rnd.uniform(0.2, 0.35), loc=(1.0 * math.cos(a), 0.7 * math.sin(a), 0.08), scale=(1.2, 1, 0.6), seed=k, sub=2)
        cyl(p, WATER, 0.95, 0.04, loc=(0, 0, 0.05), seg=24, scale=(1.0, 0.7, 1.0))
        cyl(p, SAND_WET, 0.95, 0.03, loc=(0, 0, 0.0), seg=24, scale=(1.0, 0.7, 1.0))
        for k in range(5):
            a = math.radians(90 + k * 72)
            tube(p, CORAL, [(0.2, 0.1, 0.035), (0.2 + 0.12 * math.cos(a), 0.1 + 0.12 * math.sin(a), 0.03)], [0.035, 0.012], seg=5)
        for (x, y) in ((-0.3, -0.15), (-0.45, 0.2), (0.45, -0.2)):
            cyl(p, PINK, 0.05, 0.05, loc=(x, y, 0.04), seg=8)
            for j in range(6):
                a = j / 6 * TAU
                tube(p, PINK, [(x, y, 0.06), (x + 0.05 * math.cos(a), y + 0.05 * math.sin(a), 0.1)], [0.012, 0.004], seg=4)
        rbox(p, TEAL, (0.22, 0.3, 0.03), loc=(1.4, -0.5, 0.06), rot=(0, 8, 25), r=0.01)
        rbox(p, PAPER, (0.2, 0.28, 0.012), loc=(1.4, -0.5, 0.08), rot=(0, 8, 25), r=0.004)
        cyl(p, BRASS, 0.06, 0.012, loc=(1.15, -0.75, 0.03), seg=12)
        cyl(p, GLASS, 0.05, 0.013, loc=(1.15, -0.75, 0.032), seg=12)
        cyl(p, C_HANDLE, 0.012, 0.12, loc=(1.06, -0.84, 0.03), rot=(90, 0, 45), seg=6)
    return single("SM_DressTidepool", f)


@asset("dress_rowboat", tier="prop", group="dress", col=[("box", (0, 0, 0.3), (3.2, 1.2, 0.6))])
def dress_rowboat():
    """Beached rowboat, oars, lobster pots and a coil of rope: the bay's fishing life."""
    def f(p):
        sph(p, TEAL, 1.0, loc=(0, 0, 0.55), rot=(180, 0, 0), scale=(1.5, 0.62, 0.55), u=20, v=12, hemi=True)  # hull (bowl)
        cyl(p, WOOD_DK, 1.0, 0.03, loc=(0, 0, 0.5), seg=20, scale=(1.42, 0.56, 1.0))  # floorboards inside
        tube(p, TRIM, [(1.5 * math.cos(a / 20 * TAU), 0.62 * math.sin(a / 20 * TAU), 0.56) for a in range(21)], 0.03, seg=5, cap=False)  # gunwale
        for x in (-0.5, 0.4):
            rbox(p, WOOD, (0.18, 1.05, 0.05), loc=(x, 0, 0.42), r=0.012)
        rbox(p, CORAL, (0.06, 1.1, 0.1), loc=(1.35, 0, 0.42), rot=(0, 30, 0), r=0.02)  # bow stripe
        for sy in (1, -1):
            tube(p, WOOD_LT, [(-1.0, sy * 0.75, 0.05), (0.8, sy * 0.85, 0.05)], 0.025, seg=6)
            rbox(p, WOOD_LT, (0.4, 0.14, 0.02), loc=(0.95, sy * 0.86, 0.05), r=0.01)
        for k, x in enumerate((2.0, 2.45)):
            rbox(p, WOOD_DK, (0.45, 0.35, 0.03), loc=(x, 0.3, 0.015), r=0.01)
            for j in range(4):
                tube(p, WOOD_LT, [(x - 0.2, 0.3 - 0.15 + j * 0.1, 0.03), (x - 0.2, 0.3 - 0.15 + j * 0.1, 0.25), (x + 0.2, 0.3 - 0.15 + j * 0.1, 0.25), (x + 0.2, 0.3 - 0.15 + j * 0.1, 0.03)], 0.012, seg=4, cap=False)
            rbox(p, ROPE, (0.42, 0.33, 0.01), loc=(x, 0.3, 0.2), r=0.005)
        for k in range(4):
            tube(p, ROPE, [(1.9 + 0.2 * math.cos(a / 12 * TAU), -0.5 + 0.2 * math.sin(a / 12 * TAU), 0.02 + k * 0.03) for a in range(13)], 0.02, seg=5, cap=False)
        sph(p, CORAL, 0.12, loc=(2.3, -0.3, 0.12), u=10, v=8)  # buoy
        sph(p, STRIPE_W, 0.121, loc=(2.3, -0.3, 0.12), scale=(1, 1, 0.3), u=10, v=6)
    return single("SM_DressRowboat", f)


@asset("dress_lifeguard", tier="prop", group="dress", col=[("box", (0, 0, 1.2), (1.2, 1.2, 2.4))])
def dress_lifeguard():
    def f(p):
        for sx in (-1, 1):
            for sy in (-1, 1):
                tube(p, TRIM, [(sx * 0.55, sy * 0.55, 0.0), (sx * 0.4, sy * 0.4, 1.6)], 0.05, seg=8)
        for z in (0.5, 1.0):
            for sy in (-1, 1):
                rbox(p, TRIM, (1.0, 0.05, 0.06), loc=(0, sy * 0.48 - (z - 0.5) * 0.08 * sy, z), r=0.012)
        for k in range(5):
            rbox(p, WOOD, (0.7, 0.12, 0.03), loc=(0, -0.62 + k * 0.0, 0.25 + k * 0.28), rot=(-25, 0, 0), r=0.01)
        rbox(p, WOOD, (0.9, 0.9, 0.08), loc=(0, 0, 1.62), r=0.02)
        rbox(p, RED, (0.85, 0.08, 0.6), loc=(0, 0.42, 1.95), r=0.03)
        rbox(p, RED, (0.08, 0.85, 0.3), loc=(0.42, 0, 1.8), r=0.02)
        rbox(p, RED, (0.08, 0.85, 0.3), loc=(-0.42, 0, 1.8), r=0.02)
        cyl(p, WOOD_LT, 0.025, 1.3, loc=(0.35, 0.35, 2.2), seg=6)
        lathe(p, STRIPE_Y, [(0.0, 0.0), (0.6, 0.0), (0.0, 0.2)], seg=8, loc=(0.35, 0.35, 2.82))
        lathe(p, CORAL, [(0.12, -0.03), (0.2, -0.03), (0.2, 0.03), (0.12, 0.03)], seg=16, loc=(0.0, -0.47, 1.95), rot=(90, 0, 0))  # life ring
    return single("SM_DressLifeguard", f)


@asset("dress_signpost", tier="item", group="dress", col=[("box", (0, 0, 1.1), (0.2, 0.2, 2.2))])
def dress_signpost():
    """Finger-post signs pointing to the zones (wayfinding, strategy-sim readability)."""
    def f(p):
        cyl(p, WOOD_DK, 0.06, 2.4, loc=(0, 0, 1.2), seg=8)
        sph(p, WOOD_DK, 0.08, loc=(0, 0, 2.42), u=8, v=6)
        for k, (yaw, m) in enumerate(((10, CORAL), (100, TEAL), (200, YELLOW), (300, GREEN))):
            a = math.radians(yaw)
            c = Vector((0.35 * math.cos(a), 0.35 * math.sin(a), 2.15 - k * 0.3))
            prism(p, m, [(-0.35, 0.09), (0.25, 0.09), (0.37, 0.0), (0.25, -0.09), (-0.35, -0.09)], 0.04, plane="XZ", z=-0.02, loc=c, rot=(0, 0, yaw))
            rbox(p, CREAM, (0.36, 0.045, 0.05), loc=c - Vector((0.03 * math.cos(a), 0.03 * math.sin(a), 0)), rot=(0, 0, yaw), r=0.01)
        rock(p, STONE2, 0.18, loc=(0, 0, 0.05), scale=(1.3, 1.3, 0.5), seed=4, sub=2)
    return single("SM_DressSignpost", f)


@asset("dress_dig_camp", tier="prop", group="dress", col=[("box", (0, 0.5, 0.75), (1.6, 1.2, 1.5))])
def dress_dig_camp():
    """Field paleontologist's camp: canvas tent, sieve, plaster-jacketed find, grid stakes."""
    def f(p):
        prism(p, SAND2, [(-0.8, 0), (0.8, 0), (0, 1.3)], 1.4, plane="XZ", z=-0.2, loc=(0, 0.5, 0))
        prism(p, DRIFT_DK, [(-0.6, 0), (0.6, 0), (0, 1.0)], 0.02, plane="XZ", z=-0.22, loc=(0, 0.5, 0))
        rbox(p, WOOD, (0.5, 0.5, 0.06), loc=(1.2, -0.3, 0.35), r=0.01)  # sieve
        for k in range(5):
            box(p, METAL_DK, (0.48, 0.006, 0.01), loc=(1.2, -0.5 + k * 0.1, 0.38))
        for (x, y) in ((1.0, -0.5), (1.4, -0.5), (1.0, -0.1), (1.4, -0.1)):
            cyl(p, WOOD_DK, 0.015, 0.35, loc=(x, y, 0.17), seg=4)
        sph(p, PAPER2, 0.22, loc=(-1.1, -0.4, 0.1), scale=(1.4, 1.0, 0.6), u=12, v=8)  # plaster jacket
        rbox(p, RED, (0.2, 0.01, 0.06), loc=(-1.1, -0.62, 0.15), r=0.01)
        for (x, y) in ((-0.4, -1.0), (0.4, -1.0), (0.4, -1.6), (-0.4, -1.6)):  # grid stakes + string
            cyl(p, WOOD_LT, 0.012, 0.3, loc=(x, y, 0.15), seg=4)
        tube(p, PAPER, [(-0.4, -1.0, 0.25), (0.4, -1.0, 0.25), (0.4, -1.6, 0.25), (-0.4, -1.6, 0.25), (-0.4, -1.0, 0.25)], 0.004, seg=3, cap=False)
        cyl(p, SAND_DK, 0.35, 0.03, loc=(0, -1.3, 0.0), seg=12)
        lathe(p, BLUE, [(0.0, 0.0), (0.12, 0.0), (0.14, 0.25), (0.0, 0.25)], seg=12, loc=(0.7, 0.2, 0))  # water jug
    return single("SM_DressDigCamp", f)
