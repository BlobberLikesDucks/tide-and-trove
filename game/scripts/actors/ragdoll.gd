class_name Ragdoll
extends RefCounted
## Articulated physics ragdoll for a skinned CharVisual. Eleven skeleton bones
## (hips, spine, head, upper/lower arms, thighs, shins) each get their own
## RigidBody3D, linked by joints at the bone heads: cone-twist for neck, spine,
## shoulders and hips, limited hinges for elbows and knees. Every frame the
## skeleton copies the bodies (CharVisual._drive_ragdoll). Afterwards the bodies
## are freed, the actor stands where the hips landed and plays the Blender
## "getup" clip. Works for any Mixamo-style rig (e.g. MeshyAI exports).

## bone -> [parent bone in the ragdoll, child bone that marks the segment end, shape, radius]
const PARTS := {
	"Hips": ["", "Spine", "box", 0.16],
	"Spine": ["Hips", "Neck", "capsule", 0.16],
	"Head": ["Spine", "", "sphere", 0.16],
	"LeftArm": ["Spine", "LeftForeArm", "capsule", 0.065],
	"RightArm": ["Spine", "RightForeArm", "capsule", 0.065],
	"LeftForeArm": ["LeftArm", "LeftHand", "capsule", 0.05],
	"RightForeArm": ["RightArm", "RightHand", "capsule", 0.05],
	"LeftUpLeg": ["Hips", "LeftLeg", "capsule", 0.085],
	"RightUpLeg": ["Hips", "RightLeg", "capsule", 0.085],
	"LeftLeg": ["LeftUpLeg", "LeftFoot", "capsule", 0.065],
	"RightLeg": ["RightUpLeg", "RightFoot", "capsule", 0.065],
}
## Parents first so set_bone_global_pose sees up-to-date parents.
const ORDER := ["Hips", "Spine", "Head", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg"]
const MASS := {"Hips": 12.0, "Spine": 16.0, "Head": 5.0, "LeftArm": 2.5, "RightArm": 2.5, "LeftForeArm": 2.0, "RightForeArm": 2.0,
	"LeftUpLeg": 7.0, "RightUpLeg": 7.0, "LeftLeg": 4.0, "RightLeg": 4.0}


static func knock(actor: Node3D, visual: CharVisual, v: Vector3) -> Dictionary:
	var sk := visual.skeleton
	if sk == null:
		return {}
	visual.stop_anim()
	var world: Node = actor.get_parent()
	var s := visual.body_scale
	var holder := Node3D.new()
	holder.name = "Ragdoll"
	world.add_child(holder)
	FX.burst(world, actor.global_position + Vector3(0, 0.4, 0), "dust", 1.2)
	var skx := sk.global_transform
	# Character frame (model faces +Z inside the visual, which faces -Z).
	var cf := (visual.global_transform.basis * Basis(Vector3.UP, PI)).orthonormalized()
	var bodies := {}
	var drive := {}
	var order: Array = []
	for n in ORDER:
		var b := sk.find_bone(n)
		if b < 0:
			continue
		var info: Array = PARTS[n]
		var bone_world: Transform3D = skx * sk.get_bone_global_pose(b)
		var origin := bone_world.origin
		var end := origin + cf.y * 0.3 * s
		var cb := sk.find_bone(String(info[1])) if String(info[1]) != "" else -1
		if cb >= 0:
			end = (skx * sk.get_bone_global_pose(cb)).origin
		var rb := RigidBody3D.new()
		rb.collision_layer = 16
		rb.collision_mask = 1
		rb.mass = MASS[n]
		rb.linear_damp = 0.25
		rb.angular_damp = 1.6
		rb.continuous_cd = true
		var pm := PhysicsMaterial.new()
		pm.friction = 0.9
		pm.bounce = 0.12
		rb.physics_material_override = pm
		var cs := CollisionShape3D.new()
		var r: float = float(info[3]) * s
		var seg := end - origin
		var length := maxf(seg.length(), r * 2.0 + 0.02)
		match String(info[2]):
			"box":
				var bx := BoxShape3D.new()
				bx.size = Vector3(r * 2.0, maxf(seg.length(), 0.12), r * 1.4)
				cs.shape = bx
			"sphere":
				var sp := SphereShape3D.new()
				sp.radius = r
				cs.shape = sp
			_:
				var c := CapsuleShape3D.new()
				c.radius = r
				c.height = length
				cs.shape = c
		# Body frame = character frame at the joint; shape aligned to the segment.
		rb.add_child(cs)
		holder.add_child(rb)
		rb.global_transform = Transform3D(cf, origin)
		var dir := seg.normalized() if seg.length() > 0.001 else cf.y
		var up := cf.inverse() * dir
		var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		cs.basis = Basis(side, up, side.cross(up).normalized())
		cs.position = cf.inverse() * (seg * 0.5) if String(info[2]) != "sphere" else Vector3(0, r, 0)
		bodies[n] = rb
		drive[b] = [rb, rb.global_transform.affine_inverse() * bone_world]
		order.append(b)
	# Joints at each child's joint pivot, oriented on the character frame.
	for n in bodies.keys():
		var parent_name: String = PARTS[n][0]
		if parent_name == "" or not bodies.has(parent_name):
			continue
		var child: RigidBody3D = bodies[n]
		var joint: Joint3D
		var basis: Basis
		if n.ends_with("Leg") and not n.ends_with("UpLeg") or n.ends_with("ForeArm"):
			var h := HingeJoint3D.new()
			h.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
			if n.ends_with("Leg"):
				h.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-5))
				h.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(135))
			else:
				h.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-140))
				h.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(5))
			joint = h
			basis = Basis(cf.y, cf.z, cf.x)
		else:
			var c := ConeTwistJoint3D.new()
			var swing := 35.0
			var twist := 20.0
			if n.ends_with("Arm"):
				swing = 80.0
				twist = 40.0
			elif n.ends_with("UpLeg"):
				swing = 60.0
				twist = 20.0
			elif n == "Head":
				swing = 40.0
				twist = 35.0
			c.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(swing))
			c.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(twist))
			joint = c
			basis = Basis(cf.y, -cf.x, cf.z)
		holder.add_child(joint)
		joint.global_transform = Transform3D(basis.orthonormalized(), child.global_position)
		joint.node_a = joint.get_path_to(bodies[parent_name])
		joint.node_b = joint.get_path_to(child)
		joint.exclude_nodes_from_collision = true
	# Throw it: most of the impulse into the torso, a little everywhere.
	for n in bodies.keys():
		var rb: RigidBody3D = bodies[n]
		var k := 1.0 if (n == "Spine" or n == "Hips") else 0.75
		rb.linear_velocity = v * k + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		rb.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-2, 2), randf_range(-4, 4))
	visual.rag = {"drive": drive, "order": order}
	visual.ragdolled = true
	if visual.bubble:
		visual.bubble.visible = false
	return {"holder": holder, "bodies": bodies}


static func settled(rd: Dictionary) -> bool:
	if rd.is_empty() or not rd.has("bodies"):
		return true
	var b: Dictionary = rd["bodies"]
	if not b.has("Hips"):
		return true
	var pel: RigidBody3D = b["Hips"]
	return pel.linear_velocity.length() < 0.25


static func recover(actor: Node3D, visual: CharVisual, rd: Dictionary) -> void:
	if rd.is_empty():
		return
	var bodies: Dictionary = rd["bodies"]
	var p := actor.global_position
	var face := visual.rotation.y
	if bodies.has("Hips") and is_instance_valid(bodies["Hips"]):
		p = (bodies["Hips"] as RigidBody3D).global_position
		# Get up facing the feet (the getup clip starts lying on the back).
		if bodies.has("Head") and is_instance_valid(bodies["Head"]):
			var d: Vector3 = p - (bodies["Head"] as RigidBody3D).global_position
			d.y = 0.0
			if d.length() > 0.05:
				face = atan2(-d.x, -d.z)
	p.y = 0.0
	actor.global_position = p
	visual.ragdolled = false
	visual.rag = {}
	if visual.skeleton:
		visual.skeleton.reset_bone_poses()
	var holder: Node = rd["holder"]
	if is_instance_valid(holder):
		holder.queue_free()
	visual.position = Vector3.ZERO
	visual.rotation = Vector3(0, face, 0)
	visual.play_once("getup")
