class_name DigNode
extends Node3D
## A dig spot (sand patch, dirt mound, rock...). Interact -> quick dig
## animation -> RNG drop table pops out gems, ores or rock-encased fossils.

var kind := "sand"
var zone := "shore"
var hidden := false
var depleted := false
var visual: Node3D
var inter: Interactable
var body: StaticBody3D
var _spark: Label3D


func setup(p_kind: String, p_zone: String, p_hidden: bool, rng: RandomNumberGenerator) -> void:
	kind = p_kind
	zone = p_zone
	hidden = p_hidden
	var def: Dictionary = DB.NODE_TYPES[kind]
	visual = Art.model(def["model"])
	visual.rotation.y = rng.randf() * TAU
	var s := rng.randf_range(0.85, 1.15)
	visual.scale = Vector3.ONE * s
	add_child(visual)
	if def["tool"] == "pick":
		body = Art.box_collider(self, Vector3(1.3, 1.2, 1.3) * s, Vector3(0, 0.6 * s, 0))
	inter = Interactable.attach(self, "Dig", _on_interact, 1.5, 2.0)
	inter.text_fn = _prompt
	inter.prio = 1
	if hidden:
		visual.visible = false
		inter.enabled = false


func _prompt() -> String:
	var def: Dictionary = DB.NODE_TYPES[kind]
	var err := requirement_error()
	if err != "":
		return "%s  (%s)" % [def["name"], err]
	return "%s %s" % ["Dig" if def["tool"] == "shovel" else "Break", def["name"]]  # shown by the player with the Use key


func requirement_error() -> String:
	var def: Dictionary = DB.NODE_TYPES[kind]
	var tier := int(GameState.tools.get(def["tool"], 0))
	if tier < int(def["tier"]):
		if def["tool"] == "pick":
			var names := {1: "a Stone Pick", 2: "a Steel Pickaxe", 3: "a Diamond Pickaxe"}
			return "needs %s" % names[int(def["tier"])]
		return "needs a better shovel"
	return ""


func _on_interact(_player: Node) -> void:
	## Digging is done with the held tool (Use / LMB), not Interact.
	if depleted or hidden:
		return
	var need: String = "shovel" if DB.NODE_TYPES[kind]["tool"] == "shovel" else "pick"
	Events.say("Hold your %s in the hotbar and press %s to dig." % [GameState.TOOL_NAMES[need], Settings.prompt("use_item")], Color.WHITE)


func reveal() -> void:
	if not hidden:
		return
	hidden = false
	visual.visible = true
	inter.enabled = true
	visual.scale = Vector3.ONE * 0.05
	create_tween().tween_property(visual, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spark = Art.label3d("✦ FOUND ✦", 64, UIKit.GOLD)
	_spark.position.y = 1.4
	add_child(_spark)
	var tw := create_tween()
	tw.tween_property(_spark, "position:y", 2.6, 1.6)
	tw.parallel().tween_property(_spark, "modulate:a", 0.0, 1.6)
	tw.tween_callback(_spark.queue_free)
	Audio.sfx("star_up", 1.3, -4.0)
	Events.say("The detector found something buried here!", UIKit.GOLD)


func roll_entry(rng: RandomNumberGenerator) -> String:
	var table: Array = DB.DROPS[zone].get(kind, DB.DROPS[zone].values()[0])
	var total := 0
	for e in table:
		total += int(e[0])
	var r := rng.randi_range(1, total)
	for e in table:
		r -= int(e[0])
		if r <= 0:
			return e[1]
	return table[0][1]


func _make_item(entry: String, rng: RandomNumberGenerator) -> Dictionary:
	var parts := entry.split(":")
	match parts[0]:
		"gem":
			return {"t": "gem", "id": parts[1]}
		"geode":
			return {"t": "geode"}
		"fossil":
			return {"t": "encased", "f": parts[1], "era": DB.SPECIES[parts[1]]["era"]}
		"piece":
			var sp := parts[1]
			var pieces: Array = DB.SPECIES[sp]["pieces"]
			var pick: String = pieces[rng.randi() % pieces.size()]
			if rng.randf() < 0.7:
				var missing: Array = []
				var owned := GameState.owned_pieces(sp)
				var pending := {}
				for it in GameState.encased_items():
					pending[it["f"]] = true
				for p in pieces:
					if not owned.has(p) and not pending.has("%s:%s" % [sp, p]):
						missing.append(p)
				if not missing.is_empty():
					pick = missing[rng.randi() % missing.size()]
			return {"t": "encased", "f": "%s:%s" % [sp, pick], "era": DB.SPECIES[sp]["era"]}
	return {"t": "gem", "id": "quartz"}


func harvest(player: Player) -> void:
	if depleted:
		return
	depleted = true
	inter.enabled = false
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var def: Dictionary = DB.NODE_TYPES[kind]
	var n := rng.randi_range(int(def["drops"][0]), int(def["drops"][1]))
	GameState.stats["digs"] = int(GameState.stats["digs"]) + 1
	var lost := 0
	for i in range(n):
		var it := _make_item(roll_entry(rng), rng)
		if GameState.add_backpack(it):
			_pop(it, player, i)
			if it["t"] == "encased" and String(it["f"]).begins_with("apex"):
				World.instance.on_apex_found()
		else:
			lost += 1
	if lost > 0:
		Events.say("Backpack full - %d find(s) left behind!" % lost, UIKit.CORAL)
	FX.burst(get_parent(), global_position + Vector3(0, 0.25, 0), "dust", 1.4)
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3(1.2, 0.1, 1.2), 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(queue_free)


func _pop(it: Dictionary, player: Player, i: int) -> void:
	var mid := ""
	var col := Color.WHITE
	match String(it["t"]):
		"gem":
			mid = DB.GEMS[it["id"]]["model"]
			col = DB.GEMS[it["id"]]["color"]
		"geode":
			mid = "geode"
		_:
			mid = "fossil_rock"
	var m := Art.model(mid)
	if it["t"] == "gem":
		Art.tint(m, "Gem" if mid == "gem" else "Fleck", col, 0.6)
	get_parent().add_child(m)
	m.global_position = global_position + Vector3(0, 0.6, 0)
	if it["t"] == "gem":
		FX.burst(get_parent(), m.global_position, "glint")
	m.scale = Vector3.ONE * 1.6
	var start := m.global_position
	var up := start + Vector3(randf_range(-0.8, 0.8), 1.8, randf_range(-0.8, 0.8))
	var tw := m.create_tween()
	tw.tween_interval(i * 0.15)
	tw.tween_property(m, "global_position", up, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var follow := func(t: float) -> void:
		if is_instance_valid(player):
			m.global_position = up.lerp(player.global_position + Vector3(0, 1.2, 0), t)
	tw.tween_method(follow, 0.0, 1.0, 0.3)
	var done := func() -> void:
		Audio.sfx("pickup", 1.0 + i * 0.1)
		m.queue_free()
	tw.tween_callback(done)
	var nm := GameState.item_name(it)
	var extra := ""
	if it["t"] == "gem":
		extra = "  (%s)" % UIKit.money_text(GameState.item_value(it))
	Events.say("+ " + nm + extra, Color("ffe9a8") if it["t"] == "encased" else Color.WHITE)
