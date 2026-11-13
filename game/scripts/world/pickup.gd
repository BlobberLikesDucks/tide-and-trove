class_name Pickup
extends Node3D
## An item lying in the world (a dropped tool, gem, fossil...). Look at it and
## press Interact to put it back in your hotbar (or backpack when the hotbar is full).

var item: Dictionary
var model: Node3D


static func spawn(parent: Node, it: Dictionary, pos: Vector3) -> Pickup:
	var p := Pickup.new()
	p.item = it
	parent.add_child(p)
	p.global_position = pos
	p._build()
	return p


static func model_for(it: Dictionary) -> String:
	match String(it.get("t", "")):
		"tool":
			return {"shovel": "shovel", "pick": "pickaxe", "detector": "detector"}.get(String(it["kind"]), "shovel")
		"gem":
			return DB.GEMS[it["id"]]["model"] if DB.GEMS.has(it["id"]) else "gem"
		"geode":
			return "geode"
		"encased":
			return "fossil_rock"
		"trash":
			return "trash"
	return "gem"


func _build() -> void:
	model = Art.model(model_for(item))
	Art.strip_collision(model)
	add_child(model)
	if item.get("t", "") == "tool":
		# tools lie flat on the ground (their models hang down from the grip)
		model.rotation = Vector3(PI * 0.5, randf() * TAU, 0)
		model.position.y = 0.05
		Art.tint(model, "Blade", GameState.tool_def(String(item["kind"])).get("color", Color("b8c0c8")))
	elif item.get("t", "") == "gem" and DB.GEMS.has(item["id"]):
		Art.tint(model, "Gem" if model_for(item) == "gem" else "Fleck", DB.GEMS[item["id"]]["color"], 0.6)
	var it := Interactable.attach(self, "Pick up", _take)
	it.text_fn = func() -> String: return "Pick up %s" % GameState.item_name(item)
	it.prio = 2
	add_to_group("pickups")


func _take() -> void:
	if not GameState.hotbar_add(item):
		if item.get("t", "") == "trash" or not GameState.add_backpack(item):
			Events.say("No free hotbar slot%s." % ("" if item.get("t", "") == "trash" else " or backpack space"), UIKit.CORAL)
			Audio.sfx("error")
			return
	Audio.sfx("pickup")
	queue_free()


## Removes dropped copies of a tool (the gear rack re-issued it).
static func clear_tool(tree: SceneTree, kind: String) -> void:
	for p in tree.get_nodes_in_group("pickups"):
		if p is Pickup and p.item.get("t", "") == "tool" and p.item.get("kind", "") == kind:
			p.queue_free()
