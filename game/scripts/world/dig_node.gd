class_name DigNode
extends Node3D
## A dig spot (sand patch, dirt mound, rock, or a rare BIG dune / boulder / bone
## bed). The player HOLDS Use with the right tool: progress fills while held and
## resets on release. Bigger spots take longer; better tools and the Strong Arms
## upgrades are faster. Untouched spots weather away after a while and the beach
## grows new ones. Drops come from tables built from the species list.

signal gone(node: DigNode)

var kind := "sand"
var zone := "shore"
var hidden := false
var depleted := false
var visual: Node3D
var inter: Interactable
var body: StaticBody3D
var size_k := 1.0
var life := 200.0
var _spark: Label3D
var _fading := false


func setup(p_kind: String, p_zone: String, p_hidden: bool, rng: RandomNumberGenerator, p_size: float = -1.0) -> void:
	kind = p_kind
	zone = p_zone
	hidden = p_hidden
	var def: Dictionary = DB.NODE_TYPES[kind]
	visual = Art.model(def["model"])
	visual.rotation.y = rng.randf() * TAU
	size_k = rng.randf_range(0.8, 1.25) if not is_big() else rng.randf_range(0.95, 1.15)
	if p_size > 0.0:
		size_k = p_size  # restored from a save
	visual.scale = Vector3.ONE * size_k
	add_child(visual)
	var lr: Array = def.get("life", [180.0, 260.0])
	life = rng.randf_range(float(lr[0]), float(lr[1]))
	if def["tool"] == "pick":
		var half := 1.3 if not is_big() else 2.4
		body = Art.box_collider(self, Vector3(half, 1.2 if not is_big() else 2.0, half) * size_k, Vector3(0, (0.6 if not is_big() else 1.0) * size_k, 0))
	inter = Interactable.attach(self, "Dig", _on_interact, 1.5 if not is_big() else 2.6, 2.0 if not is_big() else 3.0)
	inter.text_fn = _prompt
	inter.prio = 1
	if hidden:
		visual.visible = false
		inter.enabled = false
	else:
		visual.scale = Vector3.ONE * 0.05
		create_tween().tween_property(visual, "scale", Vector3.ONE * size_k, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_big() and not hidden:
		_spark = Art.label3d("RARE BIG FIND", 40, UIKit.GOLD)
		_spark.position.y = 2.6 * size_k
		_spark.visibility_range_end = 26.0
		add_child(_spark)


func is_big() -> bool:
	return bool(DB.NODE_TYPES[kind].get("big", false))


func _process(delta: float) -> void:
	if depleted or _fading or hidden:
		return
	var p := World.instance.player if World.instance else null
	if p and p.dig_node == self:
		return  # never weathers away while you are digging it
	life -= delta
	if life <= 0.0:
		weather_away()


## Untouched spots slowly disappear (the tide and wind cover them up).
func weather_away() -> void:
	if _fading or depleted:
		return
	_fading = true
	inter.enabled = false
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3(visual.scale.x * 1.1, 0.02, visual.scale.z * 1.1), 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_remove)


func _remove() -> void:
	gone.emit(self)
	queue_free()


## Seconds of holding Use needed with the player's current tool + upgrades.
func dig_time() -> float:
	var def: Dictionary = DB.NODE_TYPES[kind]
	var td := GameState.tool_def(String(def["tool"]))
	return float(def["time"]) * size_k / float(td.get("speed", 1.0)) / GameState.dig_speed_mult()


func _prompt() -> String:
	var def: Dictionary = DB.NODE_TYPES[kind]
	var err := requirement_error()
	if err != "":
		return "%s  (%s)" % [def["name"], err]
	return "%s %s" % ["Dig" if def["tool"] == "shovel" else "Break", def["name"]]


func requirement_error() -> String:
	var def: Dictionary = DB.NODE_TYPES[kind]
	var tier := int(GameState.tools.get(def["tool"], 0))
	if tier < int(def["tier"]):
		if def["tool"] == "pick":
			var names := {1: "a Stone Pick", 2: "a Steel Pickaxe", 3: "a Diamond Pickaxe"}
			return "needs %s" % names[int(def["tier"])]
		return "needs a %s" % ("Steel Shovel" if int(def["tier"]) == 2 else "Titanium Spade")
	return ""


func _on_interact(_player: Node) -> void:
	## Digging is done by HOLDING the held tool's Use button, not Interact.
	if depleted or hidden:
		return
	var need: String = "shovel" if DB.NODE_TYPES[kind]["tool"] == "shovel" else "pick"
	Events.say("Hold your %s in the hotbar and HOLD %s to dig." % [GameState.TOOL_NAMES[need], Settings.prompt("use_item")], Color.WHITE)


func reveal() -> void:
	if not hidden:
		return
	hidden = false
	visual.visible = true
	inter.enabled = true
	visual.scale = Vector3.ONE * 0.05
	create_tween().tween_property(visual, "scale", Vector3.ONE * size_k, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var spark := Art.label3d("FOUND!", 64, UIKit.GOLD)
	spark.position.y = 1.4
	add_child(spark)
	var tw := create_tween()
	tw.tween_property(spark, "position:y", 2.6, 1.6)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 1.6)
	tw.tween_callback(spark.queue_free)
	Audio.sfx("star_up", 1.3, -4.0)
	Events.say("The detector found something buried here!", UIKit.GOLD)


static func pick(table: Array, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for e in table:
		total += float(e[0])
	if total <= 0.0:
		return ""
	var r := rng.randf() * total
	for e in table:
		r -= float(e[0])
		if r <= 0.0:
			return e[1]
	return table[0][1]


func roll_entry(rng: RandomNumberGenerator) -> String:
	var def: Dictionary = DB.NODE_TYPES[kind]
	var fchance := float(def["fossil"])
	if not is_big():
		fchance = clampf(fchance + GameState.fossil_bonus(), 0.0, 0.95)
	if rng.randf() < fchance:
		var e := pick(DB.fossil_table(zone, kind), rng)
		if e != "":
			return e
	return pick(DB.ZONE_GEMS[zone], rng)


func _make_item(entry: String, rng: RandomNumberGenerator) -> Dictionary:
	var parts := entry.split(":")
	match parts[0]:
		"gem":
			return {"t": "gem", "id": parts[1]}
		"geode":
			return {"t": "geode"}
		"fossil":
			return {"t": "encased", "f": parts[1], "m": DB.SPECIES[parts[1]]["matrix"]}
		"piece":
			var sp := parts[1]
			var pieces: Array = DB.SPECIES[sp]["pieces"]
			var pick_pc: String = pieces[rng.randi() % pieces.size()]
			if rng.randf() < 0.7:
				var missing: Array = []
				var owned := GameState.owned_pieces(sp)
				var pending := {}
				for it in GameState.encased_items():
					pending[it["f"]] = true
				for pc in pieces:
					if not owned.has(pc) and not pending.has("%s:%s" % [sp, pc]):
						missing.append(pc)
				if not missing.is_empty():
					pick_pc = missing[rng.randi() % missing.size()]
			return {"t": "encased", "f": "%s:%s" % [sp, pick_pc], "m": DB.SPECIES[sp]["matrix"]}
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
	if is_big():
		Events.say("You cracked open a %s!" % def["name"], UIKit.GOLD)
		Audio.sfx("fanfare", 1.2, -6.0)
	FX.burst(get_parent(), global_position + Vector3(0, 0.25, 0), "dust", 1.4 if not is_big() else 2.6)
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3(size_k * 1.2, 0.1, size_k * 1.2), 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(_remove)


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
	var up := m.global_position + Vector3(randf_range(-0.8, 0.8), 1.8, randf_range(-0.8, 0.8))
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
