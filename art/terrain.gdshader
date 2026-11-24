shader_type spatial;
// Gannet Rock ground. Layers are chosen by height, slope and region, with
// painterly noise breaking every boundary:
//   sand (bars + beaches) -> wet sand below the live tide line
//   granite on steep faces, darker and weedier in the intertidal zone
//   winter grass on the upper slopes, moss on the summit
//   worn footpaths between the pier, the cottage and the lighthouse
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://art/painterly_light.gdshaderinc"
#include "res://art/triplanar.gdshaderinc"

global uniform float wetness;
global uniform float tide_height;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D moss_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D macro_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D sand_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec4 sand_col : source_color = vec4(0.72, 0.66, 0.54, 1.0);
uniform vec4 wet_sand_col : source_color = vec4(0.42, 0.38, 0.32, 1.0);
uniform vec4 rock_col : source_color = vec4(0.54, 0.52, 0.5, 1.0);
uniform vec4 rock_low_col : source_color = vec4(0.25, 0.27, 0.27, 1.0);
uniform vec4 weed_col : source_color = vec4(0.3, 0.29, 0.17, 1.0);
uniform vec4 grass_col : source_color = vec4(0.63, 0.54, 0.33, 1.0);
uniform vec4 grass_dry_col : source_color = vec4(0.45, 0.43, 0.26, 1.0);
uniform vec4 moss_col : source_color = vec4(0.36, 0.42, 0.3, 1.0);
uniform vec4 path_col : source_color = vec4(0.46, 0.4, 0.32, 1.0);
uniform float sand_scale = 0.35;
uniform float rock_scale = 0.2;
uniform float grass_scale = 0.28;
uniform float normal_strength = 0.8;
// Footpaths as segments (xz start, xz end).
uniform vec4 path_seg0 = vec4(0.0, 12.6, -1.6, 7.4);
uniform vec4 path_seg1 = vec4(-1.6, 7.4, 0.0, -1.0);
uniform vec4 path_seg2 = vec4(-1.6, 7.4, -6.8, 4.9);
uniform float path_width = 0.9;

varying vec3 v_wpos;
varying vec3 v_wnrm;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float seg_dist(vec2 p, vec4 s) {
	vec2 a = s.xy, b = s.zw;
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
	return length(p - (a + ab * t));
}

void fragment() {
	vec3 p = v_wpos;
	vec3 n = normalize(v_wnrm);
	vec3 b = tri_weights(n, 4.0);
	vec3 bm = tri_weights(n, 2.0);
	vec3 m = tri_sample(macro_tex, p * 0.03, bm).rgb;
	vec3 m2 = tri_sample(macro_tex, p * 0.11 + 0.37, bm).rgb;
	float slope = 1.0 - n.y;
	float h = p.y + (m.g - 0.5) * 0.9 + (m2.r - 0.5) * 0.4;

	// Masks.
	float ax = abs(p.x);
	float bars = smoothstep(21.0, 26.0, ax) * (1.0 - smoothstep(63.0, 69.0, ax));
	float sand_m = max(1.0 - smoothstep(1.0, 1.7, h), bars * (1.0 - smoothstep(2.0, 2.7, h)));
	float rock_m = smoothstep(0.24, 0.42, slope + (m.r - 0.5) * 0.25);
	float grass_m = smoothstep(3.4, 5.0, h) * (1.0 - rock_m);
	float moss_m = smoothstep(7.6, 9.6, h) * smoothstep(0.35, 0.65, m.b) * grass_m;

	vec3 rock_d = tri_sample(rock_tex, p * rock_scale, b).rgb * 2.0;
	vec3 sand_d = tri_sample(sand_tex, p * sand_scale, b).rgb * 2.0;
	vec3 grass_d = tri_sample(grass_tex, p * grass_scale, b).rgb * 2.0;
	vec3 moss_d = tri_sample(moss_tex, p * grass_scale * 1.3, b).rgb * 2.0;

	// Granite: darker and weedier in the intertidal zone, pink-grey above.
	vec3 rock = mix(rock_low_col.rgb, rock_col.rgb, smoothstep(1.2, 5.0, h)) * rock_d;
	rock = mix(rock, weed_col.rgb * rock_d, smoothstep(4.0, 2.6, h) * smoothstep(0.45, 0.7, m2.g) * 0.8);
	vec3 grass = mix(grass_dry_col.rgb, grass_col.rgb, m2.b) * grass_d;
	vec3 col = rock;
	col = mix(col, grass, grass_m);
	col = mix(col, moss_col.rgb * moss_d, moss_m);
	vec3 sand = mix(wet_sand_col.rgb, sand_col.rgb, smoothstep(0.4, 2.2, h)) * sand_d;
	col = mix(col, sand, sand_m * (1.0 - rock_m * 0.75));

	// Footpaths (trampled grass and bare earth).
	float d = min(seg_dist(p.xz, path_seg0), min(seg_dist(p.xz, path_seg1), seg_dist(p.xz, path_seg2)));
	float path_m = (1.0 - smoothstep(path_width * 0.6, path_width * 1.4, d + (m2.r - 0.5) * 0.9)) * step(3.5, p.y);
	col = mix(col, path_col.rgb * sand_d, path_m * 0.85);

	// Wet: everything below the current water line, the intertidal band, rain.
	float wet_tide = smoothstep(tide_height + 0.45, tide_height + 0.02, p.y);
	float intertidal = (1.0 - smoothstep(3.6, 4.5, p.y)) * 0.3;
	float wet = clamp(max(max(wet_tide, intertidal), wetness * 0.75 * smoothstep(0.3, 0.9, n.y)), 0.0, 1.0);
	col *= mix(1.0, 0.55, wet);

	// Normals: blend each layer's detail normal by its mask.
	vec3 pr = tri_normal(rock_nrm, p * rock_scale, b);
	vec3 ps = tri_normal(sand_nrm, p * sand_scale, b);
	vec3 pg = tri_normal(grass_nrm, p * grass_scale, b);
	vec3 pert = pr;
	pert = mix(pert, pg, grass_m);
	pert = mix(pert, ps, sand_m * (1.0 - rock_m * 0.75));
	vec3 nw = normalize(n + pert * normal_strength * (1.0 - wet_tide * 0.6));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);

	ALBEDO = col;
	ROUGHNESS = mix(mix(0.92, 0.85, sand_m), 0.12, wet_tide * 0.9 + wetness * 0.3);
	SPECULAR = mix(0.35, 0.6, wet);
}
