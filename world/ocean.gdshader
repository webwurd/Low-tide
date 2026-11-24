shader_type spatial;
// Low Tide sea: Gerstner swell + scrolling detail normals; depth-based colour
// (you can see the sandbars through the shallows); refraction; shoreline and
// crest foam; sun-lit crests glow when backlit. Sky reflections and sun glints
// come from the engine's specular (low roughness) on the final normal.
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;

global uniform vec3 sun_dir;
global uniform vec4 sun_color;
global uniform float daylight;
global uniform float wind;
global uniform float wetness;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D foam_tex : source_color, filter_linear_mipmap, repeat_enable, hint_default_black;

uniform vec4 shallow_col : source_color = vec4(0.18, 0.42, 0.42, 1.0);
uniform vec4 deep_col : source_color = vec4(0.05, 0.13, 0.18, 1.0);
uniform vec4 foam_col : source_color = vec4(0.88, 0.91, 0.9, 1.0);
uniform float wave_height = 0.14;      // from DayData; 0.06 still .. 0.45 storm
uniform float clarity = 3.2;           // metres of water before it reads as deep
uniform float detail_strength = 0.35;
uniform float foam_width = 0.38;
uniform float refraction = 0.025;

varying vec3 v_world;
varying vec3 v_nrm;
varying float v_crest;

vec3 gerstner(vec4 w, vec3 p, float amp, inout vec3 tangent, inout vec3 binormal) {
	float k = TAU / w.w;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(w.xy);
	float f = k * (dot(d, p.xz) - c * TIME * 0.6);
	float steep = w.z * amp;
	float a = steep / k;
	tangent += vec3(-d.x * d.x * steep * sin(f), d.x * steep * cos(f), -d.x * d.y * steep * sin(f));
	binormal += vec3(-d.x * d.y * steep * sin(f), d.y * steep * cos(f), -d.y * d.y * steep * sin(f));
	return vec3(d.x * a * cos(f), a * sin(f), d.y * a * cos(f));
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float amp = clamp(wave_height / 0.3, 0.12, 1.6);
	vec3 t = vec3(1.0, 0.0, 0.0);
	vec3 b = vec3(0.0, 0.0, 1.0);
	vec3 disp = vec3(0.0);
	disp += gerstner(vec4(1.0, 0.35, 0.16, 26.0), wp, amp, t, b);
	disp += gerstner(vec4(0.7, 1.0, 0.12, 15.0), wp, amp, t, b);
	disp += gerstner(vec4(-0.4, 1.0, 0.1, 9.5), wp, amp, t, b);
	disp += gerstner(vec4(1.0, -0.6, 0.08, 6.0), wp, amp, t, b);
	VERTEX += disp;
	v_crest = clamp(disp.y / max(0.05, 0.55 * amp), 0.0, 1.0);
	v_nrm = normalize(cross(b, t));
	NORMAL = (MODEL_MATRIX * vec4(v_nrm, 0.0)).xyz;
	v_world = wp + disp;
}

float scene_distance(vec2 uv, mat4 inv_proj) {
	float raw = texture(depth_tex, uv).r;
	vec4 vp = inv_proj * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return length(vp.xyz / vp.w);
}

void fragment() {
	// Detail normals (two scrolling layers) on top of the swell normal.
	float drift = 0.6 + wind;
	vec2 uv1 = v_world.xz * 0.045 + TIME * vec2(0.011, 0.007) * drift;
	vec2 uv2 = v_world.xz * 0.12 - TIME * vec2(0.009, 0.016) * drift;
	vec2 dn = (texture(normal_tex, uv1).xy * 2.0 - 1.0) + (texture(normal_tex, uv2).xy * 2.0 - 1.0) * 0.6;
	float dist = length(VERTEX);
	dn *= detail_strength * mix(1.0, 0.35, smoothstep(30.0, 220.0, dist));
	// Rain: a fast, fine third layer pocks the surface near the camera.
	if (wetness > 0.01) {
		vec2 r1 = texture(normal_tex, v_world.xz * 0.9 + vec2(TIME * 0.37, -TIME * 0.29)).xy * 2.0 - 1.0;
		dn += r1 * 0.22 * wetness * (1.0 - smoothstep(10.0, 60.0, dist));
	}
	vec3 wn = normalize(v_nrm + vec3(dn.x, 0.0, -dn.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);

	// Water thickness along the view ray -> approximate vertical depth.
	float surf = dist;
	float behind = scene_distance(SCREEN_UV, INV_PROJECTION_MATRIX);
	float thick = max(behind - surf, 0.0);
	vec3 vdir = normalize(VERTEX);
	float depth_m = thick * clamp(abs((INV_VIEW_MATRIX * vec4(vdir, 0.0)).y), 0.15, 1.0);

	// Refraction (skip where the offset lands on something in front of the water).
	vec2 ruv = SCREEN_UV + dn * refraction * clamp(depth_m * 0.5, 0.0, 1.0);
	if (scene_distance(ruv, INV_PROJECTION_MATRIX) < surf) {
		ruv = SCREEN_UV;
	}
	vec3 refr = textureLod(screen_tex, ruv, 0.0).rgb;

	float absorb = 1.0 - exp(-depth_m / clarity);
	vec3 body = mix(shallow_col.rgb, deep_col.rgb, smoothstep(0.0, 1.0, absorb));
	vec3 transmit = refr * mix(vec3(0.75, 0.9, 0.88), vec3(0.3, 0.5, 0.55), absorb) * (1.0 - absorb);

	// Foam: a lacy band at the shoreline, plus wind-whipped crests.
	vec2 fuv = v_world.xz * 0.42 + vec2(TIME * 0.03, -TIME * 0.02);
	float lace = mix(texture(foam_tex, fuv).r, texture(foam_tex, fuv * 1.9 + 0.37).r, 0.5);
	float lace2 = texture(foam_tex, v_world.xz * 0.09 - TIME * 0.012).r;
	float shore = 1.0 - smoothstep(0.0, foam_width, depth_m + (lace2 - 0.5) * 0.25);
	shore *= shore;
	float pulse = 0.65 + 0.35 * sin(TIME * 0.9 + v_world.x * 0.05 + v_world.z * 0.04);
	float crest = smoothstep(0.55, 0.95, v_crest + lace2 * 0.2) * clamp(wave_height * 2.5, 0.0, 1.0);
	float foam = clamp(shore * pulse * smoothstep(0.2, 0.75, lace + shore * 0.35) * 0.85 + crest * smoothstep(0.4, 0.7, lace), 0.0, 1.0);

	// Backlit crests glow towards the sun at golden hour.
	vec3 view_w = normalize(v_world - CAMERA_POSITION_WORLD);
	float sss = pow(clamp(dot(view_w, normalize(sun_dir)), 0.0, 1.0), 5.0) * (0.3 + v_crest) * daylight;

	ALBEDO = mix(body * absorb, foam_col.rgb, foam);
	EMISSION = transmit * (1.0 - foam) + shallow_col.rgb * sun_color.rgb * sss * 0.45 * (1.0 - foam);
	ROUGHNESS = mix(0.06 + wind * wind * 0.28, 0.85, foam);
	SPECULAR = mix(0.55, 0.2, foam);
	METALLIC = 0.0;
	ALPHA = 1.0;
}
