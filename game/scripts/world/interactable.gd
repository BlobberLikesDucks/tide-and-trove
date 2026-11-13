class_name Interactable
extends Area3D
## Anything the player can press Interact on. The player's look ray finds
## these on physics layer 4 and shows `prompt_text()` in the HUD.
## The trigger volume hugs the object's own meshes (its bounding box), so a
## prompt only appears when you are close AND looking straight at the thing -
## a big invisible cylinder around the workbench no longer hijacks the crates.

var text := "Interact"
var text_fn: Callable
var action: Callable
var enabled := true
var prio := 0
var owner_node: Node


static func attach(parent: Node3D, label: String, cb: Callable, radius: float = 1.6, height: float = 2.2, offset: Vector3 = Vector3.ZERO) -> Interactable:
	var a := Interactable.new()
	a.text = label
	a.action = cb
	a.owner_node = parent
	a.collision_layer = 8
	a.collision_mask = 0
	a.monitoring = false
	a.monitorable = true
	var cs := CollisionShape3D.new()
	var box := Art.local_aabb(parent)
	if box.size.length() > 0.05:
		# fit the visible model (slightly padded, never thinner than 0.45 m)
		var shape := BoxShape3D.new()
		shape.size = Vector3(maxf(box.size.x * 1.06, 0.45), maxf(box.size.y * 1.04, 0.45), maxf(box.size.z * 1.06, 0.45))
		cs.shape = shape
		cs.position = box.get_center()
		if cs.position.y - shape.size.y * 0.5 < 0.0:
			cs.position.y = shape.size.y * 0.5
	else:
		var cyl := CylinderShape3D.new()
		cyl.radius = minf(radius, 0.8)
		cyl.height = height
		cs.shape = cyl
		cs.position = Vector3(0, height * 0.5, 0) + offset * 0.0
	a.add_child(cs)
	parent.add_child(a)
	parent.set_meta("tt_inter", a)  # lets the look ray hit the object's own collider too
	return a


func prompt_text() -> String:
	if text_fn.is_valid():
		return String(text_fn.call())
	return text


func activate(player: Node) -> void:
	if enabled and action.is_valid():
		if action.get_argument_count() >= 1:
			action.call(player)
		else:
			action.call()
