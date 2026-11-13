class_name Beach
extends Node3D
## The coastline: four strata zones (Cenozoic shore, Jurassic cliffs,
## Cretaceous sea caves, Paleozoic shelf) with permit barriers, backdrop
## cliffs, props and daily-respawning dig nodes.

const GROUND := {"shore": Color("f2d49b"), "cliffs": Color("efc78e"), "caves": Color("cdb68f"), "reef": Color("d3cab8")}
const BARRIER_X := {"cliffs": 25.0, "caves": 65.0, "reef": -25.0}

var nodes_root: Node3D
var barriers := {}
var _zone_nodes := {}
var _cur_zone := ""
var _zone_t := 0.0


## Zone grounds, cliffs, palms, rocks, driftwood, cave arches, set dressing and the
## world bounds are all placed in the editor under Beach/ in world.tscn. This node
## only owns what changes at runtime: permit barriers and the daily dig nodes.
func _ready() -> void:
	nodes_root = Node3D.new()
	add_child(nodes_root)
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
	var zz := -13.0
	while zz < 51.0:
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
	Art.box_collider(root, Vector3(0.6, 4, 66), Vector3(x, 2, 19))
	return root

func _process(delta: float) -> void:
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


func _spawn_zone(zid: String) -> void:
	var zd: Dictionary = {}
	for z in DB.ZONES:
		if z["id"] == zid:
			zd = z
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s-%d-%d" % [zid, GameState.day, GameState.slot]) + randi()
	var taken: Array[Vector3] = []
	var counts: Dictionary = DB.ZONE_NODES[zid]
	for kind in counts.keys():
		for i in range(int(counts[kind])):
			var p := Vector3.ZERO
			var ok := false
			for attempt in range(30):
				p = Vector3(rng.randf_range(float(zd["x0"]) + 3.0, float(zd["x1"]) - 3.0), 0, rng.randf_range(-5.0, 40.0))
				ok = true
				for q in taken:
					if q.distance_to(p) < 3.6:
						ok = false
						break
				if ok:
					break
			if not ok:
				continue
			taken.append(p)
			var n := DigNode.new()
			nodes_root.add_child(n)
			n.position = p
			n.setup(kind, zid, kind == "buried", rng)


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
