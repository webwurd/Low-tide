class_name Interiors extends Node3D
## Greybox interior rooms, built far from the island so they never share
## space with it. Arthur is teleported between rooms behind a short fade.
## Rooms: keeper's cottage, lighthouse watch room, lantern room.

const COTTAGE := Vector3(1000, 0, 0)
const WATCH := Vector3(1000, 0, 100)
const LANTERN := Vector3(1000, 0, 200)

var its: Dictionary = {}               # id -> Interactable
var spawn: Dictionary = {}             # place -> Vector3
var lamp_glow: OmniLight3D
var lamp_mesh: MeshInstance3D
var _mats := {}

func build() -> void:
	_build_cottage()
	_build_watch_room()
	_build_lantern_room()

# --- helpers -----------------------------------------------------------

func _mat(c: Color, emissive := false) -> StandardMaterial3D:
	var key := "%s%s" % [c.to_html(), emissive]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if emissive:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m

func _prop(pos: Vector3, size: Vector3, color: Color, collide := true, emissive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color, emissive)
	mi.position = pos
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		mi.add_child(body)
	return mi

func _room(origin: Vector3, size: Vector3, wall: Color, floor_c: Color) -> void:
	var h := size.y
	_prop(origin + Vector3(0, -0.1, 0), Vector3(size.x + 0.4, 0.2, size.z + 0.4), floor_c)
	_prop(origin + Vector3(0, h + 0.1, 0), Vector3(size.x + 0.4, 0.2, size.z + 0.4), wall.darkened(0.2))
	_prop(origin + Vector3(0, h / 2, -size.z / 2 - 0.1), Vector3(size.x + 0.4, h, 0.2), wall)
	_prop(origin + Vector3(0, h / 2, size.z / 2 + 0.1), Vector3(size.x + 0.4, h, 0.2), wall)
	_prop(origin + Vector3(-size.x / 2 - 0.1, h / 2, 0), Vector3(0.2, h, size.z), wall)
	_prop(origin + Vector3(size.x / 2 + 0.1, h / 2, 0), Vector3(0.2, h, size.z), wall)

func _light(pos: Vector3, color: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	add_child(l)
	return l

func _it(id: String, title: String, pos: Vector3, radius := 2.2, hold := 0.0) -> Interactable:
	var it := Interactable.new()
	it.id = id; it.title = title; it.radius = radius; it.hold_time = hold
	it.position = pos
	add_child(it)
	its[id] = it
	return it

# --- cottage (8 x 3 x 6; door on the +z wall) ---------------------------

func _build_cottage() -> void:
	var o := COTTAGE
	_room(o, Vector3(8, 3, 6), Color("6b5a48"), Color("4a3a2c"))
	spawn["cottage"] = o + Vector3(2.4, 0.05, 1.8)
	spawn["bed"] = o + Vector3(-1.9, 0.05, 0.9)
	# stove + glow
	_prop(o + Vector3(-3.3, 0.5, -2.3), Vector3(0.9, 1.0, 0.8), Color("22282e"))
	_prop(o + Vector3(-2.84, 0.45, -2.3), Vector3(0.04, 0.3, 0.5), Color("ff8a2a"), false, true)
	_light(o + Vector3(-2.6, 0.7, -2.2), Color("ff8a3a"), 0.9, 4.5)
	_it("stove", "Brew coffee on the stove", o + Vector3(-2.7, 1.0, -1.7))
	# tide table + barometer on the back wall
	_prop(o + Vector3(-1.2, 1.6, -2.96), Vector3(0.7, 0.9, 0.04), Color("e8dfc8"), false)
	_it("tide_table", "Read the tide table", o + Vector3(-1.2, 1.4, -2.2))
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22; cm.bottom_radius = 0.22; cm.height = 0.06
	disc.mesh = cm
	disc.material_override = _mat(Color("b89f72"))
	disc.rotation.x = PI / 2.0
	disc.position = o + Vector3(0.7, 1.7, -2.95)
	add_child(disc)
	_it("barometer", "Check the barometer", o + Vector3(0.7, 1.5, -2.2))
	# radio desk
	_prop(o + Vector3(2.7, 0.4, -2.4), Vector3(1.6, 0.8, 0.8), Color("5c4938"))
	_prop(o + Vector3(2.7, 0.95, -2.5), Vector3(0.6, 0.3, 0.3), Color("2b3138"), false)
	_it("radio_desk", "Radio", o + Vector3(2.7, 1.1, -1.8), 2.4)
	# log desk
	_prop(o + Vector3(3.5, 0.4, 0.4), Vector3(0.8, 0.8, 1.2), Color("5c4938"))
	_prop(o + Vector3(3.5, 0.84, 0.4), Vector3(0.5, 0.04, 0.7), Color("e8dfc8"), false)
	_it("log_desk", "Write in the log", o + Vector3(2.9, 1.1, 0.4))
	# armchair (wait anchor)
	_prop(o + Vector3(-2.4, 0.3, 1.6), Vector3(0.9, 0.6, 0.9), Color("7a3b32"))
	_prop(o + Vector3(-2.4, 0.8, 1.95), Vector3(0.9, 0.7, 0.2), Color("7a3b32"), false)
	_it("chair_cottage", "Sit and wait", o + Vector3(-1.8, 1.0, 1.6))
	# bed
	_prop(o + Vector3(-3.0, 0.3, 0.0), Vector3(1.8, 0.6, 1.0), Color("3f5163"))
	_it("bed", "Go to bed", o + Vector3(-2.2, 1.0, -0.6))
	# shelf with the old university logbooks (left wall)
	_prop(o + Vector3(-3.8, 0.9, 2.4), Vector3(0.4, 1.8, 1.0), Color("5c4938"))
	_prop(o + Vector3(-3.58, 1.3, 2.4), Vector3(0.05, 0.3, 0.8), Color("b89f72"), false)
	var shelf := _it("shelf_logs", "Take the old university logbooks", o + Vector3(-3.0, 1.3, 2.4), 1.8)
	shelf.give_item = "uni_logs"
	shelf.visible_fn = func(): return not GameState.has_item("uni_logs")
	# cassette player on a side table
	_prop(o + Vector3(-0.8, 0.4, 2.3), Vector3(0.8, 0.8, 0.6), Color("5c4938"))
	_prop(o + Vector3(-0.8, 0.88, 2.3), Vector3(0.4, 0.16, 0.25), Color("2b3138"), false)
	_it("cassette_player", "Cassette player", o + Vector3(-0.8, 1.1, 1.8), 1.8)
	# door
	_prop(o + Vector3(2.4, 1.05, 3.0), Vector3(1.1, 2.1, 0.1), Color("5c4938"), false)
	_it("door_cottage_out", "Step outside", o + Vector3(2.4, 1.1, 2.2))
	_light(o + Vector3(0, 2.5, 0), Color("ffc27a"), 1.3, 9.0)

# --- lighthouse watch room (5 x 3 x 5; door on +z) -----------------------

func _build_watch_room() -> void:
	var o := WATCH
	_room(o, Vector3(5, 3, 5), Color("8a9096"), Color("4b5359"))
	spawn["tower_base"] = o + Vector3(0, 0.05, 1.5)
	spawn["from_above"] = o + Vector3(1.5, 0.05, -0.2)
	_prop(o + Vector3(-1.7, 1.0, -1.7), Vector3(0.9, 2.0, 0.9), Color("22282e"))
	_prop(o + Vector3(-1.7, 1.0, -1.2), Vector3(0.5, 0.3, 0.1), Color("d4a446"), false)
	_it("weights", "Wind the clockwork weights", o + Vector3(-1.6, 1.2, -0.9), 2.4, 3.0)
	for i in 5:
		_prop(o + Vector3(1.7, 0.15 + i * 0.3, -1.5 + i * 0.2), Vector3(1.0, 0.3, 0.9), Color("6b747c"))
	_it("stairs_up", "Climb to the lantern room", o + Vector3(1.4, 1.0, -0.6), 2.2)
	_prop(o + Vector3(0, 1.0, 2.5), Vector3(1.2, 2.0, 0.1), Color("8f2d2d"), false)
	_it("door_tower_out", "Leave the lighthouse", o + Vector3(0, 1.1, 1.8))
	_light(o + Vector3(0, 2.6, 0), Color("ffb066"), 1.0, 8.0)

# --- lantern room (4 x 2.6 x 4) ------------------------------------------

func _build_lantern_room() -> void:
	var o := LANTERN
	_room(o, Vector3(4, 2.6, 4), Color("5b6670"), Color("33393f"))
	spawn["tower_top"] = o + Vector3(1.2, 0.05, 1.2)
	lamp_mesh = _prop(o + Vector3(0, 1.1, 0), Vector3(0.7, 1.2, 0.7), Color("3a342c"), true)
	_prop(o + Vector3(0, 0.25, 0), Vector3(0.9, 0.5, 0.9), Color("22282e"))
	lamp_glow = _light(o + Vector3(0, 1.3, 0), Color("ffc060"), 0.0, 8.0)
	_it("lamp", "Light the lamp", o + Vector3(0.0, 1.2, 0.9), 2.2, 2.0)
	_prop(o + Vector3(-1.5, 0.25, 1.2), Vector3(0.4, 0.5, 1.2), Color("5c4938"))
	_it("bench", "Sit and wait", o + Vector3(-1.0, 0.9, 1.2))
	for sx in [-1, 1]:
		_prop(o + Vector3(sx * 1.99, 1.4, -0.4), Vector3(0.04, 0.8, 1.2), Color("2b4156"), false, true)
	_it("stairs_down", "Go down the stairs", o + Vector3(1.4, 1.0, 1.6), 2.0)

## Called by Main when the lamp state changes.
func set_lamp(lit: bool) -> void:
	lamp_glow.light_energy = 2.6 if lit else 0.0
	lamp_mesh.material_override = _mat(Color("ffd27d"), true) if lit else _mat(Color("3a342c"))
