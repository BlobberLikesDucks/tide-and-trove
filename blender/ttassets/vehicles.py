"""Traffic: four car types, a city bus, a school bus and the road tunnels at both
ends of Ammonite Bay's street (vehicle-artist + environment-artist + stylized-style).

Conventions (the game drives these):
  * vehicles face Blender +X (Godot +X); the kerb / passenger side is Blender -Y
    (Godot +Z), which is where passengers get in and out;
  * wheels are separate objects Wheel_FL / Wheel_FR / Wheel_RL / Wheel_RR with their
    origin on the axle so Godot can spin them (rotation about local Y);
  * buses have a separate "Door" object (pivot at the hinge side) that Godot slides
    open, plus "SeatAnchor" empties are not needed - passengers just walk in;
  * body colour is the tint material "CarPaint" so every car gets a random colour.
Chunky, rounded, slightly squashed toy-like proportions to match the cozy style.
"""
import random

import bmesh

from tt.geo import *  # noqa
from tt.mats import *  # noqa
from tt.pipe import asset, single, finish, empty
from tt.geo import _xf, _merge

PAINT = M("CarPaint", "#e05a4a", rough=0.45, kind="tint")
TYRE = M("Tyre", "#26272c", rough=0.9)
HUB = M("Hubcap", "#c9ced4", rough=0.35, metal=0.6)
BUMPER = M("Bumper", "#3a3d44", rough=0.6)
SCHOOL_Y = M("SchoolYellow", "#f4b82a")
BUS_TEAL = M("BusTeal", "#2f9c9a")
BUS_CREAM = M("BusCream", "#f6ecd2")
WIN_DK = M("WindowDark", "#2c3e4f", rough=0.15)
# flat, unbaked: Godot draws TunnelVoid as unshaded black, SignCream as one clean colour
VOID = M("TunnelVoid", "#000000", rough=1.0, kind="special")
SIGN_CREAM = M("SignCream", "#fff3d6", kind="special")


def _wheels(root, xs, track, r, w=0.24):
    for name, x, y in (("Wheel_FL", xs[0], track), ("Wheel_FR", xs[0], -track), ("Wheel_RL", xs[1], track), ("Wheel_RR", xs[1], -track)):
        p = Part()
        cyl(p, TYRE, r, w, rot=(90, 0, 0), seg=18)
        cyl(p, TYRE, r * 0.92, w * 1.06, rot=(90, 0, 0), seg=18)
        cyl(p, HUB, r * 0.55, w * 1.1, rot=(90, 0, 0), seg=14)
        for k in range(5):  # lug nuts make the spin readable
            a = k / 5 * TAU
            sph(p, BUMPER, r * 0.07, loc=(math.cos(a) * r * 0.32, (w * 0.56) * (1 if y > 0 else -1), math.sin(a) * r * 0.32), u=6, v=4)
        finish(p, name, root, loc=(x, y, r), smooth=40)


def _lights(p, L, H0, W, front=True, rear=True):
    for sy in (1, -1):
        if front:
            sph(p, GLOW_WARM, 0.11, loc=(L / 2 - 0.02, sy * (W / 2 - 0.25), H0), scale=(0.4, 1.0, 0.8), u=12, v=8)
        if rear:
            rbox(p, GLOW_RED, (0.05, 0.22, 0.14), loc=(-L / 2 + 0.01, sy * (W / 2 - 0.22), H0 + 0.05), r=0.03)


def _car(name, L, W, H, cabin, hood=0.9, trunk=0.6, wheel_r=0.34, kind="hatch"):
    """Generic rounded car: lower body (CarPaint), glasshouse, bumpers, lights."""
    root = empty(name)
    p = Part()
    body_h = H * 0.48
    z0 = wheel_r * 0.85
    rbox(p, PAINT, (L, W, body_h), loc=(0, 0, z0 + body_h / 2), r=0.16, seg=3)
    # cabin
    cx0, cx1 = cabin
    ch = H - z0 - body_h
    cl = cx1 - cx0
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    for v in t.verts:  # tapered greenhouse: narrower roof, raked windscreen
        top = v.co.z > 0
        v.co.x = v.co.x * cl
        if top:
            v.co.x = v.co.x * 0.78 - cl * 0.06 * (1 if v.co.x > 0 else -0.2)
        v.co.y = v.co.y * W * (0.86 if top else 0.96)
        v.co.z = v.co.z * ch
    bmesh.ops.bevel(t, geom=list(t.verts) + list(t.edges), offset=0.12, segments=3, affect="EDGES", profile=0.5, clamp_overlap=True)
    _xf(t, loc=((cx0 + cx1) / 2, 0, z0 + body_h + ch / 2 - 0.02))
    _merge(p, t, PAINT)
    # windows: dark glass inset on the four cabin sides
    zc = z0 + body_h + ch * 0.48
    for sy in (1, -1):
        rbox(p, WIN_DK, (cl * 0.74, 0.04, ch * 0.62), loc=((cx0 + cx1) / 2 - cl * 0.02, sy * W * 0.455, zc), r=0.05)
        rbox(p, PAINT, (0.06, 0.05, ch * 0.66), loc=((cx0 + cx1) / 2 - cl * 0.02, sy * W * 0.458, zc), r=0.02)  # B-pillar
    rbox(p, WIN_DK, (0.05, W * 0.74, ch * 0.6), loc=(cx1 - 0.08, 0, zc), rot=(0, -28, 0), r=0.05)
    rbox(p, WIN_DK, (0.05, W * 0.74, ch * 0.56), loc=(cx0 + 0.06, 0, zc), rot=(0, 22, 0), r=0.05)
    # bumpers, grille, wheel arches, mirrors, handles
    for sx in (1, -1):
        rbox(p, BUMPER, (0.22, W * 1.02, 0.2), loc=(sx * (L / 2 + 0.02), 0, z0 + 0.1), r=0.08)
    rbox(p, BUMPER, (0.04, W * 0.42, 0.16), loc=(L / 2 + 0.01, 0, z0 + body_h * 0.55), r=0.03)
    for sx in (1, -1):
        for sy in (1, -1):
            cyl(p, BUMPER, wheel_r * 1.18, 0.06, loc=(sx * (L / 2 - hood * 0.55 if sx > 0 else L / 2 - trunk * 0.7), sy * (W / 2 - 0.0), wheel_r), rot=(90, 0, 0), seg=20)
    for sy in (1, -1):
        rbox(p, PAINT, (0.12, 0.16, 0.1), loc=(cx1 - 0.1, sy * (W / 2 + 0.06), z0 + body_h + 0.05), r=0.03)
        for x in ((cx0 + cx1) / 2 + cl * 0.18, (cx0 + cx1) / 2 - cl * 0.22):
            rbox(p, BUMPER, (0.14, 0.03, 0.035), loc=(x, sy * (W / 2 + 0.01), z0 + body_h * 0.8), r=0.012)
    _lights(p, L, z0 + body_h * 0.55, W)
    rbox(p, PAPER, (0.02, 0.4, 0.12), loc=(-L / 2 - 0.1, 0, z0 + 0.25), r=0.01)  # number plate
    if kind == "pickup":
        # open bed: hollow out with dark floor + raised sides
        bx0 = -L / 2 + 0.1
        rbox(p, BUMPER, (trunk * 2.3, W * 0.86, 0.04), loc=(bx0 + trunk * 1.15, 0, z0 + body_h + 0.01), r=0.02)
        for sy in (1, -1):
            rbox(p, PAINT, (trunk * 2.3, 0.08, 0.36), loc=(bx0 + trunk * 1.15, sy * (W / 2 - 0.04), z0 + body_h + 0.18), r=0.03)
        rbox(p, PAINT, (0.08, W, 0.36), loc=(bx0 + 0.04, 0, z0 + body_h + 0.18), r=0.03)
        for k in range(3):  # a couple of crates in the bed
            rbox(p, WOOD, (0.4, 0.4, 0.3), loc=(bx0 + 0.4 + k * 0.48, (k % 2 - 0.5) * 0.5, z0 + body_h + 0.17), r=0.03)
    if kind == "van":
        rbox(p, BUMPER, (cl * 0.4, 0.03, 0.03), loc=((cx0 + cx1) / 2, -W / 2 - 0.01, z0 + body_h + ch * 0.95), r=0.01)  # sliding door rail
    if kind == "sedan":
        rbox(p, PAINT, (0.18, W * 0.8, 0.04), loc=(-L / 2 + 0.25, 0, z0 + body_h + 0.03), r=0.02)  # boot spoiler lip
    # roof rack / taxi-ish details per kind keep the silhouettes distinct
    if kind == "hatch":
        for sy in (0.3, -0.3):
            rbox(p, BUMPER, (cl * 0.6, 0.04, 0.04), loc=((cx0 + cx1) / 2 - 0.05, sy * W, H - 0.02), r=0.015)
    finish(p, "Body", root, smooth=40)
    xs = (L / 2 - hood * 0.55, -L / 2 + trunk * 0.7)
    _wheels(root, xs, W / 2 - 0.12, wheel_r)
    return root


@asset("car_hatch", tier="prop", group="traffic", col=[("box", (0, 0, 0.75), (3.6, 1.7, 1.5))])
def car_hatch():
    return _car("CarHatch", L=3.6, W=1.7, H=1.5, cabin=(-1.45, 0.75), hood=0.95, trunk=0.45, kind="hatch")


@asset("car_sedan", tier="prop", group="traffic", col=[("box", (0, 0, 0.72), (4.4, 1.8, 1.45))])
def car_sedan():
    return _car("CarSedan", L=4.4, W=1.8, H=1.45, cabin=(-1.05, 0.95), hood=1.2, trunk=0.95, kind="sedan")


@asset("car_van", tier="prop", group="traffic", col=[("box", (0, 0, 0.95), (4.6, 1.9, 1.9))])
def car_van():
    return _car("CarVan", L=4.6, W=1.9, H=1.95, cabin=(-2.05, 1.45), hood=0.85, trunk=0.35, wheel_r=0.36, kind="van")


@asset("car_pickup", tier="prop", group="traffic", col=[("box", (0, 0, 0.9), (5.0, 1.9, 1.8))])
def car_pickup():
    return _car("CarPickup", L=5.0, W=1.9, H=1.85, cabin=(-0.2, 1.25), hood=1.2, trunk=1.0, wheel_r=0.4, kind="pickup")


def _bus(name, L, W, H, body, roof, stripe, label, school=False):
    root = empty(name)
    p = Part()
    wheel_r = 0.5
    z0 = 0.42
    rbox(p, body, (L, W, H - z0), loc=(0, 0, z0 + (H - z0) / 2), r=0.22, seg=3)
    rbox(p, roof, (L - 0.4, W - 0.2, 0.14), loc=(0, 0, H + 0.04), r=0.07)
    # windows along both sides (passenger side -Y has the door gap at the front)
    nwin = int((L - 2.2) / 1.05)
    for sy in (1, -1):
        for k in range(nwin):
            x = L / 2 - 1.6 - k * 1.05
            if sy < 0 and x > L / 2 - 2.0:
                continue
            rbox(p, WIN_DK, (0.9, 0.05, 0.8), loc=(x - 0.2, sy * (W / 2 + 0.005), H - 0.75), r=0.06)
        rbox(p, stripe, (L * 0.98, 0.04, 0.16), loc=(0, sy * (W / 2 + 0.01), H - 1.35), r=0.03)
        rbox(p, stripe, (L * 0.98, 0.04, 0.08), loc=(0, sy * (W / 2 + 0.01), z0 + 0.35), r=0.02)
    # windscreen + destination board + rear window
    rbox(p, WIN_DK, (0.06, W * 0.86, 1.2), loc=(L / 2 + 0.005, 0, H - 0.95), r=0.08)
    rbox(p, DARK, (0.07, W * 0.6, 0.28), loc=(L / 2 + 0.01, 0, H - 0.2), r=0.03)
    text3d(p, YELLOW if not school else DARK, label, size=0.17, loc=(L / 2 + 0.05, 0, H - 0.2), rot=(90, 0, 90), depth=0.006, max_w=W * 0.55, max_h=0.2)
    rbox(p, WIN_DK, (0.06, W * 0.7, 0.7), loc=(-L / 2 - 0.005, 0, H - 0.8), r=0.06)
    # bumpers, lights, mirrors
    for sx in (1, -1):
        rbox(p, BUMPER, (0.24, W * 1.02, 0.28), loc=(sx * (L / 2 + 0.06), 0, z0 + 0.14), r=0.08)
    for sy in (1, -1):
        sph(p, GLOW_WARM, 0.14, loc=(L / 2 + 0.02, sy * (W / 2 - 0.3), z0 + 0.55), scale=(0.35, 1.0, 1.0), u=12, v=8)
        rbox(p, GLOW_RED, (0.05, 0.25, 0.25), loc=(-L / 2 - 0.01, sy * (W / 2 - 0.3), z0 + 0.6), r=0.04)
        tube(p, BUMPER, [(L / 2 - 0.1, sy * (W / 2), H - 0.6), (L / 2 + 0.25, sy * (W / 2 + 0.3), H - 0.55), (L / 2 + 0.3, sy * (W / 2 + 0.3), H - 0.85)], 0.03, seg=6)
        rbox(p, BUMPER, (0.08, 0.14, 0.26), loc=(L / 2 + 0.3, sy * (W / 2 + 0.3), H - 0.95), r=0.03)
    for sx in (1, -1):  # wheel arches
        for sy in (1, -1):
            cyl(p, BUMPER, wheel_r * 1.15, 0.06, loc=(sx * (L / 2 - 1.5), sy * W / 2, wheel_r), rot=(90, 0, 0), seg=20)
    if school:
        # stop-arm sign + crossing arm + flashing lights, the classic school-bus kit
        for sx in (1, -1):
            for sy in (1, -1):
                sph(p, GLOW_RED if sx > 0 else GLOW_WARM, 0.09, loc=(sx * (L / 2 - 0.2), sy * (W / 2 - 0.35), H + 0.02), u=10, v=8)
        cyl(p, RED, 0.24, 0.03, loc=(L / 2 - 2.6, W / 2 + 0.08, H - 1.2), rot=(90, 0, 0), seg=8)
        text3d(p, CREAM, "STOP", size=0.12, loc=(L / 2 - 2.6, W / 2 + 0.1, H - 1.2), rot=(90, 0, 180), depth=0.004, max_w=0.34)
        text3d(p, DARK, "SCHOOL BUS", size=0.3, loc=(0.4, -W / 2 - 0.03, H - 1.0), depth=0.01, max_w=L * 0.55, max_h=0.32)
        text3d(p, DARK, "SCHOOL BUS", size=0.3, loc=(0.4, W / 2 + 0.03, H - 1.0), rot=(90, 0, 180), depth=0.01, max_w=L * 0.55, max_h=0.32)
        rbox(p, BUMPER, (0.5, 0.3, 0.06), loc=(L / 2 + 0.25, -W / 2 + 0.2, z0 + 0.15), r=0.02)
    else:
        # route number + "AMMONITE BAY" livery + bike rack on the nose
        text3d(p, SIGN_CREAM, "AMMONITE BAY", size=0.26, loc=(-0.3, -W / 2 - 0.03, z0 + 0.95), depth=0.008, max_w=L * 0.5, max_h=0.28)
        text3d(p, SIGN_CREAM, "AMMONITE BAY", size=0.26, loc=(-0.3, W / 2 + 0.03, z0 + 0.95), rot=(90, 0, 180), depth=0.008, max_w=L * 0.5, max_h=0.28)
        for k in range(3):
            tube(p, METAL, [(L / 2 + 0.2, -0.5 + k * 0.5, z0 + 0.3), (L / 2 + 0.45, -0.5 + k * 0.5, z0 + 0.4), (L / 2 + 0.45, -0.5 + k * 0.5, z0 + 0.7)], 0.025, seg=5)
    finish(p, "Body", root, smooth=40)
    # front passenger door on the kerb side (-Y): two glass leaves on one object,
    # origin at the leading edge so Godot slides it back along -X to open.
    d = Part()
    dx0 = L / 2 - 0.35
    for k in range(2):
        rbox(d, body, (0.55, 0.06, H - z0 - 0.35), loc=(-0.3 - k * 0.56, 0, (H - z0 - 0.35) / 2), r=0.03)
        rbox(d, WIN_DK, (0.42, 0.07, (H - z0) * 0.62), loc=(-0.3 - k * 0.56, 0, (H - z0) * 0.48), r=0.04)
    finish(d, "Door", root, loc=(dx0, -W / 2 - 0.04, z0 + 0.15), smooth=30)
    # dark door well behind the leaves so the opening reads as a hole
    p = Part()
    rbox(p, CAVE_DK, (1.1, 0.05, H - z0 - 0.4), loc=(dx0 - 0.58, -W / 2 + 0.01, z0 + (H - z0 - 0.4) / 2 + 0.15), r=0.02)
    for k in range(2):  # entry steps
        rbox(p, BUMPER, (1.0, 0.3, 0.06), loc=(dx0 - 0.58, -W / 2 + 0.15 - k * 0.1, z0 - 0.05 + k * 0.22), r=0.02)
    finish(p, "DoorWell", root, smooth=30)
    _wheels(root, (L / 2 - 1.5, -L / 2 + 1.5), W / 2 - 0.2, wheel_r, w=0.34)
    return root


@asset("bus_city", tier="hero", res=1024, group="traffic", col=[("box", (0, 0, 1.5), (10.0, 2.5, 3.0))])
def bus_city():
    return _bus("BusCity", L=10.0, W=2.5, H=3.1, body=BUS_TEAL, roof=BUS_CREAM, stripe=BUS_CREAM, label="7  MUSEUM")


@asset("bus_school", tier="hero", res=1024, group="traffic", col=[("box", (0, 0, 1.45), (9.4, 2.4, 2.9))])
def bus_school():
    return _bus("BusSchool", L=9.4, W=2.4, H=2.95, body=SCHOOL_Y, roof=SCHOOL_Y, stripe=DARK, label="SCHOOL", school=True)


@asset("tunnel_portal", tier="env", res=1024, group="traffic", sculpt=dict(strength=1.0, scale=2.5),
       col=[("box", (12.0, 9.6, 6.0), (24.0, 9.0, 12.0)), ("box", (12.0, -9.6, 6.0), (24.0, 9.0, 12.0)), ("box", (12.0, 0, 9.8), (24.0, 11.0, 4.4))])
def tunnel_portal():
    """Road tunnel through a mossy headland. The portal faces Blender -X (the town);
    the bore runs 24 m along +X into darkness, so traffic appears out of / vanishes
    into the hill. Opening: 9 m wide, 6.2 m tall (fits the buses)."""
    root = empty("TunnelPortal")
    p = Part()
    # the hill: several big sculpted rock masses behind and around the portal
    rnd = random.Random(5)
    for k, (x, y, z, r, sx, sy, sz) in enumerate([
            (12, 15, 2, 9.0, 1.5, 0.9, 1.0), (12, -15, 2, 9.0, 1.5, 0.9, 1.0), (14, 0, 9.5, 8.0, 1.7, 1.6, 0.6),
            (4, 10.5, 4.5, 4.5, 1.1, 1.0, 1.2), (4, -10.5, 4.5, 4.5, 1.1, 1.0, 1.2), (20, 7, 7, 7.0, 1.2, 1.2, 1.0), (20, -7, 7, 7.0, 1.2, 1.2, 1.0)]):
        rock(p, ROCK if k % 2 else ROCK_LT, r, loc=(x, y, z), scale=(sx, sy, sz), seed=40 + k, sub=3, rough=0.22, floor=-0.35)
    # grassy cap and a few bushes on top of the headland
    for k in range(9):
        a = rnd.uniform(-1.0, 1.0)
        sph(p, LEAF if k % 2 else LEAF_DK, rnd.uniform(1.2, 2.2), loc=(rnd.uniform(6, 20), a * 11, rnd.uniform(11.5, 13.2)), scale=(1.3, 1.3, 0.7), u=12, v=8)
    finish(p, "Headland", root, smooth=50)
    p = Part()
    W, H = 9.0, 6.2
    # stone portal frame: two piers + arch voussoirs + parapet with nameplate
    for sy in (1, -1):
        rbox(p, STONE2, (1.2, 1.4, H - 1.0), loc=(0, sy * (W / 2 + 0.7), (H - 1.0) / 2), r=0.08)
        rbox(p, STONE, (1.4, 1.6, 0.3), loc=(0, sy * (W / 2 + 0.7), 0.15), r=0.05)
    n = 13
    for i in range(n + 1):
        a = math.pi * i / n
        y = math.cos(a) * (W / 2 + 0.35)
        z = (H - 1.0) + math.sin(a) * 1.6
        rbox(p, STONE if i % 2 else STONE2, (1.25, 0.75, 0.55), loc=(0, y, z), rot=(math.degrees(a) - 90, 0, 0), r=0.06)
    # spandrels: solid stone between the arch and the parapet (no gaps into the bore)
    ri, ro = W / 2 + 0.35, W / 2 + 1.4
    for sy in (1, -1):
        curve = [(sy * ri * math.cos(math.pi / 2 * i / 12), (H - 1.0) + 1.6 * math.sin(math.pi / 2 * i / 12)) for i in range(13)]
        pts = [(sy * ro, H - 1.0), (sy * ro, H + 1.1), (0.0, H + 1.1)] + curve[::-1]
        if sy < 0:
            pts = pts[::-1]
        prism(p, STONE2, pts, 0.9, plane="XZ", loc=(0.45, 0, 0), rot=(0, 0, 90))
    rbox(p, STONE2, (1.4, W + 3.0, 0.9), loc=(0, 0, H + 1.4), r=0.08)
    rbox(p, TEAL, (0.12, 4.2, 0.6), loc=(-0.72, 0, H + 1.4), r=0.04)
    # the road apron up to the mouth; everything past it is the black void
    box(p, ASPHALT, (1.3, W, 0.06), loc=(0.0, 0, 0.0))
    finish(p, "Portal", root, smooth=30)
    # sign lettering: flat (unbaked) cream so every letter is the same colour
    p = Part()
    text3d(p, SIGN_CREAM, "AMMONITE BAY", size=0.36, loc=(-0.79, 0, H + 1.4), rot=(90, 0, -90), depth=0.012, max_w=3.8, max_h=0.42)
    finish(p, "PortalSign", root, smooth=30)
    # the bore is pure black (Godot renders "TunnelVoid" unshaded): a black
    # curtain just inside the mouth hides the inside completely, and the walls,
    # ceiling and floor behind it are black too, so cars drive out of darkness.
    p = Part()
    # curtain shaped like the opening (piers + arch), its edges tucked behind the stones
    rr = W / 2 + 0.3
    arch = [(rr * math.cos(math.pi * i / 24), (H - 1.0) + 1.55 * math.sin(math.pi * i / 24)) for i in range(25)]
    prism(p, VOID, [(rr, 0.0)] + arch + [(-rr, 0.0)], 0.05, plane="XZ", loc=(0.7, 0, 0), rot=(0, 0, 90))
    for sy in (1, -1):
        box(p, VOID, (24.0, 0.4, H + 1.0), loc=(12.0, sy * (W / 2 + 0.3), (H + 1.0) / 2))
    box(p, VOID, (24.0, W + 1.0, 0.4), loc=(12.0, 0, H + 1.1))
    box(p, VOID, (24.0, W + 1.0, 0.06), loc=(12.6, 0, -0.01))
    box(p, VOID, (0.4, W + 1.0, H + 1.2), loc=(23.8, 0, H / 2))
    finish(p, "TunnelBore", root, smooth=0)
    return root
