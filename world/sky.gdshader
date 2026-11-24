shader_type sky;
// Painterly sky: gradient, a soft sun/moon glow, flat-shaded paper-cut clouds,
// stars. Driven every frame by main.gd from SkyModel.describe().

uniform vec3 zenith_color : source_color = vec3(0.36, 0.56, 0.75);
uniform vec3 horizon_color : source_color = vec3(0.79, 0.87, 0.9);
uniform vec3 glow_color : source_color = vec3(1.0, 0.94, 0.8);
uniform vec3 fog_color : source_color = vec3(0.32, 0.39, 0.45);
uniform vec3 sun_dir = vec3(0.0, 0.3, 1.0);
uniform vec3 moon_dir = vec3(0.0, -0.3, -1.0);
uniform float glow_strength = 1.0;
uniform float haze_height = 0.2;
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.5;
uniform float star_amount : hint_range(0.0, 1.0) = 0.0;
uniform float sun_height = 0.3;
uniform float wind_speed = 0.004;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = EYEDIR;
	float h = dir.y;

	// Base gradient. Below the horizon is pure fog colour so the sea's far edge has no seam.
	float up = clamp(h, 0.0, 1.0);
	vec3 col = mix(horizon_color, zenith_color, pow(up, 0.55));

	// Sun side glow: a wide warm bloom plus a tighter hot core.
	float sd = max(dot(dir, normalize(sun_dir)), 0.0);
	float bloom = pow(sd, 6.0) * 0.5 + pow(sd, 40.0) * 0.6;
	col += glow_color * bloom * glow_strength;
	// Sun disc: only when it is above the horizon, with a painted edge.
	float disc = smoothstep(0.9993, 0.9996, sd) * step(0.0, sun_height + 0.03);
	col = mix(col, glow_color * 1.6, disc * glow_strength);

	// Moon.
	float md = max(dot(dir, normalize(moon_dir)), 0.0);
	float night = star_amount;
	col += vec3(0.55, 0.65, 0.9) * pow(md, 60.0) * 0.35 * night;
	col = mix(col, vec3(0.92, 0.95, 1.0), smoothstep(0.9994, 0.9997, md) * night);

	// Stars.
	if (night > 0.01 && h > 0.0) {
		vec2 sp = dir.xz / (dir.y + 0.35) * 90.0;
		vec2 cell = floor(sp);
		float r = hash21(cell);
		float twinkle = 0.65 + 0.35 * sin(TIME * (1.5 + r * 3.0) + r * 40.0);
		vec2 f = fract(sp) - 0.5;
		float s = smoothstep(0.985, 1.0, r) * smoothstep(0.28, 0.0, length(f));
		col += vec3(0.85, 0.9, 1.0) * s * twinkle * night * smoothstep(0.02, 0.25, h);
	}

	// Paper-cut clouds: threshold a noise field and shade it in three flat bands.
	if (h > 0.01) {
		vec2 cp = dir.xz / (h + 0.22) * 1.15 + vec2(TIME * wind_speed, TIME * wind_speed * 0.4);
		float n = fbm(cp);
		float thr = mix(0.80, 0.30, cloud_cover);
		float body = smoothstep(thr, thr + 0.035, n);
		float core = smoothstep(thr + 0.09, thr + 0.12, n);
		vec3 lit = mix(horizon_color, glow_color, clamp(sd * 1.2, 0.0, 1.0) * glow_strength);
		lit = mix(lit, vec3(1.0), 0.22);
		vec3 shade = mix(zenith_color, horizon_color, 0.35) * 0.85;
		vec3 cloud_col = mix(lit, shade, core * 0.8);
		// Night clouds are just darker sky.
		cloud_col = mix(cloud_col, zenith_color * 1.5 + vec3(0.02, 0.03, 0.05), clamp(night, 0.0, 1.0));
		float fade = smoothstep(0.0, 0.14, h);   // thin out toward the horizon
		col = mix(col, cloud_col, body * fade * 0.92);
	}

	// Fog: thick fog climbs the sky; below the horizon it is all fog.
	float haze = 1.0 - smoothstep(0.0, haze_height, h);
	haze = clamp(haze, 0.0, 1.0);
	// Keep a little sun colour inside the haze so fog glows toward the sun.
	vec3 fogc = fog_color + glow_color * pow(sd, 8.0) * 0.18 * glow_strength;
	col = mix(col, fogc, haze * haze * (3.0 - 2.0 * haze));
	if (h <= 0.0) {
		col = fogc;
	}
	COLOR = col;
}
