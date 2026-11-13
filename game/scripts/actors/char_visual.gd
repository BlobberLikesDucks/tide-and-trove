class_name CharVisual
extends Node3D
## Stylized character from character.glb (blender/ttassets/characters.py): a
## skinned, auto-weighted body on a Mixamo-style skeleton with archetype outfit
## pieces toggled by name and AN_* clips keyed in Blender. Any rig with the same
## bone + clip names (e.g. MeshyAI / Mixamo) can be swapped in via MODEL_ID.
## The model faces +Z; this node turns it to face -Z.

const MODEL_ID := "character"
const ACCESSORIES := ["Hat_Safari", "Hat_Cap", "Hat_Fedora", "Hat_Top", "Sunglasses", "Glasses", "Hair_Long", "Hair_Bun", "Beard",
	"Backpack", "Clipboard", "Vest", "Tie", "Coat", "PhotoCamera", "Lanyard"]
const HATS := ["Hat_Safari", "Hat_Cap", "Hat_Fedora", "Hat_Top"]
const LOOPS := ["idle", "walk", "run", "dig", "sweep", "tantrum", "sit", "sleep", "wave", "cheer", "climb", "inspect"]
const SKIN := [Color("e8b48e"), Color("e0ac83"), Color("c68a5e"), Color("9a6440"), Color("6b4329"), Color("ebbd98")]  # warm light tones (very pale ones read as grey under the toon light)
const HAIR := [Color("2b1d14"), Color("5a3a22"), Color("a0622d"), Color("e3c27a"), Color("8a8a8a"), Color("1a1a1a"), Color("c0392b")]
const SHIRTS := [Color("ff7a59"), Color("4fb3d9"), Color("ffd23f"), Color("7ac56b"), Color("b47aff"), Color("ff9fc0"), Color("f2f2f2"), Color("3f6fd9"), Color("e0705a")]
const PANTS := [Color("3b4a6b"), Color("6b5a3e"), Color("2a2a30"), Color("8a7a5a"), Color("4a6b4a")]

var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var tool_node: Node3D
var bubble: Label3D
var anim := "idle"
var speed := 0.0
var body_scale := 1.0
var ragdolled := false
var rag: Dictionary = {}          # set by Ragdoll.knock: bone index -> [RigidBody3D, offset]
var _playing := ""
var _oneshot := ""
var _head_scale := 1.0
var _t := 0.0


func setup(look: Dictionary) -> void:
	model = Art.model(MODEL_ID)
	model.rotation.y = PI
	add_child(model)
	var skels := model.find_children("*", "Skeleton3D", true, false)
	skeleton = skels.front() if not skels.is_empty() else null
	var players := model.find_children("*", "AnimationPlayer", true, false)
	player = players.front() if not players.is_empty() else null
	if player:
		for n in LOOPS:
			if player.has_animation(clip(n)):
				player.get_animation(clip(n)).loop_mode = Animation.LOOP_LINEAR
		player.animation_finished.connect(_on_anim_finished)
		player.mixer_applied.connect(_after_anim)
	for mi in Art.meshes(model):
		mi.extra_cull_margin = 4.0
	var acc: Array = look.get("acc", [])
	for n in ACCESSORIES:
		var node := model.find_child(n, true, false)
		if node is Node3D:
			(node as Node3D).visible = acc.has(n)
	# hats get the short "under-hat" hair so nothing pokes through the crown
	var hatted := false
	for h in HATS:
		if acc.has(h):
			hatted = true
	var hair := model.find_child("SM_Char_Hair", true, false)
	if hair is Node3D:
		(hair as Node3D).visible = not hatted and not acc.has("Hair_Long")
	var sides := model.find_child("Hair_Sides", true, false)
	if sides is Node3D:
		(sides as Node3D).visible = hatted
	for k in ["Skin", "Shirt", "Pants", "Shoe", "Hair", "Hat", "Accent", "Pack", "Coat"]:
		if look.has(k):
			Art.tint(model, k, look[k], float(look.get("glow", 0.0)) if k == "Shirt" else 0.0)
	if look.get("cap_back", false):
		var cap := model.find_child("Hat_Cap", true, false)
		if cap is Node3D:
			(cap as Node3D).rotation.y = PI
	body_scale = float(look.get("scale", 1.0))
	scale = Vector3.ONE * body_scale
	_head_scale = float(look.get("head_scale", 1.0))
	bubble = Art.label3d("", 40)
	bubble.position = Vector3(0, 2.35, 0)
	bubble.visible = false
	add_child(bubble)
	_play("idle", 0.0)


static func random_look(rng: RandomNumberGenerator = null) -> Dictionary:
	var r := rng if rng else RandomNumberGenerator.new()
	if rng == null:
		r.randomize()
	var look := {
		"Skin": SKIN[r.randi() % SKIN.size()],
		"Hair": HAIR[r.randi() % HAIR.size()],
		"Shirt": SHIRTS[r.randi() % SHIRTS.size()],
		"Pants": PANTS[r.randi() % PANTS.size()],
		"Shoe": Color("3a2a20") if r.randf() < 0.5 else Color("f2f2f2"),
		"Hat": SHIRTS[r.randi() % SHIRTS.size()],
	}
	var acc: Array = []
	if r.randf() < 0.3:
		acc.append("Hat_Cap")
	if r.randf() < 0.3:
		acc.append("Hair_Long")
	elif r.randf() < 0.15:
		acc.append("Hair_Bun")
	if r.randf() < 0.12:
		acc.append("Sunglasses")
	if r.randf() < 0.12:
		acc.append("Beard")
	if r.randf() < 0.25:
		acc.append("PhotoCamera")  # day-tripper with a camera
	look["acc"] = acc
	return look


## Logical clip name ("walk") -> Blender action name ("AN_Walk").
static func clip(n: String) -> String:
	return "AN_" + n.capitalize().replace(" ", "")


func bone(name: String) -> int:
	return skeleton.find_bone(name) if skeleton else -1


func set_shadow_only(on: bool) -> void:
	for mi in Art.meshes(model):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if on else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func set_bubble(text: String, color: Color = Color.WHITE) -> void:
	if bubble == null:
		return
	bubble.text = text
	bubble.modulate = color
	bubble.visible = text != ""


## Tools sit in the right hand via a BoneAttachment3D. The offset is expressed
## in model space at the rest pose so it does not depend on bone axes.
func hold_tool(id: String, color: Color = Color.TRANSPARENT) -> void:
	if tool_node:
		var holder := tool_node.get_parent()
		if holder is BoneAttachment3D:
			holder.queue_free()
		else:
			tool_node.queue_free()
		tool_node = null
	var b := bone("RightForeArm")
	if id == "" or b < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = "RightForeArm"
	skeleton.add_child(att)
	tool_node = Art.model(id)
	var rest := skeleton.get_bone_global_rest(b)
	var want := Transform3D(Basis.from_euler(Vector3(0.9, 0, 0)), rest.origin + Vector3(0, -0.3, 0.02))
	tool_node.transform = rest.affine_inverse() * want
	att.add_child(tool_node)
	if color != Color.TRANSPARENT:
		Art.tint(tool_node, "Blade", color)


func kick() -> void:
	play_once("kick")


func play_once(n: String) -> void:
	if player == null or not player.has_animation(clip(n)):
		return
	_oneshot = n
	player.play(clip(n), 0.08)
	player.seek(0.0, true)
	_playing = n


func _on_anim_finished(n: StringName) -> void:
	if _oneshot != "" and String(n) == clip(_oneshot):
		_oneshot = ""
		_playing = ""


func _play(n: String, blend: float = 0.2) -> void:
	if player == null:
		return
	if not player.has_animation(clip(n)):
		n = "idle"
	if _playing == n:
		return
	_playing = n
	player.play(clip(n), blend)


func _after_anim() -> void:
	if _head_scale != 1.0 and skeleton:
		var h := bone("Head")
		if h >= 0:
			skeleton.set_bone_pose_scale(h, Vector3.ONE * _head_scale)


func _process(delta: float) -> void:
	_t += delta
	if bubble and bubble.visible:
		bubble.position.y = 2.35 + sin(_t * 4.0) * 0.06
	if ragdolled:
		_drive_ragdoll()
		return
	if player == null:
		return
	if _oneshot == "":
		_play(anim)
	if _playing == "walk" or _playing == "run":
		player.speed_scale = clampf(speed * (1.6 if _playing == "walk" else 1.0), 0.5, 1.6)
	else:
		player.speed_scale = 1.0


## While ragdolled every driven bone copies its rigid body; bones in between
## (chest, neck, hands, feet) keep their pose relative to their parent.
func _drive_ragdoll() -> void:
	if skeleton == null or rag.is_empty():
		return
	var inv := skeleton.global_transform.affine_inverse()
	for b in rag.get("order", []):
		var e: Array = rag["drive"][b]
		var rb: RigidBody3D = e[0]
		if is_instance_valid(rb):
			skeleton.set_bone_global_pose(b, inv * (rb.global_transform * (e[1] as Transform3D)))


func stop_anim() -> void:
	if player:
		player.stop()
	_playing = ""
	_oneshot = ""
