"""Asset pipeline driver (blender-director workflow).

Each asset is registered with @asset(id, tier=..., col=[...], res=..., sculpt={...}).
build() runs, per asset:
  model -> cleanup -> UV (uv-workflow) -> optional sculpt normal bake (sculpting)
  -> hand-painted atlas bake (texture-workflow / stylized-style) -> material collapse
  -> collision proxies (collision-proxy, Godot "-convcolonly" naming)
  -> validation vs. tier budget (asset-optimization / qa-review)
  -> GLB export (godot-export) -> lineup placement for the visual QA pass.

Works in the user's live Blender (via MCP) inside a dedicated scene "TT_Build",
or headless: blender -b --python blender/build.py -- <groups> [--only a,b]
"""
import json
import math
import os
import time

import bmesh
import bpy
from mathutils import Vector

from . import geo as G
from . import mats as MT
from . import paint as PT

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "game", "assets", "models")
QA = os.path.join(ROOT, "blender", "qa")

# triangle budgets per tier (polycount-budgets.md, stylized adjustment)
BUDGET = {"small": 3000, "item": 6000, "prop": 15000, "hero": 30000, "building": 40000, "env": 60000, "character": 60000}

REGISTRY = {}   # id -> dict(fn, tier, col, res, sculpt, group, anim)
SCN = None
COLL = None


def asset(id, tier="prop", col=None, res=512, sculpt=None, group="misc", paint=True, apply=True):
    def deco(fn):
        REGISTRY[id] = dict(fn=fn, tier=tier, col=col or [], res=res, sculpt=sculpt, group=group, paint=paint, apply=apply)
        return fn
    return deco


# ------------------------------------------------------------------ scene ---
def scene(name="TT_Build"):
    global SCN, COLL
    scn = bpy.data.scenes.get(name) or bpy.data.scenes.new(name)
    try:
        bpy.context.window.scene = scn
    except AttributeError:
        pass
    SCN = scn
    COLL = scn.collection
    return scn


def clear(keep_lineup=True):
    for o in list(SCN.objects):
        if keep_lineup and o.get("tt_lineup"):
            continue
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.actions):
        for d in list(coll):
            if d.users == 0 or (coll is bpy.data.actions and d.users == 1 and d.use_fake_user):
                coll.remove(d)
    for m in list(bpy.data.materials):  # orphaned per-asset materials / atlases from earlier builds
        if m.users == 0 and ("__" in m.name or m.name.startswith("MAT_")):
            bpy.data.materials.remove(m)
    for im in list(bpy.data.images):
        if im.users == 0 and im.name.startswith("T_"):
            bpy.data.images.remove(im)


def coll(name):
    c = bpy.data.collections.get(name)
    if c is None:
        c = bpy.data.collections.new(name)
    if c.name not in SCN.collection.children:
        SCN.collection.children.link(c)
    return c


def empty(name, parent=None, loc=(0, 0, 0)):
    ob = bpy.data.objects.new(name, None)
    SCN.collection.objects.link(ob)
    ob.location = loc
    if parent:
        ob.parent = parent
    return ob


def finish(p, name, parent=None, loc=(0, 0, 0), bevel=0.0, smooth=34.0, subsurf=0, pivot=None, weld=True):
    if pivot is not None:
        bmesh.ops.translate(p.bm, vec=-Vector(pivot), verts=p.bm.verts)
    if weld:
        bmesh.ops.remove_doubles(p.bm, verts=p.bm.verts, dist=0.0002)
    me = bpy.data.meshes.new(name)
    bmesh.ops.recalc_face_normals(p.bm, faces=p.bm.faces[:])
    p.bm.to_mesh(me)
    p.bm.free()
    for m in p.mats:
        me.materials.append(m)
    for poly in me.polygons:
        poly.use_smooth = True
    try:
        me.set_sharp_from_angle(angle=math.radians(smooth))
    except Exception:
        pass
    ob = bpy.data.objects.new(name, me)
    SCN.collection.objects.link(ob)
    ob.location = loc
    if parent:
        ob.parent = parent
    if subsurf > 0:
        mod = ob.modifiers.new("Sub", "SUBSURF")
        mod.levels = subsurf
        mod.render_levels = subsurf
    if bevel > 0:
        mod = ob.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(40)
        mod.harden_normals = False
    return ob


def single(name, fn, bevel=0.0, smooth=34.0, subsurf=0):
    p = G.Part()
    fn(p)
    return finish(p, name, bevel=bevel, smooth=smooth, subsurf=subsurf)


def descendants(ob):
    out = [ob]
    for c in ob.children:
        out += descendants(c)
    return out


def apply_modifiers(objs):
    for o in objs:
        if o.type != "MESH" or not o.modifiers:
            continue
        if any(m.type == "ARMATURE" for m in o.modifiers):
            continue
        PT._sel([o])
        for m in list(o.modifiers):
            try:
                bpy.ops.object.modifier_apply(modifier=m.name)
            except RuntimeError as e:
                print("  ! modifier", o.name, m.name, e)


# -------------------------------------------------------------- collision ---
def add_collision(root, specs, asset_id):
    """specs: ("box", center, size) | ("hull", object_name|None) | ("mesh", object_name)
    Godot import hints: '-convcolonly' -> StaticBody3D + convex shape, '-colonly' -> trimesh."""
    made = []
    for i, s in enumerate(specs):
        kind = s[0]
        name = "COL_%s_%02d" % (asset_id, i)
        if kind == "box":
            c, sz = Vector(s[1]), Vector(s[2])
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0)
            for v in bm.verts:
                v.co = Vector((v.co.x * sz.x, v.co.y * sz.y, v.co.z * sz.z)) + c
            me = bpy.data.meshes.new(name)
            bm.to_mesh(me)
            bm.free()
            ob = bpy.data.objects.new(name + "-convcolonly", me)
        elif kind == "bounds":
            shrink = s[1] if len(s) > 1 else 0.9
            lo, hi = PT.bounds([o for o in descendants(root) if o.type == "MESH" and not o.get("tt_collision")])
            lo = root.matrix_world.inverted() @ lo
            hi = root.matrix_world.inverted() @ hi
            c, sz = (lo + hi) / 2, (hi - lo)
            sz = Vector((sz.x * shrink, sz.y * shrink, sz.z))
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0)
            for v in bm.verts:
                v.co = Vector((v.co.x * sz.x, v.co.y * sz.y, v.co.z * sz.z)) + c
            me = bpy.data.meshes.new(name)
            bm.to_mesh(me)
            bm.free()
            ob = bpy.data.objects.new(name + "-convcolonly", me)
        elif kind in ("hull", "mesh"):
            src = bpy.data.objects.get(s[1]) if len(s) > 1 and s[1] else root
            deps = bpy.context.evaluated_depsgraph_get()
            ev = src.evaluated_get(deps)
            me = bpy.data.meshes.new_from_object(ev)
            me.transform(src.matrix_world @ root.matrix_world.inverted())
            if kind == "hull":
                bm = bmesh.new()
                bm.from_mesh(me)
                res = bmesh.ops.convex_hull(bm, input=bm.verts)
                bmesh.ops.delete(bm, geom=[g for g in res["geom_interior"] + res["geom_unused"] if isinstance(g, bmesh.types.BMVert)], context="VERTS")
                if len(s) > 2:
                    for v in bm.verts:
                        v.co *= s[2]
                bm.to_mesh(me)
                bm.free()
            me.materials.clear()
            ob = bpy.data.objects.new(name + ("-convcolonly" if kind == "hull" else "-colonly"), me)
        else:
            continue
        SCN.collection.objects.link(ob)
        ob.parent = root
        ob.display_type = "WIRE"
        ob.hide_render = True
        ob["tt_collision"] = True
        made.append(ob)
    return made


# ------------------------------------------------------------- validation ---
def tri_count(objs):
    deps = bpy.context.evaluated_depsgraph_get()
    n = 0
    for o in objs:
        if o.type != "MESH" or o.get("tt_collision"):
            continue
        me = o.evaluated_get(deps).to_mesh()
        n += sum(len(p.vertices) - 2 for p in me.polygons)
        o.evaluated_get(deps).to_mesh_clear()
    return n


def validate(asset_id, objs, info):
    render = [o for o in objs if o.type == "MESH" and not o.get("tt_collision")]
    tris = tri_count(render)
    mats = set()
    for o in render:
        for m in o.data.materials:
            if m:
                mats.add(m.name)
    issues = []
    budget = BUDGET.get(info["tier"], 15000)
    if tris > budget:
        issues.append("tris %d > %s budget %d" % (tris, info["tier"], budget))
    if info["paint"] and any(not o.data.uv_layers for o in PT.bakeable(render)):
        issues.append("missing UVs")
    for o in render:
        if any(abs(s - 1.0) > 1e-4 for s in o.scale) and o.parent is None:
            issues.append("unapplied scale on " + o.name)
        bm = bmesh.new()
        bm.from_mesh(o.data)
        loose = sum(1 for v in bm.verts if not v.link_edges)
        bm.free()
        if loose:
            issues.append("%d loose verts on %s" % (loose, o.name))
    cap = 12 if info["tier"] == "character" else 6
    if len(mats) > cap:
        issues.append("%d materials (max %d)" % (len(mats), cap))
    rep = dict(id=asset_id, tier=info["tier"], tris=tris, budget=budget, materials=sorted(mats), objects=len(render),
               collision=sum(1 for o in objs if o.get("tt_collision")), issues=issues, verdict="SHIP" if not issues else "FIX")
    return rep


# ----------------------------------------------------------------- export ---
def export(asset_id, root, anim=False, merge=None):
    objs = descendants(root)
    PT._sel(objs, root)
    path = os.path.join(OUT, asset_id + ".glb")
    kw = dict(filepath=path, export_format="GLB", use_selection=True, export_yup=True, export_apply=not anim,
              export_animations=anim, export_image_format="AUTO")
    if merge:
        kw["export_merge_animation"] = merge
    try:
        bpy.ops.export_scene.gltf(use_active_scene=True, **kw)
    except TypeError:
        bpy.ops.export_scene.gltf(**kw)
    return path


LINEUP = {"i": 0}


def to_lineup(root, spacing=None):
    lo, hi = PT.bounds([o for o in descendants(root) if o.type == "MESH"])
    w = max(hi.x - lo.x, hi.y - lo.y, 1.0)
    i = LINEUP["i"]
    LINEUP["i"] += 1
    cols = 8
    step = spacing or 6.0
    root.location = Vector(((i % cols) * step, -(i // cols) * step, 0)) + root.location
    for o in descendants(root):
        o["tt_lineup"] = True
        if "__" not in o.name:
            o.name = o.name + "__" + LINEUP.get("id", "x")
        if o.get("tt_collision"):
            o.hide_viewport = True


# ------------------------------------------------------------------ build ---
def build_one(asset_id, lineup=True, spacing=None):
    info = REGISTRY[asset_id]
    t0 = time.time()
    clear(keep_lineup=True)
    root = info["fn"]()
    objs = descendants(root)
    if info["apply"]:
        apply_modifiers(objs)
    meshes = [o for o in objs if o.type == "MESH"]
    nrm = None
    bc = None
    if info["paint"]:
        PT.unwrap(PT.bakeable(meshes))
        if info["sculpt"]:
            nrm = PT.sculpt_normal(meshes, asset_id, res=info["res"], **info["sculpt"])
        bc = PT.bake_paint(meshes, asset_id, res=info["res"])
        PT.finalize(meshes, asset_id, bc, nrm)
    cols = add_collision(root, info["col"], asset_id) if info["col"] else []
    objs = descendants(root)
    rep = validate(asset_id, objs, info)
    export(asset_id, root, anim=info.get("anim", False), merge=info.get("anim_merge"))
    PT.restore_names(asset_id)
    rep["seconds"] = round(time.time() - t0, 1)
    if lineup:
        LINEUP["id"] = asset_id
        to_lineup(root, spacing)
    print("[%s] %s tris=%d mats=%d col=%d %.1fs %s" % (rep["verdict"], asset_id, rep["tris"], len(rep["materials"]), rep["collision"],
                                                     rep["seconds"], "; ".join(rep["issues"])))
    return rep


def build(ids=None, group=None, lineup=True, spacing=None):
    scene()
    LINEUP["i"] = 0
    clear(keep_lineup=False)
    reps = []
    for aid, info in REGISTRY.items():
        if ids and aid not in ids:
            continue
        if group and info["group"] != group:
            continue
        try:
            reps.append(build_one(aid, lineup, spacing))
        except Exception as e:
            import traceback
            traceback.print_exc()
            reps.append(dict(id=aid, verdict="ERROR", issues=[repr(e)]))
            print("[ERROR]", aid, e)
    os.makedirs(QA, exist_ok=True)
    path = os.path.join(QA, "report_%s.json" % (group or "custom"))
    old = {}
    if os.path.exists(path):
        try:
            old = {r["id"]: r for r in json.load(open(path))}
        except Exception:
            old = {}
    for r in reps:
        old[r["id"]] = r
    json.dump(list(old.values()), open(path, "w"), indent=1)
    return reps
