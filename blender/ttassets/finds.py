"""Feedback round 2 finds (prop-artist + sculpting + creature-artist proportions):
seventeen new display-fossil shapes, three land-animal mega skeletons (T. rex,
Iguanodon, Dimetrodon) and the rare BIG dig spots.

Display fossils use the tint material "Fossil" so Godot recolours them per
species (exactly like the original specimens). Skeleton pieces are separate
objects: Skull / Jaw / Neck / Back / Ribs / Arms / Legs / Tail / Mount, toggled
by the game as bones are found.
"""
import random

from tt.geo import *  # noqa
from tt.mats import *  # noqa
from tt.pipe import asset, single, finish, empty

BONE_SCULPT = dict(strength=0.5, scale=6.0)
ROCK_SCULPT = dict(strength=1.1, scale=3.0)
SLABM = M("SlabStone", "#cdbf9f")
SLABM2 = M("SlabStone2", "#b6a684")
SHALE = M("ShaleSlab", "#7d8590")
CHALK = M("ChalkWhite", "#ece6d6")
TAR = M("TarBlack", "#2b2622")


# -------------------------------------------------------------- shells etc --
@asset("scallop", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def scallop():
    """Radial ribs fanning from the hinge, the 'ears' either side of it."""
    def f(p):
        for k in range(15):
            a = math.radians(-70 + k * 10)
            tube(p, FOSSIL, [(0, 0, 0.02), (0.2 * math.sin(a), -0.2 * math.cos(a) + 0.08, 0.035), (0.26 * math.sin(a), -0.26 * math.cos(a) + 0.12, 0.02)],
                 [0.012, 0.022, 0.014], seg=6, scale=(1.0, 1.0))
        sph(p, FOSSIL, 0.2, loc=(0, -0.07, 0.0), hemi=True, scale=(1.15, 1.0, 0.22), u=20, v=8)
        for sx in (-1, 1):
            prism(p, FOSSIL, [(0, 0), (sx * 0.09, 0.0), (sx * 0.07, 0.06), (0, 0.05)], 0.02, z=0.0, loc=(0, 0.05, 0.0))
    return single("SM_Scallop", f)


@asset("crab", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def crab():
    def f(p):
        sph(p, FOSSIL, 0.16, loc=(0, 0, 0.02), hemi=True, scale=(1.25, 0.9, 0.38), u=20, v=10)
        for sx in (-1, 1):
            for k in range(4):
                y = -0.06 + k * 0.05
                tube(p, FOSSIL, [(sx * 0.17, y, 0.03), (sx * 0.27, y + 0.03, 0.05), (sx * 0.32, y + 0.06, 0.0)], [0.016, 0.012, 0.005], seg=5)
            tube(p, FOSSIL, [(sx * 0.12, -0.12, 0.03), (sx * 0.2, -0.22, 0.05)], [0.025, 0.03], seg=6)
            sph(p, SHELL, 0.045, loc=(sx * 0.22, -0.26, 0.05), scale=(0.8, 1.3, 0.7), u=10, v=6)
            sph(p, SHELL2, 0.012, loc=(sx * 0.04, -0.14, 0.06), u=6, v=4)
    return single("SM_Crab", f)


@asset("urchin", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def urchin():
    """Heart-shaped chalk urchin with the five ambulacral 'petals' on top."""
    def f(p):
        sph(p, FOSSIL, 0.14, loc=(0, 0, 0.0), hemi=True, scale=(1.0, 1.1, 0.85), u=24, v=12)
        for k in range(5):
            a = k / 5 * TAU
            for j in range(6):
                r = 0.02 + j * 0.018
                sph(p, SHELL2, 0.006, loc=(r * math.cos(a), r * math.sin(a) * 1.1, 0.12 - (r ** 2) * 2.5), u=5, v=4)
    return single("SM_Urchin", f)


@asset("coral", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def coral():
    """Rugose 'horn' coral: a curved cone with growth wrinkles and a septa cup."""
    def f(p):
        pts = curve_pts((0, 0, 0.02), (0.05, 0, 0.36), (0.08, 0, 0.0), 10)
        tube(p, FOSSIL, pts, [0.015, 0.03, 0.045, 0.06, 0.072, 0.082, 0.09, 0.096, 0.1, 0.104], seg=12)
        for j in range(2, 10, 2):
            sph(p, SHELL, 0.03 + j * 0.008, loc=pts[j], scale=(1.0, 1.0, 0.18), u=10, v=4)
        for k in range(10):
            a = k / 10 * TAU
            rbox(p, SHELL2, (0.09, 0.006, 0.01), loc=(pts[-1][0] + 0.045 * math.cos(a), 0.045 * math.sin(a), pts[-1][2] + 0.002), rot=(0, 0, math.degrees(a)), r=0.002)
    return single("SM_Coral", f)


@asset("stromatolite", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def stromatolite():
    """Layered dome built by microbial mats - stacked wavy laminae."""
    def f(p):
        for k in range(9):
            r = 0.2 - k * 0.018
            rock(p, FOSSIL if k % 2 else SHELL, r, loc=(0, 0, 0.02 + k * 0.03), scale=(1.0, 0.9, 0.22), seed=30 + k, sub=2, rough=0.08, floor=-1.0)
    return single("SM_Stromatolite", f)


@asset("whorl", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def whorl():
    """Helicoprion tooth whorl: a buzz-saw spiral of serrated teeth."""
    def f(p):
        n = 34
        for i in range(n):
            th = i / n * 2.4 * TAU
            r = 0.03 * math.exp(0.13 * th)
            c = Vector((r * math.cos(th), 0.0, 0.2 + r * math.sin(th)))
            sz = 0.012 + i * 0.0014
            prism(p, FOSSIL, [(-sz, 0), (sz, 0), (0, sz * 2.6)], 0.012, plane="XZ", z=-0.006, loc=c, rot=(0, -math.degrees(th) + 90, 0))
            sph(p, SHELL2, sz * 0.7, loc=c, scale=(1.2, 0.7, 1.0), u=6, v=4)
    return single("SM_Whorl", f)


# ------------------------------------------------------------- slabs ---------
def _slab_base(p, w=0.5, d=0.38, mat=SLABM):
    slab(p, mat, (w, d, 0.07), loc=(0, 0, 0.035), seed=3, rough=0.012, cuts=4)


@asset("plant_slab", tier="small", group="finds", res=256)
def plant_slab():
    """Leaf / frond impression on a split stone slab."""
    def f(p):
        _slab_base(p)
        tube(p, FOSSIL, [(-0.2, -0.12, 0.072), (0.0, 0.0, 0.074), (0.2, 0.12, 0.072)], 0.008, seg=5)
        for k in range(9):
            t = 0.1 + k * 0.1
            c = Vector((-0.2 + 0.4 * t, -0.12 + 0.24 * t, 0.073))
            for s in (-1, 1):
                leaf(p, FOSSIL, c, math.degrees(math.atan2(0.24, 0.4)) + s * 70, 0.09 - abs(t - 0.5) * 0.06, 0.018, rise=0.0, droop=0.0, segs=4, thick=0.003)
    return single("SM_PlantSlab", f)


@asset("fish_slab", tier="small", group="finds", res=256)
def fish_slab():
    """Whole fossil fish lying on its side in a shale slab."""
    def f(p):
        _slab_base(p, 0.6, 0.36, SHALE)
        sph(p, FOSSIL, 0.12, loc=(0.02, 0, 0.075), scale=(1.6, 0.6, 0.12), u=18, v=8)
        prism(p, FOSSIL, [(0.0, 0.0), (-0.12, 0.08), (-0.12, -0.08)], 0.012, plane="XY", z=0.07, loc=(-0.17, 0, 0))
        for k in range(10):
            x = -0.12 + k * 0.025
            tube(p, SHELL2, [(x, -0.06, 0.087), (x + 0.01, 0.06, 0.087)], 0.0035, seg=4)
        sph(p, SHELL2, 0.014, loc=(0.15, 0.015, 0.088), u=6, v=4)
        prism(p, FOSSIL, [(0.0, 0.0), (0.05, 0.05), (0.08, 0.0)], 0.01, plane="XY", z=0.07, loc=(0.0, 0.06, 0))
    return single("SM_FishSlab", f)


@asset("wing_slab", tier="small", group="finds", res=256)
def wing_slab():
    """Fine limestone with a feather / insect wing impression (veins radiating)."""
    def f(p):
        _slab_base(p, 0.5, 0.34, CHALK)
        tube(p, FOSSIL, [(-0.2, 0, 0.073), (0.2, 0.03, 0.073)], 0.006, seg=4)
        for k in range(14):
            x = -0.16 + k * 0.026
            for s in (-1, 1):
                tube(p, FOSSIL, [(x, 0.002 * k, 0.073), (x + 0.04, s * (0.09 - abs(k - 7) * 0.006), 0.073)], 0.0035, seg=4)
    return single("SM_WingSlab", f)


@asset("footprint", tier="small", group="finds", res=256)
def footprint():
    """Three-toed theropod track pressed into a mudstone slab."""
    def f(p):
        _slab_base(p, 0.6, 0.6, SLABM2)
        sph(p, CAVE_DK, 0.05, loc=(0, -0.1, 0.066), scale=(1.0, 1.2, 0.1), u=12, v=6)
        for a in (-28, 0, 28):
            r = math.radians(a)
            tube(p, FOSSIL, [(0.0, -0.04, 0.072), (0.22 * math.sin(r), 0.18 * math.cos(r), 0.072)], [0.035, 0.02], seg=6, scale=(1.0, 0.25))
            sph(p, FOSSIL, 0.02, loc=(0.24 * math.sin(r), 0.2 * math.cos(r), 0.072), scale=(1, 1, 0.3), u=6, v=4)
    return single("SM_Footprint", f)


# --------------------------------------------------------------- bones etc ---
@asset("claw", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def claw():
    """Recurved claw / canine: a hooked tapering cone."""
    def f(p):
        pts = [(0.0, 0, 0.05 + 0.3 * math.sin(math.pi * 0.5 * i / 9) ** 1.0) for i in range(10)]
        pts = [(-0.04 + 0.2 * (1 - math.cos(math.pi * 0.5 * i / 9)), 0, 0.05 + 0.25 * math.sin(math.pi * 0.5 * i / 9)) for i in range(10)]
        tube(p, FOSSIL, pts, [0.05 - i * 0.0052 for i in range(10)], seg=10, scale=(1.0, 0.6))
        rbox(p, SHELL2, (0.1, 0.06, 0.06), loc=(-0.06, 0, 0.05), r=0.02)
    return single("SM_Claw", f)


@asset("horn", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def horn():
    """Ceratopsian horn core on its skull-roof base: long, slightly curved, grooved."""
    def f(p):
        rock(p, FOSSIL, 0.1, loc=(0, 0, 0.05), scale=(1.4, 1.0, 0.6), seed=4, sub=2, rough=0.12, floor=-0.3)
        pts = curve_pts((0, 0, 0.06), (0.12, 0, 0.5), (0.06, 0, 0.0), 8)
        tube(p, FOSSIL, pts, [0.07, 0.062, 0.054, 0.045, 0.036, 0.026, 0.016, 0.004], seg=10)
        for j in range(1, 7):
            sph(p, SHELL2, 0.006, loc=Vector(pts[j]) + Vector((0, 0.05 - j * 0.006, 0)), u=4, v=3)
    return single("SM_Horn", f)


@asset("tusk", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def tusk():
    """Mammoth tusk: a long ivory spiral arc."""
    def f(p):
        pts = []
        for i in range(12):
            t = i / 11
            a = t * 2.2
            pts.append((0.32 * math.sin(a) - 0.1, 0.06 * math.sin(t * 3.0), 0.04 + 0.22 * (1 - math.cos(a)) * 0.6))
        tube(p, FOSSIL, pts, [0.06 - i * 0.0045 for i in range(12)], seg=10)
        for j in range(0, 10, 2):  # growth bands
            sph(p, SHELL, 0.06 - j * 0.0045, loc=pts[j], scale=(0.3, 1.05, 1.05), u=10, v=6)
    return single("SM_Tusk", f)


@asset("armor_plate", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def armor_plate():
    """Bony plate / scute: an upright, rounded-diamond plate with a vascular texture
    (stegosaur plates, ankylosaur scutes, glyptodont shell)."""
    def f(p):
        poly = [(-0.16, 0.0), (0.16, 0.0), (0.2, 0.12), (0.08, 0.34), (0.0, 0.38), (-0.12, 0.3), (-0.2, 0.12)]
        prism(p, FOSSIL, poly, 0.045, plane="XZ", z=-0.022, loc=(0, 0, 0.03))
        rnd = random.Random(8)
        for k in range(16):
            x, z = rnd.uniform(-0.12, 0.12), rnd.uniform(0.06, 0.3)
            tube(p, SHELL2, [(x, -0.026, z), (x + rnd.uniform(-0.03, 0.03), -0.026, z + 0.05)], 0.004, seg=3)
        rbox(p, SHELL2, (0.34, 0.08, 0.05), loc=(0, 0, 0.025), r=0.02)
    return single("SM_ArmorPlate", f)


@asset("egg", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def egg():
    """Clutch of three dinosaur eggs half-buried in a nest of mudstone."""
    def f(p):
        rock(p, SLABM2, 0.24, loc=(0, 0, 0.0), scale=(1.2, 1.0, 0.3), seed=6, sub=2, rough=0.1, floor=0.0)
        for k, (x, y) in enumerate(((-0.08, -0.04), (0.08, -0.05), (0.0, 0.09))):
            sph(p, FOSSIL, 0.085, loc=(x, y, 0.09), scale=(0.8, 0.8, 1.15), rot=(10 * k, 15, 0), u=16, v=10)
            tube(p, SHELL2, [(x - 0.04, y - 0.06, 0.12), (x + 0.01, y - 0.065, 0.09)], 0.004, seg=3)
    return single("SM_Egg", f)


@asset("dino_skull", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def dino_skull():
    """Stylized theropod skull: deep snout, big eye socket + window holes, teeth."""
    def f(p):
        tube(p, FOSSIL, [(-0.16, 0, 0.16), (0.0, 0, 0.15), (0.2, 0, 0.12)], [0.11, 0.09, 0.05], seg=12, scale=(1.0, 0.75))
        rock(p, FOSSIL, 0.12, loc=(-0.14, 0, 0.16), scale=(1.0, 0.85, 1.0), seed=2, sub=2, rough=0.06, floor=-2)
        for sy in (1, -1):
            sph(p, SOCKET, 0.04, loc=(-0.12, sy * 0.072, 0.2), u=10, v=8)
            sph(p, SOCKET, 0.03, loc=(0.02, sy * 0.065, 0.16), scale=(1.4, 1.0, 0.8), u=8, v=6)
            sph(p, SOCKET, 0.012, loc=(0.2, sy * 0.03, 0.13), u=6, v=4)
        tube(p, FOSSIL, [(-0.16, 0, 0.06), (0.0, 0, 0.06), (0.16, 0, 0.08)], [0.05, 0.04, 0.025], seg=8, scale=(1.0, 0.7))
        x = -0.06
        while x < 0.18:
            for sy in (1, -1):
                cyl(p, TOOTH, 0.01, 0.045, loc=(x, sy * 0.04, 0.09), r2=0.0, rot=(180, 0, 0), seg=5)
            x += 0.035
    return single("SM_DinoSkull", f)


@asset("mammal_skull", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def mammal_skull():
    """Ice-age mammal skull (cave bear / big cat): domed braincase, cheekbones,
    big canines."""
    def f(p):
        sph(p, FOSSIL, 0.13, loc=(-0.06, 0, 0.14), scale=(1.3, 0.9, 0.85), u=18, v=12)
        tube(p, FOSSIL, [(0.0, 0, 0.12), (0.16, 0, 0.1)], [0.08, 0.055], seg=12, scale=(1.0, 0.85))
        for sy in (1, -1):
            tube(p, FOSSIL, [(-0.02, sy * 0.06, 0.12), (0.06, sy * 0.11, 0.11), (0.1, sy * 0.06, 0.1)], 0.018, seg=6)  # zygomatic arch
            sph(p, SOCKET, 0.035, loc=(0.06, sy * 0.06, 0.15), u=8, v=6)
            cyl(p, TOOTH, 0.016, 0.09, loc=(0.15, sy * 0.03, 0.05), r2=0.002, rot=(180, -10, 0), seg=6)
        sph(p, SOCKET, 0.02, loc=(0.2, 0, 0.11), u=6, v=4)
        tube(p, FOSSIL, [(-0.08, 0, 0.04), (0.14, 0, 0.04)], [0.03, 0.022], seg=8, scale=(1.0, 1.8))
    return single("SM_MammalSkull", f)


@asset("vertebra", tier="small", group="finds", res=256, sculpt=BONE_SCULPT)
def vertebra():
    def f(p):
        cyl(p, FOSSIL, 0.08, 0.1, loc=(0, 0, 0.08), rot=(0, 90, 0), seg=14)
        prism(p, FOSSIL, [(-0.03, 0), (0.03, 0), (0.04, 0.2), (-0.02, 0.22)], 0.03, plane="XZ", z=-0.015, loc=(0, 0, 0.14))
        for sy in (1, -1):
            tube(p, FOSSIL, [(0, sy * 0.06, 0.12), (0, sy * 0.17, 0.15)], [0.02, 0.01], seg=5)
        sph(p, SOCKET, 0.025, loc=(0, 0, 0.165), u=6, v=4)
    return single("SM_Vertebra", f)


# -------------------------------------------------------------- big nodes ----
@asset("node_big_sand", tier="item", group="nodes", res=512)
def node_big_sand():
    """Rare GIANT DUNE MOUND: a big wind-blown mound with bone ends poking out and
    excavation flags - takes a long dig with a good shovel."""
    def f(p):
        rock(p, SAND, 1.5, loc=(0, 0, 0.0), scale=(1.0, 0.85, 0.42), seed=17, sub=3, rough=0.12, floor=0.0)
        rock(p, SAND2, 0.8, loc=(0.6, 0.3, 0.2), scale=(1.0, 0.9, 0.5), seed=18, sub=2, rough=0.12, floor=0.0)
        tube(p, FBONE, [(-0.6, -0.4, 0.45), (-0.2, -0.6, 0.55)], [0.08, 0.06], seg=8)
        sph(p, FBONE, 0.1, loc=(-0.62, -0.38, 0.45), u=8, v=6)
        spiral(p, [SHELL2], turns=1.8, a=0.012, growth=0.25, tube_k=0.4, ppt=12, center=(0.4, -0.55, 0.42), seg=6)
        for k, (x, y) in enumerate(((-1.1, 0.2), (0.9, -0.6), (0.2, 0.95))):
            cyl(p, WOOD_LT, 0.012, 0.6, loc=(x, y, 0.45), seg=5)
            prism(p, (CORAL, YELLOW, CORAL)[k], [(0, 0), (0.18, -0.06), (0, -0.12)], 0.006, plane="XZ", loc=(x, y, 0.75))
    return single("SM_NodeBigSand", f, smooth=50)


@asset("node_big_rock", tier="item", group="nodes", res=512, sculpt=ROCK_SCULPT)
def node_big_rock():
    """Rare FOSSIL BOULDER: a car-sized block with a huge bone weathering out of it."""
    def f(p):
        rock(p, ROCK, 1.2, loc=(0, 0, 0.75), scale=(1.15, 0.95, 0.8), seed=23, sub=3, rough=0.22, floor=-0.55)
        rock(p, ROCK_LT, 0.6, loc=(0.9, 0.5, 0.35), seed=24, sub=2, rough=0.25, floor=-0.5)
        tube(p, FBONE, [(-0.7, -1.0, 1.0), (0.0, -1.12, 1.2), (0.6, -0.95, 1.05)], [0.14, 0.11, 0.13], seg=10)
        for x, z in ((-0.72, 1.0), (0.62, 1.05)):
            sph(p, FBONE, 0.17, loc=(x, -0.98, z), u=10, v=8)
        for k in range(5):  # chisel marks
            rbox(p, ROCK_DK, (0.12, 0.02, 0.02), loc=(-0.3 + k * 0.18, -1.08, 0.7), rot=(0, 30, 0), r=0.005)
    return single("SM_NodeBigRock", f, smooth=45)


@asset("node_bonebed", tier="item", group="nodes", res=512, sculpt=ROCK_SCULPT)
def node_bonebed():
    """Rare BONE BED: a tilted slate ledge crowded with jumbled bones - only the best
    pickaxe gets through it."""
    def f(p):
        for k in range(4):
            slab(p, SLATE[k % 5], (1.5 - k * 0.15, 1.1 - k * 0.1, 0.15), loc=(0, 0, 0.15 + k * 0.28), rot=(0, 6 * (k % 2 * 2 - 1), 8), seed=k + 3, rough=0.04, cuts=3)
        rnd = random.Random(11)
        for k in range(9):
            x, y = rnd.uniform(-1.0, 1.0), rnd.uniform(-0.7, 0.4)
            a = rnd.uniform(0, TAU)
            tube(p, FBONE, [(x, y, 1.15), (x + 0.35 * math.cos(a), y + 0.35 * math.sin(a), 1.2)], [0.06, 0.05], seg=7)
            sph(p, FBONE, 0.075, loc=(x, y, 1.15), u=8, v=6)
    return single("SM_NodeBoneBed", f, smooth=40)


# --------------------------------------------------------- land skeletons ---
def land_skeleton(name, L, hip_h, skull_len, s, mat, biped=True, arm_len=0.4, sail=0.0, teeth=0.05, thumb=False, crest=False):
    """Mounted dinosaur / synapsid skeleton facing +X, hips over the origin."""
    root = empty(name)

    def vert(p, x, z, r, spine=1.0):
        cyl(p, mat, r, r * 1.05, loc=(x, 0, z), rot=(0, 90, 0), seg=10, r2=r * 0.88)
        prism(p, mat, [(-r * 0.22, 0), (r * 0.22, 0), (r * 0.3, r * 1.6 * spine), (-r * 0.1, r * 1.8 * spine)], r * 0.32, z=-r * 0.16, plane="XZ", loc=(x, 0, z + r * 0.5))
        for sy in (1, -1):
            tube(p, mat, [(x, sy * r * 0.6, z + r * 0.2), (x, sy * r * 1.4, z + r * 0.35)], [r * 0.18, r * 0.07], seg=5)

    shoulder_x = L * 0.22
    def spine_z(x):
        return hip_h + (0.06 * s if biped else 0.0) + 0.04 * math.sin(x * 2.0)

    # Back (dorsal vertebrae, optional sail of very tall spines)
    p = Part()
    x = -0.05 * s
    while x <= shoulder_x:
        vert(p, x, spine_z(x), 0.09 * s)
        if sail > 0:
            h = sail * math.sin(math.pi * min(1.0, max(0.0, (x + 0.05 * s) / (shoulder_x + 0.05 * s))))
            tube(p, mat, [(x, 0, spine_z(x) + 0.12 * s), (x - 0.02 * s, 0, spine_z(x) + 0.12 * s + h)], [0.025 * s, 0.01 * s], seg=5)
        x += 0.17 * s
    finish(p, "Back", root)
    # Ribs
    p = Part()
    x = 0.05 * s
    body_r = 0.38 * s
    while x <= shoulder_x - 0.05 * s:
        z = spine_z(x)
        for sy in (1, -1):
            tube(p, mat, [(x, sy * 0.07 * s, z), (x - 0.03 * s, sy * body_r * 0.95, z - 0.2 * s), (x - 0.05 * s, sy * body_r, z - body_r * 0.95),
                          (x - 0.07 * s, sy * body_r * 0.5, z - body_r * 1.55)], [0.035 * s, 0.03 * s, 0.025 * s, 0.012 * s], seg=6)
        x += 0.16 * s
    finish(p, "Ribs", root)
    # Neck (S-curve up to the head)
    p = Part()
    nx0 = shoulder_x + 0.12 * s
    neck_pts = []
    for k in range(6 if biped else 5):
        t = k / 5.0
        xx = nx0 + t * (0.55 * s if biped else 0.4 * s)
        zz = spine_z(shoulder_x) + math.sin(t * math.pi * 0.6) * (0.35 * s if biped else 0.12 * s)
        vert(p, xx, zz, 0.075 * s, spine=0.6)
        neck_pts.append((xx, zz))
    finish(p, "Neck", root)
    hx, hz = neck_pts[-1]
    hx += 0.12 * s
    # Skull
    p = Part()
    tube(p, mat, [(hx, 0, hz), (hx + skull_len * 0.5, 0, hz - 0.04 * s), (hx + skull_len, 0, hz - 0.1 * s)], [0.2 * s, 0.15 * s, 0.07 * s], seg=12, scale=(1.0, 0.7))
    rock(p, mat, 0.2 * s, loc=(hx + 0.05 * s, 0, hz + 0.02 * s), scale=(1.1, 0.8, 1.0), seed=5, sub=2, rough=0.05, floor=-2)
    for sy in (1, -1):
        sph(p, SOCKET, 0.07 * s, loc=(hx + 0.12 * s, sy * 0.13 * s, hz + 0.06 * s), u=10, v=8)
        sph(p, SOCKET, 0.06 * s, loc=(hx + skull_len * 0.45, sy * 0.11 * s, hz), scale=(1.5, 1.0, 0.8), u=10, v=8)  # antorbital window
        sph(p, SOCKET, 0.025 * s, loc=(hx + skull_len * 0.9, sy * 0.05 * s, hz - 0.06 * s), u=6, v=4)
    if crest:
        prism(p, mat, [(0, 0), (0.3 * s, 0), (0.1 * s, 0.14 * s)], 0.03 * s, z=-0.015 * s, plane="XZ", loc=(hx + 0.1 * s, 0, hz + 0.14 * s))
    if teeth > 0:
        tx = hx + 0.25 * s
        while tx < hx + skull_len * 0.95:
            for sy in (1, -1):
                cyl(p, TOOTH, teeth * 0.4, teeth * 2.0, loc=(tx, sy * 0.06 * s, hz - 0.13 * s), r2=0.0, rot=(180, 0, 0), seg=5)
            tx += teeth * 2.5
    finish(p, "Skull", root)
    # Jaw
    p = Part()
    jz = hz - 0.2 * s
    tube(p, mat, [(hx, 0, jz + 0.05 * s), (hx + skull_len * 0.55, 0, jz - 0.04 * s), (hx + skull_len * 0.9, 0, jz - 0.06 * s)], [0.09 * s, 0.07 * s, 0.03 * s], seg=10, scale=(1.0, 0.75))
    if teeth > 0:
        tx = hx + 0.25 * s
        while tx < hx + skull_len * 0.85:
            for sy in (1, -1):
                cyl(p, TOOTH, teeth * 0.35, teeth * 1.6, loc=(tx, sy * 0.05 * s, jz + 0.03 * s), r2=0.0, seg=5)
            tx += teeth * 2.5
    finish(p, "Jaw", root)
    # Arms (forelimbs)
    p = Part()
    sz = spine_z(shoulder_x) - 0.15 * s
    for sy in (1, -1):
        sh = Vector((shoulder_x, sy * 0.26 * s, sz))
        if biped:
            el = sh + Vector((0.08 * s, sy * 0.03 * s, -arm_len * 0.5 * s))
            wr = el + Vector((0.12 * s, 0, -arm_len * 0.35 * s))
        else:  # sprawling quadruped front leg down to the ground
            el = sh + Vector((0.05 * s, sy * 0.22 * s, -sz * 0.45))
            wr = Vector((sh.x + 0.1 * s, sy * 0.42 * s, 0.08 * s))
        tube(p, mat, [sh, el], [0.05 * s, 0.04 * s], seg=8)
        tube(p, mat, [el, wr], [0.04 * s, 0.032 * s], seg=8)
        sph(p, mat, 0.05 * s, loc=el, u=8, v=6)
        for k in range(3 if biped else 4):
            a = math.radians(-25 + k * 25)
            tip = wr + Vector((0.12 * s * math.cos(a), sy * 0.06 * s * math.sin(a), -0.05 * s if biped else 0.0))
            tube(p, mat, [wr, tip], [0.018 * s, 0.006 * s], seg=5)
        if thumb:  # Iguanodon's famous conical thumb spike
            cyl(p, mat, 0.035 * s, 0.14 * s, loc=wr + Vector((0.02 * s, sy * 0.05 * s, 0.07 * s)), r2=0.0, seg=8)
    # scapulae
    for sy in (1, -1):
        tube(p, mat, [(shoulder_x - 0.2 * s, sy * 0.28 * s, spine_z(shoulder_x) + 0.02 * s), (shoulder_x, sy * 0.28 * s, sz)], [0.06 * s, 0.04 * s], seg=6, scale=(1.0, 0.4))
    finish(p, "Arms", root)
    # Legs (pelvis + hind limbs)
    p = Part()
    hz0 = spine_z(0)
    rock(p, mat, 0.18 * s, loc=(0, 0, hz0 - 0.05 * s), scale=(1.6, 0.9, 0.7), seed=8, sub=2, rough=0.06, floor=-2)  # ilium
    tube(p, mat, [(0.0, 0, hz0 - 0.1 * s), (0.15 * s, 0, hz0 - 0.55 * s), (0.25 * s, 0, hz0 - 0.62 * s)], [0.05 * s, 0.035 * s, 0.05 * s], seg=7)  # pubic boot
    tube(p, mat, [(-0.05 * s, 0, hz0 - 0.1 * s), (-0.2 * s, 0, hz0 - 0.5 * s)], [0.045 * s, 0.03 * s], seg=7)  # ischium
    for sy in (1, -1):
        hip = Vector((0.0, sy * 0.22 * s, hz0 - 0.12 * s))
        if biped:
            knee = Vector((0.18 * s, sy * 0.26 * s, hip_h * 0.52))
            ank = Vector((-0.05 * s, sy * 0.26 * s, hip_h * 0.16))
            foot = Vector((0.08 * s, sy * 0.26 * s, 0.04 * s))
        else:
            knee = Vector((0.12 * s, sy * 0.42 * s, hip_h * 0.45))
            ank = Vector((0.05 * s, sy * 0.5 * s, 0.12 * s))
            foot = Vector((0.12 * s, sy * 0.52 * s, 0.04 * s))
        tube(p, mat, [hip, knee], [0.08 * s, 0.06 * s], seg=10)
        tube(p, mat, [knee, ank], [0.06 * s, 0.045 * s], seg=10)
        tube(p, mat, [ank, foot], [0.04 * s, 0.03 * s], seg=8)
        sph(p, mat, 0.07 * s, loc=knee, u=8, v=6)
        for k in range(3):
            a = math.radians(-22 + k * 22)
            tip = foot + Vector((0.18 * s * math.cos(a), sy * 0.12 * s * math.sin(a), -0.02 * s))
            tube(p, mat, [foot, tip], [0.025 * s, 0.008 * s], seg=5)
    finish(p, "Legs", root)
    # Tail
    p = Part()
    n = 14
    tail_len = L * 0.5
    for i in range(n):
        u = (i + 1) / n
        xx = -0.1 * s - u * tail_len
        zz = spine_z(0) - u * 0.25 * s * (1.0 if not biped else 0.6) + (math.sin(u * math.pi) * 0.1 * s if biped else 0.0)
        if not biped:
            zz = max(0.12 * s, zz - u * hip_h * 0.6)
        vert(p, xx, zz, 0.085 * s * (1 - u * 0.75), spine=1.0 - u * 0.7)
    finish(p, "Tail", root)
    # Mount (steel armature)
    p = Part()
    for xx in (-0.1 * s, shoulder_x, -tail_len * 0.5):
        hz = spine_z(0) - 0.08 * s if xx != -tail_len * 0.5 else spine_z(0) - 0.2 * s
        cyl(p, METAL_DK, 0.03, hz, loc=(xx, 0, hz / 2), seg=10)
        cyl(p, METAL_DK, 0.2, 0.045, loc=(xx, 0, 0.022), seg=16)
    finish(p, "Mount", root)
    return root


@asset("skeleton_trex", tier="hero", res=1024, group="skeletons", sculpt=BONE_SCULPT)
def skeleton_trex():
    """Tyrannosaurus rex: huge deep skull, tiny two-fingered arms, horizontal back
    balanced over the hips by a long tail (not the old upright 'kangaroo' pose)."""
    return land_skeleton("SkeletonTRex", L=4.8, hip_h=1.6, skull_len=0.95, s=1.25, mat=FBONE, biped=True, arm_len=0.35, teeth=0.045)


@asset("skeleton_iguanodon", tier="hero", res=1024, group="skeletons", sculpt=BONE_SCULPT)
def skeleton_iguanodon():
    """Iguanodon: long-armed plant eater with thumb spikes (once mistaken for a horn
    on its nose!), beaked skull without big front teeth."""
    return land_skeleton("SkeletonIguanodon", L=4.6, hip_h=1.45, skull_len=0.7, s=1.15, mat=BONE, biped=True, arm_len=0.9, teeth=0.0, thumb=True, crest=False)


@asset("skeleton_dimetrodon", tier="hero", res=1024, group="skeletons", sculpt=BONE_SCULPT)
def skeleton_dimetrodon():
    """Dimetrodon: a sprawling, sail-backed synapsid - closer to mammals than to
    dinosaurs, and extinct 40 million years before the first dinosaur."""
    return land_skeleton("SkeletonDimetrodon", L=3.4, hip_h=0.55, skull_len=0.45, s=0.95, mat=APEX, biped=False, sail=1.0, teeth=0.03)
