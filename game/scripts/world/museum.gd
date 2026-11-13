class_name Museum
extends Node3D
## The museum building: grid floor plan, modular walls, roof, placed exhibits,
## visitor pathfinding (AStarGrid2D), mess (trash / sand) and the live
## Fun / Decorations / Cleanliness pillars.

const CELL := 2.0
const FRONT_Z := -22.0
const WALL_H := 3.2

var W := 5
var D := 4
var structure: Node3D
var objects: Node3D
var mess_root: Node3D
var roof: Node3D
var grid := {}
var astar := AStarGrid2D.new()
var reachable := {}
var mess: Array = []
var open_sign: Node3D
var sign_board: Node3D
var sign_inter: Interactable
var _pillar_t := 0.0


func _ready() -> void:
	structure = Node3D.new()
	add_child(structure)
	objects = Node3D.new()
	add_child(objects)
	mess_root = Node3D.new()
	add_child(mess_root)
	build_structure()
	load_objects()
	_build_frontage()


# ------------------------------------------------------------- coordinates --
func x0() -> float:
	return -W * CELL * 0.5


func cell_center(c: Vector2i) -> Vector3:
	return Vector3(x0() + (c.x + 0.5) * CELL, 0.02, FRONT_Z + (c.y + 0.5) * CELL)


func world_to_cell(p: Vector3) -> Vector2i:
	return Vector2i(floori((p.x - x0()) / CELL), floori((p.z - FRONT_Z) / CELL))


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < D


func entrance() -> Vector2i:
	return Vector2i(W / 2, 0)


func door_outside() -> Vector3:
	return Vector3(0, 0, FRONT_Z - 1.6)


func contains(p: Vector3, margin: float = 0.0) -> bool:
	return p.x > x0() - margin and p.x < -x0() + margin and p.z > FRONT_Z - margin and p.z < FRONT_Z + D * CELL + margin


func center() -> Vector3:
	return Vector3(0, 0, FRONT_Z + D * CELL * 0.5)

# --------------------------------------------------------------- structure --
func build_structure() -> void:
	var sz := GameState.museum_size()
	W = sz.x
	D = sz.y
	for c in structure.get_children():
		c.queue_free()
	var ie := entrance().x
	for i in range(W):
		var cx := x0() + (i + 0.5) * CELL
		_wall("wall_door" if i == ie else ("wall_window" if i % 2 == 1 else "wall"), Vector3(cx, 0, FRONT_Z), PI)
		_wall("wall_window" if i % 2 == 1 else ("wall_poster" if i == W / 2 else "wall"), Vector3(cx, 0, FRONT_Z + D * CELL), 0.0)
	for j in range(D):
		var cz := FRONT_Z + (j + 0.5) * CELL
		var side := "wall_poster" if j == D / 2 and j % 2 == 0 else "wall"
		_wall("wall_window" if j % 2 == 1 else side, Vector3(x0(), 0, cz), -PI / 2)
		_wall("wall_window" if j % 2 == 1 else "wall", Vector3(-x0(), 0, cz), PI / 2)
	for p in [Vector3(x0(), 0, FRONT_Z), Vector3(-x0(), 0, FRONT_Z), Vector3(x0(), 0, FRONT_Z + D * CELL), Vector3(-x0(), 0, FRONT_Z + D * CELL)]:
		var post := Art.model("wall_corner")
		post.position = p
		structure.add_child(post)
	for i in range(W):
		for j in range(D):
			var tile := Art.model("floor_tile")
			tile.position = cell_center(Vector2i(i, j))
			structure.add_child(tile)
	Art.box_collider(structure, Vector3(W * CELL, 0.4, D * CELL), Vector3(0, -0.18, FRONT_Z + D * CELL * 0.5))
	# roof
	roof = Node3D.new()
	structure.add_child(roof)
	# Blender gable roof (shingles, fascia, gable siding, attic windows) - one per museum size
	var lvl := maxi(0, DB.MUSEUM_SIZES.find(Vector2i(W, D)))
	Art.place(roof, "museum_roof_%d" % lvl, Vector3(0, 0, FRONT_Z + D * CELL * 0.5))
	rebuild_astar()


func _wall(id: String, pos: Vector3, rot_y: float) -> void:
	var w := Art.model(id)
	w.position = pos
	w.rotation.y = rot_y
	structure.add_child(w)
	if Art.has_proxy(w):  # Blender collision proxies (COL_*-convcolonly)
		return
	if id == "wall_door":
		Art.box_collider(w, Vector3(0.32, WALL_H, 0.3), Vector3(-0.85, WALL_H * 0.5, 0))
		Art.box_collider(w, Vector3(0.32, WALL_H, 0.3), Vector3(0.85, WALL_H * 0.5, 0))
		Art.box_collider(w, Vector3(1.4, 0.8, 0.3), Vector3(0, 2.8, 0))
	else:
		Art.box_collider(w, Vector3(2.0, WALL_H, 0.3), Vector3(0, WALL_H * 0.5, 0))


## The porch, path, museum sign and OPEN/CLOSED sign are placed in the editor
## under Museum/Frontage (world.tscn); the sign's InteractSpot calls back here.
func _build_frontage() -> void:
	open_sign = get_node_or_null("Frontage/OpenSign") as Node3D
	if open_sign == null:
		push_warning("Museum/Frontage/OpenSign missing from the scene")
		return
	sign_board = open_sign.find_child("Board", true, false)
	if sign_board:  # OPEN / CLOSED are carved into the two faces of the Blender board
		sign_board.rotation.y = PI
	sign_inter = open_sign.get_meta("tt_inter") if open_sign.has_meta("tt_inter") else null


func _sign_text() -> String:
	if GameState.phase == GameState.Phase.PREP:
		return "Flip sign to OPEN  (start Day %d)" % GameState.day
	if GameState.phase == GameState.Phase.OPEN:
		return "Museum is OPEN - closes at 18:00"
	return "Closed"


func _on_sign() -> void:
	if GameState.phase == GameState.Phase.PREP:
		World.instance.day_cycle.open_museum()


func set_sign_open(open: bool) -> void:
	if sign_board == null:
		return
	var tw := create_tween()
	tw.tween_property(sign_board, "rotation:y", 0.0 if open else PI, 0.6).set_trans(Tween.TRANS_BACK)


func set_roof_visible(v: bool) -> void:
	if roof:
		roof.visible = v

# ---------------------------------------------------------------- objects ---
func load_objects() -> void:
	for c in objects.get_children():
		c.queue_free()
	grid.clear()
	for e in GameState.placed:
		_spawn(e)
	rebuild_astar()


func _spawn(entry: Dictionary) -> PlacedObject:
	var o := PlacedObject.new()
	objects.add_child(o)
	o.setup(self, entry)
	for c in o.cells:
		grid[c] = o
	return o


func all_objects() -> Array:
	var out: Array = []
	for c in objects.get_children():
		if c is PlacedObject and not c.is_queued_for_deletion():
			out.append(c)
	return out


func objects_of(t: String) -> Array:
	var out: Array = []
	for o in all_objects():
		if o.type == t:
			out.append(o)
	return out


static func footprint(type: String, cell: Vector2i, rot: int) -> Array[Vector2i]:
	var s: Vector2i = DB.BUILD[type]["size"]
	if rot % 2 == 1:
		s = Vector2i(s.y, s.x)
	var out: Array[Vector2i] = []
	for i in range(s.x):
		for j in range(s.y):
			out.append(cell + Vector2i(i, j))
	return out


func footprint_center(cells: Array[Vector2i]) -> Vector3:
	var p := Vector3.ZERO
	for c in cells:
		p += cell_center(c)
	return p / cells.size()


func can_place(type: String, cell: Vector2i, rot: int, ignore: PlacedObject = null) -> String:
	var cells := footprint(type, cell, rot)
	for c in cells:
		if not in_bounds(c):
			return "Out of bounds"
		if c == entrance():
			return "Keep the entrance clear"
		if grid.has(c) and grid[c] != ignore:
			return "Space occupied"
	if DB.BUILD[type].get("walkable", false):
		return ""
	var solid := {}
	for c in grid.keys():
		if grid[c] != ignore and not grid[c].walkable():
			solid[c] = true
	for c in cells:
		solid[c] = true
	var reach := _flood(solid)
	for o in all_objects():
		if o == ignore or o.walkable():
			continue
		if not _has_access(o.cells, reach):
			return "Would block visitor paths"
	if not _has_access(cells, reach):
		return "Would block visitor paths"
	return ""


func _has_access(cells: Array, reach: Dictionary) -> bool:
	for c in cells:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if reach.has(c + d):
				return true
	return false


func _flood(solid: Dictionary) -> Dictionary:
	var seen := {}
	var q: Array[Vector2i] = [entrance()]
	seen[entrance()] = true
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if in_bounds(n) and not solid.has(n) and not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen


func place(type: String, cell: Vector2i, rot: int, data: Dictionary = {}) -> PlacedObject:
	var entry := {"type": type, "cell": [cell.x, cell.y], "rot": rot, "data": data}
	GameState.placed.append(entry)
	var o := _spawn(entry)
	rebuild_astar()
	Events.museum_changed.emit()
	return o


func remove(o: PlacedObject) -> void:
	o.release_contents()
	GameState.placed.erase(o.entry)
	for c in o.cells:
		grid.erase(c)
	o.queue_free()
	rebuild_astar()
	Events.museum_changed.emit()


func object_at(c: Vector2i) -> PlacedObject:
	return grid.get(c)


func expand() -> void:
	## Grow the floor plan; shift existing objects so the entrance stays centred.
	var old_w := W
	GameState.museum_level += 1
	var sz := GameState.museum_size()
	var dx := (sz.x - old_w) / 2
	for e in GameState.placed:
		e["cell"] = [int(e["cell"][0]) + dx, int(e["cell"][1])]
	for m in mess:
		if is_instance_valid(m["node"]):
			m["node"].queue_free()
	mess.clear()
	build_structure()
	load_objects()
	Events.museum_changed.emit()

# ------------------------------------------------------------- navigation ---
func rebuild_astar() -> void:
	astar.region = Rect2i(0, 0, W, D)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	var solid := {}
	for c in grid.keys():
		var o: PlacedObject = grid[c]
		if not o.walkable():
			astar.set_point_solid(c, true)
			solid[c] = true
	reachable = _flood(solid)


func path_points(from_c: Vector2i, to_c: Vector2i) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if not in_bounds(from_c) or not in_bounds(to_c):
		return out
	if astar.is_point_solid(from_c):
		from_c = nearest_free(from_c)
	if astar.is_point_solid(to_c):
		return out
	var ids := astar.get_id_path(from_c, to_c)
	for c in ids:
		out.append(cell_center(c))
	return out


func nearest_free(c: Vector2i) -> Vector2i:
	var best := entrance()
	var bd := 1e9
	for r: Vector2i in reachable.keys():
		var d := Vector2(r - c).length()
		if d < bd:
			bd = d
			best = r
	return best


func stand_cell(o: PlacedObject, from_c: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := 1e9
	for c in o.cells:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if o.cells.has(n) or not reachable.has(n):
				continue
			var occupant: PlacedObject = grid.get(n)
			if occupant != null and not occupant.walkable():
				continue
			var dist := Vector2(n - from_c).length() + randf() * 1.5
			if dist < bd:
				bd = dist
				best = n
	return best


func random_free_cell() -> Vector2i:
	var keys := reachable.keys()
	if keys.is_empty():
		return entrance()
	return keys[randi() % keys.size()]

# ------------------------------------------------------------------- mess ---
func add_mess(kind: String, pos: Vector3) -> void:
	if mess.size() > 40:
		return
	var m := Art.model("trash" if kind == "trash" else "sand_pile")
	m.position = Vector3(pos.x + randf_range(-0.4, 0.4), 0.03, pos.z + randf_range(-0.4, 0.4))
	m.rotation.y = randf() * TAU
	mess_root.add_child(m)
	var item := {"kind": kind, "node": m}
	var cb := func() -> void: _player_take_mess(item)
	var it := Interactable.attach(m, "Pick up trash" if kind == "trash" else "Sweep up sand", cb, 0.9, 1.5)
	it.prio = 1
	if kind == "trash":
		it.text_fn = func() -> String: return "Pick up trash" if GameState.free_hotbar_slot() >= 0 else "Pick up trash (hotbar full)"
	mess.append(item)
	_pillar_t = 0.0


func _player_take_mess(item: Dictionary) -> void:
	if item["kind"] == "trash":
		if not GameState.hotbar_add({"t": "trash"}):
			Events.say("Your hands are full - free a hotbar slot to carry the trash.", UIKit.CORAL)
			Audio.sfx("error")
			return
		Events.say("Picked up trash. Throw it in a trash bin.", Color.WHITE)
	clean_mess(item)


func has_checker() -> bool:
	return not objects_of("plaque_checker").is_empty()


## Display cases with a blank or wrong plaque.
func wrong_plaques() -> Array:
	var out: Array = []
	for o in objects_of("display_case"):
		var st: String = o.plaque_status()
		if st == "wrong" or st == "blank":
			out.append(o)
	return out


func clean_mess(item: Dictionary) -> void:
	if not mess.has(item):
		return
	mess.erase(item)
	var n: Node3D = item["node"]
	if is_instance_valid(n):
		var tw := n.create_tween()
		tw.tween_property(n, "scale", Vector3.ONE * 0.02, 0.2)
		tw.tween_callback(n.queue_free)
	Audio.sfx("brush")
	_pillar_t = 0.0


func nearest_mess(p: Vector3, taken: Dictionary = {}) -> Dictionary:
	var best := {}
	var bd := 1e9
	for m in mess:
		if taken.has(m["node"]):
			continue
		if not is_instance_valid(m["node"]):
			continue
		var d: float = (m["node"] as Node3D).global_position.distance_to(p)
		if d < bd:
			bd = d
			best = m
	return best


func mess_near(p: Vector3, r: float) -> int:
	var n := 0
	for m in mess:
		if is_instance_valid(m["node"]) and (m["node"] as Node3D).global_position.distance_to(p) < r:
			n += 1
	return n

# ---------------------------------------------------------------- pillars ---
func _process(delta: float) -> void:
	_pillar_t -= delta
	if _pillar_t <= 0.0:
		_pillar_t = 0.5
		compute_pillars()


func compute_pillars() -> void:
	var fun := 0.0
	var decor := 0.0
	var accurate := 0
	var penalty := 0.0
	var species := {}
	for o in all_objects():
		fun += o.fun_points()
		decor += o.decor_points()
		if o.accurate_plaque():
			accurate += 1
		var sp: String = o.species_shown()
		if sp != "":
			species[sp] = true
		if o.type == "trash_bin" and o.fill >= PlacedObject.BIN_CAP:
			penalty += 8
		if o.type == "restroom" and o.dirt >= PlacedObject.RESTROOM_DIRTY:
			penalty += 12
		if o.sabotaged:
			penalty += 5
	fun += species.size() * 2.0
	for m in mess:
		penalty += 6.0 if m["kind"] == "trash" else 4.0
	var h := GameState.half_stars
	var p := GameState.pillars
	p["fun_points"] = fun
	p["decor_points"] = decor
	p["accurate"] = accurate
	p["fun"] = clampf(100.0 * fun / (30.0 + 25.0 * h), 0.0, 100.0)
	p["decor"] = clampf(100.0 * decor / (12.0 + 9.0 * h), 0.0, 100.0)
	p["clean"] = clampf(100.0 - penalty, 0.0, 100.0)


func has_complete_skeleton_near(p: Vector3, r: float) -> bool:
	for o in objects_of("mega_podium"):
		if o.skeleton_complete() and o.global_position.distance_to(p) < r:
			return true
	return false


func apex_complete() -> bool:
	for o in objects_of("mega_podium"):
		if o.data.get("species", "") == "apex" and o.skeleton_complete():
			return true
	return false
