class_name JMail
extends Control
## The J-Mail app on the office computer screen (drawn into a SubViewport that is
## textured onto the 3D monitor). Inbox on the left, the open email on the right
## with its action buttons and a Delete button. "Log off" stands you up.

signal log_off

const W := 1100
const H := 700
const C_BG := Color("e9eef3")
const C_BAR := Color("2f8f8f")
const C_TEXT := Color("1f2a33")
const C_MUTED := Color("6a7884")
const C_SCAM := Color("c0392b")

var list: VBoxContainer
var view: VBoxContainer
var status: Label
var title: Label
var sel_id := -1


func _ready() -> void:
	size = Vector2(W, H)
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.size = size
	add_child(bg)
	var bar := ColorRect.new()
	bar.color = C_BAR
	bar.size = Vector2(W, 64)
	add_child(bar)
	var logo := _lbl("J-Mail", 34, Color.WHITE)
	logo.position = Vector2(22, 8)
	add_child(logo)
	title = _lbl("", 20, Color(1, 1, 1, 0.9))
	title.position = Vector2(180, 20)
	add_child(title)
	var off := _btn("Log off", Color("e05a4a"))
	off.position = Vector2(W - 150, 12)
	off.size = Vector2(130, 40)
	off.pressed.connect(func() -> void: log_off.emit())
	add_child(off)
	var ls := ScrollContainer.new()
	ls.position = Vector2(12, 76)
	ls.size = Vector2(370, H - 120)
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(ls)
	list = VBoxContainer.new()
	list.custom_minimum_size = Vector2(354, 0)
	list.add_theme_constant_override("separation", 6)
	ls.add_child(list)
	var panel := Panel.new()
	panel.position = Vector2(394, 76)
	panel.size = Vector2(W - 406, H - 120)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vs := ScrollContainer.new()
	vs.position = Vector2(410, 86)
	vs.size = Vector2(W - 436, H - 140)
	vs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(vs)
	view = VBoxContainer.new()
	view.custom_minimum_size = Vector2(W - 456, 0)
	view.add_theme_constant_override("separation", 10)
	vs.add_child(view)
	status = _lbl("", 17, C_BAR)
	status.position = Vector2(14, H - 38)
	status.size = Vector2(W - 28, 30)
	add_child(status)
	refresh()


func _lbl(t: String, s: int, c: Color = C_TEXT) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	l.add_theme_font_override("font", UIKit.font(s >= 20))
	return l


func _btn(t: String, c: Color) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 18)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = c.lightened(0.12) if st == "hover" else (c.darkened(0.15) if st == "pressed" else c)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.focus_mode = Control.FOCUS_NONE
	return b


func refresh() -> void:
	for c in list.get_children():
		c.queue_free()
	title.text = "Inbox  -  %d unread" % Mail.unread()
	if GameState.emails.is_empty():
		list.add_child(_lbl("No emails. Check back tomorrow!", 18, C_MUTED))
	for m in GameState.emails:
		var b := Button.new()
		b.custom_minimum_size = Vector2(350, 70)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		var unread: bool = not m.get("read", false)
		b.text = "%s%s\n%s" % ["* " if unread else "", String(m["from"]).split(" <")[0], m["subject"]]
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_font_override("font", UIKit.font(unread))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("cfe6e6") if int(m["id"]) == sel_id else (Color.WHITE if unread else Color("f4f6f8"))
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 10
		var sbh: StyleBoxFlat = sb.duplicate()
		sbh.bg_color = Color("dff0f0")
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sbh)
		b.add_theme_stylebox_override("pressed", sbh)
		b.add_theme_stylebox_override("focus", sb)
		b.add_theme_color_override("font_color", C_TEXT)
		b.add_theme_color_override("font_hover_color", C_TEXT)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_open.bind(int(m["id"])))
		list.add_child(b)
	_show()


func _find(id: int) -> Dictionary:
	for m in GameState.emails:
		if int(m["id"]) == id:
			return m
	return {}


func _open(id: int) -> void:
	sel_id = id
	var m := _find(id)
	if not m.is_empty():
		m["read"] = true
	Audio.sfx("click", 1.3, -10.0)
	refresh()


func _show() -> void:
	for c in view.get_children():
		c.queue_free()
	var m := _find(sel_id)
	if m.is_empty():
		view.add_child(_lbl("Select an email on the left.", 20, C_MUTED))
		return
	view.add_child(_lbl(String(m["subject"]), 24, C_TEXT))
	var from := _lbl("From: %s" % m["from"], 15, C_MUTED)
	from.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	from.custom_minimum_size = Vector2(W - 470, 0)
	view.add_child(from)
	view.add_child(_lbl("Received on Day %d" % int(m["day"]), 15, C_MUTED))
	var body := _lbl(String(m["body"]), 18, C_TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(W - 470, 0)
	view.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	view.add_child(row)
	for a in Mail.actions(m):
		var b := _btn(String(a[0]), C_BAR if String(a[1]) != "accept" or not String(m["kind"]).begins_with("scam_") else Color("d98a2b"))
		b.pressed.connect(_act.bind(int(m["id"]), String(a[1])))
		row.add_child(b)
	var del := _btn("Delete", Color("7a8894"))
	del.pressed.connect(_delete.bind(int(m["id"])))
	row.add_child(del)
	if m.get("done", false):
		view.add_child(_lbl("(Handled)", 16, C_MUTED))


func _act(id: int, action: String) -> void:
	var m := _find(id)
	if m.is_empty():
		return
	status.text = Mail.act(m, action)
	Audio.sfx("click")
	refresh()


func _delete(id: int) -> void:
	var m := _find(id)
	if m.is_empty():
		return
	if String(m["kind"]).begins_with("scam_") and not m.get("done", false):
		status.text = "Deleted. Smart move - that was a scam."
	else:
		status.text = "Email deleted."
	GameState.emails.erase(m)
	sel_id = -1
	Audio.sfx("crack", 1.6, -12.0)
	refresh()
