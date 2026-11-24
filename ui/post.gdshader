shader_type canvas_item;
// Final soft touch over the 3D view (under the HUD): a gentle vignette and a
// whisper of animated film grain, like a print rather than a render.

uniform float vignette = 0.32;
uniform float grain = 0.035;
uniform vec4 vignette_color : source_color = vec4(0.03, 0.035, 0.06, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p.yx + 19.19);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float v = smoothstep(0.35, 1.05, length(uv) * 1.25) * vignette;
	float n = hash(FRAGCOORD.xy + floor(TIME * 24.0) * 13.17) - 0.5;
	// Grain as a tiny brighten/darken; vignette as a cool darkening.
	vec3 g = n > 0.0 ? vec3(1.0) : vec3(0.0);
	float ga = abs(n) * grain * 2.0;
	COLOR = vec4(mix(g, vignette_color.rgb, v / max(v + ga, 0.0001)), clamp(v + ga, 0.0, 1.0));
}
