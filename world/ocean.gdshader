shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.11, 0.23, 0.30, 0.92);
uniform float wave_height = 0.14;

void vertex() {
	float w = sin(VERTEX.x * 0.09 + TIME * 1.4) * wave_height
			+ cos(VERTEX.z * 0.08 + TIME * 1.1) * wave_height;
	VERTEX.y += w;
}

void fragment() {
	ALBEDO = deep_color.rgb;
	ALPHA = deep_color.a;
	ROUGHNESS = 0.28;
	METALLIC = 0.35;
}
