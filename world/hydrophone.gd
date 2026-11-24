class_name Hydrophone extends Node3D
## The west cave buoy's hydrophone: a faint sonar ping every 14 seconds while
## the buoy still has power. Clara keeps it alive; ending B switches it off
## (flag `buoy_off`).

const INTERVAL := 14.0

var _player: AudioStreamPlayer3D
var _t := 6.0

func _ready() -> void:
	add_to_group("hydrophone")
	_player = AudioStreamPlayer3D.new()
	_player.bus = "Ambience"
	_player.stream = AudioDirector.ping_stream()
	_player.unit_size = 10.0
	_player.max_distance = 140.0
	_player.volume_db = -6.0
	add_child(_player)

func is_live() -> bool:
	return not GameState.has_flag("buoy_off")

func _process(delta: float) -> void:
	if not is_live():
		return
	_t += delta
	if _t >= INTERVAL:
		_t = 0.0
		_player.play()
