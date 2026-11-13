shader_type spatial;
render_mode cull_disabled, specular_toon, diffuse_toon;

// Stylised ocean: rolling vertex waves, shallow -> deep gradient, foam crests.
uniform vec4 shallow_color : source_color = vec4(0.36, 0.84, 0.86, 1.0);
uniform vec4 deep_color : source_color = vec4(0.09, 0.42, 0.66, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float wave_height = 0.22;
uniform float shore_z = 47.0;

varying float v_height;
varying vec3 v_world;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = sin(w.x * 0.13 + TIME * 0.9) * 0.5
		+ sin(w.z * 0.21 - TIME * 1.25) * 0.35
		+ sin((w.x + w.z) * 0.37 + TIME * 1.9) * 0.15;
	VERTEX.y += h * wave_height;
	v_height = h;
	v_world = w;
}

void fragment() {
	float depth_t = clamp((v_world.z - shore_z) / 32.0, 0.0, 1.0);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, depth_t);
	float crest = smoothstep(0.62, 0.95, v_height);
	float shore_foam = smoothstep(4.0, 0.0, v_world.z - shore_z) * (0.55 + 0.45 * sin(v_world.x * 0.7 + TIME * 2.0));
	col = mix(col, foam_color.rgb, clamp(crest * 0.45 + shore_foam * 0.7, 0.0, 1.0));
	ALBEDO = col;
	ROUGHNESS = 0.12;
	SPECULAR = 0.55;
	ALPHA = mix(0.78, 0.94, depth_t);
}
