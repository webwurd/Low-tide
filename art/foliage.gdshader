shader_type spatial;
// Grass / beach-grass tufts: alpha-scissored cards that sway with the global
// wind, shaded with soft up-facing normals (no card seams) and the shared
// painterly light. Each instance gets its own hue from its position.
render_mode blend_mix, depth_draw_opaque, cull_disabled;

#include "res://art/painterly_light.gdshaderinc"

global uniform float wind;
global uniform float wetness;

uniform sampler2D card_tex : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 tint_a : source_color = vec4(0.7, 0.6, 0.38, 1.0);
uniform vec4 tint_b : source_color = vec4(0.5, 0.5, 0.3, 1.0);
uniform float alpha_cut = 0.45;
uniform float sway = 0.12;

varying float v_rand;
varying float v_h;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	v_rand = hash12(origin.xz * 0.37);
	v_h = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * (1.2 + wind * 1.6) + wp.x * 0.35 + wp.z * 0.21;
	float gust = sin(t) * 0.6 + sin(t * 2.3 + 1.7) * 0.25;
	float bend = v_h * v_h * sway * (0.35 + wind) * gust;
	vec3 local_push = (inverse(mat3(MODEL_MATRIX)) * vec3(1.0, 0.0, 0.35)) * bend;
	VERTEX += local_push;
}

void fragment() {
	vec4 tex = texture(card_tex, UV);
	if (tex.a < alpha_cut) {
		discard;
	}
	vec3 tint = mix(tint_a.rgb, tint_b.rgb, v_rand);
	vec3 col = tex.rgb * 1.6 * tint * mix(0.55, 1.05, v_h);
	col *= mix(1.0, 0.65, wetness);
	ALBEDO = col;
	// Soft, mostly-up normals so tufts shade like a mass, not like cards.
	vec3 up = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	NORMAL = normalize(mix(NORMAL * (FRONT_FACING ? 1.0 : -1.0), up, 0.75));
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
	BACKLIGHT = vec3(0.35, 0.3, 0.15) * v_h;
}
