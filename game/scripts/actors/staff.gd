class_name Staff
extends Node3D
## Hired staff: Janitor (cleans), Security Guard (catches thieves/spies,
## handles kids), Paleontology Intern (plaques, wows enthusiasts).
## Each has a temperament and can go rogue (slack off or be rude).

var data: Dictionary
var type := "janitor"
var visual: CharVisual
var museum: Museum
var cycle: DayCycle
var state := "idle"
var rogue := false
var path: Array[Vector3] = []
var job: Variant = null
var timer := 0.0
var inter: Interactable
var speed := 2.6
var _repath_t := 0.0
var _rd := {}
var _knock_t := 0.0
var VENDOR_SERVE_TIME: float:  # seconds per guest (GameConfig)
	get: return GameConfig.get_cfg().vendor_serve_time


func setup(d: Dictionary, m: Museum, c: DayCycle) -> void:
	data = d
	type = d["type"]
	museum = m
	cycle = c
	var look := CharVisual.random_look()
	look["acc"] = ["Vest"]
	match type:
		"janitor":
			look["Shirt"] = Color("3f7fd9")
			look["Hat"] = Color("3f7fd9")
			look["acc"] = ["Vest", "Hat_Cap", "Lanyard"]
		"security":
			look["Shirt"] = Color("2a3550")
			look["Pants"] = Color("1a1a1a")
			look["Hat"] = Color("1a1a1a")
			look["acc"] = ["Vest", "Hat_Cap", "Sunglasses", "Lanyard"]
			speed = 3.2
		"vendor":
			look["Shirt"] = Color("e05252")  # striped-stand red with a paper cap
			look["Hat"] = Color("fff6e6")
			look["acc"] = ["Hat_Cap", "Lanyard"]
			speed = 3.0
		"intern":
			look["Shirt"] = Color("2f8f8f")
			look["Coat"] = Color("f4f4f0")  # lab coat
			look["acc"] = ["Glasses", "Coat", "Lanyard"]
	visual = CharVisual.new()
	add_child(visual)
	visual.setup(look)
	if type == "janitor":
		visual.hold_tool("broom")
		visual.tool_node.visible = false
	inter = Interactable.attach(self, d["name"], _on_player_interact, 0.9, 2.0)
	inter.text_fn = _prompt
	inter.prio = 2
	go_post()


func go_post() -> void:
	var c := museum.entrance() + Vector2i(1 if type != "janitor" else -1, 1)
	if not museum.reachable.has(c):
		c = museum.random_free_cell()
	global_position = museum.cell_center(c) + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
	global_position.y = 0
	state = "idle"
	path.clear()
	job = null
	visual.anim = "idle"
	visual.set_bubble("")
	rogue = false


func _prompt() -> String:
	var role: String = DB.STAFF[type]["name"]
	if rogue:
		return "Deal with %s (%s) - %s" % [data["name"], role, "sleeping on the job!" if type == "janitor" else "being rude to guests!"]
	return "%s - %s" % [data["name"], role]


func _on_player_interact() -> void:
	if rogue:
		Events.open_panel.emit("discipline", self)
	else:
		var lines := {
			"janitor": ["Floors don't sweep themselves!", "Found a gum wrapper shaped like a trilobite.", "Sand. Everywhere. Always."],
			"security": ["All quiet, boss.", "Nobody touches the bones on my watch.", "Keeping an eye on the gift shop."],
			"intern": ["Did you know trilobites had calcite eyes?", "Plaques are all accurate today!", "Can I clean the next fossil? Please?"],
			"vendor": ["Fresh amber lemonade, coming up!", "The popcorn machine and I have an understanding.", "No queue survives me, boss."],
		}
		var arr: Array = lines[type]
		Events.say("%s: \"%s\"" % [data["name"], arr[randi() % arr.size()]], Color.WHITE)


func morale() -> float:
	return float(data.get("morale", 70.0))


## Changes morale; at zero the employee quits on the spot.
func change_morale(amount: float, reason: String = "") -> void:
	if state == "leaving":
		return
	var m := clampf(morale() + amount, 0.0, 100.0)
	data["morale"] = m
	if m <= 0.0:
		quit(reason)


func quit(reason: String = "") -> void:
	if state == "leaving":
		return
	var line: String = DB.QUIT_LINES[randi() % DB.QUIT_LINES.size()]
	Events.radio("%s the %s QUIT! \"%s\"%s" % [data["name"], DB.STAFF[type]["name"], line, (" (" + reason + ")") if reason != "" else ""], "staff", global_position)
	Audio.sfx("error", 0.8)
	cycle.remove_staff(self)
	rogue = false
	state = "leaving"
	inter.enabled = false
	visual.set_bubble(">:(", UIKit.BAD)
	if _rd.size() > 0:
		Ragdoll.recover(self, visual, _rd)
		_rd = {}
	var p: Array[Vector3] = []
	if museum.contains(global_position, 0.5):
		p = museum.path_points(museum.world_to_cell(global_position), museum.entrance())
	p.append(museum.door_outside())
	p.append(Vector3(-3, 0, -27.5))
	p.append(Vector3(-18, 0, -29.0))
	path = p
	speed = 3.0


func reprimand() -> void:
	rogue = false
	data["temper"] = maxf(0.0, float(data.get("temper", 0.5)) - 0.15)
	visual.set_bubble("")
	visual.anim = "idle"
	state = "idle"
	Events.say("%s apologises and gets back to work." % data["name"], UIKit.GOOD)
	change_morale(-8.0, "reprimanded")


func go_rogue() -> void:
	if rogue or state == "knocked":
		return
	rogue = true
	path.clear()
	job = null
	if type == "janitor":
		state = "rogue"
		visual.anim = "sleep"
		visual.set_bubble("Zzz", Color("bcd7ff"))
		Events.radio("Your janitor %s is asleep on the job!" % data["name"], "staff", global_position)
	else:
		state = "rogue"
		visual.set_bubble("!!", UIKit.BAD)
		Events.radio("%s the %s is being rude to guests!" % [data["name"], DB.STAFF[type]["name"]], "staff", global_position)


func knockback(v: Vector3, by_player: bool) -> void:
	if state == "knocked" or state == "leaving":
		return
	var hurt := 0.0
	if by_player:
		if rogue:
			Events.say("You taught %s a lesson. Back to work!" % data["name"], UIKit.GOLD)
			data["temper"] = maxf(0.0, float(data.get("temper", 0.5)) - 0.25)
			hurt = -20.0
		else:
			data["temper"] = minf(1.0, float(data.get("temper", 0.5)) + 0.2)
			Events.say("%s didn't deserve that... (morale -30)" % data["name"], UIKit.CORAL)
			hurt = -30.0
		for g in cycle.guests:
			if is_instance_valid(g) and g.inside and g.global_position.distance_to(global_position) < 8.0:
				g.mood -= 6.0
				g._note("witness", -1.0)
	rogue = false
	visual.set_bubble("")
	state = "knocked"
	_knock_t = 1.6
	path.clear()
	_rd = Ragdoll.knock(self, visual, v)
	if hurt < 0.0:
		data["morale"] = clampf(morale() + hurt, 0.0, 100.0)


func _process(delta: float) -> void:
	if state == "leaving":
		if _move(delta):
			queue_free()
		return
	if state == "knocked":
		_knock_t -= delta
		if _knock_t <= 0.0 and (Ragdoll.settled(_rd) or _knock_t < -2.5):
			Ragdoll.recover(self, visual, _rd)
			_rd = {}
			if not museum.reachable.has(museum.world_to_cell(global_position)):
				global_position = museum.cell_center(museum.nearest_free(museum.world_to_cell(global_position)))
			state = "idle"
			if morale() <= 0.0:
				quit("you shoved them")
			elif morale() < 15.0 and randf() < 0.5:
				quit("morale collapsed")
		return
	if GameState.phase != GameState.Phase.OPEN:
		visual.anim = "idle"
		return
	if rogue:
		if type != "janitor":
			_rude_wander(delta)
		return
	if typeof(job) == TYPE_OBJECT and not is_instance_valid(job):
		job = null
		state = "idle"
		path.clear()
	elif typeof(job) == TYPE_DICTIONARY and not museum.mess.has(job):
		job = null
		state = "idle"
		path.clear()
	match state:
		"idle":
			_find_job()
		"walk":
			_repath_t -= delta
			if type == "security" and typeof(job) == TYPE_OBJECT and _repath_t <= 0.0:
				_repath_t = 1.0
				_path_to_cell(museum.world_to_cell((job as Node3D).global_position))
			if _move(delta):
				_arrive()
		"work":
			timer -= delta
			if timer <= 0.0:
				_complete()


func _move(delta: float) -> bool:
	if path.is_empty():
		return true
	var d := path[0] - global_position
	d.y = 0
	if d.length() < 0.12:
		path.pop_front()
		return path.is_empty()
	global_position += d.normalized() * minf(speed * delta, d.length())
	global_position.y = 0
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-d.x, -d.z), minf(1.0, 10.0 * delta))
	visual.anim = "walk"
	visual.speed = speed / 4.0
	return false


func _path_to_cell(c: Vector2i) -> bool:
	var from := museum.world_to_cell(global_position)
	if not museum.reachable.has(c):
		c = museum.nearest_free(c)
	path = museum.path_points(from, c)
	return true


func _find_job() -> void:
	match type:
		"janitor":
			var taken := {}
			for s in cycle.staff_nodes:
				if s != self and is_instance_valid(s) and typeof(s.job) == TYPE_DICTIONARY and s.job.has("node"):
					taken[s.job["node"]] = true
			var m := museum.nearest_mess(global_position, taken)
			if not m.is_empty():
				job = m
				_path_to_cell(museum.world_to_cell((m["node"] as Node3D).global_position))
				state = "walk"
				return
			for o in museum.all_objects():
				if (o.type == "trash_bin" and o.fill >= 3) or (o.type == "restroom" and o.dirt >= 3):
					job = o
					var sc := museum.stand_cell(o, museum.world_to_cell(global_position))
					if sc.x >= 0:
						path = museum.path_points(museum.world_to_cell(global_position), sc)
						state = "walk"
						return
		"security":
			for g in cycle.guests:
				if not is_instance_valid(g) or not g.inside or g.state == Guest.S.KNOCKED:
					continue
				if g.thief_active or (g.kind == "spy" and g.state != Guest.S.LEAVE) or g.state == Guest.S.TANTRUM or g.state == Guest.S.CLIMB:
					job = g
					_path_to_cell(g.cur_cell())
					state = "walk"
					return
		"vendor":
			# the stand with the longest queue that no other vendor is already serving
			var busy := {}
			for st in cycle.staff_nodes:
				if st != self and is_instance_valid(st) and typeof(st.job) == TYPE_OBJECT and is_instance_valid(st.job):
					busy[st.job] = true
			var best: PlacedObject = null
			for o in museum.all_objects():
				if o.def.get("cat", "") == "Concessions" and not o.queue.is_empty() and not busy.has(o):
					if best == null or o.queue.size() > best.queue.size():
						best = o
			if best:
				var sc := museum.stand_cell(best, museum.world_to_cell(global_position))
				if sc.x >= 0:
					job = best
					path = museum.path_points(museum.world_to_cell(global_position), sc)
					state = "walk"
					return
		"intern":
			var cases := museum.objects_of("display_case")
			if not cases.is_empty() and randf() < 0.02:
				var o: PlacedObject = cases[randi() % cases.size()]
				var sc := museum.stand_cell(o, museum.world_to_cell(global_position))
				if sc.x >= 0:
					job = o
					path = museum.path_points(museum.world_to_cell(global_position), sc)
					state = "walk"
					return
	if randf() < 0.01:
		_path_to_cell(museum.random_free_cell())
		job = null
		state = "walk"
	else:
		visual.anim = "idle"


func _arrive() -> void:
	if job == null:
		state = "idle"
		return
	if type == "security":
		if typeof(job) == TYPE_OBJECT and is_instance_valid(job) and job is Guest:
			var g: Guest = job
			if g.global_position.distance_to(global_position) < 2.2:
				_resolve_guest(g)
				job = null
				state = "idle"
			else:
				state = "walk"
				_path_to_cell(g.cur_cell())
		else:
			job = null
			state = "idle"
		return
	state = "work"
	timer = 2.0 if type == "janitor" else (VENDOR_SERVE_TIME if type == "vendor" else 3.0)
	visual.anim = "sweep" if type == "janitor" else ("idle" if type == "vendor" else "inspect")
	if type == "vendor" and job is Node3D:
		var d := (job as Node3D).global_position - global_position
		visual.rotation.y = atan2(-d.x, -d.z)
	if type == "janitor" and visual.tool_node:
		visual.tool_node.visible = true


func _complete() -> void:
	if type == "janitor" and visual.tool_node:
		visual.tool_node.visible = false
	if type == "vendor":
		_serve_next()
		return
	if typeof(job) == TYPE_DICTIONARY:
		museum.clean_mess(job)
	elif typeof(job) == TYPE_OBJECT and is_instance_valid(job) and job is PlacedObject:
		(job as PlacedObject).clean()
	job = null
	state = "idle"
	visual.anim = "idle"


## Vendor: hand a snack to the guest at the front of the queue, then keep
## serving while anyone is still waiting at this stand.
func _serve_next() -> void:
	var stand := job as PlacedObject
	if stand == null or not is_instance_valid(stand):
		job = null
		state = "idle"
		return
	while not stand.queue.is_empty():
		var g = stand.queue.pop_front()
		if is_instance_valid(g) and g.has_method("served"):
			g.served(stand)
			Audio.sfx("register", 1.1, -10.0)
			break
	stand._update_status()
	if stand.queue.is_empty():
		job = null
		state = "idle"
		visual.anim = "idle"
	else:
		timer = VENDOR_SERVE_TIME


func _resolve_guest(g: Guest) -> void:
	if g.thief_active or g.kind == "spy":
		g.catch_thief()
		Events.say("Security %s caught the culprit!" % data["name"], UIKit.GOOD)
	elif g.state == Guest.S.TANTRUM:
		g._end_tantrum(true)
	elif g.state == Guest.S.CLIMB:
		g.get_down()


func _rude_wander(delta: float) -> void:
	if path.is_empty():
		var gs: Array = []
		for g in cycle.guests:
			if is_instance_valid(g) and g.inside:
				gs.append(g)
		if gs.is_empty():
			return
		var g: Guest = gs[randi() % gs.size()]
		_path_to_cell(g.cur_cell())
	if _move(delta):
		visual.anim = "wave"
