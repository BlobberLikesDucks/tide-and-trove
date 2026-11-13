class_name FX
extends RefCounted
## One-shot particle bursts using the Blender-made FX meshes (blender/ttassets/
## fxdress.py: fx_puff, fx_chip, fx_sparkle, fx_gem_glint, fx_droplet,
## fx_confetti, fx_dust). CPUParticles3D so they also run headless.

const KINDS := {
	"sand": {"mesh": "fx_puff", "n": 7, "life": 0.55, "vel": Vector2(1.2, 2.4), "grav": -4.0, "scale": Vector2(0.5, 1.1), "spread": 55.0},
	"rock": {"mesh": "fx_chip", "n": 9, "life": 0.7, "vel": Vector2(2.0, 3.6), "grav": -9.8, "scale": Vector2(0.6, 1.3), "spread": 60.0},
	"dust": {"mesh": "fx_dust", "n": 12, "life": 0.9, "vel": Vector2(0.4, 1.4), "grav": 0.6, "scale": Vector2(0.8, 2.0), "spread": 85.0},
	"glint": {"mesh": "fx_gem_glint", "n": 6, "life": 0.8, "vel": Vector2(0.6, 1.6), "grav": 0.0, "scale": Vector2(0.6, 1.2), "spread": 180.0},
	"sparkle": {"mesh": "fx_sparkle", "n": 14, "life": 1.1, "vel": Vector2(1.0, 2.6), "grav": -1.0, "scale": Vector2(0.6, 1.4), "spread": 70.0},
	"confetti": {"mesh": "fx_confetti", "n": 22, "life": 1.4, "vel": Vector2(2.0, 4.0), "grav": -3.5, "scale": Vector2(0.8, 1.2), "spread": 40.0},
	"splash": {"mesh": "fx_droplet", "n": 10, "life": 0.6, "vel": Vector2(1.5, 3.0), "grav": -9.8, "scale": Vector2(0.6, 1.2), "spread": 50.0},
}


static func burst(parent: Node, pos: Vector3, kind: String, amount_mult: float = 1.0) -> void:
	if parent == null or not parent.is_inside_tree() or not KINDS.has(kind):
		return
	var k: Dictionary = KINDS[kind]
	var mesh := Art.mesh_of(k["mesh"])
	if mesh == null:
		return
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.amount = maxi(1, int(int(k["n"]) * amount_mult))
	p.lifetime = k["life"]
	p.one_shot = true
	p.explosiveness = 0.92
	p.direction = Vector3.UP
	p.spread = k["spread"]
	p.initial_velocity_min = (k["vel"] as Vector2).x
	p.initial_velocity_max = (k["vel"] as Vector2).y
	p.gravity = Vector3(0, k["grav"], 0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.particle_flag_rotate_y = true
	p.scale_amount_min = (k["scale"] as Vector2).x
	p.scale_amount_max = (k["scale"] as Vector2).y
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.4))
	c.add_point(Vector2(0.15, 1.0))
	c.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = c
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	var t := parent.get_tree().create_timer(float(k["life"]) + 0.3)
	t.timeout.connect(p.queue_free)
