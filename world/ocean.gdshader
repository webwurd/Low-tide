shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
// Painterly sea: teal shallows over the sand, a lacy foam line where the water
// meets the island, soft foam streaks, sky reflection at grazing angles.
// Water depth comes from a baked terrain-height texture (same in every renderer).

uniform vec4 deep_color : source_color = vec4(0.11, 0.23, 0.30, 0.94);
uniform vec3 shallow_color : source_color = vec3(0.27, 0.52, 0.53);
uniform vec3 foam_color : source_color = vec3(0.93, 0.95, 0.92);
uniform vec3 sky_color : source_color = vec3(0.6, 0.72, 0.8);
uniform float wave_height = 0.14;
uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(-105.0, -105.0);
uniform float height_size = 210.0;

varying vec3 wpos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	float w = sin(VERTEX.x * 0.09 + TIME * 1.4) * wave_height
			+ cos(VERTEX.z * 0.08 + TIME * 1.1) * wave_height;
	VERTEX.y += w;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = (wpos.xz - height_origin) / height_size;
	float ground = -50.0;
	if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
		ground = texture(height_tex, uv).r;
	}
	float depth = max(wpos.y - ground, 0.0);

	float t = TIME;
	float wob = vnoise(wpos.xz * 0.9 + vec2(t * 0.35, -t * 0.2));
	float shore = depth + (wob - 0.5) * 0.5;

	vec3 col = mix(shallow_color, deep_color.rgb, smoothstep(0.1, 3.2, depth));
	// Sky reflection grows toward the horizon (fresnel).
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	col = mix(col, sky_color, clamp(fres * 0.85, 0.0, 0.85));

	// Foam: a rolling band at the waterline plus faint streaks on open water.
	float pulse = 0.5 + 0.5 * sin(t * 0.9 + wpos.x * 0.15 + wpos.z * 0.11);
	float line = 1.0 - smoothstep(0.12, 0.34 + pulse * 0.14, shore);
	float lace = smoothstep(0.42, 0.62, vnoise(wpos.xz * 2.6 + vec2(t * 0.2, t * 0.13)));
	float band = (1.0 - smoothstep(0.3, 0.85, shore)) * lace * 0.8;
	float streak = smoothstep(0.78, 0.9, vnoise(wpos.xz * vec2(0.45, 1.4) + vec2(t * 0.1, 0.0))) * 0.22;
	float foam = clamp(line + band + streak * smoothstep(1.0, 3.0, depth), 0.0, 1.0);
	col = mix(col, foam_color, foam);

	ALBEDO = col;
	ALPHA = mix(0.5, deep_color.a, smoothstep(0.0, 1.4, depth));
	ALPHA = max(ALPHA, foam);
	ROUGHNESS = mix(0.22, 0.6, foam);
	METALLIC = 0.35 * (1.0 - foam);
}
