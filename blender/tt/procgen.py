"""Procedural helpers (geometry-nodes + procedural-modeling skills).

scatter() builds a Geometry Nodes tree GN_Scatter_<target>:
    Distribute Points on Faces (Poisson, density, seed, upward-facing mask)
    -> Instance on Points (pick instance from a collection, random rotation / scale)
    -> Realize Instances -> Join with the original surface.
The modifier is applied before export (Godot cannot evaluate GN), so the result is
plain, bakeable mesh data that still came from a node-based scatter.
"""
import bpy


def _sock(sockets, name, index=0):
    hits = [s for s in sockets if s.name == name and getattr(s, "enabled", True)]
    return hits[index] if hits else None


def _build_group(name, col, density, seed, scale, min_dist, up):
    ng = bpy.data.node_groups.new(name, "GeometryNodeTree")
    ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    N = ng.nodes.new
    L = ng.links.new
    gi = N("NodeGroupInput")
    go = N("NodeGroupOutput")
    nrm = N("GeometryNodeInputNormal")
    sep = N("ShaderNodeSeparateXYZ")
    L(nrm.outputs[0], sep.inputs[0])
    cmp_ = N("FunctionNodeCompare")
    cmp_.data_type = "FLOAT"
    cmp_.operation = "GREATER_THAN"
    L(sep.outputs["Z"], _sock(cmp_.inputs, "A"))
    _sock(cmp_.inputs, "B").default_value = up
    dist = N("GeometryNodeDistributePointsOnFaces")
    dist.distribute_method = "POISSON"
    L(gi.outputs[0], dist.inputs["Mesh"])
    L(cmp_.outputs[0], dist.inputs["Selection"])
    dist.inputs["Distance Min"].default_value = min_dist
    dist.inputs["Density Max"].default_value = density
    dist.inputs["Seed"].default_value = seed
    ci = N("GeometryNodeCollectionInfo")
    ci.transform_space = "ORIGINAL"
    ci.inputs["Collection"].default_value = col
    ci.inputs["Separate Children"].default_value = True
    ci.inputs["Reset Children"].default_value = True
    rot = N("FunctionNodeRandomValue")
    rot.data_type = "FLOAT_VECTOR"
    _sock(rot.inputs, "Min").default_value = (0.0, 0.0, 0.0)
    _sock(rot.inputs, "Max").default_value = (0.12, 0.12, 6.283)
    _sock(rot.inputs, "Seed").default_value = seed
    scl = N("FunctionNodeRandomValue")
    scl.data_type = "FLOAT"
    _sock(scl.inputs, "Min").default_value = scale[0]
    _sock(scl.inputs, "Max").default_value = scale[1]
    _sock(scl.inputs, "Seed").default_value = seed + 7
    inst = N("GeometryNodeInstanceOnPoints")
    inst.inputs["Pick Instance"].default_value = True
    L(dist.outputs["Points"], inst.inputs["Points"])
    L(ci.outputs[0], inst.inputs["Instance"])
    L(_sock(rot.outputs, "Value"), inst.inputs["Rotation"])
    L(_sock(scl.outputs, "Value"), inst.inputs["Scale"])
    real = N("GeometryNodeRealizeInstances")
    L(inst.outputs[0], real.inputs[0])
    join = N("GeometryNodeJoinGeometry")
    L(real.outputs[0], join.inputs[0])
    L(gi.outputs[0], join.inputs[0])
    L(join.outputs[0], go.inputs[0])
    return ng


TILE = 0.125      # trim-sheet tile size for scattered props (texture-workflow: trim sheets)
STRIP_V = 0.875   # reserved atlas strip v in [0.875, 1]; the host surface unwraps below it


def _tile_uv(o, k):
    """Unwrap one scatter source into its own trim tile and flag its faces, so every
    copy shares a properly sized texel block instead of a sub-pixel island."""
    me = o.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    for x in list(bpy.context.scene.objects):
        x.select_set(False)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.03, scale_to_bounds=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    u0 = (k % 8) * TILE
    for lp in me.uv_layers.active.data:
        u, v = lp.uv
        lp.uv = (u0 + 0.004 + u * (TILE - 0.008), STRIP_V + 0.004 + v * (TILE - 0.008))
    a = me.attributes.get("tt_fixed_uv") or me.attributes.new("tt_fixed_uv", "INT", "FACE")
    a.data.foreach_set("value", [1] * len(me.polygons))


def scatter(target, instances, density=1.0, seed=0, scale=(0.7, 1.3), min_dist=0.2, up=0.6):
    """Scatter copies of `instances` (list of objects, removed afterwards) over `target`."""
    if not target.data.uv_layers:
        target.data.uv_layers.new(name="UVMap")
    if "tt_fixed_uv" not in target.data.attributes:
        target.data.attributes.new("tt_fixed_uv", "INT", "FACE")
    k0 = int(target.get("tt_tiles", 0))
    for k, o in enumerate(instances):
        _tile_uv(o, k0 + k)
    target["tt_tiles"] = k0 + len(instances)
    col = bpy.data.collections.new("GN_src_%s_%d" % (target.name, seed))
    bpy.context.scene.collection.children.link(col)
    for o in instances:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        col.objects.link(o)
        o.location = (0, 0, 0)
    for o in instances:
        for m in o.data.materials:
            if m and m.name not in [x.name for x in target.data.materials if x]:
                target.data.materials.append(m)
    ng = _build_group("GN_Scatter_%s_%d" % (target.name, seed), col, density, seed, scale, min_dist, up)
    mod = target.modifiers.new("GN_Scatter", "NODES")
    mod.node_group = ng
    for o in list(bpy.context.scene.objects):
        o.select_set(False)
    bpy.context.view_layer.objects.active = target
    target.select_set(True)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    for o in list(col.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.collections.remove(col)
    bpy.data.node_groups.remove(ng)
    return target
