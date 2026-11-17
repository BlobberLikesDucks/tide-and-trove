"""Stylized game characters (character-artist + character-archetypes + sculpting +
retopology + rigging + hair-groom + animation + stylized-style).

Pipeline for the shared base character (character.glb):
  1. Proportion blockout as a Skin-modifier skeleton (stylized ~5.5 heads, big hands
     and feet, round friendly shapes) -> Subdivision -> applied: an all-quad mesh
     whose rings sit exactly at the joints (3-loop pinch at elbows / knees) - the
     retopology target is built in, no poles on deformation zones.
  2. Sculpt pass: procedural form shaping (glutes, calves, chest, shoulder caps).
  3. Separate head with stylized face (large eyes, small nose), card-clump hair
     (hair-groom game path: solid clumps, dense at the roots, flow back/down).
  4. Armature with Mixamo-style names, automatic weights, normalized + limited
     to 4 influences per vertex (rigging skill), rigid binds for head gear.
  5. Material zones from dominant bone weight (Shirt / Pants / Shoe / Skin / Belt),
     clothing overlays (vest, coat) duplicated from the body and inflated so they
     inherit its weights.
  6. 14 clips keyed in Blender (tt.anims), pushed to NLA, exported as AN_* clips.

Archetypes are toggled in Godot by object name (CharVisual.ACCESSORIES) and tinted
by material name (Skin, Shirt, Pants, Shoe, Hair, Hat, Accent, Pack, Coat).
"""
import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Quaternion, Vector

from tt.geo import *  # noqa
from tt.geo import _merge, _xf  # noqa
from tt.mats import *  # noqa
from tt import anims
from tt import paint as PT
from tt import pipe
from tt.pipe import asset, finish, empty

C_COAT = M("Coat", "#c8b27a", kind="tint")
VEST_Y = M("VestYellow", "#ffd23f")
REFLECT = M("Reflective", "#e8eef2", rough=0.3)

BONES = {
    "Hips": ((0, 0, 0.94), (0, 0, 1.06), None),
    "Spine": ((0, 0, 1.06), (0, 0, 1.25), "Hips"),
    "Chest": ((0, 0, 1.25), (0, 0, 1.44), "Spine"),
    "Neck": ((0, 0, 1.44), (0, 0, 1.54), "Chest"),
    "Head": ((0, 0, 1.54), (0, 0, 1.9), "Neck"),
}
for _side, _sx in (("Left", 1), ("Right", -1)):
    BONES[_side + "Shoulder"] = ((_sx * 0.05, 0, 1.40), (_sx * 0.21, 0, 1.40), "Chest")
    BONES[_side + "Arm"] = ((_sx * 0.23, 0, 1.39), (_sx * 0.265, 0, 1.13), _side + "Shoulder")
    BONES[_side + "ForeArm"] = ((_sx * 0.265, 0, 1.13), (_sx * 0.275, -0.01, 0.885), _side + "Arm")
    BONES[_side + "Hand"] = ((_sx * 0.275, -0.01, 0.885), (_sx * 0.28, -0.035, 0.72), _side + "ForeArm")
    BONES[_side + "UpLeg"] = ((_sx * 0.10, 0, 0.91), (_sx * 0.10, 0, 0.50), "Hips")
    BONES[_side + "Leg"] = ((_sx * 0.10, 0, 0.50), (_sx * 0.10, 0.01, 0.10), _side + "UpLeg")
    BONES[_side + "Foot"] = ((_sx * 0.10, 0.01, 0.10), (_sx * 0.10, -0.14, 0.03), _side + "Leg")


# --------------------------------------------------------------- helpers ----
def _link(ob):
    pipe.SCN.collection.objects.link(ob)
    return ob


def _sel(objs, active=None):
    PT._sel(objs, active)


def skin_mesh(name, verts, edges, radii, root=0, sub=1):
    """Skin-modifier blockout -> applied quad mesh (retopology-ready rings)."""
    me = bpy.data.meshes.new(name)
    me.from_pydata([Vector(v) for v in verts], edges, [])
    ob = _link(bpy.data.objects.new(name, me))
    sk = ob.modifiers.new("Skin", "SKIN")
    sk.branch_smoothing = 0.6
    sk.use_smooth_shade = True
    layer = me.skin_vertices[0] if len(me.skin_vertices) else None
    if layer is None:
        _sel([ob])
        bpy.ops.object.skin_radii_equalize() if False else None
        layer = me.skin_vertices[0]
    for i, r in enumerate(radii):
        layer.data[i].radius = r if isinstance(r, (tuple, list)) else (r, r)
        layer.data[i].use_root = (i == root)
    if sub:
        sd = ob.modifiers.new("Sub", "SUBSURF")
        sd.levels = sub
        sd.render_levels = sub
    _sel([ob])
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(ob.data)
    bm.free()
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def _rigid(ob, bone):
    vg = ob.vertex_groups.new(name=bone)
    vg.add(list(range(len(ob.data.vertices))), 1.0, "REPLACE")


def _bind(ob, rig):
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig


def part_obj(name, build, bone, rig, parent_mat=None):
    p = Part()
    build(p)
    ob = finish(p, name)
    _rigid(ob, bone)
    _bind(ob, rig)
    return ob


# ------------------------------------------------------------------ body ----
def build_body():
    V = []
    E = []
    R = []

    def add(co, r, link=None):
        V.append(co)
        R.append(r)
        i = len(V) - 1
        if link is not None:
            E.append((link, i))
        return i

    pel = add((0, 0, 0.93), (0.18, 0.134))
    waist = add((0, 0, 1.04), (0.163, 0.12), pel)
    belly = add((0, 0, 1.15), (0.175, 0.128), waist)
    chest = add((0, 0, 1.28), (0.19, 0.134), belly)
    upc = add((0, 0, 1.38), (0.178, 0.118), chest)
    nb = add((0, 0, 1.45), (0.07, 0.066), upc)
    add((0, 0, 1.56), (0.06, 0.058), nb)
    for sx in (1, -1):
        sh = add((sx * 0.17, 0, 1.4), (0.09, 0.09), upc)
        ua = add((sx * 0.236, 0, 1.36), (0.084, 0.084), sh)
        sl = add((sx * 0.254, 0, 1.25), (0.077, 0.077), ua)
        el = add((sx * 0.266, 0, 1.13), (0.066, 0.066), sl)
        fa = add((sx * 0.271, -0.004, 1.01), (0.066, 0.062), el)
        wr = add((sx * 0.276, -0.01, 0.89), (0.05, 0.05), fa)
        pm = add((sx * 0.279, -0.024, 0.81), (0.04, 0.068), wr)
        add((sx * 0.281, -0.036, 0.73), (0.036, 0.062), pm)
        add((sx * 0.256, -0.078, 0.83), (0.028, 0.028), wr)
        hp = add((sx * 0.1, 0, 0.88), (0.11, 0.11), pel)
        th = add((sx * 0.1, 0, 0.71), (0.104, 0.104), hp)
        kn = add((sx * 0.1, 0, 0.5), (0.08, 0.08), th)
        cf = add((sx * 0.1, 0.012, 0.35), (0.084, 0.084), kn)
        sn = add((sx * 0.1, 0.01, 0.2), (0.068, 0.068), cf)
        an = add((sx * 0.1, 0.01, 0.11), (0.078, 0.078), sn)
        hl = add((sx * 0.1, 0.02, 0.06), (0.086, 0.075), an)
        add((sx * 0.1, -0.17, 0.06), (0.088, 0.066), hl)
    body = skin_mesh("SM_Char_Body", V, E, R, root=pel)
    # sculpt pass: stylized form shaping (soft, friendly, readable)
    for v in body.data.vertices:
        x, y, z = v.co
        if 0.82 < z < 1.0 and y > 0.02:  # glutes
            v.co.y += 0.025 * math.sin((z - 0.82) / 0.18 * math.pi)
        if 0.24 < z < 0.46 and y > 0.0 and abs(x) > 0.04:  # calves
            v.co.y += 0.018 * math.sin((z - 0.24) / 0.22 * math.pi)
        if 1.2 < z < 1.38 and y < -0.04 and abs(x) < 0.16:  # chest plane
            v.co.y -= 0.01 * math.sin((z - 1.2) / 0.18 * math.pi)
        if 1.33 < z < 1.45 and abs(x) > 0.13:  # shoulder caps
            v.co.z += 0.012
        if z < 0.13 and y < -0.03:  # chunky toe cap
            v.co.z += 0.012 * (1 - z / 0.13)
        if z < 0.008:
            v.co.z = 0.0
    return body


def build_armature():
    arm = bpy.data.armatures.new("ARM_Character")
    rig = _link(bpy.data.objects.new("ARM_Character", arm))
    _sel([rig])
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (h, t, par) in BONES.items():
        b = arm.edit_bones.new(name)
        b.head, b.tail = Vector(h), Vector(t)
        b.roll = 0.0
        if par:
            b.parent = arm.edit_bones[par]
            b.use_connect = False
        b.use_deform = True
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def auto_weights(mesh, rig):
    _sel([mesh, rig], rig)
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    _sel([mesh])
    bpy.ops.object.vertex_group_limit_total(limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)


def dominant(mesh):
    names = {g.index: g.name for g in mesh.vertex_groups}
    dom = []
    for v in mesh.data.vertices:
        best = max(v.groups, key=lambda g: g.weight, default=None)
        dom.append(names.get(best.group, "") if best else "")
    return dom


def zone_materials(body):
    dom = dominant(body)
    mats = [C_SHIRT, C_PANTS, C_SHOE, C_SKIN, C_BELT, C_SOLE]
    body.data.materials.clear()
    for m in mats:
        body.data.materials.append(m)
    for poly in body.data.polygons:
        c = poly.center
        votes = {}
        for vi in poly.vertices:
            votes[dom[vi]] = votes.get(dom[vi], 0) + 1
        b = max(votes, key=votes.get)
        if b in ("Spine", "Chest") or b.endswith("Shoulder"):
            idx = 0
        elif b.endswith("Arm") and not b.endswith("ForeArm"):
            idx = 0 if c.z > 1.24 else 3
        elif b in ("Neck", "Head") or b.endswith("ForeArm") or b.endswith("Hand"):
            idx = 3
        elif b.endswith("Foot") or (b.endswith("Leg") and c.z < 0.115):
            idx = 5 if c.z < 0.02 else 2
        else:  # Hips, UpLeg, Leg
            idx = 1
        if 0.995 < c.z < 1.045 and abs(c.x) < 0.17:
            idx = 4
        if b == "Neck" and c.z < 1.47:
            idx = 0
        poly.material_index = idx


def overlay(body, rig, name, pick, offset, mat, cut_front=0.0):
    """Clothing shell duplicated from body faces (inherits weights) and inflated."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    keep = set()
    for f in bm.faces:
        if pick(f.calc_center_median()):
            keep.add(f.index)
    dele = [f for f in bm.faces if f.index not in keep]
    bmesh.ops.delete(bm, geom=dele, context="FACES")
    if cut_front > 0:
        dele = [f for f in bm.faces if abs(f.calc_center_median().x) < cut_front and f.calc_center_median().y < -0.02]
        bmesh.ops.delete(bm, geom=dele, context="FACES")
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * offset
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=-0.008)
    for f in bm.faces:
        f.material_index = 0
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.clear()
    me.materials.append(mat)
    ob = _link(bpy.data.objects.new(name, me))
    for g in body.vertex_groups:
        ob.vertex_groups.new(name=g.name)
    # transfer weights from the body (nearest face interpolated)
    dt = ob.modifiers.new("dt", "DATA_TRANSFER")
    dt.object = body
    dt.use_vert_data = True
    dt.data_types_verts = {"VGROUP_WEIGHTS"}
    dt.vert_mapping = "POLYINTERP_NEAREST"
    _sel([ob])
    bpy.ops.object.datalayout_transfer(modifier="dt")
    bpy.ops.object.modifier_apply(modifier="dt")
    bpy.ops.object.vertex_group_limit_total(limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(ob.data)
    bm.free()
    for p in ob.data.polygons:
        p.use_smooth = True
    _bind(ob, rig)
    return ob


# ------------------------------------------------------------------ head ----
HEAD_C = Vector((0, 0, 1.69))


def build_head(rig):
    p = Part()
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=3, radius=0.165)
    for v in t.verts:
        x, y, z = v.co
        v.co = Vector((x * 0.95, y * 1.0, z * 1.07))
        if v.co.z < -0.02:  # jaw taper -> soft rounded chin
            k = min(1.0, (-0.02 - v.co.z) / 0.15)
            v.co.x *= 1.0 - 0.28 * k
            v.co.y *= 1.0 - 0.15 * k
            if v.co.y < 0:
                v.co.y -= 0.012 * k
        if v.co.y > 0.06:  # cranium back
            v.co.y *= 1.04
        if v.co.y < -0.12 and abs(v.co.z) < 0.06:  # flatten face plane slightly
            v.co.y *= 0.97
    _xf(t, loc=HEAD_C)
    _merge(p, t, C_SKIN)
    cyl(p, C_SKIN, 0.052, 0.1, loc=(0, 0.005, 1.52), seg=12)  # neck plug
    for sx in (1, -1):
        sph(p, C_WHITE, 0.036, loc=(sx * 0.06, -0.135, 1.705), scale=(0.95, 0.5, 1.2), u=14, v=10)
        sph(p, C_EYE, 0.024, loc=(sx * 0.06, -0.152, 1.7), scale=(1.0, 0.45, 1.15), u=12, v=8)
        sph(p, C_WHITE, 0.008, loc=(sx * 0.052, -0.165, 1.715), u=6, v=4)
        tube(p, C_HAIR, [(sx * 0.03, -0.15, 1.765), (sx * 0.06, -0.153, 1.775), (sx * 0.09, -0.145, 1.768)], [0.009, 0.011, 0.007], seg=5)
        sph(p, C_SKIN, 0.036, loc=(sx * 0.155, 0.0, 1.69), scale=(0.45, 0.8, 1.15), u=10, v=8)
        sph(p, C_BLUSH, 0.024, loc=(sx * 0.092, -0.128, 1.645), scale=(1.0, 0.35, 0.7), u=10, v=6)
    sph(p, C_SKIN, 0.024, loc=(0, -0.168, 1.66), scale=(0.9, 1.0, 1.0), u=10, v=8)
    tube(p, C_MOUTH, [(-0.034, -0.153, 1.618), (-0.012, -0.161, 1.61), (0.012, -0.161, 1.61), (0.034, -0.153, 1.618)], 0.0065, seg=5)
    ob = finish(p, "SM_Char_Head")
    _rigid(ob, "Head")
    _bind(ob, rig)
    return ob


def _clump(p, mat, root, tip, w, bend=(0, 0, 0), thick=0.35):
    """One hair-card clump: tapered, slightly flattened, curved tube."""
    pts = curve_pts(root, tip, bend, 5)
    tube(p, mat, pts, [w, w * 0.85, w * 0.65, w * 0.4, w * 0.08], seg=6, scale=(1.0, thick))


def _scalp_dir(theta, phi):
    return Vector((math.sin(phi) * math.sin(theta), math.sin(phi) * math.cos(theta), math.cos(phi)))


def build_hair(rig, name="SM_Char_Hair", style="short"):
    p = Part()
    # cap shell (density at the roots: no bald patches at the hairline)
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=3, radius=0.172)
    kill = [v for v in t.verts if v.co.z < -0.035 or (v.co.y < -0.09 and v.co.z < 0.1) or (v.co.y < 0.0 and v.co.z < 0.0)
            or (style == "sides" and v.co.z > 0.06)]
    bmesh.ops.delete(t, geom=kill, context="VERTS")
    # sits clear of the head everywhere (head radii 0.157/0.165/0.177) so no scalp shows through
    _xf(t, loc=HEAD_C + Vector((0, 0.004, 0.012)), scale=(1.0, 1.035, 1.06))
    _merge(p, t, C_HAIR)
    c = HEAD_C + Vector((0, 0.01, 0.02))
    if style == "short":
        for k in range(14):  # flow back and down from the crown
            th = math.pi + (k - 6.5) / 6.5 * 2.2
            root = c + _scalp_dir(th, 0.35) * 0.17
            tip = c + _scalp_dir(th, 1.25) * 0.2 + Vector((0, 0.0, -0.06))
            _clump(p, C_HAIR, root, tip, 0.05, bend=(0, 0, 0.03))
        for k in range(4):  # fringe swept to one side
            x = -0.08 + k * 0.05
            _clump(p, C_HAIR, (x, -0.12, 1.83), (x + 0.05, -0.17, 1.76), 0.042, bend=(0, -0.02, 0.01))
        for sx in (1, -1):  # sideburns
            _clump(p, C_HAIR, (sx * 0.145, -0.04, 1.75), (sx * 0.15, -0.05, 1.66), 0.028)
    elif style == "sides":  # worn under hats: no crown volume, only nape + sides, kept
        for k in range(10):  # inside every hat's brim radius (>= 0.175) so nothing pokes out
            th = math.pi + (k - 4.5) / 4.5 * 1.9
            root = c + _scalp_dir(th, 1.45) * 0.174   # below every hat's band (z < 1.73)
            tip = c + _scalp_dir(th, 1.85) * 0.18 + Vector((0, 0.0, -0.03))
            _clump(p, C_HAIR, root, tip, 0.04, bend=(0, 0, 0.004), thick=0.34)
    elif style == "long":
        for k in range(16):
            th = math.pi + (k - 7.5) / 7.5 * 2.6
            root = c + _scalp_dir(th, 0.5) * 0.17
            tip = c + _scalp_dir(th, 1.45) * 0.2 + Vector((0, 0.04, -0.3))
            _clump(p, C_HAIR, root, tip, 0.06, bend=(0, 0.02, 0.02))
    ob = finish(p, name)
    _rigid(ob, "Head")
    _bind(ob, rig)
    return ob


# ----------------------------------------------------------- accessories ----
HT = 1.885


def build_accessories(rig, body):
    acc = {}

    def hat_safari(p):
        lathe(p, C_HAT, [(0.0, HT), (0.2, HT), (0.29, HT - 0.015), (0.31, HT - 0.035), (0.31, HT - 0.045), (0.27, HT - 0.025), (0.17, HT - 0.012), (0.0, HT - 0.01)], seg=28)
        lathe(p, C_HAT, [(0.175, HT - 0.02), (0.172, HT + 0.06), (0.158, HT + 0.12), (0.11, HT + 0.15), (0.0, HT + 0.155)], seg=24)
        cyl(p, C_ACC, 0.177, 0.038, loc=(0, 0, HT + 0.008), seg=24)
    acc["Hat_Safari"] = ("Head", hat_safari)

    def hat_cap(p):
        sph(p, C_HAT, 0.194, loc=(0, 0.008, 1.712), scale=(1.0, 1.03, 0.92), u=20, v=12, hemi=True)
        rbox(p, C_HAT, (0.23, 0.18, 0.024), loc=(0, -0.235, 1.735), rot=(-10, 0, 0), r=0.01)
        sph(p, C_HAT, 0.024, loc=(0, 0.01, 1.89), u=8, v=6)
        for k in range(6):
            a = k / 6 * TAU
            tube(p, C_ACC, [(0, 0.008, 1.89), (0.165 * math.cos(a), 0.165 * math.sin(a) + 0.008, 1.79)], 0.004, seg=4)
    acc["Hat_Cap"] = ("Head", hat_cap)

    def hat_fedora(p):
        lathe(p, C_HAT, [(0.0, HT - 0.01), (0.25, HT - 0.01), (0.27, HT + 0.012), (0.25, HT), (0.0, HT)], seg=28, scale=(1.0, 0.92, 1.0))
        lathe(p, C_HAT, [(0.16, HT), (0.155, HT + 0.08), (0.135, HT + 0.14), (0.06, HT + 0.12), (0.0, HT + 0.14)], seg=24, scale=(1.0, 0.85, 1.0))
        cyl(p, C_ACC, 0.162, 0.042, loc=(0, 0, HT + 0.025), seg=24, scale=(1.0, 0.86, 1.0))
    acc["Hat_Fedora"] = ("Head", hat_fedora)

    def hat_top(p):
        cyl(p, C_HAT, 0.27, 0.022, loc=(0, 0, HT + 0.0), seg=28)
        lathe(p, C_HAT, [(0.135, HT), (0.13, HT + 0.18), (0.145, HT + 0.34), (0.0, HT + 0.34)], seg=24)
        cyl(p, C_ACC, 0.138, 0.05, loc=(0, 0, HT + 0.045), seg=24)
    acc["Hat_Top"] = ("Head", hat_top)

    def sunglasses(p):
        for sx in (1, -1):
            rbox(p, C_ACC, (0.1, 0.02, 0.064), loc=(sx * 0.064, -0.17, 1.705), r=0.02)
            rbox(p, C_ACC, (0.012, 0.16, 0.012), loc=(sx * 0.128, -0.09, 1.72), r=0.004)
        rbox(p, C_ACC, (0.05, 0.012, 0.012), loc=(0, -0.175, 1.718), r=0.004)
    acc["Sunglasses"] = ("Head", sunglasses)

    def glasses(p):
        for sx in (1, -1):
            tube(p, C_ACC, [(sx * 0.062 + 0.046 * math.cos(k / 14 * TAU), -0.17, 1.703 + 0.046 * math.sin(k / 14 * TAU)) for k in range(15)], 0.006, seg=5, cap=False)
            rbox(p, C_ACC, (0.008, 0.15, 0.008), loc=(sx * 0.115, -0.095, 1.713), r=0.003)
        rbox(p, C_ACC, (0.035, 0.008, 0.008), loc=(0, -0.172, 1.713), r=0.003)
    acc["Glasses"] = ("Head", glasses)

    def hair_bun(p):
        sph(p, C_HAIR, 0.075, loc=(0, 0.09, 1.86), u=14, v=10)
        cyl(p, C_ACC, 0.052, 0.022, loc=(0, 0.07, 1.825), rot=(30, 0, 0), seg=14)
    acc["Hair_Bun"] = ("Head", hair_bun)

    def balaclava(p):
        """Knitted ski mask (shoplifters): a shell over the whole head and neck
        with one wide eye slit; ribbed rims around the slit and the neck."""
        t = bmesh.new()
        bmesh.ops.create_icosphere(t, subdivisions=4, radius=0.176)
        slit = [v for v in t.verts if v.co.y < -0.06 and -0.012 < v.co.z * 1.08 < 0.05 and abs(v.co.x) < 0.118]
        bmesh.ops.delete(t, geom=slit, context="VERTS")
        _xf(t, loc=HEAD_C + Vector((0, -0.004, 0.006)), scale=(1.0, 1.1, 1.08))
        _merge(p, t, C_HAT)
        cyl(p, C_HAT, 0.08, 0.16, loc=(0, 0.01, 1.53), seg=18)            # neck tube
        lathe(p, C_HAT, [(0.0, 0.0), (0.086, 0.0), (0.09, 0.03), (0.086, 0.06), (0.0, 0.06)], seg=18, loc=(0, 0.01, 1.45))  # ribbed hem
        for z in (1.68, 1.737):                                            # thick rims above/below the eye slit
            rbox(p, C_HAT, (0.24, 0.03, 0.016), loc=(0, -0.176, z), r=0.007)
    acc["Balaclava"] = ("Head", balaclava)

    def beard(p):
        sph(p, C_HAIR, 0.118, loc=(0, -0.07, 1.6), scale=(1.12, 0.85, 0.85), u=18, v=12)
        tube(p, C_HAIR, [(-0.05, -0.16, 1.645), (0, -0.168, 1.65), (0.05, -0.16, 1.645)], 0.017, seg=6)
    acc["Beard"] = ("Head", beard)

    def backpack(p):
        rbox(p, C_PACK, (0.32, 0.18, 0.38), loc=(0, 0.21, 1.25), r=0.07)
        rbox(p, C_ACC, (0.28, 0.06, 0.16), loc=(0, 0.3, 1.32), rot=(-15, 0, 0), r=0.035)
        rbox(p, C_ACC, (0.2, 0.06, 0.12), loc=(0, 0.3, 1.14), r=0.035)
        for sx in (1, -1):
            rbox(p, BRASS, (0.03, 0.012, 0.04), loc=(sx * 0.06, 0.335, 1.27), r=0.006)
            tube(p, C_ACC, [(sx * 0.12, 0.13, 1.42), (sx * 0.12, -0.03, 1.44), (sx * 0.12, -0.13, 1.32), (sx * 0.11, -0.12, 1.1)], 0.018, seg=6, scale=(1.0, 0.5))
        cyl(p, C_HAT, 0.07, 0.4, loc=(0, 0.2, 1.48), rot=(0, 90, 0), seg=16)
        for sx in (1, -1):
            cyl(p, C_BELT, 0.073, 0.03, loc=(sx * 0.1, 0.2, 1.48), rot=(0, 90, 0), seg=16)
    acc["Backpack"] = ("Chest", backpack)

    def tie(p):
        rbox(p, RED, (0.04, 0.02, 0.03), loc=(0, -0.135, 1.42), r=0.008)
        prism(p, RED, [(-0.03, 0), (0.03, 0), (0.04, -0.2), (0, -0.25), (-0.04, -0.2)], 0.012, z=-0.148, plane="XZ", loc=(0, 0, 1.405))
    acc["Tie"] = ("Chest", tie)

    def camera(p):  # tourist camera on a strap
        rbox(p, DARK, (0.12, 0.05, 0.08), loc=(0.03, -0.15, 1.2), r=0.015)
        cyl(p, METAL_DK, 0.028, 0.04, loc=(0.03, -0.18, 1.2), rot=(90, 0, 0), seg=12)
        cyl(p, GLASS, 0.02, 0.01, loc=(0.03, -0.2, 1.2), rot=(90, 0, 0), seg=12)
        tube(p, C_ACC, [(-0.03, -0.14, 1.23), (-0.1, -0.11, 1.38), (-0.06, -0.02, 1.47), (0.06, -0.02, 1.47), (0.1, -0.11, 1.38), (0.09, -0.14, 1.23)], 0.007, seg=4, cap=False)
    acc["PhotoCamera"] = ("Chest", camera)

    def lanyard(p):  # staff badge
        tube(p, CORAL, [(-0.06, -0.06, 1.45), (-0.04, -0.13, 1.33), (0.0, -0.145, 1.27), (0.04, -0.13, 1.33), (0.06, -0.06, 1.45)], 0.006, seg=4, cap=False)
        rbox(p, PAPER, (0.07, 0.01, 0.09), loc=(0, -0.15, 1.23), r=0.008)
        rbox(p, TEAL, (0.07, 0.011, 0.025), loc=(0, -0.151, 1.26), r=0.006)
    acc["Lanyard"] = ("Chest", lanyard)

    def clipboard(p):
        wr = Vector(BONES["RightHand"][1])
        rbox(p, WOOD_LT, (0.2, 0.015, 0.27), loc=(wr.x, wr.y - 0.07, wr.z + 0.04), rot=(20, 0, 0), r=0.01)
        rbox(p, PAPER, (0.17, 0.006, 0.22), loc=(wr.x, wr.y - 0.081, wr.z + 0.04), rot=(20, 0, 0), r=0.003)
        rbox(p, METAL, (0.08, 0.02, 0.03), loc=(wr.x, wr.y - 0.11, wr.z + 0.16), rot=(20, 0, 0), r=0.006)
    acc["Clipboard"] = ("RightHand", clipboard)

    out = []
    for name, (bone, fn) in acc.items():
        out.append(part_obj(name, fn, bone, rig))
    out.append(build_hair(rig, "Hair_Long", style="long"))
    out.append(build_hair(rig, "Hair_Sides", style="sides"))
    # clothing shells from the body
    out.append(overlay(body, rig, "Vest", lambda c: 1.02 < c.z < 1.43 and abs(c.x) < 0.18, 0.016, VEST_Y, cut_front=0.025))
    vest = out[-1]
    p = Part()  # reflective bands on the vest
    for z in (1.12, 1.3):
        lathe(p, REFLECT, [(0.0, z), (0.172, z), (0.175, z + 0.03), (0.0, z + 0.03)], seg=24, scale=(1.0, 0.72, 1.0))
    band = finish(p, "VestBands")
    _rigid(band, "Chest")
    _sel([vest, band], vest)
    bpy.ops.object.join()
    out.append(overlay(body, rig, "Coat", lambda c: (0.84 < c.z < 1.44 and abs(c.x) < 0.2) or (abs(c.x) > 0.18 and c.z > 0.98), 0.022, C_COAT, cut_front=0.02))
    return out


# --------------------------------------------------------------- the asset ---
@asset("character", tier="character", res=1024, group="characters", apply=False)
def character():
    for a in list(bpy.data.actions):  # one clean clip set per export (no stale .001 copies)
        if a.name.startswith("AN_"):
            bpy.data.actions.remove(a)
    rig = build_armature()
    body = build_body()
    auto_weights(body, rig)
    zone_materials(body)
    build_head(rig)
    build_hair(rig)
    build_accessories(rig, body)
    anims.bake_clips(rig)
    return rig


pipe.REGISTRY["character"]["anim"] = True


# ------------------------------------------------------- first-person arms --
# Camera space (Blender): +Y forward, +X right, +Z up; the camera sits at the origin.
# Each arm is one rigid object whose origin is the grip point inside the fist
# (arm-local: +Y = knuckles forward, +Z = thumb up, a held shaft runs along -Z).
# Clips are object-transform keys baked here (animation skill) and merged per
# NLA track name on export, so Godot gets AN_FP_* clips that move both arms.
FP_TOOL_GAP = {"tool": 0.40, "pick": 0.15}


def _fp_arm(sx):
    """Stylized forearm + sleeve + fist (thumb wrapped over the curled fingers)."""
    p = Part()
    # sleeve (rolled cuff) and forearm, angled slightly down toward the elbow
    tube(p, C_SHIRT, [(sx * 0.012, -0.20, -0.03), (sx * 0.03, -0.5, -0.1), (sx * 0.05, -0.85, -0.18)], [0.056, 0.066, 0.072], seg=16)
    lathe(p, C_SHIRT, [(0.0, 0.0), (0.06, 0.0), (0.064, 0.03), (0.06, 0.06), (0.0, 0.06)], seg=16, loc=(sx * 0.012, -0.2, -0.03), rot=(97, 0, 0))
    tube(p, C_SKIN, [(0.0, -0.035, 0.0), (sx * 0.004, -0.12, -0.012), (sx * 0.012, -0.24, -0.03)], [0.034, 0.042, 0.047], seg=14)
    # palm / back of hand (the fist block behind and beside the grip axis)
    rbox(p, C_SKIN, (0.052, 0.07, 0.09), loc=(sx * 0.018, -0.03, -0.004), r=0.022, seg=3)
    # four curled fingers wrapping the grip axis (index on top)
    for k in range(4):
        z = 0.03 - k * 0.022
        rr = 0.0105 - k * 0.0008
        pts = []
        for j in range(7):
            th = math.radians(-25 + j * 34)            # from the knuckle, round the front, to the palm side
            pts.append((sx * 0.027 * math.cos(th), 0.006 + 0.026 * math.sin(th), z))
        pts[0] = (sx * 0.03, -0.012, z)
        tube(p, C_SKIN, pts, [rr * 1.1, rr * 1.12, rr * 1.08, rr, rr * 0.98, rr * 0.92, rr * 0.8], seg=8)
        sph(p, C_SKIN, rr * 1.05, loc=(sx * 0.036, -0.014, z), u=8, v=6)   # knuckle
    # thumb: from the palm root, over the top of the index finger
    tube(p, C_SKIN, [(-sx * 0.004, -0.055, 0.03), (-sx * 0.018, -0.02, 0.043), (-sx * 0.012, 0.018, 0.046), (sx * 0.006, 0.03, 0.04)],
         [0.0145, 0.0135, 0.012, 0.0105], seg=8)
    return p


def _fp_rest(side, t=0.0, low=0.0):
    sx = 1 if side == "R" else -1
    b = math.sin(t * math.tau) * 0.006
    return (sx * 0.21, 0.44, -0.2 - low + b), (-4, -sx * 8, sx * 12)


def _fp_two_hand(rl, rr, gap, up=False):
    """Left fist on the shaft that hangs from the right grip (arm-local -Z), or
    that rises from it (arm-local +Z, the pickaxe: head on the thumb side)."""
    e = Euler([math.radians(a) for a in rr])
    d = e.to_matrix() @ Vector((0, 0, 1 if up else -1))
    ll = Vector(rl) + d * gap
    return (tuple(ll), rr)


def _fp_lerp(a, b, k):
    """Position lerp + rotation SLERP (shortest way between the two poses)."""
    qa = Euler([math.radians(x) for x in a[1]]).to_quaternion()
    qb = Euler([math.radians(x) for x in b[1]]).to_quaternion()
    e = qa.slerp(qb, k).to_euler("XYZ")
    return (tuple(a[0][i] + (b[0][i] - a[0][i]) * k for i in range(3)), tuple(math.degrees(x) for x in e))


def _fp_aim(fist, elbow_dir, head_dir):
    """A hand pose from where the fist is, which way the forearm runs (fist ->
    elbow) and which way the held shaft points (fist -> tool head, thumb side).
    The fist's frame: +Y knuckles forward (forearm along -Y), +Z thumb/shaft."""
    f = Vector(elbow_dir).normalized()
    h = Vector(head_dir)
    h = (h - f * h.dot(f)).normalized()       # keep the shaft square to the forearm (hammer grip)
    y = -f
    x = y.cross(h).normalized()
    m = Matrix((x, y, h)).transposed()        # columns = local X, Y, Z in camera space
    return (tuple(fist), tuple(math.degrees(v) for v in m.to_euler("XYZ")))


def _fp_keys(keys, t):
    """keys: [(time 0..1, pose[, ease])] -> interpolation into each key using its
    ease: smoothstep (default), "in" (accelerate) or "lin" (keep the speed, for a
    swing that must not stop at every key)."""
    for i in range(len(keys) - 1):
        t0, a = keys[i][0], keys[i][1]
        t1, b = keys[i + 1][0], keys[i + 1][1]
        ease = keys[i + 1][2] if len(keys[i + 1]) > 2 else "smooth"
        if t0 <= t <= t1:
            k = (t - t0) / max(1e-6, t1 - t0)
            if ease == "in":
                k = k * k
            elif ease != "lin":
                k = k * k * (3 - 2 * k)
            return _fp_lerp(a, b, k)
    return keys[-1][1]


TOOL_READY = ((0.2, 0.42, -0.14), (48, 0, 28))


def fp_idle(t):
    return {"R": _fp_rest("R", t), "L": _fp_rest("L", t + 0.2)}


def fp_hold_tool(t):
    b = math.sin(t * math.tau) * 0.006
    r = ((0.2, 0.42, -0.14 + b), (48 + math.sin(t * math.tau) * 1.5, 0, 28))
    return {"R": r, "L": _fp_two_hand(r[0], r[1], FP_TOOL_GAP["tool"])}


def fp_dig(t):
    keys = [(0.0, TOOL_READY), (0.3, ((0.21, 0.36, -0.04), (35, 0, 25))),
            (0.55, ((0.16, 0.56, -0.26), (72, 0, 28))), (0.78, ((0.2, 0.48, -0.2), (42, 0, 26))), (1.0, TOOL_READY)]
    r = _fp_keys(keys, t)
    return {"R": r, "L": _fp_two_hand(r[0], r[1], FP_TOOL_GAP["tool"])}


## Pickaxe: a hammer grip on the BACK end of the handle (both fists close
## together at the butt), the shaft rising from the thumb side to the head.
## (Godot turns the held pick 180 degrees so its head is on the thumb side.)
## Every pose keeps the forearm pointing back toward you - arm rotation X stays
## between -80 and +65 degrees, so the arms never flip over.
PICK_READY = _fp_aim((0.22, 0.4, -0.2), (0.25, -0.85, -0.45), (0.0, -0.15, 1.0))


def fp_hold_pick(t):
    b = math.sin(t * math.tau) * 0.006
    r = ((PICK_READY[0][0], PICK_READY[0][1], PICK_READY[0][2] + b), PICK_READY[1])
    return {"R": r, "L": _fp_two_hand(r[0], r[1], FP_TOOL_GAP["pick"], up=True)}


def fp_mine(t):
    """Miner's overhead swing (like the reference poses), hands on the BACK end of
    the handle. Forearms always come up from the bottom of the screen; the
    forearm rolls (not just tilts) so the head goes up, back over the shoulder,
    then forward-down into the rock just below the crosshair. One back-and-forth
    arc, slerped - never a spin."""
    keys = [(0.0, PICK_READY),
            (0.5, _fp_aim((0.15, 0.26, 0.13), (0.15, -0.25, -0.95), (0.0, -0.95, 0.3))),     # one smooth rise: head back over the shoulder
            (0.56, _fp_aim((0.15, 0.25, 0.14), (0.15, -0.25, -0.95), (0.0, -0.97, 0.22))),    # (brief hang at the top)
            (0.63, _fp_aim((0.14, 0.36, 0.08), (0.15, -0.4, -0.9), (-0.02, 0.15, 1.0)), "in"),     # swing: over the top...
            (0.68, _fp_aim((0.12, 0.46, 0.02), (0.2, -0.6, -0.77), (-0.06, 1.0, 0.1)), "lin"),      # ...head coming forward...
            (0.72, _fp_aim((0.1, 0.52, -0.07), (0.2, -0.7, -0.68), (-0.12, 0.75, -0.65)), "lin"),   # ...STRIKE into the rock
            (0.8, _fp_aim((0.11, 0.5, -0.04), (0.2, -0.7, -0.68), (-0.1, 0.85, -0.5))),      # recoil
            (1.0, PICK_READY)]
    r = _fp_keys(keys, t)
    return {"R": r, "L": _fp_two_hand(r[0], r[1], FP_TOOL_GAP["pick"], up=True)}


def fp_detector(t):
    """Metal-detector sweep: one hand on the grip, arm out, the coil low in front of
    you (visible at the bottom of the screen) swinging left-right over the sand."""
    s = math.sin(t * math.tau)
    c = math.cos(t * math.tau)
    return {"R": ((0.13 + s * 0.05, 0.42, -0.15 + abs(c) * 0.012), (68, 0, 8 + s * 28)),
            "L": _fp_rest("L", t, low=0.05)}


def fp_hold_item(t):
    b = math.sin(t * math.tau) * 0.006
    return {"R": ((0.16, 0.44, -0.15 + b), (6, 0, 10)), "L": _fp_rest("L", t + 0.2, low=0.03)}


def fp_shove(t):
    rest = fp_idle(0.0)
    push = {"R": ((0.15, 0.62, -0.13), (78, -10, 6)), "L": ((-0.15, 0.62, -0.13), (78, 10, -6))}
    k = math.sin(min(1.0, t) * math.pi)
    return {s: _fp_lerp(rest[s], push[s], k) for s in ("R", "L")}


def fp_throw(t):
    hold = fp_hold_item(0.0)["R"]
    keys = [(0.0, hold), (0.3, ((0.22, 0.3, -0.14), (-20, 0, 18))), (0.6, ((0.12, 0.66, -0.02), (40, 0, 4))), (1.0, hold)]
    return {"R": _fp_keys(keys, t), "L": _fp_rest("L", 0.2, low=0.03)}


def fp_grab(t):
    hold = fp_hold_item(0.0)["R"]
    keys = [(0.0, hold), (0.45, ((0.12, 0.6, -0.27), (-10, 0, 6))), (1.0, hold)]
    return {"R": _fp_keys(keys, t), "L": _fp_rest("L", 0.2, low=0.03)}


FP_ANIMS = [  # name, fn, seconds, keys, loop
    ("Idle", fp_idle, 3.0, 12, True), ("HoldTool", fp_hold_tool, 3.0, 12, True), ("Dig", fp_dig, 0.8, 16, True),
    ("HoldPick", fp_hold_pick, 3.0, 12, True), ("Mine", fp_mine, 1.1, 30, True), ("Detector", fp_detector, 1.8, 16, True),
    ("HoldItem", fp_hold_item, 3.0, 12, True), ("Shove", fp_shove, 0.32, 8, False), ("Throw", fp_throw, 0.45, 10, False),
    ("Grab", fp_grab, 0.35, 8, False),
]


def _fp_set(ob, pose):
    """Pose an arm. Rotations are keyed as quaternions kept on the same
    hemisphere as the previous key, so playback always takes the short way
    (an euler wrap from 290 to 60 degrees used to spin the arm all the way round)."""
    ob.location = Vector(pose[0])
    q = Euler([math.radians(a) for a in pose[1]]).to_quaternion()
    prev = ob.get("_q")
    if prev is not None and q.dot(Quaternion(prev)) < 0.0:
        q.negate()
    ob["_q"] = list(q)
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = q


## ---- Pickaxe clips: AUTHORED as Blender keyframes on "PickMount" -----------
## PickMount IS the pick (the game parents the pickaxe model to it): origin = the
## butt end, where the right fist grips; local -Z runs up the handle to the
## head; local -Y is the spike. Its euler X = 180 - phi, where phi is the
## handle's angle from straight up (negative = tilted back over the shoulder,
## positive = forward/down), so the swing can only turn the way the keys go.
## Interpolation is Blender's: Bezier, with an ease-in into the strike (the
## pick accelerates over the top) and an ease-out bounce off the rock.
## Both hands are then baked onto the handle at every frame.
##   key: (time 0..1, phi deg, grip position, yaw deg, interpolation)
PICK_CLIPS = {
    "HoldPick": (3.0, [
        (0.0, 10, (0.22, 0.42, -0.22), 12, "BEZIER"),
        (0.5, 13, (0.22, 0.428, -0.214), 12, "BEZIER"),
        (1.0, 10, (0.22, 0.42, -0.22), 12, "BEZIER")]),
    "Mine": (1.0, [
        (0.0, 10, (0.22, 0.42, -0.22), 12, "BEZIER"),     # ready: pick upright in both hands
        (0.42, -55, (0.26, 0.42, 0.02), 8, "BEZIER"),     # raise: up to the right, head tilting back over the shoulder (stays in view)
        (0.5, -58, (0.26, 0.42, 0.03), 8, "EASE_IN"),     # brief hold, then accelerate...
        (0.7, 105, (0.12, 0.5, -0.3), 14, "BEZIER"),      # ...down into the STRIKE (a hard stop on impact)
        (1.0, 10, (0.22, 0.42, -0.22), 12, "BEZIER")]),   # smooth return to ready (no bounce)
}
## Where each forearm runs to (an elbow just below/behind the camera), so the
## arms always come up from the bottom of the screen.
FP_ELBOW = {"R": Vector((0.26, -0.05, -0.48)), "L": Vector((-0.16, -0.05, -0.5))}
def _fp_elbow(side, fist):
    """Low hands: the forearm runs back-down to an elbow below the camera.
    Hands raised for the wind-up: the elbows rise above the fists, so the
    whole arm (and the pick hanging down your back) leaves through the top of
    the view instead of sweeping past your face."""
    lift = max(0.0, min(1.0, (fist.z - 0.2) / 0.25))  # only for hands raised well above the view
    sx = 1.0 if side == "R" else -1.0
    raised = fist + Vector((sx * 0.1, -0.35, 0.3))  # arms raised: the elbows end up above the fists, out of view
    return FP_ELBOW[side].lerp(raised, lift)


def _fp_forearm_angle(phi):
    """Forearm direction (fist -> elbow) in the swing plane, as an angle like
    phi (0 = up, -90 = back, -180 = down): back-down at ready, straight down
    with the pick raised, back and a little up at the strike (arms reaching
    down to the rock). Piecewise-linear in phi, so it is continuous."""
    if phi <= 10.0:
        return -120.0 + (phi - 10.0) * (55.0 / 68.0)
    return -120.0 + (min(phi, 105.0) - 10.0) / 95.0 * 40.0


def _fp_hand(fist, phi, yaw, side):
    """A fist pose whose sideways axis is locked to the swing plane (in a straight
    overhead swing the palms keep facing sideways and only the wrist bends), so the
    hand can never roll over - the old thumb-from-handle aim flipped the hand in a
    single frame whenever the handle lined up with the forearm (the "twitch")."""
    th = math.radians(_fp_forearm_angle(phi))
    rz = Matrix.Rotation(yaw, 3, "Z")
    x = rz @ Vector((1.0, 0.0, 0.0))
    sx = 0.12 if side == "R" else -0.18           # elbows a little out to the side
    f = (rz @ Vector((sx, math.sin(th), math.cos(th)))).normalized()
    f = (f - x * f.dot(x) * 0.0).normalized()
    y = -f
    xx = (x - y * x.dot(y)).normalized()
    z = xx.cross(y).normalized()
    m = Matrix((xx, y, z)).transposed()
    return (tuple(fist), tuple(math.degrees(v) for v in m.to_euler("XYZ")))


PICK_GAP = 0.14  # the left fist sits just above the right one, both at the back of the handle
_PICK_FLIP = Matrix.Rotation(math.pi, 3, "X")  # fist frame <-> pick frame (head on the thumb side, spike leading)


def _fcurves(ob):
    act = ob.animation_data.action
    try:
        return list(act.fcurves)
    except AttributeError:  # Blender 5 layered actions
        from bpy_extras import anim_utils
        return list(anim_utils.action_get_channelbag_for_slot(act, ob.animation_data.action_slot).fcurves)


def _push_nla(ob, name, side=""):
    ad = ob.animation_data
    act = ad.action
    act.name = "AN_FP_%s%s" % (name, ("_" + side) if side else "")
    act.use_fake_user = True
    ad.action = None
    tr = ad.nla_tracks.new()
    tr.name = "AN_FP_" + name
    tr.strips.new(act.name, 1, act)
    tr.mute = True


def _mount_from_hand(mount, pose):
    """Outside the pick clips the mount just follows the right fist."""
    m = Euler([math.radians(a) for a in pose[1]]).to_matrix() @ _PICK_FLIP
    mount.location = Vector(pose[0])
    mount.rotation_mode = "XYZ"
    mount.rotation_euler = m.to_euler("XYZ", mount.rotation_euler)


def _pick_clip(name, secs, keys, arms, mount):
    frames = max(2, int(round(secs * anims.FPS)))
    for ob in list(arms.values()) + [mount]:
        ob.animation_data_create().action = None
        ob.pop("_q", None)
    mount.rotation_mode = "XYZ"
    eases = []
    for t, phi, g, yaw, ease in keys:
        f = 1 + t * frames
        mount.location = Vector(g)
        mount.rotation_euler = Euler((math.radians(180.0 - phi), 0.0, math.radians(yaw)))
        mount.keyframe_insert("location", frame=f)
        mount.keyframe_insert("rotation_euler", frame=f)
        eases.append((f, ease))
    for fc in _fcurves(mount):
        for kp in fc.keyframe_points:
            ease = min(eases, key=lambda e: abs(e[0] - kp.co.x))[1]
            if ease in ("EASE_IN", "EASE_OUT"):
                kp.interpolation = "QUAD"
                kp.easing = ease
            else:
                kp.interpolation = "BEZIER"
                kp.handle_left_type = "AUTO_CLAMPED"
                kp.handle_right_type = "AUTO_CLAMPED"
        fc.update()
    # bake the hands onto the handle, frame by frame
    scn = bpy.context.scene
    qa = {"near": 9.0, "step": 0.0}
    last = {}
    for f in range(1, frames + 2):
        scn.frame_set(f)
        m = mount.matrix_basis
        g = m.translation.copy()
        head = (m.to_3x3() @ Vector((0, 0, -1))).normalized()
        gl = g + head * PICK_GAP
        phi = 180.0 - math.degrees(mount.rotation_euler.x)
        yaw = mount.rotation_euler.z
        poses = {"R": _fp_hand(g, phi, yaw, "R"), "L": _fp_hand(gl, phi, yaw, "L")}
        for side, ob in arms.items():
            _fp_set(ob, poses[side])
            ob.keyframe_insert("location", frame=f)
            ob.keyframe_insert("rotation_quaternion", frame=f)
            # QA: the forearm (fist -> 0.85 m toward the elbow, ~0.07 m thick)
            # must never come near the camera, and must never jump between frames
            q = Quaternion(ob["_q"])
            p0 = Vector(poses[side][0])
            fdir = q.to_matrix() @ Vector((0, -1, 0))
            tt = max(0.0, min(0.85, -p0.dot(fdir)))
            qa["near"] = min(qa["near"], (p0 + fdir * tt).length)
            if side in last:
                stp = math.degrees(q.rotation_difference(last[side]).angle)
                qa["step"] = max(qa["step"], stp)
                if stp > 20.0:
                    print("[FPQA]   frame %d %s turns %.0f deg (phi %.0f)" % (f, side, stp, 180.0 - math.degrees(mount.rotation_euler.x)))
            last[side] = q
    print("[FPQA] %s: closest forearm to camera %.2f m, biggest arm turn per frame %.1f deg" % (name, qa["near"], qa["step"]))
    if qa["step"] > 70.0:  # a fast strike turns ~50 deg/frame; a hand flipping over is far more
        raise RuntimeError("FP %s: an arm jumps %.0f degrees in one frame" % (name, qa["step"]))
    if qa["near"] < 0.2:
        raise RuntimeError("FP %s: a forearm passes through the camera (%.2f m)" % (name, qa["near"]))
    _push_nla(mount, name)
    for side, ob in arms.items():
        _push_nla(ob, name, side)


@asset("fp_arms", tier="prop", res=512, group="characters")
def fp_arms():
    """First-person view-model arms: two rigid sleeved forearms with modelled fists
    (GripR/GripL at the fist centre), the animated PickMount, and AN_FP_* clips."""
    bpy.context.scene.render.fps = anims.FPS  # clips are laid out at 30 fps (the default 24 played them 25% slow)
    bpy.context.scene.render.fps_base = 1.0
    root = empty("FPArms")
    arms = {}
    for side, sx in (("R", 1), ("L", -1)):
        ob = finish(_fp_arm(sx), "Arm" + side, root, smooth=60, subsurf=1)
        empty("Grip" + side, ob)
        arms[side] = ob
    mount = empty("PickMount", root)
    for name, fn, secs, keys, loop in FP_ANIMS:
        if name in PICK_CLIPS:
            _pick_clip(name, PICK_CLIPS[name][0], PICK_CLIPS[name][1], arms, mount)
            continue
        for ob in list(arms.values()) + [mount]:
            ob.animation_data_create().action = None
        frames = max(2, int(round(secs * anims.FPS)))
        for i in range(keys + 1):
            t = i / keys
            pose = fn(0.0 if (loop and i == keys) else t)
            for side, ob in arms.items():
                _fp_set(ob, pose[side])
                ob.keyframe_insert("location", frame=1 + t * frames)
                ob.keyframe_insert("rotation_quaternion", frame=1 + t * frames)
            _mount_from_hand(mount, pose["R"])
            mount.keyframe_insert("location", frame=1 + t * frames)
            mount.keyframe_insert("rotation_euler", frame=1 + t * frames)
        _push_nla(mount, name)
        for side, ob in arms.items():
            _push_nla(ob, name, side)
    rest = fp_idle(0.0)
    for side, ob in arms.items():
        _fp_set(ob, rest[side])
    _mount_from_hand(mount, rest["R"])
    return root


pipe.REGISTRY["fp_arms"]["anim"] = True
pipe.REGISTRY["fp_arms"]["anim_merge"] = "NLA_TRACK"
