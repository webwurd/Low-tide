class_name PropAssets
## Hero props (everything Arthur can use) and reusable furniture, saved to
## res://assets/models/<name>.res. Each model's origin is where it stands:
## floor props at floor level, wall props on the wall plane facing +Z.
## Scenes (island + interiors) place them; PropLoader lets authored .glb
## files replace any of them.

static func build_all() -> void:
	_canister()
	_acoustic_buoy()
	_stove()
	_tide_table()
	_barometer()
	_radio()
	_desk()
	_logbook()
	_armchair()
	_bed()
	_door()
	_clock_weights()
	_spiral_stair()
	_lantern_lens()
	_bench()
	_floor_hatch()
	_table_chairs()
	_shelf_books()
	_small_props()
	_tender()

static func _save(k: MeshKit, name: String) -> void:
	SceneUtil.kit_mesh(k, name)

static func _prof(pts: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in pts:
		p.append(Vector2(v[0], v[1]))
	return p

static func _circle_path(r: float, y: float, n := 24, center := Vector3.ZERO) -> PackedVector3Array:
	var p := PackedVector3Array()
	for i in n + 1:
		var a := TAU * i / n
		p.append(center + Vector3(cos(a) * r, y, sin(a) * r))
	return p

# --- island hero props -------------------------------------------------------------

## The 1974 waterproof canister: a dented, banded steel cylinder with a clamp lid,
## a carry handle and a stencilled band. Axis along Y, origin at its centre.
static func _canister() -> void:
	var k := MeshKit.new()
	k.lathe("canister", _prof([[0.0, -0.52], [0.27, -0.52], [0.3, -0.49], [0.3, 0.42], [0.285, 0.45], [0.285, 0.47], [0.0, 0.47]]), 28, true)
	for y in [-0.42, -0.05, 0.3]:
		k.lathe("iron", _prof([[0.3, y], [0.318, y + 0.01], [0.318, y + 0.05], [0.3, y + 0.06]]), 28)
	k.lathe("paint_white", _prof([[0.302, 0.08], [0.303, 0.09], [0.303, 0.22], [0.302, 0.23]]), 28)
	k.lathe("rubber", _prof([[0.29, 0.47], [0.3, 0.48], [0.3, 0.5], [0.0, 0.5]]), 28)
	k.lathe("canister", _prof([[0.0, 0.5], [0.31, 0.5], [0.315, 0.53], [0.29, 0.58], [0.12, 0.6], [0.0, 0.6]]), 28, true)
	for a in [0.0, PI]:
		var d := Vector3(cos(a), 0, sin(a))
		k.push(Transform3D(Basis(Vector3.UP, -a), d * 0.31 + Vector3(0, 0.49, 0)))
		k.box("iron", Vector3(0.05, 0.16, 0.09), Vector3.ZERO, 0.012)
		k.box("iron", Vector3(0.06, 0.03, 0.12), Vector3(0.0, 0.09, 0.0), 0.01)
		k.pop()
	var arc := PackedVector3Array()
	for i in 13:
		var t := PI * i / 12.0
		arc.append(Vector3(cos(t) * 0.17, 0.6 + sin(t) * 0.13, 0))
	k.tube("iron", arc, 0.018, 6)
	k.box("brass", Vector3(0.16, 0.1, 0.01), Vector3(0, 0.0, 0.302), 0.004)
	_save(k, "canister")

## Washed-up acoustic research buoy: a red float with a bolted equator band,
## lifting eyes, an instrument mast and a hydrophone cage beneath.
static func _acoustic_buoy() -> void:
	var k := MeshKit.new()
	var body := []
	for i in 13:
		var t := -PI / 2.0 + PI * i / 12.0
		body.append([cos(t) * 1.0, 1.0 + sin(t) * 0.82])
	k.lathe("buoy_red", _prof(body), 32, true)
	k.lathe("iron", _prof([[0.99, 0.94], [1.06, 0.96], [1.06, 1.06], [0.99, 1.08]]), 32)
	for i in 16:
		var a := TAU * i / 16.0
		k.push(Transform3D(Basis(), Vector3(cos(a) * 1.06, 1.01, sin(a) * 1.06)))
		k.box("iron", Vector3(0.05, 0.05, 0.05), Vector3.ZERO, 0.015)
		k.pop()
	k.lathe("paint_white", _prof([[0.82, 1.42], [0.84, 1.44], [0.74, 1.56], [0.72, 1.55]]), 32)
	for a in [0.0, TAU / 3.0, 2.0 * TAU / 3.0]:
		var d := Vector3(cos(a), 0, sin(a))
		k.tube("iron", PackedVector3Array([d * 0.55 + Vector3(0, 1.7, 0), d * 0.62 + Vector3(0, 1.86, 0), d * 0.69 + Vector3(0, 1.7, 0)]), 0.03, 6)
	k.cylinder("iron", 0.09, 0.07, 1.2, 10, 1.78)
	k.cylinder("brass", 0.035, 0.025, 0.9, 8, 2.95)
	k.push(Transform3D(Basis(), Vector3(0, 3.0, 0)))
	k.box("iron", Vector3(0.36, 0.22, 0.22), Vector3.ZERO, 0.03)
	k.box("brass", Vector3(0.3, 0.04, 0.24), Vector3(0, 0.13, 0), 0.01)
	k.pop()
	k.push(Transform3D(Basis(), Vector3(0, 3.82, 0)))
	k.lathe("lamp_off", _prof([[0.0, 0.0], [0.07, 0.02], [0.07, 0.14], [0.0, 0.18]]), 8, true)
	k.pop()
	k.cylinder("iron", 0.12, 0.12, 0.5, 10, -0.32)
	for i in 6:
		var a := TAU * i / 6.0
		k.tube("iron", PackedVector3Array([Vector3(cos(a) * 0.12, 0.05, sin(a) * 0.12), Vector3(cos(a) * 0.3, -0.25, sin(a) * 0.3), Vector3(cos(a) * 0.12, -0.55, sin(a) * 0.12)]), 0.018, 5)
	k.lathe("brass", _prof([[0.0, -0.6], [0.1, -0.58], [0.12, -0.48], [0.1, -0.4], [0.0, -0.38]]), 12, true)
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	for i in 5:
		var a := rng.randf() * TAU
		var p := PackedVector3Array()
		for s in 6:
			p.append(Vector3(cos(a) * (0.95 - s * 0.02), 0.45 - s * 0.12, sin(a) * (0.95 - s * 0.02)) + Vector3(sin(s * 1.3) * 0.05, 0, cos(s * 1.1) * 0.05))
		k.tube("seaweed", p, 0.04, 4)
	_save(k, "acoustic_buoy")

# --- cottage hero props -------------------------------------------------------------

## Cast-iron parlour stove with a glowing firebox window, stovepipe, enamel
## kettle and coffee pot. Origin: floor, front faces +Z.
static func _stove() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 0.5; k.ao_min = 0.6
	for lx in [-0.34, 0.34]:
		for lz in [-0.24, 0.24]:
			k.tube("stove_iron", PackedVector3Array([Vector3(lx, 0.0, lz), Vector3(lx * 1.08, 0.12, lz * 1.08), Vector3(lx, 0.24, lz)]), 0.035, 6)
	k.box("stove_iron", Vector3(0.86, 0.06, 0.66), Vector3(0, 0.26, 0), 0.02)
	k.box("stove_iron", Vector3(0.78, 0.6, 0.58), Vector3(0, 0.58, 0), 0.04, 2)
	k.box("stove_iron", Vector3(0.9, 0.06, 0.7), Vector3(0, 0.9, 0), 0.02)
	for bx in [-0.2, 0.2]:
		k.push(Transform3D(Basis(), Vector3(bx, 0.93, 0)))
		k.lathe("stove_iron", _prof([[0.0, 0.0], [0.15, 0.0], [0.15, 0.012], [0.13, 0.016], [0.0, 0.016]]), 18)
		k.pop()
	k.box("stove_iron", Vector3(0.46, 0.36, 0.05), Vector3(0, 0.6, 0.31), 0.02)
	k.box("fire", Vector3(0.3, 0.18, 0.02), Vector3(0, 0.62, 0.335), 0.005)
	for gx in [-0.1, 0.0, 0.1]:
		k.box("stove_iron", Vector3(0.02, 0.18, 0.02), Vector3(gx, 0.62, 0.345), 0.004)
	k.tube("brass", PackedVector3Array([Vector3(0.18, 0.62, 0.34), Vector3(0.18, 0.62, 0.4), Vector3(0.24, 0.62, 0.4)]), 0.012, 6)
	k.cylinder("stove_iron", 0.09, 0.09, 2.15, 14, 0.92)
	k.lathe("stove_iron", _prof([[0.095, 1.5], [0.105, 1.52], [0.105, 1.56], [0.095, 1.58]]), 14)
	# Kettle and coffee pot on the hob.
	k.push(Transform3D(Basis(), Vector3(-0.2, 0.946, 0)))
	k.lathe("enamel_blue", _prof([[0.0, 0.0], [0.12, 0.0], [0.13, 0.08], [0.11, 0.15], [0.05, 0.18], [0.0, 0.19]]), 18, true)
	k.tube("enamel_blue", PackedVector3Array([Vector3(0.1, 0.06, 0), Vector3(0.17, 0.12, 0), Vector3(0.21, 0.17, 0)]), 0.018, 6)
	k.tube("stove_iron", PackedVector3Array([Vector3(-0.08, 0.17, 0), Vector3(-0.05, 0.27, 0), Vector3(0.05, 0.27, 0), Vector3(0.08, 0.17, 0)]), 0.01, 5)
	k.pop()
	k.push(Transform3D(Basis(), Vector3(0.2, 0.946, 0.02)))
	k.lathe("enamel", _prof([[0.0, 0.0], [0.08, 0.0], [0.07, 0.18], [0.05, 0.21], [0.0, 0.23]]), 16, true)
	k.tube("enamel", PackedVector3Array([Vector3(-0.07, 0.04, 0), Vector3(-0.13, 0.1, 0), Vector3(-0.07, 0.17, 0)]), 0.012, 5)
	k.pop()
	_save(k, "stove")

## Printed tide table pinned to a board. Origin on the wall plane, faces +Z.
static func _tide_table() -> void:
	var k := MeshKit.new()
	k.box("wood_warm", Vector3(0.76, 0.96, 0.03), Vector3(0, 0, 0.015), 0.01)
	k.quad("paper_tide", Vector3(-0.32, -0.42, 0.034), Vector3(0.32, -0.42, 0.034), Vector3(0.32, 0.42, 0.034), Vector3(-0.32, 0.42, 0.034))
	for px in [-0.28, 0.28]:
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(px, 0.38, 0.04)))
		k.lathe("brass", _prof([[0.0, 0.0], [0.012, 0.0], [0.012, 0.008], [0.0, 0.01]]), 8)
		k.pop()
	k.tube("rope", PackedVector3Array([Vector3(-0.3, 0.47, 0.02), Vector3(0, 0.6, 0.02), Vector3(0.3, 0.47, 0.02)]), 0.006, 4)
	_save(k, "tide_table")

## Banjo barometer: carved case, enamel dial, brass bezel and needle. Faces +Z.
static func _barometer() -> void:
	var k := MeshKit.new()
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0, 0)))
	k.lathe("wood_warm", _prof([[0.0, 0.0], [0.24, 0.0], [0.26, 0.02], [0.26, 0.05], [0.22, 0.06], [0.0, 0.06]]), 32, true)
	k.lathe("brass", _prof([[0.18, 0.06], [0.2, 0.062], [0.2, 0.08], [0.18, 0.082]]), 32)
	k.lathe("enamel", _prof([[0.0, 0.065], [0.18, 0.065]]), 32)
	k.pop()
	k.box("wood_warm", Vector3(0.12, 0.5, 0.05), Vector3(0, 0.42, 0.025), 0.02)
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.7, 0)))
	k.lathe("wood_warm", _prof([[0.0, 0.0], [0.09, 0.0], [0.09, 0.05], [0.0, 0.05]]), 20, true)
	k.pop()
	for i in 24:
		var a := -2.3 + 4.6 * i / 23.0
		var d := Vector3(sin(a), cos(a), 0)
		k.box("iron", Vector3(0.005, 0.02 if i % 3 == 0 else 0.012, 0.004), d * 0.155 + Vector3(0, 0, 0.068), 0.0)
	k.push(Transform3D(Basis(Vector3.BACK, -0.6), Vector3(0, 0, 0.074)))
	k.box("iron", Vector3(0.008, 0.15, 0.004), Vector3(0, 0.06, 0), 0.0)
	k.pop()
	k.push(Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0, 0, 0.078)))
	k.box("brass", Vector3(0.006, 0.14, 0.004), Vector3(0, 0.055, 0), 0.0)
	k.pop()
	_save(k, "barometer")

## Marine shortwave set: steel case, bakelite face, glowing tuning dial,
## knobs, speaker grille and a hung handset with coiled cord. Origin: base.
static func _radio() -> void:
	var k := MeshKit.new()
	k.box("radio_case", Vector3(0.62, 0.34, 0.34), Vector3(0, 0.17, 0), 0.025, 2)
	k.box("bakelite", Vector3(0.58, 0.3, 0.02), Vector3(0, 0.17, 0.175), 0.008)
	k.box("dial_glow", Vector3(0.22, 0.07, 0.01), Vector3(-0.12, 0.24, 0.188), 0.003)
	for gx in 9:
		k.box("radio_case", Vector3(0.008, 0.11, 0.01), Vector3(0.1 + gx * 0.02, 0.22, 0.188), 0.002)
	for kn in [[-0.2, 0.1], [-0.08, 0.1], [0.04, 0.1], [0.2, 0.1]]:
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(kn[0], kn[1], 0.186)))
		k.lathe("bakelite", _prof([[0.0, 0.0], [0.03, 0.0], [0.028, 0.025], [0.02, 0.03], [0.0, 0.03]]), 12, true)
		k.pop()
	for hx in [-0.33, 0.33]:
		k.box("iron", Vector3(0.03, 0.04, 0.2), Vector3(hx, 0.3, 0.0), 0.01)
	# Handset on a side hook + coiled cord.
	k.box("iron", Vector3(0.02, 0.06, 0.04), Vector3(0.34, 0.2, 0.1), 0.005)
	k.push(Transform3D(Basis(Vector3.BACK, 0.12), Vector3(0.39, 0.16, 0.1)))
	k.box("bakelite", Vector3(0.05, 0.2, 0.06), Vector3.ZERO, 0.02)
	k.box("bakelite", Vector3(0.06, 0.05, 0.07), Vector3(0, 0.1, 0), 0.02)
	k.pop()
	var coil := PackedVector3Array()
	for i in 60:
		var a := i * 0.7
		coil.append(Vector3(0.38 - i * 0.003, 0.05 + sin(a) * 0.015, 0.05 + cos(a) * 0.015 - i * 0.001))
	k.tube("bakelite", coil, 0.004, 4)
	_save(k, "radio")

static func _desk() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 0.4; k.ao_min = 0.65
	k.box("wood_warm", Vector3(1.5, 0.05, 0.72), Vector3(0, 0.76, 0), 0.015)
	for lx in [-0.7, 0.7]:
		for lz in [-0.31, 0.31]:
			k.box("wood_warm", Vector3(0.06, 0.74, 0.06), Vector3(lx, 0.37, lz), 0.01)
	k.box("wood_warm", Vector3(0.5, 0.5, 0.66), Vector3(0.48, 0.48, 0), 0.015)
	for d in 3:
		k.box("wood_warm", Vector3(0.46, 0.14, 0.02), Vector3(0.48, 0.32 + d * 0.16, 0.335), 0.01)
		k.box("brass", Vector3(0.08, 0.015, 0.02), Vector3(0.48, 0.32 + d * 0.16, 0.35), 0.005)
	k.box("wood_warm", Vector3(1.4, 0.08, 0.02), Vector3(0, 0.68, 0.33), 0.005)
	_save(k, "desk")

## Open logbook with a pencil and a brass oil lamp. Origin: on the desk top.
static func _logbook() -> void:
	var k := MeshKit.new()
	k.box("leather", Vector3(0.46, 0.025, 0.32), Vector3(0, 0.012, 0), 0.008)
	for side: float in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, side * 0.06), Vector3(side * 0.112, 0.028, 0)))
		k.box("linen", Vector3(0.21, 0.016, 0.29), Vector3.ZERO, 0.004)
		k.pop()
		var x0 := side * 0.012
		var x1 := side * 0.215
		var y0 := 0.037
		var y1 := 0.037 + 0.012
		if side < 0.0:
			k.quad("paper_log", Vector3(x1, y1, 0.14), Vector3(x0, y0, 0.14), Vector3(x0, y0, -0.14), Vector3(x1, y1, -0.14))
		else:
			k.quad("paper_log", Vector3(x0, y0, 0.14), Vector3(x1, y1, 0.14), Vector3(x1, y1, -0.14), Vector3(x0, y0, -0.14))
	k.push(Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.BACK, PI / 2.0), Vector3(0.12, 0.05, 0.1)))
	k.cylinder("canister", 0.006, 0.006, 0.17, 6, -0.085)
	k.pop()
	# Oil lamp beside the book.
	k.push(Transform3D(Basis(), Vector3(-0.42, 0.0, -0.05)))
	k.lathe("brass", _prof([[0.0, 0.0], [0.08, 0.0], [0.085, 0.02], [0.05, 0.05], [0.07, 0.1], [0.05, 0.13], [0.02, 0.15], [0.0, 0.15]]), 18, true)
	k.lathe("glass", _prof([[0.035, 0.15], [0.055, 0.2], [0.05, 0.27], [0.03, 0.33]]), 16, true)
	k.lathe("bulb", _prof([[0.0, 0.16], [0.012, 0.18], [0.008, 0.22], [0.0, 0.23]]), 8, true)
	k.pop()
	_save(k, "logbook")

static func _armchair() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 0.4; k.ao_min = 0.65
	for lx in [-0.36, 0.36]:
		for lz in [-0.34, 0.34]:
			k.push(Transform3D(Basis(), Vector3(lx, 0, lz)))
			k.cylinder("wood_warm", 0.03, 0.024, 0.14, 8)
			k.pop()
	k.box("wool_red", Vector3(0.86, 0.26, 0.82), Vector3(0, 0.27, 0), 0.06, 2)
	k.box("wool_red", Vector3(0.66, 0.14, 0.66), Vector3(0, 0.46, 0.05), 0.06, 2)
	k.push(Transform3D(Basis(Vector3.RIGHT, -0.16), Vector3(0, 0.72, -0.34)))
	k.box("wool_red", Vector3(0.84, 0.72, 0.18), Vector3.ZERO, 0.08, 2)
	k.pop()
	for ax in [-0.38, 0.38]:
		k.box("wool_red", Vector3(0.14, 0.28, 0.78), Vector3(ax, 0.52, 0.0), 0.06, 2)
	k.push(Transform3D(Basis(Vector3.UP, 0.2), Vector3(0.12, 0.56, 0.12)))
	k.box("quilt", Vector3(0.42, 0.06, 0.32), Vector3.ZERO, 0.03, 2)
	k.pop()
	_save(k, "armchair")

static func _bed() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 0.5; k.ao_min = 0.6
	for lx in [-0.92, 0.92]:
		for lz in [-0.48, 0.48]:
			k.box("wood_warm", Vector3(0.08, 0.36, 0.08), Vector3(lx, 0.18, lz), 0.015)
	k.box("wood_warm", Vector3(1.9, 0.16, 1.02), Vector3(0, 0.3, 0), 0.02)
	k.box("wood_warm", Vector3(0.07, 1.0, 1.04), Vector3(-0.97, 0.6, 0), 0.02)
	for s in 5:
		k.box("wood_warm", Vector3(0.05, 0.46, 0.06), Vector3(-0.97, 0.72, -0.36 + s * 0.18), 0.012)
	k.box("wood_warm", Vector3(0.07, 0.62, 1.04), Vector3(0.97, 0.42, 0), 0.02)
	k.box("linen", Vector3(1.84, 0.18, 0.96), Vector3(0, 0.46, 0), 0.06, 2)
	k.box("linen", Vector3(0.36, 0.12, 0.7), Vector3(-0.7, 0.6, 0), 0.06, 2)
	k.box("quilt", Vector3(1.4, 0.06, 1.04), Vector3(0.24, 0.57, 0), 0.03, 2)
	k.box("quilt_red", Vector3(0.36, 0.08, 1.02), Vector3(0.74, 0.63, 0), 0.03, 2)
	_save(k, "bed")

## Ledged plank door with strap hinges and a thumb latch. Origin: floor
## centre of the doorway, front face +Z. 1.0 x 2.0 m.
static func _door() -> void:
	var k := MeshKit.new()
	k.box("wood_warm", Vector3(1.22, 0.1, 0.12), Vector3(0, 2.08, 0), 0.015)
	for sx in [-0.56, 0.56]:
		k.box("wood_warm", Vector3(0.1, 2.12, 0.12), Vector3(sx, 1.04, 0), 0.015)
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	for p in 6:
		k.tint = Color(1, 1, 1) * rng.randf_range(0.88, 1.06)
		k.box("wood_warm", Vector3(0.165, 2.0, 0.045), Vector3(-0.42 + p * 0.168, 1.0, 0.02), 0.008)
	k.tint = Color(1, 1, 1)
	for ly in [0.35, 1.65]:
		k.box("wood_warm", Vector3(0.94, 0.14, 0.035), Vector3(0, ly, 0.06), 0.01)
		k.box("iron", Vector3(0.5, 0.05, 0.012), Vector3(-0.22, ly, 0.083), 0.004)
	k.push(Transform3D(Basis(Vector3.BACK, 0.95), Vector3(0, 1.0, 0.06)))
	k.box("wood_warm", Vector3(0.12, 1.46, 0.032), Vector3.ZERO, 0.01)
	k.pop()
	k.box("iron", Vector3(0.04, 0.2, 0.03), Vector3(0.38, 1.0, 0.09), 0.01)
	k.box("iron", Vector3(0.14, 0.02, 0.02), Vector3(0.34, 1.12, 0.1), 0.006)
	_save(k, "door")

# --- lighthouse hero props --------------------------------------------------------

## Clockwork rotation machine: tall case with a glazed front showing the brass
## drive weights and chains, a gear train on top and a winding crank.
static func _clock_weights() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 0.6; k.ao_min = 0.6
	k.box("wood_beam", Vector3(0.95, 0.12, 0.95), Vector3(0, 0.06, 0), 0.02)
	for cx in [-0.42, 0.42]:
		for cz in [-0.42, 0.42]:
			k.box("wood_beam", Vector3(0.09, 2.0, 0.09), Vector3(cx, 1.06, cz), 0.015)
	k.box("wood_beam", Vector3(0.95, 0.1, 0.95), Vector3(0, 2.1, 0), 0.02)
	k.box("wood_beam", Vector3(0.84, 1.9, 0.03), Vector3(0, 1.06, -0.43), 0.01)
	for sx in [-0.43, 0.43]:
		k.box("wood_beam", Vector3(0.03, 1.9, 0.84), Vector3(sx, 1.06, 0), 0.01)
	k.box("glass", Vector3(0.78, 1.82, 0.01), Vector3(0, 1.06, 0.44), 0.0)
	k.box("wood_beam", Vector3(0.05, 1.9, 0.04), Vector3(0, 1.06, 0.445), 0.01)
	for wx in [-0.18, 0.18]:
		k.tube("iron", PackedVector3Array([Vector3(wx, 2.05, 0), Vector3(wx, 1.0 if wx < 0.0 else 1.4, 0)]), 0.012, 4)
		var wy := 0.62 if wx < 0.0 else 1.02
		k.push(Transform3D(Basis(), Vector3(wx, wy, 0)))
		k.lathe("brass", _prof([[0.0, 0.0], [0.09, 0.0], [0.1, 0.03], [0.1, 0.34], [0.09, 0.37], [0.0, 0.37]]), 16, true)
		k.pop()
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 2.32, 0.0)))
	var gear := []
	for i in 49:
		var a := TAU * i / 48.0
		var r := 0.3 if (i % 2 == 0) else 0.27
		gear.append(Vector2(cos(a) * r, sin(a) * r))
	k.extrude("brass", PackedVector2Array(gear), 0.04)
	k.pop()
	k.box("iron", Vector3(0.1, 0.2, 0.1), Vector3(0, 2.25, 0), 0.02)
	k.tube("iron", PackedVector3Array([Vector3(0.48, 1.3, 0.2), Vector3(0.6, 1.3, 0.2), Vector3(0.6, 1.1, 0.2), Vector3(0.72, 1.1, 0.2)]), 0.018, 6)
	k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(0.72, 1.1, 0.2)))
	k.cylinder("wood_warm", 0.03, 0.03, 0.14, 8, -0.07)
	k.pop()
	k.box("brass", Vector3(0.22, 0.08, 0.01), Vector3(0, 1.85, 0.452), 0.004)
	_save(k, "clock_weights")

## Iron spiral stair: 11 wedge treads around a newel post, with a handrail.
## Origin: floor at the newel centre; rises 3.0 m clockwise.
static func _spiral_stair() -> void:
	var k := MeshKit.new()
	k.cylinder("iron", 0.08, 0.08, 3.1, 12, 0.0)
	var steps := 11
	for s in steps:
		var a := s * 0.52
		var y := 0.27 * (s + 1)
		k.push(Transform3D(Basis(Vector3.UP, -a), Vector3(0, y, 0)))
		k.box("iron", Vector3(0.95, 0.04, 0.34), Vector3(0.52, 0, 0), 0.01)
		k.box("iron", Vector3(0.9, 0.03, 0.02), Vector3(0.52, -0.02, 0.17), 0.005)
		k.pop()
	var rail := PackedVector3Array()
	for s in steps * 3:
		var a := s * 0.52 / 3.0
		rail.append(Vector3(cos(-a) * 0.98, 0.27 + s * 0.09 + 0.9, sin(-a) * 0.98))
	k.tube("brass", rail, 0.025, 6)
	for s in steps:
		var a := s * 0.52
		var y := 0.27 * (s + 1)
		k.tube("iron", PackedVector3Array([Vector3(cos(-a) * 0.98, y, sin(-a) * 0.98), Vector3(cos(-a) * 0.98, y + 0.9, sin(-a) * 0.98)]), 0.012, 4)
	_save(k, "spiral_stair")

## The lamp: a burner (swapped lit/unlit at runtime as its own mesh) inside a
## stepped glass Fresnel lens with brass bands, on a cast pedestal.
static func _lantern_lens() -> void:
	var k := MeshKit.new()
	k.lathe("iron", _prof([[0.0, 0.0], [0.42, 0.0], [0.42, 0.08], [0.28, 0.14], [0.22, 0.5], [0.3, 0.56], [0.36, 0.6], [0.0, 0.6]]), 20, true)
	var rings := 7
	for r in rings:
		var y0 := 0.62 + r * 0.16
		var t := (r + 0.5) / rings - 0.5
		var rad := 0.46 - t * t * 0.5
		k.lathe("glass_lantern", _prof([[rad - 0.04, y0], [rad, y0 + 0.05], [rad, y0 + 0.11], [rad - 0.05, y0 + 0.16]]), 24)
		k.lathe("brass", _prof([[rad + 0.002, y0 - 0.008], [rad + 0.012, y0], [rad + 0.012, y0 + 0.01], [rad + 0.002, y0 + 0.016]]), 24)
	for i in 8:
		var a := TAU * i / 8.0
		k.tube("brass", PackedVector3Array([Vector3(cos(a) * 0.45, 0.6, sin(a) * 0.45), Vector3(cos(a) * 0.47, 1.18, sin(a) * 0.47), Vector3(cos(a) * 0.42, 1.76, sin(a) * 0.42)]), 0.012, 4)
	k.lathe("brass", _prof([[0.0, 1.76], [0.42, 1.76], [0.3, 1.86], [0.12, 1.92], [0.0, 1.93]]), 20, true)
	k.cylinder("iron", 0.05, 0.04, 0.4, 8, 1.92)
	_save(k, "lantern_lens")
	var b := MeshKit.new()
	b.lathe("lamp_off", _prof([[0.0, 0.85], [0.13, 0.9], [0.16, 1.15], [0.12, 1.36], [0.0, 1.4]]), 16, true)
	_save(b, "lantern_burner")

static func _bench() -> void:
	var k := MeshKit.new()
	k.box("wood_warm", Vector3(0.42, 0.06, 1.3), Vector3(0, 0.46, 0), 0.015)
	for lz in [-0.55, 0.55]:
		k.box("wood_warm", Vector3(0.36, 0.43, 0.06), Vector3(0, 0.215, lz), 0.012)
	k.box("wood_warm", Vector3(0.05, 0.06, 1.1), Vector3(0, 0.15, 0), 0.01)
	k.push(Transform3D(Basis(Vector3.UP, 0.3), Vector3(0.02, 0.49, 0.25)))
	k.box("quilt_red", Vector3(0.34, 0.05, 0.3), Vector3.ZERO, 0.02, 2)
	k.pop()
	_save(k, "bench")

static func _floor_hatch() -> void:
	var k := MeshKit.new()
	k.box("wood_beam", Vector3(1.1, 0.08, 1.1), Vector3(0, 0.0, 0), 0.01)
	k.box("iron", Vector3(0.9, 0.02, 0.9), Vector3(0, 0.045, 0), 0.005)
	for rx in [-0.4, 0.4]:
		k.tube("brass", PackedVector3Array([Vector3(rx, 0.05, 0.4), Vector3(rx, 0.85, 0.42), Vector3(rx, 0.95, 0.3)]), 0.022, 6)
	_save(k, "floor_hatch")

# --- furniture + small props ----------------------------------------------------------

static func _table_chairs() -> void:
	var t := MeshKit.new()
	t.ao_ground_y = 0.0; t.ao_range = 0.4; t.ao_min = 0.65
	t.box("wood_warm", Vector3(1.1, 0.05, 0.75), Vector3(0, 0.74, 0), 0.015)
	for lx in [-0.48, 0.48]:
		for lz in [-0.3, 0.3]:
			t.push(Transform3D(Basis(), Vector3(lx, 0, lz)))
			t.soft_cylinder("wood_warm", 0.032, 0.72, 10, 0.008, 0.0, 0.8)
			t.pop()
	_save(t, "table")
	var c := MeshKit.new()
	for lx in [-0.2, 0.2]:
		for lz in [-0.2, 0.2]:
			c.push(Transform3D(Basis(), Vector3(lx, 0, lz)))
			c.soft_cylinder("wood_warm", 0.022, 0.45, 8, 0.006)
			c.pop()
	c.box("wood_warm", Vector3(0.46, 0.04, 0.46), Vector3(0, 0.46, 0), 0.012)
	for lx in [-0.2, 0.2]:
		c.box("wood_warm", Vector3(0.035, 0.5, 0.035), Vector3(lx, 0.72, -0.21), 0.008)
	for sy in [0.7, 0.88]:
		c.box("wood_warm", Vector3(0.42, 0.06, 0.025), Vector3(0, sy, -0.21), 0.008)
	_save(c, "chair")

static func _shelf_books() -> void:
	var k := MeshKit.new()
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	k.box("wood_warm", Vector3(1.2, 0.03, 0.26), Vector3(0, 0, 0.13), 0.008)
	k.box("wood_warm", Vector3(1.2, 0.03, 0.26), Vector3(0, 0.42, 0.13), 0.008)
	for sx in [-0.58, 0.58]:
		k.box("wood_warm", Vector3(0.03, 0.45, 0.26), Vector3(sx, 0.21, 0.13), 0.008)
	var colors := [Color("6a2e28"), Color("2e4a5a"), Color("4e5a32"), Color("8a6a3a"), Color("3a3030"), Color("b8ae9c")]
	for shelf in 2:
		var x := -0.54
		var y0 := 0.015 + shelf * 0.42
		while x < 0.5:
			var w := rng.randf_range(0.025, 0.055)
			var h := rng.randf_range(0.2, 0.3) if shelf == 0 else rng.randf_range(0.16, 0.26)
			k.tint = colors[rng.randi() % colors.size()]
			var lean := 0.0 if rng.randf() > 0.12 else rng.randf_range(-0.25, 0.25)
			k.push(Transform3D(Basis(Vector3.BACK, lean), Vector3(x + w * 0.5, y0, 0.13)))
			k.box("book", Vector3(w, h, rng.randf_range(0.15, 0.21)), Vector3(0, h * 0.5, 0), 0.006)
			k.pop()
			x += w + 0.003
		if shelf == 1:
			k.tint = Color(1, 1, 1)
	k.tint = Color(1, 1, 1)
	_save(k, "shelf_books")

static func _small_props() -> void:
	# Enamel mug.
	var m := MeshKit.new()
	m.lathe("enamel", _prof([[0.0, 0.0], [0.04, 0.0], [0.042, 0.09], [0.038, 0.09], [0.036, 0.01], [0.0, 0.01]]), 16, true)
	m.tube("enamel", PackedVector3Array([Vector3(0.04, 0.07, 0), Vector3(0.07, 0.06, 0), Vector3(0.07, 0.03, 0), Vector3(0.04, 0.02, 0)]), 0.008, 5)
	_save(m, "mug")
	# Hand lantern.
	var l := MeshKit.new()
	l.lathe("iron", _prof([[0.0, 0.0], [0.09, 0.0], [0.09, 0.05], [0.06, 0.06], [0.0, 0.06]]), 12, true)
	l.lathe("glass", _prof([[0.06, 0.06], [0.08, 0.12], [0.07, 0.22], [0.05, 0.25]]), 12, true)
	l.lathe("iron", _prof([[0.05, 0.25], [0.09, 0.26], [0.06, 0.3], [0.0, 0.32]]), 12, true)
	l.tube("iron", PackedVector3Array([Vector3(-0.07, 0.3, 0), Vector3(0, 0.4, 0), Vector3(0.07, 0.3, 0)]), 0.006, 4)
	_save(l, "hand_lantern")
	# Oilskin coat on a peg.
	var c := MeshKit.new()
	c.box("wood_warm", Vector3(0.04, 0.04, 0.12), Vector3(0, 0, 0.06), 0.01)
	c.push(Transform3D(Basis(), Vector3(0, -0.5, 0.12)))
	c.lathe("canister", _prof([[0.05, 0.45], [0.18, 0.38], [0.22, 0.0], [0.24, -0.35]]), 12, true)
	c.pop()
	_save(c, "oilskin")
	# Rug.
	var r := MeshKit.new()
	r.box("rug", Vector3(2.0, 0.015, 1.3), Vector3(0, 0.008, 0), 0.006)
	r.box("quilt_red", Vector3(1.8, 0.017, 1.1), Vector3(0, 0.009, 0), 0.004)
	r.box("rug", Vector3(1.5, 0.019, 0.8), Vector3(0, 0.01, 0), 0.004)
	_save(r, "rug")
	# Crate and oil can.
	var cr := MeshKit.new()
	for s in 3:
		cr.tint = Color(1, 1, 1) * (0.9 + s * 0.06)
		cr.box("wood_weathered", Vector3(0.6, 0.13, 0.42), Vector3(0, 0.07 + s * 0.135, 0), 0.01)
	cr.tint = Color(1, 1, 1)
	_save(cr, "crate")
	var oc := MeshKit.new()
	oc.lathe("keeper_red", _prof([[0.0, 0.0], [0.1, 0.0], [0.1, 0.24], [0.07, 0.28], [0.0, 0.28]]), 16, true)
	oc.tube("iron", PackedVector3Array([Vector3(0.05, 0.27, 0), Vector3(0.1, 0.36, 0), Vector3(0.14, 0.42, 0)]), 0.008, 5)
	_save(oc, "oil_can")
	# Curtain panel (hangs from origin, 1.2 tall, faces +Z) with soft folds.
	var cu := MeshKit.new()
	var folds := PackedVector2Array()
	for i in 13:
		folds.append(Vector2(-0.3 + i * 0.05, sin(i * 1.3) * 0.025))
	for i in 12:
		var a := folds[i]; var b := folds[i + 1]
		cu.quad("linen", Vector3(a.x, -1.2, a.y), Vector3(b.x, -1.2, b.y), Vector3(b.x, 0, b.y), Vector3(a.x, 0, a.y), true)
	_save(cu, "curtain")

# --- the Coast Guard tender (prologue crossing) -----------------------------------------

## Hull cross-section point: station `t` (0 stern .. 1 bow), angle `th`
## (-PI/2 port sheer .. PI/2 starboard sheer). Bow points to -Z.
static func _tender_pt(t: float, th: float) -> Vector3:
	var len := 11.0
	var z := lerpf(len * 0.5, -len * 0.5, t)
	var beam := 1.9 * (1.0 - pow(maxf(0.0, t - 0.45) / 0.55, 1.6)) * (0.9 + 0.1 * sin(t * PI))
	var sheer := 1.1 + pow(t, 2.5) * 0.55
	var depth := 0.9 * (1.0 - pow(t, 3.0) * 0.4)
	return Vector3(beam * sin(th), lerpf(sheer, -depth, cos(th)), z)

static func _tender() -> void:
	var k := MeshKit.new()
	var st := 18
	var ring := 13
	for band in [["trim_white", -PI / 2.0, -0.62], ["keeper_red", -0.62, -0.42], ["iron", -0.42, 0.42], ["keeper_red", 0.42, 0.62], ["trim_white", 0.62, PI / 2.0]]:
		var verts := PackedVector3Array(); var norms := PackedVector3Array(); var idx := PackedInt32Array()
		var n := 4
		for i in st + 1:
			var t := float(i) / st
			for j in n + 1:
				var th := lerpf(band[1], band[2], float(j) / n)
				var p := _tender_pt(t, th)
				verts.append(p)
				var outward := Vector3(sin(th), -cos(th) * 0.8, 0.0).normalized()
				norms.append(outward)
		for i in st:
			for j in n:
				var a := i * (n + 1) + j
				var b := a + n + 1
				idx.append_array([a, a + 1, b + 1, a, b + 1, b])
		k.emit(band[0], verts, norms, idx)
	# Transom.
	var tr := PackedVector2Array()
	for j in 9:
		var p := _tender_pt(0.0, lerpf(PI / 2.0, -PI / 2.0, j / 8.0))
		tr.append(Vector2(p.x, p.y))
	k.push(Transform3D(Basis(), Vector3(0, 0, 5.5)))
	k.extrude("trim_white", tr, 0.06)
	k.pop()
	# Deck planks + gunwale rails.
	var z := 5.3
	while z > -4.2:
		var t := inverse_lerp(5.5, -5.5, z)
		var w := absf(_tender_pt(t, PI / 2.0).x) * 2.0 - 0.18
		k.box("wood_weathered", Vector3(w, 0.05, 0.2), Vector3(0, 1.08, z), 0.01)
		z -= 0.23
	for side in [-1.0, 1.0]:
		var rail := PackedVector3Array()
		for i in 13:
			var t := float(i) / 12.0
			rail.append(_tender_pt(t, side * PI / 2.0) + Vector3(0, 0.08, 0))
		k.tube("trim_white", rail, 0.05, 6)
	# Bow pulpit.
	var pulpit := PackedVector3Array()
	var ts := [0.72, 0.82, 0.9, 0.96, 1.0, 0.96, 0.9, 0.82, 0.72]
	for i in ts.size():
		var side := -1.0 if i < 4 else 1.0
		pulpit.append(_tender_pt(ts[i], side * PI / 2.0) + Vector3(0, 0.72, 0))
	k.tube("iron", pulpit, 0.03, 6)
	# Wheelhouse with lit windows, mast and a coil of line forward.
	k.box("trim_white", Vector3(2.6, 1.7, 2.4), Vector3(0, 1.95, 2.9), 0.05, 2)
	k.box("keeper_red", Vector3(2.9, 0.14, 2.8), Vector3(0, 2.86, 2.9), 0.04)
	for wx in [-0.72, 0.0, 0.72]:
		k.box("window_glow", Vector3(0.6, 0.55, 0.04), Vector3(wx, 2.3, 1.69), 0.01)
	k.cylinder("iron", 0.05, 0.035, 2.4, 8, 2.93)
	k.push(Transform3D(Basis(), Vector3(0, 2.93, 2.9)))
	k.box("iron", Vector3(0.9, 0.05, 0.05), Vector3(0, 1.8, 0), 0.01)
	k.pop()
	var coil := PackedVector3Array()
	for i in 70:
		var a := i * 0.4
		coil.append(Vector3(0.5 + cos(a) * (0.14 + i * 0.003), 1.13 + (i / 24) * 0.035, -2.6 + sin(a) * (0.14 + i * 0.003)))
	k.tube("rope", coil, 0.022, 5)
	k.box("iron", Vector3(0.22, 0.12, 0.12), Vector3(0, 1.16, -3.9), 0.02)
	_save(k, "tender")
