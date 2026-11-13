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
	GameState.storage.append({"t": "encased", "f": "ammonite", "era": "Mesozoic"})
	GameState.storage.append({"t": "encased", "f": "shark_tooth", "era": "Cenozoic"})
	GameState.storage.append({"t": "encased", "f": "ichthyosaurus:skull", "era": "Mesozoic"})
	GameState.storage.append({"t": "encased", "f": "ichthyosaurus:back", "era": "Mesozoic"})
	if shots:
		w.ui.open("lab")
		await _wait(0.3)
		var first: Dictionary = GameState.encased_items()[0]
		w.ui.panels._start_lab(first)
		for i in range(60):
			w.ui.panels._lab.chip(Vector2i(randi() % LabGame.GW, randi() % LabGame.GH))
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
	var cash0 := GameState.money
	for id in ["ticket_1", "zone_cliffs", "lic_food", "lic_podium", "equip_1", "backpack_1", "lic_aquarium", "hotbar_1"]:
		var ok := GameState.buy_skill(id)
		check(ok, "bought skill " + id)
	check(GameState.money == cash0 - 50 - 200 - 400 - 30, "tree nodes charged their cash price")
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
	GameState.skills["expand_1"] = true
	w.museum.expand()
	await _wait(0.3)
	check(w.museum.W == 7, "museum expanded to %dx%d" % [w.museum.W, w.museum.D])
	var pod_done := false
	for y in range(w.museum.D - 1, -1, -1):
		for x in range(w.museum.W):
			if not pod_done and w.museum.can_place("mega_podium", Vector2i(x, y), 0) == "":
				var pod := w.museum.place("mega_podium", Vector2i(x, y), 0)
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
	check(GameState.money == before_money and GameState.placed.size() == before_objs, "save roundtrip money/objects")
	w.museum.load_objects()
	w.day_cycle.spawn_staff()
	# --- open the museum and fast-forward
	Settings.values["day_minutes"] = 2.0
	Engine.time_scale = 6.0
	w.day_cycle.open_museum()
	check(GameState.phase == GameState.Phase.OPEN, "museum opened")
	await _wait(5.0)
	print("[T] clock=%.2f guests=%d money=%d" % [w.day_cycle.clock, w.day_cycle.guests.size(), GameState.money])
	check(w.day_cycle.guests.size() > 0, "guests spawned")
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
	print("[T] DONE failures=%d %s" % [failures.size(), failures])
	get_tree().quit(1 if failures.size() > 0 else 0)


## Opens every panel, drives build mode, shoving, interactions and the story.
func _sweep() -> void:
	var case: PlacedObject = w.museum.objects_of("display_case")[0]
	var pods := w.museum.objects_of("mega_podium")
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
			w.player.start_dig(n)
			check(w.player.digging, "player started digging")
			await _wait(3.0)
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
