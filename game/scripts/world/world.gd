class_name World
extends Node3D
## Gameplay root. The whole static world (environment, sun, ground, town, shop,
## lab, museum frontage, beach dressing and bounds) is laid out in the editor in
## res://scenes/world.tscn; this script only wires the systems together, spawns
## the player prefab at PlayerSpawn, runs story beats and the objective chain.

static var instance: World

const LAB := Vector3(18.0, 0.0, -18.0)
const SHOP := Vector3(0.0, 0.0, -44.0)

## Player prefab instanced at the PlayerSpawn marker.
@export var player_scene: PackedScene = preload("res://scenes/actors/player.tscn")
## HUD / panels / dialog layer (editor scene).
@export var ui_scene: PackedScene = preload("res://scenes/ui/game_ui.tscn")
## Pearl's look (CharVisual palette + outfit pieces).
@export var shopkeeper_look: Dictionary = {"Shirt": Color("e0705a"), "Hair": Color("8a8a8a"), "Skin": Color("c68a5e"), "Hat": Color("3f7f6a"), "acc": ["Hat_Cap", "Glasses"]}

@onready var museum: Museum = $Museum
@onready var beach: Beach = $Beach
@onready var sun: DirectionalLight3D = $Sun
@onready var lab_root: Node3D = $Lab
@onready var env: Environment = ($WorldEnvironment as WorldEnvironment).environment
var sky_mat: ProceduralSkyMaterial
var player: Player
var day_cycle: DayCycle
var build: BuildMode
var ui: GameUI
var traffic: Traffic
## The Curator's Office (computer + J-Mail), built with the 3-star expansion.
var office: Office
## Where the office desk sits inside the Prep Lab pavilion (lab-local).
@export var office_spot: Vector3 = Vector3(0.0, 0.0, 2.7)
@export var office_yaw_deg: float = 180.0
var _obj_t := 0.0
var _was_inside := false
var shopkeeper: CharVisual


func _ready() -> void:
	instance = self
	Art.prepare(self)  # cel-shade + collision-normalise every editor-placed model
	_tune_props()  # static world only (before any actor exists)
	_snap_grass.call_deferred()
	env = env.duplicate(true)  # day/night tweaks never write back to the .tres
	($WorldEnvironment as WorldEnvironment).environment = env
	sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	player = player_scene.instantiate() as Player
	add_child(player)
	var spawn := $PlayerSpawn as Node3D
	player.global_position = spawn.global_position
	player.cam_yaw = spawn.rotation.y
	var spot := get_node("Town/ShopkeeperSpot") as Node3D
	shopkeeper = CharVisual.new()
	add_child(shopkeeper)
	shopkeeper.global_position = spot.global_position
	shopkeeper.setup(shopkeeper_look)
	day_cycle = DayCycle.new()
	add_child(day_cycle)
	day_cycle.setup(self, museum)
	build = BuildMode.new()
	add_child(build)
	traffic = Traffic.new()
	traffic.name = "Traffic"
	add_child(traffic)
	_ensure_office()
	Events.expansion_bought.connect(_on_expansion)
	ui = ui_scene.instantiate() as GameUI
	add_child(ui)
	Events.half_star_gained.connect(_on_half_star)
	Events.museum_changed.connect(_check_win)
	Events.discovery.connect(_on_discovery)
	GameState.changed.connect(_on_state_changed)
	Settings.changed.connect(_apply_graphics)
	_apply_graphics()
	Audio.play_music("prep")
	GameState.phase = GameState.Phase.PREP
	Events.phase_changed.emit(GameState.phase)
	_set_sun(9.0)
	if not GameState.flags.get("intro", false):
		call_deferred("_intro")
	update_objective()
	if not GameState.pending_world.is_empty():
		restore_snapshot.call_deferred(GameState.take_pending_world())
	var args := OS.get_cmdline_user_args()
	if args.has("--autotest") or args.has("--shots"):
		add_child(Autotest.new())
	elif args.has("--look"):
		add_child(LookShots.new())

# --------------------------------------------- InteractSpot actions/prompts ---
## Generic action used by InteractSpot components placed in the scene.
func open_panel(panel: String, data: Variant = null) -> void:
	Events.open_panel.emit(panel, data)


func workbench_prompt() -> String:
	return "Workbench - clean fossils (%d encased)" % GameState.encased_items().size()


func desk_prompt() -> String:
	var n := GameState.unclaimed_count()
	return "Curator's Desk - Field Guide" + (" (%d discoveries to claim!)" % n if n > 0 else "")


func storage_prompt() -> String:
	return "Storage crates - open (%d stored, backpack %d/%d)" % [GameState.storage.size(), GameState.backpack.size(), GameState.backpack_capacity()]


func actors() -> Array:
	var out: Array = []
	for g in day_cycle.guests:
		if is_instance_valid(g):
			out.append(g)
	for s in day_cycle.staff_nodes:
		if is_instance_valid(s):
			out.append(s)
	return out

func _apply_graphics() -> void:
	if sun:
		sun.shadow_enabled = Settings.shadows_enabled()
	var q := Settings.quality()
	if env:
		env.ssao_enabled = q >= 2
		env.glow_enabled = q >= 1
		env.fog_aerial_perspective = 0.35 if q >= 1 else 0.0
	if sun:
		sun.directional_shadow_max_distance = [60.0, 90.0, 140.0][q]


## Performance: small scattered props stop drawing (and casting shadows) when far away.
func _tune_props() -> void:
	for mi in Art.meshes(self):
		if mi.mesh == null or mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		var sz := mi.mesh.get_aabb().size.length()
		if sz < 1.2:
			mi.visibility_range_end = 45.0
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif sz < 4.0:
			mi.visibility_range_end = 110.0


## Grass tufts were placed at a flat height, but the painted ground sheets dip and
## rise a little: drop every tuft onto the real ground surface so none float.
func _snap_grass() -> void:
	var grass := get_node_or_null("Beach/Grass")
	if grass == null:
		return
	var temp: Array = []
	for path in ["Beach/ZoneGrounds", "Ground/GroundGrass", "Ground/GroundFill", "Ground/ShoreSlope"]:
		var n := get_node_or_null(path)
		if n == null:
			continue
		for mi in Art.meshes(n):
			if mi.mesh == null:
				continue
			var body := StaticBody3D.new()
			body.collision_layer = 1 << 9  # a private layer only this probe uses
			body.collision_mask = 0
			var cs := CollisionShape3D.new()
			cs.shape = mi.mesh.create_trimesh_shape()
			body.add_child(cs)
			mi.add_child(body)
			temp.append(body)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	for t in grass.get_children():
		if not (t is Node3D):
			continue
		var p: Vector3 = (t as Node3D).global_position
		var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3, 0), p - Vector3(0, 3, 0), 1 << 9)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			(t as Node3D).global_position.y = float(hit["position"].y) - 0.03
	for b in temp:
		b.queue_free()


## An Expansion node was bought in the Upgrade Tree: build the bigger museum now.
func _on_expansion(level: int) -> void:
	museum.expand(level)
	day_cycle.spawn_staff()
	build.refit()
	_ensure_office()
	Audio.sfx("fanfare")
	Events.say("Museum expanded to %dx%d!" % [museum.W, museum.D], UIKit.GOLD)
	if GameState.has_office() and office and not GameState.flags.get("office_intro", false):
		GameState.flags["office_intro"] = true
		Mail.generate_day()
		Events.dialog_requested.emit([
			{"name": "Pearl", "text": "Fancy! The expansion came with a Curator's Office - there's a computer in the Prep Lab now."},
			{"name": "Pearl", "text": "Check your J-Mail every morning: schools book class trips there. And careful - scammers love new museums. If an email promises free money, DELETE it."},
		])


func _ensure_office() -> void:
	if office or not GameState.has_office():
		return
	office = Office.new()
	office.name = "Office"
	lab_root.add_child(office)
	office.position = office_spot
	office.rotation.y = deg_to_rad(office_yaw_deg)


func _set_sun(h: float) -> void:
	var t := clampf((h - 6.0) / 12.0, 0.0, 1.0)
	var elev := deg_to_rad(10.0 + 55.0 * sin(t * PI))
	sun.rotation = Vector3(-elev, deg_to_rad(lerpf(75.0, -75.0, t)), 0)
	var dusk := clampf((h - 15.5) / 3.0, 0.0, 1.0)
	sun.light_color = Color("fff1d6").lerp(Color("ffb070"), dusk)
	sun.light_energy = lerpf(1.3, 0.9, dusk)
	sky_mat.sky_horizon_color = Color("bfe8f2").lerp(Color("ffc08a"), dusk)
	sky_mat.sky_top_color = Color("3f8fd0").lerp(Color("5a5fa8"), dusk)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	env.fog_light_color = Color("cde8f0").lerp(Color("f2c8a8"), dusk)


# ------------------------------------------------------------------- tick ---
func _process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var inside := museum.contains(p, 0.3)
	museum.set_roof_visible(not inside and not build.active)
	var in_lab := absf(p.x - LAB.x) < 5.0 and absf(p.z - LAB.z) < 4.5
	if (inside or in_lab) and not _was_inside and Settings.get_v("auto_deposit"):
		var n := GameState.deposit_backpack()
		if n > 0:
			Events.say("Backpack unloaded into storage (%d items)." % n, UIKit.GOOD)
			Audio.sfx("pickup", 0.8)
	_was_inside = inside or in_lab
	if GameState.phase == GameState.Phase.OPEN:
		_set_sun(day_cycle.clock)
	_obj_t -= delta
	if _obj_t <= 0.0:
		_obj_t = 1.0
		update_objective()
	if shopkeeper:
		var pd := player.global_position.distance_to(shopkeeper.global_position)
		shopkeeper.anim = "wave" if pd > 3.0 and pd < 9.0 else "idle"
		var d := player.global_position - shopkeeper.global_position
		shopkeeper.rotation.y = lerp_angle(shopkeeper.rotation.y, atan2(-d.x, -d.z), 0.05)


# -------------------------------------------------------------- save/load ---
## Everything live in the world, so a save comes back EXACTLY as it was.
func snapshot() -> Dictionary:
	var pp := player.global_position
	var s := {"v": 1, "phase": GameState.phase, "ledger": GameState.ledger.duplicate(true),
		"player": {"pos": [pp.x, pp.y, pp.z], "yaw": player.cam_yaw, "pitch": player.cam_pitch},
		"nodes": beach.save_nodes()}
	var mess: Array = []
	for m in museum.mess:
		var mn: Node3D = m["node"]
		if is_instance_valid(mn):
			mess.append({"kind": m["kind"], "pos": [mn.position.x, mn.position.z], "rot": mn.rotation.y})
	s["mess"] = mess
	for o in museum.all_objects():
		o.data["fill"] = o.fill
	day_cycle._prune()
	var st: Array = []
	for sn in day_cycle.staff_nodes:
		st.append(sn.save_data(day_cycle.guests) if is_instance_valid(sn) else {})
	s["staff"] = st
	s["day"] = day_cycle.snapshot()
	if traffic:
		s["traffic"] = traffic.save_data()
	if player.ragdolled:
		s["player"]["ragdoll"] = Ragdoll.save_state(player._rd)
		s["player"]["rag_t"] = player._rag_t
	return s


func restore_snapshot(s: Dictionary) -> void:
	if s.is_empty():
		return
	var pl: Dictionary = s.get("player", {})
	if pl.has("pos"):
		player.global_position = Vector3(float(pl["pos"][0]), float(pl["pos"][1]), float(pl["pos"][2]))
		player.velocity = Vector3.ZERO
	player.cam_yaw = float(pl.get("yaw", player.cam_yaw))
	player.cam_pitch = float(pl.get("pitch", player.cam_pitch))
	if s.has("nodes"):
		beach.restore_nodes(s["nodes"])
	for m in museum.mess.duplicate():
		if is_instance_valid(m["node"]):
			(m["node"] as Node).free()
	museum.mess.clear()
	for m in s.get("mess", []):
		museum.add_mess(String(m["kind"]), Vector3(float(m["pos"][0]), 0, float(m["pos"][1])))
		if not museum.mess.is_empty():
			var mn: Node3D = museum.mess.back()["node"]
			mn.position = Vector3(float(m["pos"][0]), 0.03, float(m["pos"][1]))
			mn.rotation.y = float(m.get("rot", 0.0))
	for o in museum.all_objects():
		o.fill = int(o.data.get("fill", 0))
	day_cycle.spawn_staff()
	if traffic:
		traffic.clear_vehicles()
	if s.has("ledger"):
		GameState.ledger = s["ledger"]
	var phase := int(s.get("phase", GameState.Phase.PREP))
	day_cycle.restore(s.get("day", {}), phase)
	var st: Array = s.get("staff", [])
	for i in range(mini(st.size(), day_cycle.staff_nodes.size())):
		if st[i] is Dictionary and (st[i] as Dictionary).has("pos"):
			day_cycle.staff_nodes[i].load_data(st[i], day_cycle.guests)
		elif st[i] is Array and (st[i] as Array).size() == 2:
			day_cycle.staff_nodes[i].global_position = Vector3(float(st[i][0]), 0, float(st[i][1]))
	if traffic and s.has("traffic"):
		traffic.restore_vehicles(s["traffic"])
	if pl.has("ragdoll"):
		player.knockback(Vector3.ZERO)
		Ragdoll.load_state(player._rd, pl["ragdoll"])
		player._rag_t = float(pl.get("rag_t", 0.0))
	if phase == GameState.Phase.OPEN:
		_set_sun(day_cycle.clock)
	elif phase != GameState.Phase.PREP:
		_set_sun(DayCycle.CLOSE_H)
	else:
		_set_sun(9.0)
	update_objective()
	GameState.changed.emit()


func new_day() -> void:
	beach.spawn_nodes()
	day_cycle.spawn_staff()
	Mail.generate_day()
	if Mail.unread() > 0 and GameState.has_office():
		Events.say("You have %d new J-Mail(s) - check the office computer in the Prep Lab." % Mail.unread(), UIKit.GOLD)
	_set_sun(9.0)
	story_check()
	update_objective()


func _on_state_changed() -> void:
	pass

# ------------------------------------------------------------------ story ---
func _intro() -> void:
	GameState.flags["intro"] = true
	Events.dialog_requested.emit([
		{"name": "Ammonite Bay", "text": "You spent your last dime on a boarded-up shack by the sea. Zero money. One rusty shovel. A whole coastline full of secrets."},
		{"name": "Pearl (Equipment Shop)", "text": "Welcome to the bay, dreamer! Dig up gems and ores on the beach, then bring them across the street - I'll buy them for cash."},
		{"name": "Pearl (Equipment Shop)", "text": "Fossils are worth more on display than in my till. Clean them at the Prep Lab next to the museum, mount them, then flip your sign to OPEN."},
		{"name": "Tip", "text": "Time is paused until you open the doors. %s interacts, %s opens your backpack, hold %s to dig. Press %s for the Upgrade Tree (earn points by opening the museum), %s for Build Mode, %s for the Guide." % [Settings.prompt("interact"), Settings.prompt("inventory"), Settings.prompt("use_item"), Settings.prompt("skill_tree"), Settings.prompt("build_mode"), Settings.prompt("field_guide")]},
	])


func on_apex_found() -> void:
	if int(GameState.flags.get("act", 1)) >= 2:
		return
	GameState.flags["act"] = 2
	Events.story_beat.emit("act2")
	Events.dialog_requested.emit([
		{"name": "Act 2: Beneath the Strata", "text": "Your shovel hits something HUGE. The bone fragment is bigger than your arm - and nothing in the Field Guide matches it."},
		{"name": "You", "text": "An apex marine reptile... undiscovered. If I can find every piece, this museum could put Ammonite Bay on the map."},
		{"name": "Goal", "text": "Use the Fossil Detector in the Sea Caves to find all 8 bones of the mystery reptile, then assemble them on a Mega-Skeleton Podium."},
	])


func story_check() -> void:
	var act := int(GameState.flags.get("act", 1))
	if act == 2:
		var pieces := GameState.owned_pieces("apex").size()
		for it in GameState.encased_items():
			if String(it["f"]).begins_with("apex"):
				pieces += 1
		if GameState.half_stars >= 5 or pieces >= 4:
			GameState.flags["act"] = 3
			Events.story_beat.emit("act3")
			Events.dialog_requested.emit([
				{"name": "Act 3: Saving the Cove", "text": "A sleek letter is pinned to your door: 'NOTICE OF INTENT - Grimsby Extraction Co. will acquire Ammonite Bay for strip-mining.'"},
				{"name": "Mr. Grimsby (letter)", "text": "Your little sandcastle of a museum is charming. Unprotected land, however, is merely inventory. - G."},
				{"name": "Pearl", "text": "The Heritage Council can protect the bay - but only for a 5-star accredited museum with a complete skeleton of a new species. And watch out: Grimsby's spies will sneak in to sabotage exhibits!"},
				{"name": "Goal", "text": "Reach 5 stars and complete the Cove Tyrant skeleton. Shove spies out or hire Security."},
			])
	_check_win()


func _check_win() -> void:
	if GameState.flags.get("won", false):
		return
	if GameState.half_stars >= 10 and museum and museum.apex_complete():
		GameState.flags["won"] = true
		Audio.sfx("fanfare")
		Events.dialog_requested.emit([
			{"name": "The Heritage Council", "text": "Tide & Trove is hereby accredited as a FIVE-STAR museum, home to the type specimen of Pelagotyrannus covensis."},
			{"name": "The Heritage Council", "text": "Ammonite Bay is granted permanent historical protection. Grimsby Extraction Co.'s claim is void."},
			{"name": "Pearl", "text": "You did it, curator. From one rusty shovel to saving the whole cove. Keep digging - the bay still has secrets!"},
		])
		Events.game_won.emit()


func _on_half_star(h: int) -> void:
	Audio.sfx("star_up")
	if is_instance_valid(player):
		FX.burst(self, player.global_position + Vector3(0, 1.4, -1.2), "sparkle")
	Events.say("Museum leveled up to %s! New upgrades unlocked." % GameState.star_text(h), UIKit.GOLD)


func _on_discovery(sp: String) -> void:
	Events.say("NEW SPECIES: %s! Display it and open the museum - when visitors see it you earn Upgrade Points." % DB.SPECIES[sp]["name"], UIKit.GOLD)


func on_field_trip_done() -> void:
	var opts: Array = []
	for o in museum.cases():
		var f: Dictionary = o.fossil_entry()
		if not f.is_empty():
			opts.append(GameState.species_of(f["f"]))
	if opts.is_empty():
		return
	var sp: String = opts[randi() % opts.size()]
	var sd: Dictionary = DB.SPECIES[sp]
	var q := {}
	if randf() < 0.5:
		q = {"q": "Field trip trivia! In which era did the %s live?" % sd["name"], "options": DB.ERAS.duplicate(), "answer": sd["era"]}
	else:
		var opts2: Array = [sd["diet"]]
		for dd in DB.DIETS:
			if opts2.size() < 4 and dd != sd["diet"]:
				opts2.append(dd)
		opts2.shuffle()
		q = {"q": "Field trip trivia! What did the %s eat?" % sd["name"], "options": opts2, "answer": sd["diet"]}
	Events.radio("Field trip trivia is ready!", "vip", Vector3.ZERO)
	Events.open_panel.emit("trivia", q)

# -------------------------------------------------------------- objective ---
func update_objective() -> void:
	var t := ""
	var st := GameState.stats
	var has_display := false
	for o in museum.cases():
		if not o.fossil_entry().is_empty():
			has_display = true
	if int(st["digs"]) == 0:
		t = "Walk to the beach (south), hold your shovel (slot 1) and HOLD %s on a sand patch to dig" % Settings.prompt("use_item")
	elif GameState.sellable_count() > 0 and GameState.money < 40 and int(GameState.stats["earned"]) == 0:
		t = "Sell your gems & ores at the Equipment Shop across the street"
	elif GameState.encased_items().size() > 0 and int(st["cleaned"]) == 0:
		t = "Clean your encased fossil at the Prep Lab workbench (east of the museum)"
	elif int(st["cleaned"]) > 0 and not has_display:
		t = "Mount a cleaned fossil in the Display Case inside the museum"
	elif GameState.day == 1 and GameState.phase == GameState.Phase.PREP:
		t = "Flip the sign by the museum door to OPEN - opening earns Upgrade Points"
	elif GameState.unclaimed_count() > 0 and GameState.phase == GameState.Phase.PREP:
		t = "Display your new species and open the museum: visitors seeing it earns Upgrade Points"
	else:
		var act := int(GameState.flags.get("act", 1))
		if GameState.flags.get("won", false):
			t = "Ammonite Bay is protected! Keep growing your museum."
		elif act == 1:
			t = "Reach %d star for the Ammonite Cliffs permit, then %d stars for the Sea Caves (%s Upgrade Tree)" % [int(DB.SKILLS["zone_cliffs"]["tier"]), int(DB.SKILLS["zone_caves"]["tier"]), Settings.prompt("skill_tree")]
		elif act == 2:
			t = "Find all 8 Cove Tyrant bones in the Sea Caves (%d/8 cleaned)" % GameState.owned_pieces("apex").size()
		else:
			t = "Reach 5 stars (%s) and complete the Cove Tyrant skeleton" % GameState.star_text()
	Events.objective_changed.emit(t)
