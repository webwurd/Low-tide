// Triplanar sampling helpers (no UVs needed). `p` and `n` are in the same
// space (world or object). Normal maps are OpenGL/Y+; the perturbation is
// returned in that same space so the caller can add it to the geometric normal.
// Projections: X face uv=(z, -y), Y face uv=(x, z), Z face uv=(x, -y), so the
// image's "up" is world up on vertical faces.

vec3 tri_weights(vec3 n, float sharp) {
	vec3 b = pow(abs(n), vec3(sharp));
	return b / max(b.x + b.y + b.z, 0.0001);
}

vec4 tri_sample(sampler2D tex, vec3 p, vec3 b) {
	vec4 x = texture(tex, vec2(p.z, -p.y));
	vec4 y = texture(tex, vec2(p.x, p.z));
	vec4 z = texture(tex, vec2(p.x, -p.y));
	return x * b.x + y * b.y + z * b.z;
}

// Returns a perturbation vector (add to n, then normalise).
vec3 tri_normal(sampler2D tex, vec3 p, vec3 b) {
	vec2 tx = texture(tex, vec2(p.z, -p.y)).xy * 2.0 - 1.0;
	vec2 ty = texture(tex, vec2(p.x, p.z)).xy * 2.0 - 1.0;
	vec2 tz = texture(tex, vec2(p.x, -p.y)).xy * 2.0 - 1.0;
	vec3 nx = vec3(0.0, tx.y, tx.x);
	vec3 ny = vec3(ty.x, 0.0, -ty.y);
	vec3 nz = vec3(tz.x, tz.y, 0.0);
	return nx * b.x + ny * b.y + nz * b.z;
}
