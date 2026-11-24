class_name IslandAssets
## Exterior landmarks of Gannet Rock as scenes under res://scenes/island/.
## Placement matches the gameplay layout (Terrain constants, interactable
## positions and radii are unchanged from the greybox; tests rely on them).

const OUT := "res://scenes/island/"

static func build_all() -> void:
	_terrain()
	_lighthouse()
	_cottage()
	_pier()
	_wreck()
	_cave()
	_rocks()

static func _ring(radius: float, y: float, n := 48) -> PackedVector3Array:
	var p := PackedVector3Array()
	for i in n + 1:
		var a := TAU * i / n
		p.append(Vector3(cos(a) * radius, y, sin(a) * radius))
	return p

static func _glow(it: Interactable, nodes: Array) -> void:
	var paths: Array[NodePath] = []
	for n in nodes:
		paths.append(it.get_path_to(n))
	it.highlight_paths = paths

static func _bino(parent: Node, label: String, pos: Vector3) -> void:
	var n := Node3D.new()
	n.name = "BinoTarget"
	n.position = pos
	n.set_meta("label", label)
	n.add_to_group("bino_target", true)
	parent.add_child(n)

# --- terrain -----------------------------------------------------------------------

## Render mesh (smooth, ~130k tris) + material, and the gameplay collision
## shape (the coarse grid). Both derive from Terrain.height(): re-run the
## factory after changing the height field.
static func _terrain() -> void:
	var T := "res://assets/textures/"
	var m := ShaderMaterial.new()
	m.shader = load("res://art/terrain.gdshader")
	for pair in [["sand_tex", "sand_albedo"], ["rock_tex", "granite_albedo"], ["grass_tex", "grass_albedo"],
			["moss_tex", "moss_albedo"], ["macro_tex", "macro_breakup"], ["sand_nrm", "sand_normal"],
			["rock_nrm", "granite_normal"], ["grass_nrm", "grass_normal"]]:
		m.set_shader_parameter(pair[0], load(T + pair[1] + ".png"))
	ResourceSaver.save(m, "res://assets/materials/terrain.tres")
	m.take_over_path("res://assets/materials/terrain.tres")
	var mesh := Terrain.build_smooth_mesh()
	mesh.surface_set_material(0, m)
	SceneUtil.save_mesh(mesh, "terrain")
	var shape := Terrain.build_mesh().create_trimesh_shape()
	ResourceSaver.save(shape, SceneUtil.MODELS + "terrain_collision.res", ResourceSaver.FLAG_COMPRESS)
	print("    model terrain (+ collision)")
	var o := ShaderMaterial.new()
	o.shader = load("res://world/ocean.gdshader")
	o.set_shader_parameter("normal_tex", load(T + "water_normal.png"))
	o.set_shader_parameter("foam_tex", load(T + "foam_albedo.png"))
	ResourceSaver.save(o, "res://assets/materials/ocean.tres")

# --- lighthouse ----------------------------------------------------------------

static func _tower_r(y: float) -> float:
	return 3.3 - 1.05 * pow(clampf((y - 3.1) / 14.6, 0.0, 1.0), 1.1)

static func _lighthouse() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 3.5; k.ao_min = 0.72
	# Granite plinth the keeper's door is set into.
	k.lathe("granite", PackedVector2Array([Vector2(4.45, -1.4), Vector2(4.45, 0.15), Vector2(4.3, 0.3),
		Vector2(4.12, 0.42), Vector2(4.0, 2.55), Vector2(3.86, 2.7), Vector2(3.86, 2.85),
		Vector2(3.5, 3.05), Vector2(3.3, 3.1)]), 40)
	# Tapered whitewashed tower with the keeper-red day-mark band.
	var sections := [[3.1, 9.25, "whitewash"], [9.25, 12.75, "keeper_red"], [12.75, 17.7, "whitewash"]]
	for s in sections:
		var prof := PackedVector2Array()
		var y0: float = s[0]
		var y1: float = s[1]
		var steps := int(ceil((y1 - y0) / 0.7))
		for i in steps + 1:
			var y := lerpf(y0, y1, float(i) / steps)
			prof.append(Vector2(_tower_r(y), y))
		k.lathe(s[2], prof, 48, true)
	# Thin cornice rings where the band meets the white.
	for yb in [9.25, 12.75]:
		k.lathe("trim_white", PackedVector2Array([Vector2(_tower_r(yb) - 0.02, yb - 0.06), Vector2(_tower_r(yb) + 0.05, yb - 0.04),
			Vector2(_tower_r(yb) + 0.05, yb + 0.04), Vector2(_tower_r(yb) - 0.02, yb + 0.06)]), 48)
	# Corbel flare + brackets under the gallery.
	var rt := _tower_r(17.7)
	k.lathe("iron", PackedVector2Array([Vector2(rt, 17.55), Vector2(rt + 0.12, 17.75), Vector2(2.75, 17.95), Vector2(3.0, 18.0)]), 40)
	for i in 16:
		var a := TAU * i / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		k.push(Transform3D(Basis(Vector3.UP, -a + PI / 2.0), d * (rt + 0.3) + Vector3(0, 17.62, 0)))
		k.box("iron", Vector3(0.12, 0.42, 0.62), Vector3.ZERO, 0.03)
		k.pop()
	# Gallery deck, posts and rails.
	k.soft_cylinder("iron", 3.2, 0.22, 48, 0.04, 18.0)
	for i in 28:
		var a := TAU * i / 28.0
		k.push(Transform3D(Basis(), Vector3(cos(a) * 3.08, 0, sin(a) * 3.08)))
		k.cylinder("iron", 0.035, 0.03, 1.0, 6, 18.22, false)
		k.pop()
	k.tube("iron", _ring(3.08, 19.22), 0.045, 6)
	k.tube("iron", _ring(3.08, 18.72), 0.028, 6)
	# Lantern: iron parapet, 12-sided glazing with mullions, red cap.
	k.lathe("iron", PackedVector2Array([Vector2(0.0, 18.22), Vector2(1.95, 18.22), Vector2(1.95, 19.02), Vector2(2.03, 19.08), Vector2(1.86, 19.12)]), 12, false, false, false, PI / 12.0)
	k.cylinder("iron", 0.26, 0.2, 0.95, 12, 18.22, false)
	for i in 12:
		var a := TAU * i / 12.0 + PI / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		k.push(Transform3D(Basis(Vector3.UP, -a + PI / 2.0), d * 1.86 + Vector3(0, 20.2, 0)))
		k.box("iron", Vector3(0.07, 2.2, 0.08), Vector3.ZERO, 0.015)
		k.pop()
	k.tube("iron", _ring(1.87, 20.2, 12), 0.025, 5)
	k.lathe("glass_lantern", PackedVector2Array([Vector2(1.84, 19.1), Vector2(1.84, 21.3)]), 12, false, false, false, PI / 12.0)
	k.cylinder("iron", 2.26, 2.26, 0.07, 24, 21.24, true)
	k.lathe("keeper_red", PackedVector2Array([Vector2(2.28, 21.3), Vector2(2.34, 21.38), Vector2(2.22, 21.5),
		Vector2(1.82, 22.0), Vector2(1.26, 22.55), Vector2(0.62, 23.0), Vector2(0.18, 23.25), Vector2(0.0, 23.3)]), 32, true)
	var ball := PackedVector2Array()
	for i in 9:
		var t := -PI / 2.0 + PI * i / 8.0
		ball.append(Vector2(cos(t) * 0.26, 23.55 + sin(t) * 0.26))
	k.lathe("iron", ball, 12, true)
	k.tube("iron", PackedVector3Array([Vector3(0, 23.8, 0), Vector3(0, 24.9, 0)]), 0.025, 5)
	# Keeper's door in the plinth (+Z faces the cottage and pier).
	k.box("granite", Vector3(2.0, 2.95, 0.7), Vector3(0, 1.35, 4.0), 0.06, 2)
	k.box("granite", Vector3(2.3, 0.28, 0.85), Vector3(0, 2.92, 4.08), 0.05)
	k.box("granite", Vector3(2.2, 0.32, 1.0), Vector3(0, -0.02, 4.55), 0.05)
	# Stair windows up the tower.
	for w in [[6.6, 0.0], [10.8, PI * 0.75], [14.8, -PI * 0.6]]:
		var wy: float = w[0]
		var wa: float = w[1]
		var r := _tower_r(wy)
		var d := Vector3(sin(wa), 0, cos(wa))
		k.push(Transform3D(Basis(Vector3.UP, wa), d * (r - 0.05) + Vector3(0, wy, 0)))
		k.box("granite", Vector3(0.78, 1.18, 0.3), Vector3.ZERO, 0.03)
		k.box("window_glow", Vector3(0.52, 0.9, 0.1), Vector3(0, 0, 0.12), 0.01)
		k.box("granite", Vector3(0.92, 0.12, 0.38), Vector3(0, -0.62, 0.05), 0.02)
		k.pop()
	var mesh := SceneUtil.kit_mesh(k, "lighthouse")
	var lens_k := MeshKit.new()
	lens_k.lathe("lamp_off", PackedVector2Array([Vector2(0.0, 19.2), Vector2(0.34, 19.3), Vector2(0.6, 19.68),
		Vector2(0.66, 20.0), Vector2(0.6, 20.32), Vector2(0.34, 20.7), Vector2(0.0, 20.8)]), 24, true)
	var lens := SceneUtil.kit_mesh(lens_k, "lighthouse_lens", false)
	var knob_k := MeshKit.new()
	knob_k.box("red_paint", Vector3(1.12, 2.2, 0.1), Vector3(0, 1.15, 4.36), 0.02)
	for py in [0.62, 1.62]:
		knob_k.box("red_paint", Vector3(0.82, 0.78, 0.05), Vector3(0, py, 4.42), 0.03)
	knob_k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.38, 1.12, 4.45)))
	knob_k.lathe("brass", PackedVector2Array([Vector2(0.0, -0.06), Vector2(0.03, -0.05), Vector2(0.03, 0.0), Vector2(0.055, 0.02), Vector2(0.05, 0.05), Vector2(0.0, 0.06)]), 10, true)
	var knob := SceneUtil.kit_mesh(knob_k, "lighthouse_door", false)

	var root := Node3D.new()
	root.name = "Lighthouse"
	root.position = Vector3(0, 10.1, -6)
	SceneUtil.mesh_node(root, mesh, "Model", Transform3D.IDENTITY, true, "lighthouse")
	SceneUtil.mesh_node(root, lens, "Lens", Transform3D.IDENTITY, false)
	var door_mi := SceneUtil.mesh_node(root, knob, "DoorPanel", Transform3D.IDENTITY, true, "lighthouse_door")
	var col := CylinderShape3D.new(); col.radius = 4.2; col.height = 16.0
	SceneUtil.body(root, "Body", [[col, Transform3D(Basis(), Vector3(0, 5, 0))]])
	# Beam: two opposed shafts + real spot lights, and the lamp's own glow.
	var pivot := Node3D.new()
	pivot.name = "BeamPivot"
	pivot.position = Vector3(0, 19.8, 0)
	root.add_child(pivot)
	var cone := CylinderMesh.new()
	cone.top_radius = 14.0; cone.bottom_radius = 0.5; cone.height = 95.0
	cone.radial_segments = 32; cone.rings = 8
	var beam_mat := ShaderMaterial.new()
	beam_mat.shader = load("res://art/beam.gdshader")
	ResourceSaver.save(beam_mat, "res://assets/materials/beam.tres")
	beam_mat.take_over_path("res://assets/materials/beam.tres")
	for i in 2:
		var arm := Node3D.new()
		arm.name = "Arm%d" % i
		arm.rotation.y = PI * i
		pivot.add_child(arm)
		var shaft := SceneUtil.mesh_node(arm, cone, "Shaft", Transform3D(Basis.from_euler(Vector3(PI / 2.0, 0, 0)), Vector3(0, 0, 47.5)), false)
		shaft.material_override = beam_mat
		var sp := SpotLight3D.new()
		sp.name = "Spot"
		sp.light_color = Color("ffd49a")
		sp.spot_range = 160.0
		sp.spot_angle = 7.5
		sp.spot_angle_attenuation = 1.6
		sp.spot_attenuation = 0.6
		sp.light_volumetric_fog_energy = 6.0
		sp.light_specular = 0.6
		sp.light_energy = 0.0
		sp.rotation = Vector3(-0.06, PI, 0.0)
		arm.add_child(sp)
	var lamp := OmniLight3D.new()
	lamp.name = "LampLight"
	lamp.light_color = Color("ffb84d")
	lamp.light_energy = 0.0
	lamp.omni_range = 45.0
	pivot.add_child(lamp)
	_glow(SceneUtil.interactable(root, "Door", "lighthouse", "Enter the lighthouse", Vector3(0, 1.2, 4.8), 3.2, "lighthouse"), [door_mi])
	_bino(root, "GANNET ROCK LIGHTHOUSE (1884)", Vector3(0, 19.9, 0))
	SceneUtil.save_scene(root, OUT + "Lighthouse.tscn")

# --- keeper's cottage ------------------------------------------------------------

static func _window(k: MeshKit, w := 1.0, h := 1.2, shutters := true) -> void:
	# Built facing +Z at the origin (frame on the wall plane).
	k.box("trim_white", Vector3(w + 0.25, h + 0.25, 0.1), Vector3.ZERO, 0.02)
	k.box("window_glow", Vector3(w, h, 0.04), Vector3(0, 0, 0.055), 0.005)
	k.box("trim_white", Vector3(0.05, h, 0.04), Vector3(0, 0, 0.085), 0.01)
	k.box("trim_white", Vector3(w, 0.05, 0.04), Vector3(0, 0, 0.085), 0.01)
	k.box("trim_white", Vector3(w + 0.4, 0.08, 0.22), Vector3(0, -h * 0.5 - 0.14, 0.07), 0.02)
	if shutters:
		for sx in [-1.0, 1.0]:
			k.box("green_paint", Vector3(0.46, h + 0.2, 0.05), Vector3(sx * (w * 0.5 + 0.38), 0, 0.03), 0.015)
			for sl in 6:
				k.box("green_paint", Vector3(0.36, 0.03, 0.03), Vector3(sx * (w * 0.5 + 0.38), -h * 0.4 + sl * h * 0.16, 0.065), 0.008)

static func _cottage() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.3; k.ao_range = 1.4; k.ao_min = 0.68
	k.box("granite", Vector3(6.9, 0.72, 5.4), Vector3(0, -0.01, 0), 0.06, 2)
	k.box("clapboard", Vector3(6.5, 3.0, 5.0), Vector3(0, 1.8, 0), 0.02)
	for cx in [-3.2, 3.2]:
		for cz in [-2.45, 2.45]:
			k.box("trim_white", Vector3(0.2, 3.05, 0.2), Vector3(cx, 1.8, cz), 0.02)
	for cz in [-2.54, 2.54]:
		k.box("trim_white", Vector3(6.6, 0.22, 0.08), Vector3(0, 3.2, cz), 0.02)
	# Gable ends.
	for gx in [-3.15, 3.15]:
		k.push(Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(gx, 3.3, 0)))
		k.extrude("clapboard", PackedVector2Array([Vector2(-2.5, 0), Vector2(2.5, 0), Vector2(0, 1.75)]), 0.2)
		k.pop()
	# Roof: two shingled slabs on a 35 degree pitch, generous eaves.
	var pitch := atan2(1.75, 2.5)
	var run := 2.5 + 0.48
	var slope_len := run / cos(pitch)
	var ridge := Vector3(0, 5.05 + 0.1, 0)
	for side in [1.0, -1.0]:
		var d := Vector3(0, -sin(pitch), cos(pitch) * side)
		var n := Vector3(0, cos(pitch), sin(pitch) * side)
		var c := ridge + d * slope_len * 0.5 + n * 0.02
		k.push(Transform3D(Basis(Vector3.RIGHT, pitch * side), c))
		k.box("shingle", Vector3(7.3, 0.16, slope_len), Vector3.ZERO, 0.03)
		k.pop()
		var eave := ridge + d * slope_len
		k.push(Transform3D(Basis(Vector3.RIGHT, pitch * side), eave + n * -0.04))
		k.box("trim_white", Vector3(7.32, 0.2, 0.06), Vector3.ZERO, 0.015)
		k.pop()
	k.box("shingle", Vector3(7.35, 0.14, 0.34), ridge + Vector3(0, 0.1, 0), 0.04)
	# Chimney.
	k.box("brick", Vector3(0.82, 2.9, 0.82), Vector3(1.8, 4.35, -0.8), 0.03)
	k.box("granite", Vector3(0.98, 0.14, 0.98), Vector3(1.8, 5.85, -0.8), 0.03)
	k.push(Transform3D(Basis(), Vector3(1.8, 5.92, -0.8)))
	k.soft_cylinder("iron", 0.15, 0.36, 10, 0.02)
	k.pop()
	# Windows and door (front faces +Z: towards the lighthouse path).
	for wx in [-1.75, 1.75]:
		k.push(Transform3D(Basis(), Vector3(wx, 1.95, 2.53)))
		_window(k)
		k.pop()
	for wx in [-1.6, 1.6]:
		k.push(Transform3D(Basis(Vector3.UP, PI), Vector3(wx, 1.95, -2.53)))
		_window(k, 1.0, 1.2, false)
		k.pop()
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.UP, sx * PI / 2.0), Vector3(sx * 3.27, 1.95, 0.0)))
		_window(k, 0.9, 1.1, false)
		k.pop()
		k.push(Transform3D(Basis(Vector3.UP, sx * PI / 2.0), Vector3(sx * 3.18, 4.0, 0.0)))
		_window(k, 0.6, 0.6, false)
		k.pop()
	k.box("trim_white", Vector3(1.35, 2.42, 0.1), Vector3(0, 1.5, 2.53), 0.02)
	k.box("window_glow", Vector3(0.92, 0.22, 0.04), Vector3(0, 2.5, 2.585), 0.005)
	k.box("granite", Vector3(1.7, 0.32, 0.85), Vector3(0, 0.2, 2.95), 0.05)
	# Porch lamp bracket.
	k.box("iron", Vector3(0.05, 0.05, 0.3), Vector3(0.9, 2.42, 2.68), 0.01)
	k.push(Transform3D(Basis(), Vector3(0.9, 2.2, 2.82)))
	k.lathe("iron", PackedVector2Array([Vector2(0.0, 0.42), Vector2(0.13, 0.36), Vector2(0.12, 0.3), Vector2(0.1, 0.0), Vector2(0.0, -0.02)]), 8)
	k.pop()
	k.push(Transform3D(Basis(), Vector3(0.9, 2.32, 2.82)))
	k.lathe("bulb", PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.07, 0.04), Vector2(0.07, 0.16), Vector2(0.0, 0.22)]), 8, true)
	k.pop()
	# Rain barrel + woodpile by the side wall.
	k.push(Transform3D(Basis(), Vector3(-3.75, 0.34, 1.7)))
	k.lathe("wood_dark", PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.36, 0.0), Vector2(0.42, 0.45), Vector2(0.36, 0.9), Vector2(0.3, 0.9)]), 16, true)
	for hy in [0.12, 0.78]:
		k.lathe("iron", PackedVector2Array([Vector2(0.39, hy), Vector2(0.41, hy + 0.03), Vector2(0.41, hy + 0.07), Vector2(0.39, hy + 0.1)]), 16)
	k.pop()
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	for row in 4:
		for log_i in 6 - row:
			k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0).rotated(Vector3.UP, rng.randf_range(-0.05, 0.05)),
				Vector3(-1.4 + log_i * 0.26 + row * 0.13, 0.46 + row * 0.22, -2.95)))
			k.tint = Color(1, 1, 1) * rng.randf_range(0.85, 1.1)
			k.lathe("bark", PackedVector2Array([Vector2(0.0, -0.45), Vector2(0.12, -0.45), Vector2(0.12, 0.45), Vector2(0.0, 0.45)]), 7)
			k.pop()
	k.tint = Color(1, 1, 1)
	var mesh := SceneUtil.kit_mesh(k, "cottage")
	var dk := MeshKit.new()
	dk.box("green_paint", Vector3(1.0, 2.0, 0.08), Vector3(0, 1.33, 2.58), 0.02)
	for py in [0.85, 1.75]:
		dk.box("green_paint", Vector3(0.72, 0.6, 0.04), Vector3(0, py, 2.63), 0.025)
	dk.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.36, 1.3, 2.64)))
	dk.lathe("brass", PackedVector2Array([Vector2(0.0, -0.05), Vector2(0.03, -0.04), Vector2(0.03, 0.0), Vector2(0.05, 0.02), Vector2(0.045, 0.05), Vector2(0.0, 0.06)]), 10, true)
	dk.pop()
	var door_mesh := SceneUtil.kit_mesh(dk, "cottage_door", false)

	var root := Node3D.new()
	root.name = "Cottage"
	root.position = Vector3(Terrain.COTTAGE_POS.x, Terrain.COTTAGE_Y, Terrain.COTTAGE_POS.y)
	root.rotation.y = Terrain.COTTAGE_YAW
	SceneUtil.mesh_node(root, mesh, "Model", Transform3D.IDENTITY, true, "cottage")
	var cdoor := SceneUtil.mesh_node(root, door_mesh, "DoorPanel", Transform3D.IDENTITY, true, "cottage_door")
	SceneUtil.body(root, "Body", [[SceneUtil.box_shape(Vector3(6.5, 3.6, 5.0)), Transform3D(Basis(), Vector3(0, 1.8, 0))]])
	var light := OmniLight3D.new()
	light.name = "PorchLight"
	light.light_color = Color("ffaa3b"); light.light_energy = 1.2; light.omni_range = 14.0
	light.shadow_enabled = true
	light.position = Vector3(0.9, 2.3, 3.1)
	root.add_child(light)
	var spill := OmniLight3D.new()
	spill.name = "WindowSpill"
	spill.light_color = Color("ffb066"); spill.light_energy = 0.6; spill.omni_range = 7.0
	spill.position = Vector3(0, 1.8, 3.4)
	root.add_child(spill)
	root.add_child(_smoke())
	_glow(SceneUtil.interactable(root, "Door", "cottage", "Enter the cottage", Vector3(0, 1.25, 3.8), 2.6, "cottage"), [cdoor])
	SceneUtil.save_scene(root, OUT + "Cottage.tscn")

static func _smoke() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "ChimneySmoke"
	p.position = Vector3(1.8, 6.3, -0.8)
	p.amount = 28
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.visibility_aabb = AABB(Vector3(-8, -1, -8), Vector3(16, 14, 16))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 8.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0.35, 0.12, 0.15)
	pm.damping_min = 0.05; pm.damping_max = 0.1
	pm.scale_min = 0.6; pm.scale_max = 1.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.35)); sc.add_point(Vector2(1, 2.6))
	var sct := CurveTexture.new(); sct.curve = sc
	pm.scale_curve = sct
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	g.colors = PackedColorArray([Color(0.75, 0.75, 0.76, 0.0), Color(0.72, 0.72, 0.74, 0.32), Color(0.8, 0.8, 0.82, 0.0)])
	var gt := GradientTexture1D.new(); gt.gradient = g
	pm.color_ramp = gt
	pm.angle_min = -180.0; pm.angle_max = 180.0
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1.2, 1.2)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.disable_receive_shadows = true
	var puff := GradientTexture2D.new()
	puff.fill = GradientTexture2D.FILL_RADIAL
	puff.fill_from = Vector2(0.5, 0.5); puff.fill_to = Vector2(1.0, 0.5)
	var pg := Gradient.new()
	pg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	puff.gradient = pg
	m.albedo_texture = puff
	q.material = m
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p

# --- pier --------------------------------------------------------------------------

static func _pier() -> void:
	var k := MeshKit.new()
	var rng := RandomNumberGenerator.new(); rng.seed = 1884
	var top := Terrain.PIER_TOP
	var z0 := Terrain.PIER_Z0
	var z1 := Terrain.PIER_Z1
	var cz := (z0 + z1) * 0.5
	var length := z1 - z0
	for sx in [-1.45, 0.0, 1.45]:
		k.box("wood_dark", Vector3(0.22, 0.3, length + 0.1), Vector3(sx, top - 0.08 - 0.15, cz), 0.02)
	# Deck planks run across the pier, each slightly different.
	var z := z0 + 0.13
	while z < z1 - 0.1:
		var w := 0.22 + rng.randf_range(-0.015, 0.01)
		k.tint = Color(1, 1, 1).lerp(Color(1.05, 0.98, 0.9), rng.randf()) * rng.randf_range(0.82, 1.08)
		k.push(Transform3D(Basis(Vector3.UP, rng.randf_range(-0.012, 0.012)), Vector3(rng.randf_range(-0.04, 0.04), top - 0.04 + rng.randf_range(-0.006, 0.006), z)))
		k.box("wood_weathered", Vector3(Terrain.PIER_X * 2.0 + rng.randf_range(-0.05, 0.08), 0.08, w), Vector3.ZERO, 0.014)
		k.pop()
		z += w + 0.035
	k.tint = Color(1, 1, 1)
	# Pilings (same stations as the greybox), x-bracing and the painted tide gauge.
	var pz := z0 + 3.0
	while pz <= z1:
		for px in [-1.6, 1.6]:
			k.push(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(px, 0, pz)))
			k.lathe("wood_dark", PackedVector2Array([Vector2(0.24, -4.5), Vector2(0.235, 4.6), Vector2(0.2, 4.95), Vector2(0.0, 5.0)]), 12, true)
			k.lathe("barnacle", PackedVector2Array([Vector2(0.236, -0.3), Vector2(0.252, 0.0), Vector2(0.25, 1.2), Vector2(0.236, 1.7)]), 12, true)
			k.pop()
			if pz > z0 + 12.0 and px > 0.0:
				for i in range(0, 10):
					var hgt := i * 0.5
					var thick := 0.05 if i % 2 == 1 else 0.09
					k.push(Transform3D(Basis(), Vector3(px, hgt - thick * 0.5, pz)))
					k.lathe("paint_white", PackedVector2Array([Vector2(0.258, 0.0), Vector2(0.262, 0.01), Vector2(0.262, thick - 0.01), Vector2(0.258, thick)]), 12)
					k.pop()
		k.push(Transform3D(Basis(), Vector3(0, 2.6, pz)))
		for sgn in [1.0, -1.0]:
			k.push(Transform3D(Basis(Vector3.FORWARD, sgn * 0.62), Vector3.ZERO))
			k.box("wood_dark", Vector3(3.6, 0.16, 0.12), Vector3(0, 0, sgn * 0.17), 0.02)
			k.pop()
		k.pop()
		pz += 3.6
	# Rails: posts, top and mid rails, end rail.
	var post_z := z0 + 0.3
	while post_z <= z1:
		for sx in [-1.79, 1.79]:
			k.box("wood_weathered", Vector3(0.11, 1.05, 0.11), Vector3(sx, top + 0.5, post_z), 0.02)
		post_z += 2.0
	for sx in [-1.79, 1.79]:
		k.box("wood_weathered", Vector3(0.09, 0.07, length), Vector3(sx, top + 1.0, cz), 0.02)
		k.box("wood_weathered", Vector3(0.05, 0.05, length), Vector3(sx, top + 0.55, cz), 0.015)
	k.box("wood_weathered", Vector3(3.6, 0.07, 0.09), Vector3(0, top + 1.0, z1 - 0.02), 0.02)
	k.box("wood_weathered", Vector3(3.6, 0.05, 0.05), Vector3(0, top + 0.55, z1 - 0.02), 0.015)
	# End-of-pier details: bollards, coiled rope, dock lamp post.
	for bx in [-1.15, 1.15]:
		k.push(Transform3D(Basis(), Vector3(bx, top, z1 - 0.9)))
		k.lathe("iron", PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.14, 0.32), Vector2(0.21, 0.38), Vector2(0.2, 0.44), Vector2(0.0, 0.46)]), 14, true)
		k.pop()
	var coil := PackedVector3Array()
	for i in 90:
		var a := i * 0.35
		var r := 0.12 + i * 0.0035
		coil.append(Vector3(0.75 + cos(a) * r, top + 0.03 + (i / 30) * 0.04, z1 - 2.2 + sin(a) * r))
	k.tube("rope", coil, 0.025, 5)
	k.box("wood_dark", Vector3(0.14, 2.3, 0.14), Vector3(-1.62, top + 1.15, z1 - 0.35), 0.02)
	k.box("iron", Vector3(0.05, 0.05, 0.42), Vector3(-1.62, top + 2.18, z1 - 0.18), 0.01)
	k.push(Transform3D(Basis(), Vector3(-1.62, top + 1.72, z1 + 0.02)))
	k.lathe("iron", PackedVector2Array([Vector2(0.0, 0.42), Vector2(0.14, 0.36), Vector2(0.13, 0.3), Vector2(0.11, 0.0), Vector2(0.0, -0.02)]), 8)
	k.pop()
	k.push(Transform3D(Basis(), Vector3(-1.62, top + 1.82, z1 + 0.02)))
	k.lathe("bulb", PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.075, 0.05), Vector2(0.075, 0.18), Vector2(0.0, 0.25)]), 8, true)
	k.pop()
	# Ladder down the east side of the head.
	for lx in [0.55, 1.05]:
		k.box("wood_dark", Vector3(0.08, 5.4, 0.08), Vector3(lx, top - 2.5, z1 + 0.12), 0.015)
	for r in 14:
		k.box("wood_dark", Vector3(0.5, 0.05, 0.06), Vector3(0.8, top - 0.2 - r * 0.36, z1 + 0.12), 0.01)
	var mesh := SceneUtil.kit_mesh(k, "pier")

	var root := Node3D.new()
	root.name = "Pier"
	SceneUtil.mesh_node(root, mesh, "Model", Transform3D.IDENTITY, true, "pier")
	var deck_h := 0.35
	var cy := top - deck_h / 2.0
	var shapes := [[SceneUtil.box_shape(Vector3(Terrain.PIER_X * 2.0, deck_h, length)), Transform3D(Basis(), Vector3(0, cy, cz))]]
	for side in [-1.0, 1.0]:
		shapes.append([SceneUtil.box_shape(Vector3(0.3, 1.4, length)), Transform3D(Basis(), Vector3(side * Terrain.PIER_X, top + 0.7, cz))])
	shapes.append([SceneUtil.box_shape(Vector3(Terrain.PIER_X * 2.0, 1.4, 0.3)), Transform3D(Basis(), Vector3(0, top + 0.7, z1))])
	SceneUtil.body(root, "Body", shapes)
	# Tide-gauge numerals (one per metre) on the east pilings.
	pz = z0 + 3.0
	while pz <= z1:
		if pz > z0 + 12.0:
			for i in [2, 4, 6, 8]:
				var lbl := Label3D.new()
				lbl.name = "Mark_%d_%d" % [int(pz), i / 2]
				lbl.text = str(i / 2)
				lbl.font_size = 64
				lbl.pixel_size = 0.004
				lbl.modulate = Color("e8dfc8")
				lbl.outline_size = 6
				lbl.outline_modulate = Color(0.1, 0.1, 0.1, 0.6)
				lbl.position = Vector3(1.6 - 0.3, i * 0.5 + 0.12, pz)
				lbl.rotation.y = -PI / 2.0
				root.add_child(lbl)
		pz += 3.6
	var dock := OmniLight3D.new()
	dock.name = "DockLight"
	dock.light_color = Color("ffbf70"); dock.light_energy = 0.0; dock.omni_range = 9.0
	dock.position = Vector3(-1.62, top + 1.85, z1 + 0.02)
	root.add_child(dock)
	SceneUtil.save_scene(root, OUT + "Pier.tscn")

# --- east stack: the wreck ------------------------------------------------------------

static func _hull_w(x: float) -> float:
	return 1.75 * sqrt(maxf(0.0, 1.0 - pow(x / 5.4, 2.0)))

static func _hull_d(x: float) -> float:
	return 1.7 * (0.75 + 0.25 * sqrt(maxf(0.0, 1.0 - pow(x / 5.4, 2.0))))

static func _hull_pt(x: float, th: float) -> Vector3:
	return Vector3(x, _hull_d(x) * (1.0 - cos(th)), _hull_w(x) * sin(th))

static func _wreck() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 1.2; k.ao_min = 0.55
	var rng := RandomNumberGenerator.new(); rng.seed = 1974
	k.push(Transform3D(Basis.from_euler(Vector3(0.32, 0.5, 0.06)), Vector3(-0.6, 0.15, -0.4)))
	# Keel and stem.
	k.box("wood_wreck", Vector3(10.6, 0.22, 0.24), Vector3(0, 0.05, 0), 0.03)
	var stem := PackedVector3Array()
	for i in 7:
		var t := i / 6.0
		stem.append(Vector3(5.2 + sin(t * 1.2) * 0.6, t * 2.3, 0))
	k.tube("wood_wreck", stem, 0.13, 6)
	# Ribs (frames); the starboard tops are broken off on half of them.
	for i in 10:
		var x := -4.6 + i * 1.02
		var rib := PackedVector3Array()
		var broken := rng.randf() < 0.5
		var th_max := PI / 2.0 if not broken else rng.randf_range(0.6, 1.2)
		for s in 13:
			var th := lerpf(-PI / 2.0, th_max, s / 12.0)
			rib.append(_hull_pt(x, th) * Vector3(1, 1, 1.02))
		k.tube("wood_wreck", rib, 0.07, 5)
	# Planking (strakes): complete low down and on the port side, gone above.
	for j in 11:
		var th := lerpf(-1.45, 1.45, j / 10.0)
		var keep_from := -5.2
		var keep_to := 5.2
		if th > 0.35:
			keep_from = rng.randf_range(-3.0, 0.5)
			keep_to = keep_from + rng.randf_range(1.0, 3.0)
		var xs := 18
		for s in xs:
			var xa := lerpf(-5.2, 5.2, float(s) / xs)
			var xb := lerpf(-5.2, 5.2, float(s + 1) / xs)
			if xa < keep_from or xb > keep_to:
				continue
			if rng.randf() < 0.06:
				continue
			var a := _hull_pt(xa, th)
			var b := _hull_pt(xb, th)
			var dir := b - a
			var mid := (a + b) * 0.5
			var outward := Vector3(0, -cos(th), sin(th)).normalized()
			var basis := Basis.looking_at(dir.normalized(), outward)
			k.tint = Color(1, 1, 1) * rng.randf_range(0.8, 1.1)
			k.push(Transform3D(basis, mid))
			k.box("wood_wreck", Vector3(0.28, 0.045, dir.length() + 0.04), Vector3.ZERO, 0.012)
			k.pop()
	k.tint = Color(1, 1, 1)
	# Gunwale stub, rusted fittings and a broken mast lying across.
	var gun := PackedVector3Array()
	for s in 9:
		gun.append(_hull_pt(lerpf(-5.0, 1.0, s / 8.0), -PI / 2.0) + Vector3(0, 0.05, 0))
	k.tube("wood_wreck", gun, 0.09, 6)
	k.tube("rust_metal", PackedVector3Array([Vector3(-4.8, 0.6, 0.2), Vector3(-4.9, 1.4, 0.5), Vector3(-4.7, 1.8, 0.9)]), 0.05, 6)
	k.pop()
	k.tube("wood_wreck", PackedVector3Array([Vector3(-1.4, 0.35, 1.9), Vector3(0.6, 1.0, 2.6), Vector3(3.4, 1.7, 3.6)]), 0.14, 7)
	k.box("rust_metal", Vector3(0.5, 0.35, 0.5), Vector3(-2.2, 0.25, 1.2), 0.05)
	# Seaweed-draped stones around the hull.
	for i in 7:
		k.push(Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)), Vector3(rng.randf_range(-4.5, 4.5), 0.0, rng.randf_range(-2.6, 3.4))))
		k.rock("seaweed" if i % 2 == 0 else "granite_dark", 300 + i, rng.randf_range(0.35, 0.8), Vector3(1.2, 0.5, 1.0), 2, 6)
		k.pop()
	var mesh := SceneUtil.kit_mesh(k, "wreck")
	var root := Node3D.new()
	root.name = "Wreck"
	root.position = Vector3(76, 5.4, 6)
	SceneUtil.mesh_node(root, mesh, "Model", Transform3D.IDENTITY, true, "wreck")
	var canister: Mesh = load(SceneUtil.MODELS + "canister.res")
	var can := SceneUtil.mesh_node(root, canister, "Canister", Transform3D(Basis.from_euler(Vector3(0.15, 0.6, 1.35)), Vector3(2.5, 0.55, 2.2)), true, "canister")
	_glow(SceneUtil.interactable(root, "UseCanister", "shipwreck", "Inspect 1974 Waterproof Canister", Vector3(2.5, 0.8, 2.2), 5.5, "shipwreck"), [can])
	_bino(root, "EAST SEA STACK // UNCHARTED WRECK", Vector3(0, 2.6, 0))
	SceneUtil.save_scene(root, OUT + "Wreck.tscn")

# --- west stack: the echo cave ------------------------------------------------------

static func _cave() -> void:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 3.0; k.ao_min = 0.55
	var parts := [
		[Vector3(0.2, 2.4, -4.4), 3.0, Vector3(0.95, 1.45, 0.8), 41],
		[Vector3(0.2, 2.4, 4.4), 3.0, Vector3(0.9, 1.5, 0.85), 42],
		[Vector3(-0.2, 6.2, 0.0), 3.3, Vector3(0.9, 0.55, 1.8), 43],
		[Vector3(-3.6, 3.0, 0.0), 3.2, Vector3(0.75, 1.25, 1.4), 44],
		[Vector3(2.6, 0.6, -6.2), 1.4, Vector3(1.2, 0.7, 1.0), 45],
		[Vector3(3.2, 0.4, 5.8), 1.1, Vector3(1.1, 0.6, 1.2), 46],
		[Vector3(-1.5, 8.2, -1.5), 1.6, Vector3(1.0, 0.6, 1.0), 47],
	]
	for p in parts:
		k.push(Transform3D(Basis.from_euler(Vector3(0, p[3] * 0.7, 0)), p[0]))
		k.rock("granite_dark", p[3], p[1], p[2], 3, 11)
		k.pop()
	var mesh := SceneUtil.kit_mesh(k, "sea_cave")
	var root := Node3D.new()
	root.name = "SeaCave"
	root.position = Vector3(-74, 5.5, -8)
	SceneUtil.mesh_node(root, mesh, "Model", Transform3D.IDENTITY, true, "sea_cave")
	var pillar := CylinderShape3D.new(); pillar.radius = 2.3; pillar.height = 7.0
	SceneUtil.body(root, "Body", [
		[pillar, Transform3D(Basis(), Vector3(0.2, 2.5, -4.6))],
		[pillar, Transform3D(Basis(), Vector3(0.2, 2.5, 4.6))],
		[SceneUtil.box_shape(Vector3(2.4, 7.0, 6.0)), Transform3D(Basis(), Vector3(-4.2, 2.5, 0))]])
	var buoy: Mesh = load(SceneUtil.MODELS + "acoustic_buoy.res")
	var bmi := SceneUtil.mesh_node(root, buoy, "Buoy", Transform3D(Basis.from_euler(Vector3(0.0, 0.4, 0.42)), Vector3(1.5, 0.15, 0)), true, "acoustic_buoy")
	_glow(SceneUtil.interactable(root, "UseBuoy", "seacave", "Examine Washed-Up Acoustic Buoy", Vector3(1.5, 1.0, 0), 6.0, "seacave"), [bmi])
	_bino(root, "WEST SEA STACK // ECHO SEA CAVE", Vector3(0, 3.5, 0))
	SceneUtil.save_scene(root, OUT + "SeaCave.tscn")

# --- scattered boulders -------------------------------------------------------------

static func _rocks() -> void:
	var variants: Array[Mesh] = []
	for v in 6:
		var k := MeshKit.new()
		k.ao_ground_y = -0.4; k.ao_range = 0.9; k.ao_min = 0.6
		k.rock("granite", 1000 + v, 1.0, Vector3(1.0, 0.72, 0.95), 3, 10)
		variants.append(SceneUtil.kit_mesh(k, "rock_%d" % v))
	var root := Node3D.new()
	root.name = "Rocks"
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var coords := [[14, 14, 2.4], [-16, 15, 2.8], [18, -14, 3.1], [-19, -15, 2.6],
		[8, -22, 3.5], [-10, -24, 2.9], [44, 11, 1.8], [56, -2, 2.1],
		[-42, -13, 2.0], [-55, 1, 1.7], [84, 14, 3.2], [-82, -16, 3.4]]
	var shapes := []
	var i := 0
	for c in coords:
		var s: float = c[2]
		var y := Terrain.height(c[0], c[1])
		var pos := Vector3(c[0], y + s * 0.18, c[1])
		var xf := Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.15, 0.15), rng.randf() * TAU, rng.randf_range(-0.15, 0.15))).scaled(Vector3(s * 1.15, s * 0.95, s)), pos)
		SceneUtil.mesh_node(root, variants[i % variants.size()], "Rock%d" % i, xf, true, "rock_%d" % (i % variants.size()))
		var sph := SphereShape3D.new(); sph.radius = s * 0.75
		shapes.append([sph, Transform3D(Basis(), pos)])
		i += 1
	SceneUtil.body(root, "Body", shapes)
	SceneUtil.save_scene(root, OUT + "Rocks.tscn")
