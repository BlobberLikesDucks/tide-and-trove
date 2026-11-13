"""QA contact sheets (qa-review + lookdev skills).

Renders every lineup asset in the build scene from a 3/4 hero angle under a
warm key / cool fill stylized rig (EEVEE), labels nothing, tiles the thumbnails
into blender/qa/<name>.png for a ship / no-ship visual review.
"""
import math
import os

import bpy
import numpy as np
from mathutils import Vector

from . import paint as PT
from . import pipe


def _rig(scn):
    for n in ("QA_Cam", "QA_Key", "QA_Fill"):
        o = bpy.data.objects.get(n)
        if o:
            bpy.data.objects.remove(o, do_unlink=True)
    cam = bpy.data.objects.new("QA_Cam", bpy.data.cameras.new("QA_Cam"))
    scn.collection.objects.link(cam)
    cam.data.lens = 50
    key = bpy.data.objects.new("QA_Key", bpy.data.lights.new("QA_Key", "SUN"))
    key.data.energy = 3.2
    key.data.color = (1.0, 0.95, 0.86)
    key.data.angle = math.radians(3)
    key.rotation_euler = (math.radians(48), 0, math.radians(-35))
    scn.collection.objects.link(key)
    fill = bpy.data.objects.new("QA_Fill", bpy.data.lights.new("QA_Fill", "SUN"))
    fill.data.energy = 0.9
    fill.data.color = (0.7, 0.8, 1.0)
    fill.rotation_euler = (math.radians(60), 0, math.radians(150))
    scn.collection.objects.link(fill)
    w = bpy.data.worlds.get("QA_World") or bpy.data.worlds.new("QA_World")
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.42, 0.5, 0.58, 1)
    bg.inputs[1].default_value = 0.9
    scn.world = w
    scn.camera = cam
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            scn.render.engine = eng
            break
        except TypeError:
            continue
    try:
        scn.view_settings.view_transform = "AgX"
        scn.view_settings.look = "AgX - Medium High Contrast"
    except TypeError:
        pass
    return cam, key, fill


def sheet(name, cols=6, tile=300, view=(0.55, -1.0, 0.55)):
    scn = pipe.SCN or bpy.context.scene
    roots = [o for o in scn.objects if o.get("tt_lineup") and (o.parent is None or not o.parent.get("tt_lineup"))]
    roots.sort(key=lambda o: (-o.location.y, o.location.x))
    cam, key, fill = _rig(scn)
    scn.render.resolution_x = scn.render.resolution_y = tile
    scn.render.film_transparent = False
    tmp = os.path.join(pipe.QA, "_tile.png")
    os.makedirs(pipe.QA, exist_ok=True)
    all_objs = [o for o in scn.objects if o.get("tt_lineup")]
    tiles = []
    for r in roots:
        group = [o for o in pipe.descendants(r) if o.type == "MESH" and not o.get("tt_collision")]
        if not group:
            continue
        for o in all_objs:
            o.hide_render = o not in group
        lo, hi = PT.bounds(group)
        c = (lo + hi) / 2
        rad = max((hi - lo).length / 2, 0.1)
        d = Vector(view).normalized()
        cam.location = c - d * -1 * 0 + d * 0  # reset
        cam.location = c + Vector((d.x, d.y, d.z)) * (rad / math.tan(math.radians(18)) * 1.05)
        look = (c - cam.location).normalized()
        cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(tmp, check_existing=False)
        px = np.empty(tile * tile * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        tiles.append(px.reshape(tile, tile, 4).copy())
        bpy.data.images.remove(img)
    for o in all_objs:
        o.hide_render = bool(o.get("tt_collision"))
    if not tiles:
        return None
    rows = (len(tiles) + cols - 1) // cols
    out = np.ones((rows * tile, cols * tile, 4), dtype=np.float32)
    for i, t in enumerate(tiles):
        rr, cc = divmod(i, cols)
        rr = rows - 1 - rr
        out[rr * tile:(rr + 1) * tile, cc * tile:(cc + 1) * tile] = t
    im = bpy.data.images.new("QA_" + name, cols * tile, rows * tile, alpha=True)
    im.pixels.foreach_set(out.ravel())
    path = os.path.join(pipe.QA, name + ".png")
    im.filepath_raw = path
    im.file_format = "PNG"
    im.save()
    bpy.data.images.remove(im)
    if os.path.exists(tmp):
        os.remove(tmp)
    return path
