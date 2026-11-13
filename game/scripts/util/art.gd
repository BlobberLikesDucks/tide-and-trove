class_name Art
extends RefCounted
## Loads the Blender-built .glb models, converts their materials to the
## cel-shaded look (toon diffuse + toon specular + rim), and builds colliders.

static var _scenes := {}
const CEL_SHADER := preload("res://assets/shaders/cel.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/cel_outline.gdshader")
static var _outline: ShaderMaterial
static var _toon := {}
static var _tint := {}
static var _ghost := {}
static var _meshes := {}


static func model(id: String) -> Node3D:
	var ps: PackedScene = _scenes.get(id)
	if ps == null:
		var path := "res://assets/models/%s.glb" % id
		if not ResourceLoader.exists(path):
			push_warning("Missing model " + path)
			var fallback := MeshInstance3D.new()
			fallback.mesh = BoxMesh.new()
			return fallback
		ps = load(path)
		_scenes[id] = ps
	var n: Node3D = ps.instantiate()
	toonify(n)
	_prep_bodies(n)
	return n


## Prepares a scene that was laid out in the editor: cel-shades every instanced
## Blender model, normalises their collision proxies, and turns shadows off for
## anything in the "no_shadow" group (ground sheets, the sea).
static func prepare(root: Node) -> void:
	toonify(root)
	_prep_bodies(root)
	for n in root.get_tree().get_nodes_in_group("no_shadow") if root.is_inside_tree() else []:
		if root.is_ancestor_of(n) or n == root:
			for mi in meshes(n):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Blender collision proxies ("-convcolonly" / "-colonly" meshes) import as
## StaticBody3D. Match the game's static-collider convention (layer 1, no mask).
static func _prep_bodies(root: Node) -> void:
	for c in root.get_children():
		if c is StaticBody3D:
			(c as StaticBody3D).collision_layer = 1
			(c as StaticBody3D).collision_mask = 0
		_prep_bodies(c)


static func has_proxy(root: Node) -> bool:
	if root is StaticBody3D:
		return true
	for c in root.get_children():
		if has_proxy(c):
			return true
	return false


## Remove Blender collision proxies (ghost previews, held / decorative copies).
static func strip_collision(root: Node) -> void:
	for c in root.get_children():
		if c is StaticBody3D:
			root.remove_child(c)
			c.queue_free()
		else:
			strip_collision(c)


## First mesh of a model (used by FX particles).
static func mesh_of(id: String) -> Mesh:
	if _meshes.has(id):
		return _meshes[id]
	var n := model(id)
	var mis := meshes(n)
	var m: Mesh = mis[0].mesh if not mis.is_empty() else null
	if m and not mis.is_empty() and mis[0].get_surface_override_material(0):
		m = m.duplicate()
		for i in range(m.get_surface_count()):
			var o := mis[0].get_surface_override_material(i)
			if o:
				m.surface_set_material(i, o)
	n.free()
	_meshes[id] = m
	return m


## Blender model placed as a child of `parent` at `pos` (rotation y in radians).
static func place(parent: Node, id: String, pos: Vector3, rot_y: float = 0.0, shadows: bool = true) -> Node3D:
	var n := model(id)
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	if not shadows:
		for mi in meshes(n):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


## The Blender sea grid with the animated water shader on it.
static func sea(parent: Node, pos: Vector3, shore_z: float = 47.0) -> Node3D:
	var n := model("water_plane")
	n.position = pos
	parent.add_child(n)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/water.gdshader")
	sm.set_shader_parameter("shore_z", shore_z)
	for mi in meshes(n):
		mi.material_override = sm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


static func meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		out.append(root)
	for c in root.get_children():
		out.append_array(meshes(c))
	return out


## Cel-shading (godot-shader skill): opaque painted materials become a
## ShaderMaterial running cel.gdshader (banded light, toon specular, rim) with an
## inverted-hull ink outline as next_pass. Glass, glows and other transparent or
## unshaded surfaces keep a StandardMaterial3D toon setup.
static func toon(m: Material) -> Material:
	if not (m is BaseMaterial3D):
		return m
	if _toon.has(m):
		return _toon[m]
	var b := m as BaseMaterial3D
	var out: Material
	if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or not GameConfig.get_cfg().cel_shading:
		var t: BaseMaterial3D = b.duplicate()
		t.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		t.specular_mode = BaseMaterial3D.SPECULAR_TOON
		t.rim_enabled = true
		t.rim = 0.22
		t.rim_tint = 0.65
		if t.metallic > 0.5:
			t.metallic = 0.35
		t.roughness = maxf(t.roughness, 0.3)
		out = t
	else:
		var sm := ShaderMaterial.new()
		sm.shader = CEL_SHADER
		sm.resource_name = b.resource_name
		sm.set_shader_parameter("albedo_color", b.albedo_color)
		if b.albedo_texture:
			sm.set_shader_parameter("albedo_texture", b.albedo_texture)
		if b.normal_enabled and b.normal_texture:
			sm.set_shader_parameter("normal_texture", b.normal_texture)
			sm.set_shader_parameter("use_normal_map", true)
		if b.emission_enabled:
			sm.set_shader_parameter("emission_color", b.emission)
			sm.set_shader_parameter("emission_energy", b.emission_energy_multiplier)
		sm.next_pass = outline_material()
		out = sm
	_toon[m] = out
	return out


static func outline_material() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = OUTLINE_SHADER
		_outline.set_shader_parameter("outline_width", GameConfig.get_cfg().outline_width)
		_outline.set_shader_parameter("outline_color", GameConfig.get_cfg().outline_color)
	return _outline


static func toonify(root: Node) -> void:
	for mi in meshes(root):
		if mi.mesh == null:
			continue
		# ground sheets, streets and other huge flat meshes get no ink outline
		var big := mi.mesh.get_aabb().size.length() > 25.0
		for i in range(mi.mesh.get_surface_count()):
			var m := mi.mesh.surface_get_material(i)
			if m:
				mi.set_surface_override_material(i, _no_outline(toon(m)) if big else toon(m))


static var _plain := {}


static func _no_outline(m: Material) -> Material:
	if not (m is ShaderMaterial) or m.next_pass == null:
		return m
	if not _plain.has(m):
		var d: ShaderMaterial = m.duplicate()
		d.next_pass = null
		_plain[m] = d
	return _plain[m]


## Recolour every surface whose source material is named `mat_name`.
static func tint(root: Node, mat_name: String, color: Color, emission: float = 0.0) -> void:
	for mi in meshes(root):
		if mi.mesh == null:
			continue
		for i in range(mi.mesh.get_surface_count()):
			var src := mi.mesh.surface_get_material(i)
			if src == null or src.resource_name != mat_name:
				continue
			var key := "%d|%s|%.2f" % [src.get_instance_id(), color.to_html(), emission]
			var t: Material = _tint.get(key)
			if t == null:
				t = toon(src).duplicate()
				if t is ShaderMaterial:
					var sm := t as ShaderMaterial
					sm.set_shader_parameter("albedo_color", color)
					if emission > 0.0:
						sm.set_shader_parameter("emission_color", color)
						sm.set_shader_parameter("emission_energy", emission)
				elif t is BaseMaterial3D:
					var bm := t as BaseMaterial3D
					bm.albedo_color = color
					if emission > 0.0:
						bm.emission_enabled = true
						bm.emission = color
						bm.emission_energy_multiplier = emission
				_tint[key] = t
			mi.set_surface_override_material(i, t)


static func ghostify(root: Node, color: Color) -> void:
	var key := color.to_html()
	var m: StandardMaterial3D = _ghost.get(key)
	if m == null:
		m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = color
		m.no_depth_test = false
		_ghost[key] = m
	for mi in meshes(root):
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func local_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in meshes(root):
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != null and n != root:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b := xf * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


static func box_collider(parent: Node3D, size: Vector3, center: Vector3, layer: int = 1) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = layer
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(size.x, 0.05), maxf(size.y, 0.05), maxf(size.z, 0.05))
	cs.shape = shape
	cs.position = center
	sb.add_child(cs)
	parent.add_child(sb)
	return sb


## Static box collider fitted to the model's mesh bounds (optionally shrunk).
static func fit_collider(root: Node3D, shrink: float = 1.0, layer: int = 1) -> StaticBody3D:
	var b := local_aabb(root)
	return box_collider(root, b.size * Vector3(shrink, 1.0, shrink), b.get_center(), layer)


static func label3d(text: String, size: int = 48, color: Color = Color.WHITE, billboard: bool = true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = UIKit.font(true)
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = 10
	l.outline_modulate = Color(0.1, 0.1, 0.14, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	l.no_depth_test = false
	l.double_sided = true
	return l


static func toon_mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.15
	return m
