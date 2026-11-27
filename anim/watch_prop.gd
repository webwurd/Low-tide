class_name WatchProp extends Node3D
## 3D pocket watch with a hinged lid (PROTOTYPE). Face normal is +Y, 12 o'clock
## is -Z. `lid_open` 0 closed .. 1 fully open; `clock_minutes` drives the hands.
## Life size here; the viewmodel hand that holds it is drawn 1.5x so the dial reads.

const R := 0.034
const SCALE := 1.0

var _lid: Node3D
var _hour: Node3D
var _min: Node3D
var _sec: Node3D

@export var lid_open := 0.0: set = set_lid
@export var clock_minutes := 418.0: set = set_clock

func _init() -> void:
	scale = Vector3.ONE * SCALE
	var k := MeshKit.new()
	k.lathe("brass", PackedVector2Array([Vector2(0.0, 0.0), Vector2(R, 0.0), Vector2(R * 1.02, 0.007), Vector2(R, 0.013), Vector2(0.0, 0.013)]), 28, true, true, false)
	k.cylinder("enamel", R * 0.92, R * 0.92, 0.0009, 28, 0.0128, true)
	for i in 12:
		var a := TAU * i / 12.0
		var major := i % 3 == 0
		k.push(Transform3D(Basis(Vector3.UP, -a), Vector3.ZERO))
		k.box("iron", Vector3(0.0026 if major else 0.0014, 0.0008, 0.007 if major else 0.0045), Vector3(0, 0.0141, -R * 0.78), 0.0002)
		k.pop()
	# crown and bow at 12 o'clock
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.0065, -R - 0.002)))
	k.cylinder("brass", 0.0055, 0.0045, 0.008, 10, 0.0, true)
	k.pop()
	var ring := PackedVector3Array()
	for i in 13:
		var a := TAU * i / 12.0
		ring.append(Vector3(0.0, 0.0065 + sin(a) * 0.0085, -R - 0.016 + cos(a) * 0.0085))
	k.tube("brass", ring, 0.0016, 6)
	# a few links of chain trailing off toward the waistcoat
	var chain := PackedVector3Array()
	for i in 8:
		var f := i / 7.0
		chain.append(Vector3(0.0, 0.0065 - 0.05 * f * f, -R - 0.024 - 0.06 * f))
	k.tube("brass", chain, 0.0011, 5)
	var body := MeshInstance3D.new()
	body.mesh = k.commit(false)
	add_child(body)
	_hour = _hand(0.016, 0.0034, "iron", 0.0152)
	_min = _hand(0.025, 0.0024, "iron", 0.0156)
	_sec = _hand(0.027, 0.001, "red_paint", 0.016)
	# lid: pivots at the 12 o'clock edge, lies over the face when closed
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.0135, -R)
	var lk := MeshKit.new()
	lk.cylinder("brass", R * 1.01, R * 1.01, 0.0045, 28, 0.0, true)
	lk.cylinder("brass", R * 0.86, R * 0.86, 0.0012, 28, 0.0045, true)
	var lid_mesh := MeshInstance3D.new()
	lid_mesh.mesh = lk.commit(false)
	lid_mesh.position = Vector3(0, 0, R)
	_lid.add_child(lid_mesh)
	add_child(_lid)
	set_lid(lid_open)
	set_clock(clock_minutes)

func _hand(length: float, width: float, mat: String, y: float) -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(0, y, 0)
	var k := MeshKit.new()
	k.box(mat, Vector3(width, 0.0007, length), Vector3(0, 0, -length * 0.5 + 0.004), 0.0002)
	var mi := MeshInstance3D.new()
	mi.mesh = k.commit(false)
	n.add_child(mi)
	add_child(n)
	return n

func set_lid(v: float) -> void:
	lid_open = v
	if _lid:
		_lid.rotation.x = -v * 2.6

func set_clock(m: float) -> void:
	clock_minutes = m
	if _min:
		_min.rotation.y = -TAU * fmod(m, 60.0) / 60.0
		_hour.rotation.y = -TAU * fmod(m / 60.0, 12.0) / 12.0
		_sec.rotation.y = -TAU * fmod(m * 60.0, 60.0) / 60.0
