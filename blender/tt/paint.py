"""Hand-painted texture pipeline (uv-workflow + texture-workflow + stylized-style).

For one asset (a list of mesh objects):
  1. unwrap()      smart-project every mesh into ONE shared 0-1 UV space and pack it
                   (consistent texel density across the asset's parts).
  2. sculpt_normal optional: build a displaced high-poly copy (sculpting skill),
                   bake a tangent-space normal map onto the game mesh.
  3. bake_paint()  Cycles EMIT bake of a stylized "painted" shader into T_<id>_BC:
                     base colour (white for tint materials)
                   x painted top-light gradient   (light shapes, not photoreal AO)
                   x cool-shifted cavity shadow  (AO node, painted look)
                   + warm edge highlight         (Bevel-node normal vs face normal)
                   x low-frequency brush mottling (object-space noise / voronoi)
                   x material-specific strokes   (wood grain, strata bands, sand speckle)
  4. finalize()    every 'paint' material of the asset collapses into one MAT_<id>
                   using the atlas; 'tint' materials keep their names (Godot recolours
                   them) and get the atlas x their colour as baseColorFactor;
                   'special' materials are left alone.
"""
import math
import bpy
from mathutils import Vector

from . import mats as MT


def _sel(objs, active=None):
    for o in bpy.context.scene.objects:
        if o is not None and o.name in bpy.context.view_layer.objects:
            o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or (objs[0] if objs else None)


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def bakeable(objs):
    out = []
    for o in objs:
        if o.type != "MESH" or not o.data.polygons:
            continue
        if any(m and MT.kind_of(m) != "special" for m in o.data.materials):
            out.append(o)
    return out


def face_flags(me, name="tt_fixed_uv"):
    """Per-face int flag whatever domain Geometry Nodes left it on."""
    a = me.attributes.get(name)
    if a is None:
        return None
    vals = [0] * len(a.data)
    a.data.foreach_get("value", vals)
    if a.domain == "FACE":
        return vals
    if a.domain == "POINT":
        return [1 if all(vals[v] for v in p.vertices) else 0 for p in me.polygons]
    if a.domain == "CORNER":
        return [1 if all(vals[i] for i in p.loop_indices) else 0 for p in me.polygons]
    return None


def _fixed(o):
    vals = face_flags(o.data)
    return vals if vals and any(vals) else None


def _unwrap_host(o, flags, margin, angle):
    """Scatter host: unwrap only its own faces, packed below the trim-tile strip."""
    import bmesh
    _sel([o])
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(o.data)
    bm.faces.ensure_lookup_table()
    bm.faces.index_update()
    for v in bm.verts:
        v.select_set(False)
    for i, f in enumerate(bm.faces):
        f.select_set(flags[i] == 0)
    bm.select_flush_mode()
    bmesh.update_edit_mesh(o.data)
    bpy.ops.uv.smart_project(angle_limit=math.radians(angle), island_margin=margin, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    # (no pack_islands here: it would also repack the fixed trim tiles)
    bm = bmesh.from_edit_mesh(o.data)
    uvl = bm.loops.layers.uv.active
    k = 0.86  # keep clear of the reserved strip (v >= 0.875)
    for i, f in enumerate(bm.faces):
        if flags[i] == 0:
            for lp in f.loops:
                lp[uvl].uv = lp[uvl].uv * k
    bmesh.update_edit_mesh(o.data)
    bpy.ops.object.mode_set(mode="OBJECT")


def unwrap(objs, margin=0.01, angle=62.0):
    objs = [o for o in objs if o.type == "MESH" and o.data.polygons]
    if not objs:
        return
    for o in objs:
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")
    hosts = [(o, _fixed(o)) for o in objs]
    for o, flags in hosts:
        if flags:
            _unwrap_host(o, flags, margin, angle)
    objs = [o for o, flags in hosts if not flags]
    if not objs:
        return
    _sel(objs)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(angle), island_margin=margin, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.select_all(action="SELECT")
    try:
        bpy.ops.uv.pack_islands(margin=margin, rotate=True, shape_method="CONCAVE")
    except TypeError:
        bpy.ops.uv.pack_islands(margin=margin, rotate=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def _cycles(samples=24):
    scn = bpy.context.scene
    try:
        scn.render.engine = "CYCLES"
    except TypeError:
        pass
    scn.cycles.samples = samples
    try:
        scn.cycles.use_denoising = False
    except AttributeError:
        pass
    scn.render.bake.margin = 16
    try:
        scn.render.bake.margin_type = "EXTEND"
    except (AttributeError, TypeError):
        pass
    scn.render.bake.use_clear = True


STROKE = {  # material-name keyword -> stroke style
    "Wood": "grain", "Drift": "grain", "Trunk": "grain", "Handle": "grain", "Leather": "grain",
    "Strata": "bands", "Slate": "bands", "Sandstone": "bands", "Rock": "rock", "Matrix": "rock", "Stone": "rock",
    "Sand": "speckle", "Grass": "speckle", "Clover": "speckle", "Soil": "speckle", "Mud": "speckle", "Concrete": "speckle",
    "Asphalt": "speckle", "Curb": "rock", "Bone": "rock", "Fossil": "rock", "Shell": "bands", "Roof": "grain", "Siding": "grain",
    "Leaf": "leaf", "Cloth": "weave", "Cushion": "weave", "Velvet": "weave", "Shirt": "weave", "Pants": "weave", "Pack": "weave",
}


def _stroke(name):
    for k, v in STROKE.items():
        if k in name:
            return v
    return ""


def _paint_material(src, lo, hi, white=False):
    """Temporary emission shader that paints `src`'s colour."""
    size = max((hi - lo).length, 0.05)
    m = bpy.data.materials.new("__bake_" + src.name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    N = nt.nodes.new
    L = nt.links.new
    out = N("ShaderNodeOutputMaterial")
    emi = N("ShaderNodeEmission")
    L(emi.outputs[0], out.inputs[0])
    geo = N("ShaderNodeNewGeometry")
    col = MT.hexc(MT.base_hex(src)) if not white else (0.92, 0.92, 0.92)

    def val(v):
        n = N("ShaderNodeValue")
        n.outputs[0].default_value = v
        return n.outputs[0]

    def math_(op, a, b=None, clamp=False):
        n = N("ShaderNodeMath")
        n.operation = op
        n.use_clamp = clamp
        for i, x in enumerate((a, b)):
            if x is None:
                continue
            if isinstance(x, (int, float)):
                n.inputs[i].default_value = x
            else:
                L(x, n.inputs[i])
        return n.outputs[0]

    def mix(a, b, f, mode="MIX"):
        n = N("ShaderNodeMix")
        n.data_type = "RGBA"
        n.blend_type = mode
        for sock, x in ((n.inputs[0], f), (n.inputs[6], a), (n.inputs[7], b)):
            if isinstance(x, (int, float)):
                sock.default_value = x
            elif isinstance(x, tuple):
                sock.default_value = (*x[:3], 1.0)
            else:
                L(x, sock)
        return n.outputs[2]

    def remap(x, a, b, c, d):
        n = N("ShaderNodeMapRange")
        n.clamp = True
        L(x, n.inputs[0])
        n.inputs[1].default_value, n.inputs[2].default_value = a, b
        n.inputs[3].default_value, n.inputs[4].default_value = c, d
        return n.outputs[0]

    pos = geo.outputs["Position"]
    sep = N("ShaderNodeSeparateXYZ")
    L(pos, sep.inputs[0])
    # 1. painted top-light gradient
    t = remap(sep.outputs[2], lo.z, hi.z, 0.0, 1.0)
    grad = remap(t, 0.0, 1.0, 0.80, 1.06)
    # facing-up faces catch sky light, overhangs go cool
    dz = N("ShaderNodeSeparateXYZ")
    L(geo.outputs["Normal"], dz.inputs[0])
    sky = remap(dz.outputs[2], -1.0, 1.0, 0.90, 1.06)
    shade = math_("MULTIPLY", grad, sky)
    # 2. cavity / contact shadow (cool)
    ao = N("ShaderNodeAmbientOcclusion")
    ao.samples = 12
    ao.inputs["Distance"].default_value = max(0.04, min(1.2, size * 0.08))
    aof = remap(ao.outputs["AO"], 0.0, 1.0, 0.0, 1.0)
    # 3. edge highlight
    bev = N("ShaderNodeBevel")
    bev.samples = 8
    bev.inputs["Radius"].default_value = max(0.004, min(0.05 if size < 12 else 0.012, size * 0.01))
    dot = N("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    L(bev.outputs[0], dot.inputs[0])
    L(geo.outputs["Normal"], dot.inputs[1])
    edge = remap(dot.outputs["Value"], 0.80, 0.995, 1.0, 0.0)
    # 4. brush mottling (object space so tiling is consistent per asset)
    tc = N("ShaderNodeTexCoord")
    nz = N("ShaderNodeTexNoise")
    L(tc.outputs["Object"], nz.inputs["Vector"])
    nz.inputs["Scale"].default_value = 2.2 / max(0.15, min(size, 6.0))
    nz.inputs["Detail"].default_value = 2.0
    mott = remap(nz.outputs["Fac"], 0.3, 0.7, 0.93, 1.05)
    vo = N("ShaderNodeTexVoronoi")
    L(tc.outputs["Object"], vo.inputs["Vector"])
    vo.inputs["Scale"].default_value = 7.0 / max(0.15, min(size, 6.0))
    dab = remap(vo.outputs["Distance"], 0.0, 0.6, 1.03, 0.97)
    mott = math_("MULTIPLY", mott, dab)
    # 5. material strokes
    st = _stroke(src.name)
    if st == "grain":
        w = N("ShaderNodeTexWave")
        L(tc.outputs["Object"], w.inputs["Vector"])
        w.wave_type = "BANDS"
        w.bands_direction = "X"
        w.inputs["Scale"].default_value = 6.0
        w.inputs["Distortion"].default_value = 6.0
        w.inputs["Detail"].default_value = 1.5
        mott = math_("MULTIPLY", mott, remap(w.outputs["Fac"], 0.0, 1.0, 0.90, 1.04))
    elif st == "bands":
        w = N("ShaderNodeTexWave")
        L(tc.outputs["Object"], w.inputs["Vector"])
        w.wave_type = "BANDS"
        w.bands_direction = "Z"
        w.inputs["Scale"].default_value = 3.0 / max(0.2, min(size, 4.0))
        w.inputs["Distortion"].default_value = 3.0
        mott = math_("MULTIPLY", mott, remap(w.outputs["Fac"], 0.0, 1.0, 0.92, 1.05))
    elif st == "rock":
        v2 = N("ShaderNodeTexVoronoi")
        L(tc.outputs["Object"], v2.inputs["Vector"])
        v2.feature = "DISTANCE_TO_EDGE"
        v2.inputs["Scale"].default_value = 2.5 / max(0.2, min(size, 6.0))
        mott = math_("MULTIPLY", mott, remap(v2.outputs["Distance"], 0.0, 0.05, 0.94, 1.0))
    elif st == "speckle":
        v2 = N("ShaderNodeTexVoronoi")
        L(tc.outputs["Object"], v2.inputs["Vector"])
        v2.inputs["Scale"].default_value = 26.0
        sp = remap(v2.outputs["Distance"], 0.0, 0.12, 1.035, 1.0)
        mott = math_("MULTIPLY", mott, sp)
    elif st == "leaf":
        w = N("ShaderNodeTexWave")
        L(tc.outputs["Object"], w.inputs["Vector"])
        w.wave_type = "RINGS"
        w.inputs["Scale"].default_value = 3.0
        mott = math_("MULTIPLY", mott, remap(w.outputs["Fac"], 0.0, 1.0, 0.92, 1.06))
    elif st == "weave":
        ck = N("ShaderNodeTexChecker")
        L(tc.outputs["Object"], ck.inputs["Vector"])
        ck.inputs["Scale"].default_value = 90.0
        ck.inputs["Color1"].default_value = (1.0, 1.0, 1.0, 1)
        ck.inputs["Color2"].default_value = (0.95, 0.95, 0.95, 1)
        bw = N("ShaderNodeRGBToBW")
        L(ck.outputs["Color"], bw.inputs[0])
        mott = math_("MULTIPLY", mott, bw.outputs[0])
    # combine: colour * shade * mottling, cool shadows from AO, warm edge lift
    lum = math_("MULTIPLY", shade, mott)
    base = mix(col, (1, 1, 1), 0.0)
    lit = mix(base, lum, 1.0, "MULTIPLY")
    cool = mix(lit, (0.62, 0.68, 0.86), 1.0, "MULTIPLY")
    aofac = remap(aof, 0.25, 1.0, 1.0, 0.0)
    shadowed = mix(lit, cool, aofac)
    warm = mix(shadowed, (1.0, 0.93, 0.80), 1.0, "SCREEN")
    edged = mix(shadowed, warm, math_("MULTIPLY", edge, 0.28))
    L(edged, emi.inputs["Color"])
    return m


def bake_paint(objs, asset_id, res=512):
    objs = bakeable(objs)
    if not objs:
        return None
    lo, hi = bounds(objs)
    _cycles()
    img = bpy.data.images.get("T_%s_BC" % asset_id)
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new("T_%s_BC" % asset_id, res, res, alpha=False)
    img.generated_color = (0.55, 0.47, 0.38, 1.0)  # warm neutral behind the islands (no black/white seams in mips)
    img.colorspace_settings.name = "sRGB"
    saved = {}
    temp = {}
    for o in objs:
        saved[o] = [s.material for s in o.material_slots]
        for s in o.material_slots:
            src = s.material
            if src is None:
                continue
            k = MT.kind_of(src)
            if k == "special":
                tm = temp.get(("special", src.name))
                if tm is None:
                    tm = bpy.data.materials.new("__bake_special")
                    tm.use_nodes = True
                    temp[("special", src.name)] = tm
            else:
                tm = temp.get(src.name)
                if tm is None:
                    tm = _paint_material(src, lo, hi, white=(k == "tint"))
                    temp[src.name] = tm
            tn = tm.node_tree.nodes.new("ShaderNodeTexImage")
            tn.image = img
            tm.node_tree.nodes.active = tn
            s.material = tm
    _sel(objs)
    bpy.ops.object.bake(type="EMIT", margin=16, use_clear=True)
    for o, ms in saved.items():
        for s, m in zip(o.material_slots, ms):
            s.material = m
    for tm in temp.values():
        bpy.data.materials.remove(tm)
    img.pack()
    return img


def sculpt_normal(objs, asset_id, res=512, strength=0.6, scale=4.0, detail=6.0, kind="CLOUDS"):
    """Sculpt-style surface detail: displaced subdivided copy -> normal map."""
    objs = bakeable(objs)
    if not objs:
        return None
    lo, hi = bounds(objs)
    size = max((hi - lo).length, 0.05)
    _cycles(8)
    img = bpy.data.images.new("T_%s_N" % asset_id, res, res, alpha=False)
    img.colorspace_settings.name = "Non-Color"
    tex = bpy.data.textures.new("__sculpt", "CLOUDS" if kind == "CLOUDS" else "VORONOI")
    if kind == "CLOUDS":
        tex.noise_scale = size / scale
        tex.noise_depth = 2
    else:
        tex.noise_scale = size / scale
    for o in objs:
        hp = o.copy()
        hp.data = o.data.copy()
        bpy.context.scene.collection.objects.link(hp)
        sub = hp.modifiers.new("s", "SUBSURF")
        sub.levels = 2
        sub.render_levels = 2
        dp = hp.modifiers.new("d", "DISPLACE")
        dp.texture = tex
        dp.strength = strength * size * 0.012
        dp.mid_level = 0.5
        tn_mats = []
        for s in o.material_slots:
            m = s.material
            if m is None:
                continue
            nt = m.node_tree
            n = nt.nodes.new("ShaderNodeTexImage")
            n.image = img
            nt.nodes.active = n
            tn_mats.append((m, n))
        _sel([hp, o], o)
        bpy.ops.object.bake(type="NORMAL", use_selected_to_active=True, cage_extrusion=size * 0.02, max_ray_distance=size * 0.05,
                            normal_space="TANGENT", margin=16, use_clear=(o == objs[0]))
        for m, n in tn_mats:
            m.node_tree.nodes.remove(n)
        bpy.data.objects.remove(hp, do_unlink=True)
    bpy.data.textures.remove(tex)
    img.pack()
    return img


def finalize(objs, asset_id, bc, nrm=None, rough=0.85):
    """Collapse paint materials into MAT_<id>; wire the atlas into tint ones."""
    objs = bakeable(objs)
    if not objs or bc is None:
        return
    camel = "".join(p.capitalize() for p in asset_id.split("_"))
    main = bpy.data.materials.new("MAT_" + camel)
    main.use_nodes = True
    nt = main.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tx = nt.nodes.new("ShaderNodeTexImage")
    tx.image = bc
    nt.links.new(tx.outputs[0], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = 0.0
    try:
        b.inputs["Specular IOR Level"].default_value = 0.2
    except KeyError:
        pass
    if nrm is not None:
        nx = nt.nodes.new("ShaderNodeTexImage")
        nx.image = nrm
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(nx.outputs[0], nm.inputs["Color"])
        nt.links.new(nm.outputs[0], b.inputs["Normal"])
    tinted = {}
    for o in objs:
        old = [s.material for s in o.material_slots]
        new_list = []
        remap = {}
        for i, m in enumerate(old):
            if m is None:
                tgt = main
            else:
                k = MT.kind_of(m)
                if k == "paint":
                    tgt = main
                elif k == "tint":
                    tgt = tinted.get(m.name)
                    if tgt is None:
                        tgt = _tint_material(m, bc)
                        tinted[m.name] = tgt
                else:
                    tgt = m
            if tgt not in new_list:
                new_list.append(tgt)
            remap[i] = new_list.index(tgt)
        idx = [remap.get(p.material_index, 0) for p in o.data.polygons]
        o.data.materials.clear()
        for m in new_list:
            o.data.materials.append(m)
        for p, i in zip(o.data.polygons, idx):
            p.material_index = i


RENAMED = []


def restore_names(asset_id):
    """After export: give the palette its names back so the next asset can reuse them."""
    for pal, tex, name in RENAMED:
        tex.name = name + "__" + asset_id
        pal.name = name
    RENAMED.clear()


def _tint_material(src, bc):
    """Same name as the palette material (Godot contract) but textured."""
    keep = src.get("tt_name", src.name)
    src.name = keep + "__palette"
    m = bpy.data.materials.new(keep)
    m.use_nodes = True
    m["tt_kind"] = "tint"
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tx = nt.nodes.new("ShaderNodeTexImage")
    tx.image = bc
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    nt.links.new(tx.outputs[0], mix.inputs[6])
    mix.inputs[7].default_value = (*MT.hexc(MT.base_hex(src)), 1.0)
    nt.links.new(mix.outputs[2], b.inputs["Base Color"])
    sb = next(n for n in src.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    for k in ("Roughness", "Metallic"):
        b.inputs[k].default_value = sb.inputs[k].default_value
    try:
        b.inputs["Specular IOR Level"].default_value = 0.25
    except KeyError:
        pass
    RENAMED.append((src, m, keep))
    return m
