"""Museum builds added in feedback round 2 (prop-artist + set-dressing +
stylized-style): the three bigger fossil display cases (each fossil fits exactly
one case size), the office computer, and twelve new attractions / amenities /
decorations unlocked through the Upgrade Tree.

Pivot = floor centre, front = Blender -Y (same as every other build). Footprints:
1 cell = 2 m; a 2x1 build is ~3.8 x 1.8 m, 2x2 ~3.8 x 3.8 m, 3x3 ~5.8 x 5.8 m.
"""
import random

from tt.geo import *  # noqa
from tt.mats import *  # noqa
from tt.pipe import asset, single, finish, empty

BOUNDS = [("bounds", 0.9)]
SAND_BED = M("SandBed", "#e9cf9c")
LAVA = M("Lava", "#ff6a2a", emit=2.5)
ICE_PINK = M("IceCreamPink", "#f7a8c4")
ICE_MINT = M("IceCreamMint", "#a8f0c8")
CONE = M("Cone", "#d99a4e")
SCREEN_BLUE = M("ScreenBlue", "#4fb4ff", emit=1.2)
CYCAD = M("Cycad", "#3f8f3a")


def _brass_posts(p, xs, ys, z0, h):
    for x in xs:
        for y in ys:
            lathe(p, BRASS, [(0.0, z0), (0.06, z0), (0.04, z0 + 0.06), (0.03, z0 + h - 0.05), (0.05, z0 + h), (0.0, z0 + h + 0.04)], seg=10, loc=(x, y, 0))
            sph(p, BRASS, 0.05, loc=(x, y, z0 + h + 0.06), u=8, v=6)


def _frame(p, w, d, z, t=0.05):
    """Brass top frame (4 bars) - the glass stays see-through from above."""
    for sy in (-1, 1):
        rbox(p, BRASS, (w, t, t), loc=(0, sy * d / 2, z), r=0.012)
    for sx in (-1, 1):
        rbox(p, BRASS, (t, d, t), loc=(sx * w / 2, 0, z), r=0.012)


def _plaque(p, loc, w=0.5):
    rbox(p, BRASS, (w, 0.05, 0.26), loc=loc, rot=(-20, 0, 0), r=0.018)
    rbox(p, PAPER, (w - 0.08, 0.01, 0.2), loc=(loc[0], loc[1] - 0.025, loc[2] + 0.004), rot=(-20, 0, 0), r=0.006)


# ------------------------------------------------------------ display cases --
@asset("display_case_medium", tier="prop", group="builds", col=[("box", (0, 0, 0.75), (3.7, 1.5, 1.5))])
def display_case_medium():
    """Long low vitrine for hand- to forearm-sized finds (teeth as big as your hand,
    claws, fish slabs): wooden plinth, glass hood, brass frame."""
    def f(p):
        rbox(p, WOOD_DK, (3.7, 1.5, 0.12), loc=(0, 0, 0.06), r=0.04)
        rbox(p, WOOD, (3.5, 1.3, 0.62), loc=(0, 0, 0.43), r=0.035)
        for k in range(3):
            rbox(p, WOOD_LT, (1.0, 0.02, 0.4), loc=(-1.15 + k * 1.15, -0.66, 0.43), r=0.012)
        rbox(p, TRIM, (3.6, 1.4, 0.07), loc=(0, 0, 0.77), r=0.025)
        rbox(p, VELVET, (3.2, 1.1, 0.04), loc=(0, 0, 0.82), r=0.018)
        box(p, GLASS, (3.4, 1.2, 0.62), loc=(0, 0, 1.12))
        _frame(p, 3.48, 1.28, 1.45)
        _brass_posts(p, (-1.72, 1.72), (-0.62, 0.62), 0.8, 0.62)
        _plaque(p, (0, -0.72, 0.6), 0.6)
    return single("SM_DisplayCaseMedium", f)


@asset("display_case_big", tier="hero", res=1024, group="builds", col=[("box", (0, 0, 0.9), (3.7, 3.7, 1.8))])
def display_case_big():
    """Raised island for big single fossils (a T. rex-sized skull, a horn core, a
    sail spine): stepped stone base, sand bed, tall glass walls on a brass frame."""
    def f(p):
        rbox(p, STONE2, (3.8, 3.8, 0.2), loc=(0, 0, 0.1), r=0.05)
        rbox(p, STONE, (3.5, 3.5, 0.25), loc=(0, 0, 0.32), r=0.05)
        rbox(p, TRIM, (3.6, 3.6, 0.05), loc=(0, 0, 0.46), r=0.02)
        rock(p, SAND_BED, 1.5, loc=(0, 0, 0.45), scale=(1.0, 1.0, 0.07), seed=21, sub=3, rough=0.1, floor=0.0)
        for sx in (-1, 1):
            box(p, GLASS, (0.03, 3.3, 1.3), loc=(sx * 1.66, 0, 1.15))
            box(p, GLASS, (3.3, 0.03, 1.3), loc=(0, sx * 1.66, 1.15))
        _frame(p, 3.42, 3.42, 1.82)
        _brass_posts(p, (-1.68, 1.68), (-1.68, 1.68), 0.5, 1.32)
        _plaque(p, (0, -1.9, 0.42), 0.8)
        rbox(p, STONE2, (1.2, 0.4, 0.14), loc=(0, -2.0, 0.07), r=0.03)
    return single("SM_DisplayCaseBig", f)


@asset("display_case_mega", tier="hero", res=1024, group="builds", col=[("box", (0, 0, 0.35), (5.8, 5.8, 0.7))])
def display_case_mega():
    """Grand 3x3 hall centrepiece for complete skeletons: a two-step marble dais,
    excavation-sand bed, brass posts with velvet ropes, corner glass screens and
    an info lectern. The game assembles the skeleton on top."""
    def f(p):
        rbox(p, STONE2, (5.9, 5.9, 0.22), loc=(0, 0, 0.11), r=0.06)
        rbox(p, STONE, (5.5, 5.5, 0.2), loc=(0, 0, 0.32), r=0.06)
        rbox(p, TRIM, (5.6, 5.6, 0.05), loc=(0, 0, 0.42), r=0.02)
        rock(p, SAND_BED, 2.4, loc=(0, 0, 0.42), scale=(1.0, 1.0, 0.05), seed=9, sub=3, rough=0.12, floor=0.0)
        posts = [(-2.6, -2.6), (0, -2.6), (2.6, -2.6), (2.6, 0), (2.6, 2.6), (0, 2.6), (-2.6, 2.6), (-2.6, 0)]
        for (x, y) in posts:
            lathe(p, BRASS, [(0.0, 0.42), (0.13, 0.42), (0.06, 0.5), (0.045, 1.25), (0.075, 1.3), (0.0, 1.4)], seg=12, loc=(x, y, 0))
            sph(p, BRASS, 0.06, loc=(x, y, 1.42), u=8, v=6)
        for i in range(len(posts)):
            a, b = posts[i], posts[(i + 1) % len(posts)]
            if i == 0:
                continue  # gap at the front-left for the lectern
            tube(p, VELVET, curve_pts((a[0], a[1], 1.24), (b[0], b[1], 1.24), (0, 0, -0.2), 8), 0.035, seg=8)
        for sx in (-1, 1):
            for sy in (-1, 1):
                box(p, GLASS, (1.2, 0.03, 1.1), loc=(sx * 2.2, sy * 2.9, 1.0), rot=(0, 0, 0))
        rbox(p, BRASS, (0.8, 0.06, 0.4), loc=(-1.6, -3.0, 0.75), rot=(-25, 0, 0), r=0.025)
        rbox(p, PAPER, (0.7, 0.02, 0.3), loc=(-1.6, -3.03, 0.755), rot=(-25, 0, 0), r=0.01)
        cyl(p, BRASS, 0.04, 0.6, loc=(-1.6, -2.95, 0.3), seg=8)
        rbox(p, STONE2, (2.0, 0.6, 0.18), loc=(0.6, -3.1, 0.09), r=0.035)
    return single("SM_DisplayCaseMega", f)


# ----------------------------------------------------------------- computer --
@asset("computer_desk", tier="prop", group="builds", col=[("box", (0, 0.1, 0.4), (1.7, 0.8, 0.8))])
def computer_desk():
    """The curator's office PC (unlocked with the 3-star expansion): wooden desk, a
    chunky monitor whose screen the game renders J-Mail onto (ScreenAnchor empty =
    screen centre, facing -Y), keyboard, a Mouse object the game slides around, a
    mug, and a swivel Chair object the player sits on."""
    root = empty("ComputerDesk")
    p = Part()
    rbox(p, WOOD_DK, (1.7, 0.85, 0.06), loc=(0, 0.1, 0.76), r=0.025)
    for x in (-0.78, 0.78):
        rbox(p, WOOD, (0.08, 0.75, 0.73), loc=(x, 0.1, 0.37), r=0.02)
    rbox(p, WOOD, (0.5, 0.7, 0.55), loc=(0.55, 0.12, 0.42), r=0.02)  # drawer pedestal
    for k in range(3):
        rbox(p, WOOD_LT, (0.42, 0.02, 0.14), loc=(0.55, -0.24, 0.24 + k * 0.17), r=0.01)
        sph(p, BRASS, 0.018, loc=(0.55, -0.26, 0.24 + k * 0.17), u=6, v=4)
    # monitor: chunky retro bezel on a stand
    rbox(p, TEAL, (0.2, 0.18, 0.05), loc=(0, 0.33, 0.815), r=0.02)
    cyl(p, METAL_DK, 0.03, 0.18, loc=(0, 0.35, 0.9), seg=8)
    rbox(p, CREAM, (0.82, 0.12, 0.56), loc=(0, 0.32, 1.25), r=0.04)
    rbox(p, CAVE_DK, (0.72, 0.02, 0.46), loc=(0, 0.255, 1.25), r=0.015)
    rbox(p, CREAM, (0.6, 0.25, 0.4), loc=(0, 0.48, 1.24), r=0.06)  # CRT back
    sph(p, GLOW_WARM, 0.012, loc=(0.34, 0.255, 1.04), u=6, v=4)    # power light
    text3d(p, TEAL, "J-PC", size=0.04, loc=(-0.3, 0.255, 1.04), depth=0.002, max_w=0.12)
    # keyboard
    rbox(p, CREAM, (0.48, 0.17, 0.03), loc=(-0.05, 0.02, 0.805), rot=(4, 0, 0), r=0.012)
    for r in range(4):
        for c in range(12):
            rbox(p, PAPER2, (0.03, 0.028, 0.012), loc=(-0.25 + c * 0.037, -0.04 + r * 0.035, 0.825 + r * 0.0025), r=0.004)
    # mousepad + mug + notes + a little ammonite paperweight
    rbox(p, CORAL, (0.24, 0.2, 0.006), loc=(0.35, 0.02, 0.793), r=0.02)
    lathe(p, CREAM, [(0.0, 0.0), (0.045, 0.0), (0.05, 0.1), (0.0, 0.1)], seg=12, loc=(-0.6, 0.15, 0.79))
    tube(p, CREAM, [(-0.553, 0.15, 0.82), (-0.52, 0.15, 0.85), (-0.553, 0.15, 0.88)], 0.008, seg=5)
    rbox(p, YELLOW, (0.12, 0.12, 0.01), loc=(-0.45, -0.12, 0.795), rot=(0, 0, 12), r=0.004)
    spiral(p, [SHELL], turns=2.0, a=0.006, growth=0.25, tube_k=0.4, ppt=14, center=(-0.62, -0.1, 0.82), seg=6, centered=True)
    finish(p, "Desk", root)
    a = empty("ScreenAnchor", root, loc=(0, 0.243, 1.25))
    a.rotation_euler = (0, 0, 0)
    # mouse (own object; origin on the pad so the game can slide it)
    m = Part()
    sph(m, CREAM, 0.035, loc=(0, 0, 0.018), scale=(0.8, 1.25, 0.55), u=12, v=8)
    tube(m, DARK, [(0, -0.04, 0.012), (0.0, -0.09, 0.006), (-0.1, -0.12, 0.0)], 0.003, seg=4)
    finish(m, "Mouse", root, loc=(0.35, 0.02, 0.796))
    # swivel chair (own object so the game can turn it toward the desk)
    c = Part()
    cyl(c, METAL_DK, 0.03, 0.42, loc=(0, 0, 0.27), seg=8)
    for k in range(5):
        aa = k / 5 * TAU
        tube(c, METAL_DK, [(0, 0, 0.07), (0.28 * math.cos(aa), 0.28 * math.sin(aa), 0.05)], 0.018, seg=5)
        sph(c, RUBBER, 0.03, loc=(0.28 * math.cos(aa), 0.28 * math.sin(aa), 0.03), u=6, v=4)
    rbox(c, CUSHION, (0.5, 0.48, 0.09), loc=(0, 0, 0.5), r=0.04)
    rbox(c, CUSHION, (0.46, 0.08, 0.5), loc=(0, 0.24, 0.82), rot=(-8, 0, 0), r=0.04)
    for sx in (-1, 1):
        rbox(c, METAL_DK, (0.04, 0.3, 0.04), loc=(sx * 0.26, 0.02, 0.68), r=0.012)
        cyl(c, METAL_DK, 0.015, 0.14, loc=(sx * 0.26, 0.05, 0.6), seg=6)
    finish(c, "Chair", root, loc=(0, -0.62, 0))
    return root


# ------------------------------------------------------------ attractions ----
@asset("touch_table", tier="prop", group="builds", col=BOUNDS)
def touch_table():
    """'Please Touch!' table: cast replicas guests can handle (kids love it)."""
    def f(p):
        cyl(p, WOOD_DK, 0.75, 0.08, loc=(0, 0, 0.78), seg=28)
        cyl(p, WOOD, 0.7, 0.06, loc=(0, 0, 0.83), seg=28)
        lathe(p, WOOD, [(0.0, 0.0), (0.45, 0.0), (0.12, 0.08), (0.1, 0.74), (0.0, 0.74)], seg=16)
        cyl(p, SAND_BED, 0.6, 0.02, loc=(0, 0, 0.865), seg=24)
        spiral(p, [SHELL, SHELL2], turns=2.4, a=0.01, growth=0.22, tube_k=0.42, ppt=16, center=(-0.25, 0.1, 0.95), seg=8, centered=True)
        tube(p, BONE, [(0.05, -0.3, 0.9), (0.4, -0.15, 0.9)], [0.05, 0.04], seg=8)
        for x in (0.02, 0.43):
            sph(p, BONE, 0.06, loc=(x, -0.3 + (x - 0.02) * 0.37, 0.9), u=8, v=6)
        prism(p, TOOTH, [(-0.05, 0), (0.05, 0), (0, 0.16)], 0.03, plane="XZ", z=-0.015, loc=(0.25, 0.3, 0.88))
        for k in range(5):  # tiny trilobite casts
            sph(p, FBONE, 0.05, loc=(-0.45 + k * 0.08, -0.25 + (k % 2) * 0.1, 0.875), hemi=True, scale=(1.0, 1.4, 0.5), u=10, v=6)
        rbox(p, CORAL, (0.7, 0.05, 0.22), loc=(0, -0.72, 0.98), rot=(-10, 0, 0), r=0.03)
        text3d(p, CREAM, "PLEASE TOUCH!", size=0.06, loc=(0, -0.75, 0.985), depth=0.003, max_w=0.6)
    return single("SM_TouchTable", f)


@asset("microscope_station", tier="prop", group="builds", col=BOUNDS)
def microscope_station():
    """Microscope bench: peer at microfossils (forams, pollen) - big screen shows
    what the scope sees."""
    def f(p):
        rbox(p, WOOD_DK, (1.5, 0.8, 0.06), loc=(0, 0, 0.88), r=0.025)
        for x in (-0.68, 0.68):
            rbox(p, WOOD, (0.08, 0.7, 0.85), loc=(x, 0, 0.43), r=0.02)
        rbox(p, CREAM, (0.3, 0.22, 0.04), loc=(-0.2, -0.05, 0.93), r=0.015)
        tube(p, CREAM, [(-0.2, 0.05, 0.93), (-0.2, 0.08, 1.2), (-0.2, -0.02, 1.32)], 0.04, seg=10)
        cyl(p, DARK, 0.045, 0.22, loc=(-0.2, -0.05, 1.33), rot=(-35, 0, 0), seg=12)
        cyl(p, METAL, 0.03, 0.12, loc=(-0.2, -0.04, 1.08), seg=10)
        cyl(p, GLASS, 0.06, 0.01, loc=(-0.2, -0.05, 0.96), seg=12)
        # monitor showing a magnified foraminifera
        rbox(p, DARK, (0.62, 0.06, 0.44), loc=(0.35, 0.22, 1.25), r=0.03)
        rbox(p, SCREEN_BLUE, (0.54, 0.02, 0.36), loc=(0.35, 0.185, 1.25), r=0.02)
        spiral(p, [CREAM], turns=1.5, a=0.006, growth=0.3, tube_k=0.45, ppt=14, center=(0.35, 0.17, 1.25), seg=6, centered=True)
        cyl(p, METAL_DK, 0.025, 0.25, loc=(0.35, 0.24, 1.0), seg=8)
        for k in range(4):  # slide box
            rbox(p, GLASS, (0.08, 0.03, 0.005), loc=(0.15 + k * 0.1, -0.25, 0.915), r=0.002)
        rbox(p, TEAL, (0.6, 0.05, 0.2), loc=(0, -0.42, 0.7), r=0.03)
        text3d(p, CREAM, "MICRO-FOSSILS", size=0.05, loc=(0, -0.448, 0.7), depth=0.003, max_w=0.52)
    return single("SM_MicroscopeStation", f)


@asset("photo_booth", tier="prop", group="builds", col=[("box", (0, 0, 1.1), (1.6, 0.4, 2.2))])
def photo_booth():
    """'Selfie with a T. rex' cut-out board with a face hole + a camera on a tripod."""
    def f(p):
        grn = M("BoothGreen", "#5aa84a")
        poly = [(-0.75, 0.0), (0.75, 0.0), (0.75, 1.3), (0.55, 1.6), (0.6, 2.05), (0.15, 2.2), (-0.45, 2.1), (-0.75, 1.8)]
        prism(p, grn, poly, 0.06, plane="XZ", z=-0.03, loc=(0, 0.0, 0.0))
        # face hole (dark disc on both sides) + painted teeth & eye
        cyl(p, CAVE_DK, 0.17, 0.08, loc=(0.05, 0, 1.65), rot=(90, 0, 0), seg=18)
        for k in range(6):
            prism(p, TOOTH, [(-0.03, 0), (0.03, 0), (0, -0.08)], 0.01, plane="XZ", z=-0.045, loc=(-0.35 + k * 0.1, 0, 1.42))
        sph(p, C_EYE, 0.05, loc=(0.35, -0.04, 1.9), scale=(1, 0.3, 1), u=8, v=6)
        rbox(p, WOOD_DK, (0.1, 0.4, 0.06), loc=(-0.6, 0.2, 0.03), r=0.02)
        rbox(p, WOOD_DK, (0.1, 0.4, 0.06), loc=(0.6, 0.2, 0.03), r=0.02)
        for x in (-0.6, 0.6):
            tube(p, WOOD_DK, [(x, 0.05, 0.05), (x, 0.38, 0.05), (x, 0.05, 1.0)], 0.025, seg=5)
        text3d(p, CREAM, "SAY ROAR!", size=0.12, loc=(0, -0.035, 0.5), depth=0.004, max_w=1.1)
    return single("SM_PhotoBooth", f)


@asset("ice_cream_stand", tier="prop", group="builds", col=BOUNDS)
def ice_cream_stand():
    """'Ice Age Ice Cream' cart: freezer cart, striped parasol, giant cone sign."""
    def f(p):
        rbox(p, ICE_MINT, (1.4, 0.8, 0.8), loc=(0, 0, 0.62), r=0.06)
        rbox(p, CREAM, (1.48, 0.88, 0.06), loc=(0, 0, 1.05), r=0.03)
        for k in range(4):
            rbox(p, GLASS, (0.28, 0.5, 0.02), loc=(-0.45 + k * 0.3, 0.05, 1.09), r=0.01)
            sph(p, (ICE_PINK, CREAM, ICE_MINT, YELLOW)[k], 0.08, loc=(-0.45 + k * 0.3, 0.05, 1.06), u=10, v=6)
        for sx in (-1, 1):
            cyl(p, RUBBER, 0.2, 0.08, loc=(sx * 0.55, 0.42, 0.2), rot=(90, 0, 0), seg=16)
        cyl(p, METAL_DK, 0.025, 1.4, loc=(0.55, 0.3, 1.75), seg=8)
        for k in range(8):
            a0, a1 = k / 8 * TAU, (k + 1) / 8 * TAU
            prism(p, ICE_PINK if k % 2 else CREAM, [(0, 0), (1.0 * math.cos(a0), 1.0 * math.sin(a0)), (1.0 * math.cos(a1), 1.0 * math.sin(a1))], 0.03, z=2.42, loc=(0.55, 0.3, 0))
        lathe(p, CONE, [(0.0, 0.0), (0.12, 0.35), (0.0, 0.35)], seg=12, loc=(-0.5, -0.1, 1.1))
        sph(p, ICE_PINK, 0.14, loc=(-0.5, -0.1, 1.5), u=12, v=8)
        sph(p, ICE_MINT, 0.12, loc=(-0.5, -0.1, 1.68), u=12, v=8)
        rbox(p, CORAL, (0.9, 0.05, 0.3), loc=(0, -0.42, 0.65), r=0.03)
        text3d(p, CREAM, "ICE AGE ICE CREAM", size=0.07, loc=(0, -0.448, 0.65), depth=0.003, max_w=0.82)
    return single("SM_IceCreamStand", f)


@asset("water_fountain", tier="item", group="builds", col=[("box", (0, 0, 0.5), (0.6, 0.6, 1.0))])
def water_fountain():
    def f(p):
        rbox(p, METAL, (0.5, 0.4, 0.85), loc=(0, 0.05, 0.43), r=0.05)
        rbox(p, METAL_DK, (0.56, 0.46, 0.08), loc=(0, 0.02, 0.9), r=0.03)
        lathe(p, METAL, [(0.0, 0.0), (0.18, 0.0), (0.2, 0.06), (0.0, 0.03)], seg=16, loc=(0, -0.03, 0.94))
        tube(p, METAL, [(0.05, -0.03, 0.96), (0.05, -0.03, 1.02), (0.0, -0.05, 1.03)], 0.012, seg=5)
        tube(p, WATER, curve_pts((0.0, -0.05, 1.03), (-0.08, -0.06, 0.96), (0, 0, 0.06), 5), 0.008, seg=4)
        rbox(p, BLUE, (0.3, 0.02, 0.2), loc=(0, -0.16, 0.6), r=0.02)
        sph(p, CREAM, 0.04, loc=(0, -0.175, 0.62), scale=(0.7, 0.3, 1.1), u=8, v=6)
    return single("SM_WaterFountain", f)


@asset("vending_machine", tier="item", group="builds", col=[("box", (0, 0, 0.95), (1.0, 0.8, 1.9))])
def vending_machine():
    def f(p):
        # hollow cabinet: back block, side walls, top, bottom, control column
        rbox(p, CORAL, (0.95, 0.4, 1.9), loc=(0, 0.175, 0.95), r=0.04)
        for sx in (-1, 1):
            rbox(p, CORAL, (0.06, 0.38, 1.9), loc=(sx * 0.445, -0.18, 0.95), r=0.02)
        rbox(p, CORAL, (0.95, 0.38, 0.12), loc=(0, -0.18, 1.85), r=0.02)
        rbox(p, CORAL, (0.95, 0.38, 0.5), loc=(0, -0.18, 0.25), r=0.02)
        rbox(p, CORAL, (0.24, 0.38, 1.3), loc=(0.32, -0.18, 1.15), r=0.02)
        box(p, GLASS, (0.62, 0.03, 1.2), loc=(-0.1, -0.37, 1.15))
        for r in range(4):
            rbox(p, METAL_DK, (0.6, 0.5, 0.02), loc=(-0.1, -0.1, 0.65 + r * 0.3), r=0.005)
            for c in range(4):
                rbox(p, (YELLOW, BLUE, GREEN, RED)[(r + c) % 4], (0.1, 0.14, 0.2), loc=(-0.32 + c * 0.15, -0.2, 0.76 + r * 0.3), r=0.02)
        rbox(p, DARK, (0.2, 0.04, 0.5), loc=(0.33, -0.37, 1.3), r=0.02)
        for k in range(6):
            rbox(p, CREAM, (0.05, 0.02, 0.04), loc=(0.3 + (k % 2) * 0.07, -0.39, 1.45 - (k // 2) * 0.08), r=0.008)
        rbox(p, DARK, (0.5, 0.04, 0.16), loc=(-0.1, -0.37, 0.3), r=0.02)
        text3d(p, CREAM, "DINO SNACKS", size=0.08, loc=(-0.05, -0.385, 1.8), depth=0.004, max_w=0.8)
    return single("SM_VendingMachine", f)


@asset("volcano_diorama", tier="hero", res=1024, group="builds", col=[("box", (0, 0, 0.6), (3.6, 3.6, 1.2))])
def volcano_diorama():
    """Cretaceous diorama: a smoking volcano with glowing lava rivers, cycads and
    little dinosaurs on a wooden diorama table (2x2)."""
    def f(p):
        rbox(p, WOOD_DK, (3.7, 3.7, 0.5), loc=(0, 0, 0.25), r=0.06)
        rbox(p, TRIM, (3.75, 3.75, 0.05), loc=(0, 0, 0.5), r=0.02)
        rock(p, SOIL, 1.6, loc=(0, 0, 0.52), scale=(1.05, 1.05, 0.12), seed=3, sub=3, rough=0.15, floor=0.0)
        lathe(p, ROCK_DK, [(1.3, 0.55), (1.0, 0.9), (0.5, 1.8), (0.3, 2.05), (0.2, 2.0), (0.0, 1.9)], seg=24, loc=(0.4, 0.5, 0))
        for k in range(4):  # lava rivers down the flanks
            a = k * 1.4 + 0.3
            tube(p, LAVA, [(0.4 + 0.25 * math.cos(a), 0.5 + 0.25 * math.sin(a), 2.0), (0.4 + 0.7 * math.cos(a + 0.2), 0.5 + 0.7 * math.sin(a + 0.2), 1.3),
                           (0.4 + 1.25 * math.cos(a + 0.3), 0.5 + 1.25 * math.sin(a + 0.3), 0.62)], [0.06, 0.08, 0.1], seg=6)
        cyl(p, LAVA, 0.22, 0.04, loc=(0.4, 0.5, 2.0), seg=16)
        for k in range(3):  # smoke puffs
            sph(p, PAPER2, 0.25 + k * 0.08, loc=(0.4 + k * 0.15, 0.5 - k * 0.1, 2.3 + k * 0.35), u=10, v=8)
        rnd = random.Random(4)
        for k in range(6):  # cycads
            x, y = rnd.uniform(-1.5, -0.4), rnd.uniform(-1.5, 1.5)
            cyl(p, TRUNK, 0.05, 0.25, loc=(x, y, 0.75), seg=6)
            for j in range(6):
                aa = j / 6 * TAU
                leaf(p, CYCAD, (x, y, 0.88), math.degrees(aa), 0.28, 0.05, rise=0.3, droop=0.9, segs=5)
        for k, (x, y) in enumerate(((-0.8, -1.2), (-0.2, -1.3), (1.2, -1.0))):  # tiny sauropods
            sph(p, GREEN, 0.1, loc=(x, y, 0.72), scale=(1.4, 0.8, 0.8), u=10, v=8)
            tube(p, GREEN, [(x + 0.1, y, 0.75), (x + 0.22, y, 0.92), (x + 0.28, y, 0.95)], [0.035, 0.025, 0.02], seg=6)
            tube(p, GREEN, [(x - 0.12, y, 0.72), (x - 0.3, y, 0.66)], [0.03, 0.005], seg=5)
    return single("SM_VolcanoDiorama", f)


@asset("dino_slide", tier="hero", res=1024, group="builds", col=[("box", (0, 0, 1.0), (3.6, 3.6, 2.0))])
def dino_slide():
    """Kids' slide shaped like a friendly sauropod: climb the back, slide down the neck."""
    def f(p):
        grn = M("SlideGreen", "#6cc04a")
        sph(p, grn, 1.1, loc=(-0.4, 0.3, 0.9), scale=(1.4, 0.85, 0.85), u=24, v=14)
        for sx in (-1, 1):
            for sy in (-1, 1):
                cyl(p, grn, 0.22, 0.6, loc=(-0.4 + sx * 0.8, 0.3 + sy * 0.45, 0.3), seg=12)
        tube(p, grn, [(-1.8, 0.3, 0.9), (-2.4, 0.3, 0.55), (-1.9, 0.3, 0.2)], [0.35, 0.2, 0.06], seg=12)  # tail
        # slide: the neck curving down to the front
        pts = [(0.6, 0.3, 1.6), (1.1, 0.0, 1.3), (1.3, -0.6, 0.7), (1.1, -1.3, 0.25)]
        tube(p, YELLOW, pts, 0.32, seg=12, scale=(1.0, 0.35))
        for sy in (1, -1):
            tube(p, ORANGE, [(x, y + sy * 0.28, z + 0.12) for (x, y, z) in pts], 0.05, seg=6)
        sph(p, grn, 0.35, loc=(0.75, 0.45, 2.1), scale=(1.2, 0.9, 0.8), u=16, v=10)  # head
        tube(p, grn, [(0.3, 0.35, 1.5), (0.6, 0.4, 1.9), (0.75, 0.45, 2.05)], [0.3, 0.25, 0.22], seg=10)
        for sy in (1, -1):
            sph(p, C_EYE, 0.05, loc=(0.95, 0.45 + sy * 0.18, 2.2), u=8, v=6)
        # ladder up the back
        for k in range(5):
            rbox(p, WOOD_LT, (0.5, 0.06, 0.06), loc=(-0.6, -0.55, 0.25 + k * 0.3), r=0.02)
        for sx in (-1, 1):
            cyl(p, WOOD, 0.035, 1.6, loc=(-0.6 + sx * 0.25, -0.55, 0.8), seg=6)
        rock(p, SAND_BED, 1.0, loc=(1.0, -1.4, 0.0), scale=(1.0, 0.8, 0.08), seed=2, sub=2, rough=0.1, floor=0.0)
    return single("SM_DinoSlide", f)


@asset("time_tunnel", tier="hero", res=1024, group="builds", col=[("box", (-1.6, 0, 1.3), (0.5, 1.6, 2.6)), ("box", (1.6, 0, 1.3), (0.5, 1.6, 2.6)), ("box", (0, 0, 2.5), (3.7, 1.6, 0.4))])
def time_tunnel():
    """Walk-through 'Time Tunnel' arch (2x1): its bands are the rock layers from the
    Paleozoic (bottom, grey slate) to the Cenozoic (top, sandy) - deeper = older."""
    def f(p):
        bands = [(SLATE[1], "PALEOZOIC"), (STRATA[3], "MESOZOIC"), (SANDST[0], "CENOZOIC")]
        for sx in (-1, 1):
            for k, (m, _) in enumerate(bands):
                rbox(p, m, (0.5, 1.6, 0.85), loc=(sx * 1.6, 0, 0.43 + k * 0.85), r=0.05)
        rbox(p, SANDST[2], (3.7, 1.6, 0.4), loc=(0, 0, 2.75), r=0.06)
        for k in range(11):
            a = math.pi * k / 10
            rbox(p, STRATA[k % 5], (0.35, 1.62, 0.3), loc=(math.cos(a) * 1.45, 0, 2.55 + math.sin(a) * 0.35), rot=(0, -math.degrees(a) + 90, 0), r=0.04)
        for k, (m, nm) in enumerate(bands):
            text3d(p, CREAM, nm, size=0.09, loc=(-1.6, -0.81, 0.43 + k * 0.85), depth=0.004, max_w=0.46)
        spiral(p, [SHELL], turns=2.0, a=0.02, growth=0.22, tube_k=0.4, ppt=14, center=(1.6, -0.82, 1.3), seg=8, centered=True)
        sph(p, FBONE, 0.1, loc=(1.6, -0.82, 0.45), hemi=True, scale=(1.2, 0.4, 0.8), u=10, v=6)
        rbox(p, TEAL, (2.2, 0.08, 0.3), loc=(0, -0.82, 2.75), r=0.04)
        text3d(p, CREAM, "TIME TUNNEL", size=0.18, loc=(0, -0.865, 2.75), depth=0.006, max_w=2.0)
        rbox(p, SAND_BED, (2.6, 1.5, 0.03), loc=(0, 0, 0.015), r=0.01)
    return single("SM_TimeTunnel", f)


# ----------------------------------------------------------------- decor -----
@asset("fern_garden", tier="item", group="builds", col=[("box", (0, 0, 0.3), (1.6, 1.6, 0.6))])
def fern_garden():
    """Prehistoric planter: tree ferns, cycads and horsetails - living plant groups
    that were already here when dinosaurs walked."""
    def f(p):
        rbox(p, STONE2, (1.7, 1.7, 0.5), loc=(0, 0, 0.25), r=0.06)
        rbox(p, SOIL, (1.5, 1.5, 0.05), loc=(0, 0, 0.5), r=0.02)
        rnd = random.Random(7)
        cyl(p, TRUNK2, 0.07, 0.9, loc=(0.2, 0.2, 0.95), seg=8)
        for j in range(8):
            leaf(p, LEAF_DK, (0.2, 0.2, 1.4), j * 45.0, 0.6, 0.1, rise=0.4, droop=1.1, segs=6)
        cyl(p, TRUNK, 0.08, 0.25, loc=(-0.4, -0.3, 0.62), seg=8)
        for j in range(7):
            leaf(p, CYCAD, (-0.4, -0.3, 0.75), j * 51.4, 0.42, 0.07, rise=0.5, droop=1.0, segs=5)
        for k in range(9):  # horsetails
            x, y = rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6)
            if abs(x - 0.2) < 0.2 and abs(y - 0.2) < 0.2:
                continue
            h = rnd.uniform(0.3, 0.6)
            cyl(p, GRASS2, 0.015, h, loc=(x, y, 0.52 + h / 2), seg=5)
            for j in range(3):
                cyl(p, DARK, 0.018, 0.01, loc=(x, y, 0.55 + h * (0.3 + j * 0.25)), seg=5)
        rbox(p, BRASS, (0.4, 0.04, 0.12), loc=(0, -0.86, 0.35), r=0.015)
    return single("SM_FernGarden", f)


@asset("ammonite_fountain", tier="prop", group="builds", col=[("box", (0, 0, 0.35), (1.7, 1.7, 0.7))])
def ammonite_fountain():
    def f(p):
        lathe(p, STONE, [(0.0, 0.0), (0.85, 0.0), (0.85, 0.45), (0.75, 0.45), (0.72, 0.12), (0.0, 0.12)], seg=28)
        cyl(p, WATER, 0.72, 0.03, loc=(0, 0, 0.38), seg=28)
        cyl(p, STONE2, 0.2, 0.5, loc=(0, 0, 0.6), seg=16)
        spiral(p, [STONE, STONE2], turns=2.2, a=0.02, growth=0.2, tube_k=0.45, center=(0, 0, 1.15), seg=10, centered=True)
        for k in range(4):
            a = k / 4 * TAU
            tube(p, WATER, curve_pts((0.15 * math.cos(a), 0.15 * math.sin(a), 0.95), (0.6 * math.cos(a), 0.6 * math.sin(a), 0.4), (0, 0, 0.3), 6), 0.025, seg=4)
    return single("SM_AmmoniteFountain", f)


@asset("bookshelf", tier="item", group="builds", col=[("box", (0, 0.1, 1.0), (1.6, 0.5, 2.0))])
def bookshelf():
    """Reading nook shelf: field guides, a globe and a trilobite bookend."""
    def f(p):
        # open-fronted carcass: back, sides, top, plinth (books show from the front)
        rbox(p, WOOD_DK, (1.6, 0.05, 2.0), loc=(0, 0.33, 1.0), r=0.015)
        for sx in (-1, 1):
            rbox(p, WOOD_DK, (0.06, 0.45, 2.0), loc=(sx * 0.77, 0.12, 1.0), r=0.015)
        rbox(p, WOOD_DK, (1.6, 0.45, 0.06), loc=(0, 0.12, 1.97), r=0.015)
        rbox(p, WOOD_DK, (1.6, 0.45, 0.1), loc=(0, 0.12, 0.05), r=0.015)
        rnd = random.Random(3)
        for s in range(4):
            z = 0.12 + s * 0.48
            rbox(p, WOOD, (1.45, 0.4, 0.04), loc=(0, 0.1, z), r=0.01)
            x = -0.66
            while x < 0.6:
                w = rnd.uniform(0.05, 0.1)
                h = rnd.uniform(0.28, 0.38)
                rbox(p, (RED, TEAL, YELLOW, BLUE, GREEN, PURPLE, CORAL)[rnd.randrange(7)], (w, 0.28, h), loc=(x + w / 2, 0.08, z + 0.02 + h / 2), rot=(0, rnd.uniform(-4, 4), 0), r=0.008)
                x += w + 0.008
        sph(p, BLUE, 0.13, loc=(0.4, 0.1, 2.15), u=14, v=10)
        cyl(p, BRASS, 0.08, 0.05, loc=(0.4, 0.1, 2.02), seg=10)
        sph(p, FBONE, 0.09, loc=(-0.45, 0.05, 2.06), hemi=True, scale=(1.0, 1.4, 0.6), u=12, v=8)
    return single("SM_Bookshelf", f)
