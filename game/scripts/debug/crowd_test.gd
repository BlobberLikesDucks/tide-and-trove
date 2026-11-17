class_name CrowdTest
extends Node
## Visitor behaviour check on a FRESH game (starter museum, nothing built):
## `godot --path game -- --crowd --out=DIR`. Opens the museum, fast-forwards,
## and logs what every visitor is doing and where they stand, so "everyone
## bunches up at the door" shows up as numbers (and a top-down screenshot).

var out_dir := "user://crowd"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	run.call_deferred()


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func run() -> void:
	var w := World.instance
	await _wait(1.5)
	for k in range(6):  # the new-game intro dialog holds time
		w.ui.dialog_queue.clear()
		w.ui._next_line()
		w.ui.close_panel()
		await _wait(0.3)
	get_tree().paused = false
	Settings.values["day_len"] = 3.0
	print("[CROWD] museum %dx%d objects=%d reachable=%d entrance=%s" % [w.museum.W, w.museum.D, w.museum.all_objects().size(), w.museum.reachable.size(), w.museum.entrance()])
	for o in w.museum.all_objects():
		print("[CROWD]   object %s at %s fossil=%s" % [o.type, o.cell, not o.fossil_entry().is_empty() if o.is_case() else "-"])
	# an early-game museum: one empty case, a bin, plus a vending machine
	for x in range(w.museum.W):
		for y in range(w.museum.D):
			if w.museum.objects_of("vending_machine").is_empty() and y >= 2 and w.museum.can_place("vending_machine", Vector2i(x, y), 0) == "":
				w.museum.place("vending_machine", Vector2i(x, y), 0)
	w.day_cycle.open_museum()
	print("[CROWD] phase after open: ", GameState.phase, " paused=", get_tree().paused)
	Engine.time_scale = 4.0
	for i in range(18):
		await _wait(1.5)
		if w.ui.dialog_panel.visible or w.ui.current:  # tutorial pop-ups pause the game
			print("[CROWD]   (dismissed a pop-up: %s)" % (w.ui.current_name if w.ui.current else "dialog"))
			w.ui.dialog_queue.clear()
			w.ui._next_line()
			if w.ui.current:
				w.ui.close_panel()
			get_tree().paused = false
		var states := {}
		var cells := {}
		for g in w.day_cycle.guests:
			if not is_instance_valid(g):
				continue
			var sn: String = Guest.S.keys()[g.state]
			states[sn] = int(states.get(sn, 0)) + 1
			if g.inside:
				var c: Vector2i = g.cur_cell()
				cells[c] = int(cells.get(c, 0)) + 1
		var biggest := 0
		for v in cells.values():
			biggest = maxi(biggest, int(v))
		print("[CROWD] t=%.0f clock=%.2f guests=%d spread=%d cells, max %d in one cell, trash=%d vending$=%d states=%s" % [i * 1.5 * 4.0, w.day_cycle.clock, w.day_cycle.guests.size(), cells.size(), biggest, w.museum.mess.filter(func(m): return m["kind"] == "trash").size(), int(GameState.ledger["income"].get("Vending machine", 0)), states])
	Engine.time_scale = 1.0
	# a shoplifter, close up
	var thief := w.day_cycle.spawn_guest("shoplifter", w.museum.cell_center(w.museum.entrance()) + Vector3(0, 0, 1.0))
	thief.state = Guest.S.BROWSE
	thief.timer = 99.0
	thief.inside = true
	var cam0 := Camera3D.new()
	w.add_child(cam0)
	cam0.global_position = thief.global_position + Vector3(0.6, 1.5, -1.9)
	cam0.look_at(thief.global_position + Vector3(0, 1.2, 0))
	thief.visual.rotation.y = atan2(-(cam0.global_position - thief.global_position).x, -(cam0.global_position - thief.global_position).z)
	cam0.current = true
	w.museum.set_roof_visible(false)
	await _wait(0.6)
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("shoplifter.png"))
	cam0.queue_free()
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.global_position = w.museum.center() + Vector3(0, 13, 6)
	cam.look_at(w.museum.center())
	cam.current = true
	w.museum.set_roof_visible(false)
	await _wait(0.5)
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join("crowd_top.png"))
	print("[CROWD] done")
	get_tree().quit()
