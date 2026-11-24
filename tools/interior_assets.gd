class_name InteriorAssets
## The three interiors as scenes (res://scenes/interiors/). Each scene's
## origin is the room's floor centre; Interiors places them far from the
## island. Interactable ids, positions and radii, spawn points and furniture
## colliders match the M3 greybox (tests and Main rely on them).

const OUT := "res://scenes/interiors/"

static func build_all(_tree: SceneTree) -> void:
	var wv := ShaderMaterial.new()
	wv.shader = load("res://art/window_view.gdshader")
	ResourceSaver.save(wv, "res://assets/materials/window_view.tres")
	wv.take_over_path("res://assets/materials/window_view.tres")
	_cottage()
	_watch_room()
	_lantern_room()

static func _m(name: String) -> Mesh:
	return load(SceneUtil.MODELS + name + ".res")

static func _place(root: Node, model: String, pos: Vector3, yaw := 0.0, node_name := "") -> MeshInstance3D:
	return SceneUtil.mesh_node(root, _m(model), node_name if node_name != "" else model.capitalize().replace(" ", ""),
		Transform3D(Basis(Vector3.UP, yaw), pos), true, model)

static func _light(root: Node, name: String, pos: Vector3, color: Color, energy: float, rng: float, shadows := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = name
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadows
	l.shadow_blur = 1.5
	l.light_volumetric_fog_energy = 0.6
	l.position = pos
	root.add_child(l)
	return l

## Cool daylight through a window: a soft spot aimed into the room. Interiors
## scales its energy with the time of day (group "window_light").
static func _window_light(root: Node, name: String, pos: Vector3, aim: Vector3) -> void:
	var s := SpotLight3D.new()
	s.name = name
	s.light_color = Color("b9cde0")
	s.light_energy = 2.0
	s.spot_range = 8.0
	s.spot_angle = 38.0
	s.spot_angle_attenuation = 1.3
	s.shadow_enabled = true
	s.light_volumetric_fog_energy = 2.0
	s.position = pos
	root.add_child(s)
	s.look_at_from_position(pos, aim, Vector3.UP)
	s.add_to_group("window_light", true)

## Flat room shell: plank floor, wainscot + plaster walls, beamed ceiling.
static func _shell(k: MeshKit, size: Vector3, wall := "plaster", floor_mat := "wood_floor", wainscot := true) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = int(size.x * 100 + size.z)
	var hx := size.x * 0.5; var hz := size.z * 0.5; var h := size.y
	var x := -hx
	while x < hx - 0.01:
		var w := minf(0.2, hx - x)
		k.tint = Color(1, 1, 1) * rng.randf_range(0.85, 1.1)
		k.box(floor_mat, Vector3(w - 0.006, 0.06, size.z), Vector3(x + w * 0.5, -0.03, 0), 0.006)
		x += w
	k.tint = Color(1, 1, 1)
	k.box("plaster", Vector3(size.x, 0.06, size.z), Vector3(0, h + 0.03, 0), 0.0)
	for side in [[Vector3(0, h * 0.5, -hz - 0.05), Vector3(size.x, h, 0.1)], [Vector3(0, h * 0.5, hz + 0.05), Vector3(size.x, h, 0.1)],
			[Vector3(-hx - 0.05, h * 0.5, 0), Vector3(0.1, h, size.z)], [Vector3(hx + 0.05, h * 0.5, 0), Vector3(0.1, h, size.z)]]:
		k.box(wall, side[1], side[0], 0.0)
	if wainscot:
		for side in [[Vector3(0, 0.5, -hz + 0.01), Vector3(size.x, 1.0, 0.04)], [Vector3(0, 0.5, hz - 0.01), Vector3(size.x, 1.0, 0.04)],
				[Vector3(-hx + 0.01, 0.5, 0), Vector3(0.04, 1.0, size.z)], [Vector3(hx - 0.01, 0.5, 0), Vector3(0.04, 1.0, size.z)]]:
			k.box("wainscot", side[1], side[0], 0.005)
		for side in [[Vector3(0, 1.02, -hz + 0.03), Vector3(size.x, 0.05, 0.06)], [Vector3(0, 1.02, hz - 0.03), Vector3(size.x, 0.05, 0.06)],
				[Vector3(-hx + 0.03, 1.02, 0), Vector3(0.06, 0.05, size.z)], [Vector3(hx - 0.03, 1.02, 0), Vector3(0.06, 0.05, size.z)]]:
			k.box("wood_warm", side[1], side[0], 0.01)
	var bx := -hx + 0.6
	while bx < hx:
		k.box("wood_beam", Vector3(0.16, 0.2, size.z), Vector3(bx, h - 0.1, 0), 0.02)
		bx += 1.3

## Interior window: frame + painted outside view. Faces +Z at the origin.
static func _window(k: MeshKit, w: float, h: float) -> void:
	k.box("trim_white", Vector3(w + 0.22, h + 0.22, 0.12), Vector3.ZERO, 0.02)
	k.quad("window_view", Vector3(-w * 0.5, -h * 0.5, 0.065), Vector3(w * 0.5, -h * 0.5, 0.065), Vector3(w * 0.5, h * 0.5, 0.065), Vector3(-w * 0.5, h * 0.5, 0.065))
	k.box("glass", Vector3(w, h, 0.01), Vector3(0, 0, 0.075), 0.0)
	k.box("trim_white", Vector3(0.045, h, 0.04), Vector3(0, 0, 0.09), 0.01)
	k.box("trim_white", Vector3(w, 0.045, 0.04), Vector3(0, 0, 0.09), 0.01)
	k.box("trim_white", Vector3(w + 0.36, 0.06, 0.2), Vector3(0, -h * 0.5 - 0.12, 0.1), 0.015)

static func _walls_body(root: Node, size: Vector3) -> void:
	var hx := size.x * 0.5; var hz := size.z * 0.5; var h := size.y
	SceneUtil.body(root, "Walls", [
		[SceneUtil.box_shape(Vector3(size.x + 0.4, 0.2, size.z + 0.4)), Transform3D(Basis(), Vector3(0, -0.1, 0))],
		[SceneUtil.box_shape(Vector3(size.x + 0.4, 0.2, size.z + 0.4)), Transform3D(Basis(), Vector3(0, h + 0.1, 0))],
		[SceneUtil.box_shape(Vector3(size.x + 0.4, h, 0.2)), Transform3D(Basis(), Vector3(0, h / 2, -hz - 0.1))],
		[SceneUtil.box_shape(Vector3(size.x + 0.4, h, 0.2)), Transform3D(Basis(), Vector3(0, h / 2, hz + 0.1))],
		[SceneUtil.box_shape(Vector3(0.2, h, size.z)), Transform3D(Basis(), Vector3(-hx - 0.1, h / 2, 0))],
		[SceneUtil.box_shape(Vector3(0.2, h, size.z)), Transform3D(Basis(), Vector3(hx + 0.1, h / 2, 0))]])

static func _it(root: Node, id: String, title: String, pos: Vector3, radius := 2.2, hold := 0.0, glow: Array = []) -> void:
	var it := SceneUtil.interactable(root, "It_" + id, id, title, pos, radius, "", hold)
	var paths: Array[NodePath] = []
	for g in glow:
		paths.append(it.get_path_to(g))
	it.highlight_paths = paths

# --- keeper's cottage (8 x 3 x 6; door on +Z) ------------------------------------------

static func _cottage() -> void:
	var size := Vector3(8, 3, 6)
	var k := MeshKit.new()
	_shell(k, size)
	for wpos in [[Vector3(-1.6, 1.65, 2.94), PI], [Vector3(-3.94, 1.65, -1.2), PI / 2.0], [Vector3(3.94, 1.65, 1.9), -PI / 2.0]]:
		k.push(Transform3D(Basis(Vector3.UP, wpos[1]), wpos[0]))
		_window(k, 0.9, 1.1)
		k.pop()
	# Curtains either side of the front window, a shelf of mugs above the stove.
	var room := SceneUtil.kit_mesh(k, "cottage_room", false)
	var root := Node3D.new()
	root.name = "CottageInterior"
	SceneUtil.mesh_node(root, room, "Room", Transform3D.IDENTITY, true, "cottage_room")
	_walls_body(root, size)
	SceneUtil.marker(root, "Spawn_cottage", Vector3(2.4, 0.05, 1.8))
	SceneUtil.marker(root, "Spawn_bed", Vector3(-1.9, 0.05, 0.9))
	var stove := _place(root, "stove", Vector3(-3.3, 0.0, -2.35), 0.0, "Stove")
	var tide := _place(root, "tide_table", Vector3(-1.2, 1.6, -2.96), 0.0, "TideTable")
	var baro := _place(root, "barometer", Vector3(0.7, 1.6, -2.96), 0.0, "Barometer")
	var desk := _place(root, "desk", Vector3(2.7, 0.0, -2.58), 0.0, "RadioDesk")
	var radio := _place(root, "radio", Vector3(2.55, 0.785, -2.68), 0.0, "Radio")
	var logdesk := _place(root, "desk", Vector3(3.58, 0.0, 0.4), -PI / 2.0, "LogDesk")
	var book := _place(root, "logbook", Vector3(3.5, 0.785, 0.4), -PI / 2.0, "Logbook")
	var chair := _place(root, "armchair", Vector3(-2.4, 0.0, 1.6), PI, "Armchair")
	var bed := _place(root, "bed", Vector3(-3.0, 0.0, 0.0), 0.0, "Bed")
	var door := _place(root, "door", Vector3(2.4, 0.0, 2.97), PI, "Door")
	_place(root, "rug", Vector3(0.3, 0.0, 0.6), 0.1, "Rug")
	_place(root, "table", Vector3(0.4, 0.0, 0.5), 0.05, "Table")
	_place(root, "chair", Vector3(0.4, 0.0, 1.2), PI + 0.15, "ChairA")
	_place(root, "chair", Vector3(-0.45, 0.0, 0.35), PI / 2.0 + 0.3, "ChairB")
	_place(root, "mug", Vector3(0.55, 0.765, 0.4), 0.7, "Mug")
	_place(root, "hand_lantern", Vector3(0.15, 0.765, 0.65), 0.0, "HandLantern")
	_place(root, "shelf_books", Vector3(-0.2, 1.75, -2.98), 0.0, "Shelf")
	_place(root, "shelf_books", Vector3(-3.97, 1.95, 1.3), PI / 2.0, "ShelfSide")
	_place(root, "oilskin", Vector3(1.4, 1.8, 2.98), PI, "Oilskin")
	_place(root, "crate", Vector3(-3.55, 0.0, -1.45), 0.2, "Woodbox")
	_place(root, "curtain", Vector3(-2.15, 2.35, 2.9), PI, "CurtainL")
	_place(root, "curtain", Vector3(-1.05, 2.35, 2.9), PI, "CurtainR")
	_place(root, "mug", Vector3(-0.55, 1.79, -2.88), 0.3, "ShelfMug")
	SceneUtil.body(root, "Furniture", [
		[SceneUtil.box_shape(Vector3(0.9, 1.0, 0.8)), Transform3D(Basis(), Vector3(-3.3, 0.5, -2.3))],
		[SceneUtil.box_shape(Vector3(1.6, 0.8, 0.8)), Transform3D(Basis(), Vector3(2.7, 0.4, -2.4))],
		[SceneUtil.box_shape(Vector3(0.8, 0.8, 1.2)), Transform3D(Basis(), Vector3(3.5, 0.4, 0.4))],
		[SceneUtil.box_shape(Vector3(0.9, 0.6, 0.9)), Transform3D(Basis(), Vector3(-2.4, 0.3, 1.6))],
		[SceneUtil.box_shape(Vector3(1.8, 0.6, 1.0)), Transform3D(Basis(), Vector3(-3.0, 0.3, 0.0))],
		[SceneUtil.box_shape(Vector3(1.1, 0.78, 0.75)), Transform3D(Basis(), Vector3(0.4, 0.39, 0.5))]])
	_it(root, "stove", "Brew coffee on the stove", Vector3(-2.7, 1.0, -1.7), 2.2, 0.0, [stove])
	_it(root, "tide_table", "Read the tide table", Vector3(-1.2, 1.4, -2.2), 2.2, 0.0, [tide])
	_it(root, "barometer", "Check the barometer", Vector3(0.7, 1.5, -2.2), 2.2, 0.0, [baro])
	_it(root, "radio_desk", "Radio", Vector3(2.7, 1.1, -1.8), 2.4, 0.0, [radio])
	_it(root, "log_desk", "Write in the log", Vector3(2.9, 1.1, 0.4), 2.2, 0.0, [book])
	_it(root, "chair_cottage", "Sit and wait", Vector3(-1.8, 1.0, 1.6), 2.2, 0.0, [chair])
	_it(root, "bed", "Go to bed", Vector3(-2.2, 1.0, -0.6), 2.2, 0.0, [bed])
	_it(root, "door_cottage_out", "Step outside", Vector3(2.4, 1.1, 2.2), 2.2, 0.0, [door])
	_light(root, "StoveGlow", Vector3(-3.0, 0.65, -1.85), Color("ff8a3a"), 1.4, 4.5)
	_light(root, "Ceiling", Vector3(0.4, 2.45, 0.5), Color("ffc27a"), 1.1, 9.0)
	_light(root, "DeskLamp", Vector3(3.08, 1.1, 0.82), Color("ffbd6a"), 0.7, 3.5, false)
	_light(root, "RadioDial", Vector3(2.45, 1.05, -2.3), Color("ffb84d"), 0.25, 1.6, false)
	_window_light(root, "WindowFront", Vector3(-1.6, 2.4, 3.5), Vector3(-0.6, 0.0, 0.2))
	_window_light(root, "WindowWest", Vector3(-4.5, 2.4, -1.2), Vector3(-2.0, 0.0, -0.8))
	SceneUtil.save_scene(root, OUT + "Cottage.tscn")

# --- lighthouse watch room (round, r 2.55; door on +Z) ------------------------------------

static func _round_walls_body(root: Node, r: float, h: float) -> void:
	var shapes := [[SceneUtil.box_shape(Vector3(r * 2 + 1, 0.2, r * 2 + 1)), Transform3D(Basis(), Vector3(0, -0.1, 0))],
		[SceneUtil.box_shape(Vector3(r * 2 + 1, 0.2, r * 2 + 1)), Transform3D(Basis(), Vector3(0, h + 0.1, 0))]]
	for i in 16:
		var a := TAU * i / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		shapes.append([SceneUtil.box_shape(Vector3(0.3, h, r * 0.45)), Transform3D(Basis(Vector3.UP, -a), d * (r + 0.12) + Vector3(0, h / 2, 0))])
	SceneUtil.body(root, "Walls", shapes)

static func _watch_room() -> void:
	var r := 2.55
	var h := 3.0
	var k := MeshKit.new()
	# Curved whitewashed stone wall (inward-facing), granite floor, beams.
	k.lathe("whitewash", PackedVector2Array([Vector2(r + 0.02, h), Vector2(r + 0.02, 0.0)]), 40)
	k.push(Transform3D(Basis(), Vector3(0, -0.06, 0)))
	k.cylinder("stone_floor", r + 0.1, r + 0.1, 0.06, 40)
	k.pop()
	k.cylinder("plaster", r + 0.1, r + 0.1, 0.06, 40, h)
	for bz in [-1.2, 0.0, 1.2]:
		k.box("wood_beam", Vector3(r * 2.0 * sqrt(maxf(0.0, 1.0 - pow(bz / r, 2.0))), 0.2, 0.16), Vector3(0, h - 0.1, bz), 0.02)
	k.box("granite", Vector3(1.5, 2.4, 0.14), Vector3(0, 1.2, r - 0.08), 0.03)
	k.push(Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(-r * 0.68, 1.75, -r * 0.68)))
	k.push(Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO))
	_window(k, 0.45, 0.8)
	k.pop()
	k.pop()
	var room := SceneUtil.kit_mesh(k, "watch_room", false)
	var root := Node3D.new()
	root.name = "WatchRoom"
	SceneUtil.mesh_node(root, room, "Room", Transform3D.IDENTITY, true, "watch_room")
	_round_walls_body(root, r, h)
	SceneUtil.marker(root, "Spawn_tower_base", Vector3(0, 0.05, 1.5))
	SceneUtil.marker(root, "Spawn_from_above", Vector3(1.5, 0.05, -0.2))
	var weights := _place(root, "clock_weights", Vector3(-1.3, 0.0, -1.3), PI * 0.25, "ClockWeights")
	var stair := _place(root, "spiral_stair", Vector3(1.2, 0.0, -1.0), 0.0, "SpiralStair")
	var door := _place(root, "door", Vector3(0.0, 0.0, r - 0.16), PI, "Door")
	door.scale = Vector3(1.1, 1.05, 1.0)
	_place(root, "oil_can", Vector3(-1.9, 0.0, 0.6), 0.4, "OilCanA")
	_place(root, "oil_can", Vector3(-1.75, 0.0, 0.95), 1.4, "OilCanB")
	_place(root, "crate", Vector3(-1.6, 0.0, 1.45), 0.9, "Crate")
	_place(root, "oilskin", Vector3(1.55, 1.75, 1.95), PI + 0.65, "Oilskin")
	_place(root, "hand_lantern", Vector3(-1.6, 0.41, 1.45), 0.3, "HandLantern")
	SceneUtil.body(root, "Furniture", [
		[SceneUtil.box_shape(Vector3(0.95, 2.2, 0.95)), Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(-1.3, 1.1, -1.3))],
		[CylinderShape3D.new(), Transform3D(Basis(), Vector3(1.2, 1.0, -1.0))]])
	_it(root, "weights", "Wind the clockwork weights", Vector3(-1.6, 1.2, -0.9), 2.4, 3.0, [weights])
	_it(root, "stairs_up", "Climb to the lantern room", Vector3(1.4, 1.0, -0.6), 2.2, 0.0, [stair])
	_it(root, "door_tower_out", "Leave the lighthouse", Vector3(0, 1.1, 1.8), 2.2, 0.0, [door])
	_light(root, "WallLamp", Vector3(0.0, 2.3, -2.2), Color("ffb066"), 1.2, 7.5)
	_light(root, "Fill", Vector3(0.0, 1.6, 0.8), Color("e0c09a"), 0.25, 5.0, false)
	_window_light(root, "Window", Vector3(-2.4, 2.6, -2.4), Vector3(-0.2, 0.0, 0.2))
	SceneUtil.save_scene(root, OUT + "WatchRoom.tscn")

# --- lantern room (glazed, r 2.3) --------------------------------------------------------

static func _lantern_room() -> void:
	var r := 2.3
	var k := MeshKit.new()
	k.push(Transform3D(Basis(), Vector3(0, -0.06, 0)))
	k.cylinder("iron", r + 0.1, r + 0.1, 0.06, 24)
	k.pop()
	k.lathe("iron", PackedVector2Array([Vector2(r, 0.9), Vector2(r, 0.0)]), 16, false, false, false, PI / 16.0)
	k.lathe("window_view", PackedVector2Array([Vector2(r + 0.06, 2.35), Vector2(r + 0.06, 0.9)]), 16, false, false, false, PI / 16.0)
	for i in 16:
		var a := TAU * i / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		k.push(Transform3D(Basis(Vector3.UP, -a + PI / 2.0), d * (r - 0.02) + Vector3(0, 1.62, 0)))
		k.box("iron", Vector3(0.08, 1.5, 0.08), Vector3.ZERO, 0.015)
		k.pop()
	for ry in [0.9, 1.62, 2.35]:
		var ring := PackedVector3Array()
		for i in 17:
			var a := TAU * i / 16.0 + PI / 16.0
			ring.append(Vector3(cos(a) * (r - 0.03), ry, sin(a) * (r - 0.03)))
		k.tube("iron", ring, 0.04, 5)
	# Profile runs top-down so the roof faces into the room.
	k.lathe("keeper_red", PackedVector2Array([Vector2(0.0, 3.25), Vector2(1.2, 3.0), Vector2(r + 0.05, 2.38)]), 24, true)
	var room := SceneUtil.kit_mesh(k, "lantern_room", false)
	var root := Node3D.new()
	root.name = "LanternRoom"
	SceneUtil.mesh_node(root, room, "Room", Transform3D.IDENTITY, true, "lantern_room")
	_round_walls_body(root, r, 2.6)
	SceneUtil.marker(root, "Spawn_tower_top", Vector3(1.2, 0.05, 1.2))
	var lens := _place(root, "lantern_lens", Vector3(0.0, 0.0, 0.0), 0.0, "Lens")
	var burner := _place(root, "lantern_burner", Vector3(0.0, 0.0, 0.0), 0.0, "Burner")
	var bench := _place(root, "bench", Vector3(-1.45, 0.0, 1.0), -0.6, "Bench")
	var hatch := _place(root, "floor_hatch", Vector3(1.25, 0.0, 1.35), 0.4, "Hatch")
	_place(root, "oil_can", Vector3(0.9, 0.0, -1.5), 2.0, "OilCan")
	_place(root, "hand_lantern", Vector3(-1.5, 0.49, 0.75), 0.2, "HandLantern")
	SceneUtil.body(root, "Furniture", [
		[SceneUtil.box_shape(Vector3(0.9, 1.7, 0.9)), Transform3D(Basis(), Vector3(0, 0.85, 0))],
		[SceneUtil.box_shape(Vector3(0.42, 0.5, 1.3)), Transform3D(Basis(Vector3.UP, -0.6), Vector3(-1.45, 0.25, 1.0))]])
	_it(root, "lamp", "Light the lamp", Vector3(0.0, 1.2, 0.9), 2.2, 2.0, [lens, burner])
	_it(root, "bench", "Sit and wait", Vector3(-1.0, 0.9, 1.2), 2.2, 0.0, [bench])
	_it(root, "stairs_down", "Go down the stairs", Vector3(1.4, 1.0, 1.6), 2.0, 0.0, [hatch])
	var glow := _light(root, "LampGlow", Vector3(0, 1.3, 0), Color("ffc060"), 0.0, 8.0)
	glow.shadow_enabled = true
	var day := OmniLight3D.new()
	day.name = "Daylight"
	day.light_color = Color("b9cde0")
	day.light_energy = 0.8
	day.omni_range = 6.0
	day.position = Vector3(0, 2.2, 0)
	day.add_to_group("window_light", true)
	root.add_child(day)
	SceneUtil.save_scene(root, OUT + "LanternRoom.tscn")
