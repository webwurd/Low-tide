shader_type canvas_item;
// Frosted glass behind HUD panels: the game view under the panel, blurred
// (a lower mip of the screen copy) and tinted towards slate, with rounded
// corners. Text stays legible over a bright sky without a heavy opaque slab,
// and the panel still feels like part of the scene.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.04, 0.06, 0.08, 0.64);
uniform float blur_lod = 3.2;
uniform vec2 size = vec2(100.0, 100.0);   // panel size in pixels (set from code)
uniform float radius = 10.0;

void fragment() {
	vec2 p = UV * size;
	vec2 half_size = size * 0.5;
	vec2 q = abs(p - half_size) - (half_size - vec2(radius));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	float mask = clamp(0.5 - d, 0.0, 1.0);
	vec3 behind = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb;
	// Pull bright backgrounds down more than dark ones, so contrast is even.
	float lum = dot(behind, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(behind, tint.rgb, clamp(tint.a + lum * 0.22, 0.0, 0.92));
	COLOR = vec4(col, mask * COLOR.a);
}
