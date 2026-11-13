extends Node
## Persistent settings (audio / gameplay / graphics / controls), InputMap setup,
## live remapping and keyboard <-> gamepad prompt switching.

signal changed
signal device_changed(using_pad: bool)
signal remapped(action: String)

const PATH := "user://settings.cfg"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const WINDOW_MODES := ["Windowed", "Fullscreen", "Exclusive Fullscreen"]
const SHADOW_LEVELS := ["Off", "Low", "High"]
const PAD_BUTTONS := ["A", "B", "X", "Y", "Back", "Guide", "Start", "L3", "R3", "LB", "RB", "D-Up", "D-Down", "D-Left", "D-Right"]
const PAD_AXES := ["LS X", "LS Y", "RS X", "RS Y", "LT", "RT"]

## Default bindings. kb/kb2 = keyboard or mouse, pad = gamepad.
var ACTIONS := {
	"move_forward": {"label": "Move Forward", "kb": {"type": "key", "code": KEY_W}, "kb2": {"type": "key", "code": KEY_UP}, "pad": {"type": "axis", "axis": JOY_AXIS_LEFT_Y, "dir": -1.0}},
	"move_back": {"label": "Move Back", "kb": {"type": "key", "code": KEY_S}, "kb2": {"type": "key", "code": KEY_DOWN}, "pad": {"type": "axis", "axis": JOY_AXIS_LEFT_Y, "dir": 1.0}},
	"move_left": {"label": "Move Left", "kb": {"type": "key", "code": KEY_A}, "kb2": {"type": "key", "code": KEY_LEFT}, "pad": {"type": "axis", "axis": JOY_AXIS_LEFT_X, "dir": -1.0}},
	"move_right": {"label": "Move Right", "kb": {"type": "key", "code": KEY_D}, "kb2": {"type": "key", "code": KEY_RIGHT}, "pad": {"type": "axis", "axis": JOY_AXIS_LEFT_X, "dir": 1.0}},
	"look_left": {"label": "Camera Left", "kb": {"type": "key", "code": KEY_J}, "pad": {"type": "axis", "axis": JOY_AXIS_RIGHT_X, "dir": -1.0}},
	"look_right": {"label": "Camera Right", "kb": {"type": "key", "code": KEY_L}, "pad": {"type": "axis", "axis": JOY_AXIS_RIGHT_X, "dir": 1.0}},
	"look_up": {"label": "Camera Up", "kb": {"type": "key", "code": KEY_I}, "pad": {"type": "axis", "axis": JOY_AXIS_RIGHT_Y, "dir": -1.0}},
	"look_down": {"label": "Camera Down", "kb": {"type": "key", "code": KEY_K}, "pad": {"type": "axis", "axis": JOY_AXIS_RIGHT_Y, "dir": 1.0}},
	"sprint": {"label": "Sprint", "kb": {"type": "key", "code": KEY_SHIFT}, "pad": {"type": "button", "code": JOY_BUTTON_LEFT_SHOULDER}},
	"jump": {"label": "Jump", "kb": {"type": "key", "code": KEY_SPACE}, "pad": {"type": "button", "code": JOY_BUTTON_A}},
	"interact": {"label": "Interact / Pick Up", "kb": {"type": "key", "code": KEY_E}, "pad": {"type": "button", "code": JOY_BUTTON_X}},
	"use_item": {"label": "Use Held Item / Shove", "kb": {"type": "mouse", "code": MOUSE_BUTTON_LEFT}, "pad": {"type": "axis", "axis": JOY_AXIS_TRIGGER_RIGHT, "dir": 1.0}},
	"drop_item": {"label": "Drop Held Item", "kb": {"type": "key", "code": KEY_Q}, "pad": {"type": "button", "code": JOY_BUTTON_Y}},
	"trash_item": {"label": "Trash Held Item", "kb": {"type": "key", "code": KEY_X}, "pad": {"type": "button", "code": JOY_BUTTON_RIGHT_STICK}},
	"hotbar_next": {"label": "Next Hotbar Slot", "kb": {"type": "mouse", "code": MOUSE_BUTTON_WHEEL_DOWN}, "pad": {"type": "button", "code": JOY_BUTTON_RIGHT_SHOULDER}},
	"hotbar_prev": {"label": "Previous Hotbar Slot", "kb": {"type": "mouse", "code": MOUSE_BUTTON_WHEEL_UP}, "pad": {"type": "button", "code": JOY_BUTTON_LEFT_STICK}},
	"build_mode": {"label": "Build Mode", "kb": {"type": "key", "code": KEY_B}, "pad": {"type": "button", "code": JOY_BUTTON_BACK}},
	"skill_tree": {"label": "Upgrade Tree", "kb": {"type": "key", "code": KEY_T}, "pad": {"type": "button", "code": JOY_BUTTON_DPAD_UP}},
	"field_guide": {"label": "Guide", "kb": {"type": "key", "code": KEY_G}, "pad": {"type": "button", "code": JOY_BUTTON_DPAD_LEFT}},
	"inventory": {"label": "Inventory", "kb": {"type": "key", "code": KEY_TAB}, "pad": {"type": "button", "code": JOY_BUTTON_DPAD_DOWN}},
	"management": {"label": "Management", "kb": {"type": "key", "code": KEY_M}, "pad": {"type": "button", "code": JOY_BUTTON_DPAD_RIGHT}},
	"pause": {"label": "Pause", "kb": {"type": "key", "code": KEY_ESCAPE}, "pad": {"type": "button", "code": JOY_BUTTON_START}},
	"rotate": {"label": "Rotate (Build)", "kb": {"type": "key", "code": KEY_R}, "pad": {"type": "button", "code": JOY_BUTTON_RIGHT_SHOULDER}},
	"build_place": {"label": "Place (Build)", "kb": {"type": "mouse", "code": MOUSE_BUTTON_LEFT}, "pad": {"type": "button", "code": JOY_BUTTON_A}},
	"build_remove": {"label": "Remove (Build)", "kb": {"type": "mouse", "code": MOUSE_BUTTON_RIGHT}, "pad": {"type": "button", "code": JOY_BUTTON_X}},
	"build_prev": {"label": "Prev Item (Build)", "kb": {"type": "key", "code": KEY_Z}, "pad": {"type": "axis", "axis": JOY_AXIS_TRIGGER_LEFT, "dir": 1.0}},
	"build_next": {"label": "Next Item (Build)", "kb": {"type": "key", "code": KEY_C}, "pad": {"type": "axis", "axis": JOY_AXIS_TRIGGER_RIGHT, "dir": 1.0}},
}
const REMAPPABLE := ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "interact", "use_item", "drop_item", "trash_item", "hotbar_next", "hotbar_prev",
	"build_mode", "skill_tree", "field_guide", "inventory", "management", "pause", "rotate", "build_place", "build_remove", "build_prev", "build_next",
	"look_left", "look_right", "look_up", "look_down"]

var values := {
	"master": 0.8, "music": 0.6, "sfx": 0.8,
	"auto_clean": false, "auto_deposit": true, "text_speed": 45.0, "day_minutes": 5.0, "sensitivity": 1.0, "invert_y": false,
	"resolution": 1, "window_mode": 0, "shadows": 2, "vsync": true,
}
var binds := {}  # action -> {"kb": {...}, "pad": {...}} overrides
var using_pad := false
var capture_action := ""
var capture_slot := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	load_settings()
	apply_all()


func _ensure_buses() -> void:
	for n in ["Music", "SFX"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")


func get_v(key: String) -> Variant:
	return values.get(key)


func set_v(key: String, v: Variant) -> void:
	values[key] = v
	apply_all()
	save_settings()
	changed.emit()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in values.keys():
		values[k] = cf.get_value("settings", k, values[k])
	var b = cf.get_value("input", "binds", {})
	if b is Dictionary:
		binds = b


func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in values.keys():
		cf.set_value("settings", k, values[k])
	cf.set_value("input", "binds", binds)
	cf.save(PATH)


func apply_all() -> void:
	_apply_audio()
	_apply_input()
	_apply_graphics()


func _apply_audio() -> void:
	for pair in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var idx := AudioServer.get_bus_index(pair[0])
		if idx >= 0:
			var lin: float = clampf(float(values[pair[1]]), 0.0, 1.0)
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(lin, 0.0001)))
			AudioServer.set_bus_mute(idx, lin <= 0.001)


func _apply_graphics() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := int(values["window_mode"])
	match mode:
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res: Vector2i = RESOLUTIONS[clampi(int(values["resolution"]), 0, RESOLUTIONS.size() - 1)]
			var screen := DisplayServer.screen_get_usable_rect()
			if res.x > screen.size.x or res.y > screen.size.y:
				res = Vector2i(int(screen.size.x * 0.9), int(screen.size.y * 0.9))
			if DisplayServer.window_get_size() != res:
				DisplayServer.window_set_size(res)
				DisplayServer.window_set_position(screen.position + (screen.size - res) / 2)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values["vsync"] else DisplayServer.VSYNC_DISABLED)
	var lvl := int(values["shadows"])
	RenderingServer.directional_shadow_atlas_set_size(2048 if lvl == 1 else 4096, true)


func shadows_enabled() -> bool:
	return int(values["shadows"]) > 0

# ------------------------------------------------------------------ input ---
func bind_for(action: String, slot: String) -> Dictionary:
	var o: Dictionary = binds.get(action, {})
	if o.has(slot):
		return o[slot]
	return ACTIONS[action].get(slot, {})


func _make_event(d: Dictionary) -> InputEvent:
	var t: String = d.get("type", "")
	if t == "key":
		var k := InputEventKey.new()
		k.physical_keycode = int(d["code"])
		return k
	if t == "mouse":
		var m := InputEventMouseButton.new()
		m.button_index = int(d["code"])
		return m
	if t == "button":
		var b := InputEventJoypadButton.new()
		b.button_index = int(d["code"])
		return b
	if t == "axis":
		var a := InputEventJoypadMotion.new()
		a.axis = int(d["axis"])
		a.axis_value = float(d["dir"])
		return a
	return null


func _apply_input() -> void:
	for action in ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.35)
		InputMap.action_erase_events(action)
		for slot in ["kb", "kb2", "pad"]:
			var d := bind_for(action, slot)
			if d.is_empty():
				continue
			var ev := _make_event(d)
			if ev:
				InputMap.action_add_event(action, ev)


func event_text(d: Dictionary) -> String:
	var t: String = d.get("type", "")
	match t:
		"key":
			return OS.get_keycode_string(int(d["code"]))
		"mouse":
			var names := {1: "LMB", 2: "RMB", 3: "MMB", 4: "Wheel Up", 5: "Wheel Down"}
			return names.get(int(d["code"]), "Mouse %d" % int(d["code"]))
		"button":
			var i := int(d["code"])
			return PAD_BUTTONS[i] if i < PAD_BUTTONS.size() else "Btn %d" % i
		"axis":
			var ax := int(d["axis"])
			var nm: String = PAD_AXES[ax] if ax < PAD_AXES.size() else "Axis %d" % ax
			if ax >= 4:
				return nm
			return nm + ("+" if float(d["dir"]) > 0 else "-")
	return "-"


func prompt(action: String) -> String:
	if not ACTIONS.has(action):
		return action
	var d := bind_for(action, "pad" if using_pad else "kb")
	return ("(%s)" if using_pad else "[%s]") % event_text(d)


func begin_capture(action: String, slot: String) -> void:
	capture_action = action
	capture_slot = slot


func reset_binds() -> void:
	binds = {}
	_apply_input()
	save_settings()
	remapped.emit("")


func _input(event: InputEvent) -> void:
	var pad_now := using_pad
	if event is InputEventJoypadButton:
		pad_now = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.45:
		pad_now = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad_now = false
	elif event is InputEventMouseMotion and event.relative.length() > 6.0:
		pad_now = false
	if pad_now != using_pad:
		using_pad = pad_now
		device_changed.emit(using_pad)
	if capture_action == "":
		return
	var d := {}
	if capture_slot == "kb":
		if event is InputEventKey and event.pressed:
			if event.physical_keycode == KEY_ESCAPE and capture_action != "pause":
				capture_action = ""
				remapped.emit("")
				get_viewport().set_input_as_handled()
				return
			d = {"type": "key", "code": int(event.physical_keycode)}
		elif event is InputEventMouseButton and event.pressed:
			d = {"type": "mouse", "code": int(event.button_index)}
	else:
		if event is InputEventJoypadButton and event.pressed:
			d = {"type": "button", "code": int(event.button_index)}
		elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
			d = {"type": "axis", "axis": int(event.axis), "dir": signf(event.axis_value)}
		elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			capture_action = ""
			remapped.emit("")
			get_viewport().set_input_as_handled()
			return
	if d.is_empty():
		return
	var o: Dictionary = binds.get(capture_action, {})
	o[capture_slot] = d
	binds[capture_action] = o
	var a := capture_action
	capture_action = ""
	_apply_input()
	save_settings()
	get_viewport().set_input_as_handled()
	remapped.emit(a)
