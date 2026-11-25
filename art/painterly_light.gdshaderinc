// Shared light model for Low Tide's painterly materials.
//  - Wrapped, smoothed diffuse: soft terminators instead of hard N.L edges.
//  - Shadowed/turned-away regions get a slate-violet fill (global shadow_tint)
//    rather than going grey, the core of the Firewatch-like palette.
//  - A warm rim where the sun is behind or beside the surface.
//  - Simple GGX highlight (roughness from the material).
// Engine ambient + sky reflections still apply on top.

global uniform vec4 shadow_tint;
uniform float wrap : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_fill : hint_range(0.0, 1.0) = 0.55;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.35;
uniform float spec_strength : hint_range(0.0, 2.0) = 0.5;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float w = clamp((ndl + wrap) / (1.0 + wrap), 0.0, 1.0);
	float soft = w * w * (3.0 - 2.0 * w);
	vec3 lc = LIGHT_COLOR / PI;
	float lit = soft * ATTENUATION;
	DIFFUSE_LIGHT += lc * lit;
	if (LIGHT_IS_DIRECTIONAL) {
		// Coloured shadow: what the light would have added, tinted violet.
		DIFFUSE_LIGHT += lc * shadow_tint.rgb * (soft - lit) * shadow_fill;
		float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float back = clamp(dot(-VIEW, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
		float rim = pow(1.0 - ndv, 4.0) * back * back * ATTENUATION;
		DIFFUSE_LIGHT += lc * rim * rim_strength * 2.0;
	}
	vec3 h = normalize(VIEW + LIGHT);
	float ndh = clamp(dot(NORMAL, h), 0.0, 1.0);
	float r = max(ROUGHNESS, 0.04);
	float a2 = r * r * r * r;
	float d = a2 / (PI * pow(ndh * ndh * (a2 - 1.0) + 1.0, 2.0));
	SPECULAR_LIGHT += LIGHT_COLOR * d * clamp(ndl, 0.0, 1.0) * ATTENUATION * spec_strength * 0.25;
}
