extends Node3D
## Main menu: a small 3D diorama of the cove with an orbiting camera, plus
## Continue / New Game (10 slots) / Load / Settings / Quit.

## Orbit radius / height / speed of the menu camera.
@export var orbit_radius: float = 15.0
@export var orbit_height: float = 5.5
@export var orbit_speed: float = 0.12
var cam: Camera3D
var ui: CanvasLayer
var root: Control
var menu_box: VBoxContainer
var overlay: Control
var _t := 0.0


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_scene()
	_build_ui()
	Audio.play_music("prep")
	var args := OS.get_cmdline_user_args()
	if args.has("--autotest") or args.has("--shots"):
		call_deferred("_start_new", 9)
	elif args.has("--menushot"):
		_menushot(args)


func _menushot(args: PackedStringArray) -> void:
	var out := "user://shots"
	for a in args:
		if a.begins_with("--out="):
			out = a.substr(6)
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/00_main_menu.png")
	_slots(true)
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/00b_slots.png")
	_settings()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/00c_settings.png")
	get_tree().quit()


## The diorama (sky, sun, shore, sea, podium skeleton, palms, cliffs) is placed in
## the editor in res://scenes/main_menu.tscn; only the camera orbit is scripted.
func _build_scene() -> void:
	Art.prepare(self)
	cam = $OrbitCamera


func _process(delta: float) -> void:
	_t += delta * orbit_speed
	cam.position = Vector3(sin(_t) * orbit_radius, orbit_height + sin(_t * 0.7) * 0.8, cos(_t) * orbit_radius + 2.0)
	cam.look_at(Vector3(0, 2.0, -1.0))

# --------------------------------------------------------------------- ui ---
## The menu UI (logo, button panel, tagline) is laid out in the editor under
## MenuUI/Root in res://scenes/main_menu.tscn; this only wires the buttons.
func _build_ui() -> void:
	root = $MenuUI/Root
	menu_box = $MenuUI/Root/Column/MenuPanel/Buttons
	var cont: Button = menu_box.get_node("Continue")
	var recent := SaveManager.most_recent_slot()
	if recent >= 0:
		var meta := SaveManager.slot_meta(recent)
		cont.text = "Continue  (Slot %d, Day %d)" % [recent + 1, int(meta.get("day", 1))]
	else:
		cont.disabled = true
	cont.pressed.connect(UIKit._btn_pressed.bind(_continue))
	(menu_box.get_node("NewGame") as Button).pressed.connect(UIKit._btn_pressed.bind(_slots.bind(true)))
	(menu_box.get_node("LoadGame") as Button).pressed.connect(UIKit._btn_pressed.bind(_slots.bind(false)))
	(menu_box.get_node("Settings") as Button).pressed.connect(UIKit._btn_pressed.bind(_settings))
	(menu_box.get_node("Quit") as Button).pressed.connect(UIKit._btn_pressed.bind(_quit))
	UIKit.focus_first(menu_box)


func _continue() -> void:
	var s := SaveManager.most_recent_slot()
	if s >= 0 and SaveManager.load_slot(s):
		_go()


func _settings() -> void:
	var sp := SettingsPanel.create(_close_overlay)
	_show_overlay(sp)


func _show_overlay(c: Control) -> void:
	_close_overlay()
	overlay = c
	root.add_child(c)
	UIKit.focus_first(c)


func _close_overlay() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null
	UIKit.focus_first(menu_box)


func _slots(new_game: bool) -> void:
	var m := UIKit.modal("New Game - choose a save slot" if new_game else "Load Game", 760, 0, _close_overlay)
	var body: VBoxContainer = m["body"]
	var metas := SaveManager.list_slots()
	for i in range(metas.size()):
		var meta: Dictionary = metas[i]
		var h := UIKit.hbox(8)
		body.add_child(h)
		var desc := "Slot %d  -  empty" % (i + 1)
		if not meta.is_empty():
			desc = "Slot %d  -  Day %d  |  %s  |  %s  |  Act %d  |  %s" % [i + 1, int(meta.get("day", 1)), UIKit.money_text(int(meta.get("money", 0))),
				GameState.star_text(int(meta.get("half_stars", 0))), int(meta.get("act", 1)), String(meta.get("stamp", ""))]
		h.add_child(UIKit.expand(UIKit.label(desc, 16, UIKit.TEXT if not meta.is_empty() else UIKit.MUTED, true)))
		if new_game:
			h.add_child(UIKit.button("Overwrite" if not meta.is_empty() else "Start", _confirm_new.bind(i, not meta.is_empty()), 120, UIKit.CORAL if not meta.is_empty() else UIKit.GOOD))
		else:
			var lb := UIKit.button("Load", _load.bind(i), 100, UIKit.GOOD)
			lb.disabled = meta.is_empty()
			h.add_child(lb)
			if not meta.is_empty():
				h.add_child(UIKit.button("Delete", _delete.bind(i), 0, UIKit.CORAL))
	_show_overlay(m["root"])


func _confirm_new(i: int, occupied: bool) -> void:
	if not occupied:
		_start_new(i)
		return
	var m := UIKit.modal("Overwrite slot %d?" % (i + 1), 520, 0, _close_overlay)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label("The existing save in this slot will be replaced.", 17))
	body.add_child(UIKit.button("Yes, start a new game", _start_new.bind(i), 0, UIKit.CORAL))
	_show_overlay(m["root"])


func _start_new(i: int) -> void:
	GameState.reset()
	GameState.slot = i
	if OS.get_cmdline_user_args().has("--autotest") or OS.get_cmdline_user_args().has("--shots"):
		GameState.flags["intro"] = true
	SaveManager.save(i)
	_go()


func _load(i: int) -> void:
	if SaveManager.load_slot(i):
		_go()


func _delete(i: int) -> void:
	SaveManager.delete_slot(i)
	_slots(false)


func _go() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _quit() -> void:
	get_tree().quit()
