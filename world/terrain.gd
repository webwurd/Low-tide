class_name Terrain
## Deterministic height field, ported from the Milestone 1 prototype
## (getTerrainHeight). Used for the visual mesh, collision and audio surfaces.
## Change from prototype: the south "dock flatten" is removed; the pier now
## spans from the hillside out over the water instead (see PIER_* constants).

const PIER_X := 1.85
const PIER_Z0 := 12.5
const PIER_Z1 := 37.0
const PIER_TOP := 4.7           # above max high tide (4.2m) + wave height
## Flat pad the keeper's cottage stands on (the prototype left it floating).
const COTTAGE_POS := Vector2(-8.5, 1.5)
const COTTAGE_Y := 8.0
const COTTAGE_YAW := 0.45

static func height(x: float, z: float) -> float:
	var dist_main := Vector2(x, z).length()
	var h_main := -4.0
	if dist_main < 42.0:
		var t := maxf(0.0, 1.0 - dist_main / 36.0)
		h_main = -3.5 + pow(t, 1.35) * 14.5
		h_main += sin(x * 0.18) * cos(z * 0.18) * 0.55 * t

	# Summit plateau for lighthouse + cottage around (0, -4)
	var dist_summit := Vector2(x, z + 4.0).length()
	if dist_summit < 11.0:
		var blend := maxf(0.0, 1.0 - dist_summit / 11.0)
		h_main = h_main * (1.0 - blend) + 10.2 * blend

	var d_pad := Vector2(x, z).distance_to(COTTAGE_POS)
	if d_pad < 9.0:
		var pad_blend := smoothstep(0.0, 1.0, clampf((9.0 - d_pad) / 4.8, 0.0, 1.0))
		h_main = lerpf(h_main, COTTAGE_Y, pad_blend)

	# East sandbar (tide-locked, crest ~1.65m)
	var h_east_bar := -4.0
	if x > 20.0 and x < 74.0:
		var z_off := sin((x - 25.0) * 0.07) * 3.5
		var d := absf(z - (4.0 + z_off))
		if d < 9.5:
			h_east_bar = -2.0 + cos((d / 9.5) * (PI / 2.0)) * 3.65

	# East sea stack (shipwreck)
	var d_east := Vector2(x - 76.0, z - 6.0).length()
	var h_east_stack := -4.0
	if d_east < 19.0:
		var t2 := maxf(0.0, 1.0 - d_east / 17.0)
		h_east_stack = -2.5 + pow(t2, 1.2) * 8.2

	# West sandbar (crest ~1.70m)
	var h_west_bar := -4.0
	if x < -20.0 and x > -72.0:
		var z_off2 := cos((x + 25.0) * 0.08) * 3.0
		var d2 := absf(z - (-6.0 + z_off2))
		if d2 < 9.0:
			h_west_bar = -2.0 + cos((d2 / 9.0) * (PI / 2.0)) * 3.70

	# West sea stack (echo cave)
	var d_west := Vector2(x + 74.0, z + 8.0).length()
	var h_west_stack := -4.0
	if d_west < 20.0:
		var t3 := maxf(0.0, 1.0 - d_west / 18.0)
		h_west_stack = -2.5 + pow(t3, 1.25) * 9.5

	return maxf(maxf(maxf(h_main, h_east_bar), maxf(h_east_stack, h_west_bar)), h_west_stack)

static func on_pier(x: float, z: float) -> bool:
	return absf(x) <= PIER_X and z >= PIER_Z0 and z <= PIER_Z1

## Footstep surface: "wood", "sand" or "rock".
static func surface_at(x: float, z: float, y: float) -> String:
	if on_pier(x, z) and y >= PIER_TOP - 0.3:
		return "wood"
	if absf(x) > 20.0 and y < 2.2:
		return "sand"
	return "rock"

static func color_for(h: float, x: float) -> Color:
	var sand := Color("9e957e")
	var wet := Color("3a434a")
	var granite := Color("6b747c")
	var moss := Color("4d5e53")
	if (absf(x) > 25.0 and absf(x) < 67.0 and h > 0.3 and h < 2.2) or h < 1.35:
		return sand
	if h < 3.4:
		return wet.lerp(granite, (h - 1.35) / 2.05)
	if h < 7.5:
		return granite
	return granite.lerp(moss, minf(1.0, (h - 7.5) / 3.0))

## Builds the flat-shaded terrain ArrayMesh (per-face colour).
static func build_mesh(size := 210.0, seg := 180) -> ArrayMesh:
	var step := size / seg
	var half := size / 2.0
	var n := seg + 1
	var hs := PackedFloat32Array()
	hs.resize(n * n)
	for iz in n:
		for ix in n:
			hs[iz * n + ix] = height(-half + ix * step, -half + iz * step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for iz in seg:
		for ix in seg:
			var x0 := -half + ix * step
			var z0 := -half + iz * step
			var p00 := Vector3(x0, hs[iz * n + ix], z0)
			var p10 := Vector3(x0 + step, hs[iz * n + ix + 1], z0)
			var p01 := Vector3(x0, hs[(iz + 1) * n + ix], z0 + step)
			var p11 := Vector3(x0 + step, hs[(iz + 1) * n + ix + 1], z0 + step)
			_tri(st, p00, p10, p01)
			_tri(st, p10, p11, p01)
	st.generate_normals()
	return st.commit()

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var col := color_for((a.y + b.y + c.y) / 3.0, (a.x + b.x + c.x) / 3.0)
	for p in [a, b, c]:
		st.set_color(col)
		st.add_vertex(p)
