class_name VegetationAssets
## Plants and the far horizon for Gannet Rock:
##   - windswept spruce (3 variants), bayberry/juniper shrubs, seaweed clumps
##   - grass + beach-grass tufts (cards with assets/textures/grass_card.png)
##   - a seeded scatter of all of them, saved as chunked MultiMeshes so far
##     chunks drop out by visibility range
##   - distant mainland ridges and islets: flat silhouettes the fog turns into
##     colour layers
## Output: scenes/island/Vegetation.tscn + scenes/island/Horizon.tscn.

const OUT := "res://scenes/island/"
const CHUNK := 24.0

static func build_all() -> void:
	var meshes := _meshes()
	_scatter(meshes)
	_horizon()

# --- meshes -----------------------------------------------------------------------

## A jagged branch tier: a ring of drooping tips joined to a narrower ring above.
static func _tier(k: MeshKit, rng: RandomNumberGenerator, y: float, r: float, h: float, lean: Vector3) -> void:
	var n := 9 + rng.randi() % 3
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var idx := PackedInt32Array()
	var top := Vector3(0, y + h, 0) + lean * (y + h)
	verts.append(top); norms.append(Vector3.UP)
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.15, 0.15)
		var rr := r * rng.randf_range(0.75, 1.15)
		var tip := Vector3(cos(a) * rr, y - rng.randf_range(0.05, 0.3) * h, sin(a) * rr) + lean * y
		var notch_a := a + PI / n
		var notch := Vector3(cos(notch_a) * rr * 0.62, y + h * 0.12, sin(notch_a) * rr * 0.62) + lean * y
		verts.append(tip); norms.append((Vector3(cos(a), 0.9, sin(a))).normalized())
		verts.append(notch); norms.append((Vector3(cos(notch_a), 1.2, sin(notch_a))).normalized())
	var under := Vector3(0, y + h * 0.15, 0) + lean * y
	var u := verts.size()
	verts.append(under); norms.append(Vector3.DOWN)
	var m := n * 2
	for i in m:
		var a0 := 1 + i
		var a1 := 1 + (i + 1) % m
		idx.append_array([0, a0, a1])
		idx.append_array([u, a1, a0])
	k.emit("spruce", verts, norms, idx)

static func _spruce(seed: int, height: float) -> Mesh:
	var k := MeshKit.new()
	var rng := RandomNumberGenerator.new(); rng.seed = seed
	k.ao_ground_y = 0.0; k.ao_range = height * 0.8; k.ao_min = 0.55
	var lean := Vector3(-0.06, 0, -0.02) * rng.randf_range(0.6, 1.4)
	k.tube("bark", PackedVector3Array([Vector3(0, -0.3, 0), Vector3(0, height * 0.5, 0) + lean * height * 0.5, Vector3(0, height, 0) + lean * height]), 0.16 * height / 7.0, 7)
	var tiers := 7 + rng.randi() % 3
	for t in tiers:
		var f := float(t) / tiers
		var y := lerpf(height * 0.22, height * 0.92, f)
		var r := lerpf(height * 0.3, height * 0.07, f) * rng.randf_range(0.85, 1.1)
		# Windswept: the seaward (+x) side is clipped shorter.
		_tier(k, rng, y, r, height * 0.2, lean)
	_tier(k, rng, height * 0.95, height * 0.06, height * 0.12, lean)
	return SceneUtil.kit_mesh(k, "spruce_%d" % seed, true)

static func _shrub(seed: int, mat: String) -> Mesh:
	var k := MeshKit.new()
	k.ao_ground_y = 0.0; k.ao_range = 0.8; k.ao_min = 0.5
	var rng := RandomNumberGenerator.new(); rng.seed = seed
	for i in 3:
		k.push(Transform3D(Basis(), Vector3(rng.randf_range(-0.4, 0.4), 0.15, rng.randf_range(-0.4, 0.4))))
		k.rock(mat, seed * 10 + i, rng.randf_range(0.5, 0.8), Vector3(1.2, 0.75, 1.1), 2, 4)
		k.pop()
	return SceneUtil.kit_mesh(k, "%s_%d" % [mat, seed], true)

static func _tuft(name: String, w: float, h: float) -> Mesh:
	var k := MeshKit.new()
	for i in 3:
		var a := PI * i / 3.0
		var d := Vector3(cos(a), 0, sin(a)) * w * 0.5
		k.quad("grass_card", -d, d, d + Vector3(0, h, 0), -d + Vector3(0, h, 0))
	var mesh := k.commit(false)
	SceneUtil.save_mesh(mesh, name)
	return mesh

static func _meshes() -> Dictionary:
	var gm := ShaderMaterial.new()
	gm.shader = load("res://art/foliage.gdshader")
	gm.set_shader_parameter("card_tex", load("res://assets/textures/grass_card.png"))
	ResourceSaver.save(gm, "res://assets/materials/grass_card.tres")
	gm.take_over_path("res://assets/materials/grass_card.tres")
	var bm := gm.duplicate() as ShaderMaterial
	bm.set_shader_parameter("tint_a", Color(0.82, 0.74, 0.52))
	bm.set_shader_parameter("tint_b", Color(0.7, 0.66, 0.44))
	bm.set_shader_parameter("sway", 0.2)
	ResourceSaver.save(bm, "res://assets/materials/beach_grass.tres")
	bm.take_over_path("res://assets/materials/beach_grass.tres")
	var grass := _tuft("grass_tuft", 0.7, 0.45)
	var beach := _tuft("beach_grass_tuft", 0.6, 0.85)
	beach.surface_set_material(0, bm)
	ResourceSaver.save(beach, SceneUtil.MODELS + "beach_grass_tuft.res", ResourceSaver.FLAG_COMPRESS)
	return {
		"spruce": [_spruce(1, 7.5), _spruce(2, 9.0), _spruce(3, 6.0)],
		"shrub": [_shrub(1, "shrub"), _shrub(2, "shrub"), _shrub(3, "spruce")],
		"seaweed": [_shrub(4, "seaweed"), _shrub(5, "seaweed")],
		"grass": [grass], "beach": [beach],
	}

# --- scatter -------------------------------------------------------------------------

static func _slope(x: float, z: float) -> float:
	var e := 0.6
	var dx := Terrain.height(x + e, z) - Terrain.height(x - e, z)
	var dz := Terrain.height(x, z + e) - Terrain.height(x, z - e)
	var n := Vector3(-dx, 2.0 * e, -dz).normalized()
	return 1.0 - n.y

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

## Keeps plants off the pier, buildings, doors and footpaths.
static func _clear(x: float, z: float, margin := 0.0) -> bool:
	var p := Vector2(x, z)
	if absf(x) < 3.2 + margin and z > 9.0 and z < 39.0:
		return false
	if p.distance_to(Vector2(0, -6)) < 6.2 + margin:
		return false
	if p.distance_to(Terrain.COTTAGE_POS) < 6.0 + margin:
		return false
	var paths := [[Vector2(0.0, 12.6), Vector2(-1.6, 7.4)], [Vector2(-1.6, 7.4), Vector2(0.0, -1.0)], [Vector2(-1.6, 7.4), Vector2(-6.8, 4.9)]]
	for s in paths:
		if _seg_dist(p, s[0], s[1]) < 1.5 + margin:
			return false
	if p.distance_to(Vector2(76, 6)) < 7.0 + margin or p.distance_to(Vector2(-74, -8)) < 8.0 + margin:
		return false
	# M5 content: cove cable hut, reef vault and both causeway lanes stay clear.
	if p.distance_to(Vector2(-13.5, -50.0)) < 6.0 + margin or p.distance_to(Terrain.COVE_C) < 5.0 + margin:
		return false
	if p.distance_to(Terrain.VAULT_C) < 6.0 + margin:
		return false
	if _seg_dist(p, Terrain.NORTH_A, Terrain.NORTH_B) < Terrain.LANE_HALF_WIDTH + 1.5 + margin:
		return false
	if _seg_dist(p, Terrain.SOUTH_A, Terrain.SOUTH_B) < Terrain.LANE_HALF_WIDTH + 1.5 + margin:
		return false
	return true

static func _scatter(meshes: Dictionary) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 1998
	var buckets := {}   # "kind|variant|cx|cz" -> Array[Transform3D]
	var trees := []
	var add := func(kind: String, variant: int, xf: Transform3D) -> void:
		var key := "%s|%d|%d|%d" % [kind, variant, int(floor(xf.origin.x / CHUNK)), int(floor(xf.origin.z / CHUNK))]
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(xf)
	var step := 0.34
	var x := -100.0
	while x < 100.0:
		var z := -100.0
		while z < 100.0:
			var px := x + rng.randf_range(-step, step) * 0.5
			var pz := z + rng.randf_range(-step, step) * 0.5
			var h := Terrain.height(px, pz)
			if h > -0.8 and _clear(px, pz):
				var s := _slope(px, pz)
				var r := rng.randf()
				var yaw := rng.randf() * TAU
				var base := Vector3(px, h - 0.03, pz)
				if h > 4.5 and h < 11.0 and s < 0.34 and r < 0.8:
					var sc := rng.randf_range(0.7, 1.3)
					add.call("grass", 0, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc * rng.randf_range(0.8, 1.25), sc)), base))
				elif h > 4.25 and h < 5.4 and s < 0.36 and r < 0.9:
					var sc := rng.randf_range(0.7, 1.2)
					add.call("beach", 0, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc, sc)), base))
				elif h > 4.6 and h < 9.5 and s < 0.45 and r < 0.84:
					var sc := rng.randf_range(0.6, 1.25)
					add.call("shrub", rng.randi() % 3, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc * 0.8, sc)), base))
				elif h > -0.6 and h < 1.7 and r < 0.006 and (s > 0.08 or absf(px) < 24.0):
					var sc := rng.randf_range(0.35, 0.8)
					add.call("seaweed", rng.randi() % 2, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc * 0.4, sc)), base))
			z += step
		x += step
	# Spruce stands: a coarse pass on the sheltered slopes, kept out of the
	# view from the pier (the lighthouse must stay the tallest silhouette).
	var tx := -30.0
	while tx < 30.0:
		var tz := -30.0
		while tz < 30.0:
			var px := tx + rng.randf_range(-0.9, 0.9)
			var pz := tz + rng.randf_range(-0.9, 0.9)
			var h := Terrain.height(px, pz)
			var south_view := absf(px) < 5.0 and pz > -2.0
			if h > 4.8 and h < 10.4 and _slope(px, pz) < 0.42 and not south_view and _clear(px, pz, 1.2) and rng.randf() < 0.42:
				var sc := rng.randf_range(0.65, 1.15)
				var v := rng.randi() % 3
				add.call("spruce", v, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(px, h - 0.25, pz)))
				trees.append(Vector3(px, h, pz))
			tz += 2.2
		tx += 2.2
	# Build one MultiMeshInstance per (kind, variant, chunk).
	var root := Node3D.new()
	root.name = "Vegetation"
	var vis := {"grass": 70.0, "beach": 80.0, "shrub": 140.0, "seaweed": 90.0, "spruce": 420.0}
	var count := {}
	for key in buckets:
		var parts: PackedStringArray = key.split("|")
		var kind := parts[0]
		var variant := int(parts[1])
		var xfs: Array = buckets[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[kind][variant]
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = key.replace("|", "_").replace("-", "m")
		mmi.multimesh = mm
		mmi.visibility_range_end = vis[kind]
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if kind == "grass" or kind == "beach" or kind == "seaweed":
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)
		count[kind] = count.get(kind, 0) + xfs.size()
	# Trunk colliders so Arthur can't walk through the trees.
	var shapes := []
	for t in trees:
		var c := CylinderShape3D.new(); c.radius = 0.35; c.height = 3.0
		shapes.append([c, Transform3D(Basis(), t + Vector3(0, 1.5, 0))])
	if not shapes.is_empty():
		SceneUtil.body(root, "TreeBodies", shapes)
	print("    scatter ", count)
	SceneUtil.save_scene(root, OUT + "Vegetation.tscn")

# --- far horizon -------------------------------------------------------------------

## A long silhouette: rolling hill line topped with a saw-tooth of spruce.
static func _ridge(k: MeshKit, seed: int, length: float, hill: float, xf: Transform3D) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = seed
	var fn := FastNoiseLite.new(); fn.seed = seed; fn.frequency = 0.008
	var top := PackedVector2Array()
	var x := length * 0.5
	while x > -length * 0.5:
		var edge := 1.0 - pow(absf(x) / (length * 0.5), 3.0)
		var hy := (hill * (0.55 + fn.get_noise_1d(x) * 0.6)) * edge
		var tree := rng.randf_range(1.5, 5.0) * edge
		top.append(Vector2(x, hy))
		top.append(Vector2(x - 1.4, hy + tree))
		x -= rng.randf_range(2.6, 5.0)
	var poly := PackedVector2Array([Vector2(-length * 0.5, -6.0), Vector2(length * 0.5, -6.0)])
	poly.append_array(top)
	k.push(xf)
	k.extrude("ridge", poly, 18.0)
	k.pop()

static func _horizon() -> void:
	FactoryMaterials._painterly("ridge", Color("2a3a3a"), "moss", 0.05, {"roughness": 1.0, "detail_strength": 0.3, "normal_strength": 0.0, "macro_strength": 0.0, "rim_strength": 0.0, "object_space": false})
	var k := MeshKit.new()
	# Mainland to the north and west at three depths, a few islets east.
	_ridge(k, 11, 520.0, 26.0, Transform3D(Basis(Vector3.UP, 0.12), Vector3(-60, 0, -410)))
	_ridge(k, 12, 300.0, 18.0, Transform3D(Basis(Vector3.UP, 0.9), Vector3(-330, 0, -230)))
	_ridge(k, 13, 240.0, 14.0, Transform3D(Basis(Vector3.UP, -0.35), Vector3(190, 0, -300)))
	_ridge(k, 14, 90.0, 9.0, Transform3D(Basis(Vector3.UP, 0.3), Vector3(-230, 0, 120)))
	_ridge(k, 15, 60.0, 7.0, Transform3D(Basis(Vector3.UP, -1.2), Vector3(260, 0, 60)))
	_ridge(k, 16, 45.0, 6.0, Transform3D(Basis(Vector3.UP, 0.7), Vector3(210, 0, 190)))
	var mesh := SceneUtil.kit_mesh(k, "horizon", false)
	var root := Node3D.new()
	root.name = "Horizon"
	var mi := SceneUtil.mesh_node(root, mesh, "Ridges", Transform3D.IDENTITY, false, "horizon")
	mi.extra_cull_margin = 50.0
	SceneUtil.save_scene(root, OUT + "Horizon.tscn")
