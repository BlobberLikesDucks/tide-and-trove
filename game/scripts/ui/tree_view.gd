class_name TreeView
extends Control
## Pannable, zoomable window onto the (much bigger than the screen) Upgrade
## Tree. Drag empty space with any mouse button, scroll to zoom, or use the
## arrow keys / WASD / left stick. The view is remembered between reopenings.

static var saved_offset := Vector2(0, 0)
static var saved_zoom := 1.0

var canvas: Control
var zoom := 1.0
var _drag := false
const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.35


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


func setup(c: Control) -> void:
	canvas = c
	add_child(c)
	zoom = saved_zoom
	canvas.scale = Vector2.ONE * zoom
	canvas.position = saved_offset
	call_deferred("_clamp")


func center_on(p: Vector2) -> void:
	canvas.position = size * 0.5 - p * zoom
	_clamp()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, 1.1)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, 1.0 / 1.1)
			accept_event()
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_drag = mb.pressed
			if mb.pressed:
				grab_focus()
			accept_event()
	elif e is InputEventMouseMotion and _drag:
		canvas.position += (e as InputEventMouseMotion).relative
		_clamp()
		accept_event()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if v.length() < 0.2:
		v = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if v.length() > 0.2:
		canvas.position -= v * 900.0 * delta
		_clamp()


func _zoom_at(p: Vector2, k: float) -> void:
	var nz := clampf(zoom * k, MIN_ZOOM, MAX_ZOOM)
	var local := (p - canvas.position) / zoom
	zoom = nz
	canvas.scale = Vector2.ONE * zoom
	canvas.position = p - local * zoom
	_clamp()


func _clamp() -> void:
	if canvas == null:
		return
	var cs := canvas.custom_minimum_size * zoom
	var lo := Vector2(minf(0.0, size.x - cs.x - 40.0), minf(0.0, size.y - cs.y - 30.0))
	canvas.position = Vector2(clampf(canvas.position.x, lo.x, 40.0), clampf(canvas.position.y, lo.y, 30.0))
	saved_offset = canvas.position
	saved_zoom = zoom
