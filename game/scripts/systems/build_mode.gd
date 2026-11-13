class_name BuildMode
extends Node3D
## Top-down Build Mode: the camera snaps to an orthographic view of the
## floor plan; place / rotate / remove exhibits on the grid; buy expansions.

const GRID_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform vec2 cells = vec2(5.0, 4.0);
void fragment() {
	vec2 g = fract(UV * cells);
	float l = step(g.x, 0.025) + step(0.975, g.x) + step(g.y, 0.025) + step(0.975, g.y);
	ALBEDO = vec3(1.0, 0.97, 0.85);
	ALPHA = clamp(l, 0.0, 1.0) * 0.55;
}
"""

var active := false
var cam: Camera3D
var ghost: Node3D
var ghost_type := ""
var rot := 2
var cell := Vector2i.ZERO
var selected := "display_case"
var grid_mesh: MeshInstance3D
var ui: Control
var info: Label
var money_lbl: Label
var items_box: HBoxContainer
var cat_box: HBoxContainer
var expand_btn: Button
var category := "Exhibits"
var _pad_t := 0.0
var _zoom := 1.0


func _ready() -> void:
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation = Vector3(-PI * 0.5, 0, 0)
	cam.far = 200.0
	add_child(cam)
	grid_mesh = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	grid_mesh.mesh = pm
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GRID_SHADER
	sm.shader = sh
	grid_mesh.material_override = sm
	grid_mesh.visible = false
	add_child(grid_mesh)


func museum() -> Museum:
	return World.instance.museum


func toggle() -> void:
	if active:
		exit()
	else:
		enter()


func enter() -> void:
	if GameState.phase != GameState.Phase.PREP:
		Events.say("Build Mode is available during the Prep phase (before you open).", UIKit.CORAL)
		Audio.sfx("error")
		return
	active = true
	World.instance.player.locked = true
	cell = museum().entrance() + Vector2i(0, 1)
	_fit_camera()
	cam.current = true
	grid_mesh.visible = true
	_build_ui()
	_select(selected)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.sfx("page")


func exit() -> void:
	active = false
	cam.current = false
	World.instance.player.camera.current = true
	World.instance.player.locked = false
	grid_mesh.visible = false
	if ghost:
		ghost.queue_free()
		ghost = null
	if ui:
		ui.queue_free()
		ui = null
	World.instance.ui.refresh_mouse()


func _fit_camera() -> void:
	var m := museum()
	var c := m.center()
	cam.position = Vector3(c.x, 45.0, c.z + 2.5)
	cam.size = maxf(m.D * Museum.CELL + 9.0, (m.W * Museum.CELL + 6.0) * 0.6) * _zoom
	var pm: PlaneMesh = grid_mesh.mesh
	pm.size = Vector2(m.W * Museum.CELL, m.D * Museum.CELL)
	grid_mesh.position = Vector3(c.x, 0.06, c.z)
	(grid_mesh.material_override as ShaderMaterial).set_shader_parameter("cells", Vector2(m.W, m.D))

# --------------------------------------------------------------------- ui ---
func _build_ui() -> void:
	if ui:
		ui.queue_free()
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UIKit.theme()
	World.instance.ui.add_child(ui)
	var top := UIKit.card()
	top.position = Vector2(20, 16)
	ui.add_child(top)
	var tv := UIKit.vbox(4)
	top.add_child(tv)
	tv.add_child(UIKit.label("BUILD MODE  -  %s place   %s remove   %s rotate   %s/%s cycle   %s exit" % [
		Settings.prompt("build_place"), Settings.prompt("build_remove"), Settings.prompt("rotate"),
		Settings.prompt("build_prev"), Settings.prompt("build_next"), Settings.prompt("build_mode")], 17, UIKit.TEXT, true))
	money_lbl = UIKit.label("", 17)
	tv.add_child(money_lbl)
	info = UIKit.label("", 16, UIKit.MUTED)
	info.custom_minimum_size = Vector2(620, 0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(info)
	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -150
	bottom.offset_left = 20
	bottom.offset_right = -20
	bottom.offset_bottom = -14
	ui.add_child(bottom)
	var bv := UIKit.vbox(6)
	bottom.add_child(bv)
	cat_box = UIKit.hbox(6)
	bv.add_child(cat_box)
	for c in DB.BUILD_CATS:
		var cb := UIKit.button(c, _set_category.bind(c), 0, UIKit.ACCENT if c == category else Color("8a8478"))
		cat_box.add_child(cb)
	cat_box.add_child(UIKit.expand(Control.new()))
	expand_btn = UIKit.button("Expand Museum", _try_expand, 0, UIKit.CORAL)
	cat_box.add_child(expand_btn)
	cat_box.add_child(UIKit.button("Done", exit, 0, UIKit.CORAL))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 66)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bv.add_child(sc)
	items_box = UIKit.hbox(6)
	sc.add_child(items_box)
	_refresh_items()


func _set_category(c: String) -> void:
	category = c
	_refresh_items()


func _refresh_items() -> void:
	if items_box == null:
		return
	UIKit.clear(items_box)
	var i := 0
	for c in cat_box.get_children():
		if c is Button and i < DB.BUILD_CATS.size():
			UIKit.style_button(c, "btn_teal" if DB.BUILD_CATS[i] == category else "btn_grey")
			i += 1
	for id in DB.BUILD.keys():
		var d: Dictionary = DB.BUILD[id]
		if d["cat"] != category:
			continue
		var lock := lock_reason(id)
		var b := UIKit.button("%s\n%s" % [d["name"], UIKit.money_text(int(d["cost"]))], _select.bind(id), 150)
		b.custom_minimum_size = Vector2(170, 60)
		b.tooltip_text = d["desc"] + ("\nLOCKED: " + lock if lock != "" else "")
		b.add_theme_font_size_override("font_size", 14)
		if lock != "":
			UIKit.style_button(b, "btn_grey")
			b.icon = UIKit.icon_tex("lock", 22)
			b.disabled = true
		elif GameState.money < int(d["cost"]):
			# can't afford it: greyed out and unclickable
			UIKit.style_button(b, "btn_grey")
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.6)
			b.tooltip_text += "
Not enough cash (%s)." % UIKit.money_text(int(d["cost"]))
		elif id == selected:
			UIKit.style_button(b, "btn_gold")
		items_box.add_child(b)
	_update_info()


func lock_reason(id: String) -> String:
	var d: Dictionary = DB.BUILD[id]
	if d["lic"] != "" and not GameState.has_skill(d["lic"]):
		return "Needs skill: " + String(DB.SKILLS[d["lic"]]["name"])
	if GameState.half_stars < int(d["stars"]):
		return "Needs %s" % GameState.star_text(int(d["stars"]))
	return ""


func _select(id: String) -> void:
	selected = id
	category = DB.BUILD[id]["cat"]
	if ghost:
		ghost.queue_free()
		ghost = null
	ghost_type = id
	ghost = Art.model(DB.BUILD[id]["model"])
	Art.strip_collision(ghost)
	add_child(ghost)
	_refresh_items_if_needed()
	_update_ghost()


func _refresh_items_if_needed() -> void:
	if items_box and items_box.get_child_count() > 0:
		_refresh_items()


func _update_info() -> void:
	if info == null:
		return
	var d: Dictionary = DB.BUILD[selected]
	var err := museum().can_place(selected, cell, rot)
	var lock := lock_reason(selected)
	var s := "%s - %s. %s" % [d["name"], UIKit.money_text(int(d["cost"])), d["desc"]]
	if lock != "":
		s += "\nLOCKED: " + lock
	elif err != "":
		s += "\n" + err
	info.text = s
	money_lbl.text = "Cash: %s     Floor: %dx%d" % [UIKit.money_text(GameState.money), museum().W, museum().D]
	var lvl := GameState.museum_level
	if lvl + 1 < DB.MUSEUM_SIZES.size():
		var nsz: Vector2i = DB.MUSEUM_SIZES[lvl + 1]
		var cost: int = DB.EXPANSION_COST[lvl + 1]
		expand_btn.text = "Expand to %dx%d (%s)" % [nsz.x, nsz.y, UIKit.money_text(cost)]
		expand_btn.disabled = not GameState.has_skill("expand_%d" % (lvl + 1))
		expand_btn.tooltip_text = "Requires skill: Expansion Permit %s" % ["I", "II", "III"][lvl] if expand_btn.disabled else "Bigger floor plan. Can be financed with a loan."
	else:
		expand_btn.text = "Max size"
		expand_btn.disabled = true


func _update_ghost() -> void:
	if ghost == null:
		return
	var m := museum()
	var cells := Museum.footprint(selected, cell, rot)
	ghost.position = m.footprint_center(cells) + Vector3(0, 0.03, 0)
	ghost.rotation.y = rot * PI * 0.5
	var ok := m.can_place(selected, cell, rot) == "" and lock_reason(selected) == "" and GameState.money >= int(DB.BUILD[selected]["cost"])
	Art.ghostify(ghost, Color(0.3, 1.0, 0.45, 0.45) if ok else Color(1.0, 0.3, 0.25, 0.45))
	_update_info()

# ------------------------------------------------------------------ input ---
func _unhandled_input(event: InputEvent) -> void:
	if not active or World.instance.ui.has_panel():
		return
	if event is InputEventMouseMotion:
		_mouse_cell(event.position)
	elif event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_zoom = clampf(_zoom + (-0.08 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.08), 0.6, 1.5)
		_fit_camera()
	if event.is_action_pressed("build_place"):
		_place()
	elif event.is_action_pressed("build_remove"):
		_remove()
	elif event.is_action_pressed("rotate"):
		rot = (rot + 1) % 4
		Audio.sfx("click")
		_update_ghost()
	elif event.is_action_pressed("build_next") or event.is_action_pressed("build_prev"):
		var ids: Array = []
		for id in DB.BUILD.keys():
			if lock_reason(id) == "":
				ids.append(id)
		if not ids.is_empty():
			var i := ids.find(selected)
			i = (i + (1 if event.is_action_pressed("build_next") else -1) + ids.size()) % ids.size()
			_select(ids[i])
	elif event.is_action_pressed("build_mode") or event.is_action_pressed("pause"):
		exit()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not active:
		return
	_pad_t -= delta
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if v.length() > 0.5 and _pad_t <= 0.0:
		_pad_t = 0.16
		cell += Vector2i(roundi(v.x), roundi(v.y))
		var m := museum()
		cell = Vector2i(clampi(cell.x, 0, m.W - 1), clampi(cell.y, 0, m.D - 1))
		_update_ghost()


func _mouse_cell(screen: Vector2) -> void:
	var o := cam.project_ray_origin(screen)
	var n := cam.project_ray_normal(screen)
	if absf(n.y) < 0.001:
		return
	var t := -o.y / n.y
	var p := o + n * t
	var c := museum().world_to_cell(p)
	var s: Vector2i = DB.BUILD[selected]["size"]
	if rot % 2 == 1:
		s = Vector2i(s.y, s.x)
	c -= Vector2i((s.x - 1) / 2, (s.y - 1) / 2)
	if c != cell:
		cell = c
		_update_ghost()


func _place() -> void:
	var lock := lock_reason(selected)
	if lock != "":
		Events.say(lock, UIKit.CORAL)
		Audio.sfx("error")
		return
	var err := museum().can_place(selected, cell, rot)
	if err != "":
		Events.say(err, UIKit.CORAL)
		Audio.sfx("error")
		return
	var cost := int(DB.BUILD[selected]["cost"])
	if not GameState.try_spend(cost, "Construction"):
		Events.say("Not enough cash (%s)." % UIKit.money_text(cost), UIKit.CORAL)
		Audio.sfx("error")
		return
	var o := museum().place(selected, cell, rot)
	Audio.sfx("register")
	Events.say("Built %s." % DB.BUILD[selected]["name"], UIKit.GOOD)
	if selected == "display_case" and not GameState.free_fossils().is_empty():
		Events.open_panel.emit("exhibit", o)
	elif selected == "mega_podium":
		Events.open_panel.emit("podium", o)
	_refresh_items()
	_update_ghost()


func _remove() -> void:
	var o := museum().object_at(cell)
	if o == null:
		for c in Museum.footprint(selected, cell, rot):
			o = museum().object_at(c)
			if o:
				break
	if o == null:
		return
	var refund := int(DB.BUILD[o.type]["cost"]) / 2
	museum().remove(o)
	if refund > 0:
		GameState.earn(refund, "Refunds")
	Audio.sfx("crack")
	Events.say("Removed %s (+%s refund)." % [o.def["name"], UIKit.money_text(refund)], Color.WHITE)
	_refresh_items()
	_update_ghost()


func _try_expand() -> void:
	var lvl := GameState.museum_level
	if lvl + 1 >= DB.MUSEUM_SIZES.size():
		return
	var cost: int = DB.EXPANSION_COST[lvl + 1]
	if GameState.money >= cost:
		GameState.charge(cost, "Expansion")
		_do_expand()
	else:
		var need := cost - maxi(GameState.money, 0)
		Events.open_panel.emit("choice", {
			"title": "Finance the expansion?",
			"text": "The expansion costs %s. You can take an expansion loan of %s, repaid with 15%% interest over 10 days (%s/day)." % [UIKit.money_text(cost), UIKit.money_text(need), UIKit.money_text(int(ceil(need * 1.15 / 10.0)))],
			"options": [
				["Take the loan", _expand_with_loan.bind(need, cost)],
				["Not now", Callable()],
			],
		})


func _expand_with_loan(need: int, cost: int) -> void:
	GameState.take_loan(need, 10, "Expansion loan")
	GameState.charge(cost, "Expansion")
	_do_expand()


func _do_expand() -> void:
	museum().expand()
	World.instance.day_cycle.spawn_staff()
	Audio.sfx("fanfare")
	Events.say("Museum expanded to %dx%d!" % [museum().W, museum().D], UIKit.GOLD)
	_fit_camera()
	cell = museum().entrance() + Vector2i(0, 1)
	_update_ghost()
