shader_type canvas_item;
// Dual-circle 7x50 binocular vignette.
uniform float radius = 0.27;
uniform float softness = 0.012;

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 a = (UV - vec2(0.38, 0.5)) * vec2(aspect, 1.0);
	vec2 b = (UV - vec2(0.62, 0.5)) * vec2(aspect, 1.0);
	float d = min(length(a), length(b));
	float m = smoothstep(radius, radius + softness, d);
	COLOR = vec4(0.03, 0.05, 0.063, m * 0.96);
}
