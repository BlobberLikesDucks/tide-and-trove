class_name PlacedObject
extends Node3D
## One placed exhibit / attraction / amenity / decoration inside the museum.

static var BIN_CAP: int:
	get: return GameConfig.get_cfg().trash_bin_capacity
static var RESTROOM_DIRTY: int:
	get: return GameConfig.get_cfg().restroom_dirty_at

var museum: Museum
var entry: Dictionary
var data: Dictionary
var type := ""
var def: Dictionary
var cell := Vector2i.ZERO
var rot := 0
var cells: Array[Vector2i] = []
var model: Node3D
var inter: Interactable
var fill := 0
var dirt := 0
var sabotaged := false
var climber: Node = null
var display_node: Node3D
var plaque: Label3D
var status: Label3D
var skeleton: Node3D
var holo: Node3D
var creatures: Array = []
var _t := 0.0
## Concession stands: guests waiting to be served by the player (oldest first).
var queue: Array = []
var _check_t := 0.0


func setup(m: Museum, e: Dictionary) -> void:
	museum = m
	entry = e
	type = e["type"]
	def = DB.BUILD[type]
	if not (e.get("data") is Dictionary):
		e["data"] = {}
	data = e["data"]
	cell = Vector2i(int(e["cell"][0]), int(e["cell"][1]))
	rot = int(e["rot"])
	cells = Museum.footprint(type, cell, rot)
	position = museum.footprint_center(cells)
	model = Art.model(def["model"])
	model.rotation.y = rot * PI * 0.5
	add_child(model)
	if not walkable() and not Art.has_proxy(model):
		var b := Art.local_aabb(model)
		var sz := b.size
		if rot % 2 == 1:
			sz = Vector3(sz.z, sz.y, sz.x)
		Art.box_collider(self, Vector3(minf(sz.x, cells.size() * 2.0) * 0.9, sz.y, sz.z * 0.9), Vector3(0, sz.y * 0.5, 0))
	status = Art.label3d("", 34, UIKit.GOLD)
	status.position.y = 2.6
	status.visibility_range_end = 11.0  # only near-by status tags, no floating text across the map
	add_child(status)
	inter = Interactable.attach(self, def["name"], _on_interact, 1.0 + 0.5 * maxf(def["size"].x, def["size"].y), 2.4)
	inter.text_fn = _prompt
	match type:
		"display_case":
			plaque = Art.label3d("", 20, Color("3a2a10"), false)
			plaque.outline_size = 0
			plaque.position = Vector3(0, 0.66, 0.57)
			plaque.rotation.x = -0.35
			plaque.pixel_size = 0.004
			model.add_child(plaque)
			refresh_display()
		"mega_podium":
			refresh_display()
		"aquarium":
			_spawn_creatures()
		"holo_theater":
			holo = Art.model("dino_statue")
			Art.strip_collision(holo)
			Art.ghostify(holo, Color(0.4, 1.0, 1.0, 0.35))
			holo.position = Vector3(0, 0.5, 0)
			holo.scale = Vector3.ONE * 1.1
			add_child(holo)
	_update_status()


func walkable() -> bool:
	return def.get("walkable", false)

# ----------------------------------------------------------------- prompts --
func _prompt() -> String:
	if sabotaged:
		return "Repair sabotaged %s ($20)" % def["name"]
	match type:
		"display_case":
			var f := fossil_entry()
			if f.is_empty():
				return "Mount a fossil in this Display Case"
			return "%s - edit plaque / swap" % GameState.fossil_name(f["f"])
		"mega_podium":
			var sp: String = data.get("species", "")
			if sp == "":
				return "Assemble a skeleton on this podium"
			return "%s skeleton (%d/%d) - add bones" % [DB.SPECIES[sp]["name"].split(" (")[0], mounted_count(), DB.SPECIES[sp]["pieces"].size()]
		"dig_pit":
			return "Bury duplicate fossils (stock: %d digs)" % GameState.pit_stock
		"restroom":
			return "Clean the restroom" if dirt >= RESTROOM_DIRTY else "Restroom (clean)"
		"trash_bin":
			if GameState.held().get("t", "") == "trash":
				return "Throw trash in the bin (%d/%d)" % [fill, BIN_CAP] if fill < BIN_CAP else "Bin is FULL - empty it first"
			return "Empty the trash bin" if fill >= 3 else "Trash bin (%d/%d)" % [fill, BIN_CAP]
		"plaque_checker":
			var bad := museum.wrong_plaques().size()
			return "Fact-Check Kiosk - %s" % ("all plaques correct" if bad == 0 else "%d display(s) need fixing" % bad)
		"popcorn_stand", "dinodog_stand", "lemonade_stand":
			return _stand_prompt()
		"gift_shop":
			return "Gift shop - stock info"
		"aquarium":
			return "Living Fossil Aquarium - read about the species"
	return def["name"]


func _on_interact() -> void:
	if climber and is_instance_valid(climber):
		climber.call("get_down")
		return
	if sabotaged:
		if GameState.try_spend(20, "Repairs"):
			sabotaged = false
			Audio.sfx("register")
			Events.say("Exhibit repaired.", UIKit.GOOD)
			_update_status()
		else:
			Events.say("Not enough cash to repair ($20).", UIKit.CORAL)
			Audio.sfx("error")
		return
	match type:
		"display_case":
			Events.open_panel.emit("exhibit", self)
		"mega_podium":
			Events.open_panel.emit("podium", self)
		"dig_pit":
			Events.open_panel.emit("pit", self)
		"gift_shop":
			Events.open_panel.emit("giftshop", self)
		"restroom":
			if dirt > 0:
				dirt = 0
				Audio.sfx("brush")
				Events.say("Restroom sparkling clean.", UIKit.GOOD)
		"trash_bin":
			if GameState.held().get("t", "") == "trash":
				if fill >= BIN_CAP:
					Events.say("This bin is full. Empty it first (look at it with empty hands).", UIKit.CORAL)
					Audio.sfx("error")
				else:
					GameState.take_held()
					fill += 1
					Audio.sfx("brush", 1.3)
					Events.say("Trash in the bin. (%d/%d)" % [fill, BIN_CAP], UIKit.GOOD)
			elif fill > 0:
				fill = 0
				Audio.sfx("brush")
				Events.say("Trash bin emptied.", UIKit.GOOD)
		"plaque_checker":
			Events.open_panel.emit("factcheck", self)
		"popcorn_stand", "dinodog_stand", "lemonade_stand":
			_stand_use()
		"aquarium":
			var lines: Array = []
			for k in DB.LIVING.keys():
				var l: Dictionary = DB.LIVING[k]
				lines.append({"name": "%s (%s)" % [l["name"], l["sci"]], "text": l["fact"]})
			Events.dialog_requested.emit(lines)
	_update_status()


func clean() -> void:
	dirt = 0
	fill = 0
	_update_status()


func _update_status() -> void:
	var t := ""
	var c := UIKit.GOLD
	if sabotaged:
		t = "DAMAGED"
		c = UIKit.BAD
	elif type == "restroom" and dirt >= RESTROOM_DIRTY:
		t = "Needs cleaning!"
		c = UIKit.CORAL
	elif type == "trash_bin" and fill >= BIN_CAP:
		t = "FULL"
		c = UIKit.CORAL
	elif type == "display_case" and museum.has_checker() and plaque_status() in ["wrong", "blank"]:
		t = "Plaque %s!" % ("wrong" if plaque_status() == "wrong" else "blank")
		c = UIKit.BAD
	elif type in ["popcorn_stand", "dinodog_stand", "lemonade_stand"] and not queue.is_empty():
		t = "%d waiting" % queue.size()
		c = UIKit.CORAL
	elif type == "mega_podium" and data.get("species", "") != "":
		var sp: String = data["species"]
		t = "%s  %d/%d" % [DB.SPECIES[sp]["name"].split(" (")[0], mounted_count(), DB.SPECIES[sp]["pieces"].size()]
		c = Color.WHITE
	if status:
		status.text = t
		status.modulate = c
		status.position.y = 4.6 if type == "mega_podium" else 2.6


func add_dirt(n: int = 1) -> void:
	dirt += n
	if dirt == RESTROOM_DIRTY:
		Events.radio("Restroom needs cleaning!", "mess", global_position)
	_update_status()


func add_fill() -> bool:
	if fill >= BIN_CAP:
		return false
	fill += 1
	if fill == BIN_CAP:
		Events.radio("A trash bin is full.", "mess", global_position)
	_update_status()
	return true


func sabotage() -> void:
	sabotaged = true
	_update_status()

# ---------------------------------------------------------------- display ---
func fossil_entry() -> Dictionary:
	if type != "display_case":
		return {}
	var uid := int(data.get("uid", 0))
	if uid <= 0:
		return {}
	return GameState.find_uid(uid)


func mount_fossil(e: Dictionary) -> void:
	var old := fossil_entry()
	if not old.is_empty():
		old["where"] = ""
	data["uid"] = int(e["uid"])
	e["where"] = "case"
	data["plaque"] = {}
	refresh_display()
	Events.museum_changed.emit()


func unmount_fossil() -> void:
	var old := fossil_entry()
	if not old.is_empty():
		old["where"] = ""
	data.erase("uid")
	data["plaque"] = {}
	refresh_display()
	Events.museum_changed.emit()


func mounted_count() -> int:
	return (data.get("pieces", {}) as Dictionary).size()


func skeleton_complete() -> bool:
	var sp: String = data.get("species", "")
	if sp == "":
		return false
	return mounted_count() >= DB.SPECIES[sp]["pieces"].size()


func mount_species(sp: String) -> int:
	if data.get("species", "") != sp:
		release_contents()
		data["species"] = sp
		data["pieces"] = {}
	var pieces: Dictionary = data["pieces"]
	var added := 0
	for e in GameState.free_fossils(sp):
		var pc := GameState.piece_of(e["f"])
		if pc == "" or pieces.has(pc):
			continue
		pieces[pc] = int(e["uid"])
		e["where"] = "podium"
		added += 1
	refresh_display()
	Events.museum_changed.emit()
	return added


func release_contents() -> void:
	match type:
		"display_case":
			var old := fossil_entry()
			if not old.is_empty():
				old["where"] = ""
		"mega_podium":
			for uid in (data.get("pieces", {}) as Dictionary).values():
				var e := GameState.find_uid(int(uid))
				if not e.is_empty():
					e["where"] = ""
			data["pieces"] = {}
			data["species"] = ""


func refresh_display() -> void:
	if type == "display_case":
		if display_node:
			display_node.queue_free()
			display_node = null
		var f := fossil_entry()
		if f.is_empty():
			plaque.text = "(empty)"
			return
		var sp := GameState.species_of(f["f"])
		var sd: Dictionary = DB.SPECIES[sp]
		display_node = Art.model(sd["model"] if GameState.piece_of(f["f"]) == "" else "bone")
		Art.tint(display_node, "Fossil", sd["color"])
		var s: float = sd.get("scale", 1.0) * 1.6
		display_node.scale = Vector3.ONE * s
		display_node.position = Vector3(0, 1.05, 0)
		add_child(display_node)
		var pl: Dictionary = data.get("plaque", {})
		var txt := GameState.fossil_name(f["f"])
		if pl.is_empty():
			txt += "\n(blank plaque)"
		else:
			txt += "\n%s | %s | %s" % [pl.get("era", "?"), pl.get("diet", "?"), pl.get("habitat", "?")]
		plaque.text = txt
	elif type == "mega_podium":
		if skeleton:
			skeleton.queue_free()
			skeleton = null
		var sp: String = data.get("species", "")
		if sp != "":
			skeleton = Art.model(DB.SPECIES[sp]["skeleton"])
			skeleton.rotation.y = rot * PI * 0.5
			skeleton.position = Vector3(0, 0.4, 0)
			var b := Art.local_aabb(skeleton)
			var fit := minf(1.0, 5.3 / maxf(b.size.x, 0.1))
			skeleton.scale = Vector3.ONE * fit
			add_child(skeleton)
			var pieces: Dictionary = data.get("pieces", {})
			var shown := {}
			for pc in pieces.keys():
				shown[DB.PIECE_NODES[pc]] = true
			if pieces.has("back"):
				shown["Neck"] = true
			for n in ["Skull", "Jaw", "Neck", "Back", "Ribs", "Flippers", "ForeFlipper", "HindFlipper", "Tail"]:
				var node := skeleton.find_child(n, true, false)
				if node is Node3D:
					(node as Node3D).visible = shown.has(n)
		_update_status()


func accurate_plaque() -> bool:
	if type != "display_case":
		return false
	var f := fossil_entry()
	if f.is_empty():
		return false
	var pl: Dictionary = data.get("plaque", {})
	if pl.is_empty():
		return false
	var sd: Dictionary = DB.SPECIES[GameState.species_of(f["f"])]
	return pl.get("era") == sd["era"] and pl.get("diet") == sd["diet"] and pl.get("habitat") == sd["habitat"]


## "" (nothing on display), "blank" (no tags picked), "wrong" or "ok".
func plaque_status() -> String:
	if type != "display_case":
		return ""
	var f := fossil_entry()
	if f.is_empty():
		return ""
	var pl: Dictionary = data.get("plaque", {})
	if pl.size() < 3:
		return "blank"
	return "ok" if accurate_plaque() else "wrong"


## Human-readable list of the wrong tags, e.g. "Era: Mesozoic".
func wrong_tags() -> Array:
	var out: Array = []
	var f := fossil_entry()
	if f.is_empty():
		return out
	var sd: Dictionary = DB.SPECIES[GameState.species_of(f["f"])]
	var pl: Dictionary = data.get("plaque", {})
	for k in ["era", "diet", "habitat"]:
		if pl.has(k) and pl[k] != sd[k]:
			out.append("%s: %s" % [k.capitalize(), pl[k]])
	return out

# ---------------------------------------------------------- concessions ---
func _stand_prompt() -> String:
	var h := GameState.held()
	var what: String = def.get("item", "snack")
	var waiting := "  (%d waiting)" % queue.size() if not queue.is_empty() else "  (no one waiting)"
	if h.get("t", "") == "serve" and h.get("stand", "") == type:
		if not h.get("full", false):
			return "Fill it with %s%s" % [what, waiting]
		return ("Serve %s to the next guest" % what) if not queue.is_empty() else "Nobody is waiting for %s yet" % what
	if h.get("t", "") == "serve":
		return "That's for another stand"
	if GameState.free_hotbar_slot() < 0:
		return "Free a hotbar slot to grab a %s%s" % [_cup_word(), waiting]
	return "Grab a %s%s" % [_cup_word(), waiting]


func _cup_word() -> String:
	return {"held_cup": "cup", "held_bag": "popcorn bag", "held_dog": "bun"}.get(String(def.get("serve", "")), "cup")


func _stand_use() -> void:
	var h := GameState.held()
	if h.get("t", "") == "serve" and h.get("stand", "") == type:
		if not h.get("full", false):
			h["full"] = true
			Audio.sfx("pickup", 0.7)
			Events.say("Filled with %s. Now serve it!" % def.get("item", "snack"), UIKit.GOOD)
			GameState.changed.emit()
			return
		if queue.is_empty():
			Events.say("Nobody is queuing here right now.", Color.WHITE)
			return
		var g = queue.pop_front()
		GameState.take_held()
		if is_instance_valid(g) and g.has_method("served"):
			g.served(self)
		_update_status()
		return
	if h.get("t", "") == "serve":
		Events.say("You're holding something for another stand.", UIKit.CORAL)
		return
	if not GameState.hotbar_add({"t": "serve", "stand": type, "full": false}):
		Events.say("Your hotbar is full - free a slot first.", UIKit.CORAL)
		Audio.sfx("error")
		return
	Audio.sfx("pickup", 1.2)


func join_queue(g: Node) -> void:
	if not queue.has(g):
		queue.append(g)
		if queue.size() == 1:
			Events.radio("A guest is waiting at the %s!" % def["name"], "info", global_position)
	_update_status()


func leave_queue(g: Node) -> void:
	queue.erase(g)
	_update_status()


func species_shown() -> String:
	if type == "display_case":
		var f := fossil_entry()
		return "" if f.is_empty() else GameState.species_of(f["f"])
	if type == "mega_podium":
		return data.get("species", "")
	return ""


func fun_points() -> float:
	if sabotaged:
		return 0.0
	match type:
		"display_case":
			var f := fossil_entry()
			if f.is_empty():
				return 0.0
			var v := float(DB.RARITY_VALUE[GameState.fossil_rarity(f["f"])]) * (0.5 + 0.5 * float(f["pres"]))
			return v * (1.2 if accurate_plaque() else 1.0)
		"mega_podium":
			var sp: String = data.get("species", "")
			if sp == "":
				return 0.0
			var per := 12.0 if sp == "apex" else 6.0
			return mounted_count() * per + ((70.0 if sp == "apex" else 30.0) if skeleton_complete() else 0.0)
		"dig_pit":
			return 12.0 + (4.0 if GameState.pit_stock > 0 else 0.0)
		"holo_theater":
			return float(def["fun"]) * (2.0 if museum.has_complete_skeleton_near(global_position, 9.0) else 1.0)
	return float(def.get("fun", 0))


func decor_points() -> float:
	return float(def.get("decor", 0))


func view_value() -> float:
	## Mood boost a guest gets from viewing this.
	match type:
		"display_case", "mega_podium", "holo_theater", "aquarium", "dig_pit":
			return 3.0 + fun_points() * 0.6
		"dino_statue", "banner", "plant_pot", "floor_lamp":
			return 2.0
	return 1.0

# -------------------------------------------------------------- animation ---
func _spawn_creatures() -> void:
	var span := 1.4
	for i in range(3):
		var crab := Art.model("horseshoe_crab")
		crab.position = Vector3(randf_range(-span, span), 1.0, randf_range(-0.3, 0.3))
		crab.scale = Vector3.ONE * 1.4
		model.add_child(crab)
		creatures.append({"node": crab, "kind": "crab", "phase": randf() * TAU, "speed": randf_range(0.2, 0.4)})
	for i in range(2):
		var n := Art.model("nautilus")
		n.position = Vector3(randf_range(-span, span), 1.6, 0)
		n.scale = Vector3.ONE * 1.6
		model.add_child(n)
		creatures.append({"node": n, "kind": "naut", "phase": randf() * TAU, "speed": randf_range(0.3, 0.6)})


func _process(delta: float) -> void:
	_t += delta
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = 1.0
		if type == "plaque_checker":
			Art.tint(model, "Lamp", UIKit.GOOD if museum.wrong_plaques().is_empty() else UIKit.BAD, 1.5)
		elif type == "display_case" or not queue.is_empty():
			queue = queue.filter(func(g): return is_instance_valid(g))
			_update_status()
	if display_node:
		display_node.rotation.y += delta * 0.6
	if holo:
		holo.rotation.y += delta * 0.8
		holo.position.y = 0.5 + sin(_t * 1.5) * 0.08
	for c in creatures:
		var n: Node3D = c["node"]
		var ph: float = c["phase"] + _t * float(c["speed"])
		if c["kind"] == "crab":
			n.position.x = sin(ph) * 1.4
			n.rotation.y = PI * 0.5 if cos(ph) > 0 else -PI * 0.5
		else:
			n.position.x = sin(ph) * 1.3
			n.position.y = 1.6 + sin(ph * 2.3) * 0.25
			n.rotation.y = 0.0 if cos(ph) > 0 else PI
