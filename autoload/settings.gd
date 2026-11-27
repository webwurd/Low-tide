extends Node
## User settings: persistence, live application, and input bindings
## (keyboard/mouse and gamepad parity). Everything the Settings menu changes
## goes through set_v(), which validates, applies, signals and saves.

signal changed(key: String)
signal assist_changed(on: bool)
signal bindings_changed
signal controllers_changed

var path := "user://lowtide_settings.cfg"

const DEFAULTS := {
	# graphics
	"window_mode": 0,          # 0 windowed, 1 borderless fullscreen, 2 exclusive fullscreen
	"vsync": 1,                # 0 off, 1 on, 2 adaptive
	"fps_cap": 0,              # 0 = unlimited
	"render_scale": 1.0,
	"msaa": 0,                 # 0 off, 1 2x, 2 4x, 3 8x
	"shadow_quality": 2,       # 0 off, 1 low, 2 medium, 3 high
	"ocean_detail": 2,         # 0 low, 1 medium, 2 high
	"quality_preset": 2,       # 0 low, 1 medium, 2 high, 3 deck, 4 custom
	# audio
	"vol_master": 1.0, "vol_ambience": 1.0, "vol_sfx": 1.0, "vol_radio": 1.0, "vol_music": 1.0,
	"radio_static": 1.0,
	"music_score": 2,          # 0 stings only, 1 sparse, 2 full adaptive score
	# lighting
	"brightness": 1.0, "exposure": 1.0, "night_assist": 0.0, "fog_scale": 1.0, "glow": true, "beam_scale": 1.0,
	# controls
	"mouse_sens": 1.0, "bino_sens": 1.0, "pad_sens": 1.0, "invert_y": false, "deadzone": 0.2,
	"toggle_binoculars": false, "toggle_watch": false, "toggle_hold": false,
	"gamepad_input": 0,        # 0 recognised controllers only, 1 any device, 2 off
	# accessibility
	"assist_mode": false, "reduce_motion": false, "ui_scale": 1.0, "subtitle_scale": 1.0,
	"highlight_mode": 0,       # interactables: 0 nearby dimly + focused brightly, 1 focused only, 2 off
}

## key -> [min, max] for numeric settings (values are clamped).
const RANGES := {
	"window_mode": [0, 2], "vsync": [0, 2], "fps_cap": [0, 240], "render_scale": [0.5, 1.0], "msaa": [0, 3],
	"shadow_quality": [0, 3], "ocean_detail": [0, 2], "quality_preset": [0, 4],
	"vol_master": [0.0, 1.0], "vol_ambience": [0.0, 1.0], "vol_sfx": [0.0, 1.0], "vol_radio": [0.0, 1.0],
	"vol_music": [0.0, 1.0], "radio_static": [0.0, 1.0], "music_score": [0, 2],
	"brightness": [0.6, 1.6], "exposure": [0.6, 1.6], "night_assist": [0.0, 1.0], "fog_scale": [0.3, 1.5], "beam_scale": [0.4, 2.0],
	"mouse_sens": [0.3, 3.0], "bino_sens": [0.3, 3.0], "pad_sens": [0.3, 3.0], "deadzone": [0.05, 0.5],
	"gamepad_input": [0, 2], "highlight_mode": [0, 2],
	"ui_scale": [0.8, 1.5], "subtitle_scale": [0.8, 1.8],
}

## Settings that a quality preset controls. Changing any of them by hand switches the preset to "custom".
const PRESET_KEYS := ["render_scale", "msaa", "shadow_quality", "ocean_detail", "fps_cap"]
const PRESETS := [
	{"render_scale": 0.75, "msaa": 0, "shadow_quality": 1, "ocean_detail": 0, "fps_cap": 0},    # low
	{"render_scale": 0.9, "msaa": 0, "shadow_quality": 2, "ocean_detail": 1, "fps_cap": 0},     # medium
	{"render_scale": 1.0, "msaa": 2, "shadow_quality": 3, "ocean_detail": 2, "fps_cap": 0},     # high
	{"render_scale": 0.8, "msaa": 0, "shadow_quality": 1, "ocean_detail": 1, "fps_cap": 60},    # steam deck
]

const AUDIO_BUSES := {"vol_master": "Master", "vol_ambience": "Ambience", "vol_sfx": "SFX", "vol_radio": "Radio", "vol_music": "Music"}

var values: Dictionary = DEFAULTS.duplicate()
var _save_timer: Timer
var _applying := false

# ---- values --------------------------------------------------------------

func v(key: String):
	return values.get(key, DEFAULTS.get(key))

func get_v(key: String):
	return v(key)

func set_v(key: String, value) -> void:
	if not DEFAULTS.has(key):
		push_warning("Unknown setting: " + key)
		return
	value = _coerce(key, value)
	if values.get(key) == value:
		return
	values[key] = value
	if key in PRESET_KEYS and key != "quality_preset" and not _applying and int(values["quality_preset"]) != 4:
		values["quality_preset"] = 4
		changed.emit("quality_preset")
	_apply_key(key)
	changed.emit(key)
	if key == "assist_mode":
		assist_changed.emit(value)
	_queue_save()

func _coerce(key: String, value):
	var def = DEFAULTS[key]
	if typeof(def) == TYPE_BOOL:
		return bool(value)
	if typeof(def) == TYPE_INT:
		var r: Array = RANGES.get(key, [-1000000, 1000000])
		return clampi(int(round(float(value))), int(r[0]), int(r[1]))
	var rf: Array = RANGES.get(key, [-1e9, 1e9])
	return clampf(float(value), float(rf[0]), float(rf[1]))

func set_preset(index: int) -> void:
	index = clampi(index, 0, 4)
	if index < PRESETS.size():
		_applying = true
		for k in PRESETS[index]:
			set_v(k, PRESETS[index][k])
		_applying = false
	set_v("quality_preset", index)

var assist_mode: bool:
	get: return bool(v("assist_mode"))
	set(value): set_v("assist_mode", value)

func reset_defaults(keys: Array = []) -> void:
	var list: Array = keys if keys.size() > 0 else DEFAULTS.keys()
	for k in list:
		set_v(k, DEFAULTS[k])

# ---- persistence ------------------------------------------------------------

func _queue_save() -> void:
	if _save_timer == null:
		return
	_save_timer.start(0.6)

func save_settings() -> bool:
	var cfg := ConfigFile.new()
	for k in values:
		if values[k] != DEFAULTS[k]:
			cfg.set_value("settings", k, values[k])
	for action in _bindings_dirty():
		cfg.set_value("bindings", action, JSON.stringify(_dump_action(action)))
	return cfg.save(path) == OK

func load_settings() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return false
	_applying = true
	for k in cfg.get_section_keys("settings") if cfg.has_section("settings") else []:
		if DEFAULTS.has(k):
			values[k] = _coerce(k, cfg.get_value("settings", k))
	_applying = false
	if cfg.has_section("bindings"):
		for action in cfg.get_section_keys("bindings"):
			var parsed: Variant = JSON.parse_string(String(cfg.get_value("bindings", action)))
			if typeof(parsed) == TYPE_DICTIONARY and InputMap.has_action(action):
				_load_action(action, parsed)
	return true

func delete_saved_settings() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

# ---- live application ----------------------------------------------------------

func apply_all() -> void:
	for k in DEFAULTS:
		_apply_key(k)

func _apply_key(key: String) -> void:
	match key:
		"window_mode", "vsync", "fps_cap", "render_scale", "msaa", "shadow_quality":
			_apply_graphics(key)
		"deadzone":
			_apply_deadzone()
		"gamepad_input":
			refresh_pads()
		"ui_scale":
			var w := get_window()
			if w:
				w.content_scale_factor = float(v("ui_scale"))
		_:
			if key in AUDIO_BUSES:
				_apply_volume(key)

static func vol_to_db(vol: float) -> float:
	return -80.0 if vol <= 0.001 else linear_to_db(vol)

func _apply_volume(key: String) -> void:
	var idx := AudioServer.get_bus_index(AUDIO_BUSES[key])
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, vol_to_db(float(v(key))))
		AudioServer.set_bus_mute(idx, float(v(key)) <= 0.001)

func _apply_graphics(key: String) -> void:
	var headless := DisplayServer.get_name() == "headless"
	match key:
		"window_mode":
			if not headless:
				var mode := int(v("window_mode"))
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, mode == 1)
				DisplayServer.window_set_mode([DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN][mode])
		"vsync":
			if not headless:
				DisplayServer.window_set_vsync_mode([DisplayServer.VSYNC_DISABLED, DisplayServer.VSYNC_ENABLED, DisplayServer.VSYNC_ADAPTIVE][int(v("vsync"))])
		"fps_cap":
			Engine.max_fps = int(v("fps_cap"))
		"render_scale":
			var vp := get_viewport()
			if vp:
				var method := RenderingServer.get_current_rendering_method()
				var scaled := float(v("render_scale")) < 0.999
				# FSR upscaling exists only in Forward+/Mobile; the Compatibility renderer ignores 3D scaling.
				vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if (scaled and method != "gl_compatibility") else Viewport.SCALING_3D_MODE_BILINEAR
				vp.scaling_3d_scale = float(v("render_scale"))
		"msaa":
			var vp2 := get_viewport()
			if vp2:
				vp2.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X][int(v("msaa"))]
		"shadow_quality":
			RenderingServer.directional_shadow_atlas_set_size([1024, 1024, 2048, 4096][int(v("shadow_quality"))], true)

## Longest distance the sun's shadows are drawn, by quality (0 = shadows off).
func shadow_distance() -> float:
	return [0.0, 90.0, 150.0, 220.0][int(v("shadow_quality"))]

# ---- gamepad devices -------------------------------------------------------------
# Events made in code default to device 0, so only joypad slot 0 would drive the game, and
# an unrelated HID device that registers as a joystick (gaming mice, hubs, wheels, trackers)
# with axes resting off-centre would spin the camera and walk Arthur backwards. Every joypad
# binding is therefore pinned to one recognised controller (or to every device, or to none).

const NO_PAD := 99999          # a device id that never exists: pinned events match nothing
const ANY_PAD := -1
var _pad_active := 0
var _hinted: Dictionary = {}         # device id -> true once the "not recognised" hint was shown
var _pads_fake: Variant = null       # tests: an Array of {id, name, known} instead of real devices

## Connected joypads: [{id, name, known}]. Tests can substitute a fake list.
func _pads() -> Array:
	if _pads_fake != null:
		return _pads_fake
	var out: Array = []
	for id in Input.get_connected_joypads():
		out.append({"id": id, "name": Input.get_joy_name(id), "known": Input.is_joy_known(id)})
	return out

func _pad_target() -> int:
	match int(v("gamepad_input")):
		1:
			return ANY_PAD
		2:
			return NO_PAD
	for p in _pads():
		if p["known"]:
			return p["id"]
	return NO_PAD

## Re-chooses which joypad drives the game and pins every joypad binding to it.
func refresh_pads() -> void:
	_pin_pads(_pad_target())

## Game actions follow `target`. Menu (ui_*) actions follow it too, except that with no
## usable controller (none recognised, or the setting is Off) their buttons stay open to
## every device, so the menus and the setting can always be reached, while their axes are
## closed, so a drifting stick can never move menu focus.
func _pin_pads(target: int) -> void:
	_pad_active = target
	var ui_buttons := ANY_PAD if target == NO_PAD else target
	for action in InputMap.get_actions():
		var is_ui := String(action).begins_with("ui_")
		var pads: Array = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				pads.append(ev)
		var wanted: Array = []
		for ev in pads:
			wanted.append(ui_buttons if (is_ui and ev is InputEventJoypadButton) else target)
		# Replace in order so each action's per-device event order is unchanged. Erasing an
		# event also clears the action's held state in the engine, so a pad that is unplugged
		# or retargeted mid-stride cannot leave Arthur walking (tests guard this).
		for k in pads.size():
			if pads[k].device != wanted[k]:
				InputMap.action_erase_event(action, pads[k])
		for k in pads.size():
			if pads[k].device != wanted[k]:
				pads[k].device = wanted[k]
				InputMap.action_add_event(action, pads[k])

func _on_joy_changed(device: int, connected: bool) -> void:
	print("Joypad %d %s: '%s' (recognised: %s)" % [device, "connected" if connected else "removed", Input.get_joy_name(device), Input.is_joy_known(device)])
	refresh_pads()
	controllers_changed.emit()
	_schedule_hint()

func _schedule_hint() -> void:
	if is_inside_tree():
		get_tree().create_timer(3.0).timeout.connect(_unrecognised_hint)

## In the default mode, a connected controller that Godot does not recognise is ignored.
## Say so once per device (as one of Arthur's toasts), and where to change it.
func _unrecognised_hint() -> void:
	if int(v("gamepad_input")) != 0:
		return
	var pads := _pads()
	for p in pads:
		if p["known"]:
			return
	for p in pads:
		if not _hinted.has(p["id"]):
			_hinted[p["id"]] = true
			# GameState loads after Settings, so look it up at run time rather than by name.
			get_node("/root/GameState").note("A controller (%s) was detected but isn't recognised, so it's ignored. Turn on Any device in Settings > Controls if it's yours." % p["name"])

## For the Controls tab: one entry per connected joypad.
func pad_status() -> Array:
	var out: Array = []
	for p in _pads():
		out.append({"id": p["id"], "name": p["name"], "known": p["known"],
			"active": _pad_active == p["id"] or _pad_active == ANY_PAD})
	return out

func _apply_deadzone() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "look_up", "look_down", "look_left", "look_right"]:
		if InputMap.has_action(a):
			InputMap.action_set_deadzone(a, float(v("deadzone")))

# ---- input bindings ---------------------------------------------------------------

## [action, label, rebindable on gamepad]
const ACTIONS := [
	["move_forward", "Move forward", false], ["move_back", "Move back", false],
	["move_left", "Move left", false], ["move_right", "Move right", false],
	["sprint", "Brisk walk", true], ["interact", "Inspect / use", true], ["binoculars", "Binoculars", true],
	["watch", "Pocket watch", true], ["logbook", "Journal", true], ["radio_1", "Radio reply 1", true],
	["radio_2", "Radio reply 2", true], ["radio_dismiss", "Dismiss radio", true],
	["toggle_assist", "Assist readout", true], ["pause", "Pause", true],
]
const KB := "kb"
const PAD := "pad"
var _defaults: Dictionary = {}     # action -> {kb: [dict], pad: [dict]}

func _ready() -> void:
	UiFonts.install_default()
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.timeout.connect(save_settings)
	add_child(_save_timer)
	_register_default_bindings()
	_ensure_buses()
	_snapshot_defaults()
	load_settings()
	apply_all()
	refresh_pads()
	Input.joy_connection_changed.connect(_on_joy_changed)
	_schedule_hint()

func _exit_tree() -> void:
	if _save_timer and not _save_timer.is_stopped():
		save_settings()

func _ensure_buses() -> void:
	for n in ["Ambience", "SFX", "Radio", "Music"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, n)
			AudioServer.set_bus_send(idx, "Master")

func _register_default_bindings() -> void:
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
	if OS.is_debug_build():
		_key("debug_skip", KEY_T)   # dev-only time skip; never bound in release builds
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

static func device_of(ev: InputEvent) -> String:
	if ev is InputEventKey or ev is InputEventMouseButton:
		return KB
	if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
		return PAD
	return ""

static func ev_to_dict(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return {"t": "key", "code": int(ev.physical_keycode)}
	if ev is InputEventMouseButton:
		return {"t": "mouse", "b": int(ev.button_index)}
	if ev is InputEventJoypadButton:
		return {"t": "jbtn", "b": int(ev.button_index)}
	if ev is InputEventJoypadMotion:
		return {"t": "jaxis", "a": int(ev.axis), "v": 1.0 if ev.axis_value >= 0.0 else -1.0}
	return {}

static func dict_to_ev(d: Dictionary) -> InputEvent:
	match String(d.get("t", "")):
		"key":
			var k := InputEventKey.new(); k.physical_keycode = int(d["code"]) as Key; return k
		"mouse":
			var m := InputEventMouseButton.new(); m.button_index = int(d["b"]) as MouseButton; return m
		"jbtn":
			var b := InputEventJoypadButton.new(); b.button_index = int(d["b"]) as JoyButton; return b
		"jaxis":
			var a := InputEventJoypadMotion.new(); a.axis = int(d["a"]) as JoyAxis; a.axis_value = float(d["v"]); return a
	return null

func _dump_action(action: String) -> Dictionary:
	var out := {KB: [], PAD: []}
	for ev in InputMap.action_get_events(action):
		var dev := device_of(ev)
		if dev != "":
			out[dev].append(ev_to_dict(ev))
	return out

func _snapshot_defaults() -> void:
	for a in ACTIONS:
		_defaults[a[0]] = _dump_action(a[0])

func _load_action(action: String, dump: Dictionary) -> void:
	for dev in [KB, PAD]:
		if not dump.has(dev):
			continue
		_clear_device(action, dev)
		for d in dump[dev]:
			var ev := dict_to_ev(d)
			if ev:
				InputMap.action_add_event(action, ev)

func _bindings_dirty() -> Array:
	var out: Array = []
	for a in ACTIONS:
		if _dump_action(a[0]) != _defaults.get(a[0], {}):
			out.append(a[0])
	return out

func _clear_device(action: String, dev: String) -> void:
	for ev in InputMap.action_get_events(action):
		if device_of(ev) == dev:
			InputMap.action_erase_event(action, ev)

func is_rebindable(action: String, dev: String) -> bool:
	for a in ACTIONS:
		if a[0] == action:
			return dev == KB or a[2]
	return false

func binding_text(action: String, dev: String) -> String:
	var parts: Array = []
	for ev in InputMap.action_get_events(action):
		if device_of(ev) == dev:
			parts.append(event_text(ev))
	return " / ".join(PackedStringArray(parts)) if parts.size() > 0 else "(unbound)"

static func event_text(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return OS.get_keycode_string(ev.physical_keycode)
	if ev is InputEventMouseButton:
		return ["", "Mouse Left", "Mouse Right", "Mouse Middle", "Wheel Up", "Wheel Down"][clampi(ev.button_index, 0, 5)] if ev.button_index <= 5 else "Mouse %d" % ev.button_index
	if ev is InputEventJoypadButton:
		var names := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y", JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Menu",
			JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
			JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down", JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right"}
		return names.get(ev.button_index, "Button %d" % ev.button_index)
	if ev is InputEventJoypadMotion:
		var axis_names := {JOY_AXIS_LEFT_X: "Left stick X", JOY_AXIS_LEFT_Y: "Left stick Y", JOY_AXIS_RIGHT_X: "Right stick X",
			JOY_AXIS_RIGHT_Y: "Right stick Y", JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT"}
		var nm: String = axis_names.get(ev.axis, "Axis %d" % ev.axis)
		if ev.axis <= JOY_AXIS_RIGHT_Y:
			nm += " +" if ev.axis_value > 0 else " -"
		return nm
	return "?"

## Rebinds `action` on one device class to `ev`. Any other rebindable action holding
## the same input loses it. Returns the labels of actions that were unbound.
## Non-empty (a message for the player) when binding `ev` to `action` would take the
## last keyboard binding away from Pause, leaving the menu unreachable by keyboard.
func rebind_blocked(action: String, ev: InputEvent) -> String:
	if action == "pause" or device_of(ev) != KB:
		return ""
	var want := ev_to_dict(ev)
	var kb_events: Array = []
	for other in InputMap.action_get_events("pause"):
		if device_of(other) == KB:
			kb_events.append(other)
	if kb_events.size() == 1 and ev_to_dict(kb_events[0]) == want:
		return "Pause needs a keyboard key. Give it another key first."
	return ""

func rebind(action: String, ev: InputEvent) -> Array:
	var dev := device_of(ev)
	if dev == "" or not is_rebindable(action, dev):
		return []
	if rebind_blocked(action, ev) != "":
		return []
	var want := ev_to_dict(ev)
	var cleared: Array = []
	for a in ACTIONS:
		if a[0] == action:
			continue
		for other in InputMap.action_get_events(a[0]):
			if device_of(other) == dev and ev_to_dict(other) == want:
				InputMap.action_erase_event(a[0], other)
				cleared.append(a[1])
	_clear_device(action, dev)
	InputMap.action_add_event(action, ev)
	_pin_pads(_pad_active)
	bindings_changed.emit()
	_queue_save()
	return cleared

func reset_bindings() -> void:
	for a in ACTIONS:
		for dev in [KB, PAD]:
			_clear_device(a[0], dev)
		_load_action(a[0], _defaults[a[0]])
	_pin_pads(_pad_active)
	bindings_changed.emit()
	_queue_save()
