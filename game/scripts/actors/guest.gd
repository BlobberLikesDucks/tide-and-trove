class_name Guest
extends Node3D
## Museum visitor. Archetypes: tourist, kid, nerd (enthusiast), celebrity,
## critic, shoplifter, spy, teacher, student, fan. Arrives by car (or school
## bus), walks the museum grid, views exhibits, buys snacks, THROWS litter,
## reacts to incidents, writes a review, then waits at the bus stop and rides
## the bus away. School classes follow the player on a guided tour.

enum S { ARRIVE, DECIDE, WALK, VIEW, BUY, RESTROOM, TANTRUM, CLIMB, STEAL, SABOTAGE, LEAVE, KNOCKED, WAIT_BUS, BOARD, FOLLOW }

var kind := "tourist"
var gname := ""
var visual: CharVisual
var museum: Museum
var cycle: DayCycle
var state: int = S.ARRIVE
var path: Array[Vector3] = []
var target: PlacedObject
var timer := 0.0
var mood := 60.0
var notes := {}
var pen := {}
var visits_left := 3
var speed := 2.3
var bladder := 0.0
var hunger := 0.0
var offset := Vector3.ZERO
var inside := false
var assaulted := false
var kicked_out := false
var resolved := false
var personality := ""
var leader: Guest
var stolen := {}
var thief_active := false
var will_tantrum := false
var will_climb := false
var tantrum_done := false
var weight := 1.0
var greeted := false
var hit_count := 0
var no_review := false
var visited := {}
var inter: Interactable
var trash_timer := -1.0
## Set when a fossil enthusiast spots a wrong plaque: {"fossil": name, "wrong": "Era: Mesozoic"}.
var harsh := {}
var queued_at: PlacedObject
## Something to throw away later (wrapper, can, ticket stub...) - from day one.
var has_litter := false
## School trips: the class follows this node (the teacher, or the player on a tour).
var follow_node: Node3D
var trip: Dictionary = {}
var _follow_t := 0.0
var _bus_spot := Vector3.ZERO
var _arrive_cb := ""
var _perceive_t := 0.0
var _rd := {}
var _knock_t := 0.0
var _sfx_t := 0.0
var _radioed := false
var _climb_obj: PlacedObject
## Seed for the random look / name, so a saved guest comes back looking the same.
var look_seed := 0


func setup(p_kind: String, m: Museum, c: DayCycle, spawn: Vector3) -> void:
	kind = p_kind
	museum = m
	cycle = c
	global_position = spawn
	var rng := RandomNumberGenerator.new()
	if look_seed == 0:
		look_seed = randi() % 2000000000 + 1
	rng.seed = look_seed
	var look := CharVisual.random_look(rng)
	gname = DB.FIRST_NAMES[rng.randi() % DB.FIRST_NAMES.size()]
	match kind:
		"kid":
			look["scale"] = 0.62
			look["acc"] = ["Hat_Cap"] if rng.randf() < 0.6 else []
			look["cap_back"] = true
			speed = 2.7
			visits_left = 4
			will_tantrum = rng.randf() < 0.12
			will_climb = rng.randf() < 0.12
		"nerd":
			look["acc"] = ["Glasses", "Hat_Safari"] if rng.randf() < 0.4 else ["Glasses"]
			look["Shirt"] = Color("6fae6a")
			visits_left = 5
		"celebrity":
			gname = DB.CELEB_NAMES[rng.randi() % DB.CELEB_NAMES.size()]
			look["acc"] = ["Sunglasses", "Hat_Top"] if rng.randf() < 0.5 else ["Sunglasses", "Hair_Long"]
			look["Shirt"] = [Color("ff4fa3"), Color("ffd23f"), Color("b47aff")][rng.randi() % 3]
			look["Hat"] = Color("1a1a1a")
			look["glow"] = 0.35
			personality = "crowd" if rng.randf() < 0.55 else "diva"
			visits_left = 4
			weight = 1.5
		"critic":
			gname = DB.CRITIC_NAMES[rng.randi() % DB.CRITIC_NAMES.size()]
			look["acc"] = ["Hat_Fedora", "Clipboard", "Tie"]
			look["Shirt"] = Color("2a2a30")
			look["Pants"] = Color("2a2a30")
			look["Hat"] = Color("3a3a42")
			visits_left = 6
			weight = 3.0
			speed = 1.9
		"shoplifter":
			look["acc"] = ["Hat_Cap", "Sunglasses"] if rng.randf() < 0.5 else ["Hat_Cap"]
			look["Shirt"] = Color("5a5f6a")
			look["Hat"] = Color("2a2a30")
			visits_left = 2
		"spy":
			gname = "Suspicious Person"
			look["acc"] = ["Hat_Fedora", "Sunglasses", "Coat"]
			look["Coat"] = Color("c8b27a")
			look["Shirt"] = Color("3a3a42")
			look["Pants"] = Color("3a3a42")
			look["Hat"] = Color("4a3a2a")
			no_review = true
			speed = 2.6
		"teacher":
			look["acc"] = ["Glasses", "Hair_Bun"]
			look["Shirt"] = Color("8a5cc2")
			visits_left = 4
		"student":
			look["scale"] = 0.62
			look["acc"] = ["Hat_Cap"] if rng.randf() < 0.3 else []
			look["cap_back"] = true
			look["Shirt"] = [Color("f4b82a"), Color("e05a4a"), Color("3f7fd9")][rng.randi() % 3]
			speed = 2.6
			visits_left = 3
			will_tantrum = rng.randf() < 0.22
	visual = CharVisual.new()
	add_child(visual)
	visual.setup(look)
	offset = Vector3(rng.randf_range(-0.55, 0.55), 0, rng.randf_range(-0.55, 0.55))
	bladder = rng.randf_range(0, 50)
	hunger = rng.randf_range(0, 60)
	inter = Interactable.attach(self, gname, _on_player_interact, 0.9, 2.0)
	inter.text_fn = _prompt
	var to_door: Array[Vector3] = [Vector3(spawn.x * 0.3, 0, -27.0), museum.door_outside(), museum.cell_center(museum.entrance())]
	path = to_door
	state = S.ARRIVE
	has_litter = kind != "spy" and rng.randf() < (0.45 if kind in ["kid", "student"] else 0.3)
	if has_litter:
		trash_timer = rng.randf_range(12.0, 50.0)

# ------------------------------------------------------------- save/load ---
const SAVE_VARS := ["gname", "mood", "notes", "pen", "visits_left", "bladder", "hunger", "inside", "assaulted", "kicked_out",
	"resolved", "personality", "stolen", "thief_active", "will_tantrum", "will_climb", "tantrum_done", "weight", "greeted",
	"hit_count", "no_review", "trash_timer", "harsh", "has_litter", "speed"]


## Everything needed to put this visitor back exactly where they were and
## exactly mid-way through whatever they were doing.
func save_data() -> Dictionary:
	var d := {"kind": kind, "seed": look_seed, "state": state, "pos": [global_position.x, global_position.y, global_position.z],
		"yaw": visual.rotation.y, "timer": timer, "arrive_cb": _arrive_cb, "anim": visual.anim, "visible": visual.visible,
		"perceive_t": _perceive_t, "follow_t": _follow_t, "knock_t": _knock_t, "sfx_t": _sfx_t}
	for k in SAVE_VARS:
		d[k] = get(k)
	var vis: Array = []
	for o in museum.all_objects():
		if visited.has(o.get_instance_id()):
			vis.append([o.cell.x, o.cell.y])
	d["visited"] = vis
	d["bus_spot"] = [_bus_spot.x, _bus_spot.z]
	var pts: Array = []
	for q in path:
		pts.append([q.x, q.z])
	d["path"] = pts
	d["target"] = [target.cell.x, target.cell.y] if target and is_instance_valid(target) else []
	d["climb_obj"] = [_climb_obj.cell.x, _climb_obj.cell.y] if _climb_obj and is_instance_valid(_climb_obj) else []
	if queued_at and is_instance_valid(queued_at):
		d["queued_at"] = [queued_at.cell.x, queued_at.cell.y]
		d["queue_i"] = queued_at.queue.find(self)
	if visual.bubble:
		d["bubble"] = [visual.bubble.text, visual.bubble.modulate.to_html(), visual.bubble.visible]
	if state == S.KNOCKED:
		d["ragdoll"] = Ragdoll.save_state(_rd)
	return d


func _obj_at(c: Variant) -> PlacedObject:
	if not (c is Array) or (c as Array).size() < 2:
		return null
	var cell := Vector2i(int(c[0]), int(c[1]))
	for o in museum.all_objects():
		if o.cell == cell:
			return o
	return null


func load_data(d: Dictionary) -> void:
	for k in SAVE_VARS:
		if d.has(k):
			var v = d[k]
			if typeof(get(k)) == TYPE_INT:
				v = int(v)
			set(k, v)
	var pp: Array = d.get("pos", [0, 0, 0])
	if pp.size() == 3:
		global_position = Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
	visual.rotation.y = float(d.get("yaw", 0.0))
	inter.text = gname
	visited.clear()
	for c in d.get("visited", []):
		var vo := _obj_at(c)
		if vo:
			visited[vo.get_instance_id()] = true
	var bs: Array = d.get("bus_spot", [0, 0])
	_bus_spot = Vector3(float(bs[0]), 0, float(bs[1]))
	timer = float(d.get("timer", 0.0))
	_arrive_cb = String(d.get("arrive_cb", ""))
	_perceive_t = float(d.get("perceive_t", 0.0))
	_follow_t = float(d.get("follow_t", 0.0))
	_sfx_t = float(d.get("sfx_t", 0.0))
	target = _obj_at(d.get("target", []))
	path.clear()
	for q in d.get("path", []):
		path.append(Vector3(float(q[0]), 0, float(q[1])))
	var st := int(d.get("state", S.ARRIVE))
	state = st
	match st:
		S.BUY:
			queued_at = _obj_at(d.get("queued_at", []))
			if queued_at == null:
				state = S.DECIDE
			# (the queue itself is rebuilt in saved order by DayCycle.restore)
		S.CLIMB:
			_climb_obj = _obj_at(d.get("climb_obj", []))
			if _climb_obj:
				_climb_obj.climber = self
			else:
				global_position.y = 0.0
				state = S.DECIDE
		S.RESTROOM:
			visual.visible = false
		S.WAIT_BUS, S.BOARD:
			if cycle.world.traffic:
				cycle.world.traffic.take_spot(self, _bus_spot)
			if st == S.BOARD:
				state = S.WAIT_BUS  # Traffic re-sends them to the bus door from where they stand
			if cycle.world.traffic and cycle.world.traffic.is_seat(_bus_spot) and global_position.distance_to(_bus_spot) < 0.3:
				visual.rotation.y = 0.0
			if cycle.world.traffic:
				cycle.world.traffic.waiting(self)
		S.KNOCKED:
			_knock_t = float(d.get("knock_t", 0.0))
			_rd = Ragdoll.knock(self, visual, Vector3.ZERO)
			Ragdoll.load_state(_rd, d.get("ragdoll", {}))
			inter.enabled = false
		S.WALK:
			if target == null:
				state = S.DECIDE
	visual.visible = bool(d.get("visible", true))
	if state != S.KNOCKED:
		var an := String(d.get("anim", "idle"))
		visual.anim = an
	var bb: Array = d.get("bubble", [])
	if bb.size() == 3 and bool(bb[2]) and String(bb[0]) != "":
		visual.set_bubble(String(bb[0]), Color.html(String(bb[1])))
	else:
		visual.set_bubble("")

# ------------------------------------------------------------------- tick ---
func _process(delta: float) -> void:
	if state == S.KNOCKED:
		_knock_t -= delta
		if _knock_t <= 0.0 and (Ragdoll.settled(_rd) or _knock_t < -2.5):
			_get_up()
		return
	if state == S.WAIT_BUS:
		if not visual.anim == "sit":
			_face(_bus_spot + Vector3(0, 0, -3))
		return
	if state == S.BOARD:
		if _move(delta):
			_board()
		return
	if state == S.FOLLOW:
		_update_follow(delta)
		if inside:
			_perceive_t -= delta
			if _perceive_t <= 0.0:
				_perceive_t = 1.0
				_perceive()
		return
	if inside and state != S.LEAVE:
		_perceive_t -= delta
		if _perceive_t <= 0.0:
			_perceive_t = 1.0
			_perceive()
		if trash_timer > 0.0 and state != S.TANTRUM and state != S.CLIMB:
			trash_timer -= delta
			if trash_timer <= 0.0:
				_drop_trash()
	match state:
		S.ARRIVE:
			if _move(delta):
				_enter()
		S.WALK:
			if _move(delta):
				_arrived()
		S.DECIDE:
			_decide()
		S.BUY:
			timer -= delta
			if target and is_instance_valid(target):
				_face(target.global_position)
			if cycle.closing:
				_quit_queue(false)
			elif timer <= 10.0 and timer + delta > 10.0:
				visual.set_bubble("...", UIKit.CORAL)
			elif timer <= 0.0:
				_quit_queue(true)
		S.VIEW, S.RESTROOM, S.STEAL, S.SABOTAGE:
			timer -= delta
			if target and is_instance_valid(target):
				_face(target.global_position)
			if timer <= 0.0:
				_finish_activity()
		S.TANTRUM:
			timer -= delta
			_sfx_t -= delta
			if _sfx_t <= 0.0:
				_sfx_t = 2.2
				Audio.sfx("tantrum", randf_range(0.9, 1.2), -8.0)
			if timer <= 0.0:
				_end_tantrum(false)
		S.CLIMB:
			timer -= delta
			if timer <= 0.0:
				get_down()
		S.LEAVE:
			if _move(delta):
				if trip.is_empty() and cycle.world.traffic and not kicked_out:
					_arrive_at_stop()
				elif not trip.is_empty() and cycle.world.traffic:
					_arrive_at_stop()
				else:
					_despawn()


func _move(delta: float) -> bool:
	if path.is_empty():
		visual.anim = "idle"
		return true
	# something was built on our route (you can build while open): re-plan
	if inside and state == S.WALK and museum.astar.region.has_point(museum.world_to_cell(path[0])) and museum.astar.is_point_solid(museum.world_to_cell(path[0])):
		state = S.DECIDE
		path.clear()
		return false
	var tgt := path[0] + (offset if inside else Vector3.ZERO)
	var d := tgt - global_position
	d.y = 0
	if d.length() < 0.12:
		path.pop_front()
		return path.is_empty()
	var step := minf(speed * delta, d.length())
	global_position += d.normalized() * step
	global_position.y = 0.0
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-d.x, -d.z), minf(1.0, 10.0 * delta))
	visual.anim = "walk"
	visual.speed = speed / 4.0
	return false


func _face(p: Vector3) -> void:
	var d := p - global_position
	if Vector2(d.x, d.z).length() > 0.05:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-d.x, -d.z), 0.15)


func cur_cell() -> Vector2i:
	return museum.world_to_cell(global_position)

# ------------------------------------------------------------- lifecycle ---
func _enter() -> void:
	inside = true
	if kind != "spy":
		var price := GameState.ticket_price()
		if kind == "fan":
			price = maxi(1, price / 2)
		GameState.earn(price, "Tickets")
		GameState.stats["visitors"] = int(GameState.stats["visitors"]) + 1
		cycle.visitors_today += 1
	if randf() < 0.22:
		museum.add_mess("sand", global_position)
	var p := GameState.pillars
	mood = 58.0 + (float(p["fun"]) - 50.0) * 0.18 + (float(p["decor"]) - 40.0) * 0.1 + (float(p["clean"]) - 70.0) * 0.12
	if float(p["fun_points"]) < 10.0:
		_note("boring", -1.5)
		mood -= 8.0
	if float(p["clean"]) < 55.0:
		_note("dirty", -1.0)
	if float(p["clean"]) > 88.0:
		_note("clean", 0.6)
	if float(p["decor"]) > 65.0:
		_note("decor", 0.6)
	var value := 4.0 + float(p["fun_points"]) * 0.12
	if GameState.ticket_price() > value * 1.35:
		_note("pricey", -1.0)
		mood -= 7.0
	if kind == "celebrity":
		var msg := "%s is here with a crowd of fans!" % gname if personality == "crowd" else "%s demands VIP treatment - greet them!" % gname
		Events.radio(msg, "vip", global_position)
		if personality == "crowd":
			cycle.spawn_fans(self)
	elif kind == "critic":
		Events.radio("A Museum Critic just arrived (%s). Keep it spotless!" % gname, "vip", global_position)
	elif kind == "spy":
		Events.radio("A suspicious person slipped in without a ticket!", "threat", global_position)
	state = S.DECIDE


func _decide() -> void:
	if cycle.closing:
		_leave()
		return
	if kind == "fan" and is_instance_valid(leader) and leader.inside and leader.state != S.LEAVE and leader.target:
		if _go_to(leader.target):
			return
	if (kind == "student" or kind == "teacher") and is_instance_valid(follow_node):
		state = S.FOLLOW
		return
	if kind == "teacher" and not trip.is_empty():
		# waits just inside the door for the player to start the guided tour
		visual.anim = "idle"
		if randf() < 0.004:
			visual.play_once("wave")
		visual.set_bubble("?" if cycle.tour and not cycle.tour.done else "", UIKit.GOLD)
		return
	if bladder > 85.0:
		var rr := museum.objects_of("restroom")
		if rr.is_empty():
			_note("no_restroom", -2.0)
			mood -= 14.0
			bladder = 0.0
		elif _go_to(rr[randi() % rr.size()], S.RESTROOM):
			return
	if hunger > 75.0 and kind != "spy":
		var stands: Array = []
		for o in museum.all_objects():
			if o.def.get("cat", "") == "Concessions":
				stands.append(o)
		if not stands.is_empty() and _go_to(stands[randi() % stands.size()], S.BUY):
			return
		hunger = 30.0
	if kind == "kid" and not tantrum_done:
		if will_tantrum and randf() < 0.4:
			_start_tantrum()
			return
		if will_climb:
			for o in museum.objects_of("display_case_mega"):
				if o.mounted_count() > 0 and o.climber == null:
					will_climb = false
					if _go_to(o, S.CLIMB):
						return
	if kind == "shoplifter" and stolen.is_empty() and not thief_active:
		var gs := museum.objects_of("gift_shop")
		var cand: Array = gs if not gs.is_empty() else museum.cases()
		if not cand.is_empty() and _go_to(cand[randi() % cand.size()], S.STEAL):
			return
	if kind == "spy" and not resolved:
		var ex: Array = []
		for o in museum.all_objects():
			if (o.is_case() and not o.fossil_entry().is_empty()) or (o.is_mega() and o.mounted_count() > 0):
				if not o.sabotaged:
					ex.append(o)
		if not ex.is_empty() and _go_to(ex[randi() % ex.size()], S.SABOTAGE):
			return
		_leave()
		return
	if visits_left <= 0:
		_leave()
		return
	var pick := _pick_target()
	if pick == null or not _go_to(pick):
		visits_left -= 1
		if visits_left <= 0:
			_leave()


func _pick_target() -> PlacedObject:
	var total := 0.0
	var opts: Array = []
	for o in museum.all_objects():
		var w := 0.0
		if o.is_case():
			w = (3.0 + (1.0 if o.case_size() != "small" else 0.0)) if not o.fossil_entry().is_empty() else 0.0
			if kind == "nerd" or kind == "critic":
				w *= 2.0
		elif o.is_mega():
			w = 2.0 + o.mounted_count() if o.mounted_count() > 0 else 0.0
		match o.type:
			"touch_table":
				w = 6.0 if kind in ["kid", "student"] else 2.0
			"microscope_station":
				w = 6.0 if kind == "nerd" or kind == "critic" else 1.5
			"volcano_diorama":
				w = 6.0
			"dino_slide":
				w = 8.0 if kind in ["kid", "student"] else 0.3
			"time_tunnel":
				w = 5.0
			"photo_booth":
				w = 4.0 if kind == "tourist" or kind == "fan" else 2.0
			"water_fountain":
				w = 0.9
			"vending_machine":
				w = 1.6 if hunger > 40.0 else 0.4
			"bookshelf":
				w = 2.5 if kind == "nerd" else 0.5
			"fern_garden", "ammonite_fountain":
				w = 0.8
			"aquarium":
				w = 5.0
			"holo_theater":
				w = 7.0
			"dig_pit":
				w = 7.0 if kind == "kid" else 1.2
			"gift_shop":
				w = 3.0
			"dino_statue":
				w = 3.0 if kind == "kid" else 1.0
			"bench":
				w = 0.8
			"banner", "plant_pot", "floor_lamp":
				w = 0.35
		if visited.has(o.get_instance_id()):
			w *= 0.25
		if w > 0.0:
			opts.append([o, w])
			total += w
	if opts.is_empty():
		return null
	var r := randf() * total
	for e in opts:
		r -= e[1]
		if r <= 0.0:
			return e[0]
	return opts[0][0]


func _go_to(o: PlacedObject, after: int = S.VIEW) -> bool:
	if o == null or not is_instance_valid(o):
		return false
	var sc := museum.stand_cell(o, cur_cell())
	if sc.x < 0:
		visited[o.get_instance_id()] = true
		return false
	var p := museum.path_points(cur_cell(), sc)
	if p.is_empty() and cur_cell() != sc:
		visited[o.get_instance_id()] = true
		return false
	target = o
	path = p
	_arrive_cb = str(after)
	state = S.WALK
	return true


func _arrived() -> void:
	var after := int(_arrive_cb)
	if target == null or not is_instance_valid(target):
		state = S.DECIDE
		return
	visited[target.get_instance_id()] = true
	match after:
		S.VIEW:
			state = S.VIEW
			timer = randf_range(4.0, 7.0)
			match target.type:
				"holo_theater":
					timer = 11.0
				"aquarium":
					timer = 6.5
				"dig_pit":
					timer = 9.0 if kind == "kid" else 4.0
			if target.type in ["volcano_diorama", "time_tunnel", "touch_table"]:
				timer = 7.0
			elif target.type == "dino_slide":
				timer = 8.0
			visual.anim = "inspect" if (target.is_case() or target.type in ["microscope_station", "touch_table", "bookshelf"]) else ("dig" if target.type == "dig_pit" and kind in ["kid", "student"] else ("sit" if target.type == "bench" else ("cheer" if target.type in ["dino_slide", "photo_booth"] else "idle")))
			if kind == "critic":
				visual.anim = "inspect"
		S.BUY:
			state = S.BUY
			var cfg := GameConfig.get_cfg()
			timer = cfg.queue_patience_impatient if kind in ["kid", "celebrity", "critic"] else cfg.queue_patience
			visual.anim = "idle"
			visual.set_bubble("?", UIKit.GOLD)
			queued_at = target
			target.join_queue(self)
		S.RESTROOM:
			state = S.RESTROOM
			timer = 3.0
			visual.visible = false
		S.CLIMB:
			_start_climb(target)
		S.STEAL:
			state = S.STEAL
			timer = randf_range(3.0, 5.0)
			visual.anim = "inspect"
		S.SABOTAGE:
			state = S.SABOTAGE
			timer = 5.0
			visual.anim = "inspect"
		_:
			state = S.DECIDE


func _finish_activity() -> void:
	var o := target
	var st := state
	state = S.DECIDE
	visual.anim = "idle"
	if o == null or not is_instance_valid(o):
		return
	match st:
		S.VIEW:
			visits_left -= 1
			_view_effects(o)
		S.BUY:
			pass  # handled by served() / _quit_queue()
		S.RESTROOM:
			visual.visible = true
			bladder = 0.0
			if o.dirt >= PlacedObject.RESTROOM_DIRTY:
				mood -= 9.0
				_note("restroom_dirty", -1.5)
			o.add_dirt()
		S.STEAL:
			_steal(o)
		S.SABOTAGE:
			o.sabotage()
			resolved = true
			Events.radio("A corporate spy sabotaged an exhibit! Catch them!", "threat", global_position)
			visual.set_bubble("!", UIKit.BAD)
			speed = 3.4
			_leave()


## The player handed over a filled cup / bag / bun.
func served(o: PlacedObject) -> void:
	queued_at = null
	state = S.DECIDE
	visual.anim = "idle"
	var price := int(o.def.get("price", 3))
	GameState.earn(price, "Concessions")
	Audio.sfx("coin", 1.0, -6.0)
	hunger = 0.0
	mood += 8.0 if timer > 20.0 else 4.0
	_note("served", 1.2 if timer > 20.0 else 0.4)
	visual.set_bubble("$", UIKit.GOOD)
	get_tree().create_timer(1.5).timeout.connect(_clear_bubble)
	if o.type == "lemonade_stand":
		_note("lemonade", 1.0)
		visits_left += 2
	else:
		_note("food", 0.8)
		trash_timer = randf_range(5.0, 14.0)


## Waited too long (or the museum is closing): leave the queue.
func _quit_queue(angry: bool) -> void:
	if is_instance_valid(queued_at):
		queued_at.leave_queue(self)
	var stand_name: String = queued_at.def["name"] if is_instance_valid(queued_at) else "snack stand"
	queued_at = null
	hunger = 20.0
	state = S.DECIDE
	visual.set_bubble("")
	if angry:
		mood -= 18.0
		_note("slow_service", -4.0)
		notes["_stand"] = stand_name
		visual.set_bubble("!", UIKit.BAD)
		get_tree().create_timer(2.0).timeout.connect(_clear_bubble)
		Events.radio("A guest gave up waiting at the %s!" % stand_name, "mess", global_position)
		Audio.sfx("error", 0.8, -10.0)


func _view_effects(o: PlacedObject) -> void:
	var k := 0.6 + float(GameState.pillars["decor"]) / 250.0
	if GameState.has_skill("audio_guide"):
		k += 0.2
	mood += o.view_value() * k
	var shown_sp: String = o.species_shown()
	if shown_sp != "":
		GameState.mark_seen(shown_sp)  # first time a visitor sees a new species: Upgrade Points tonight
	if o.is_mega():
		_note("apex" if o.data.get("species", "") == "apex" and o.skeleton_complete() else "skeleton", 1.0 + o.mounted_count() * 0.3)
	match o.type:
		"touch_table":
			_note("touch", 1.4)
			if kind in ["kid", "student"]:
				mood += 6.0
		"microscope_station":
			_note("microscope", 1.2)
			if kind == "nerd":
				mood += 8.0
				if randf() < 0.5:
					GameState.earn(randi_range(3, 8), "Tips & donations")
		"volcano_diorama":
			_note("volcano", 1.8)
		"dino_slide":
			_note("slide", 1.8 if kind in ["kid", "student"] else 0.4)
			if state == S.DECIDE and kind in ["kid", "student"]:
				mood += 8.0
		"time_tunnel":
			_note("tunnel", 1.6)
		"photo_booth":
			_note("photo", 1.0)
			if randf() < 0.3:
				GameState.earn(6, "Publicity")
		"water_fountain":
			mood += 4.0
			bladder += 6.0
		"vending_machine":
			if hunger > 30.0:
				hunger = 0.0
				GameState.earn(3, "Vending machine")
				Audio.sfx("coin", 1.2, -10.0)
				has_litter = true
				trash_timer = randf_range(6.0, 20.0)
		"bookshelf":
			if kind == "nerd":
				mood += 5.0
				_note("intern", 0.4)
		"display_case", "display_case_medium", "display_case_big":
			_note("exhibits", 0.5 + o.fun_points() * 0.1)
			_plaque_reaction(o)
			if kind == "nerd":
				if o.accurate_plaque():
					var tip := randi_range(6, 14)
					GameState.earn(tip, "Tips & donations")
					mood += 12.0
					_note("plaque", 3.0)
					visual.set_bubble("$", UIKit.GOOD)
					get_tree().create_timer(1.5).timeout.connect(_clear_bubble)
				if cycle.has_staff("intern"):
					mood += 3.0
					_note("intern", 1.0)
		"aquarium":
			_note("aquarium", 1.5)
			if randf() < 0.3:
				GameState.earn(4, "Aquarium feeding")
		"holo_theater":
			_note("holo", 2.5)
		"dig_pit":
			if kind == "kid" or kind == "student":
				if GameState.pit_stock > 0:
					GameState.pit_stock -= 1
					GameState.earn(5, "Dig pit")
					mood += 8.0
				_note("digpit", 1.5)
		"gift_shop":
			if randf() < 0.5:
				_buy_souvenir()
		"bench":
			mood += 2.0


## Wrong or blank plaques: most visitors grumble; fossil enthusiasts go nuclear.
func _plaque_reaction(o: PlacedObject) -> void:
	var st := o.plaque_status()
	var fossil := GameState.fossil_name(o.fossil_entry()["f"]) if st != "" else ""
	if st == "blank":
		if kind == "nerd" or kind == "critic":
			mood -= 10.0
			_note("blank_plaque", -2.5)
		else:
			mood -= 2.0
			_note("blank_plaque", -0.6)
	elif st == "wrong":
		var wrong: Array = o.wrong_tags()
		if kind == "nerd":
			mood -= GameConfig.get_cfg().nerd_wrong_plaque_mood
			harsh = {"fossil": fossil, "wrong": ", ".join(wrong)}
			_note("harsh_plaque", -25.0)
			visual.set_bubble("!!!", UIKit.BAD)
			get_tree().create_timer(2.5).timeout.connect(_clear_bubble)
			Events.radio("A fossil enthusiast is FURIOUS about the plaque on the %s!" % fossil, "threat", global_position)
		elif kind == "critic":
			mood -= 25.0
			_note("wrong_plaque", -6.0)
		elif randf() < GameConfig.get_cfg().visitor_complain_chance:
			mood -= 7.0
			_note("wrong_plaque", -1.6)
			visual.set_bubble("?!", UIKit.CORAL)
			get_tree().create_timer(1.6).timeout.connect(_clear_bubble)


func _clear_bubble() -> void:
	if visual and not thief_active:
		visual.set_bubble("")


func _buy_souvenir() -> void:
	var mult := 1.25 if GameState.has_skill("souvenir") else 1.0
	var roll := randf()
	if roll < 0.35 and GameState.plushies > 0:
		GameState.plushies -= 1
		GameState.earn(int(8 * mult), "Gift shop")
	elif roll < 0.6 and GameState.take_storage_geode():
		GameState.earn(int(DB.GEODE_CRACK_PRICE * mult), "Gift shop")
		Audio.sfx("crack", 1.0, -6.0)
	else:
		var g := GameState.take_storage_gem()
		if g.is_empty():
			return
		GameState.earn(int(round(float(DB.GEMS[g["id"]]["value"]) * 1.5 * mult)), "Gift shop")
	Audio.sfx("register", 1.0, -8.0)
	_note("giftshop", 1.0)
	mood += 4.0


## Throw away whatever we are carrying: an arc into a nearby bin (good guest)
## or onto the floor (litter the player can pick up and throw in a bin).
func _drop_trash() -> void:
	has_litter = false
	var from := global_position + Vector3(0, 1.3 * visual.body_scale, 0)
	visual.play_once("wave")
	for b in museum.objects_of("trash_bin"):
		if b.global_position.distance_to(global_position) < 7.0 and b.fill < PlacedObject.BIN_CAP:
			_face(b.global_position)
			var bin: PlacedObject = b
			Throw.arc(get_parent(), from, b.global_position + Vector3(0, 1.0, 0), "trash", 0.6, func() -> void:
				if is_instance_valid(bin) and bin.add_fill():
					Audio.sfx("brush", 1.4, -10.0)
				elif is_instance_valid(museum):
					museum.add_mess("trash", bin.global_position + Vector3(0.8, 0, 0)))
			return
	var fwd := Vector3(-sin(visual.rotation.y), 0, -cos(visual.rotation.y))
	var land := global_position + fwd * randf_range(1.2, 2.4) + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
	if inside and not museum.contains(land, -0.3):
		land = global_position
	Throw.arc(get_parent(), from, land + Vector3(0, 0.03, 0), "trash", 0.55, func() -> void:
		if is_instance_valid(museum):
			museum.add_mess("trash", land))
	if randf() < 0.35:
		Events.radio("A visitor just threw trash on the floor!", "mess", land)


## Incident penalty capped per guest so one problem can't sink every review.
func _pen(k: String, mood_amt: float, note_amt: float, cap: float) -> void:
	_note(k, -note_amt)
	var cur: float = pen.get(k, 0.0)
	if cur >= cap:
		return
	var a := minf(mood_amt, cap - cur)
	pen[k] = cur + a
	mood -= a


func _note(k: String, v: float) -> void:
	notes[k] = float(notes.get(k, 0.0)) + v

# -------------------------------------------------------------- perceive ---
func _perceive() -> void:
	bladder += 1.4
	hunger += 1.0
	if state == S.TANTRUM or state == S.CLIMB or kind == "spy":
		return
	var p := global_position
	var n := museum.mess_near(p, 6.0)
	if n > 0:
		_pen("dirty", n * 0.6, 0.15 * n, 12.0)
		if kind == "critic" and hit_count < 4:
			hit_count += 1
			GameState.quality = maxf(0.0, GameState.quality - 2.0)
			Events.say("The critic scribbles a note about the mess... Quality -2%", UIKit.CORAL)
	for g in cycle.guests:
		if g == self or not is_instance_valid(g):
			continue
		var d: float = g.global_position.distance_to(p)
		if g.state == S.TANTRUM and d < 5.0:
			_pen("tantrum", 0.6, 0.12, 8.0)
		elif g.state == S.CLIMB and d < 10.0:
			_pen("climb", 0.5, 0.25, 6.0)
		elif g.kind == "celebrity" and g.inside and d < 7.0:
			if g.personality == "diva" and not g.resolved:
				_pen("vip", 1.2, 0.4, 7.0)
			else:
				if float(pen.get("celeb_bonus", 0.0)) < 8.0:
					pen["celeb_bonus"] = float(pen.get("celeb_bonus", 0.0)) + 0.6
					mood += 0.6
				_note("celebrity", 0.4)
	for s in cycle.staff_nodes:
		if not is_instance_valid(s) or not s.rogue:
			continue
		var d: float = s.global_position.distance_to(p)
		if s.type == "janitor" and d < 6.0:
			_note("lazy_staff", -0.3)
		elif s.type != "janitor" and d < 4.0:
			_pen("rude_staff", 2.0, 0.5, 10.0)
			if kind == "critic" and hit_count < 5:
				hit_count += 1
				GameState.quality = maxf(0.0, GameState.quality - 3.0)
	mood = clampf(mood, 0.0, 100.0)

# --------------------------------------------------------------- special ---
func _start_tantrum() -> void:
	tantrum_done = true
	state = S.TANTRUM
	timer = 25.0
	visual.anim = "tantrum"
	visual.set_bubble(">:(", UIKit.BAD)
	Events.radio("A kid is throwing a tantrum!", "kid", global_position)


func _end_tantrum(calmed: bool) -> void:
	visual.set_bubble("")
	visual.anim = "idle"
	if calmed:
		mood += 15.0
	else:
		mood -= 10.0
	if not museum.objects_of("dig_pit").is_empty() and not calmed:
		var pit = museum.objects_of("dig_pit")[0]
		if _go_to(pit):
			return
	state = S.DECIDE


func _start_climb(o: PlacedObject) -> void:
	state = S.CLIMB
	timer = 30.0
	_climb_obj = o
	o.climber = self
	global_position = o.global_position + Vector3(randf_range(-1.5, 1.5), 0.45, randf_range(-0.6, 0.6))
	visual.anim = "climb"
	visual.set_bubble("!", UIKit.CORAL)
	Events.radio("A kid is climbing the skeleton! 'Do Not Touch'!", "kid", global_position)


func get_down() -> void:
	if state != S.CLIMB:
		return
	if _climb_obj and is_instance_valid(_climb_obj):
		_climb_obj.climber = null
		var sc := museum.stand_cell(_climb_obj, museum.world_to_cell(_climb_obj.global_position))
		global_position = museum.cell_center(sc if sc.x >= 0 else museum.entrance())
	global_position.y = 0
	visual.set_bubble("")
	visual.anim = "idle"
	state = S.DECIDE


func _steal(o: PlacedObject) -> void:
	thief_active = true
	if o.type == "gift_shop":
		var g := GameState.take_storage_gem()
		if not g.is_empty():
			stolen = g
		elif GameState.plushies > 0:
			GameState.plushies -= 1
			stolen = {"t": "plush"}
		else:
			stolen = {"t": "nothing"}
	else:
		var f := o.fossil_entry()
		if not f.is_empty():
			f["pres"] = maxf(0.2, float(f["pres"]) - 0.1)
			stolen = {"t": "chip"}
		else:
			stolen = {"t": "nothing"}
	visual.set_bubble("!", UIKit.BAD)
	speed = 3.6
	Events.radio("Shoplifter! Someone is pocketing merchandise!", "threat", global_position)
	_leave()


func catch_thief() -> void:
	if not thief_active and kind != "spy":
		return
	if kind == "spy":
		Events.say("Spy escorted off the premises!", UIKit.GOOD)
		Audio.sfx("cheer", 1.0, -6.0)
		FX.burst(get_parent(), global_position + Vector3(0, 1.8, 0), "confetti", 0.6)
	else:
		if stolen.get("t", "") == "gem":
			GameState.storage.append(stolen)
		elif stolen.get("t", "") == "plush":
			GameState.plushies += 1
		Events.say("Shoplifter caught - merchandise recovered!", UIKit.GOOD)
		Audio.sfx("cheer", 1.0, -6.0)
		FX.burst(get_parent(), global_position + Vector3(0, 1.8, 0), "confetti", 0.6)
	thief_active = false
	stolen = {}
	kicked_out = true
	no_review = true
	resolved = true
	visual.set_bubble("")
	if state != S.KNOCKED:
		speed = 3.0
		_leave()

# ------------------------------------------------------------- player I/O ---
func _prompt() -> String:
	if kind == "teacher" and not trip.is_empty() and cycle.tour:
		if cycle.tour.done:
			return "%s - the tour is over" % gname
		return ("%s - tour: %d/%d stops" % [gname, cycle.tour.presented.size(), SchoolTour.STOPS_NEEDED]) if cycle.tour.active else "Start the guided tour for %s's class" % gname
	if kind == "student" and state == S.FOLLOW and not is_instance_valid(follow_node):
		return gname
	if state == S.TANTRUM:
		return "Calm %s down (%s)" % [gname, "give a plushie" if GameState.plushies > 0 else "escort out"]
	if state == S.CLIMB:
		return "Tell %s to get off the skeleton!" % gname
	if thief_active:
		return "Grab the shoplifter!"
	if kind == "spy":
		return "Escort the suspicious person out"
	if kind == "celebrity" and personality == "diva" and not resolved:
		return "Give %s the VIP welcome" % gname
	if kind == "critic" and not greeted:
		return "Greet the critic, %s" % gname
	if not greeted:
		return "Chat with %s (%s)" % [gname, DB.GUESTS[kind]["name"]]
	return "%s (%s) - mood %d%%" % [gname, DB.GUESTS[kind]["name"], int(mood)]


func _on_player_interact() -> void:
	if state == S.KNOCKED:
		return
	if kind == "teacher" and not trip.is_empty() and cycle.tour:
		cycle.tour.teacher_talk()
		return
	if state == S.TANTRUM:
		if GameState.plushies > 0:
			GameState.plushies -= 1
			Events.say("A dino plushie works wonders. Tantrum over!", UIKit.GOOD)
			_note("owner", 1.5)
			_end_tantrum(true)
		else:
			Events.say("You escort the kid and their parent out.", UIKit.GOLD)
			visual.set_bubble("")
			kicked_out = true
			mood = 35.0
			_leave()
		return
	if state == S.CLIMB:
		Events.say("'Down you get!' The skeleton is safe.", UIKit.GOOD)
		get_down()
		return
	if thief_active or kind == "spy":
		catch_thief()
		return
	if kind == "celebrity" and personality == "diva" and not resolved:
		resolved = true
		mood += 22.0
		_note("owner", 3.0)
		visual.anim = "wave"
		Events.say("%s loves the VIP treatment!" % gname, UIKit.GOOD)
		Audio.sfx("cheer", 1.1, -6.0)
		FX.burst(get_parent(), global_position + Vector3(0, 1.8, 0), "confetti", 0.8)
		return
	if not greeted:
		greeted = true
		mood += 12.0 if kind == "critic" else 6.0
		_note("owner", 2.0 if kind == "critic" else 1.0)
		visual.anim = "wave"
		Events.say("%s: \"%s\"" % [gname, ["What a charming place!", "Love the sea breeze here.", "Any new fossils today?", "My kids won't stop talking about dinosaurs."][randi() % 4]], Color.WHITE)
		return


func knockback(v: Vector3, by_player: bool) -> void:
	if state == S.KNOCKED or state == S.BOARD:
		return
	if state == S.CLIMB and _climb_obj and is_instance_valid(_climb_obj):
		_climb_obj.climber = null
	if state == S.RESTROOM:
		visual.visible = true
	if state == S.WAIT_BUS and is_instance_valid(cycle) and cycle.world.traffic:
		cycle.world.traffic.leave_stop(self)
	if by_player:
		_on_hit()
	elif not inside:
		mood -= 15.0
		_note("hit_by_car", -3.0)
	path.clear()
	state = S.KNOCKED
	_knock_t = 1.6
	visual.anim = "idle"
	_rd = Ragdoll.knock(self, visual, v)
	inter.enabled = false


func _on_hit() -> void:
	if thief_active or kind == "spy":
		catch_thief()
		return
	assaulted = true
	mood = 0.0
	_note("assault", -10.0)
	var place := "entrance"
	if target and is_instance_valid(target):
		place = String(target.def["name"]).to_lower()
	notes["_place"] = place
	Events.say("That guest will NOT forget this...", UIKit.BAD)
	for g in cycle.guests:
		if g == self or not is_instance_valid(g) or not g.inside:
			continue
		if g.global_position.distance_to(global_position) < 9.0:
			g.witness()


func witness() -> void:
	mood -= 18.0
	_note("witness", -2.0)
	if kind == "critic":
		GameState.quality = maxf(0.0, GameState.quality - 8.0)
		Events.say("The critic saw that! Quality -8%", UIKit.BAD)


func _get_up() -> void:
	Ragdoll.recover(self, visual, _rd)
	_rd = {}
	inter.enabled = true
	if museum.contains(global_position, -0.2):
		inside = true
		var c := cur_cell()
		if not museum.reachable.has(c):
			global_position = museum.cell_center(museum.nearest_free(c))
	if assaulted or kicked_out or not inside:
		speed = 3.0 if (assaulted or kicked_out) else speed
		_leave()
	else:
		state = S.DECIDE

# ------------------------------------------------------------------ leave ---
func _leave() -> void:
	if is_instance_valid(queued_at):
		queued_at.leave_queue(self)
		queued_at = null
	state = S.LEAVE
	visual.set_bubble("!" if thief_active or (kind == "spy" and not kicked_out) else "")
	if visual.anim == "tantrum":
		visual.anim = "idle"
	var p: Array[Vector3] = []
	if inside and museum.contains(global_position, 0.5):
		p = museum.path_points(cur_cell(), museum.entrance())
	p.append(museum.door_outside())
	p.append(Vector3(-3, 0, -27.5))
	# school classes go back to their bus; everyone else takes the city bus home
	if kind in ["teacher", "student"] and not trip.is_empty():
		_bus_spot = Vector3(-1.0 + randf_range(-1.5, 1.5), 0, -28.9)
	else:
		_bus_spot = cycle.world.traffic.stop_spot(self) if cycle.world.traffic else Vector3(-16 + randf_range(-2, 2), 0, -29.0)
	p.append(_bus_spot)
	path = p
	inside = false


## Reached the bus stop: sit on the bench (or stand nearby) and wait for the bus.
func _arrive_at_stop() -> void:
	state = S.WAIT_BUS
	visual.set_bubble("")
	if cycle.world.traffic and cycle.world.traffic.is_seat(_bus_spot):
		visual.anim = "sit"
		visual.rotation.y = 0.0  # face the road
	else:
		visual.anim = "idle"
	if cycle.world.traffic:
		cycle.world.traffic.waiting(self)


## The bus is here: walk to its door.
func board_bus(door: Vector3) -> void:
	if state != S.WAIT_BUS:
		return
	state = S.BOARD
	var p: Array[Vector3] = [Vector3(door.x, 0, -29.6), door]
	path = p
	visual.anim = "walk"


func _board() -> void:
	visible = false
	_despawn()


func _despawn() -> void:
	if thief_active:
		var what := "merchandise"
		if stolen.get("t", "") == "gem":
			what = DB.GEMS[stolen["id"]]["name"]
		Events.radio("The shoplifter got away with %s." % what, "threat", global_position)
		for g in cycle.guests:
			if is_instance_valid(g) and g.inside:
				g._note("theft", -1.0)
	if kind == "spy" and not kicked_out and resolved:
		pass
	cycle.guest_left(self)
	queue_free()


func make_review() -> Dictionary:
	if kind == "teacher" and not trip.is_empty() and cycle.tour:
		return cycle.tour.teacher_review(self)
	var stars := clampi(int(round(mood / 20.0)), 1, 5)
	if assaulted:
		stars = 1
	if not harsh.is_empty():
		# an enthusiast who caught a wrong plaque: one star, and their review counts double
		var arr: Array = DB.REVIEW_BAD["harsh_plaque"]
		var t: String = arr[randi() % arr.size()]
		t = t.replace("{fossil}", String(harsh["fossil"])).replace("{wrong}", String(harsh["wrong"]))
		return {"name": gname, "kind": kind, "stars": 1, "text": t, "weight": weight * GameConfig.get_cfg().harsh_review_weight, "key": "harsh_plaque"}
	var good := stars >= 3
	var best_k := ""
	var best_v := 0.0
	for k in notes.keys():
		if String(k).begins_with("_"):
			continue
		var v: float = notes[k]
		if good and v > best_v:
			best_v = v
			best_k = k
		elif not good and v < best_v:
			best_v = v
			best_k = k
	var text := ""
	var bank: Dictionary = DB.REVIEW_GOOD if good else DB.REVIEW_BAD
	if best_k != "" and bank.has(best_k):
		var arr: Array = bank[best_k]
		text = arr[randi() % arr.size()]
	else:
		text = ["Nice little museum.", "Pleasant visit.", "Cute spot by the beach."][randi() % 3] if good else ["Meh.", "Expected more.", "Not my cup of tea."][randi() % 3]
	text = text.replace("{place}", String(notes.get("_place", "gift shop"))).replace("{stand}", String(notes.get("_stand", "snack stand")))
	return {"name": gname, "kind": kind, "stars": stars, "text": text, "weight": weight, "key": best_k}


# ---------------------------------------------------------- school trips ---
## Follow the teacher (or, during a guided tour, the player) through the museum,
## staying a couple of metres behind in a loose group.
func _update_follow(delta: float) -> void:
	var leader_gone: bool = follow_node is Guest and (follow_node as Guest).state in [S.LEAVE, S.WAIT_BUS, S.BOARD]
	if not is_instance_valid(follow_node) or cycle.closing or leader_gone:
		follow_node = null
		state = S.DECIDE
		_leave()
		return
	_follow_t -= delta
	var goal := follow_node.global_position
	var d := goal - global_position
	d.y = 0.0
	if _follow_t <= 0.0:
		_follow_t = 0.7
		if d.length() > 2.2:
			var stand := goal - d.normalized() * 1.6 + offset * 1.4
			var direct: Array[Vector3] = [stand]
			if museum.contains(global_position, 0.2) and museum.contains(stand, -0.2):
				var p := museum.path_points(cur_cell(), museum.world_to_cell(stand))
				path = p if not p.is_empty() else direct
			else:
				path = direct
				if not inside and museum.contains(stand, -0.3):
					inside = true
		else:
			path.clear()
	if path.is_empty():
		visual.anim = "idle"
		_face(goal)
	else:
		var was := speed
		speed = maxf(speed, 2.4 if d.length() < 5.0 else 3.4)
		_move(delta)
		speed = was


## A student reacts to what the tour guide (the player) just told the class.
func tour_react(correct: bool) -> void:
	if correct:
		mood = minf(100.0, mood + 10.0)
		_note("tour", 2.0)
		visual.play_once("cheer")
		visual.set_bubble("!", UIKit.GOOD)
	else:
		mood = maxf(0.0, mood - 25.0)
		_note("bad_tour", -6.0)
		visual.set_bubble("?!", UIKit.BAD)
	get_tree().create_timer(1.8).timeout.connect(_clear_bubble)
