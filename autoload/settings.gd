extends Node
## User settings + InputMap registration (keyboard/mouse and gamepad parity).

signal assist_changed(on: bool)
var assist_mode := false:
	set(v):
		assist_mode = v
		assist_changed.emit(v)

## Graphics quality preset. HIGH is the PC target (SDFGI, SSIL, volumetric fog,
## 4x MSAA); LOW is the Steam Deck / older-GPU preset. The M7 settings menu
## writes this; `--quality=low|medium|high` on the command line overrides it.
enum Quality { LOW, MEDIUM, HIGH }
signal quality_changed(q: Quality)
var quality: Quality = Quality.HIGH:
	set(v):
		quality = v
		quality_changed.emit(v)

func _ready() -> void:
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--quality="):
			match a.get_slice("=", 1).to_lower():
				"low": quality = Quality.LOW
				"medium": quality = Quality.MEDIUM
				_: quality = Quality.HIGH
	_key("move_forward", KEY_W); _key("move_back", KEY_S)
	_key("move_left", KEY_A); _key("move_right", KEY_D)
	_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0); _axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0); _axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0); _axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)
	_axis("look_left", JOY_AXIS_RIGHT_X, -1.0); _axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_key("sprint", KEY_SHIFT); _btn("sprint", JOY_BUTTON_LEFT_STICK)
	_key("binoculars", KEY_B); _mouse("binoculars", MOUSE_BUTTON_RIGHT); _axis("binoculars", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_key("interact", KEY_E); _btn("interact", JOY_BUTTON_A)
	_key("watch", KEY_Q); _btn("watch", JOY_BUTTON_LEFT_SHOULDER)
	_key("radio_1", KEY_1); _btn("radio_1", JOY_BUTTON_DPAD_LEFT)
	_key("radio_2", KEY_2); _btn("radio_2", JOY_BUTTON_DPAD_RIGHT)
	_key("radio_dismiss", KEY_X); _btn("radio_dismiss", JOY_BUTTON_B)
	_key("toggle_assist", KEY_F1); _btn("toggle_assist", JOY_BUTTON_Y)
	_key("logbook", KEY_TAB); _btn("logbook", JOY_BUTTON_BACK)
	_key("debug_skip", KEY_T)
	_key("pause", KEY_ESCAPE); _btn("pause", JOY_BUTTON_START)

func _add(action: String, ev: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	InputMap.action_add_event(action, ev)

func _key(action: String, code: Key) -> void:
	var e := InputEventKey.new(); e.physical_keycode = code; _add(action, e)

func _mouse(action: String, b: MouseButton) -> void:
	var e := InputEventMouseButton.new(); e.button_index = b; _add(action, e)

func _btn(action: String, b: JoyButton) -> void:
	var e := InputEventJoypadButton.new(); e.button_index = b; _add(action, e)

func _axis(action: String, axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new(); e.axis = axis; e.axis_value = value; _add(action, e)
