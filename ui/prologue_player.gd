class_name ProloguePlayer extends Control
## Plays Prologue.beats(): typed text cards with choices over a darkened
## frame, and crossing shots (Main moves the camera on `shot_requested`).
## Advance with E / Enter / A; choose with the buttons (mouse or gamepad);
## hold Esc / B to skip the whole prologue. Emits `finished` at the end.

signal shot_requested(index: int, seconds: float)
signal finished

const TYPE_RATE := 52.0        # characters per second
const SKIP_HOLD := 1.0

var _beats: Array = []
var _i := -1
var _shade: ColorRect
var _card: VBoxContainer
var _lines: Label
var _choices: VBoxContainer
var _caption: Label
var _radio: PanelContainer
var _radio_who: Label
var _radio_line: Label
var _skip: Label
var _typing: Tween
var _waiting_choice := false
var _shot_left := 0.0
var _skip_t := 0.0
var _done := false
## Choices made, applied to GameState by Main after new_game() resets it.
var chosen_flags: Array[String] = []
var trust_delta := 0

func _ready() -> void:
	# Already in the tree here, so offsets must be set too (plain
	# set_anchors_preset would keep the current zero-size rect).
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shade = ColorRect.new()
	_shade.color = Color(0.02, 0.03, 0.04, 0.0)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_card = VBoxContainer.new()
	_card.custom_minimum_size = Vector2(720, 0)
	_card.add_theme_constant_override("separation", 26)
	_card.modulate.a = 0.0
	center.add_child(_card)
	_lines = Label.new()
	_lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lines.custom_minimum_size = Vector2(720, 0)
	_lines.add_theme_font_override("font", UiTheme.title_font(500))
	_lines.add_theme_font_size_override("font_size", 28)
	_lines.add_theme_color_override("font_color", Color("ede4cf"))
	_lines.add_theme_constant_override("line_spacing", 6)
	_card.add_child(_lines)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 4)
	_card.add_child(_choices)
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_caption.position = Vector2(72, -96)
	_caption.add_theme_font_override("font", UiTheme.title_font(500, 2))
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Color(0.95, 0.91, 0.82, 0.9))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption.modulate.a = 0.0
	add_child(_caption)
	_radio = PanelContainer.new()
	_radio.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_radio.position = Vector2(-340, -210)
	_radio.custom_minimum_size = Vector2(680, 0)
	_radio.visible = false
	add_child(_radio)
	var rv := VBoxContainer.new()
	_radio.add_child(rv)
	_radio_who = Label.new()
	_radio_who.add_theme_font_size_override("font_size", 12)
	_radio_who.add_theme_color_override("font_color", UiTheme.AMBER)
	_radio_line = Label.new()
	_radio_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_line.custom_minimum_size = Vector2(650, 0)
	_radio_line.add_theme_font_override("font", UiTheme.title_font(500))
	_radio_line.add_theme_font_size_override("font_size", 22)
	rv.add_child(_radio_who)
	rv.add_child(_radio_line)
	_skip = Label.new()
	_skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip.position = Vector2(-260, -48)
	_skip.text = "Hold Esc / B to skip"
	_skip.add_theme_font_size_override("font_size", 12)
	_skip.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8, 0.4))
	add_child(_skip)
	visible = false

func play() -> void:
	_beats = Prologue.beats()
	_i = -1
	chosen_flags.clear()
	trust_delta = 0
	_done = false
	visible = true
	_next()

func _next() -> void:
	if _done:
		return   # a pending timer/tween from before a skip
	_i += 1
	if _i >= _beats.size():
		_finish()
		return
	var b: Dictionary = _beats[_i]
	if b.has("shot"):
		_hide_card()
		_radio.visible = false
		create_tween().tween_property(_shade, "color:a", 0.0, 1.2)
		_caption.text = b.get("caption", "")
		var tw := create_tween()
		tw.tween_interval(0.8)
		tw.tween_property(_caption, "modulate:a", 1.0 if _caption.text != "" else 0.0, 1.0)
		_shot_left = b.get("seconds", 6.0)
		shot_requested.emit(int(b["shot"]), _shot_left)
	elif b.has("radio"):
		_radio_who.text = b["radio"]
		_radio_line.text = '"' + b["line"] + '"'
		_radio.visible = true
		_radio.modulate.a = 0.0
		create_tween().tween_property(_radio, "modulate:a", 1.0, 0.4)
		_shot_left = 3.0 + String(b["line"]).length() * 0.05
	else:
		_show_text(b)

func _show_text(b: Dictionary) -> void:
	_shot_left = 0.0
	create_tween().tween_property(_caption, "modulate:a", 0.0, 0.5)
	create_tween().tween_property(_shade, "color:a", 0.86, 1.0)
	_lines.text = "\n\n".join(PackedStringArray(b["text"]))
	_lines.visible_characters = 0
	for c in _choices.get_children():
		c.queue_free()
	_choices.visible = false
	_waiting_choice = false
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.8)
	var n := _lines.get_total_character_count()
	_typing = create_tween()
	_typing.tween_interval(0.6)
	_typing.tween_property(_lines, "visible_characters", n, n / TYPE_RATE)
	_typing.tween_callback(_show_choices.bind(b))

func _show_choices(b: Dictionary) -> void:
	if _done:
		return
	_lines.visible_characters = -1
	var first: Button = null
	for ch in b.get("choices", []):
		var btn := Button.new()
		btn.text = ch["text"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_override("font", UiTheme.title_font(600))
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color(1, 0.86, 0.62))
		btn.pressed.connect(_choose.bind(ch))
		_choices.add_child(btn)
		if first == null:
			first = btn
	_choices.visible = true
	_choices.modulate.a = 0.0
	create_tween().tween_property(_choices, "modulate:a", 1.0, 0.5)
	_waiting_choice = first != null
	if first:
		first.grab_focus.call_deferred()

func _choose(ch: Dictionary) -> void:
	if not _waiting_choice or _done:
		return
	_waiting_choice = false
	if ch.get("flag", "") != "":
		chosen_flags.append(ch["flag"])
	trust_delta += int(ch.get("trust", 0))
	_hide_card()
	get_tree().create_timer(0.7).timeout.connect(_next)

func _hide_card() -> void:
	create_tween().tween_property(_card, "modulate:a", 0.0, 0.6)

func _finish() -> void:
	if _done:
		return
	_done = true
	_waiting_choice = false
	_shot_left = 0.0
	if _typing and _typing.is_valid():
		_typing.kill()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func():
		visible = false
		modulate.a = 1.0
		finished.emit())

func _process(delta: float) -> void:
	if not visible or _done:
		return
	# Hold to skip.
	if Input.is_action_pressed("pause") or Input.is_action_pressed("radio_dismiss"):
		_skip_t += delta
		_skip.text = "Skipping..." if _skip_t > 0.15 else "Hold Esc / B to skip"
		if _skip_t >= SKIP_HOLD:
			_finish()
			return
	else:
		_skip_t = 0.0
		_skip.text = "Hold Esc / B to skip"
	if _shot_left > 0.0:
		_shot_left -= delta
		if _shot_left <= 0.0:
			_next()
		return
	# Tap to finish typing early.
	if (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept")) and _typing and _typing.is_running():
		_typing.kill()
		_show_choices(_beats[_i])

func apply_to_state() -> void:
	for f in chosen_flags:
		GameState.set_flag(f)
	GameState.trust += trust_delta
	GameState.set_flag("prologue_seen")
