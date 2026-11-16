class_name Beach
extends Node3D
## The coastline: four strata zones (Cenozoic shore, Jurassic cliffs,
## Cretaceous sea caves, Paleozoic shelf) with permit barriers, backdrop
## cliffs, props and daily-respawning dig nodes.

const GROUND := {"shore": Color("f2d49b"), "cliffs": Color("efc78e"), "caves": Color("cdb68f"), "reef": Color("d3cab8")}
const BARRIER_X := {"cliffs": 25.0, "caves": 65.0, "reef": -25.0}

## Seconds between respawn checks: depleted / weathered spots grow back quickly.
const RESPAWN_EVERY := 5.0

var nodes_root: Node3D
var barriers := {}
var _zone_nodes := {}
var _cur_zone := ""
var _zone_t := 0.0
var _respawn_t := RESPAWN_EVERY
var _rng := RandomNumberGenerator.new()


## Zone grounds, cliffs, palms, rocks, driftwood, cave arches, set dressing and the
## world bounds are all placed in the editor under Beach/ in world.tscn. This node
## only owns what changes at runtime: permit barriers and the daily dig nodes.
func _ready() -> void:
	nodes_root = Node3D.new()
	add_child(nodes_root)
	_rng.randomize()
	refresh_barriers(false)
	spawn_nodes()


## Blender-made zone ground (sand tone per era, wet band at the waterline,
## ripples, shells/pebbles). Scaled on X to the zone's exact width.
# --------------------------------------------------------------- barriers ---
func refresh_barriers(announce: bool = true) -> void:
	for zid in BARRIER_X.keys():
		var unlocked := GameState.zone_unlocked(zid)
		if unlocked and barriers.has(zid):
			var b: Node3D = barriers[zid]
			barriers.erase(zid)
			var tw := b.create_tween()
			tw.tween_property(b, "position:y", -4.0, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(b.queue_free)
			if announce:
				var zn := ""
				for z in DB.ZONES:
					if z["id"] == zid:
						zn = z["name"]
				Events.say("The %s are now open for digging!" % zn, UIKit.GOLD)
				Audio.sfx("fanfare")
				_spawn_zone(zid)
		elif not unlocked and not barriers.has(zid):
			barriers[zid] = _make_barrier(zid)


func _make_barrier(zid: String) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	var x: float = BARRIER_X[zid]
	var zname := ""
	var skill := ""
	for z in DB.ZONES:
		if z["id"] == zid:
			zname = z["name"]
			skill = z["skill"]
	# a solid plank hoarding from the backdrop cliffs right down into the surf, so
	# there is no gap to look (or walk) through anywhere along the zone border
	var zz := -21.0
	while zz < 62.0:
		var f := Art.model("fence_barrier")
		f.position = Vector3(x, 0, zz + 2.0)
		f.rotation.y = PI * 0.5
		root.add_child(f)
		zz += 4.0
	# the fence boards carry "PERMIT REQUIRED"; looking at one tells you which permit
	var info := "Permit required: %s  (Upgrade Tree: %s)" % [zname, DB.SKILLS[skill]["name"]]
	for f in root.get_children():
		var it := Interactable.attach(f, info, func() -> void: Events.say(info, UIKit.GOLD))
		it.prio = 0
	Art.box_collider(root, Vector3(0.6, 4, 84), Vector3(x, 2, 20.5))
	return root

func _process(delta: float) -> void:
	_respawn_t -= delta
	if _respawn_t <= 0.0:
		_respawn_t = RESPAWN_EVERY
		_respawn_tick()
	_zone_t -= delta
	if _zone_t > 0.0 or World.instance == null or World.instance.player == null:
		return
	_zone_t = 0.5
	var p := World.instance.player.global_position
	var zid := ""
	if p.z > -10.0:
		zid = String(zone_at(p.x)["id"])
	if zid != _cur_zone:
		_cur_zone = zid
		if zid != "":
			var z := zone_at(p.x)
			Events.say("%s  -  %s strata" % [z["name"], z["era"]], Color("fff6e6"))

# ------------------------------------------------------------------ nodes ---
func spawn_nodes() -> void:
	for c in nodes_root.get_children():
		c.queue_free()
	_zone_nodes.clear()
	for z in DB.ZONES:
		if GameState.zone_unlocked(z["id"]):
			_spawn_zone(z["id"])


## Every live dig spot, for the save file.
func save_nodes() -> Array:
	var out: Array = []
	for c in nodes_root.get_children():
		var n := c as DigNode
		if n == null or n.depleted or n._fading or n.is_queued_for_deletion():
			continue
		out.append({"kind": n.kind, "zone": n.zone, "hidden": n.hidden, "size": n.size_k, "life": n.life,
			"pos": [n.position.x, n.position.z], "rot": n.visual.rotation.y})
	return out


## Put back exactly the spots that were there when the game was saved.
func restore_nodes(list: Array) -> void:
	for c in nodes_root.get_children():
		c.free()
	_zone_nodes.clear()
	for e in list:
		if not DB.NODE_TYPES.has(String(e.get("kind", ""))):
			continue
		var n := DigNode.new()
		nodes_root.add_child(n)
		n.position = Vector3(float(e["pos"][0]), 0, float(e["pos"][1]))
		n.setup(String(e["kind"]), String(e["zone"]), bool(e.get("hidden", false)), _rng, float(e.get("size", 1.0)))
		n.life = float(e.get("life", 200.0))
		n.visual.rotation.y = float(e.get("rot", 0.0))


func _spawn_zone(zid: String) -> void:
	var counts: Dictionary = DB.ZONE_NODES[zid]
	for kind in counts.keys():
		var big: bool = DB.NODE_TYPES[kind].get("big", false)
		for i in range(int(counts[kind])):
			if big and _rng.randf() > _big_chance():
				continue
			_spawn_one(zid, kind)


func _big_chance() -> float:
	var k := 2.0 if GameState.has_skill("lucky_3") else 1.0
	if int(GameState.flags.get("storm_day", -1)) == GameState.day:
		k *= 2.5  # the storm (J-Mail warning) washed fresh rock out of the cliffs
	return clampf(DB.BIG_SPAWN_CHANCE * k, 0.0, 1.0)


func _zone_def(zid: String) -> Dictionary:
	for z in DB.ZONES:
		if z["id"] == zid:
			return z
	return {}


## Spot a new dig node in a free place of the zone (away from other spots and the player).
func _spawn_one(zid: String, kind: String) -> DigNode:
	var zd := _zone_def(zid)
	var big: bool = DB.NODE_TYPES[kind].get("big", false)
	var gap := 3.6 if not big else 6.0
	var player_p := World.instance.player.global_position if World.instance and World.instance.player else Vector3(0, 0, -100)
	var p := Vector3.ZERO
	var ok := false
	for attempt in range(30):
		p = Vector3(_rng.randf_range(float(zd["x0"]) + 3.0, float(zd["x1"]) - 3.0), 0, _rng.randf_range(-5.0, 40.0))
		ok = p.distance_to(Vector3(player_p.x, 0, player_p.z)) > 4.0
		if ok:
			for c in nodes_root.get_children():
				if c is DigNode and not c.is_queued_for_deletion() and (c as Node3D).position.distance_to(p) < gap:
					ok = false
					break
		if ok:
			break
	if not ok:
		return null
	var n := DigNode.new()
	nodes_root.add_child(n)
	n.position = p
	n.setup(kind, zid, kind == "buried", _rng)
	return n


## Keep every unlocked zone stocked: one missing spot per zone grows back every
## few seconds (big rare spots only now and then).
func _respawn_tick() -> void:
	if World.instance == null:
		return
	for z in DB.ZONES:
		var zid: String = z["id"]
		if not GameState.zone_unlocked(zid) or barriers.has(zid):
			continue
		var have := {}
		for c in nodes_root.get_children():
			if c is DigNode and not c.is_queued_for_deletion() and not c.depleted and c.zone == zid:
				have[c.kind] = int(have.get(c.kind, 0)) + 1
		var counts: Dictionary = DB.ZONE_NODES[zid]
		var missing: Array = []
		for kind in counts.keys():
			if int(have.get(kind, 0)) < int(counts[kind]):
				missing.append(kind)
		if missing.is_empty():
			continue
		var kind: String = missing[_rng.randi() % missing.size()]
		if DB.NODE_TYPES[kind].get("big", false):
			if _rng.randf() > _big_chance() * 0.35:
				continue
			var n := _spawn_one(zid, kind)
			if n and zid == _cur_zone:
				Events.radio("A rare %s has appeared in the %s!" % [DB.NODE_TYPES[kind]["name"], z["name"]], "info", n.global_position)
		else:
			_spawn_one(zid, kind)


func hidden_nodes() -> Array[DigNode]:
	var out: Array[DigNode] = []
	for c in nodes_root.get_children():
		if c is DigNode and c.hidden and not c.depleted:
			out.append(c)
	return out


func zone_at(x: float) -> Dictionary:
	for z in DB.ZONES:
		if x >= float(z["x0"]) and x < float(z["x1"]):
			return z
	return DB.ZONES[0]
