"""Tide & Trove asset kit - mesh primitives (bmesh). Every builder appends
into a Part (one bmesh + material slots); pipe.finish() turns it into an object."""
import bmesh, math
from mathutils import Vector, Matrix, Euler, noise

TAU = math.tau

def T(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    return Matrix.LocRotScale(Vector(loc), Euler([math.radians(a) for a in rot]), Vector(scale))


class Part:
    def __init__(self):
        self.bm = bmesh.new()
        self.mats = []

    def mi(self, m):
        if m not in self.mats:
            self.mats.append(m)
        return self.mats.index(m)


def _merge(p, t, mat):
    idx = p.mi(mat)
    t.verts.index_update()
    vm = [p.bm.verts.new(v.co) for v in t.verts]
    for f in t.faces:
        try:
            nf = p.bm.faces.new([vm[v.index] for v in f.verts])
        except ValueError:
            continue
        nf.material_index = idx
    t.free()


def _xf(t, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    bmesh.ops.transform(t, matrix=T(loc, rot, scale), verts=t.verts)


def box(p, mat, size, loc=(0, 0, 0), rot=(0, 0, 0)):
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    _xf(t, loc, rot, size)
    _merge(p, t, mat)


def rbox(p, mat, size, loc=(0, 0, 0), rot=(0, 0, 0), r=0.02, seg=2):
    """Rounded (bevelled) box."""
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    _xf(t, scale=size)
    rr = min(r, min(size) * 0.48)
    if rr > 1e-4:
        bmesh.ops.bevel(t, geom=list(t.verts) + list(t.edges), offset=rr, segments=seg, affect="EDGES", profile=0.5, clamp_overlap=True)
    _xf(t, loc, rot)
    _merge(p, t, mat)


def cyl(p, mat, r, h, loc=(0, 0, 0), rot=(0, 0, 0), seg=16, r2=None, scale=(1, 1, 1)):
    t = bmesh.new()
    bmesh.ops.create_cone(t, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=(r if r2 is None else r2), depth=h)
    _xf(t, loc, rot, scale)
    _merge(p, t, mat)


def sph(p, mat, r, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), u=16, v=10, hemi=False):
    t = bmesh.new()
    bmesh.ops.create_uvsphere(t, u_segments=u, v_segments=v, radius=r)
    if hemi:
        bmesh.ops.delete(t, geom=[x for x in t.verts if x.co.z < -1e-4], context="VERTS")
        bmesh.ops.holes_fill(t, edges=[e for e in t.edges if e.is_boundary])
    _xf(t, loc, rot, scale)
    _merge(p, t, mat)


def lathe(p, mat, prof, seg=20, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), close_top=True, close_bottom=True):
    """Revolve a (radius, z) profile around Z."""
    t = bmesh.new()
    rings = []
    for r, z in prof:
        if r < 1e-4:
            rings.append([t.verts.new((0, 0, z))])
        else:
            rings.append([t.verts.new((r * math.cos(a / seg * TAU), r * math.sin(a / seg * TAU), z)) for a in range(seg)])
    for i in range(len(rings) - 1):
        a, b = rings[i], rings[i + 1]
        for k in range(seg):
            if len(a) == 1 and len(b) > 1:
                t.faces.new((a[0], b[(k + 1) % seg], b[k]))
            elif len(b) == 1 and len(a) > 1:
                t.faces.new((a[k], a[(k + 1) % seg], b[0]))
            elif len(a) > 1 and len(b) > 1:
                t.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
    if close_bottom and len(rings[0]) > 1:
        t.faces.new(list(reversed(rings[0])))
    if close_top and len(rings[-1]) > 1:
        t.faces.new(rings[-1])
    _xf(t, loc, rot, scale)
    _merge(p, t, mat)


def tube(p, mat, pts, radii, seg=10, cap=True, scale=None):
    pts = [Vector(x) for x in pts]
    n = len(pts)
    if isinstance(radii, (int, float)):
        radii = [radii] * n
    t = bmesh.new()
    tans = []
    for i in range(n):
        d = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        tans.append(d.normalized() if d.length > 1e-6 else Vector((0, 0, 1)))
    up = Vector((0, 0, 1)) if abs(tans[0].z) < 0.9 else Vector((1, 0, 0))
    nrm = tans[0].cross(up).normalized()
    rings = []
    for i in range(n):
        tg = tans[i]
        nrm = nrm - tg * nrm.dot(tg)
        if nrm.length < 1e-6:
            nrm = tg.orthogonal()
        nrm.normalize()
        bi = tg.cross(nrm).normalized()
        r = max(radii[i], 0.002)
        rings.append([t.verts.new(pts[i] + nrm * math.cos(k / seg * TAU) * r + bi * math.sin(k / seg * TAU) * r) for k in range(seg)])
    for i in range(n - 1):
        for k in range(seg):
            t.faces.new((rings[i][k], rings[i][(k + 1) % seg], rings[i + 1][(k + 1) % seg], rings[i + 1][k]))
    if cap:
        t.faces.new(list(reversed(rings[0])))
        t.faces.new(rings[-1])
    if scale:
        c = sum(pts, Vector()) / n
        sz = scale[2] if len(scale) > 2 else 1.0
        bmesh.ops.transform(t, matrix=Matrix.Translation(c) @ Matrix.Diagonal((scale[0], scale[1], sz, 1.0)) @ Matrix.Translation(-c), verts=t.verts)
    _merge(p, t, mat)


def curve_pts(a, b, bend, n=8):
    a, b, bend = Vector(a), Vector(b), Vector(bend)
    return [a.lerp(b, i / (n - 1)) + bend * math.sin(math.pi * i / (n - 1)) for i in range(n)]


def rock(p, mat, r, loc=(0, 0, 0), scale=(1, 1, 1), seed=0, sub=3, rough=0.28, freq=1.3, floor=-0.4, rot=(0, 0, 0)):
    t = bmesh.new()
    bmesh.ops.create_icosphere(t, subdivisions=sub, radius=1.0)
    off = Vector((seed * 13.1, seed * 7.7, seed * 3.3))
    for v in t.verts:
        n = v.co.normalized()
        d = noise.noise(n * freq + off) * 0.6 + noise.noise(n * freq * 2.4 + off) * 0.3 + noise.noise(n * 5.5 + off) * 0.12
        v.co = n * r * (1.0 + rough * d)
        if v.co.z < floor * r:
            v.co.z = floor * r + (v.co.z - floor * r) * 0.08
    _xf(t, loc, rot, scale)
    _merge(p, t, mat)


def slab(p, mat, size, loc=(0, 0, 0), rot=(0, 0, 0), seed=0, rough=0.06, cuts=4):
    """Noisy rounded slab (strata layers, stone)."""
    t = bmesh.new()
    bmesh.ops.create_cube(t, size=1.0)
    bmesh.ops.subdivide_edges(t, edges=t.edges[:], cuts=cuts, use_grid_fill=True)
    off = Vector((seed * 3.7, seed * 1.9, seed * 5.3))
    for v in t.verts:
        q = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
        d = noise.noise(q * 0.9 + off) * 0.7 + noise.noise(q * 2.7 + off) * 0.3
        v.co = Vector((v.co.x * size[0] + d * rough * 2.5, v.co.y * size[1] + d * rough * 2.5, v.co.z * size[2] + d * rough))
    _xf(t, loc, rot)
    _merge(p, t, mat)


def leaf(p, mat, base, yaw, length, width, rise=0.35, droop=0.9, segs=7, thick=0.012, pitch=0.0, fold=0.3):
    """Two-sided leaf strip with a centre fold."""
    t = bmesh.new()
    rows = []
    for i in range(segs + 1):
        u = i / segs
        x = length * u
        z = rise * length * u - droop * length * u * u
        w = width * math.sin(math.pi * min(0.97, 0.06 + u * 0.94))
        f = w * fold
        rows.append([t.verts.new((x, w, z - f + thick)), t.verts.new((x, 0, z + thick)), t.verts.new((x, -w, z - f + thick)),
                     t.verts.new((x, w, z - f - thick)), t.verts.new((x, 0, z - thick)), t.verts.new((x, -w, z - f - thick))])
    for i in range(segs):
        a, b = rows[i], rows[i + 1]
        t.faces.new((a[0], a[1], b[1], b[0]))
        t.faces.new((a[1], a[2], b[2], b[1]))
        t.faces.new((b[3], b[4], a[4], a[3]))
        t.faces.new((b[4], b[5], a[5], a[4]))
    _xf(t, base, (0, pitch, yaw))
    _merge(p, t, mat)


def spiral(p, mats, turns=3.2, a=0.012, growth=0.19, tube_k=0.42, ppt=24, center=(0, 0, 0), ribs=True, seg=12, centered=False):
    """Log spiral (ammonite). centered=True puts the shell's bounding box (not the
    spiral's origin) on `center`, so it sits in the middle of a frame or plaque."""
    n = int(turns * ppt)
    pts, rad = [], []
    for i in range(n + 1):
        th = i / ppt * TAU
        r = a * math.exp(growth * th)
        pts.append((center[0] + r * math.cos(th), center[1], center[2] + r * math.sin(th)))
        rr = r * tube_k
        if ribs and i % 2 == 1:
            rr *= 1.1
        rad.append(rr)
    if centered:
        xs = [q[0] - rr for q, rr in zip(pts, rad)] + [q[0] + rr for q, rr in zip(pts, rad)]
        zs = [q[2] - rr for q, rr in zip(pts, rad)] + [q[2] + rr for q, rr in zip(pts, rad)]
        dx = center[0] - (min(xs) + max(xs)) / 2
        dz = center[2] - (min(zs) + max(zs)) / 2
        pts = [(q[0] + dx, q[1], q[2] + dz) for q in pts]
    band = max(3, ppt // 3)
    i, k = 0, 0
    while i < n:
        j = min(n, i + band)
        tube(p, mats[k % len(mats)], pts[i:j + 1], rad[i:j + 1], seg=seg, cap=(i == 0 or j == n))
        i = j
        k += 1


def star_path(cx, cy, r1, r2, n=5):
    return [(cx + (r1 if i % 2 == 0 else r2) * math.cos(-math.pi / 2 + i * math.pi / n),
             cy + (r1 if i % 2 == 0 else r2) * math.sin(-math.pi / 2 + i * math.pi / n)) for i in range(2 * n)]


FONT_PATHS = (r"C:\Windows\Fonts\COOPBL.TTF", r"C:\Windows\Fonts\georgiab.ttf", r"C:\Windows\Fonts\arialbd.ttf")


def _font():
    import bpy, os
    for path in FONT_PATHS:
        if os.path.exists(path):
            try:
                return bpy.data.fonts.load(path, check_existing=True)
            except RuntimeError:
                continue
    return None


def text3d(p, mat, body, size=0.3, loc=(0, 0, 0), rot=(90, 0, 0), depth=0.012, max_w=None, max_h=None, line=0.95, res=3):
    """Extruded 3D lettering (Cooper Black, the seaside-sign face) merged into the
    part as real geometry, so signs light, shade and texture like the rest of the
    model. rot=(90,0,0) faces Blender -Y (the model front); (90,0,180) faces +Y.
    max_w / max_h shrink the text to fit its board."""
    import bpy
    cu = bpy.data.curves.new("tt_text", "FONT")
    cu.body = body
    f = _font()
    if f:
        cu.font = f
    cu.size = size
    cu.extrude = depth
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.space_line = line
    cu.resolution_u = res
    ob = bpy.data.objects.new("tt_text", cu)
    bpy.context.scene.collection.objects.link(ob)
    deps = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(deps))
    bpy.data.objects.remove(ob)
    bpy.data.curves.remove(cu)
    t = bmesh.new()
    t.from_mesh(me)
    bpy.data.meshes.remove(me)
    if t.verts:
        xs = [v.co.x for v in t.verts]
        ys = [v.co.y for v in t.verts]
        w, h = max(xs) - min(xs), max(ys) - min(ys)
        k = 1.0
        if max_w and w > max_w:
            k = min(k, max_w / w)
        if max_h and h > max_h:
            k = min(k, max_h / h)
        cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
        bmesh.ops.translate(t, vec=Vector((-cx, -cy, depth)), verts=t.verts)
        if k < 1.0:
            bmesh.ops.scale(t, vec=(k, k, 1.0), verts=t.verts)
    bmesh.ops.remove_doubles(t, verts=t.verts, dist=1e-5)
    _xf(t, loc, rot)
    _merge(p, t, mat)


def prism(p, mat, poly, h, z=0.0, plane="XY", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Extrude a 2D polygon by h."""
    t = bmesh.new()
    if plane == "XY":
        b = [t.verts.new((x, y, z)) for x, y in poly]
        top = [t.verts.new((x, y, z + h)) for x, y in poly]
    else:  # XZ (thickness along Y)
        b = [t.verts.new((x, z, y)) for x, y in poly]
        top = [t.verts.new((x, z + h, y)) for x, y in poly]
    n = len(poly)
    t.faces.new(list(reversed(b)))
    t.faces.new(top)
    for i in range(n):
        t.faces.new((b[i], b[(i + 1) % n], top[(i + 1) % n], top[i]))
    bmesh.ops.recalc_face_normals(t, faces=t.faces[:])
    _xf(t, loc, rot)
    _merge(p, t, mat)

