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
	# (no floating name text on cases: visitors - and you - read the real plaque)
	if is_case() or is_mega():
		refresh_display()
	match type:
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


## Small / medium / big single-fossil display cases.
func is_case() -> bool:
	return type == "display_case" or type == "display_case_medium" or type == "display_case_big"


func is_mega() -> bool:
	return type == "display_case_mega"


func is_stand() -> bool:
	return def.get("cat", "") == "Concessions"


func case_size() -> String:
	return String(DB.CASE_OF_BUILD.get(type, ""))

# ----------------------------------------------------------------- prompts --
func _prompt() -> String:
	if sabotaged:
		return "Repair sabotaged %s ($20)" % def["name"]
	if is_case():
		var f := fossil_entry()
		if f.is_empty():
			return "Mount a fossil in this %s" % def["name"]
		return "%s - edit plaque / swap" % GameState.fossil_name(f["f"])
	if is_mega():
		var sp: String = data.get("species", "")
		if sp == "":
			return "Assemble a skeleton in this Mega Display Case"
		return "%s skeleton (%d/%d) - add bones" % [DB.SPECIES[sp]["name"].split(" (")[0], mounted_count(), DB.SPECIES[sp]["pieces"].size()]
	if is_stand():
		return _stand_prompt()
	match type:
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
		"gift_shop":
			return "Gift shop - stock info"
		"aquarium":
			return "Living Fossil Aquarium - read about the species"
		"vending_machine":
			return "Vending machine - buy a Dino Snack ($3)"
	return "%s - read about it" % def["name"] if INFO.has(type) else String(def["name"])


## What the player is told when they look at an attraction (and what it teaches).
const INFO := {
	"touch_table": "Fossil casts are exact copies made from moulds of the real thing, so everyone can touch without wearing the original away.",
	"microscope_station": "Microfossils like foraminifera are smaller than a grain of sand, yet their shells make up whole cliffs of chalk and limestone.",
	"photo_booth": "Scientists think T. rex could not run fast - about as fast as a quick human jog - because it was so heavy.",
	"volcano_diorama": "Huge volcanic eruptions in India (the Deccan Traps) were happening when an asteroid hit 66 million years ago, ending the age of non-bird dinosaurs.",
	"dino_slide": "Sauropods were the biggest land animals ever. Their long necks let them reach food without walking much.",
	"time_tunnel": "Rock layers stack up over time: the deeper the layer, the older it is. That is the 'law of superposition'.",
	"fern_garden": "Ferns, cycads and horsetails are plant groups that were already around before the first dinosaurs.",
	"ammonite_fountain": "Ammonites grew new, bigger chambers as they grew and sealed off the old ones, using them as floats.",
	"bookshelf": "Mary Anning, a self-taught fossil hunter from Lyme Regis, found the first ichthyosaur skeleton known to science.",
	"water_fountain": "Visitors who can get a drink stay longer and grumble less.",
}


func _on_interact() -> void:
	var dc: DayCycle = World.instance.day_cycle if World.instance else null
	if dc and dc.tour and is_instance_valid(dc.tour) and dc.tour.active and dc.tour.present(self):
		return
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
	if is_case():
		Events.open_panel.emit("exhibit", self)
		_update_status()
		return
	if is_mega():
		Events.open_panel.emit("podium", self)
		_update_status()
		return
	if is_stand():
		_stand_use()
		_update_status()
		return
	if INFO.has(type):
		Events.dialog_requested.emit([{"name": String(def["name"]), "text": INFO[type]}])
		return
	match type:
		"vending_machine":
			if GameState.try_spend(3, "Snacks"):
				Audio.sfx("register", 1.2, -6.0)
				Events.say("A Dino Snack! Tasty. (Your own vending machine - the money is yours anyway.)", Color.WHITE)
				GameState.earn(3, "Vending machine")
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
	elif is_case() and museum.has_checker() and plaque_status() in ["wrong", "blank"]:
		t = "Plaque %s!" % ("wrong" if plaque_status() == "wrong" else "blank")
		c = UIKit.BAD
	elif is_stand() and not queue.is_empty():
		t = "%d waiting" % queue.size()
		c = UIKit.CORAL
	elif is_mega() and data.get("species", "") != "":
		var sp: String = data["species"]
		t = "%s  %d/%d" % [DB.SPECIES[sp]["name"].split(" (")[0], mounted_count(), DB.SPECIES[sp]["pieces"].size()]
		c = Color.WHITE
	if status:
		status.text = t
		status.modulate = c
		status.position.y = 4.8 if is_mega() else 2.6


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
	if not is_case():
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
	if is_case():
		var old := fossil_entry()
		if not old.is_empty():
			old["where"] = ""
	elif is_mega():
		for uid in (data.get("pieces", {}) as Dictionary).values():
			var e := GameState.find_uid(int(uid))
			if not e.is_empty():
				e["where"] = ""
		data["pieces"] = {}
		data["species"] = ""


func refresh_display() -> void:
	if is_case():
		if display_node:
			display_node.queue_free()
			display_node = null
		var f := fossil_entry()
		if f.is_empty():
			return
		var sp := GameState.species_of(f["f"])
		var sd: Dictionary = DB.SPECIES[sp]
		display_node = Art.model(sd["model"] if GameState.piece_of(f["f"]) == "" else "bone")
		Art.strip_collision(display_node)
		Art.tint(display_node, "Fossil", sd["color"])
		var show: Array = DB.CASE_SHOW.get(case_size(), [1.6, 1.05])
		display_node.scale = Vector3.ONE * float(sd.get("scale", 1.0)) * float(show[0])
		display_node.position = Vector3(0, float(show[1]), 0)
		add_child(display_node)
	elif is_mega():
		if skeleton:
			skeleton.queue_free()
			skeleton = null
		var sp: String = data.get("species", "")
		if sp != "":
			skeleton = Art.model(DB.SPECIES[sp]["skeleton"])
			skeleton.rotation.y = rot * PI * 0.5
			skeleton.position = Vector3(0, 0.4, 0)
			var b := Art.local_aabb(skeleton)
			var fit := minf(1.0, 5.4 / maxf(maxf(b.size.x, b.size.z), 0.1))
			skeleton.scale = Vector3.ONE * fit
			add_child(skeleton)
			var pieces: Dictionary = data.get("pieces", {})
			var shown := {}
			for pc in pieces.keys():
				shown[DB.PIECE_NODES[pc]] = true
			if pieces.has("back") and not (DB.SPECIES[sp]["pieces"] as Array).has("neck"):
				shown["Neck"] = true
			for n in ["Skull", "Jaw", "Neck", "Back", "Ribs", "Flippers", "ForeFlipper", "HindFlipper", "Tail", "Arms", "Legs"]:
				var node := skeleton.find_child(n, true, false)
				if node is Node3D:
					(node as Node3D).visible = shown.has(n)
		_update_status()


func accurate_plaque() -> bool:
	if not is_case():
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
	if not is_case():
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
	if is_case():
		var f := fossil_entry()
		return "" if f.is_empty() else GameState.species_of(f["f"])
	if is_mega():
		return data.get("species", "") if mounted_count() > 0 else ""
	return ""


const CASE_FUN := {"small": 1.0, "medium": 1.5, "big": 2.3}


func fun_points() -> float:
	if sabotaged:
		return 0.0
	if is_case():
		var f := fossil_entry()
		if f.is_empty():
			return 0.0
		var v := float(DB.RARITY_VALUE[GameState.fossil_rarity(f["f"])]) * (0.5 + 0.5 * float(f["pres"])) * float(CASE_FUN.get(case_size(), 1.0))
		return v * (1.2 if accurate_plaque() else 1.0)
	if is_mega():
		var sp: String = data.get("species", "")
		if sp == "":
			return 0.0
		var per := 12.0 if sp == "apex" or sp == "trex" else 6.0
		return mounted_count() * per + ((70.0 if sp == "apex" or sp == "trex" else 30.0) if skeleton_complete() else 0.0)
	match type:
		"dig_pit":
			return 12.0 + (4.0 if GameState.pit_stock > 0 else 0.0)
		"holo_theater":
			return float(def["fun"]) * (2.0 if museum.has_complete_skeleton_near(global_position, 9.0) else 1.0)
	return float(def.get("fun", 0))


func decor_points() -> float:
	return float(def.get("decor", 0))


func view_value() -> float:
	## Mood boost a guest gets from viewing this.
	if is_case() or is_mega():
		return 3.0 + fun_points() * 0.6
	match type:
		"holo_theater", "aquarium", "dig_pit", "touch_table", "microscope_station", "volcano_diorama", "dino_slide", "time_tunnel", "photo_booth":
			return 3.0 + fun_points() * 0.6
		"dino_statue", "banner", "plant_pot", "floor_lamp", "fern_garden", "ammonite_fountain", "bookshelf":
			return 2.0 + float(def.get("decor", 0)) * 0.15
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
		elif is_case() or not queue.is_empty():
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
