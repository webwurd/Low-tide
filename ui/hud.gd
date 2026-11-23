class_name HUD extends CanvasLayer
## All UI built in code: reticle + prompt, binocular overlay, pocket watch,
## Assist-mode readout, radio panel, fade/respawn card, title card.

signal new_game_pressed
signal continue_pressed

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
var _note: Label
var _note_t := 0.0
var _hold_bar: ProgressBar
var _modal: PanelContainer
var _modal_title: Label
var _modal_body: Label
var _modal_frame := -1
var _card: Control
var _card_title: Label
var _card_sub: Label
var _tut_pages: Array = []
var _tut_idx := 0
var _tut: PanelContainer
var _tut_title: Label
var _tut_body: VBoxContainer
var _tut_next: Button
var _tut_back: Button
var _title_panel: PanelContainer
var _continue_btn: Button
var modal_open := false

func _ready() -> void:
	layer = 10
	_build_reticle()
	_build_binoculars()
	_build_watch()
	_build_assist()
	_build_radio()
	_build_fade()
	_build_toasts()
	_build_modal()
	_build_card()
	_build_tutorial()
	_build_title()
	GameState.note_posted.connect(show_note)
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
	_title_panel = PanelContainer.new()
	_title_panel.add_theme_stylebox_override("panel", _style(CARD_BG, Color(0.85, 0.7, 0.42, 0.5)))
	c.add_child(_title_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(480, 0)
	_title_panel.add_child(v)
	var t := _label("LOW TIDE", 40, Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := _label("GANNET ROCK LIGHT STATION - MAINE COAST, WINTER 1998", 12, Color("9aa7b0"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := _label("You are Arthur, winter keeper on a fog-bound island. Read the tide, cross the sandbars while they last, and be back on high ground before the Atlantic returns.", 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var b_new := Button.new()
	b_new.text = "NEW WATCH"
	b_new.pressed.connect(_open_tutorial)
	_continue_btn = Button.new()
	_continue_btn.text = "CONTINUE"
	_continue_btn.pressed.connect(func():
		_title.visible = false
		continue_pressed.emit())
	_continue_btn.visible = SaveSystem.has_save()
	for n in [t, sub, body, b_new, _continue_btn]:
		v.add_child(n)

# --- setup / tutorial (shown before Arthur steps onto the island) -------

func _build_tutorial() -> void:
	_tut = PanelContainer.new()
	_tut.add_theme_stylebox_override("panel", _style(Color(0.06, 0.09, 0.12, 0.96), Color(0.85, 0.7, 0.42, 0.5)))
	_tut.set_anchors_preset(Control.PRESET_CENTER)
	_tut.custom_minimum_size = Vector2(760, 440)
	_tut.position = Vector2(-380, -220)
	_tut.visible = false
	_tut.z_index = 5
	add_child(_tut)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_tut.add_child(v)
	_tut_title = _label("", 24, Color.WHITE)
	_tut_body = VBoxContainer.new()
	_tut_body.add_theme_constant_override("separation", 6)
	_tut_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_tut_back = Button.new()
	_tut_back.text = "BACK"
	_tut_back.pressed.connect(func(): _tut_go(_tut_idx - 1))
	_tut_next = Button.new()
	_tut_next.pressed.connect(func(): _tut_go(_tut_idx + 1))
	row.add_child(_tut_back)
	row.add_child(_tut_next)
	for n in [_tut_title, _tut_body, row]:
		v.add_child(n)
	_tut_pages = [
		{"title": "1 / 3   Moving about", "rows": [
			["ACTION", "KEYBOARD + MOUSE", "GAMEPAD"],
			["Walk", "W A S D", "Left stick"],
			["Look", "Mouse", "Right stick"],
			["Brisk walk (uses stamina)", "Hold Shift", "Press L3"],
			["Inspect / use", "E  (hold for winding & lighting)", "A  (hold)"],
			["Release the mouse / pause", "Esc", "Start"],
		], "text": ""},
		{"title": "2 / 3   Your tools", "rows": [
			["ACTION", "KEYBOARD + MOUSE", "GAMEPAD"],
			["Pocket watch (hold)", "Q", "Left bumper"],
			["Binoculars (hold)", "Right mouse  or  B", "Left trigger"],
			["Radio: answer 1 / 2", "1  /  2", "D-pad left / right"],
			["Radio: dismiss", "X", "B"],
			["Keeper's log", "Tab", "View / Back"],
			["Assist readout (clock + tide)", "F1", "Y"],
		], "text": ""},
		{"title": "3 / 3   A day on Gannet Rock", "rows": [], "text":
			"MORNING   Brew the coffee, read the barometer and the tide table, wind the clockwork weights in the lighthouse, then check in with Clara on the radio. Time stands still while you are indoors.\n\n" +
			"EXPEDITION   Step outside and the clock runs: one game minute per second. Sandbars appear at low water and drown above two metres. Watch the pocket watch and the painted tide marks on the pier pilings. If the sea catches you, you lose time, not the game.\n\n" +
			"EVENING   Light the lamp in the lantern room, write the log at the cottage desk, call Clara, and turn in. Sitting in the armchair or on the lantern bench lets you wait for the tide."},
	]

func _open_tutorial() -> void:
	_title_panel.visible = false
	_tut.visible = true
	_tut_go(0)

func _tut_go(i: int) -> void:
	if i < 0:
		_tut.visible = false
		_title_panel.visible = true
		return
	if i >= _tut_pages.size():
		_tut.visible = false
		_title.visible = false
		new_game_pressed.emit()
		return
	_tut_idx = i
	var pg: Dictionary = _tut_pages[i]
	_tut_title.text = pg["title"]
	for ch in _tut_body.get_children():
		ch.queue_free()
	var rows: Array = pg["rows"]
	if rows.size() > 0:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 28)
		grid.add_theme_constant_override("v_separation", 8)
		for r in rows.size():
			for cell in rows[r]:
				grid.add_child(_label(cell, 15, AMBER if r == 0 else Color("e8dfc8")))
		_tut_body.add_child(grid)
	if pg["text"] != "":
		var t := _label(pg["text"], 15)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(720, 0)
		_tut_body.add_child(t)
	_tut_back.text = "BACK" if i > 0 else "TITLE"
	_tut_next.text = "NEXT" if i < _tut_pages.size() - 1 else "STEP INTO THE COTTAGE"

# --- toasts, modal panel, day card --------------------------------------

func _build_toasts() -> void:
	_note = _label("", 17, Color("ffe9b8"))
	_note.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_note.position = Vector2(-300, -120)
	_note.size = Vector2(600, 30)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_note.add_theme_constant_override("shadow_offset_x", 1)
	_note.add_theme_constant_override("shadow_offset_y", 1)
	_note.modulate.a = 0.0
	add_child(_note)
	_hold_bar = ProgressBar.new()
	_hold_bar.set_anchors_preset(Control.PRESET_CENTER)
	_hold_bar.position = Vector2(-70, 62)
	_hold_bar.size = Vector2(140, 6)
	_hold_bar.show_percentage = false
	_hold_bar.max_value = 1.0
	_hold_bar.visible = false
	add_child(_hold_bar)

func show_note(text: String) -> void:
	_note.text = text
	_note.modulate.a = 1.0
	_note_t = 3.5 + text.length() * 0.03

func _build_modal() -> void:
	_modal = PanelContainer.new()
	_modal.add_theme_stylebox_override("panel", _style(Color("e8dfc8"), Color("8a7448")))
	_modal.set_anchors_preset(Control.PRESET_CENTER)
	_modal.custom_minimum_size = Vector2(520, 360)
	_modal.position = Vector2(-260, -200)
	_modal.visible = false
	_modal.z_index = 4
	add_child(_modal)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_modal.add_child(v)
	_modal_title = _label("", 22, Color("2b2418"))
	_modal_body = _label("", 17, Color("2b2418"))
	_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_body.custom_minimum_size = Vector2(480, 0)
	v.add_child(_modal_title)
	v.add_child(_modal_body)
	v.add_child(_label("[E / Tab / Esc] close", 12, Color("6a5a3a")))

func _open_modal(title: String, body: String) -> void:
	_modal_title.text = title
	_modal_body.text = body
	_modal.visible = true
	modal_open = true
	_modal_frame = Engine.get_process_frames()
	player.ui_lock = true

func close_modal() -> void:
	_modal.visible = false
	modal_open = false
	if player:
		player.ui_lock = false

func show_tide_table(day: int, extremes: Array) -> void:
	var lines: Array = []
	for e in extremes:
		var m := int(e["minute"])
		var h24 := m / 60
		var h12 := h24 % 12
		if h12 == 0: h12 = 12
		lines.append("%s   %02d:%02d %s     %.1f m" % ["HIGH" if e["high"] else "LOW ", h12, m % 60, "PM" if h24 >= 12 else "AM", e["height"]])
	lines.append("")
	lines.append("Sandbars close above 2.1 m.")
	_open_modal("TIDE TABLE   -   Day %d" % day, "\n".join(lines))

func toggle_logbook() -> void:
	if modal_open:
		close_modal()
		return
	var lines: Array = []
	for i in range(GameState.logbook.size() - 1, -1, -1):
		var e: Dictionary = GameState.logbook[i]
		lines.append("DAY %d\n%s\n" % [e["day"], e["text"]])
	if lines.is_empty():
		lines.append("No entries yet. Write one at the cottage desk each evening.")
	_open_modal("KEEPER'S LOG", "\n".join(lines))

func _build_card() -> void:
	_card = Control.new()
	_full(_card)
	_card.modulate.a = 0.0
	_card.z_index = 3
	add_child(_card)
	var c := CenterContainer.new()
	_full(c)
	c.offset_top = -190.0
	c.offset_bottom = -190.0
	_card.add_child(c)
	var v := VBoxContainer.new()
	c.add_child(v)
	_card_title = _label("", 44, Color.WHITE)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_sub = _label("", 16, AMBER)
	_card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_card_title)
	v.add_child(_card_sub)

func show_card(title: String, sub: String, seconds := 3.0) -> void:
	_card_title.text = title
	_card_sub.text = sub
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.6)
	tw.tween_interval(seconds)
	tw.tween_property(_card, "modulate:a", 0.0, 1.0)

# --- runtime -----------------------------------------------------------

func _process(delta: float) -> void:
	if player == null:
		return
	if Input.is_action_just_pressed("toggle_assist"):
		Settings.assist_mode = not Settings.assist_mode
	_watch.visible = Input.is_action_pressed("watch") or Settings.assist_mode
	if Input.is_action_just_pressed("logbook") and not _title.visible:
		toggle_logbook()
	if modal_open and Engine.get_process_frames() > _modal_frame:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("radio_dismiss"):
			close_modal()
	_hold_bar.visible = player.hold_progress > 0.0
	_hold_bar.value = player.hold_progress
	if _note_t > 0.0:
		_note_t -= delta
		if _note_t < 0.8:
			_note.modulate.a = maxf(0.0, _note_t / 0.8)
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
		_prompt.text = ("[hold E]  " if player.nearby.hold_time > 0.0 else "[E]  ") + player.nearby.get_title()
	_stamina.value = player.stamina
	_stamina.modulate.a = lerpf(_stamina.modulate.a, 0.0 if player.stamina > 98.0 else 0.8, minf(1.0, delta * 6.0))

	if _assist.visible:
		_assist_clock.text = GameClock.hhmm() + "   Day %d" % GameClock.day
		_assist_tide.text = "Tide: " + TideSystem.tide_label()
		_assist_level.text = "Water: %.2f m   (bars close at %.1f)" % [TideSystem.current_height, TideSystem.SANDBAR_CLOSED_AT]
		_assist_bar.value = TideSystem.current_height

func refresh_log() -> void:
	_refresh_log()

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
