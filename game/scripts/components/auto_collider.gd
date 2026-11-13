class_name AutoCollider
extends Node
## Child of an instanced model: if the model has no Blender collision proxy,
## fits a box collider to its meshes (shrunk a little so it never feels sticky).

@export_range(0.3, 1.0) var shrink: float = 0.75


func _ready() -> void:
	_fit.call_deferred()  # the host is still adding its children during _ready


func _fit() -> void:
	var host := get_parent() as Node3D
	if host and not Art.has_proxy(host):
		Art.fit_collider(host, shrink)
