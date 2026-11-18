extends Control
## Opening splash: the animated Fikr AI Learning Forum signature (frames in
## assets/branding/intro_frames), then a burst of light as it finishes -
## a deep night-sky backdrop with drifting aurora, slowly turning god rays, a
## pulsing halo, a soft outer glow on the logo, a shine sweeping across it, a
## flash as it lands, a twinkling flare on the little star and drifting sparkles.
## Any key / click / button skips. Then the main menu.

const FRAMES := 46  # the Fikr signature animation, keyed onto transparency
const FPS := 25.0
const ANIM_START := 0.45  # when the signature starts drawing
const ANIM_END := ANIM_START + FRAMES / FPS  # ...and when the big glow hits
var LOGO: Texture2D
var _frames: Array[Texture2D] = []
const NEXT := "res://scenes/main_menu.tscn"
const LENGTH := ANIM_END + 1.5  # short hold after the signature

var _logo: TextureRect
var _logo_mat: ShaderMaterial
var _flare: Control
var _flash: ColorRect
var _fade: ColorRect
var _t := 0.0
var _leaving := false
var _rays: Control
var _halo: Control
var _sparks: CPUParticles2D

const BG_SHADER := """
shader_type canvas_item;
uniform float t = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float r = length(uv);
	vec3 col = mix(vec3(0.05, 0.16, 0.26), vec3(0.008, 0.02, 0.05), smoothstep(0.0, 0.85, r));
	// slow aurora ribbons
	float n = noise(vec2(uv.x * 2.2 + t * 0.05, uv.y * 5.0 - t * 0.12)) * noise(vec2(uv.x * 4.0 - t * 0.07, uv.y * 3.0));
	col += vec3(0.05, 0.35, 0.45) * smoothstep(0.25, 0.6, n) * 0.5 * (1.0 - smoothstep(0.2, 0.8, r));
	// tiny background stars
	vec2 g = floor(UV * vec2(160.0, 90.0));
	float s = step(0.996, hash(g)) * (0.5 + 0.5 * sin(t * 3.0 + hash(g + 3.0) * 40.0));
	col += vec3(0.7, 0.9, 1.0) * s * 0.6;
	COLOR = vec4(col, 1.0);
}
"""

const RAYS_SHADER := """
shader_type canvas_item;
render_mode blend_add;
uniform float t = 0.0;
uniform float strength = 0.0;
void fragment() {
	vec2 uv = UV - 0.5;
	float a = atan(uv.y, uv.x);
	float r = length(uv);
	float rays = pow(abs(sin(a * 9.0 + t * 0.25)), 18.0) + 0.6 * pow(abs(sin(a * 5.0 - t * 0.17 + 1.3)), 24.0);
	float fall = smoothstep(0.5, 0.05, r) * smoothstep(0.0, 0.08, r);
	COLOR = vec4(vec3(0.35, 0.8, 1.0) * rays * fall * strength, 1.0);
}
"""

const HALO_SHADER := """
shader_type canvas_item;
render_mode blend_add;
uniform float strength = 0.0;
uniform vec3 tint = vec3(0.45, 0.85, 1.0);
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float g = exp(-r * r * 3.2) * 0.9 + exp(-r * r * 18.0) * 0.6;
	COLOR = vec4(tint * g * strength, 1.0);
}
"""

const LOGO_SHADER := """
shader_type canvas_item;
uniform float shine = -1.0;   // position of the shine band across the logo (-0.5 .. 1.5)
uniform float glow = 0.0;     // outer glow strength
uniform float lift = 0.0;     // brightens the dark text so it reads on the night sky
uniform vec3 glow_col = vec3(0.4, 0.85, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.a = min(c.a * 1.8, 1.0);  // the keyed signature is semi-transparent; make it solid
	// soft outer glow: average alpha around the pixel
	float a = 0.0;
	for (int i = 0; i < 16; i++) {
		float ang = float(i) * 0.3926991;
		a += texture(TEXTURE, UV + vec2(cos(ang), sin(ang)) * TEXTURE_PIXEL_SIZE * 9.0).a;
		a += texture(TEXTURE, UV + vec2(cos(ang + 0.2), sin(ang + 0.2)) * TEXTURE_PIXEL_SIZE * 20.0).a * 0.6;
	}
	a /= 25.6;
	vec3 col = c.rgb + (vec3(0.55, 0.85, 1.0) - c.rgb) * lift * (1.0 - dot(c.rgb, vec3(0.33)));
	float band = 1.0 - smoothstep(0.0, 0.09, abs((UV.x + UV.y * 0.6) - shine));
	col += vec3(1.0) * band * 0.85 * c.a;
	vec3 g = glow_col * glow * a * (1.0 - c.a);
	COLOR = vec4(col * c.a + g, max(c.a, a * glow));
}
"""

const FLARE_SHADER := """
shader_type canvas_item;
render_mode blend_add;
uniform float strength = 0.0;
uniform float t = 0.0;
void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	float core = exp(-dot(uv, uv) * 30.0);
	float cross = exp(-abs(uv.y) * 60.0) * exp(-abs(uv.x) * 2.2) + exp(-abs(uv.x) * 60.0) * exp(-abs(uv.y) * 2.2);
	float ring = exp(-pow((length(uv) - 0.45) * 14.0, 2.0)) * 0.15;
	float tw = 0.75 + 0.25 * sin(t * 6.0);
	COLOR = vec4(vec3(0.75, 0.95, 1.0) * (core * 1.6 + cross * 0.9 * tw + ring) * strength, 1.0);
}
"""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# automated runs go straight to the menu
	var args := OS.get_cmdline_user_args()
	for a in ["--autotest", "--shots", "--look", "--crowd", "--menushot"]:
		if args.has(a):
			_go.call_deferred()
			return
	for i in range(FRAMES):
		_frames.append(load("res://assets/branding/intro_frames/f%02d.png" % i))
	LOGO = _frames[FRAMES - 1]
	var vs := get_viewport_rect().size
	var bg := _rect(BG_SHADER, Vector2.ZERO, vs)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var lh := vs.y * 0.72
	var lw := lh * float(LOGO.get_width()) / float(LOGO.get_height())
	var center := vs * 0.5
	_rays = _rect(RAYS_SHADER, center - Vector2.ONE * lh * 1.1, Vector2.ONE * lh * 2.2, "rays")
	_halo = _rect(HALO_SHADER, center - Vector2(lh * 0.9, lh * 0.9), Vector2.ONE * lh * 1.8, "halo")
	# sparkles drifting up around the logo
	var sp := CPUParticles2D.new()
	sp.position = center
	sp.amount = 70
	sp.lifetime = 3.2
	sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sp.emission_rect_extents = Vector2(lw * 0.6, lh * 0.5)
	sp.direction = Vector2(0, -1)
	sp.spread = 25.0
	sp.gravity = Vector2.ZERO
	sp.initial_velocity_min = 8.0
	sp.initial_velocity_max = 30.0
	sp.scale_amount_min = 0.15
	sp.scale_amount_max = 0.5
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.3, 1))
	curve.add_point(Vector2(1, 0))
	sp.scale_amount_curve = curve
	sp.color = Color(0.7, 0.95, 1.0, 0.9)
	sp.texture = _dot_texture()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = add
	sp.emitting = false
	add_child(sp)
	_sparks = sp
	# the logo
	_logo = TextureRect.new()
	_logo.texture = _frames[0]
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.size = Vector2(lw, lh)
	_logo.position = center - _logo.size * 0.5
	_logo.pivot_offset = _logo.size * 0.5
	_logo_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = LOGO_SHADER
	_logo_mat.shader = sh
	_logo.material = _logo_mat
	add_child(_logo)
	# twinkling flare on the little star (top right of the logo)
	_flare = _rect(FLARE_SHADER, Vector2.ZERO, Vector2.ONE * lh * 0.5, "flare")
	_flare.position = _logo.position + Vector2(lw * 0.69, lh * 0.12) - _flare.size * 0.5
	_flash = ColorRect.new()
	_flash.color = Color(0.8, 0.95, 1.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_play()
	for a in args:  # visual check: --introshot=DIR saves frames along the timeline
		if a.begins_with("--introshot="):
			_shots(a.substr(12))


func _shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var last := 0.0
	for t in [0.6, 1.0, 1.6, 2.1, 2.35, 2.5, 2.9, 3.5]:
		await get_tree().create_timer(t - last).timeout
		last = t
		get_viewport().get_texture().get_image().save_png(dir.path_join("intro_%.2f.png" % t))
	get_tree().quit()


func _rect(code: String, pos: Vector2, sz: Vector2, meta := "") -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	var s := Shader.new()
	s.code = code
	m.shader = s
	r.material = m
	if meta != "":
		r.set_meta("fx", meta)
	add_child(r)
	return r


func _dot_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t


func _fx(name: String) -> ShaderMaterial:
	for c in get_children():
		if c.has_meta("fx") and c.get_meta("fx") == name:
			return (c as CanvasItem).material as ShaderMaterial
	return null


func _play() -> void:
	var E := ANIM_END
	_logo_mat.set_shader_parameter("lift", 0.8)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.4)
	tw.parallel().tween_method(func(v: float) -> void: _fx("halo").set_shader_parameter("strength", v), 0.0, 0.35, 1.0).set_delay(0.3)
	tw.parallel().tween_method(func(v: float) -> void: _logo_mat.set_shader_parameter("glow", v), 0.0, 0.4, 1.2).set_delay(0.4)
	# the signature finishes -> burst of light
	tw.parallel().tween_property(_flash, "color:a", 0.18, 0.06).set_delay(E)
	tw.parallel().tween_property(_flash, "color:a", 0.0, 0.8).set_delay(E + 0.06)
	tw.parallel().tween_property(_logo, "scale", Vector2.ONE * 1.06, 0.12).set_delay(E)
	tw.parallel().tween_property(_logo, "scale", Vector2.ONE, 0.7).set_delay(E + 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(v: float) -> void: _fx("rays").set_shader_parameter("strength", v), 0.0, 0.6, 0.15).set_delay(E)
	tw.parallel().tween_method(func(v: float) -> void: _fx("rays").set_shader_parameter("strength", v), 0.6, 0.3, 0.9).set_delay(E + 0.15)
	tw.parallel().tween_method(func(v: float) -> void: _fx("halo").set_shader_parameter("strength", v), 0.9, 0.55, 0.9).set_delay(E)
	tw.parallel().tween_method(func(v: float) -> void: _logo_mat.set_shader_parameter("glow", v), 1.6, 1.0, 0.9).set_delay(E)
	tw.parallel().tween_method(func(v: float) -> void: _fx("flare").set_shader_parameter("strength", v), 1.6, 1.0, 0.6).set_delay(E)
	tw.parallel().tween_method(func(v: float) -> void: _logo_mat.set_shader_parameter("shine", v), -0.4, 1.8, 0.8).set_delay(E + 0.1)
	tw.parallel().tween_callback(func() -> void:
		_sparks.emitting = true
		_sparks.restart()).set_delay(E)
	tw.parallel().tween_property(_fade, "color:a", 1.0, 0.4).set_delay(LENGTH - 0.4)
	tw.tween_callback(_go)

## Everything is placed from the CURRENT window size every frame (the window
## resizes right after start-up; placing once left the effects off-centre).
func _layout() -> void:
	var vs := get_viewport_rect().size
	var lh := vs.y * 0.72
	var lw := lh * float(LOGO.get_width()) / float(LOGO.get_height())
	var center := vs * 0.5
	_logo.size = Vector2(lw, lh)
	_logo.position = center - _logo.size * 0.5
	_logo.pivot_offset = _logo.size * 0.5
	var star := _logo.position + Vector2(lw * 0.5, lh * 0.3)  # the big star: rays and halo come from it
	_rays.size = Vector2.ONE * lh * 2.0
	_rays.position = star - _rays.size * 0.5
	_halo.size = Vector2.ONE * lh * 1.2
	_halo.position = star - _halo.size * 0.5
	_flare.size = Vector2.ONE * lh * 0.5
	_flare.position = _logo.position + Vector2(lw * 0.69, lh * 0.12) - _flare.size * 0.5
	_sparks.position = center
	_sparks.emission_rect_extents = Vector2(lw * 0.6, lh * 0.5)


func _process(delta: float) -> void:
	_t += delta
	if _frames.size() > 0 and _logo:
		_logo.texture = _frames[clampi(int((_t - ANIM_START) * FPS), 0, FRAMES - 1)]
	if _logo:
		_layout()
	for c in get_children():
		if c is CanvasItem and (c as CanvasItem).material is ShaderMaterial:
			var m := (c as CanvasItem).material as ShaderMaterial
			if m != _logo_mat:
				m.set_shader_parameter("t", _t)
	if _logo:
		var pulse := 0.55 + 0.06 * sin(_t * 2.2)
		var h := _fx("halo")
		if h and _t > ANIM_END + 0.9:
			h.set_shader_parameter("strength", pulse)


func _input(event: InputEvent) -> void:
	if _t < 0.4 or _leaving:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.25)
		tw.tween_callback(_go)


func _go() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file(NEXT)
