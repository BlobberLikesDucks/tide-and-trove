class_name Throw
extends RefCounted
## A thrown object (litter, a snack wrapper...) flying along a parabola from one
## point to another, tumbling, then calling on_land. Used by guests throwing trash
## and by the player throwing held trash at bins.


static func arc(parent: Node, from: Vector3, to: Vector3, model_id: String, duration: float = 0.6, on_land: Callable = Callable(), height: float = 1.2) -> Node3D:
	var m := Art.model(model_id)
	Art.strip_collision(m)
	parent.add_child(m)
	m.global_position = from
	m.scale = Vector3.ONE * 0.8
	var spin := Vector3(randf_range(-9, 9), randf_range(-6, 6), randf_range(-9, 9))
	var step := func(t: float) -> void:
		if not is_instance_valid(m):
			return
		var p := from.lerp(to, t)
		p.y += sin(t * PI) * height
		m.global_position = p
		m.rotation = spin * t
	var tw := m.create_tween()
	tw.tween_method(step, 0.0, 1.0, duration)
	tw.tween_callback(func() -> void:
		# the thrower may be gone by now (left, or replaced when a save is loaded)
		if on_land.is_valid() and is_instance_valid(on_land.get_object()):
			on_land.call()
		if is_instance_valid(m):
			m.queue_free())
	return m
