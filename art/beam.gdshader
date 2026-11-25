shader_type spatial;
// Lighthouse beam shaft: additive, soft at the edges (view-facing falloff) and
// fading along its length, so it reads as light in haze, not a solid cone.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 beam_color : source_color = vec3(1.0, 0.82, 0.5);
uniform float intensity = 0.25;
uniform float length_m = 95.0;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying float along;

void vertex() {
	// Cone mesh: local Y runs from -length/2 (narrow end) to +length/2 (wide end).
	along = clamp(VERTEX.y / length_m + 0.5, 0.0, 1.0);
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float edge = pow(facing, 2.2);
	float fade = (1.0 - along) * (1.0 - along * 0.35);
	float near = smoothstep(0.0, 0.04, along);
	// Soften where the beam meets geometry.
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 world = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = -world.z / world.w;
	float soft = clamp((scene_z + VERTEX.z) / 4.0, 0.0, 1.0);
	ALBEDO = beam_color * intensity * edge * fade * near * soft;
}
