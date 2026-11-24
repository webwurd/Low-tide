shader_type sky;
// Painted winter sky for Low Tide: a soft zenith->horizon gradient, a warm
// glow around the sun, flat-cut stylised cloud bands, stars and a moon at
// night, and a haze band that melts the horizon into the fog colour so the
// distant layers read as flat colour planes. All colours come from
// SkyRig (art/sky_rig.gd), sampled from the Atmosphere + WeatherLook.

uniform vec3 top_color : source_color = vec3(0.35, 0.5, 0.68);
uniform vec3 horizon_color : source_color = vec3(0.72, 0.78, 0.82);
uniform vec3 ground_color : source_color = vec3(0.1, 0.16, 0.2);
uniform vec3 fog_color : source_color = vec3(0.6, 0.66, 0.7);
uniform float horizon_haze = 0.55;
uniform float sky_to_fog = 0.0;
uniform float energy = 1.0;

uniform vec3 sun_dir = vec3(0.0, 0.3, 0.95);
uniform vec3 sun_color : source_color = vec3(1.0, 0.85, 0.6);
uniform float sun_visible = 1.0;
uniform float sun_disc_size = 0.022;
uniform float sun_glow = 1.0;

uniform vec3 moon_dir = vec3(0.0, 0.5, 0.86);
uniform float moon_visible = 0.0;
uniform float stars = 0.0;

uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;
uniform vec3 cloud_lit : source_color = vec3(0.95, 0.93, 0.9);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.68, 0.76);
uniform float cloud_cover = 0.35;
uniform float cloud_darkness = 0.0;
uniform float cloud_speed = 0.004;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float cloud_field(vec2 uv) {
	vec2 wind = vec2(TIME * cloud_speed, TIME * cloud_speed * 0.35);
	float n = texture(cloud_noise, uv * 0.55 + wind).r * 0.62;
	n += texture(cloud_noise, uv * 1.37 - wind * 1.7 + 0.31).r * 0.28;
	n += texture(cloud_noise, uv * 3.1 + wind * 2.3 + 0.67).r * 0.1;
	return n;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float y = d.y;

	// Base gradient: a long soft horizon band, a deeper zenith.
	float up = clamp(y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, smoothstep(0.0, 0.75, pow(up, 0.55)));

	// Warm the horizon on the sun's side (big soft glow), cool it opposite.
	float sd = dot(d, normalize(sun_dir));
	float side = clamp(sd * 0.5 + 0.5, 0.0, 1.0);
	float low = 1.0 - smoothstep(0.0, 0.45, up);
	col = mix(col, col * mix(vec3(0.9, 0.93, 1.02), vec3(1.0), side), low * 0.6);
	col += sun_color * pow(max(sd, 0.0), 6.0) * 0.32 * sun_glow * sun_visible;
	col += sun_color * pow(max(sd, 0.0), 48.0) * 0.55 * sun_glow * sun_visible;

	// Below the horizon: the sea/ground haze.
	if (y < 0.0) {
		col = mix(horizon_color, ground_color, smoothstep(0.0, -0.25, y));
	}

	// Stars (hidden by cloud and haze below).
	if (stars > 0.001 && y > 0.0) {
		vec3 g = floor(d * 260.0);
		float h = hash13(g);
		float tw = 0.6 + 0.4 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);
		float s = step(0.9965, h) * tw * smoothstep(0.03, 0.3, y);
		col += vec3(0.85, 0.9, 1.0) * s * stars * 1.6;
	}

	// Sun disc and moon disc.
	float disc = smoothstep(cos(sun_disc_size), cos(sun_disc_size * 0.82), sd);
	col = mix(col, sun_color * 3.5, disc * sun_visible * step(0.0, y + 0.02));
	float md = dot(d, normalize(moon_dir));
	float mdisc = smoothstep(cos(0.03), cos(0.026), md);
	col += vec3(0.9, 0.93, 1.0) * (mdisc * 1.6 + pow(max(md, 0.0), 200.0) * 0.4) * moon_visible;

	// Clouds: a flat plane projected onto the dome. Crisp-but-soft edges give the
	// painted, cut-paper shapes; lit from the sun side, shaded beneath.
	if (y > 0.0 && cloud_cover > 0.001) {
		vec2 uv = d.xz / (y + 0.09) * 0.11;
		float n = cloud_field(uv);
		float thresh = mix(0.78, 0.2, cloud_cover);
		float c = smoothstep(thresh, thresh + 0.06 + cloud_cover * 0.08, n);
		float thick = smoothstep(thresh, thresh + 0.32, n);
		float lit = clamp(0.45 + 0.55 * side - thick * 0.45, 0.0, 1.0);
		vec3 ccol = mix(cloud_shade, cloud_lit, lit);
		ccol = mix(ccol, ccol * vec3(0.42, 0.46, 0.5), cloud_darkness * thick);
		// Bright rim where thin cloud passes near the sun.
		float rim = (1.0 - thick) * pow(max(sd, 0.0), 10.0) * sun_visible;
		ccol += sun_color * rim * 0.9;
		float fade = smoothstep(0.0, 0.12, y);
		col = mix(col, ccol, c * fade);
	}

	// Horizon haze: melt the bottom of the sky into the fog colour.
	float haze = exp(-abs(y) * mix(14.0, 4.0, horizon_haze)) * horizon_haze;
	col = mix(col, fog_color, clamp(haze, 0.0, 1.0));
	col = mix(col, fog_color, sky_to_fog * (1.0 - smoothstep(0.0, 0.9, up) * 0.35));

	COLOR = col * energy;
}
