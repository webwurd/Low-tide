class_name BellBuoy extends Node3D
## A bell buoy marking one side of the island, for navigating by ear in fog.
## Strike count tells the compass point: 1 = North, 2 = East, 3 = South, 4 = West.
## Rougher seas ring faster and louder.

@export var strikes := 1
@export var pitch := 440.0
@export var label := "Bell buoy"

var _player: AudioStreamPlayer3D
var _phase := 0.0
var _clock := 0.0
var _rung := 0
var _gap := 0.0

func _ready() -> void:
	add_to_group("bell_buoy")
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("b83b2b")
	red.roughness = 0.6
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("22282e")
	var float_mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5; cm.bottom_radius = 0.8; cm.height = 0.9
	float_mesh.mesh = cm
	float_mesh.material_override = red
	add_child(float_mesh)
	var cage := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(0.6, 1.6, 0.6)
	cage.mesh = bx
	cage.material_override = dark
	cage.position.y = 1.2
	add_child(cage)
	_player = AudioStreamPlayer3D.new()
	_player.bus = "Ambience"
	_player.stream = AudioDirector.bell_stream(pitch)
	_player.unit_size = 30.0
	_player.max_distance = 450.0
	_player.max_db = 2.0
	_player.position.y = 1.2
	add_child(_player)
	_phase = randf() * TAU
	_gap = 1.0 + randf() * 3.0

func _process(delta: float) -> void:
	position.y = TideSystem.current_height + 0.2 + sin(Time.get_ticks_msec() * 0.0013 + _phase) * 0.12
	rotation.z = sin(Time.get_ticks_msec() * 0.0011 + _phase) * 0.06
	var rough := 1.0 + DayDirector.data().wave_height * 2.0
	_clock += delta * rough
	if _rung < strikes:
		if _clock >= _gap:
			_player.volume_db = -4.0 + minf(rough - 1.0, 1.0) * 4.0
			_player.play()
			_rung += 1
			_clock = 0.0
			_gap = 0.95
	elif _clock >= 6.0:
		_rung = 0
		_clock = 0.0
		_gap = 0.0
