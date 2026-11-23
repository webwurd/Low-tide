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
## North cove: tide-gated shingle bar (crest ~1.05 m) to a sheltered shelf.
const NORTH_A := Vector2(-5.0, -22.0)
const NORTH_B := Vector2(-15.0, -46.0)
const COVE_C := Vector2(-17.0, -52.0)
## South reef: a deep bar (crest ~-1.0 m) that only walks at the Day 5 spring
## low, leading to the cable-vault pad (~0.5 m).
const SOUTH_A := Vector2(12.0, 20.0)
const SOUTH_B := Vector2(18.0, 56.0)
const VAULT_C := Vector2(18.0, 62.0)

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

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

	# North cove bar + shelf + backdrop stack
	var p := Vector2(x, z)
	var h_north := -4.0
	var dn := _seg_dist(p, NORTH_A, NORTH_B)
	if dn < 5.0:
		h_north = -2.0 + cos(dn / 5.0 * (PI / 2.0)) * 3.05
	var dc := p.distance_to(COVE_C)
	if dc < 9.0:
		h_north = maxf(h_north, lerpf(1.25, -2.0, smoothstep(5.5, 9.0, dc)))
	var dback := p.distance_to(Vector2(-20.0, -60.0))
	if dback < 8.0:
		h_north = maxf(h_north, -2.5 + pow(1.0 - dback / 8.0, 1.2) * 8.0)

	# South reef bar + vault pad
	var h_south := -4.0
	var dr := _seg_dist(p, SOUTH_A, SOUTH_B)
	if dr < 4.5:
		h_south = -3.0 + cos(dr / 4.5 * (PI / 2.0)) * 2.0
	var dv := p.distance_to(VAULT_C)
	if dv < 9.0:
		h_south = maxf(h_south, lerpf(0.5, -3.0, smoothstep(6.0, 9.0, dv)))

	var best := maxf(maxf(maxf(h_main, h_east_bar), maxf(h_east_stack, h_west_bar)), h_west_stack)
	return maxf(best, maxf(h_north, h_south))

static func on_pier(x: float, z: float) -> bool:
	return absf(x) <= PIER_X and z >= PIER_Z0 and z <= PIER_Z1

## Footstep surface: wood, concrete, gravel, sand, wet, rock.
static func surface_at(x: float, z: float, y: float) -> String:
	if on_pier(x, z) and y >= PIER_TOP - 0.3:
		return "wood"
	var p := Vector2(x, z)
	if p.distance_to(VAULT_C) < 7.0:
		return "concrete"
	if p.distance_to(COVE_C) < 9.5 or (_seg_dist(p, NORTH_A, NORTH_B) < 5.0 and z < -26.0):
		return "gravel"
	if _seg_dist(p, SOUTH_A, SOUTH_B) < 5.0 and z > 24.0:
		return "sand"
	if absf(x) > 20.0 and y < 2.2:
		return "sand"
	if y > 0.4 and y < 2.8 and p.length() < 32.0:
		return "wet"          # barnacled intertidal rock
	return "rock"

static func color_for(h: float, x: float, z := 0.0) -> Color:
	var cp := Vector2(x, z)
	if cp.distance_to(VAULT_C) < 7.0 and h > 0.3:
		return Color("8a8d8f")                       # concrete pad
	if (cp.distance_to(COVE_C) < 9.0 or (_seg_dist(cp, NORTH_A, NORTH_B) < 5.0 and z < -26.0)) and h < 2.5:
		return Color("77706a")                       # shingle
	var sand := Color("9e957e")
	var wet := Color("3a434a")
	var granite := Color("6b747c")
	var moss := Color("4d5e53")
	if h > 0.4 and h < 1.35 and cp.length() < 32.0:
		return Color("35403f")                       # kelp / barnacle line
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
	var col := color_for((a.y + b.y + c.y) / 3.0, (a.x + b.x + c.x) / 3.0, (a.z + b.z + c.z) / 3.0)
	for p in [a, b, c]:
		st.set_color(col)
		st.add_vertex(p)

## Coarse named zone for location-aware radio reactions.
static func zone_at(x: float, z: float, y: float) -> String:
	if on_pier(x, z) and y >= PIER_TOP - 0.3:
		return "pier"
	if Vector2(x - 76.0, z - 6.0).length() < 17.0 and y > 3.0:
		return "east_stack"
	if Vector2(x + 74.0, z + 8.0).length() < 18.0 and y > 3.0:
		return "west_stack"
	var p := Vector2(x, z)
	if p.distance_to(VAULT_C) < 8.5 and y > -0.5:
		return "south_reef"
	if _seg_dist(p, SOUTH_A, SOUTH_B) < 5.0 and z > 24.0:
		return "south_bar"
	if p.distance_to(COVE_C) < 9.0 and y > 0.0:
		return "north_cove"
	if _seg_dist(p, NORTH_A, NORTH_B) < 5.5 and z < -26.0:
		return "north_bar"
	if Vector2(x, z + 4.0).length() < 12.0 or y > 7.0:
		return "summit"
	if x > 20.0 and y < 3.0:
		return "east_bar"
	if x < -20.0 and y < 3.0:
		return "west_bar"
	return "shore"
