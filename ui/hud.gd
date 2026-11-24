class_name HUD extends CanvasLayer
## All UI built in code: reticle + prompt, binocular overlay, pocket watch,
## Assist-mode readout, radio panel, fade/respawn card, title card.

signal new_game_pressed
signal continue_pressed
signal settings_requested

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
var _watch_on := false
var _modal_scroll: ScrollContainer
signal ending_closed
var _ending_panel: ColorRect
var _ending_title: Label
var _ending_name: Label
var _ending_body: Label
var _ending_hint: Label
var _ending_open := false
var _ending_opened_at := 0.0
var _endings_label: Label
var _journal_page := -1          # -1 = not a journal modal; 0 log, 1 satchel, 2 tapes
var _tape_panel: PanelContainer
var _tape_title: Label
var _tape_text: Label

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
	_build_tape_panel()
	_build_card()
	_build_ending_card()
	_build_tutorial()
	_build_title()
	GameState.note_posted.connect(show_note)
	TapePlayer.started.connect(func(t): _tape_title.text = t; _tape_text.text = ""; _tape_panel.visible = true)
	TapePlayer.line_shown.connect(func(l): _tape_text.text = l)
	TapePlayer.finished.connect(func(_id): _tape_panel.visible = false)
	RadioSystem.line_shown.connect(_on_line)
	RadioSystem.reply_shown.connect(_on_reply)
	RadioSystem.hidden.connect(func(): _radio.visible = false)
	Settings.assist_changed.connect(func(on): _assist.visible = on)
	GameState.discovered_changed.connect(func(_id): _refresh_log())
	_assist.visible = Settings.assist_mode
	Settings.changed.connect(func(k: String):
		if k == "subtitle_scale":
			apply_text_scale())
	apply_text_scale()
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
	sb.set_content_margin_all(16)
	return sb

func _label(text: String, size := 14, color := Color("e8dfc8"), role := "ui") -> Label:
	var l := Label.new()
	l.text = text
	UiFonts.style(l, role, size)
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
	_bino_range = _label("Distance: --- m", 14, AMBER)
	_bino_range.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_bino_range.position = Vector2(-60, 40)
	_bino.add_child(_bino_range)
	_bino_label = _label("Scanning the horizon...", 14, AMBER)
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
	# Bottom-centre, growing upward, so tall text never runs off the screen.
	_radio.anchor_left = 0.5
	_radio.anchor_right = 0.5
	_radio.anchor_top = 1.0
	_radio.anchor_bottom = 1.0
	_radio.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_radio.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_radio.visible = false
	add_child(_radio)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_radio.add_child(v)
	_radio_speaker = _label("", 12, AMBER)
	_radio_text = _label("", 17)
	_radio_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_text.custom_minimum_size = Vector2(750, 0)
	_radio_opts = HBoxContainer.new()
	_radio_opts.add_theme_constant_override("separation", 10)
	for i in 2:
		var b := Button.new()
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(365, 0)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(RadioSystem.choose.bind(i))
		_radio_opts.add_child(b)
		_opt_buttons.append(b)
	for n in [_radio_speaker, _radio_text, _radio_opts]:
		v.add_child(n)
	_layout_radio()

## The radio panel widens with the subtitle size so large text still fits.
func _layout_radio() -> void:
	var k: float = float(Settings.v("subtitle_scale"))
	var w: float = clampf(780.0 + (k - 1.0) * 520.0, 780.0, 1220.0)
	_radio.offset_left = -w * 0.5
	_radio.offset_right = w * 0.5
	_radio.offset_bottom = -60.0
	_radio.offset_top = -60.0
	_radio.custom_minimum_size = Vector2(w, 0)
	_radio_text.custom_minimum_size = Vector2(w - 34.0, 0)
	for b in _opt_buttons:
		b.custom_minimum_size = Vector2((w - 44.0) * 0.5, 0)

func _build_fade() -> void:
	_fade = ColorRect.new()
	_full(_fade)
	_fade.color = Color("0b1117")
	_fade.modulate.a = 0.0
	add_child(_fade)
	_fade_label = _label("The tide caught you\n\nFreezing swells drove you back to the pier.", 20, AMBER)
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
	v.custom_minimum_size = Vector2(560, 0)
	_title_panel.add_child(v)
	var t := _label("Low Tide", 46, Color.WHITE, "display")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := _label("Gannet Rock Light Station, Maine coast, winter 1998", 13, Color("9aa7b0"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := _label("You are Arthur, winter keeper on a fog-bound island. Read the tide, cross the sandbars while they last, and be back on high ground before the Atlantic returns.", 14)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var b_new := Button.new()
	b_new.text = "New watch"
	b_new.pressed.connect(_open_tutorial)
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.pressed.connect(func():
		_title.visible = false
		continue_pressed.emit())
	_continue_btn.visible = SaveSystem.has_save()
	_endings_label = _label("", 12, Color("9aa7b0"))
	_endings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var seen: Array = SaveSystem.endings_seen()
	if seen.size() > 0:
		_endings_label.text = "Endings found: " + ", ".join(seen.map(func(k): return String(k).to_upper()))
	var b_settings := Button.new()
	b_settings.text = "Settings"
	b_settings.pressed.connect(func(): settings_requested.emit())
	for n in [t, sub, body, b_new, _continue_btn, b_settings, _endings_label]:
		v.add_child(n)

# --- setup / tutorial (shown before Arthur steps onto the island) -------

func _build_tutorial() -> void:
	_tut = PanelContainer.new()
	_tut.add_theme_stylebox_override("panel", _style(Color(0.06, 0.09, 0.12, 0.96), Color(0.85, 0.7, 0.42, 0.5)))
	_tut.set_anchors_preset(Control.PRESET_CENTER)
	_tut.custom_minimum_size = Vector2(860, 460)
	_tut.position = Vector2(-430, -230)
	_tut.visible = false
	_tut.z_index = 5
	add_child(_tut)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_tut.add_child(v)
	_tut_title = _label("", 26, Color.WHITE, "display")
	_tut_body = VBoxContainer.new()
	_tut_body.add_theme_constant_override("separation", 6)
	_tut_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_tut_back = Button.new()
	_tut_back.text = "Back"
	_tut_back.pressed.connect(func(): _tut_go(_tut_idx - 1))
	_tut_next = Button.new()
	_tut_next.pressed.connect(func(): _tut_go(_tut_idx + 1))
	row.add_child(_tut_back)
	row.add_child(_tut_next)
	for n in [_tut_title, _tut_body, row]:
		v.add_child(n)
	_tut_pages = TutorialData.pages()

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
		t.custom_minimum_size = Vector2(820, 0)
		_tut_body.add_child(t)
	_tut_back.text = "Back" if i > 0 else "Title"
	_tut_next.text = "Next" if i < _tut_pages.size() - 1 else "Step into the cottage"

# --- toasts, modal panel, day card --------------------------------------

func _build_toasts() -> void:
	_note = _label("", 17, Color("ffe9b8"))
	_note.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_note.position = Vector2(-380, -120)
	_note.size = Vector2(760, 30)
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
	_modal.custom_minimum_size = Vector2(780, 440)
	_modal.position = Vector2(-390, -240)
	_modal.visible = false
	_modal.z_index = 4
	add_child(_modal)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_modal.add_child(v)
	_modal_title = _label("", 24, Color("2b2418"), "display")
	_modal_body = _label("", 17, Color("2b2418"))
	_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_body.custom_minimum_size = Vector2(740, 0)
	_modal_scroll = ScrollContainer.new()
	_modal_scroll.custom_minimum_size = Vector2(760, 350)
	_modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll.add_child(_modal_body)
	v.add_child(_modal_title)
	v.add_child(_modal_scroll)
	v.add_child(_label("[E / Tab / Esc] close     [W / S or right stick] scroll", 12, Color("6a5a3a")))

func _open_modal(title: String, body: String) -> void:
	_modal_title.text = title
	_modal_body.text = body
	_modal_body.tab_stops = PackedFloat32Array()
	UiFonts.style(_modal_body, "paper", 26)       # journal entries and the tide table are handwritten
	_modal.visible = true
	_modal_scroll.scroll_vertical = 0
	modal_open = true
	_modal_frame = Engine.get_process_frames()
	player.ui_lock = true

func close_modal() -> void:
	_journal_page = -1
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
		lines.append("%s\t%d:%02d %s\t%.1f m" % ["High" if e["high"] else "Low", h12, m % 60, "pm" if h24 >= 12 else "am", e["height"]])
	lines.append("")
	lines.append("Sandbars close above 2.1 m.")
	_open_modal("Tide table, day %d" % day, "\n".join(lines))
	_modal_body.tab_stops = PackedFloat32Array([90.0, 240.0])

func _build_ending_card() -> void:
	_ending_panel = ColorRect.new()
	_ending_panel.color = Color(0.02, 0.03, 0.04, 1.0)
	_full(_ending_panel)
	_ending_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ending_panel.modulate.a = 0.0
	_ending_panel.visible = false
	_ending_panel.z_index = 8
	add_child(_ending_panel)
	var c := CenterContainer.new()
	_full(c)
	_ending_panel.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(760, 0)
	c.add_child(v)
	_ending_title = _label("Low Tide", 20, Color("9aa7b0"))
	_ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_name = _label("", 44, Color.WHITE, "display")
	_ending_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_body = _label("", 17, Color("d8dde2"))
	_ending_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_body.custom_minimum_size = Vector2(760, 0)
	_ending_hint = _label("[E]  return to title", 13, AMBER)
	_ending_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for n in [_ending_title, _ending_name, _ending_body, _ending_hint]:
		v.add_child(n)

func show_ending(letter: String, ending_name: String, body: String) -> void:
	_ending_title.text = "Low Tide: ending %s" % letter.to_upper()
	_ending_name.text = ending_name
	_ending_body.text = body
	_ending_panel.visible = true
	create_tween().tween_property(_ending_panel, "modulate:a", 1.0, 2.0)
	_ending_open = true
	_ending_opened_at = Time.get_ticks_msec() / 1000.0

func _build_tape_panel() -> void:
	_tape_panel = PanelContainer.new()
	_tape_panel.add_theme_stylebox_override("panel", _style(Color(0.1, 0.08, 0.06, 0.9), Color(0.7, 0.55, 0.3, 0.5)))
	_tape_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_tape_panel.custom_minimum_size = Vector2(720, 0)
	_tape_panel.position = Vector2(-360, 24)
	_tape_panel.visible = false
	add_child(_tape_panel)
	var v := VBoxContainer.new()
	_tape_panel.add_child(v)
	_tape_title = _label("", 12, Color("d9b26a"))
	_tape_text = _label("", 20, Color("f1e6cf"), "tape")
	_tape_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tape_text.custom_minimum_size = Vector2(690, 0)
	v.add_child(_tape_title)
	v.add_child(_tape_text)

## The journal: Log / Satchel / Tapes. Tab toggles; A/D (or stick) turn pages.
func toggle_logbook() -> void:
	if modal_open:
		close_modal()
		return
	_journal_page = 0
	_render_journal()

func _render_journal() -> void:
	var tabs := ["Log", "Satchel", "Tapes"]
	var head: Array = []
	for i in tabs.size():
		head.append("[ %s ]" % tabs[i] if i == _journal_page else tabs[i])
	var body: Array = []
	match _journal_page:
		0:
			for i in range(GameState.logbook.size() - 1, -1, -1):
				var e: Dictionary = GameState.logbook[i]
				body.append("Day %d\n%s\n" % [e["day"], e["text"]])
			if body.is_empty():
				body.append("No entries yet. Write one at the cottage desk each evening.")
		1:
			for id in GameState.items:
				body.append("%s\n   %s\n" % [Items.title(id), Items.desc(id)])
			if body.is_empty():
				body.append("The satchel is empty.")
		2:
			for id in GameState.items:
				if String(id).begins_with("tape_"):
					var tape := Conversations.tape(id)
					body.append(String(tape.get("title", id)))
					if TapePlayer.is_heard(id):
						for l in tape.get("lines", []):
							body.append("   " + String(l["text"]))
					else:
						body.append("   (not yet played)")
					body.append("")
			if body.is_empty():
				body.append("No tapes yet.")
	_open_modal("Keeper's journal     " + "   ".join(head) + "     (A / D to turn)", "\n".join(body))

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
	_card_title = _label("", 56, Color.WHITE, "display")
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
	if player == null or get_tree().paused:
		return
	_place_note()
	if Input.is_action_just_pressed("toggle_assist"):
		Settings.assist_mode = not Settings.assist_mode
	if Settings.v("toggle_watch"):
		if Input.is_action_just_pressed("watch"):
			_watch_on = not _watch_on
	else:
		_watch_on = Input.is_action_pressed("watch")
	_watch.visible = _watch_on or Settings.assist_mode
	if Input.is_action_just_pressed("logbook") and not _title.visible:
		toggle_logbook()
	if modal_open and Engine.get_process_frames() > _modal_frame:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("radio_dismiss"):
			close_modal()
	if modal_open and _journal_page >= 0 and Engine.get_process_frames() > _modal_frame:
		if Input.is_action_just_pressed("move_right"):
			_journal_page = (_journal_page + 1) % 3
			_render_journal()
		elif Input.is_action_just_pressed("move_left"):
			_journal_page = (_journal_page + 2) % 3
			_render_journal()
	if modal_open:
		var dir := Input.get_axis("move_forward", "move_back") + Input.get_axis("look_up", "look_down")
		if dir != 0.0:
			_modal_scroll.scroll_vertical += int(clampf(dir, -1.0, 1.0) * 700.0 * delta)
	if _ending_open and Time.get_ticks_msec() / 1000.0 - _ending_opened_at > 2.5 and Input.is_action_just_pressed("interact"):
		_ending_open = false
		ending_closed.emit()
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
		_bino_range.text = "Distance: %d m" % player.bino_dist if player.bino_dist >= 0 else "Distance: --- m"
		_bino_label.text = player.bino_label if player.bino_label != "" else "Scanning the horizon..."
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
	var names := {"lighthouse": "Lantern Tower", "cottage": "Cottage", "shipwreck": "East Stack Wreck", "seacave": "Echo Cave", "cable": "North Cove Cable", "vault": "Reef Cable Vault"}
	var found := 0
	for id in names:
		if GameState.discovered.has(id):
			found += 1
	var lines := ["Gannet Rock Log  %d / %d" % [found, names.size()]]
	for id in names:
		lines.append(("[x] " if GameState.discovered.has(id) else "[ ] ") + names[id])
	_assist_log.text = "\n".join(lines)

## Toasts sit just above the radio panel when it is up, so they never overlap it.
func _place_note() -> void:
	var vh: float = get_viewport().get_visible_rect().size.y
	var y: float = vh - 120.0
	if _radio.visible:
		y = minf(y, _radio.global_position.y - _note.size.y - 12.0)
	_note.position.y = y

## Radio, tape and toast text follow the "subtitle size" accessibility setting.
func apply_text_scale() -> void:
	var k: float = float(Settings.v("subtitle_scale"))
	_radio_speaker.add_theme_font_size_override("font_size", int(12 * k))
	_radio_text.add_theme_font_size_override("font_size", int(17 * k))
	for b in _opt_buttons:
		b.add_theme_font_size_override("font_size", int(14 * k))
	_tape_title.add_theme_font_size_override("font_size", int(12 * k))
	_tape_text.add_theme_font_size_override("font_size", int(20 * k))
	_note.add_theme_font_size_override("font_size", int(17 * k))
	_layout_radio()

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
