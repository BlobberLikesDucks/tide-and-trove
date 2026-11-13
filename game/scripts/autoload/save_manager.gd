extends Node
## 10 save slots as JSON in user://saves. "Continue" loads the newest one.

const SLOTS := 10
const DIR := "user://saves"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func slot_path(i: int) -> String:
	return "%s/slot_%d.json" % [DIR, i]


func read_slot(i: int) -> Dictionary:
	var p := slot_path(i)
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


func slot_meta(i: int) -> Dictionary:
	var d := read_slot(i)
	return d.get("meta", {})


func list_slots() -> Array:
	var out: Array = []
	for i in range(SLOTS):
		out.append(slot_meta(i))
	return out


func most_recent_slot() -> int:
	var best := -1
	var best_t := -1.0
	for i in range(SLOTS):
		var m := slot_meta(i)
		if m.is_empty():
			continue
		var t := float(m.get("saved_at", 0))
		if t > best_t:
			best_t = t
			best = i
	return best


func save(i: int = -1) -> bool:
	if i < 0:
		i = GameState.slot
	if i < 0:
		return false
	GameState.slot = i
	var data := {
		"version": 1,
		"meta": {
			"saved_at": Time.get_unix_time_from_system(),
			"stamp": Time.get_datetime_string_from_system(false, true),
			"day": GameState.day,
			"money": GameState.money,
			"half_stars": GameState.half_stars,
			"playtime": GameState.playtime,
			"act": GameState.flags.get("act", 1),
		},
		"state": GameState.to_dict(),
	}
	var f := FileAccess.open(slot_path(i), FileAccess.WRITE)
	if f == null:
		push_error("Could not write save slot %d" % i)
		return false
	f.store_string(JSON.stringify(data, "  "))
	return true


func load_slot(i: int) -> bool:
	var d := read_slot(i)
	if d.is_empty() or not d.has("state"):
		return false
	GameState.from_dict(d["state"])
	GameState.slot = i
	return true


func delete_slot(i: int) -> void:
	if FileAccess.file_exists(slot_path(i)):
		DirAccess.remove_absolute(slot_path(i))
