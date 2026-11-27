shader_type spatial;
// Low Tide's standard surface. Tinted albedo x painted detail texture
// (triplanar, so generated meshes need no UVs), soft painterly light
// (painterly_light.gdshaderinc), low-frequency colour breakup, vertex-colour
// AO from the mesh kit, rain/tide wetness and an interactable highlight.
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://art/painterly_light.gdshaderinc"
#include "res://art/triplanar.gdshaderinc"

global uniform float wetness;
global uniform float tide_height;

uniform vec4 albedo : source_color = vec4(0.7, 0.7, 0.7, 1.0);
uniform sampler2D detail_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D macro_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform float detail_strength : hint_range(0.0, 1.5) = 1.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.6;
uniform float tex_scale = 0.5;               // tiles per metre
uniform bool object_space = true;            // texture sticks to the object
uniform float macro_strength : hint_range(0.0, 1.0) = 0.25;
uniform float macro_scale = 0.08;
uniform vec4 macro_tint : source_color = vec4(0.92, 0.9, 1.0, 1.0);  // hue the breakup drifts towards
uniform float vertex_ao : hint_range(0.0, 1.0) = 1.0;

uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.4;

uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

uniform float wet_response : hint_range(0.0, 1.0) = 0.6;   // rain darkening
uniform bool tide_wet = false;                           // darkens below the waterline
instance uniform float highlight : hint_range(0.0, 1.0) = 0.0;   // interactable glow (per instance)

varying vec3 v_tp;
varying vec3 v_tn;
varying vec3 v_wpos;
varying vec3 v_wnrm;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_tp = object_space ? VERTEX : v_wpos;
	v_tn = object_space ? NORMAL : v_wnrm;
}

void fragment() {
	vec3 b = tri_weights(normalize(v_tn), 4.0);
	vec3 p = v_tp * tex_scale;
	vec3 detail = tri_sample(detail_tex, p, b).rgb;
	vec3 col = albedo.rgb * mix(vec3(1.0), detail * 2.0, detail_strength);

	// Painterly breakup: big soft patches of value + hue drift (world space,
	// so neighbouring objects don't repeat the same pattern).
	vec3 wb = tri_weights(v_wnrm, 2.0);
	vec3 m = tri_sample(macro_tex, v_wpos * macro_scale, wb).rgb;
	col *= mix(1.0, 0.82 + m.r * 0.36, macro_strength);
	col = mix(col, col * macro_tint.rgb * 1.08, (m.g - 0.35) * macro_strength * 1.5);

	col *= mix(vec3(1.0), COLOR.rgb, vertex_ao);

	// Wetness: rain on up-facing surfaces, and everything below the tide line.
	float wet = wetness * wet_response * smoothstep(-0.2, 0.6, v_wnrm.y);
	if (tide_wet) {
		wet = max(wet, smoothstep(tide_height + 0.7, tide_height + 0.05, v_wpos.y));
	}
	col *= mix(1.0, 0.58, wet);

	// Normal: triplanar detail normal, converted to view space.
	vec3 pert = tri_normal(normal_tex, p, b) * normal_strength * (1.0 - wet * 0.5);
	vec3 n_space = normalize(v_tn + pert);
	vec3 n_world = object_space ? (MODEL_MATRIX * vec4(n_space, 0.0)).xyz : n_space;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	ALBEDO = col;
	ROUGHNESS = mix(roughness * (0.9 + detail.r * 0.2), 0.15, wet);
	METALLIC = metallic;
	SPECULAR = mix(specular, 0.6, wet);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = emission_color.rgb * emission_energy
		+ highlight * (vec3(1.0, 0.72, 0.38) * (pow(1.0 - ndv, 1.6) * 1.1 + 0.16) + col * 0.28);   // warm rim plus a lift, so flat faces read too
}
