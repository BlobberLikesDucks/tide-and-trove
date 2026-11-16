class_name Autotest
extends Node
## Smoke test driven from the command line:
##   godot --path game -- --autotest            (headless logic run)
##   godot --path game -- --shots --out=DIR     (windowed, saves screenshots)
## Plays one full day: dig, sell, clean, mount, skills, build, open, reviews,
## ledger, next day, save + reload.

var w: World
var shots := false
var out_dir := "user://shots"
var failures: Array = []
## What visitors got up to during the first open day (sampled).
var _seen := {}
var _inside_t := {}
var _litter := 0
var _left_inside: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	w = World.instance
	var args := OS.get_cmdline_user_args()
	shots = args.has("--shots")
	for a in args:
		if String(a).begins_with("--out="):
			out_dir = String(a).substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Events.open_panel.connect(_on_panel)
	Events.dialog_requested.connect(_on_dialog)
	Events.game_over.connect(func(r: String) -> void: print("[T] GAME OVER: ", r))
	run()


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func check(cond: bool, what: String) -> void:
	print("[T] %s %s" % ["PASS" if cond else "FAIL", what])
	if not cond:
		failures.append(what)


func shot(n: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := "%s/%s.png" % [out_dir, n]
	img.save_png(p)
	print("[T] shot ", p)


func _on_dialog(_l: Array) -> void:
	call_deferred("_skip_dialog")


func _skip_dialog() -> void:
	w.ui.dialog_queue.clear()
	w.ui._next_line()


func _on_panel(n: String, data: Variant) -> void:
	match n:
		"reviews":
			if not _inside_t.is_empty() and not _seen.has("checked"):
				_seen["checked"] = true
				var tot := 0.0
				for v in _inside_t.values():
					tot += float(v)
				var avg := tot / _inside_t.size()
				print("[T] visitor states seen: ", _seen.keys(), " avg time inside %.1fs, litter dropped %d" % [avg, _litter])
				check(_seen.has(Guest.S.VIEW) and _seen.has(Guest.S.BROWSE), "visitors look at exhibits AND stroll around")
				check(_seen.has(Guest.S.BUY) or w.museum.all_objects().filter(func(o): return o.def.get("cat", "") == "Concessions").is_empty(), "visitors go to the snack stands")
				check(_litter > 0, "visitors drop litter (%d)" % _litter)
				check(avg > 25.0, "visitors stay inside a good while (avg %.1fs)" % avg)
			print("[T] REVIEWS count=%d avg=%.2f delta=%.1f quality=%.1f half_stars=%d up+%d" % [data["count"], data["avg"], data["delta"], data["new_q"], data["new_h"], data["up"]])
			for r in data["shown"].slice(0, 5):
				print("[T]   %d* %s - %s (%s)" % [r["stars"], r["text"], r["name"], r["kind"]])
			if shots:
				await _wait(0.6)
				await shot("06_reviews")
			_close_then(w.day_cycle.to_ledger)
		"ledger":
			print("[T] LEDGER income=%s expense=%s net=%d money=%d" % [data["income"], data["expense"], data["net"], data["money"]])
			if shots:
				await _wait(0.3)
				await shot("07_ledger")
			_close_then(w.day_cycle.next_day)
		"trivia", "choice", "exhibit", "podium", "discipline":
			print("[T] panel opened: ", n)
			_close_then(Callable())


func _sample_guests() -> void:
	var had := {}
	while GameState.phase == GameState.Phase.OPEN:
		await _wait(0.25)
		for g in w.day_cycle.guests:
			if not is_instance_valid(g):
				continue
			_seen[g.state] = true
			var id: int = g.get_instance_id()
			if g.inside:
				_inside_t[id] = float(_inside_t.get(id, 0.0)) + 0.25 * Engine.time_scale
			if had.get(id, false) and not g.has_litter:
				_litter += 1
			had[id] = g.has_litter


func _close_then(cb: Callable) -> void:
	await get_tree().process_frame
	w.ui.close_panel()
	if cb.is_valid():
		cb.call()


class FakeGuest extends Node:
	var got := false

	func served(_o: Node) -> void:
		got = true


func run() -> void:
	await _wait(0.5)
	var nodes := 0
	for n in w.beach.nodes_root.get_children():
		if n is DigNode:
			nodes += 1
	check(nodes > 10, "dig nodes spawned (%d)" % nodes)
	check(w.museum.all_objects().size() == 2, "starter museum has display case + bin")
	# --- hotbar & held tools (feedback 34/45/46/55)
	check(GameState.hotbar.size() == 3, "hotbar starts with 3 slots")
	check(GameState.held_tool() == "shovel", "start holding the shovel")
	check(w.player.held_node != null, "held shovel shows in the hand")
	var tp_visible := false
	if w.player.visual.tool_node:
		for mi in Art.meshes(w.player.visual.tool_node):
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
				tp_visible = true
	check(not tp_visible, "body's copy of the held tool is shadow-only (no ghost tool under the player)")
	check(w.player._use_clip() == "AN_FP_Dig", "shovel uses the dig animation")
	check(not Settings.ACTIONS.has("shove"), "separate shove key removed (Use shoves)")
	# --- feedback round 2: keys, loans, matrix names, music
	check(int(Settings.ACTIONS["interact"]["kb"]["code"]) == KEY_F, "F is Interact")
	check(int(Settings.ACTIONS["inventory"]["kb"]["code"]) == KEY_E, "E opens the inventory / backpack")
	check(not GameState.has_method("take_loan"), "loans removed")
	var nm_era := GameState.item_name({"t": "encased", "f": "ammonite", "m": "shale"})
	check(not ("Mesozoic" in nm_era or "Cenozoic" in nm_era or "Paleozoic" in nm_era), "find names don't give away the era (%s)" % nm_era)
	check(ResourceLoader.exists(Audio.MUSIC["open"]) and String(Audio.MUSIC["open"]).ends_with(".ogg"), "recorded music tracks (not code-made)")
	check(DB.SPECIES.size() >= 60, "many more fossils (%d species)" % DB.SPECIES.size())
	var mega_n := 0
	for spk in DB.SPECIES.keys():
		var c1 := String(DB.SPECIES[spk]["case"])
		check(DB.CASES.has(c1), "%s fits exactly one case (%s)" % [spk, c1])
		if c1 == "mega":
			mega_n += 1
	check(mega_n >= 6, "mega skeletons: %d" % mega_n)
	check(DB.SKILLS.size() >= 70, "much bigger upgrade tree (%d nodes)" % DB.SKILLS.size())
	check(GameState.up == 0, "upgrade points start at 0 (earned by opening)")
	var gsmall := GameState.lab_grid("sand_dollar")
	var gbig := GameState.lab_grid("trex:skull")
	check(gsmall.x * gsmall.y < gbig.x * gbig.y and gsmall.x <= 9, "lab grid scales with fossil size (%s vs %s)" % [gsmall, gbig])
	check(w.traffic != null and w.traffic.get_child_count() >= 2, "traffic + road tunnels exist")
	var car: Traffic.Vehicle = w.traffic.spawn("car_sedan", 1, 10.0, Color.RED)
	check(car.wheels.size() == 4, "cars have 4 spinning wheels")
	var bus: Traffic.Vehicle = w.traffic.spawn("bus_school", -1, 9.0)
	check(bus.door != null, "buses have an opening door")
	car.queue_free()
	bus.queue_free()
	w.player.trash_held()
	check(GameState.held_tool() == "shovel", "vital shovel can't be trashed")
	w.player.drop_held()
	check(GameState.held().is_empty() and not GameState.has_tool_item("shovel"), "shovel dropped")
	var pk: Array = get_tree().get_nodes_in_group("pickups")
	check(pk.size() == 1, "dropped shovel lies in the world")
	if not pk.is_empty():
		(pk[0] as Pickup)._take()
	check(GameState.has_tool_item("shovel"), "picked the shovel back up")
	w.player.drop_held()
	await get_tree().process_frame
	w.ui.panels._equip_tool("shovel")
	w.ui.close_panel()
	await get_tree().process_frame
	check(GameState.has_tool_item("shovel") and get_tree().get_nodes_in_group("pickups").filter(func(x): return not x.is_queued_for_deletion()).is_empty(), "gear rack re-issued the shovel")
	GameState.hotbar[1] = {"t": "gem", "id": "quartz"}
	GameState.select_slot(1)
	w.player.trash_held()
	check(GameState.hotbar[1].is_empty(), "non-vital item trashed")
	GameState.select_slot(0)
	if w.player.arm_anim:
		check(w.player.arm_anim.has_animation("AN_FP_Dig") and w.player.arm_anim.has_animation("AN_FP_HoldTool"), "Blender FP arm clips imported")
	if shots:
		w.player.global_position = Vector3(2, 0.2, -31)
		w.player.cam_yaw = PI
		w.player.cam_pitch = -0.28
		await _wait(0.8)
		await shot("01_museum_street")
		w.player.global_position = Vector3(0, 0.2, 6)
		w.player.cam_yaw = 0.0
		await _wait(0.8)
		print("[T] beach shot player at ", w.player.global_position, " yaw ", w.player.cam_yaw)
		await shot("02_beach")
	# --- dig
	var dug := 0
	for n in w.beach.nodes_root.get_children():
		if n is DigNode and not n.hidden and n.zone == "shore" and dug < 6:
			n.harvest(w.player)
			dug += 1
	await _wait(0.8)
	check(GameState.backpack.size() > 0, "digging filled the backpack (%d items)" % GameState.backpack.size())
	check(GameState.move_item("backpack", 0, "hotbar") == "", "backpack -> hotbar move")
	check(GameState.move_item("hotbar", GameState.hotbar.find(GameState.hotbar.filter(func(x): return not x.is_empty() and x.get("t", "") != "tool")[0]), "storage") == "", "hotbar -> storage move")
	check(GameState.move_item("storage", 0, "backpack") == "", "storage -> backpack move")
	GameState.deposit_backpack()
	var sold := GameState.sell_all_gems()
	print("[T] sold gems for ", sold, " money=", GameState.money)
	# --- guarantee some fossils & clean them
	GameState.storage.append({"t": "encased", "f": "ammonite", "m": "shale"})
	GameState.storage.append({"t": "encased", "f": "shark_tooth", "m": "sandstone"})
	GameState.storage.append({"t": "encased", "f": "ichthyosaurus:skull", "m": "jacket"})
	GameState.storage.append({"t": "encased", "f": "ichthyosaurus:back", "m": "jacket"})
	GameState.storage.append({"t": "encased", "f": "megalodon", "m": "sandstone"})
	if shots:
		w.ui.open("lab")
		await _wait(0.3)
		var first: Dictionary = GameState.encased_items()[0]
		w.ui.panels._start_lab(first)
		for i in range(60):
			w.ui.panels._lab.chip(Vector2i(randi() % w.ui.panels._lab.GW, randi() % w.ui.panels._lab.GH))
		await _wait(0.3)
		await shot("03_lab_minigame")
		w.ui.close_panel()
	for it in GameState.encased_items():
		GameState.remove_item(it)
		GameState.add_cleaned(it["f"], 0.85)
	check(GameState.collection.size() >= 4, "fossils cleaned into collection")
	var claimed := 0
	for sp in GameState.discovered.keys():
		claimed += GameState.claim(sp)
	check(claimed > 0, "discoveries claimed for %d UP" % claimed)
	# --- skills & money for the test
	GameState.money += 6000
	GameState.up += 40
	GameState.half_stars = 6
	check(not GameState.buy_skill("zone_reef"), "tree: can't skip a node's parents")
	check(not GameState.buy_skill("staff_slot_4"), "tree: 5-star tier locked at 3 stars")
	# --- each shore matches its star rating (no finds for cases you can't build yet)
	var zones_ok := true
	var reachable := {}
	for z in DB.ZONES:
		var zs := int(z["stars"])
		if z["skill"] != "" and int(DB.SKILLS[z["skill"]]["tier"]) != zs:
			zones_ok = false
		for kind in DB.NODE_TYPES.keys():
			for e in DB.fossil_table(z["id"], kind):
				var sp := String(e[1]).split(":")[1]
				reachable[sp] = true
				if int(DB.CASE_STARS[DB.SPECIES[sp]["case"]]) > zs:
					zones_ok = false
	check(zones_ok, "every shore only drops fossils for cases unlocked at its star rating")
	check(reachable.size() == DB.SPECIES.size(), "every species can still be found somewhere (%d/%d)" % [reachable.size(), DB.SPECIES.size()])
	for c in DB.CASE_STARS.keys():
		if c != "small":
			zones_ok = zones_ok and int(DB.SKILLS["bp_case_" + c]["tier"]) == int(DB.CASE_STARS[c])
	check(zones_ok, "case star ratings match their blueprints")
	var cash0 := GameState.money
	check(not GameState.build_unlocked("display_case_mega"), "Mega case is locked until its blueprint is bought")
	for id in ["ticket_1", "zone_cliffs", "lic_food", "bp_case_medium", "bp_case_big", "bp_case_mega", "equip_1", "backpack_1", "hotbar_1", "dig_1", "dig_2"]:
		var ok := GameState.buy_skill(id)
		check(ok, "bought skill " + id)
	check(GameState.money == cash0 - 50 - 40 - 150 - 300 - 30 - 40, "tree nodes charged their cash price")
	check(GameState.build_unlocked("display_case_mega"), "blueprint unlocked the Mega case")
	check(absf(GameState.dig_speed_mult() - 1.24) < 0.01, "Strong Arms upgrades speed up digging")
	check(GameState.hotbar.size() == 4, "Tool Belt +1 added a hotbar slot")
	w.beach.refresh_barriers(true)
	await _wait(1.5)
	check(not w.beach.barriers.has("cliffs"), "cliffs barrier removed")
	# --- mount + plaque
	var case: PlacedObject = w.museum.objects_of("display_case")[0]
	var free := GameState.free_fossils("ammonite")
	case.mount_fossil(free[0])
	case.data["plaque"] = {"era": "Mesozoic", "diet": "Carnivore", "habitat": "Open Ocean"}
	case.refresh_display()
	check(case.accurate_plaque(), "accurate plaque detected")
	# expansion + podium first (needs a 3x2 clear area)
	check(GameState.buy_skill("expand_1"), "bought Expansion I in the tree")
	await _wait(0.3)
	check(w.museum.W == 6 and GameState.museum_level == 1, "tree expansion built the bigger museum (%dx%d)" % [w.museum.W, w.museum.D])
	check(GameState.buy_skill("expand_2"), "bought Expansion II in the tree")
	await _wait(0.3)
	check(w.museum.W == 7, "museum is now %dx%d" % [w.museum.W, w.museum.D])
	var pod_done := false
	for y in range(w.museum.D - 1, -1, -1):
		for x in range(w.museum.W):
			if not pod_done and w.museum.can_place("display_case_mega", Vector2i(x, y), 0) == "":
				var pod := w.museum.place("display_case_mega", Vector2i(x, y), 0)
				var nmounted := pod.mount_species("ichthyosaurus")
				check(nmounted == 2, "mounted 2 ichthyosaur bones on podium")
				pod_done = true
	check(pod_done, "podium placed")
	# --- build
	var placed := 0
	for t in ["restroom", "popcorn_stand", "lemonade_stand", "plant_pot", "bench", "display_case", "trash_bin", "floor_lamp", "rug"]:
		var done := false
		for y in range(w.museum.D):
			for x in range(w.museum.W):
				if done:
					break
				if w.museum.can_place(t, Vector2i(x, y), 2) == "":
					var o := w.museum.place(t, Vector2i(x, y), 2)
					if t == "display_case":
						var f2 := GameState.free_fossils("shark_tooth")
						if not f2.is_empty():
							o.mount_fossil(f2[0])
					done = true
					placed += 1
	check(placed >= 6, "placed %d objects" % placed)
	w.museum.compute_pillars()
	print("[T] pillars ", GameState.pillars, " ticket=", GameState.ticket_price())
	if shots:
		w.build.enter()
		await _wait(0.6)
		await shot("04_build_mode")
		w.build.exit()
	# --- staff: no slots until bought in the tree; every job is its own licence
	GameState.half_stars = 6
	check(GameState.staff_cap() == 0, "start with 0 staff slots")
	check(not w.day_cycle.hire("janitor"), "cannot hire with 0 slots")
	check(GameState.buy_skill("staff_slot_1"), "bought Staff Slot +1")
	check(not w.day_cycle.hire("janitor"), "cannot hire a janitor before the job is unlocked")
	check(GameState.buy_skill("job_janitor"), "bought Job: Janitor")
	check(GameState.buy_skill("job_security"), "bought Job: Security Guard")
	check(GameState.buy_skill("staff_slot_2"), "bought Staff Slot +1 (II)")
	check(GameState.staff_cap() == 2, "staff cap is 2")
	check(w.day_cycle.hire("janitor"), "hired janitor")
	check(w.day_cycle.hire("security"), "hired security")
	check(not w.day_cycle.hire("intern"), "intern blocked (job locked, cap full)")
	# --- plaques: blank / wrong / fact-check kiosk (feedback 50/54)
	var case2: PlacedObject = w.museum.objects_of("display_case")[0]
	var keep: Dictionary = case2.data["plaque"]
	case2.data["plaque"] = {}
	check(case2.plaque_status() == "blank", "plaque starts blank (no auto)")
	case2.data["plaque"] = {"era": "Paleozoic", "diet": "Carnivore", "habitat": "Open Ocean"}
	check(case2.plaque_status() == "wrong" and case2.wrong_tags().size() == 1, "wrong plaque detected: %s" % [case2.wrong_tags()])
	check(w.museum.wrong_plaques().size() >= 1, "museum lists wrong plaques")
	var kiosk_ok := false
	for y in range(w.museum.D):
		for x in range(w.museum.W):
			if not kiosk_ok and w.museum.can_place("plaque_checker", Vector2i(x, y), 0) == "":
				w.museum.place("plaque_checker", Vector2i(x, y), 0)
				kiosk_ok = true
	check(kiosk_ok and w.museum.has_checker(), "fact-check kiosk built")
	case2.data["plaque"] = keep
	# --- concession stand service (feedback 52)
	var stand: PlacedObject = w.museum.objects_of("lemonade_stand")[0] if not w.museum.objects_of("lemonade_stand").is_empty() else null
	if stand:
		var fake := FakeGuest.new()
		add_child(fake)
		stand.join_queue(fake)
		GameState.select_slot(2)
		stand._stand_use()
		check(GameState.held().get("t", "") == "serve", "grabbed a cup at the stand")
		stand._stand_use()
		check(GameState.held().get("full", false), "filled the cup from the jug")
		stand._stand_use()
		check(fake.got and GameState.held().is_empty() and stand.queue.is_empty(), "served the waiting guest")
		fake.queue_free()
		GameState.select_slot(0)
		# a hired Snack Vendor serves the queue on their own
		GameState.half_stars = 8
		check(GameState.buy_skill("job_vendor"), "bought Job: Snack Vendor")
		check(GameState.buy_skill("staff_slot_3"), "bought Staff Slot +1 (III)")
		check(w.day_cycle.hire("vendor"), "hired a snack vendor")
		var vendor: Staff = w.day_cycle.staff_nodes[w.day_cycle.staff_nodes.size() - 1]
		var f2 := FakeGuest.new()
		var f3 := FakeGuest.new()
		add_child(f2)
		add_child(f3)
		stand.join_queue(f2)
		stand.join_queue(f3)
		vendor.job = stand
		vendor.state = "work"
		vendor._complete()
		check(f2.got and not f3.got and vendor.job == stand, "vendor served the first guest and stays for the next")
		vendor._complete()
		check(f3.got and stand.queue.is_empty() and vendor.job == null, "vendor cleared the queue")
		f2.queue_free()
		f3.queue_free()
		GameState.half_stars = 6
	# --- save/load roundtrip before opening
	SaveManager.save(9)
	var before_money := GameState.money
	var before_objs := GameState.placed.size()
	check(SaveManager.load_slot(9), "reload slot")
	check(not GameState.pending_world.is_empty(), "save carries a world snapshot")
	GameState.take_pending_world()
	check(GameState.money == before_money and GameState.placed.size() == before_objs, "save roundtrip money/objects")
	w.museum.load_objects()
	w.day_cycle.spawn_staff()
	# --- open the museum and fast-forward
	Settings.values["day_len"] = 2.0
	Engine.time_scale = 6.0
	w.day_cycle.open_museum()
	_sample_guests()
	check(GameState.phase == GameState.Phase.OPEN, "museum opened")
	await _wait(5.0)
	print("[T] clock=%.2f guests=%d money=%d" % [w.day_cycle.clock, w.day_cycle.guests.size(), GameState.money])
	check(w.day_cycle.guests.size() > 0, "guests spawned")
	# --- mid-day save comes back EXACTLY as it was
	Engine.time_scale = 1.0
	w.museum.add_mess("trash", w.museum.cell_center(w.museum.entrance()) + Vector3(0.5, 0, 0.5))
	w.player.global_position = Vector3(3.25, 0.0, -20.5)
	w.player.cam_yaw = 1.23
	var snap_before := {"clock": w.day_cycle.clock, "guests": w.day_cycle.guests.size(), "money": GameState.money,
		"visitors": w.day_cycle.visitors_today, "mess": w.museum.mess.size(), "nodes": w.beach.save_nodes().size(), "day": GameState.day}
	var names_before: Array = []
	var where_before: Array = []
	for g in w.day_cycle.guests:
		names_before.append(g.gname)
		where_before.append([g.gname, g.global_position])
	names_before.sort()
	# a car is on the road (it must come back at the same spot and speed)
	if w.traffic.vehicles.is_empty():
		w.traffic.spawn("car_sedan", 1, 10.0, Color("3f7fd9")).position.x = -12.0
	# the hard cases: someone mid-fall (ragdoll) and someone on the bus-stop bench
	var gl: Array = w.day_cycle.guests
	var knocked: Guest = null
	var knocked_name := ""
	if gl.size() >= 2:
		knocked = gl[0]
		knocked_name = knocked.gname
		knocked.knockback(Vector3(3.0, 4.0, 0.0), false)
		var sitter: Guest = gl[1]
		sitter.inside = false
		sitter.state = Guest.S.LEAVE
		sitter._bus_spot = w.traffic.stop_spot(sitter)
		sitter.global_position = sitter._bus_spot
		sitter._arrive_at_stop()
		await _wait(0.3)
	var hips_a := Vector3.ZERO
	if knocked and knocked._rd.has("bodies"):
		hips_a = (knocked._rd["bodies"]["Hips"] as RigidBody3D).global_position
	check(SaveManager.save(9), "saved mid-day")
	var exact_a: Dictionary = JSON.parse_string(JSON.stringify(w.snapshot()))
	check(SaveManager.load_slot(9), "loaded the mid-day save")
	w.restore_snapshot(GameState.take_pending_world())
	var exact_b: Dictionary = JSON.parse_string(JSON.stringify(w.snapshot()))
	var money_after := GameState.money
	var visitors_after: int = w.day_cycle.visitors_today
	# same frame, no time passed: every visitor, staff member and vehicle must match field for field
	var diffs: Array = []
	for key in ["guests"]:
		var la: Array = exact_a["day"][key]
		var lb: Array = exact_b["day"][key]
		for i in range(mini(la.size(), lb.size())):
			for f in ["kind", "gname", "state", "timer", "pos", "yaw", "path", "target", "anim", "mood", "inside", "queue_i", "bubble", "visible"]:
				if str(la[i].get(f)) != str(lb[i].get(f)):
					diffs.append("%s.%s: %s -> %s" % [la[i].get("gname"), f, str(la[i].get(f)), str(lb[i].get(f))])
	for i in range(mini(exact_a["staff"].size(), exact_b["staff"].size())):
		for f in ["pos", "state", "timer", "path", "job", "anim"]:
			if str(exact_a["staff"][i].get(f)) != str(exact_b["staff"][i].get(f)):
				diffs.append("staff%d.%s" % [i, f])
	var va: Array = exact_a["traffic"]["vehicles"]
	var vb: Array = exact_b["traffic"]["vehicles"]
	if va.size() != vb.size():
		diffs.append("vehicles %d -> %d" % [va.size(), vb.size()])
	else:
		for i in range(va.size()):
			for f in ["model", "x", "z", "speed", "stopped", "role", "stop_x"]:
				if str(va[i].get(f)) != str(vb[i].get(f)):
					diffs.append("vehicle%d.%s: %s -> %s" % [i, f, str(va[i].get(f)), str(vb[i].get(f))])
	if knocked_name != "":
		var kb: Guest = null
		for g in w.day_cycle.guests:
			if g.gname == knocked_name and g.state == Guest.S.KNOCKED:
				kb = g
		check(kb != null and kb._rd.has("bodies") and (kb._rd["bodies"]["Hips"] as RigidBody3D).global_position.distance_to(hips_a) < 0.05, "a knocked-over visitor reloads mid-fall in the same pose")
		var seated := 0
		for g in w.day_cycle.guests:
			if g.state == Guest.S.WAIT_BUS and w.traffic.is_seat(g._bus_spot) and g.visual.anim == "sit":
				seated += 1
		check(seated >= 1, "the bus-stop visitor is back on the same bench seat")
	for d in diffs.slice(0, 12):
		print("[T]   diff ", d)
	check(diffs.is_empty() and va.size() > 0, "visitors, staff and %d vehicle(s) restored field for field (%d diffs)" % [va.size(), diffs.size()])
	await _wait(0.05)
	var names_after: Array = []
	var placed_ok := true
	for g in w.day_cycle.guests:
		names_after.append(g.gname)
		var near := false
		for e in where_before:
			if e[0] == g.gname and (e[1] as Vector3).distance_to(g.global_position) < 0.6:
				near = true
		placed_ok = placed_ok and near
	names_after.sort()
	check(GameState.phase == GameState.Phase.OPEN and GameState.day == int(snap_before["day"]), "mid-day load stays on the same day, still open")
	check(absf(w.day_cycle.clock - float(snap_before["clock"])) < 0.05, "clock restored (%.2f vs %.2f)" % [w.day_cycle.clock, snap_before["clock"]])
	check(w.player.global_position.distance_to(Vector3(3.25, 0.0, -20.5)) < 0.3 and absf(w.player.cam_yaw - 1.23) < 0.01, "player restored to the exact spot")
	check(w.day_cycle.guests.size() == int(snap_before["guests"]), "every visitor restored (%d/%d)" % [w.day_cycle.guests.size(), snap_before["guests"]])
	check(names_after == names_before, "visitors keep their names (positions: exact check above)")
	check(money_after == int(snap_before["money"]) and visitors_after == int(snap_before["visitors"]), "money and visitor count restored")
	check(w.museum.mess.size() == int(snap_before["mess"]), "litter restored")
	check(w.beach.save_nodes().size() == int(snap_before["nodes"]), "dig spots restored")
	# --- benches: visitors sit ON the seat, facing out, and stand back up after
	var bench: PlacedObject = null
	for o in w.museum.objects_of("bench"):
		bench = o
	if bench == null:
		for x in range(w.museum.W):
			for y in range(w.museum.D):
				if bench == null and w.museum.can_place("bench", Vector2i(x, y), 1) == "":
					bench = w.museum.place("bench", Vector2i(x, y), 1)
	var sitter_g: Guest = null
	for g in w.day_cycle.guests:
		if g.inside and g.state != Guest.S.KNOCKED and sitter_g == null:
			sitter_g = g
	if bench and sitter_g:
		var stand_p := sitter_g.global_position
		sitter_g.target = bench
		sitter_g._arrive_cb = str(Guest.S.VIEW)
		sitter_g._arrived()
		var mt: Transform3D = bench.model.global_transform
		var local := mt.affine_inverse() * sitter_g.global_position
		var f := mt.basis.z.normalized()
		var facing := Vector3(-sin(sitter_g.visual.rotation.y), 0, -cos(sitter_g.visual.rotation.y))
		check(absf(local.z) < 0.15 and absf(absf(local.x) - 0.42) < 0.05 and sitter_g.visual.anim == "sit" and facing.dot(f) > 0.95, "visitor sits on the bench seat, facing out (local %s)" % local)
		if shots:
			Engine.time_scale = 1.0
			sitter_g.timer = 60.0
			var cam := Camera3D.new()
			w.add_child(cam)
			var seat := bench.model.global_position + Vector3(0, 0.7, 0)
			cam.global_position = seat + f * 0.9 + mt.basis.x.normalized() * 0.5 + Vector3(0, 2.2, 0)
			cam.look_at(seat)
			cam.current = true
			w.museum.set_roof_visible(false)
			await _wait(0.6)
			await shot("17_bench_sit")
			cam.queue_free()
			w.player.camera.current = true
		sitter_g._finish_activity()
		check(sitter_g.global_position.distance_to(stand_p) < 0.05, "visitor stands back up where they were")
	Engine.time_scale = 6.0
	if shots:
		Engine.time_scale = 1.0
		w.player.global_position = w.museum.cell_center(w.museum.entrance()) + Vector3(0, 0.2, 1.0)
		w.player.cam_yaw = PI
		w.player.cam_pitch = -0.55
		await _wait(1.2)
		await shot("05_open_inside")
		# shove a guest to test ragdolls
		for g in w.day_cycle.guests:
			if is_instance_valid(g) and g.inside:
				g.knockback(Vector3(4, 4, 0), true)
				break
		await _wait(0.4)
		await shot("05b_ragdoll")
		Engine.time_scale = 6.0
	var start_day := GameState.day
	var tries := 0
	while GameState.day == start_day and tries < 400:
		await _wait(0.5)
		tries += 1
	Engine.time_scale = 1.0
	check(GameState.day == start_day + 1, "advanced to day %d" % GameState.day)
	check(GameState.phase == GameState.Phase.PREP, "back in prep phase")
	print("[T] END stats=", GameState.stats, " money=", GameState.money, " quality=", GameState.quality, " stars=", GameState.half_stars)
	if shots:
		w.ui.open("skills")
		await _wait(0.4)
		await shot("08_skill_tree")
		w.ui.open("guide", true)
		await _wait(0.4)
		await shot("09_field_guide")
		w.ui.open("guide", false)
		await _wait(0.4)
		await shot("09b_guide")
		w.ui.open("storage")
		await _wait(0.4)
		await shot("09c_storage")
		w.ui.open("management", "")
		await _wait(0.4)
		await shot("10_management")
		w.ui.open("pause")
		await _wait(0.4)
		await shot("11_pause")
		w.ui.close_panel()
	await _sweep()
	await _round2()
	print("[T] DONE failures=%d %s" % [failures.size(), failures])
	get_tree().quit(1 if failures.size() > 0 else 0)


## Feedback round 2: J-Mail + scams + school trip tour, trash throwing, selling,
## building on people, quality / upgrade points from opening, weathering spots.
func _round2() -> void:
	GameState.phase = GameState.Phase.PREP
	GameState.money = 2000
	# --- office + J-Mail
	GameState.half_stars = 6
	if not GameState.has_skill("expand_3"):
		GameState.skills.erase("expand_3")
		GameState.up += 20
		GameState.money += 5000
		check(GameState.buy_skill("expand_3"), "bought Expansion III + Office")
	await _wait(0.3)
	check(w.office != null, "the 3-star expansion added the office computer")
	Mail.generate_day()
	check(not GameState.emails.is_empty(), "J-Mail emails arrive (%d)" % GameState.emails.size())
	Mail._make("scam")
	var scam: Dictionary = GameState.emails[0]
	var m0 := GameState.money
	Mail.act(scam, "accept")
	check(GameState.money < m0 * 0.5, "accepting a scam loses a MASSIVE share of cash (%d -> %d)" % [m0, GameState.money])
	GameState.money = 3000
	for em in GameState.emails.duplicate():
		if em["kind"] == "school_trip":
			GameState.emails.erase(em)
	var trip_ok := Mail._make("school_trip")
	check(trip_ok, "school trip email (3+ stars)")
	var trip_mail: Dictionary = {}
	for m in GameState.emails:
		if m["kind"] == "school_trip":
			trip_mail = m
	Mail.act(trip_mail, "accept")
	check(not GameState.events.is_empty(), "school trip booked")
	if w.office:
		w.office._on_use()
		await _wait(0.2)
		check(w.office.seated and w.player.locked, "sat down at the computer")
		if shots:
			await _wait(0.5)
			await shot("12_jmail")
		w.office.stand_up()
		check(not w.office.seated and not w.player.locked, "stood up from the computer")
	if shots:
		w.ui.open("factcheck")
		await _wait(0.4)
		await shot("13_factcheck")
		w.ui.open("skills")
		await _wait(0.4)
		await shot("14_tree")
		w.ui.open("pause")
		await _wait(0.4)
		await shot("15_pause")
		w.ui.close_panel()
	# --- the school trip arrives and the player gives the tour
	var ev: Dictionary = GameState.events[0]
	ev["day"] = GameState.day
	Settings.values["day_len"] = 3.0
	w.day_cycle.open_museum()
	w.day_cycle._start_school_trip(ev)
	var tour: SchoolTour = w.day_cycle.tour
	Engine.time_scale = 3.0
	var tries := 0
	while (tour.teacher == null or tour.students.size() < 3) and tries < 60:
		await _wait(0.5)
		tries += 1
	Engine.time_scale = 1.0
	check(tour.teacher != null and tour.students.size() >= 3, "school bus dropped off the teacher and %d students" % tour.students.size())
	if tour.teacher:
		tour.teacher_talk()
		w.ui.dialog_queue.clear()
		w.ui._next_line()
		check(tour.active, "guided tour started")
		var stops := 0
		for o in w.museum.all_objects():
			if stops >= SchoolTour.STOPS_NEEDED:
				break
			var q := tour._question(o)
			if q.is_empty():
				continue
			tour.teacher.global_position = o.global_position + Vector3(1.5, 0, 0)
			tour.answer(o.get_instance_id(), stops != 1)  # one wrong fact on purpose
			stops += 1
		check(tour.done and tour.wrong == 1, "tour finished (%d right, %d wrong)" % [tour.right, tour.wrong])
		var rv := tour.teacher_review(tour.teacher)
		check(int(rv["stars"]) == 1 and float(rv["weight"]) >= 3.0, "a wrong fact gets a very negative, heavy review")
	# --- litter: a guest throws trash; the player throws held trash into a bin
	var g := w.day_cycle.spawn_guest("tourist", w.museum.cell_center(w.museum.entrance()) + Vector3(0, 0, 2))
	g.inside = true
	g.state = Guest.S.DECIDE
	var mess0 := w.museum.mess.size()
	var fills0 := 0
	for b in w.museum.objects_of("trash_bin"):
		fills0 += b.fill
	g._drop_trash()
	await _wait(1.0)
	var fills1 := 0
	for b in w.museum.objects_of("trash_bin"):
		fills1 += b.fill
	check(w.museum.mess.size() > mess0 or fills1 > fills0, "guest threw trash (floor or bin)")
	var bin: PlacedObject = w.museum.objects_of("trash_bin")[0]
	bin.fill = 0
	GameState.hotbar[GameState.hotbar.size() - 1] = {"t": "trash"}
	GameState.select_slot(GameState.hotbar.size() - 1)
	w.player.global_position = bin.global_position + Vector3(0, 0, 2.5)
	w.player.face(bin.global_position)
	w.player.cam_pitch = -0.3
	await _wait(0.2)
	w.player.throw_trash()
	await _wait(1.0)
	check(bin.fill == 1, "thrown trash landed in the bin")
	# --- build while open, never on a person; selling refunds 25%
	var cell := w.museum.world_to_cell(g.global_position)
	check(w.museum.can_place("bench", cell, 0) != "", "can't build on top of a visitor")
	var spot := Vector2i(-1, -1)
	for y in range(w.museum.D):
		for x in range(w.museum.W):
			if spot.x < 0 and w.museum.can_place("bench", Vector2i(x, y), 0) == "":
				spot = Vector2i(x, y)
	w.build.enter()
	check(w.build.active, "Build Mode works while the museum is open")
	check(not w.player.fp.visible, "Build Mode hides the first-person arms")
	await _wait(0.1)
	check(not w.ui.get_node("HUD/StatusCard").visible and not w.ui.get_node("HUD/RatingCard").visible, "Build Mode hides the top-left and top-right HUD cards")
	w.build._select("bench")
	w.build.cell = spot
	w.build.rot = 0
	var mbefore := GameState.money
	w.build._place()
	w.build._remove()
	check(GameState.money == mbefore - 25 + int(floor(25 * GameState.refund_rate())), "selling refunds only %d%%" % int(GameState.refund_rate() * 100))
	w.build.exit()
	check(w.player.fp.visible, "arms back after Build Mode")
	await _wait(0.1)
	check(w.ui.get_node("HUD/StatusCard").visible and w.ui.get_node("HUD/RatingCard").visible, "HUD cards back after Build Mode")
	# --- player gets hit by a car
	for v in w.traffic.vehicles:
		if is_instance_valid(v):
			v.queue_free()
	await get_tree().process_frame
	w.player.global_position = Vector3(-20, 0.1, Traffic.EAST_Z)
	var hit_car: Traffic.Vehicle = w.traffic.spawn("car_hatch", 1, 10.0, Color.BLUE)
	hit_car.position.x = -26.0
	var t2 := 0
	while not w.player.ragdolled and t2 < 120:
		await get_tree().physics_frame
		t2 += 1
	check(w.player.ragdolled, "a car knocked the player over (ragdoll)")
	if shots:
		await _wait(0.6)
		await shot("16_player_ragdoll")
	var t3 := 0
	while w.player.ragdolled and t3 < 20:
		await _wait(0.3)
		t3 += 1
	check(not w.player.ragdolled and w.player.camera.current, "player got back up in first person")
	# --- dig spots weather away and grow back
	var spot_node: DigNode = null
	for n in w.beach.nodes_root.get_children():
		if n is DigNode and not n.hidden and not n.depleted:
			spot_node = n
			break
	if spot_node:
		spot_node.life = 0.01
		await _wait(2.0)
		check(not is_instance_valid(spot_node), "untouched dig spots weather away")
	var before := w.beach.nodes_root.get_child_count()
	w.beach._respawn_tick()
	await get_tree().process_frame
	check(w.beach.nodes_root.get_child_count() >= before, "dig spots grow back")
	# --- upgrade points come from opening: a visitor sees a new species
	GameState.discovered["trilobite"] = {"claimed": false, "pieces": {}}
	GameState.mark_seen("trilobite")
	var up0 := GameState.up
	w.day_cycle.visitors_today = 6
	var sm := w.day_cycle._review_summary()
	check(GameState.up > up0 and (sm["seen"] as Array).size() == 1, "opening earned %d Upgrade Points (visitors + new species seen)" % (GameState.up - up0))
	w.day_cycle._finish_day()
	w.ui.close_panel()
	GameState.phase = GameState.Phase.PREP


## Opens every panel, drives build mode, shoving, interactions and the story.
func _sweep() -> void:
	var case: PlacedObject = w.museum.objects_of("display_case")[0]
	var pods := w.museum.objects_of("display_case_mega")
	var staff: Staff = w.day_cycle.staff_nodes[0] if not w.day_cycle.staff_nodes.is_empty() else null
	if staff:
		staff.go_rogue()
	var specs := [["shop", null], ["inventory", null], ["storage", null], ["gear", null], ["factcheck", null], ["management", ""], ["management", "Finances"], ["exhibit", case],
		["pit", null], ["giftshop", null], ["pause", null], ["settings", null], ["guide", false], ["guide", true], ["skills", null],
		["choice", {"title": "t", "text": "x", "options": [["ok", Callable()]]}], ["trivia", {"q": "q?", "options": ["a", "b"], "answer": "a"}]]
	if not pods.is_empty():
		specs.append(["podium", pods[0]])
	if staff:
		specs.append(["discipline", staff])
	for s in specs:
		w.ui.open(s[0], s[1])
		await get_tree().process_frame
		check(w.ui.current != null, "panel opens: %s" % s[0])
		w.ui.close_panel()
	# shop actions
	GameState.money += 1000
	w.ui.panels._buy_tool("pick_1")
	check(int(GameState.tools["pick"]) == 1, "bought stone pick")
	check(GameState.has_tool_item("pick"), "new pickaxe went into the hotbar/backpack")
	w.ui.panels._buy_plush()
	check(GameState.plushies >= 5, "bought plushies")
	w.ui.close_panel()
	# exhibit plaque save path
	var opts := {}
	for k in ["era", "diet", "habitat"]:
		var ob := OptionButton.new()
		ob.add_item("(auto)")
		for x in {"era": DB.ERAS, "diet": DB.DIETS, "habitat": DB.HABITATS}[k]:
			ob.add_item(x)
		opts[k] = ob
	(opts["era"] as OptionButton).selected = 1
	(opts["diet"] as OptionButton).selected = 1
	(opts["habitat"] as OptionButton).selected = 1
	var res := Label.new()
	w.ui.panels._save_plaque(case, opts, res)
	print("[T] plaque result: ", res.text)
	# build mode place/remove
	w.build.enter()
	check(w.build.active, "build mode entered")
	w.build._select("bench")
	var placed_ok := false
	for y in range(w.museum.D):
		for x in range(w.museum.W):
			if not placed_ok and w.museum.can_place("bench", Vector2i(x, y), 2) == "":
				w.build.cell = Vector2i(x, y)
				w.build.rot = 2
				var before := w.museum.all_objects().size()
				w.build._place()
				await get_tree().process_frame
				placed_ok = w.museum.all_objects().size() == before + 1
				w.build._remove()
	check(placed_ok, "build mode placement")
	w.build.exit()
	# player interaction + shove
	w.player.cam_yaw = 0.0
	w.player.cam_pitch = 0.0
	var g := w.day_cycle.spawn_guest("tourist", w.player.global_position + Vector3(0, 0, -1.2))
	g.inside = true
	g.state = Guest.S.DECIDE
	await get_tree().physics_frame
	await get_tree().process_frame
	w.player._shove_cd = 0.0
	w.player._do_shove()
	check(g.state == Guest.S.KNOCKED, "first-person shove ragdolls guest")
	var rbodies: Dictionary = g._rd.get("bodies", {})
	var nb: int = rbodies.size()
	check(nb >= 10, "ragdoll has a physics body per body part (%d)" % nb)
	await _wait(0.6)
	var head_y := -1.0
	for b in rbodies.values():
		if is_instance_valid(b):
			head_y = maxf(head_y, (b as Node3D).global_position.y)
	var parts_moved := 0
	for b in rbodies.values():
		if is_instance_valid(b) and (b as RigidBody3D).linear_velocity.length() > 0.05:
			parts_moved += 1
	print("[T] ragdoll highest part y=%.2f, parts moving=%d" % [head_y, parts_moved])
	var vis: CharVisual = g.visual
	var clips := ["idle", "walk", "run", "dig", "sweep", "tantrum", "sit", "sleep", "wave", "cheer", "climb", "inspect", "kick", "getup"]
	var have := 0
	for c in clips:
		if vis.player and vis.player.has_animation(CharVisual.clip(c)):
			have += 1
	check(have == clips.size(), "Blender animation clips on the character (%d/%d)" % [have, clips.size()])
	if rbodies.has("Hips") and vis.skeleton:
		var hb := vis.skeleton.find_bone("Hips")
		var bone_pos: Vector3 = (vis.skeleton.global_transform * vis.skeleton.get_bone_global_pose(hb)).origin
		var gap: float = bone_pos.distance_to((rbodies["Hips"] as Node3D).global_position)
		check(gap < 0.05, "skeleton follows ragdoll bodies (gap %.3f)" % gap)
	await _wait(4.0)
	check(g.state != Guest.S.KNOCKED, "guest got back up")
	check(not vis.ragdolled and vis.player.is_playing(), "animation resumes after get-up")
	# Blender pipeline: collision proxies + FX meshes + set dressing
	var wall := Art.model("wall")
	check(Art.has_proxy(wall), "wall.glb carries a Blender collision proxy")
	wall.free()
	for fxm in ["fx_puff", "fx_chip", "fx_sparkle", "fx_gem_glint", "fx_confetti", "fx_dust", "fx_droplet"]:
		check(Art.mesh_of(fxm) != null, "FX mesh %s loads" % fxm)
	FX.burst(w, w.player.global_position, "confetti")
	check(ResourceLoader.exists("res://assets/models/dress_beach_camp.glb"), "set-dressing clusters exported")
	var hatless := 0
	for n in ["SM_Char_Hair", "Hair_Sides", "Coat", "PhotoCamera", "Lanyard"]:
		if vis.model.find_child(n, true, false):
			hatless += 1
	check(hatless == 5, "character outfit pieces present (%d/5)" % hatless)
	# staff morale: praise / raise / quit
	if not w.day_cycle.staff_nodes.is_empty():
		var st: Staff = w.day_cycle.staff_nodes[0]
		var m0: float = st.morale()
		w.ui.open("management", "")
		await get_tree().process_frame
		w.ui.panels._praise(st)
		check(st.morale() > m0 or m0 >= 100.0, "praise raises morale")
		var wage0 := GameState.staff_wage(st.data)
		w.ui.panels._raise(st)
		check(GameState.staff_wage(st.data) == wage0 + 10, "raise adds $10/day")
		w.ui.close_panel()
		var n0 := GameState.staff.size()
		st.change_morale(-500.0, "test")
		await get_tree().process_frame
		check(st.state == "leaving", "employee quits at 0 morale")
		check(GameState.staff.size() == n0 - 1 and not w.day_cycle.staff_nodes.has(st), "quitter removed from staff roster")
		await _wait(6.0)
		print("[T] quitter still walking: ", is_instance_valid(st))
	# dig via the player path
	for n in w.beach.nodes_root.get_children():
		if n is DigNode and not n.hidden and not n.depleted and n.kind == "sand":
			GameState.backpack.clear()
			w.player.hold_override = true
			w.player.start_dig(n)
			check(w.player.digging, "player started digging")
			await _wait(1.0)
			check(w.player.digging and w.player.dig_t > 0.3, "progress fills while holding")
			w.player.hold_override = false
			w.player.focus_dig = n
			w.player._hold_dig_check()
			check(not w.player.digging and w.player.dig_t == 0.0, "letting go resets the dig")
			w.player.hold_override = true
			w.player.start_dig(n)
			await _wait(6.0)
			w.player.hold_override = false
			check(not w.player.digging and GameState.backpack.size() > 0, "player dig completed")
			break
	# story: act 2 -> act 3 -> win
	w.on_apex_found()
	check(int(GameState.flags["act"]) == 2, "act 2 triggered")
	for pc in DB.SPECIES["apex"]["pieces"]:
		GameState.add_cleaned("apex:" + pc, 0.9)
	w.story_check()
	check(int(GameState.flags["act"]) == 3, "act 3 triggered")
	if not pods.is_empty():
		GameState.half_stars = 10
		pods[0].mount_species("apex")
		await get_tree().process_frame
		check(pods[0].skeleton_complete(), "apex skeleton complete")
		check(GameState.flags.get("won", false), "win condition reached")
	# bankruptcy path
	GameState.money = -5000
	w.day_cycle.next_day()
	await get_tree().process_frame
	check(w.ui.current_name == "gameover", "bankruptcy shows game over")
	w.ui.close_panel()
