// Inverted-hull ink outline (godot-shader skill), used as the cel material's
// next_pass. Back faces are pushed out along the normal and drawn flat; width is
// kept roughly constant on screen by scaling with view distance (clamped).
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, blend_mix, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.16, 0.12, 0.14, 1.0);
/** Outline thickness in metres at 1 m from the camera. */
uniform float outline_width : hint_range(0.0, 0.05) = 0.006;
/** Never thicker than this in world units (keeps far buildings clean). */
uniform float max_width : hint_range(0.0, 0.2) = 0.05;

void vertex() {
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float dist = max(-view_pos.z, 0.1);
	float w = min(outline_width * dist, max_width);
	VERTEX += normalize(NORMAL) * w;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
