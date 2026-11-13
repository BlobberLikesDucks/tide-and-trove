class_name WaterSurface
extends Node3D
## Put on an instanced water_plane.glb in the editor: swaps its mesh material for
## the animated stylized sea shader (waves, foam line at the shore).

@export var shore_z: float = 46.0
@export var water_shader: Shader = preload("res://assets/shaders/water.gdshader")


func _ready() -> void:
	var sm := ShaderMaterial.new()
	sm.shader = water_shader
	sm.set_shader_parameter("shore_z", shore_z)
	for mi in Art.meshes(self):
		mi.material_override = sm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
