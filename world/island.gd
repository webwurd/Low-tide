class_name Island extends Node3D
## Builds Gannet Rock greybox: terrain, lighthouse, cottage, pier, wreck stack,
## echo-cave arch, rocks. Everything is generated in code for M2; hand-sculpted
## scenes replace it in later milestones.

const PILING_MARK_COLOR := Color("e8dfc8")

var beam_pivot: Node3D
var beam_arms: Array[Node3D] = []
var beam_mat: StandardMaterial3D
var lantern_mat: StandardMaterial3D
var lamp_light: OmniLight3D
var beam_spinning := false
var cottage_door: Interactable
var tower_door: Interactable
var spawn_point := Vector3(0.0, Terrain.PIER_TOP + 0.05, 24.0)
var _mats := {}

func build() -> void:
	_build_terrain()
	_build_lighthouse()
	_build_cottage()
	_build_pier()
	_build_wreck()
	_build_cave()
	_build_rocks()

func _process(delta: float) -> void:
	if beam_pivot and beam_spinning:
		beam_pivot.rotation.y += delta * 0.48

# --- helpers -----------------------------------------------------------

## Where Arthur stands (feet) when he steps out of the cottage door.
func cottage_exit() -> Vector3:
	var local := Vector3(0, 0, 3.8).rotated(Vector3.UP, Terrain.COTTAGE_YAW)
	return Vector3(Terrain.COTTAGE_POS.x + local.x, Terrain.COTTAGE_Y + 0.05, Terrain.COTTAGE_POS.y + local.z)

func tower_exit() -> Vector3:
	return Vector3(0, 10.25, -0.9)

## Lamp lit + weights wound = lens turns and the beam sweeps. `daylight` 0..1
## makes the beam stronger at night.
func set_lamp(lit: bool, wound: bool, daylight: float) -> void:
	beam_spinning = lit and wound
	for a in beam_arms:
		a.visible = lit
	beam_mat.albedo_color.a = lerpf(0.26, 0.07, daylight)
	lantern_mat.albedo_color = Color("ffd27d") if lit else Color("2a2f33")
	lamp_light.light_energy = 2.2 if lit else 0.0

func _mat(color: Color, rough := 0.85, metal := 0.0, unshaded := false) -> StandardMaterial3D:
	var key := "%s_%s_%s_%s" % [color.to_html(), rough, metal, unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m

func _mesh(parent: Node, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _cyl(top: float, bottom: float, h: float, sides := 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top; c.bottom_radius = bottom; c.height = h
	c.radial_segments = sides; c.rings = 1
	return c

func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new(); b.size = size; return b

func _solid(parent: Node, shape: Shape3D, pos: Vector3, rot := Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	body.position = pos
	body.rotation = rot
	parent.add_child(body)

func _box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new(); s.size = size; return s

func _bino_target(label: String, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	n.set_meta("label", label)
	n.add_to_group("bino_target")
	add_child(n)

func _interactable(id: String, title: String, pos: Vector3, radius: float, conv: String) -> Interactable:
	var it := Interactable.new()
	it.id = id; it.title = title; it.radius = radius; it.conversation = conv
	it.position = pos
	add_child(it)
	return it

# --- terrain -----------------------------------------------------------

func _build_terrain() -> void:
	var mesh := Terrain.build_mesh()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.88
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)
	add_child(body)

# --- lighthouse --------------------------------------------------------

func _build_lighthouse() -> void:
	var g := Node3D.new()
	g.position = Vector3(0, 10.1, -6)
	add_child(g)
	var stone := _mat(Color("d9dde0"), 0.75)
	var red := _mat(Color("8f2d2d"), 0.65)
	var iron := _mat(Color("22282e"), 0.45, 0.6)
	_mesh(g, _cyl(3.4, 4.0, 3.0), _mat(Color("4b5359"), 0.9), Vector3(0, 1.5, 0))
	_mesh(g, _cyl(2.2, 3.3, 15.0), stone, Vector3(0, 10.5, 0))
	_mesh(g, _cyl(2.68, 2.95, 3.5), red, Vector3(0, 11.0, 0))
	_mesh(g, _cyl(3.0, 3.0, 0.5, 16), iron, Vector3(0, 18.2, 0))
	lantern_mat = StandardMaterial3D.new()
	lantern_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lantern_mat.albedo_color = Color("2a2f33")
	_mesh(g, _cyl(1.75, 1.75, 2.8), lantern_mat, Vector3(0, 19.8, 0))
	var roof := CylinderMesh.new()
	roof.top_radius = 0.0; roof.bottom_radius = 2.2; roof.height = 2.0; roof.radial_segments = 12
	_mesh(g, roof, red, Vector3(0, 22.1, 0))
	_mesh(g, _box(Vector3(1.3, 2.3, 0.4)), red, Vector3(0, 1.2, 3.75))
	var lh_shape := CylinderShape3D.new()
	lh_shape.radius = 3.7
	lh_shape.height = 16.0
	_solid(g, lh_shape, Vector3(0, 5, 0))

	beam_pivot = Node3D.new()
	beam_pivot.position = Vector3(0, 19.8, 0)
	g.add_child(beam_pivot)
	var cone := _cyl(14.0, 0.5, 95.0, 24)
	beam_mat = StandardMaterial3D.new()
	beam_mat.albedo_color = Color(1.0, 0.81, 0.44, 0.13)
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for rot_y in [0.0, PI]:
		var arm := Node3D.new()
		arm.rotation.y = rot_y
		beam_pivot.add_child(arm)
		beam_arms.append(arm)
		var m := _mesh(arm, cone, beam_mat, Vector3(0, 0, 47.5), Vector3(PI / 2.0, 0, 0))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamp_light = OmniLight3D.new()
	lamp_light.light_color = Color("ffb84d")
	lamp_light.light_energy = 0.0
	lamp_light.omni_range = 45.0
	beam_pivot.add_child(lamp_light)
	set_lamp(false, false, 1.0)

	tower_door = _interactable("lighthouse", "Enter the lighthouse", Vector3(0, 11.3, -1.2), 3.2, "lighthouse")
	_bino_target("GANNET ROCK LIGHTHOUSE (1884)", Vector3(0, 30, -6))

# --- cottage -----------------------------------------------------------

func _build_cottage() -> void:
	var g := Node3D.new()
	g.position = Vector3(Terrain.COTTAGE_POS.x, Terrain.COTTAGE_Y, Terrain.COTTAGE_POS.y)
	g.rotation.y = Terrain.COTTAGE_YAW
	add_child(g)
	_mesh(g, _box(Vector3(6.5, 3.6, 5.0)), _mat(Color("575e63"), 0.9), Vector3(0, 1.8, 0))
	var roof := CylinderMesh.new()
	roof.top_radius = 0.0; roof.bottom_radius = 5.2; roof.height = 2.4
	roof.radial_segments = 4
	_mesh(g, roof, _mat(Color("8f2d2d"), 0.65), Vector3(0, 4.8, 0), Vector3(0, PI / 4.0, 0))
	_mesh(g, _box(Vector3(0.9, 2.4, 0.9)), _mat(Color("22282e"), 0.45, 0.6), Vector3(1.8, 5.0, -0.8))
	var glow := _mat(Color("ffb84d"), 0.5, 0.0, true)
	for wx in [-1.5, 1.5]:
		var q := QuadMesh.new(); q.size = Vector2(1.1, 1.1)
		_mesh(g, q, glow, Vector3(wx, 2.0, 2.52))
	_mesh(g, _box(Vector3(1.1, 2.1, 0.2)), _mat(Color("5c4938"), 0.9), Vector3(0, 1.05, 2.52))
	var light := OmniLight3D.new()
	light.light_color = Color("ffaa3b"); light.light_energy = 1.6; light.omni_range = 16.0
	light.position = Vector3(0, 2.5, 3.5)
	g.add_child(light)
	_solid(g, _box_shape(Vector3(6.5, 3.6, 5.0)), Vector3(0, 1.8, 0))
	cottage_door = _interactable("cottage", "Enter the cottage", cottage_exit() + Vector3(0, 1.2, 0), 2.6, "cottage")

# --- pier (spawn + safe high ground) ----------------------------------

func _build_pier() -> void:
	var wood := _mat(Color("5c4938"), 0.9)
	var length := Terrain.PIER_Z1 - Terrain.PIER_Z0
	var cz := (Terrain.PIER_Z0 + Terrain.PIER_Z1) / 2.0
	var deck_h := 0.35
	var cy := Terrain.PIER_TOP - deck_h / 2.0
	var deck_size := Vector3(Terrain.PIER_X * 2.0, deck_h, length)
	_mesh(self, _box(deck_size), wood, Vector3(0, cy, cz))
	_solid(self, _box_shape(deck_size), Vector3(0, cy, cz))
	# Rails (collision keeps Arthur from stepping off the side by accident)
	for side in [-1.0, 1.0]:
		var rail := Vector3(0.12, 0.9, length)
		_mesh(self, _box(rail), wood, Vector3(side * (Terrain.PIER_X - 0.06), Terrain.PIER_TOP + 0.45, cz))
		_solid(self, _box_shape(Vector3(0.3, 1.4, length)), Vector3(side * Terrain.PIER_X, Terrain.PIER_TOP + 0.7, cz))
	_solid(self, _box_shape(Vector3(Terrain.PIER_X * 2.0, 1.4, 0.3)), Vector3(0, Terrain.PIER_TOP + 0.7, Terrain.PIER_Z1))
	# Pilings with painted tide marks (every 0.5m; numeral at each metre).
	var z := Terrain.PIER_Z0 + 3.0
	var first := true
	while z <= Terrain.PIER_Z1:
		for px in [-1.6, 1.6]:
			_mesh(self, _cyl(0.22, 0.25, 9.0, 8), wood, Vector3(px, 0.2, z))
			if z > Terrain.PIER_Z0 + 12.0 and px > 0.0:
				_tide_marks(Vector3(px, 0.0, z))
		z += 3.6
		first = false

func _tide_marks(base: Vector3) -> void:
	var band := _mat(PILING_MARK_COLOR, 0.8)
	for i in range(0, 10):
		var h := i * 0.5
		var thick := 0.05 if i % 2 == 1 else 0.09
		var ring := _cyl(0.27, 0.27, thick, 8)
		_mesh(self, ring, band, base + Vector3(0, h, 0))
		if i % 2 == 0 and i > 0:
			var lbl := Label3D.new()
			lbl.text = str(i / 2)
			lbl.font_size = 64
			lbl.pixel_size = 0.004
			lbl.modulate = Color("e8dfc8")
			lbl.position = base + Vector3(-0.3, h + 0.12, 0.0)
			lbl.rotation.y = -PI / 2.0
			add_child(lbl)

# --- east sea stack: wreck ---------------------------------------------

func _build_wreck() -> void:
	var g := Node3D.new()
	g.position = Vector3(76, 5.4, 6)
	add_child(g)
	var wood := _mat(Color("5c4938"), 0.9)
	_mesh(g, _cyl(2.2, 3.4, 11.5, 8), wood, Vector3(0, 1.3, 0), Vector3(0.4, 0.4, PI / 2.35))
	_mesh(g, _cyl(0.18, 0.28, 8.5, 8), wood, Vector3(-1.2, 3.6, 0.5), Vector3(0, 0, -0.35))
	_mesh(g, _cyl(0.35, 0.35, 1.1), _mat(Color("d99b26"), 0.4, 0.5), Vector3(2.5, 0.8, 2.2), Vector3(0, 0, 1.2))
	_interactable("shipwreck", "Inspect 1974 Waterproof Canister", Vector3(78.5, 6.2, 8.2), 5.5, "shipwreck")
	_bino_target("EAST SEA STACK // UNCHARTED WRECK", Vector3(76, 8, 6))

# --- west sea stack: echo cave -----------------------------------------

func _build_cave() -> void:
	var g := Node3D.new()
	g.position = Vector3(-74, 5.5, -8)
	add_child(g)
	var rock := _mat(Color("454e54"), 0.92)
	for z in [-3.5, 3.5]:
		var s := SphereMesh.new(); s.radius = 3.8; s.height = 7.6; s.radial_segments = 8; s.rings = 5
		_mesh(g, s, rock, Vector3(0, 2.0, z))
	_mesh(g, _box(Vector3(6.5, 3.2, 11.5)), rock, Vector3(0, 5.2, 0))
	var buoy := SphereMesh.new(); buoy.radius = 1.1; buoy.height = 2.2; buoy.radial_segments = 10; buoy.rings = 6
	_mesh(g, buoy, _mat(Color("b83b2b"), 0.5), Vector3(1.5, 1.2, 0))
	_mesh(g, _cyl(0.15, 0.15, 1.6, 8), _mat(Color("d4a446"), 0.3, 0.8), Vector3(1.5, 2.4, 0))
	_interactable("seacave", "Examine Washed-Up Acoustic Buoy", Vector3(-72.5, 6.5, -8), 6.0, "seacave")
	_bino_target("WEST SEA STACK // ECHO SEA CAVE", Vector3(-74, 9, -8))

func _build_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var rock_mat := _mat(Color("3b444b"), 0.92)
	var coords := [[14, 14, 2.4], [-16, 15, 2.8], [18, -14, 3.1], [-19, -15, 2.6],
		[8, -22, 3.5], [-10, -24, 2.9], [44, 11, 1.8], [56, -2, 2.1],
		[-42, -13, 2.0], [-55, 1, 1.7], [84, 14, 3.2], [-82, -16, 3.4]]
	for c in coords:
		var s: float = c[2]
		var sphere := SphereMesh.new()
		sphere.radius = 1.0; sphere.height = 2.0; sphere.radial_segments = 6; sphere.rings = 3
		var y := Terrain.height(c[0], c[1])
		var mi := _mesh(self, sphere, rock_mat, Vector3(c[0], y + s * 0.3, c[1]),
			Vector3(rng.randf() * 3.0, rng.randf() * 3.0, rng.randf() * 3.0))
		mi.scale = Vector3(s * 1.2, s * 0.85, s)
