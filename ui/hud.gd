class_name HUD extends CanvasLayer
## All UI built in code: reticle + prompt, binocular overlay, pocket watch,
## Assist-mode readout, radio panel, fade/respawn card, title card.

signal start_pressed

const AMBER := Color("ffb84d")
const CARD_BG := Color(0.07, 0.1, 0.13, 0.88)

var player: Player
var _reticle: Control
var _prompt: Label
var _bino: ColorRect
var _bino_range: Label
var _bino_label: Label
var _watch: PocketWatch
var _assist: PanelContainer
var _assist_clock: Label
var _assist_tide: Label
var _assist_level: Label
var _assist_bar: ProgressBar
var _assist_log: Label
var _stamina: ProgressBar
var _radio: PanelContainer
var _radio_speaker: Label
var _radio_text: Label
var _radio_opts: HBoxContainer
var _opt_buttons: Array[Button] = []
var _fade: ColorRect
var _fade_label: Label
var _title: Control
var _hints: Label

func _ready() -> void:
	layer = 10
	_build_reticle()
	_build_binoculars()
	_build_watch()
	_build_assist()
	_build_radio()
	_build_fade()
	_build_title()
	RadioSystem.line_shown.connect(_on_line)
	RadioSystem.reply_shown.connect(_on_reply)
	RadioSystem.hidden.connect(func(): _radio.visible = false)
	Settings.assist_changed.connect(func(on): _assist.visible = on)
	GameState.discovered_changed.connect(func(_id): _refresh_log())
	_assist.visible = Settings.assist_mode
	_refresh_log()

func _full(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _style(bg := CARD_BG, border := Color(0.85, 0.7, 0.42, 0.35)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	return sb

func _label(text: String, size := 14, color := Color("e8dfc8")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

# --- build -------------------------------------------------------------

func _build_reticle() -> void:
	_reticle = Control.new()
	_full(_reticle)
	add_child(_reticle)
	var dot := ColorRect.new()
	dot.color = Color(1.0, 0.95, 0.8, 0.75)
	dot.size = Vector2(4, 4)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position = Vector2(-2, -2)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.add_child(dot)
	_prompt = _label("", 15, Color("ffe9b8"))
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.position = Vector2(-140, 26)
	_prompt.size = Vector2(280, 30)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_reticle.add_child(_prompt)

func _build_binoculars() -> void:
	_bino = ColorRect.new()
	_full(_bino)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ui/binocular.gdshader")
	_bino.material = mat
	_bino.visible = false
	add_child(_bino)
	_bino_range = _label("DIST: --- m", 14, AMBER)
	_bino_range.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_bino_range.position = Vector2(-60, 40)
	_bino.add_child(_bino_range)
	_bino_label = _label("SCANNING HORIZON...", 14, AMBER)
	_bino_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bino_label.position = Vector2(-160, -80)
	_bino_label.size = Vector2(320, 24)
	_bino_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bino.add_child(_bino_label)

func _build_watch() -> void:
	_watch = PocketWatch.new()
	_watch.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_watch.position = Vector2(-190, -190)
	_watch.size = Vector2(150, 150)
	_watch.visible = false
	add_child(_watch)

func _build_assist() -> void:
	_assist = PanelContainer.new()
	_assist.add_theme_stylebox_override("panel", _style())
	_assist.position = Vector2(20, 20)
	_assist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_assist)
	var v := VBoxContainer.new()
	_assist.add_child(v)
	_assist_clock = _label("", 18, Color("ffe9b8"))
	_assist_tide = _label("", 14)
	_assist_level = _label("", 14)
	_assist_bar = ProgressBar.new()
	_assist_bar.custom_minimum_size = Vector2(200, 8)
	_assist_bar.max_value = 4.6
	_assist_bar.min_value = -0.4
	_assist_bar.show_percentage = false
	_assist_log = _label("", 13, Color("b8c4cc"))
	for n in [_assist_clock, _assist_tide, _assist_level, _assist_bar, _assist_log]:
		v.add_child(n)
	_stamina = ProgressBar.new()
	_stamina.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stamina.position = Vector2(20, -24)
	_stamina.size = Vector2(160, 4)
	_stamina.show_percentage = false
	_stamina.max_value = 100
	_stamina.modulate.a = 0.0
	add_child(_stamina)
	_hints = _label("[WASD/Stick] Move  [Shift/L3] Brisk  [RMB/B/LT] Binoculars  [E/A] Inspect  [Q/LB] Pocket watch  [F1/Back] Assist HUD", 12, Color(0.8, 0.85, 0.9, 0.8))
	_hints.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hints.position = Vector2(20, -52)
	add_child(_hints)
	get_tree().create_timer(18.0).timeout.connect(func(): _hints.visible = false)

func _build_radio() -> void:
	_radio = PanelContainer.new()
	_radio.add_theme_stylebox_override("panel", _style())
	_radio.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_radio.custom_minimum_size = Vector2(680, 0)
	_radio.position = Vector2(-340, -250)
	_radio.visible = false
	add_child(_radio)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_radio.add_child(v)
	_radio_speaker = _label("", 12, AMBER)
	_radio_text = _label("", 17)
	_radio_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_text.custom_minimum_size = Vector2(650, 0)
	_radio_opts = HBoxContainer.new()
	_radio_opts.add_theme_constant_override("separation", 10)
	for i in 2:
		var b := Button.new()
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(320, 0)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(RadioSystem.choose.bind(i))
		_radio_opts.add_child(b)
		_opt_buttons.append(b)
	for n in [_radio_speaker, _radio_text, _radio_opts]:
		v.add_child(n)

func _build_fade() -> void:
	_fade = ColorRect.new()
	_full(_fade)
	_fade.color = Color("0b1117")
	_fade.modulate.a = 0.0
	add_child(_fade)
	_fade_label = _label("THE TIDE CAUGHT YOU\n\nFreezing swells drove you back to the pier.", 20, AMBER)
	_fade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_full(_fade_label)
	_fade.add_child(_fade_label)

func _build_title() -> void:
	_title = ColorRect.new()
	(_title as ColorRect).color = Color(0.03, 0.05, 0.07, 0.82)
	_full(_title)
	_title.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_title)
	var c := CenterContainer.new()
	_full(c)
	_title.add_child(c)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(CARD_BG, Color(0.85, 0.7, 0.42, 0.5)))
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(480, 0)
	p.add_child(v)
	var t := _label("LOW TIDE", 40, Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := _label("GANNET ROCK LIGHT STATION - MAINE COAST, WINTER 1998", 12, Color("9aa7b0"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := _label("You are Arthur, winter keeper on a fog-bound island. Read the tide, cross the sandbars while they last, and be back on the pier before the Atlantic returns.\n\nMilestone 2: greybox + tide loop.", 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var b := Button.new()
	b.text = "BEGIN WATCH"
	b.pressed.connect(func():
		_title.visible = false
		start_pressed.emit())
	for n in [t, sub, body, b]:
		v.add_child(n)

# --- runtime -----------------------------------------------------------

func _process(delta: float) -> void:
	if player == null:
		return
	if Input.is_action_just_pressed("toggle_assist"):
		Settings.assist_mode = not Settings.assist_mode
	_watch.visible = Input.is_action_pressed("watch") or Settings.assist_mode
	if Input.is_action_just_pressed("radio_1"): RadioSystem.choose(0)
	if Input.is_action_just_pressed("radio_2"): RadioSystem.choose(1)
	if Input.is_action_just_pressed("radio_dismiss"): RadioSystem.dismiss()

	_bino.visible = player.binoculars
	_reticle.get_child(0).visible = not player.binoculars
	if player.binoculars:
		_bino_range.text = "DIST: %d m" % player.bino_dist if player.bino_dist >= 0 else "DIST: --- m"
		_bino_label.text = player.bino_label if player.bino_label != "" else "SCANNING HORIZON..."
	_prompt.visible = player.nearby != null and not player.binoculars
	if player.nearby:
		_prompt.text = "[E]  " + player.nearby.title
	_stamina.value = player.stamina
	_stamina.modulate.a = lerpf(_stamina.modulate.a, 0.0 if player.stamina > 98.0 else 0.8, minf(1.0, delta * 6.0))

	if _assist.visible:
		_assist_clock.text = GameClock.hhmm() + "   Day %d" % GameClock.day
		_assist_tide.text = "Tide: " + TideSystem.tide_label()
		_assist_level.text = "Water: %.2f m   (bars close at %.1f)" % [TideSystem.current_height, TideSystem.SANDBAR_CLOSED_AT]
		_assist_bar.value = TideSystem.current_height

func _refresh_log() -> void:
	var names := {"lighthouse": "Lantern Tower", "cottage": "Cottage", "shipwreck": "East Stack Wreck", "seacave": "Echo Cave"}
	var lines := ["Gannet Rock Log  %d / 4" % GameState.discovered.size()]
	for id in names:
		lines.append(("[x] " if GameState.discovered.has(id) else "[ ] ") + names[id])
	_assist_log.text = "\n".join(lines)

func _on_line(speaker: String, text: String, options: Array) -> void:
	_radio.visible = true
	_radio_speaker.text = speaker
	_radio_text.text = '"' + text + '"'
	_radio_opts.visible = options.size() > 0
	for i in 2:
		_opt_buttons[i].visible = i < options.size()
		if i < options.size():
			_opt_buttons[i].text = "%d  %s" % [i + 1, options[i].get("text", "")]

func _on_reply(speaker: String, text: String) -> void:
	_radio_speaker.text = speaker
	_radio_text.text = '"' + text + '"'
	_radio_opts.visible = false

func fade_out(duration := 0.7) -> void:
	create_tween().tween_property(_fade, "modulate:a", 1.0, duration)

func fade_in(duration := 0.9) -> void:
	create_tween().tween_property(_fade, "modulate:a", 0.0, duration)

func show_title(on: bool) -> void:
	_title.visible = on
