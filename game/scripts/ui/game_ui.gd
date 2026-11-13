class_name GameUI
extends CanvasLayer
## In-game UI: HUD, toasts, walkie-talkie alerts, dialog box, and routing for
## every modal panel (which pause the world while open). The layout lives in the
## editor scene res://scenes/ui/game_ui.tscn (Canva theme type variations); this
## script only fills it with live data.

const WALKIE_COLORS := {"threat": Color("ff7a6a"), "kid": Color("ffb36a"), "vip": Color("ffd75a"), "staff": Color("c8a2ff"), "mess": Color("e2c08a"), "info": Color("8dffb0")}
const NO_ESC := ["reviews", "ledger", "gameover", "trivia", "choice"]

@onready var hud: Control = $HUD
@onready var panel_layer: Control = $PanelLayer
var current: Control
var current_name := ""
var panels: Panels
@onready var dialog_panel: PanelContainer = $DialogPanel
@onready var dialog_name: Label = $DialogPanel/Rows/Speaker/Name
@onready var dialog_text: RichTextLabel = $DialogPanel/Rows/Text
@onready var dialog_hint: Label = $DialogPanel/Rows/Continue/Hint
var dialog_queue: Array = []
var dialog_chars := 0.0
@onready var toasts: VBoxContainer = $HUD/Toasts
@onready var walkie_panel: PanelContainer = $HUD/Walkie
@onready var walkie_list: VBoxContainer = $HUD/Walkie/Screen/Messages
@onready var prompt_panel: PanelContainer = $HUD/PromptPill
@onready var prompt_lbl: Label = $HUD/PromptPill/Text
@onready var objective_lbl: Label = $HUD/ObjectivePill/Text
@onready var day_lbl: Label = $HUD/StatusCard/Rows/Day/Value
@onready var money_lbl: Label = $HUD/StatusCard/Rows/Money/Value
@onready var up_lbl: Label = $HUD/StatusCard/Rows/UpgradePoints/Value
@onready var bag_lbl: Label = $HUD/StatusCard/Rows/Bag/Value
@onready var star_row: HBoxContainer = $HUD/RatingCard/Rows/Stars
@onready var quality_bar: ProgressBar = $HUD/RatingCard/Rows/Quality/Bar
@onready var quality_lbl: Label = $HUD/RatingCard/Rows/Quality/Value
@onready var pillar_bars := {"fun": $HUD/RatingCard/Rows/Fun/Bar, "decor": $HUD/RatingCard/Rows/Decor/Bar, "clean": $HUD/RatingCard/Rows/Clean/Bar}
@onready var ticket_lbl: Label = $HUD/RatingCard/Rows/Ticket/Value
@onready var hotbar_box: HBoxContainer = $HUD/HotbarArea/Slots
@onready var hotbar_name: Label = $HUD/HotbarArea/HeldName
var _hotbar_key := ""
@onready var detector_box: HBoxContainer = $HUD/HotbarArea/Detector
@onready var detector_bar: ProgressBar = $HUD/HotbarArea/Detector/Bar
@onready var hint_lbl: Label = $HUD/HotbarArea/Hints
@onready var crosshair: TextureRect = $HUD/Crosshair
var _hud_t := 0.0
var _detector := -1.0
var _last_half := -1


func _ready() -> void:
	panels = Panels.new(self)
	dialog_panel.gui_input.connect(_on_dialog_input)
	Events.toast.connect(_toast)
	Events.walkie.connect(_walkie)
	Events.prompt.connect(_on_prompt)
	Events.objective_changed.connect(_on_objective)
	Events.open_panel.connect(open)
	Events.dialog_requested.connect(_dialog)
	Events.game_over.connect(_on_game_over)
	Events.detector_ping.connect(_on_ping)
	Settings.device_changed.connect(_on_device)
	_refresh_hints()
	refresh_hud()
	refresh_mouse()


func world() -> World:
	return World.instance


func _on_objective(t: String) -> void:
	objective_lbl.text = t


func _on_game_over(r: String) -> void:
	open("gameover", r)


func _on_ping(s: float) -> void:
	_detector = s


func _on_device(_p: bool) -> void:
	_refresh_hints()

# -------------------------------------------------------------------- hud ---
func _item_icon(it: Dictionary) -> String:
	match String(it.get("t", "")):
		"tool":
			return {"shovel": "shovel", "pick": "pickaxe", "detector": "gear"}.get(String(it["kind"]), "gear")
		"gem", "geode":
			return "gem"
		"encased":
			return "bone"
		"trash":
			return "trash"
		"serve":
			return "coin"
	return "gem"


func _refresh_hotbar() -> void:
	var key := JSON.stringify(GameState.hotbar) + str(GameState.hotbar_sel)
	if key == _hotbar_key:
		return
	_hotbar_key = key
	UIKit.clear(hotbar_box)
	for i in range(GameState.hotbar.size()):
		var it: Dictionary = GameState.hotbar[i]
		var sel := i == GameState.hotbar_sel
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", UIKit.sb(Color(0.06, 0.09, 0.11, 0.72 if sel else 0.5), UIKit.GOLD if sel else Color(1, 1, 1, 0.35), 4 if sel else 2, 10, 4))
		slot.custom_minimum_size = Vector2(62, 62)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hotbar_box.add_child(slot)
		var c := Control.new()
		c.custom_minimum_size = Vector2(54, 54)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(c)
		if not it.is_empty():
			var ic := UIKit.icon(_item_icon(it), 40)
			ic.position = Vector2(7, 7)
			if it["t"] == "gem" and DB.GEMS.has(it["id"]):
				ic.modulate = (DB.GEMS[it["id"]]["color"] as Color).lerp(Color.WHITE, 0.35)
			elif it["t"] == "serve" and not it.get("full", false):
				ic.modulate = Color(1, 1, 1, 0.5)
			c.add_child(ic)
		var n := UIKit.label(str(i + 1), 13, Color.WHITE, true)
		n.add_theme_color_override("font_outline_color", Color.BLACK)
		n.add_theme_constant_override("outline_size", 4)
		n.position = Vector2(2, -2)
		c.add_child(n)
	var h := GameState.held()
	hotbar_name.text = GameState.item_name(h) if not h.is_empty() else ""


func _refresh_hints() -> void:
	if hint_lbl:
		hint_lbl.text = "1-9 Select   %s Use   %s Interact   %s Drop   %s Trash   %s Guide" % [
			Settings.prompt("use_item"), Settings.prompt("interact"), Settings.prompt("drop_item"), Settings.prompt("trash_item"), Settings.prompt("field_guide")]


func refresh_hud() -> void:
	var gs = GameState
	var phase_txt := ""
	match gs.phase:
		0:
			phase_txt = "PREP  -  time paused"
		1:
			var c: float = world().day_cycle.clock if world() and world().day_cycle else 9.0
			phase_txt = "OPEN  -  %02d:%02d" % [int(c), int(fmod(c, 1.0) * 60.0)]
		2:
			phase_txt = "SUNSET  -  reviews"
		3:
			phase_txt = "SUNSET  -  ledger"
	day_lbl.text = "Day %d  |  %s" % [gs.day, phase_txt]
	money_lbl.text = UIKit.money_text(gs.money)
	money_lbl.add_theme_color_override("font_color", UIKit.GOOD if gs.money >= 0 else UIKit.BAD)
	up_lbl.text = "Upgrade Points: %d%s" % [gs.up, ("   (%d to claim at desk)" % gs.unclaimed_count()) if gs.unclaimed_count() > 0 else ""]
	var debt: int = gs.debt_total()
	bag_lbl.text = "Bag %d/%d   Stored %d   Plushies %d%s" % [gs.backpack.size(), gs.backpack_capacity(), gs.storage.size(), gs.plushies,
		("   Debt %s" % UIKit.money_text(debt)) if debt > 0 else ""]
	var half: int = gs.half_stars
	if half != _last_half:
		_last_half = half
		UIKit.set_stars(star_row, half)
	quality_bar.value = gs.quality
	quality_lbl.text = "%d%%" % int(gs.quality)
	for k in pillar_bars.keys():
		(pillar_bars[k] as ProgressBar).value = float(gs.pillars[k])
	ticket_lbl.text = "Ticket %s   |   Fun %d   Decor %d   Clean %d" % [UIKit.money_text(gs.ticket_price()), int(gs.pillars["fun"]), int(gs.pillars["decor"]), int(gs.pillars["clean"])]
	_refresh_hotbar()
	detector_box.visible = gs.detector_on and int(gs.tools["detector"]) > 0


func _process(delta: float) -> void:
	_hud_t -= delta
	if _hud_t <= 0.0:
		_hud_t = 0.2
		refresh_hud()
	elif hotbar_box:
		_refresh_hotbar()
	if detector_bar:
		detector_bar.value = maxf(0.0, _detector) * 100.0
	if crosshair:
		var w := world()
		crosshair.visible = current == null and not dialog_panel.visible and not (w != null and w.build != null and w.build.active)
	if dialog_panel.visible and dialog_text.visible_ratio < 1.0:
		dialog_chars += delta * float(Settings.get_v("text_speed"))
		dialog_text.visible_characters = int(dialog_chars)


func _on_prompt(t: String) -> void:
	prompt_panel.visible = t != "" and current == null and not dialog_panel.visible
	prompt_lbl.text = t


func _toast(text: String, color: Color) -> void:
	var p := UIKit.pill_panel()
	var h := UIKit.hbox(8)
	p.add_child(h)
	var ic := "check"
	if color == UIKit.BAD or color == UIKit.CORAL:
		ic = "warning"
	elif color == UIKit.GOLD or color == Color("e0a020"):
		ic = "star"
	elif color == UIKit.ACCENT:
		ic = "research"
	h.add_child(UIKit.icon(ic, 22))
	var l := UIKit.label(text, 16, color.lightened(0.35) if color != Color.WHITE else Color("fff6e6"), true)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if text.length() > 48:
		l.custom_minimum_size = Vector2(380, 0)
	h.add_child(l)
	toasts.add_child(p)
	while toasts.get_child_count() > 6:
		var first := toasts.get_child(0)
		toasts.remove_child(first)
		first.queue_free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	tw.tween_interval(3.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


func _walkie(text: String, kind: String, pos: Vector3) -> void:
	walkie_panel.visible = true
	var col: Color = WALKIE_COLORS.get(kind, Color("8dffb0"))
	var dist := ""
	if pos != Vector3.ZERO and world() and world().player:
		dist = "  (%dm)" % int(world().player.global_position.distance_to(pos))
	var clock := ""
	if world() and world().day_cycle:
		var c: float = world().day_cycle.clock
		clock = "%02d:%02d " % [int(c), int(fmod(c, 1.0) * 60.0)]
	var l := UIKit.label(clock + text + dist, 14, col, true)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size = Vector2(310, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	walkie_list.add_child(l)
	walkie_list.move_child(l, 0)
	while walkie_list.get_child_count() > 5:
		var last := walkie_list.get_child(walkie_list.get_child_count() - 1)
		walkie_list.remove_child(last)
		last.queue_free()
	Audio.sfx("alert", 1.0, -4.0)
	var tw := walkie_panel.create_tween()
	walkie_panel.modulate = Color(1.5, 1.35, 1.0)
	tw.tween_property(walkie_panel, "modulate", Color.WHITE, 0.6)

# ------------------------------------------------------------------ dialog --
func _on_dialog_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_advance_dialog()


func _dialog(lines: Array) -> void:
	dialog_queue.append_array(lines)
	if not dialog_panel.visible:
		_next_line()


func _next_line() -> void:
	if dialog_queue.is_empty():
		dialog_panel.visible = false
		if current == null:
			get_tree().paused = false
		refresh_mouse()
		Events.dialog_finished.emit()
		return
	var l: Dictionary = dialog_queue.pop_front()
	dialog_name.text = l.get("name", "")
	dialog_text.text = l.get("text", "")
	dialog_text.visible_characters = 0
	dialog_chars = 0.0
	dialog_hint.text = "%s / click to continue" % Settings.prompt("interact")
	dialog_panel.visible = true
	prompt_panel.visible = false
	get_tree().paused = true
	refresh_mouse()
	Audio.sfx("page", 1.1, -6.0)


func _advance_dialog() -> void:
	if dialog_text.visible_ratio < 1.0:
		dialog_text.visible_characters = -1
		dialog_chars = 99999.0
	else:
		_next_line()

# ------------------------------------------------------------------ input ---
func _unhandled_input(event: InputEvent) -> void:
	if Settings.capture_action != "":
		return
	if dialog_panel.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
			_advance_dialog()
			get_viewport().set_input_as_handled()
		return
	if current:
		if (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not NO_ESC.has(current_name):
			close_panel()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(_toggle_action(current_name)):
			close_panel()
			get_viewport().set_input_as_handled()
		return
	if world() and world().build.active:
		return
	var map := {"pause": "pause", "skill_tree": "skills", "field_guide": "guide", "inventory": "inventory", "management": "management"}
	for a in map.keys():
		if event.is_action_pressed(a):
			open(map[a], false if a == "field_guide" else null)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("build_mode"):
		world().build.enter()
		get_viewport().set_input_as_handled()


func _toggle_action(n: String) -> String:
	var map := {"skills": "skill_tree", "guide": "field_guide", "inventory": "inventory", "management": "management"}
	return map.get(n, "pause")


func has_panel() -> bool:
	return current != null or dialog_panel.visible


func open(n: String, data: Variant = null) -> void:
	if current:
		current.queue_free()
		current = null
	var c := panels.build(n, data)
	if c == null:
		return
	if world() and world().player and world().player.digging:
		world().player.cancel_dig()
	panel_layer.add_child(c)
	current = c
	current_name = n
	prompt_panel.visible = false
	get_tree().paused = true
	refresh_mouse()
	Audio.sfx("page", 1.0, -6.0)
	UIKit.focus_first(c)


func reopen(data: Variant = null) -> void:
	var n := current_name
	open(n, data)


func close_panel() -> void:
	if current:
		current.queue_free()
		current = null
	current_name = ""
	if not dialog_panel.visible:
		get_tree().paused = false
	refresh_mouse()


func refresh_mouse() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var w := world()
	var free := current != null or dialog_panel.visible or (w != null and w.build != null and w.build.active)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if free else Input.MOUSE_MODE_CAPTURED
