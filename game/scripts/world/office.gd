class_name Office
extends Node3D
## The Curator's Office corner (comes with the 3-star expansion): a desk with the
## office computer and a swivel chair. Interact to sit down: the view moves to
## the chair, the J-Mail screen fills the monitor, and you steer the real mouse
## pointer on the screen (the little 3D mouse on the desk moves with it).
## Escape or "Log off" stands you up again.

const VP_SIZE := Vector2i(1100, 700)
const SCREEN_W := 0.72
const SCREEN_H := 0.458

var desk: Node3D
var viewport: SubViewport
var screen: MeshInstance3D
var app: JMail
var cam: Camera3D
var mouse3d: Node3D
var chair: Node3D
var seated := false
var _mouse_rest := Vector3.ZERO
var _anchor: Node3D
var _saved_pos := Vector3.ZERO


func _ready() -> void:
	desk = Art.model("computer_desk")
	add_child(desk)
	_anchor = desk.find_child("ScreenAnchor", true, false) as Node3D
	mouse3d = desk.find_child("Mouse", true, false) as Node3D
	chair = desk.find_child("Chair", true, false) as Node3D
	if mouse3d:
		_mouse_rest = mouse3d.position
	viewport = SubViewport.new()
	viewport.size = VP_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = true
	add_child(viewport)
	app = JMail.new()
	viewport.add_child(app)
	app.log_off.connect(stand_up)
	screen = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(SCREEN_W, SCREEN_H)
	screen.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()
	screen.material_override = mat
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(screen)
	if _anchor:
		screen.global_transform = _anchor.global_transform
		screen.position += _anchor.global_transform.basis.z * 0.004  # just in front of the glass
	cam = Camera3D.new()
	cam.fov = 48.0
	cam.near = 0.02
	add_child(cam)
	var it := Interactable.attach(desk, "Use the computer (J-Mail)", _on_use, 1.4, 2.0)
	it.text_fn = func() -> String:
		var n := Mail.unread()
		return "Sit at the computer - J-Mail%s" % ((" (%d new!)" % n) if n > 0 else "")
	Events.mail_arrived.connect(func(_n: int) -> void: app.refresh())


func _on_use(_p: Variant = null) -> void:
	if seated:
		return
	var pl := World.instance.player
	seated = true
	pl.locked = true
	pl.seated = true
	pl.fp.visible = false
	_saved_pos = pl.global_position
	if chair:
		var tw := create_tween()
		tw.tween_property(chair, "rotation:y", 0.0, 0.3)
	# eye position: sitting on the chair, looking at the middle of the screen
	var sc := screen.global_transform
	cam.global_position = sc.origin + sc.basis.z * 0.6 + Vector3(0, 0.03, 0)
	cam.look_at(sc.origin, Vector3.UP)
	cam.current = true
	pl.global_position = sc.origin + sc.basis.z * 1.0 - Vector3(0, sc.origin.y, 0)
	app.refresh()
	World.instance.ui.refresh_mouse()
	World.instance.ui.hud.visible = false  # just the screen while you work
	Events.prompt.emit("")
	Audio.sfx("page", 1.2, -6.0)


func stand_up() -> void:
	if not seated:
		return
	seated = false
	var pl := World.instance.player
	pl.locked = false
	pl.seated = false
	pl.fp.visible = true
	pl.global_position = _saved_pos
	pl.camera.current = true
	if mouse3d:
		mouse3d.position = _mouse_rest
	World.instance.ui.hud.visible = true
	World.instance.ui.refresh_mouse()


## While seated: mouse events are projected from the camera onto the monitor
## quad and pushed into the J-Mail SubViewport.
func _input(e: InputEvent) -> void:
	if not seated:
		return
	if e.is_action_pressed("pause") or e.is_action_pressed("interact"):
		stand_up()
		get_viewport().set_input_as_handled()
		return
	if e is InputEventMouse:
		var uv := _screen_uv((e as InputEventMouse).position)
		if uv.x < 0.0:
			return
		var ev: InputEventMouse = e.duplicate()
		var px := Vector2(uv.x * VP_SIZE.x, uv.y * VP_SIZE.y)
		ev.position = px
		ev.global_position = px
		if ev is InputEventMouseMotion:
			(ev as InputEventMouseMotion).relative = (e as InputEventMouseMotion).relative * 1.0
		viewport.push_input(ev, true)
		if mouse3d:
			mouse3d.position = _mouse_rest + Vector3((uv.x - 0.5) * 0.14, 0, (uv.y - 0.5) * 0.11)
		get_viewport().set_input_as_handled()


func _screen_uv(p: Vector2) -> Vector2:
	var o := cam.project_ray_origin(p)
	var d := cam.project_ray_normal(p)
	var t := screen.global_transform
	var n := t.basis.z.normalized()
	var denom := n.dot(d)
	if absf(denom) < 1e-5:
		return Vector2(-1, -1)
	var hit := o + d * (n.dot(t.origin - o) / denom)
	var local := t.affine_inverse() * hit
	var u := local.x / SCREEN_W + 0.5
	var v := 0.5 - local.y / SCREEN_H
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return Vector2(-1, -1)
	return Vector2(u, v)
