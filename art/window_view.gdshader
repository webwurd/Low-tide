shader_type spatial;
// What Arthur sees through interior windows: the interiors are built away
// from the island, so each pane shows a soft painted view of the current sky
// (set by Interiors from the SkyRig) with a fog-blurred horizon and sea.
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 sky_top : source_color = vec4(0.4, 0.55, 0.7, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.75, 0.8, 0.82, 1.0);
uniform vec4 sea : source_color = vec4(0.15, 0.25, 0.3, 1.0);
uniform float energy = 1.0;
uniform float horizon = 0.38;   // height of the sea line in the pane (0 bottom .. 1 top)

void fragment() {
	float v = 1.0 - UV.y;
	vec3 sky = mix(sky_horizon.rgb, sky_top.rgb, smoothstep(horizon, 1.0, v));
	vec3 water = mix(sea.rgb, sky_horizon.rgb * 0.8, smoothstep(horizon - 0.25, horizon, v) * 0.6);
	vec3 col = mix(water, sky, smoothstep(horizon - 0.01, horizon + 0.01, v));
	// Condensation haze at the edges of the glass.
	float edge = smoothstep(0.0, 0.18, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	col = mix(col * 0.85 + 0.05, col, edge);
	ALBEDO = col * energy;
}
