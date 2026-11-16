class_name LookShots
extends Node
## Visual QA: `godot --path game -- --look --out=DIR` walks the camera to a list
## of spots (tunnels, bus stop, doors, barriers, kiosk, grass, office...) and
## saves a screenshot of each, plus first-person tool poses and NPC close-ups.

var w: World
var out_dir := "user://look"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	w = World.instance
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--out="):
			out_dir = String(a).substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Events.dialog_requested.connect(func(_l: Array) -> void: call_deferred("_skip"))
	run()


func _skip() -> void:
	w.ui.dialog_queue.clear()
	w.ui._next_line()


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, n])
	print("[L] ", n)


func look(n: String, pos: Vector3, at: Vector3, settle: float = 0.6) -> void:
	var p := w.player
	p.global_position = pos
	p.velocity = Vector3.ZERO
	var eye := pos + Vector3(0, p.EYE, 0)
	var d := at - eye
	p.cam_yaw = atan2(-d.x, -d.z)
	p.cam_pitch = atan2(d.y, Vector2(d.x, d.z).length())
	await _wait(settle)
	await shot(n)


func run() -> void:
	await _wait(1.5)
	w.ui.close_panel()
	GameState.half_stars = 6
	# hide the HUD toasts for clean pictures
	await look("a_street_east_tunnel", Vector3(16, 0.1, -29.2), Vector3(29, 3, -33))
	await look("b_street_west_tunnel", Vector3(-16, 0.1, -37.0), Vector3(-29, 3, -33))
	await look("c_bus_stop", Vector3(-12.5, 0.1, -31.0), Vector3(-16.2, 1.6, -28.2))
	await look("d_museum_door", Vector3(0.6, 0.1, -25.6), Vector3(0, 1.1, -22.4))
	await look("e_barrier_cliffs", Vector3(19, 0.1, 6), Vector3(25, 1.2, 6))
	await look("f_barrier_reef", Vector3(-19, 0.1, 18), Vector3(-25, 1.2, 14))
	await look("g_grass_edge", Vector3(-3, 0.1, -6.5), Vector3(-5.5, 0, -10))
	await look("h_grass_edge2", Vector3(8, 0.1, -6.5), Vector3(10, 0, -10.5))
	# fact-check kiosk close-up
	var spot := Vector2i(-1, -1)
	for y in range(w.museum.D):
		for x in range(w.museum.W):
			if spot.x < 0 and w.museum.can_place("plaque_checker", Vector2i(x, y), 2) == "":
				spot = Vector2i(x, y)
	if spot.x >= 0:
		var k := w.museum.place("plaque_checker", spot, 2)
		await look("i_kiosk", k.global_position + Vector3(0.9, 0.0, 1.6), k.global_position + Vector3(0, 1.15, 0))
	# office + J-Mail
	GameState.skills["expand_1"] = true
	GameState.skills["expand_2"] = true
	GameState.skills["expand_3"] = true
	w._on_expansion(3)
	w.ui.dialog_queue.clear()
	w.ui._next_line()
	await _wait(0.3)
	if w.office:
		await look("j_office", w.office.global_position + w.office.global_transform.basis.z * 2.2 + Vector3(0.8, 0, 0), w.office.global_position + Vector3(0, 1.0, 0))
		w.office._on_use()
		await _wait(0.6)
		await shot("k_office_seated")
		w.office.stand_up()
	# first-person tool poses (held + mid-use)
	GameState.tools["pick"] = 1
	GameState.tools["detector"] = 1
	GameState.hotbar[1] = {"t": "tool", "kind": "pick"}
	GameState.hotbar[2] = {"t": "tool", "kind": "detector"}
	await look("l_fp_hold_pick_view", Vector3(0, 0.1, 10), Vector3(0, 0.4, 16))
	GameState.select_slot(1)
	w.player._refresh_held()
	await _wait(0.6)
	await shot("m_fp_hold_pick")
	w.player._oneshot_t = 30.0
	var mine_len := w.player.arm_anim.get_animation("AN_FP_Mine").length
	for k in [["n0_mine_a", 0.0], ["n0_mine_b", 0.22], ["n0_mine_c", 0.36], ["n0_mine_d", 0.5], ["n0_mine_e", 0.59], ["n0_mine_f", 0.64], ["n0_mine_g", 0.69], ["n0_mine_h", 0.79]]:
		w.player.arm_anim.play("AN_FP_Mine")
		w.player.arm_anim.seek(mine_len * float(k[1]), true)
		w.player.arm_anim.pause()
		await _wait(0.15)
		await shot(String(k[0]))
	w.player.arm_anim.play()
	w.player._oneshot_t = 0.0
	# the full radio log (V): long messages must be readable in full
	for msg in ["A guest is waiting at the Amber Lemonade Stand - serve them before they give up and leave a bad review!",
			"The restroom needs cleaning! Send a janitor or grab a mop yourself before the next visitors complain.",
			"The shoplifter got away with merchandise from the gift shop! Hire security to catch them next time.",
			"A Museum Critic just arrived (Pemberton Quill). Keep it spotless!"]:
		Events.radio(msg, "info", Vector3.ZERO)
	w.ui.open("radio")
	await _wait(0.5)
	await shot("p_radio_log")
	w.ui.close_panel()
	GameState.select_slot(2)
	w.player._refresh_held()
	await _wait(0.8)
	await shot("p_fp_detector_a")
	await _wait(0.45)
	await shot("q_fp_detector_b")
	GameState.select_slot(0)
	w.player._refresh_held()
	await _wait(0.8)
	w.player.arm_anim.play("AN_FP_Dig")
	w.player._oneshot_t = 5.0
	await _wait(0.4)
	await shot("r_fp_dig")
	w.player._oneshot_t = 0.0
	# NPC heads with hats / hair
	var base := Vector3(0, 0, -27.0)
	var looks := [["Hat_Safari"], ["Hat_Cap"], ["Hat_Fedora", "Hair_Long"], ["Hat_Top"], ["Hair_Bun", "Hat_Cap"], []]
	var vis: Array = []
	for i in range(looks.size()):
		var lk := CharVisual.random_look()
		lk["acc"] = looks[i]
		var v := CharVisual.new()
		w.add_child(v)
		v.setup(lk)
		v.global_position = base + Vector3(-2.5 + i * 1.0, 0, 0)
		v.rotation.y = PI
		vis.append(v)
	await look("s_npc_hats", Vector3(0, 0.1, -24.6), Vector3(0, 1.55, -27))
	for v in vis:
		v.rotation.y = 0.0
	await look("t_npc_hats_back", Vector3(0, 0.1, -29.4), Vector3(0, 1.55, -27))
	for v in vis:
		v.queue_free()
	# traffic: a bus at the stop and a car dropping visitors off
	GameState.phase = GameState.Phase.OPEN
	w.day_cycle.open_museum()
	w.day_cycle.arrive_by_car(["tourist", "kid", "tourist"])
	await _wait(5.0)
	await look("u_car_dropoff", Vector3(9, 0.1, -27.5), Vector3(0, 1.0, -31))
	var g := w.day_cycle.spawn_guest("tourist", Vector3(-15, 0, -28.5))
	g._leave()
	g.global_position = Vector3(-15.5, 0, -28.8)
	g.path.clear()
	g.path.append(w.traffic.stop_spot(g))
	g.state = Guest.S.LEAVE
	g.inside = false
	await _wait(14.0)
	await look("v_bus_pickup", Vector3(-8, 0.1, -27.2), Vector3(-18, 1.4, -30.5))
	await _wait(2.0)
	await shot("w_bus_pickup_2")
	get_tree().quit()
