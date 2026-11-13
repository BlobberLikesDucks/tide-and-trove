class_name SettingsPanel
extends Control
## Modular settings UI: Audio / Gameplay / Graphics / Controls (remapping).

var on_close: Callable
var tabs: TabContainer
var _bind_buttons := {}


static func create(close_cb: Callable) -> SettingsPanel:
	var p := SettingsPanel.new()
	p.on_close = close_cb
	return p


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var m := UIKit.modal("Settings", 860, 600, _close)
	add_child(m["root"])
	var body: VBoxContainer = m["body"]
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(820, 520)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	_audio_tab()
	_gameplay_tab()
	_graphics_tab()
	_controls_tab()
	Settings.remapped.connect(_on_remapped)
	UIKit.focus_first(tabs)


func _close() -> void:
	Settings.capture_action = ""
	if on_close.is_valid():
		on_close.call()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if Settings.capture_action != "":
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()


func _tab(title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(sc)
	var v := UIKit.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return v


func _slider_row(parent: Control, label: String, key: String, mn: float, mx: float, step: float, fmt: String) -> void:
	var h := UIKit.hbox(12)
	parent.add_child(h)
	var l := UIKit.label(label, 18)
	l.custom_minimum_size = Vector2(250, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = float(Settings.get_v(key))
	s.custom_minimum_size = Vector2(340, 28)
	s.focus_mode = Control.FOCUS_ALL
	h.add_child(s)
	var val := UIKit.label(fmt % s.value, 18, UIKit.ACCENT, true)
	val.custom_minimum_size = Vector2(90, 0)
	h.add_child(val)
	s.value_changed.connect(_on_slider.bind(key, val, fmt))


func _on_slider(v: float, key: String, val: Label, fmt: String) -> void:
	val.text = fmt % v
	Settings.set_v(key, v)
	if key == "sfx":
		Audio.sfx("click")


func _check_row(parent: Control, label: String, key: String, tip: String) -> void:
	var c := CheckBox.new()
	c.text = label
	c.button_pressed = bool(Settings.get_v(key))
	c.tooltip_text = tip
	c.focus_mode = Control.FOCUS_ALL
	c.add_theme_font_size_override("font_size", 18)
	parent.add_child(c)
	c.toggled.connect(func(on: bool) -> void: Settings.set_v(key, on))
	parent.add_child(UIKit.label(tip, 14, UIKit.MUTED))


func _option_row(parent: Control, label: String, key: String, opts: Array) -> void:
	var h := UIKit.hbox(12)
	parent.add_child(h)
	var l := UIKit.label(label, 18)
	l.custom_minimum_size = Vector2(250, 0)
	h.add_child(l)
	var o := OptionButton.new()
	for t in opts:
		o.add_item(str(t))
	o.selected = int(Settings.get_v(key))
	o.custom_minimum_size = Vector2(300, 40)
	o.focus_mode = Control.FOCUS_ALL
	h.add_child(o)
	o.item_selected.connect(func(i: int) -> void: Settings.set_v(key, i))


func _audio_tab() -> void:
	var v := _tab("Audio")
	v.add_child(UIKit.spacer(6))
	_slider_row(v, "Master volume", "master", 0.0, 1.0, 0.05, "%.2f")
	_slider_row(v, "Music volume", "music", 0.0, 1.0, 0.05, "%.2f")
	_slider_row(v, "SFX volume", "sfx", 0.0, 1.0, 0.05, "%.2f")
	v.add_child(UIKit.label("Music shifts with the day: calm coastal acoustics while time is paused, an upbeat bustle once the doors open, and a reflective tune at sunset.", 15, UIKit.MUTED))


func _gameplay_tab() -> void:
	var v := _tab("Gameplay")
	v.add_child(UIKit.spacer(6))
	_check_row(v, "Auto-clean fossils in the lab", "auto_clean", "Adds a one-click Quick Clean (60% preservation) so you can skip the mini-game.")
	_check_row(v, "Auto-unload backpack", "auto_deposit", "Unload your backpack automatically when you enter the museum or Prep Lab.")
	_check_row(v, "Invert camera Y", "invert_y", "Flip vertical camera look.")
	_slider_row(v, "Text speed (chars/sec)", "text_speed", 10.0, 120.0, 5.0, "%.0f")
	_slider_row(v, "Open-phase length (minutes)", "day_minutes", 2.0, 12.0, 0.5, "%.1f")
	_slider_row(v, "Camera sensitivity", "sensitivity", 0.3, 2.5, 0.1, "%.1f")


func _graphics_tab() -> void:
	var v := _tab("Graphics")
	v.add_child(UIKit.spacer(6))
	var res: Array = []
	for r in Settings.RESOLUTIONS:
		res.append("%d x %d" % [r.x, r.y])
	_option_row(v, "Resolution", "resolution", res)
	_option_row(v, "Window mode", "window_mode", Settings.WINDOW_MODES)
	_option_row(v, "Shadow quality", "shadows", Settings.SHADOW_LEVELS)
	_check_row(v, "V-Sync", "vsync", "Synchronise frames with your monitor.")


func _controls_tab() -> void:
	var v := _tab("Controls")
	var head := UIKit.hbox(12)
	v.add_child(head)
	head.add_child(UIKit.expand(UIKit.label("Click a binding, then press a key / button. Esc cancels. Keyboard and gamepad switch automatically.", 15, UIKit.MUTED)))
	head.add_child(UIKit.button("Reset to defaults", Settings.reset_binds, 0, UIKit.CORAL))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	grid.add_child(UIKit.label("Action", 16, UIKit.ACCENT, true))
	grid.add_child(UIKit.label("Keyboard / Mouse", 16, UIKit.ACCENT, true))
	grid.add_child(UIKit.label("Gamepad", 16, UIKit.ACCENT, true))
	for a in Settings.REMAPPABLE:
		var l := UIKit.label(Settings.ACTIONS[a]["label"], 16)
		l.custom_minimum_size = Vector2(230, 0)
		grid.add_child(l)
		for slot in ["kb", "pad"]:
			var b := UIKit.button(Settings.event_text(Settings.bind_for(a, slot)), _begin.bind(a, slot), 220)
			b.custom_minimum_size = Vector2(220, 34)
			grid.add_child(b)
			_bind_buttons["%s|%s" % [a, slot]] = b


func _begin(action: String, slot: String) -> void:
	var b: Button = _bind_buttons["%s|%s" % [action, slot]]
	b.text = "Press %s..." % ("a key" if slot == "kb" else "a button")
	Settings.begin_capture(action, slot)


func _on_remapped(_a: String) -> void:
	for k in _bind_buttons.keys():
		var parts := String(k).split("|")
		(_bind_buttons[k] as Button).text = Settings.event_text(Settings.bind_for(parts[0], parts[1]))
