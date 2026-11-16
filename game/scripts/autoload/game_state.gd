extends Node
## All persistent run state plus the economy rules that operate on it.
## Serialised wholesale by SaveManager.

signal changed
signal backpack_changed

var DEBT_LIMIT: int:
	get: return GameConfig.get_cfg().debt_limit
var DEBT_WARN: int:
	get: return GameConfig.get_cfg().debt_warn

enum Phase { PREP, OPEN, REVIEWS, LEDGER }

var slot := -1
var day := 1
var phase: int = Phase.PREP
var money := 0
var up := 0
var half_stars := 0
var quality := 0.0
var museum_level := 0
var backpack: Array = []
var storage: Array = []
var collection: Array = []
var next_uid := 1
var tools := {"shovel": 1, "pick": 0, "detector": 0, "lab": 1}
var skills := {}
var placed: Array = []
var staff: Array = []
var discovered := {}
var flags := {}
var loans: Array = []  # unused since loans were removed; kept so old saves load
var plushies := 0
## J-Mail inbox: [{"id", "kind", "from", "subject", "body", "day", "read", "done", ...}]
var emails: Array = []
## Scheduled things from emails: [{"what": "school_trip", "day": n, ...}]
var events: Array = []
var next_mail := 1
var pit_stock := 0
var stats := {"visitors": 0, "earned": 0, "digs": 0, "cleaned": 0, "best_day": 0}
var playtime := 0.0
var last_reviews: Array = []
var ledger := {}
var detector_on := false
## Hotbar: fixed-size row of item slots ({} = empty). Tools, finds, trash and
## serving cups live here; the selected slot is what you hold in your hand.
var hotbar: Array = []
var hotbar_sel := 0
const VITAL_TOOLS := ["shovel", "pick", "detector"]
const TOOL_NAMES := {"shovel": "Shovel", "pick": "Pickaxe", "detector": "Fossil Detector"}
## Live museum pillars (0..100) - recomputed by the Museum node.
var pillars := {"fun": 0.0, "decor": 0.0, "clean": 100.0, "fun_points": 0.0, "decor_points": 0.0, "accurate": 0}


func _ready() -> void:
	reset()


func reset() -> void:
	day = 1
	phase = Phase.PREP
	money = 0
	up = 0
	half_stars = 0
	quality = 0.0
	museum_level = 0
	backpack = []
	storage = []
	collection = []
	next_uid = 1
	tools = {"shovel": 1, "pick": 0, "detector": 0, "lab": 1}
	skills = {}
	placed = [
		{"type": "display_case", "cell": [1, 2], "rot": 0, "data": {}},
		{"type": "trash_bin", "cell": [4, 0], "rot": 0, "data": {}},
	]
	staff = []
	discovered = {}
	flags = {"act": 1, "intro": false, "tut": 0}
	loans = []
	emails = []
	events = []
	next_mail = 1
	plushies = 0
	pit_stock = 0
	stats = {"visitors": 0, "earned": 0, "digs": 0, "cleaned": 0, "best_day": 0}
	playtime = 0.0
	last_reviews = []
	detector_on = false
	hotbar = []
	hotbar_sel = 0
	_fit_hotbar()
	hotbar[0] = {"t": "tool", "kind": "shovel"}
	reset_ledger()


func reset_ledger() -> void:
	ledger = {"income": {}, "expense": {}}

# ------------------------------------------------------------------ money ---
func earn(amount: int, category: String) -> void:
	if amount == 0:
		return
	money += amount
	ledger["income"][category] = int(ledger["income"].get(category, 0)) + amount
	stats["earned"] = int(stats["earned"]) + amount
	changed.emit()
	Events.money_delta.emit(amount)


func charge(amount: int, category: String) -> void:
	money -= amount
	ledger["expense"][category] = int(ledger["expense"].get(category, 0)) + amount
	changed.emit()
	if amount != 0:
		Events.money_delta.emit(-amount)


func try_spend(amount: int, category: String) -> bool:
	if money < amount:
		return false
	charge(amount, category)
	return true


func debt_total() -> int:
	return maxi(0, -money)

# --------------------------------------------------------------- progress ---
func stars() -> float:
	return half_stars * 0.5


func star_text(h: int = -1) -> String:
	if h < 0:
		h = half_stars
	var s := ""
	for i in range(5):
		var v := h - i * 2
		s += "★" if v >= 2 else ("½" if v == 1 else "☆")
	return s


func has_skill(id: String) -> bool:
	return skills.has(id)


func star_count() -> int:
	return half_stars / 2


func skill_state(id: String) -> String:
	if has_skill(id):
		return "owned"
	var s: Dictionary = DB.SKILLS[id]
	for r in s["req"]:
		if not has_skill(r):
			return "locked"
	if star_count() < int(s.get("tier", 0)):
		return "stars"
	return "available"


func skill_missing(id: String) -> Array:
	var s: Dictionary = DB.SKILLS[id]
	var need: Array = []
	for r in s["req"]:
		if not has_skill(r):
			need.append(DB.SKILLS[r]["name"])
	if star_count() < int(s.get("tier", 0)):
		need.append("%d-star museum" % int(s["tier"]))
	return need


func can_afford_skill(id: String) -> bool:
	var s: Dictionary = DB.SKILLS[id]
	return up >= int(s["cost"]) and money >= int(s.get("cash", 0))


func buy_skill(id: String) -> bool:
	if skill_state(id) != "available" or not can_afford_skill(id):
		return false
	var s: Dictionary = DB.SKILLS[id]
	up -= int(s["cost"])
	if int(s.get("cash", 0)) > 0:
		charge(int(s["cash"]), "Upgrades")
	skills[id] = true
	if id.begins_with("hotbar_"):
		_fit_hotbar()
	if id.begins_with("expand_"):
		Events.expansion_bought.emit(int(id.substr(7)))
	changed.emit()
	backpack_changed.emit()
	Events.museum_changed.emit()
	return true


func count_skills(prefix: String) -> int:
	var n := 0
	for k in skills.keys():
		if String(k).begins_with(prefix):
			n += 1
	return n


func backpack_capacity() -> int:
	var c := GameConfig.get_cfg()
	return c.backpack_base_slots + c.backpack_slots_per_upgrade * count_skills("backpack_")


func speed_mult() -> float:
	return 1.0 + GameConfig.get_cfg().speed_bonus_per_upgrade * count_skills("speed_")


## Hold-to-dig speed: the "Strong Arms" upgrades (one per star tier).
func dig_speed_mult() -> float:
	return 1.0 + 0.12 * count_skills("dig_")


## Share of the price you get back when selling a build in Build Mode.
func refund_rate() -> float:
	return 0.25 + 0.15 * count_skills("refund_")


func fossil_bonus() -> float:
	return 0.15 * mini(2, count_skills("lucky_"))


func build_unlocked(id: String) -> bool:
	var lic := String(DB.BUILD[id].get("lic", ""))
	return lic == "" or has_skill(lic)


func has_office() -> bool:
	return museum_level >= DB.OFFICE_LEVEL


func ticket_base() -> int:
	var b := 2
	var add := [2, 3, 4, 6, 8]
	for i in range(5):
		if has_skill("ticket_%d" % (i + 1)):
			b += add[i]
	return b


func ticket_price() -> int:
	var p := float(ticket_base()) + float(pillars["fun_points"]) * 0.05 + float(pillars["accurate"]) * 0.5
	p *= 0.75 + 0.25 * (quality / 100.0) + 0.12 * stars()
	return maxi(1, int(round(p)))


func reputation() -> float:
	## 0..1 blend of pillars + quality used for spawn rates.
	var avgp := (float(pillars["fun"]) + float(pillars["decor"]) + float(pillars["clean"])) / 300.0
	return clampf(0.25 * quality / 100.0 + 0.75 * avgp, 0.05, 1.0)


func detector_radius() -> float:
	var t := int(tools["detector"])
	if t <= 0:
		return 0.0
	var r: float = DB.TOOLS["detector_%d" % t]["radius"]
	if has_skill("detector_range"):
		r *= 1.4
	return r


func tool_def(kind: String) -> Dictionary:
	var t := int(tools.get(kind, 0))
	if t <= 0:
		return {}
	return DB.TOOLS.get("%s_%d" % [kind, t], {})


func staff_cap() -> int:
	return count_skills("staff_slot_")


func job_unlocked(t: String) -> bool:
	return has_skill(String(DB.STAFF[t].get("job", "")))


func staff_wage(d: Dictionary) -> int:
	return int(DB.STAFF[d["type"]]["wage"]) + int(d.get("bonus", 0))


func museum_size() -> Vector2i:
	return DB.MUSEUM_SIZES[museum_level]


func zone_unlocked(zone_id: String) -> bool:
	for z in DB.ZONES:
		if z["id"] == zone_id:
			return z["skill"] == "" or has_skill(z["skill"])
	return false

# -------------------------------------------------------------- inventory ---
func item_name(it: Dictionary) -> String:
	match String(it.get("t", "")):
		"gem":
			return DB.GEMS[it["id"]]["name"] if DB.GEMS.has(it["id"]) else "Gem"
		"tool":
			var td := tool_def(String(it["kind"]))
			return String(td.get("name", TOOL_NAMES.get(it["kind"], "Tool")))
		"trash":
			return "Trash"
		"serve":
			var bd: Dictionary = DB.BUILD.get(String(it.get("stand", "")), {})
			var what: String = bd.get("item", "snack")
			return ("%s (ready to serve)" % what.capitalize()) if it.get("full", false) else ("Empty %s" % {"held_cup": "cup", "held_bag": "popcorn bag", "held_dog": "bun"}.get(bd.get("serve", ""), "cup"))
		"geode":
			return "Sealed Geode"
		"encased":
			return String(DB.MATRIX.get(matrix_of(it), {"name": "Rock-Encased Find"})["name"])
	return "?"


func item_value(it: Dictionary) -> int:
	var v := 0
	match String(it.get("t", "")):
		"gem":
			v = int(DB.GEMS[it["id"]]["value"]) if DB.GEMS.has(it["id"]) else 0
		"geode":
			v = DB.GEODE_VALUE
	if has_skill("haggle"):
		v = int(round(v * 1.2))
	if has_skill("haggle_2"):
		v = int(round(v * 1.2))
	return v


## What rock a find is wrapped in (old saves stored only the era).
func matrix_of(it: Dictionary) -> String:
	if it.has("m"):
		return String(it["m"])
	var sp := species_of(String(it.get("f", "")))
	return String(DB.SPECIES.get(sp, {}).get("matrix", "sandstone"))


func backpack_full() -> bool:
	return backpack.size() >= backpack_capacity()


func add_backpack(it: Dictionary) -> bool:
	if backpack_full():
		return false
	backpack.append(it)
	backpack_changed.emit()
	changed.emit()
	return true


func deposit_backpack() -> int:
	var n := backpack.size()
	if n == 0:
		return 0
	storage.append_array(backpack)
	backpack.clear()
	backpack_changed.emit()
	changed.emit()
	return n


func sellable_count() -> int:
	var n := 0
	for it in backpack + storage + hotbar:
		if not it.is_empty() and (it["t"] == "gem" or it["t"] == "geode"):
			n += 1
	return n


func sell_all_gems() -> int:
	var total := 0
	for arr in [backpack, storage]:
		var keep: Array = []
		for it in arr:
			if it["t"] == "gem" or it["t"] == "geode":
				total += item_value(it)
			else:
				keep.append(it)
		arr.clear()
		arr.append_array(keep)
	for i in range(hotbar.size()):
		var h: Dictionary = hotbar[i]
		if not h.is_empty() and (h["t"] == "gem" or h["t"] == "geode"):
			total += item_value(h)
			hotbar[i] = {}
	if total > 0:
		earn(total, "Gem & ore sales")
	backpack_changed.emit()
	return total


func encased_items() -> Array:
	var out: Array = []
	for it in storage + backpack + hotbar:
		if it.get("t", "") == "encased":
			out.append(it)
	return out


func remove_item(it: Dictionary) -> void:
	var i := storage.find(it)
	if i >= 0:
		storage.remove_at(i)
	else:
		i = backpack.find(it)
		if i >= 0:
			backpack.remove_at(i)
		else:
			i = hotbar.find(it)
			if i >= 0:
				hotbar[i] = {}
	backpack_changed.emit()
	changed.emit()


func take_storage_gem() -> Dictionary:
	for i in range(storage.size()):
		if storage[i]["t"] == "gem":
			var it: Dictionary = storage[i]
			storage.remove_at(i)
			return it
	return {}


func take_storage_geode() -> bool:
	for i in range(storage.size()):
		if storage[i]["t"] == "geode":
			storage.remove_at(i)
			return true
	return false

# ----------------------------------------------------------------- hotbar ---
func hotbar_capacity() -> int:
	return GameConfig.get_cfg().hotbar_base_slots + count_skills("hotbar_")


func _fit_hotbar() -> void:
	var cap := hotbar_capacity()
	while hotbar.size() < cap:
		hotbar.append({})
	while hotbar.size() > cap and (hotbar[hotbar.size() - 1] as Dictionary).is_empty():
		hotbar.pop_back()
	hotbar_sel = clampi(hotbar_sel, 0, hotbar.size() - 1)


func held() -> Dictionary:
	if hotbar_sel < 0 or hotbar_sel >= hotbar.size():
		return {}
	return hotbar[hotbar_sel]


func held_tool() -> String:
	var h := held()
	return String(h.get("kind", "")) if h.get("t", "") == "tool" else ""


func select_slot(i: int) -> void:
	if hotbar.is_empty():
		return
	hotbar_sel = posmod(i, hotbar.size())
	detector_on = held_tool() == "detector" and int(tools.get("detector", 0)) > 0
	backpack_changed.emit()


func free_hotbar_slot() -> int:
	if held().is_empty():
		return hotbar_sel
	for i in range(hotbar.size()):
		if (hotbar[i] as Dictionary).is_empty():
			return i
	return -1


## Puts an item in the hotbar (selected slot if empty, else the first free one).
func hotbar_add(it: Dictionary, select := true) -> bool:
	var i := free_hotbar_slot()
	if i < 0:
		return false
	hotbar[i] = it
	if select:
		hotbar_sel = i
	select_slot(hotbar_sel)
	changed.emit()
	return true


func take_held() -> Dictionary:
	var h := held()
	if h.is_empty():
		return {}
	hotbar[hotbar_sel] = {}
	select_slot(hotbar_sel)
	changed.emit()
	return h


func is_vital(it: Dictionary) -> bool:
	return it.get("t", "") == "tool" and VITAL_TOOLS.has(String(it.get("kind", "")))


func has_tool_item(kind: String) -> bool:
	for arr in [hotbar, backpack, storage]:
		for it in arr:
			if not it.is_empty() and it.get("t", "") == "tool" and it.get("kind", "") == kind:
				return true
	return false


## Re-issue a tool you own (from the gear rack, or after buying one).
func issue_tool(kind: String) -> String:
	if int(tools.get(kind, 0)) <= 0:
		return "You don't own a %s yet." % TOOL_NAMES.get(kind, kind)
	if has_tool_item(kind):
		return "Your %s is already in your hotbar or bags." % TOOL_NAMES.get(kind, kind)
	var it := {"t": "tool", "kind": kind}
	if hotbar_add(it):
		return ""
	if add_backpack(it):
		return ""
	return "No free hotbar or backpack slot."


## Move one item between "hotbar", "backpack" and "storage" (index in the source list).
func move_item(src: String, index: int, dst: String) -> String:
	var from: Array = get(src)
	if index < 0 or index >= from.size():
		return "Nothing there."
	var it: Dictionary = from[index]
	if it.is_empty():
		return "That slot is empty."
	if dst != "hotbar" and (it["t"] == "trash" or it["t"] == "serve"):
		return "That only fits in your hands (hotbar)."
	match dst:
		"hotbar":
			var slot := -1
			for i in range(hotbar.size()):
				if (hotbar[i] as Dictionary).is_empty():
					slot = i
					break
			if slot < 0:
				return "Hotbar is full."
			hotbar[slot] = it
		"backpack":
			if backpack_full():
				return "Backpack is full."
			backpack.append(it)
		"storage":
			storage.append(it)
	if src == "hotbar":
		from[index] = {}
	else:
		from.remove_at(index)
	select_slot(hotbar_sel)
	changed.emit()
	return ""


# ---------------------------------------------------------------- fossils ---
static func species_of(fid: String) -> String:
	return fid.split(":")[0]


static func piece_of(fid: String) -> String:
	var parts := fid.split(":")
	return parts[1] if parts.size() > 1 else ""


func fossil_name(fid: String) -> String:
	var sp := species_of(fid)
	var d: Dictionary = DB.SPECIES[sp]
	var pc := piece_of(fid)
	if pc != "":
		return "%s %s" % [d["name"].split(" (")[0], DB.PIECE_NAMES[pc]]
	return d["name"]


## Which display case size a fossil fits (exactly one).
func fossil_case(fid: String) -> String:
	return String(DB.SPECIES[species_of(fid)].get("case", "small"))


func lab_grid(fid: String) -> Vector2i:
	var g: Vector2i = DB.LAB_GRID[fossil_case(fid)]
	var r := DB.RARITY_ORDER.find(fossil_rarity(fid))
	return g + Vector2i(r, r / 2)


func fossil_rarity(fid: String) -> String:
	return "rare" if piece_of(fid) != "" and species_of(fid) != "apex" else String(DB.SPECIES[species_of(fid)]["rarity"])


func add_cleaned(fid: String, pres: float) -> Dictionary:
	var entry := {"uid": next_uid, "f": fid, "pres": pres, "where": ""}
	next_uid += 1
	collection.append(entry)
	stats["cleaned"] = int(stats["cleaned"]) + 1
	var sp := species_of(fid)
	var is_new := not discovered.has(sp)
	if is_new:
		discovered[sp] = {"claimed": false, "pieces": {}}
	var pc := piece_of(fid)
	if pc != "":
		discovered[sp]["pieces"][pc] = true
	entry["new"] = is_new
	changed.emit()
	if is_new:
		Events.discovery.emit(sp)
	return entry


func unclaimed_count() -> int:
	var n := 0
	for sp in discovered.keys():
		if not discovered[sp]["claimed"]:
			n += 1
	return n


## Discovery rewards are earned by OPENING: the first day visitors see a new
## species on display it pays Upgrade Points (in the end-of-day reviews).
func mark_seen(sp: String) -> void:
	if discovered.has(sp) and not discovered[sp]["claimed"]:
		discovered[sp]["seen"] = true


func discovery_points(sp: String) -> int:
	var r: String = DB.SPECIES[sp]["rarity"]
	return {"common": 1, "uncommon": 1, "rare": 2, "epic": 3}.get(r, 1)


func claim(sp: String) -> int:
	if not discovered.has(sp) or discovered[sp]["claimed"]:
		return 0
	discovered[sp]["claimed"] = true
	var pts := discovery_points(sp)
	up += pts
	changed.emit()
	return pts


func free_fossils(species_filter: String = "") -> Array:
	var out: Array = []
	for e in collection:
		if e["where"] == "" and (species_filter == "" or species_of(e["f"]) == species_filter):
			out.append(e)
	return out


func find_uid(uid: int) -> Dictionary:
	for e in collection:
		if int(e["uid"]) == uid:
			return e
	return {}


func duplicate_fossils() -> Array:
	## Unplaced fossils whose exact id is already displayed or duplicated in storage.
	var seen := {}
	for e in collection:
		if e["where"] != "":
			seen[e["f"]] = true
	var out: Array = []
	var free_seen := {}
	for e in collection:
		if e["where"] != "":
			continue
		if seen.has(e["f"]) or free_seen.has(e["f"]):
			out.append(e)
		free_seen[e["f"]] = true
	return out


func owned_pieces(sp: String) -> Dictionary:
	if discovered.has(sp):
		return discovered[sp]["pieces"]
	return {}

# ----------------------------------------------------------- serialisation --
const SAVE_KEYS := ["day", "money", "up", "half_stars", "quality", "museum_level", "backpack", "storage", "collection", "next_uid",
	"tools", "skills", "placed", "staff", "discovered", "flags", "plushies", "pit_stock", "stats", "playtime", "last_reviews", "hotbar", "hotbar_sel",
	"emails", "events", "next_mail"]


## A save made in the middle of the game also carries a snapshot of the live
## world (where you stand, the clock, every visitor, litter, dig spots...).
## World._ready() puts it back after loading.
var pending_world := {}


func to_dict() -> Dictionary:
	var w := World.instance
	var snap := {}
	if w and is_instance_valid(w) and w.is_inside_tree():
		snap = w.snapshot()  # first: it writes live values (bin fill) into `placed`
	var d := {}
	for k in SAVE_KEYS:
		d[k] = get(k)
	d["saved_phase"] = phase
	if not snap.is_empty():
		d["world"] = snap
	return d


func take_pending_world() -> Dictionary:
	var s := pending_world
	pending_world = {}
	return s


func from_dict(d: Dictionary) -> void:
	reset()
	for k in SAVE_KEYS:
		if d.has(k):
			set(k, d[k])
	# JSON turns ints into floats; normalise the ones we index with.
	day = int(day)
	money = int(money)
	up = int(up)
	half_stars = int(half_stars)
	museum_level = int(museum_level)
	next_uid = int(next_uid)
	plushies = int(plushies)
	pit_stock = int(pit_stock)
	for k in tools.keys():
		tools[k] = int(tools[k])
	for p in placed:
		p["rot"] = int(p["rot"])
		p["cell"] = [int(p["cell"][0]), int(p["cell"][1])]
	for e in collection:
		e["uid"] = int(e["uid"])
	hotbar_sel = int(hotbar_sel)
	next_mail = int(next_mail)
	# amber used to be a gem; it is a fossil now. Finds now carry their matrix.
	for arr in [backpack, storage, hotbar]:
		for i in range(arr.size()):
			var it: Dictionary = arr[i]
			if it.get("t", "") == "gem" and it.get("id", "") == "amber":
				arr[i] = {"t": "encased", "f": "amber", "m": "amber"}
			elif it.get("t", "") == "serve":
				arr[i] = {}
			elif it.get("t", "") == "encased":
				if not DB.SPECIES.has(species_of(String(it.get("f", "")))):
					arr[i] = {}
				elif not it.has("m"):
					it["m"] = matrix_of(it)
	collection = collection.filter(func(e): return DB.SPECIES.has(species_of(String(e.get("f", "")))))
	for sp in discovered.keys().duplicate():
		if not DB.SPECIES.has(sp):
			discovered.erase(sp)
	if (d.get("skills", {}) as Dictionary).has("lic_podium"):
		skills["bp_case_medium"] = true
		skills["bp_case_big"] = true
		skills["bp_case_mega"] = true
	for k in skills.keys().duplicate():  # renamed / removed tree nodes
		if not DB.SKILLS.has(k):
			skills.erase(k)
	museum_level = clampi(museum_level, 0, DB.MUSEUM_SIZES.size() - 1)
	for i in range(1, museum_level + 1):  # old saves bought floors in Build Mode
		skills["expand_%d" % i] = true
	for p in placed:  # podiums became Mega Display Cases
		if p.get("type", "") == "mega_podium":
			p["type"] = "display_case_mega"
	placed = placed.filter(func(p): return DB.BUILD.has(String(p.get("type", ""))))
	backpack = backpack.filter(func(x): return not (x as Dictionary).is_empty())
	_fit_hotbar()
	if not has_tool_item("shovel"):
		issue_tool("shovel")
	pending_world = d.get("world", {})
	# Old saves had no world snapshot: a day saved while open is over - you wake
	# up on the next morning's prep phase with what you earned so far.
	if pending_world.is_empty() and int(d.get("saved_phase", Phase.PREP)) != Phase.PREP:
		day += 1
	phase = Phase.PREP
	reset_ledger()
	changed.emit()
