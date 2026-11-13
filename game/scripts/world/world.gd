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
var _obj_t := 0.0
var _was_inside := false
var shopkeeper: CharVisual


func _ready() -> void:
	instance = self
	Art.prepare(self)  # cel-shade + collision-normalise every editor-placed model
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
	var args := OS.get_cmdline_user_args()
	if args.has("--autotest") or args.has("--shots"):
		add_child(Autotest.new())

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


func new_day() -> void:
	beach.spawn_nodes()
	day_cycle.spawn_staff()
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
		{"name": "Tip", "text": "Time is paused until you open the doors. Take it slow. Press %s for the Upgrade Tree, %s for Build Mode, %s for the Guide (how to play + Field Guide)." % [Settings.prompt("skill_tree"), Settings.prompt("build_mode"), Settings.prompt("field_guide")]},
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
	Events.say("NEW SPECIES: %s! Claim research points at the Curator's Desk." % DB.SPECIES[sp]["name"], UIKit.GOLD)


func on_field_trip_done() -> void:
	var opts: Array = []
	for o in museum.objects_of("display_case"):
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
	for o in museum.objects_of("display_case"):
		if not o.fossil_entry().is_empty():
			has_display = true
	if int(st["digs"]) == 0:
		t = "Walk to the beach (south), hold your shovel (slot 1) and dig a sand patch with %s" % Settings.prompt("use_item")
	elif GameState.sellable_count() > 0 and GameState.money < 40 and int(GameState.stats["earned"]) == 0:
		t = "Sell your gems & ores at the Equipment Shop across the street"
	elif GameState.encased_items().size() > 0 and int(st["cleaned"]) == 0:
		t = "Clean your encased fossil at the Prep Lab workbench (east of the museum)"
	elif int(st["cleaned"]) > 0 and not has_display:
		t = "Mount a cleaned fossil in the Display Case inside the museum"
	elif GameState.unclaimed_count() > 0:
		t = "Claim your discovery points at the Curator's Desk in the Prep Lab"
	elif GameState.day == 1 and GameState.phase == GameState.Phase.PREP:
		t = "Flip the sign by the museum door to OPEN"
	else:
		var act := int(GameState.flags.get("act", 1))
		if GameState.flags.get("won", false):
			t = "Ammonite Bay is protected! Keep growing your museum."
		elif act == 1:
			t = "Buy the Ammonite Cliffs permit, then reach 1 star for the Sea Caves (%s Upgrade Tree)" % Settings.prompt("skill_tree")
		elif act == 2:
			t = "Find all 8 Cove Tyrant bones in the Sea Caves (%d/8 cleaned)" % GameState.owned_pieces("apex").size()
		else:
			t = "Reach 5 stars (%s) and complete the Cove Tyrant skeleton" % GameState.star_text()
	Events.objective_changed.emit(t)
