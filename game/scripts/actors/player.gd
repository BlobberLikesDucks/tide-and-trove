class_name Player
extends CharacterBody3D
## First-person paleontologist. Eye-height camera with Blender view-model arms
## (AN_FP_* clips) that hold whatever is selected in the hotbar. Tools are used
## with the Use button (LMB): shovel / pickaxe dig the node you look at, the
## detector scans while held. Interact (E) is for objects; Q drops the held item,
## X trashes it (never the vital tools). A look ray (not a fat sphere) picks the
## object under the crosshair, so prompts only show when you face the thing.

# Movement tuning lives in GameConfig (res://data/game_config.tres).
var WALK: float:
	get: return GameConfig.get_cfg().walk_speed
var SPRINT: float:
	get: return GameConfig.get_cfg().sprint_speed
var JUMP: float:
	get: return GameConfig.get_cfg().jump_velocity
var GRAVITY: float:
	get: return GameConfig.get_cfg().gravity
var EYE: float:
	get: return GameConfig.get_cfg().eye_height
var REACH: float:
	get: return GameConfig.get_cfg().reach
const LOOP_CLIPS := ["AN_FP_Idle", "AN_FP_HoldTool", "AN_FP_Dig", "AN_FP_HoldPick", "AN_FP_Mine", "AN_FP_Detector", "AN_FP_HoldItem"]

## Third-person body (casts the player's shadow only).
@export var body_look: Dictionary = {"Skin": Color("e0ac83"), "Shirt": Color("c8b27a"), "Pants": Color("6b5a3e"), "Hat": Color("d9c08c"),
	"Hair": Color("5a3a22"), "Pack": Color("8a6a3a"), "acc": ["Hat_Safari", "Backpack"]}
## Colours of the first-person sleeves and hands.
@export var arm_skin: Color = Color("e0ac83")
@export var arm_shirt: Color = Color("c8b27a")

# Laid out in res://scenes/actors/player.tscn
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var fp: Node3D = $Head/Camera3D/ViewModel
@onready var arms: Node3D = $Head/Camera3D/ViewModel/Arms
@onready var aim: RayCast3D = $Head/Camera3D/Aim
var visual: CharVisual
var arm_anim: AnimationPlayer
var grip_r: Node3D
var held_node: Node3D
var _held_key := ""
var focus: Interactable
var focus_dig: DigNode
var cam_yaw := PI
var cam_pitch := -0.1
var locked := false
var digging := false
var dig_node: DigNode
var dig_t := 0.0
var dig_total := 0.0
var _dig_sfx_t := 0.0
var _shove_cd := 0.0
var _oneshot_t := 0.0
var _ping_t := 0.0
var _step_t := 0.0
var _bob := 0.0
var _equip_t := 0.0
var _clip := ""


func _ready() -> void:
	visual = CharVisual.new()
	add_child(visual)
	visual.setup(body_look)
	visual.set_shadow_only(true)
	head.position.y = EYE
	aim.target_position = Vector3(0, 0, -REACH)
	Art.prepare(arms)
	grip_r = arms.find_child("GripR", true, false)
	arm_anim = arms.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if arm_anim:
		for n in LOOP_CLIPS:
			if arm_anim.has_animation(n):
				arm_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for mi in Art.meshes(arms):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.layers = 2
	Art.tint(arms, "Skin", arm_skin)
	Art.tint(arms, "Shirt", arm_shirt)
	GameState.backpack_changed.connect(_on_items_changed)
	GameState.changed.connect(_on_items_changed)
	GameState.select_slot(GameState.hotbar_sel)
	_refresh_held()


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = 0.0024 * float(Settings.get_v("sensitivity"))
		cam_yaw -= event.relative.x * sens
		var inv := -1.0 if Settings.get_v("invert_y") else 1.0
		cam_pitch = clampf(cam_pitch - event.relative.y * sens * inv, -1.45, 1.4)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k >= KEY_1 and k <= KEY_9:
			_select(k - KEY_1)
			return
	if event.is_action_pressed("interact"):
		_do_interact()
	elif event.is_action_pressed("use_item"):
		use_held()
	elif event.is_action_pressed("hotbar_next"):
		_select(GameState.hotbar_sel + 1)
	elif event.is_action_pressed("hotbar_prev"):
		_select(GameState.hotbar_sel - 1)
	elif event.is_action_pressed("drop_item"):
		drop_held()
	elif event.is_action_pressed("trash_item"):
		trash_held()
	elif event.is_action_pressed("jump") and is_on_floor() and not digging:
		velocity.y = JUMP


func forward() -> Vector3:
	return -camera.global_transform.basis.z


func _physics_process(delta: float) -> void:
	_shove_cd = maxf(0.0, _shove_cd - delta)
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if not locked and look.length() > 0.05:
		var s: float = 2.6 * float(Settings.get_v("sensitivity"))
		cam_yaw -= look.x * s * delta
		var inv := -1.0 if Settings.get_v("invert_y") else 1.0
		cam_pitch = clampf(cam_pitch - look.y * s * delta * 0.7 * inv, -1.45, 1.4)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var input := Vector2.ZERO if (locked or digging) else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Basis(Vector3.UP, cam_yaw) * Vector3(input.x, 0, input.y)
	var sprinting := Input.is_action_pressed("sprint") and not locked
	var spd := (SPRINT if sprinting else WALK) * GameState.speed_mult()
	var target := dir * spd
	var accel := 14.0 if is_on_floor() else 4.0
	velocity.x = move_toward(velocity.x, target.x, accel * spd * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * spd * delta)
	move_and_slide()
	head.rotation = Vector3(cam_pitch, cam_yaw, 0)
	visual.rotation.y = cam_yaw
	var hv := Vector2(velocity.x, velocity.z)
	var moving := hv.length() > 0.3 and is_on_floor()
	if digging:
		_update_dig(delta)
	elif moving:
		visual.anim = "run" if sprinting else "walk"
		visual.speed = hv.length() / (SPRINT * GameState.speed_mult())
		_step_t -= delta * hv.length()
		if _step_t <= 0.0:
			_step_t = 2.2
			Audio.sfx("step", randf_range(0.8, 1.2), -14.0)
	else:
		visual.anim = "idle"
	_animate_view(delta, moving, sprinting)
	_update_focus()
	_update_detector(delta)
	if global_position.y < -20.0:
		global_position = Vector3(0, 1, -26)
		velocity = Vector3.ZERO

# ------------------------------------------------------------ view model ---
func _animate_view(delta: float, moving: bool, sprinting: bool) -> void:
	var f := 11.0 if sprinting else 7.5
	if moving:
		_bob += delta * f
	var amt := (0.022 if sprinting else 0.014) if moving else 0.0
	camera.position.y = lerpf(camera.position.y, sin(_bob * 2.0) * amt * 0.8, 0.2)
	_equip_t = maxf(0.0, _equip_t - delta * 4.0)
	var sway := Vector3(sin(_bob) * amt, -absf(cos(_bob)) * amt * 0.8 - _equip_t * 0.25, 0)
	fp.position = fp.position.lerp(sway, minf(1.0, delta * 12.0))
	_oneshot_t = maxf(0.0, _oneshot_t - delta)
	if _oneshot_t <= 0.0:
		_play(_base_clip())


func _base_clip() -> String:
	if digging and is_instance_valid(dig_node):
		return "AN_FP_Mine" if DB.NODE_TYPES[dig_node.kind]["tool"] == "pick" else "AN_FP_Dig"
	var h := GameState.held()
	if h.is_empty():
		return "AN_FP_Idle"
	if h["t"] == "tool":
		match String(h["kind"]):
			"shovel":
				return "AN_FP_HoldTool"
			"pick":
				return "AN_FP_HoldPick"
			"detector":
				return "AN_FP_Detector"
	return "AN_FP_HoldItem"


func _play(clip: String, oneshot := false) -> void:
	if arm_anim == null or not arm_anim.has_animation(clip):
		return
	if oneshot:
		arm_anim.play(clip, 0.08)
		_oneshot_t = arm_anim.get_animation(clip).length
		_clip = clip
		return
	if clip != _clip:
		arm_anim.play(clip, 0.22)
		_clip = clip


func _on_items_changed() -> void:
	_refresh_held()


## Puts the selected hotbar item into the right hand (tools, finds, trash, cups).
func _refresh_held() -> void:
	var h := GameState.held()
	var key := JSON.stringify(h)
	if key == _held_key and held_node != null:
		return
	_held_key = key
	if held_node:
		held_node.queue_free()
		held_node = null
	var tp_tool := ""
	if not h.is_empty() and grip_r:
		var mid := ""
		var sc := 1.0
		var pos := Vector3.ZERO
		match String(h["t"]):
			"tool":
				mid = {"shovel": "shovel", "pick": "pickaxe", "detector": "detector"}.get(String(h["kind"]), "")
				tp_tool = mid
			"gem":
				mid = DB.GEMS[h["id"]]["model"] if DB.GEMS.has(h["id"]) else "gem"
				sc = 0.55
				pos = Vector3(0, 0.035, -0.005)
			"geode":
				mid = "geode"
				sc = 0.42
				pos = Vector3(0, 0.03, 0)
			"encased":
				mid = "fossil_rock"
				sc = 0.42
				pos = Vector3(0, 0.03, 0)
			"trash":
				mid = "trash"
				sc = 0.75
				pos = Vector3(0, 0.03, 0)
			"serve":
				mid = String(DB.BUILD.get(String(h.get("stand", "")), {}).get("serve", "held_cup"))
		if mid != "":
			held_node = Art.model(mid)
			Art.strip_collision(held_node)
			held_node.scale = Vector3.ONE * sc
			held_node.position = pos
			grip_r.add_child(held_node)
			for mi in Art.meshes(held_node):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.layers = 2
			if h["t"] == "tool":
				var td := GameState.tool_def(String(h["kind"]))
				Art.tint(held_node, "Blade", td.get("color", Color("b8c0c8")))
			elif h["t"] == "gem" and DB.GEMS.has(h["id"]):
				Art.tint(held_node, "Gem" if mid == "gem" else "Fleck", DB.GEMS[h["id"]]["color"], 0.6)
			elif h["t"] == "serve":
				var fill := held_node.find_child("Fill", true, false)
				if fill is Node3D:
					(fill as Node3D).visible = bool(h.get("full", false))
	visual.hold_tool(tp_tool, GameState.tool_def(String(h.get("kind", ""))).get("color", Color.TRANSPARENT) if tp_tool != "" else Color.TRANSPARENT)
	# the third-person body only casts the shadow: its copy of the tool must not be seen either
	if visual.tool_node:
		for mi in Art.meshes(visual.tool_node):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _select(i: int) -> void:
	if digging:
		cancel_dig()
	var before := GameState.hotbar_sel
	GameState.select_slot(i)
	if GameState.hotbar_sel != before:
		_equip_t = 1.0
		Audio.sfx("whoosh", 1.6, -16.0)
	_refresh_held()

# ------------------------------------------------------------------- aim ---
func _interactable_of(c: Object) -> Interactable:
	if c is Interactable:
		return c
	var n := c as Node
	while n != null and not (n is World):
		if n.has_meta("tt_inter"):
			var it: Variant = n.get_meta("tt_inter")
			if it is Interactable and is_instance_valid(it):
				return it
		n = n.get_parent()
	return null


func _update_focus() -> void:
	focus = null
	focus_dig = null
	if aim.is_colliding():
		var it := _interactable_of(aim.get_collider())
		if it and it.enabled and it.is_inside_tree():
			if it.owner_node is DigNode:
				focus_dig = it.owner_node
			else:
				focus = it
	if locked:
		Events.prompt.emit("")
	elif digging:
		pass
	elif focus_dig and not focus_dig.depleted:
		Events.prompt.emit(_dig_prompt(focus_dig))
	elif focus:
		Events.prompt.emit("%s  %s" % [Settings.prompt("interact"), focus.prompt_text()])
	else:
		Events.prompt.emit("")


func _dig_prompt(n: DigNode) -> String:
	var def: Dictionary = DB.NODE_TYPES[n.kind]
	var err := n.requirement_error()
	if err != "":
		return "%s  (%s)" % [def["name"], err]
	var need: String = "shovel" if def["tool"] == "shovel" else "pick"
	if GameState.held_tool() != need:
		return "%s - hold your %s (hotbar) and press %s" % [def["name"], GameState.TOOL_NAMES[need], Settings.prompt("use_item")]
	return "%s  %s %s" % [Settings.prompt("use_item"), "Dig" if need == "shovel" else "Break", def["name"]]


func _do_interact() -> void:
	if digging:
		return
	if focus_dig and focus == null:
		Events.say(_dig_prompt(focus_dig), Color.WHITE)
		return
	if focus == null:
		return
	focus.activate(self)
	if _oneshot_t <= 0.0:
		_play("AN_FP_Grab", true)


func face(p: Vector3) -> void:
	var d := p - global_position
	cam_yaw = atan2(-d.x, -d.z)

# --------------------------------------------------------------- hotbar ---
## The Use button. Aimed at a guest or staff member it swings whatever you hold
## at them (bare hands = a shove) and ragdolls them; otherwise the held tool does
## its job. Every item has its own first-person use animation.
func use_held() -> void:
	if digging:
		return
	if _shove_target() != null:
		_do_shove()
		return
	var tool := GameState.held_tool()
	match tool:
		"shovel", "pick":
			if focus_dig and not focus_dig.depleted:
				var need: String = "shovel" if DB.NODE_TYPES[focus_dig.kind]["tool"] == "shovel" else "pick"
				if need != tool:
					Events.say("That needs your %s." % GameState.TOOL_NAMES[need], UIKit.CORAL)
					Audio.sfx("error")
					return
				start_dig(focus_dig)
				return
			Audio.sfx("whoosh", 1.2 if tool == "shovel" else 0.9, -10.0)
		"detector":
			_ping_t = 0.0
			Audio.sfx("ping", 1.0, -4.0)
		_:
			var h := GameState.held()
			if h.get("t", "") == "trash":
				Events.say("Throw trash in a trash bin (%s while looking at a bin)." % Settings.prompt("interact"), Color.WHITE)
			Audio.sfx("whoosh", 1.4, -12.0)
	_play_use()


## First-person use animation for whatever is in the hand.
func _use_clip() -> String:
	var h := GameState.held()
	if h.is_empty():
		return "AN_FP_Shove"
	match String(h.get("t", "")):
		"tool":
			return {"shovel": "AN_FP_Dig", "pick": "AN_FP_Mine", "detector": "AN_FP_Detector"}.get(String(h["kind"]), "AN_FP_Grab")
		"trash", "serve":
			return "AN_FP_Throw"
	return "AN_FP_Grab"


func _play_use() -> void:
	var clip := _use_clip()
	_play(clip, true)
	if arm_anim and arm_anim.has_animation(clip):
		_oneshot_t = minf(arm_anim.get_animation(clip).length, 0.7)


func drop_held() -> void:
	if digging:
		return
	var h := GameState.held()
	if h.is_empty():
		return
	if h["t"] == "serve":
		Events.say("Serve it, or trash it with %s." % Settings.prompt("trash_item"), Color.WHITE)
		return
	GameState.take_held()
	var p := global_position + Vector3(forward().x, 0, forward().z).normalized() * 1.1
	Pickup.spawn(get_parent(), h, Vector3(p.x, global_position.y + 0.02, p.z))
	_play("AN_FP_Throw", true)
	Audio.sfx("whoosh", 0.9, -8.0)
	Events.say("Dropped %s.%s" % [GameState.item_name(h), "  (Lost it? Re-issue it at the gear rack in the Prep Lab.)" if GameState.is_vital(h) else ""], Color.WHITE)
	_refresh_held()


func trash_held() -> void:
	if digging:
		return
	var h := GameState.held()
	if h.is_empty():
		return
	if GameState.is_vital(h):
		Events.say("You can't trash your %s - it's vital! Drop it (%s) if you must." % [GameState.item_name(h), Settings.prompt("drop_item")], UIKit.CORAL)
		Audio.sfx("error")
		return
	if h["t"] == "trash":
		Events.say("Put trash in a trash bin - look at a bin and press %s." % Settings.prompt("interact"), UIKit.CORAL)
		Audio.sfx("error")
		return
	GameState.take_held()
	_play("AN_FP_Throw", true)
	Audio.sfx("whoosh", 0.8, -6.0)
	Events.say("Trashed %s." % GameState.item_name(h), UIKit.MUTED)
	_refresh_held()

# -------------------------------------------------------------------- dig ---
func start_dig(node: DigNode) -> void:
	var err := node.requirement_error()
	if err != "":
		Events.say(err, UIKit.CORAL)
		Audio.sfx("error")
		return
	if GameState.backpack_full():
		Events.say("Backpack full! Unload at the Prep Lab storage crates.", UIKit.CORAL)
		Audio.sfx("error")
		return
	var def: Dictionary = DB.NODE_TYPES[node.kind]
	var td := GameState.tool_def(def["tool"])
	digging = true
	dig_node = node
	dig_t = 0.0
	dig_total = float(def["time"]) / float(td.get("speed", 1.0))
	visual.anim = "dig"
	_dig_sfx_t = 0.0


func _update_dig(delta: float) -> void:
	dig_t += delta
	_dig_sfx_t -= delta
	if not is_instance_valid(dig_node):
		cancel_dig()
		return
	if _dig_sfx_t <= 0.0:
		_dig_sfx_t = 0.4
		Audio.sfx(String(DB.NODE_TYPES[dig_node.kind]["sfx"]))
		FX.burst(dig_node.get_parent(), dig_node.global_position + Vector3(0, 0.35, 0), "rock" if String(DB.NODE_TYPES[dig_node.kind]["tool"]) == "pick" else "sand")
	Events.prompt.emit("Digging... %d%%" % int(100.0 * dig_t / maxf(dig_total, 0.01)))
	if dig_t >= dig_total:
		digging = false
		visual.anim = "idle"
		dig_node.harvest(self)
		dig_node = null


func cancel_dig() -> void:
	digging = false
	dig_node = null
	visual.anim = "idle"

# ------------------------------------------------------------------ shove ---
## Nearest guest / staff member in front of you within arm's (or tool's) reach.
func _shove_target() -> Node3D:
	var fwd := forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var best: Node3D = null
	var best_d := 2.8
	for a in World.instance.actors():
		if not is_instance_valid(a) or not a.has_method("knockback"):
			continue
		var d: Vector3 = a.global_position - global_position
		d.y = 0
		if d.length() < best_d and fwd.dot(d.normalized()) > 0.45:
			best_d = d.length()
			best = a
	return best


## Swing the held item (or bare hands) at whoever is in front: they ragdoll.
func _do_shove() -> void:
	if _shove_cd > 0.0 or digging:
		return
	_shove_cd = 0.7
	_play_use()
	visual.kick()
	Audio.sfx("whoosh")
	var best := _shove_target()
	if best:
		var dir := (best.global_position - global_position)
		dir.y = 0
		var force := 7.0 if GameState.held().is_empty() else 8.5  # tools hit a little harder
		best.knockback(dir.normalized() * force + Vector3.UP * 3.8, true)
		Audio.sfx("bonk")

# --------------------------------------------------------------- detector ---
func _update_detector(delta: float) -> void:
	GameState.detector_on = GameState.held_tool() == "detector" and int(GameState.tools["detector"]) > 0
	if not GameState.detector_on:
		Events.detector_ping.emit(-1.0)
		return
	var r := GameState.detector_radius()
	var nearest: DigNode = null
	var nd := r
	for n in World.instance.beach.hidden_nodes():
		var d := n.global_position.distance_to(global_position)
		if d < nd:
			nd = d
			nearest = n
	if nearest == null:
		Events.detector_ping.emit(0.0)
		return
	var strength := 1.0 - nd / r
	Events.detector_ping.emit(strength)
	_ping_t -= delta
	if _ping_t <= 0.0:
		_ping_t = lerpf(1.3, 0.12, strength)
		Audio.sfx("ping", 0.8 + strength * 0.8, -6.0)
	if nd < 2.4:
		nearest.reveal()
