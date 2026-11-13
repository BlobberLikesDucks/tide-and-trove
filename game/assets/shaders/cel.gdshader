// Tide & Trove cel shader (godot-shader skill): hard-banded diffuse, a warm/cool
// shadow tint, a crisp toon specular blob and a fresnel rim. Every Blender-painted
// material is converted to this at load (Art.toon), so the hand-painted textures
// keep their detail while lighting snaps into clean stylized steps.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

/** Base colour (multiplied with the painted texture; Godot tints write here). */
uniform vec4 albedo_color : source_color = vec4(1.0);
/** Hand-painted colour bake from Blender. */
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
/** Optional tangent-space normal bake (sculpt pass). */
uniform sampler2D normal_texture : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_normal_map = false;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.6;
/** Number of light bands (2 = classic cel, 3-4 = softer anime look). */
uniform float bands : hint_range(1.0, 6.0, 1.0) = 3.0;
/** Width of the soft edge between bands (0 = razor sharp). */
uniform float band_softness : hint_range(0.0, 0.2) = 0.03;
/** Colour shadows are pushed toward (cool sea-blue keeps it sunny, never grey). */
uniform vec4 shadow_tint : source_color = vec4(0.42, 0.48, 0.72, 1.0);
/** How dark the darkest band gets (1 = no shadow). */
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.38;
uniform float specular_size : hint_range(0.0, 1.0) = 0.14;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.35;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.18;
uniform float rim_width : hint_range(0.0, 1.0) = 0.32;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 0.0;

// how much a surface faces straight up/down (0 = wall, 1 = floor); written in fragment, read in light
varying float v_flat;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb * albedo_color.rgb;
	ROUGHNESS = 0.8;
	SPECULAR = 0.3;
	if (use_normal_map) {
		NORMAL_MAP = texture(normal_texture, UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
	EMISSION = emission_color.rgb * emission_energy;
	// rim light from the view angle (stylized "back light" edge)
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = smoothstep(1.0 - rim_width, 1.0 - rim_width + 0.04, fres);
	// no rim on floors/ground: grazing views of flat ground would glow white
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_flat = smoothstep(0.55, 0.85, abs(wn.y));
	rim *= 1.0 - v_flat;
	EMISSION += rim_color.rgb * rim * rim_amount * ALBEDO;
}

void light() {
	// quantised Lambert
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float stepped = floor(ndl * bands) / bands;
	float frac_part = fract(ndl * bands);
	float edge = smoothstep(1.0 - band_softness * bands, 1.0, frac_part) / bands;
	float lit = clamp(stepped + edge, 0.0, 1.0);
	// only the sun gets a coloured "shadow band"; lamps fade to nothing outside their reach
	float base = LIGHT_IS_DIRECTIONAL ? shadow_floor : 0.0;
	float shade = mix(base, 1.0, lit);
	vec3 tint = mix(shadow_tint.rgb, vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR * shade * tint / PI;  // Godot multiplies ALBEDO in afterwards
	// toon specular blob
	vec3 h = normalize(VIEW + LIGHT);
	float s = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 48.0) * ATTENUATION;
	// floors stay matte: a toon highlight on a whole street or lawn reads as a white-out
	SPECULAR_LIGHT += LIGHT_COLOR * smoothstep(1.0 - specular_size, 1.0 - specular_size + 0.02, s) * specular_strength * (1.0 - v_flat);
}
