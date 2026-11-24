class_name HUD extends CanvasLayer
## All UI built in code: reticle + prompt, binocular overlay, pocket watch,
## Assist-mode readout, radio panel, fade/respawn card, title card.

signal new_game_pressed
signal continue_pressed
signal settings_requested

const AMBER := Color("ffb84d")
const CARD_BG := Color(0.07, 0.1, 0.13, 0.88)
const INK := Color("101a21")
const CREAM := Color("efe4c8")
const POSTER_TEAL := Color("1f4b52")
const POSTER_BRASS := Color("d9a441")      # thin rules only
const TYPE_CPS := 55.0                     # radio text types in at about reading speed
# Radio panel (sizes at subtitle scale 1.0; apply_text_scale() multiplies them).
const RADIO_SPEAKER_SIZE := 15
const RADIO_TEXT_SIZE := 21
const RADIO_OPT_SIZE := 18
const RADIO_PAD := Vector2(32, 24)
const RADIO_WIDTH := 860.0
const RADIO_GAP := 12                      # between speaker, text and replies
const TAPE_TITLE_SIZE := 14
const TAPE_TEXT_SIZE := 22
const NOTE_SIZE := 18
const PROMPT_SIZE := 17

var player: Player
var _reticle: Control
var _prompt: Label
var _prompt_box: Control
var _prompt_key: Label
var _note_box: PanelContainer
var _pad_input := false           # last input came from a gamepad (prompts show A, not E)
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
var _modal_tabs: HBoxContainer
var _modal_hint: Label
var _modal_body: Label
var _modal_frame := -1
var _card: Control
var _card_band: ColorRect
var _banner: Control
var _banner_tween: Tween
var _type_tween: Tween
var _card_title: Label
var _card_sub: Label
var _tut_pages: Array = []
var _tut_idx := 0
var _tut: PanelContainer
var _tut_title: Label
var _tut_body: VBoxContainer
var _tut_next: Button
var _tut_device := ""
var _tut_back: Button
var _title_panel: Control
var title_screen: TitleScreen
var prologue: ProloguePlayer
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
	_build_banner()
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

func _flat_box(bg: Color, left_accent := Color(0, 0, 0, 0), margin_h := 16, margin_v := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = left_accent
	sb.border_width_left = 3 if left_accent.a > 0.0 else 0
	sb.set_corner_radius_all(2)
	sb.content_margin_left = margin_h
	sb.content_margin_right = margin_h
	sb.content_margin_top = margin_v
	sb.content_margin_bottom = margin_v
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
	# Interaction prompt: a frosted pill under the reticle with a key cap.
	var kit := UiTheme.glass_panel(Vector2(16, 8), 999)
	_prompt_box = kit[0]
	_prompt_box.anchor_left = 0.5
	_prompt_box.anchor_right = 0.5
	_prompt_box.anchor_top = 0.5
	_prompt_box.anchor_bottom = 0.5
	_prompt_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_box.offset_top = 30.0
	_prompt_box.offset_bottom = 30.0
	_prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_box.visible = false
	_reticle.add_child(_prompt_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	(kit[1] as Control).add_child(row)
	var cap := PanelContainer.new()
	var cap_sb := StyleBoxFlat.new()
	cap_sb.bg_color = Color(1, 0.96, 0.88, 0.92)
	cap_sb.set_corner_radius_all(5)
	cap_sb.content_margin_left = 8
	cap_sb.content_margin_right = 8
	cap_sb.content_margin_top = 1
	cap_sb.content_margin_bottom = 1
	cap.add_theme_stylebox_override("panel", cap_sb)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_prompt_key = _label("E", 15, Color("1c140a"), "ui_bold")
	cap.add_child(_prompt_key)
	row.add_child(cap)
	_prompt = _label("", PROMPT_SIZE, UiTheme.CREAM)
	row.add_child(_prompt)

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
	var akit := UiTheme.glass_panel(Vector2(20, 16))
	_assist = akit[0]
	_assist.position = Vector2(24, 24)
	_assist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_assist)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	(akit[1] as Control).add_child(v)
	_assist_clock = _label("", 20, UiTheme.CREAM, "ui_bold")
	_assist_tide = _label("", 15, UiTheme.CREAM)
	_assist_level = _label("", 15, UiTheme.CREAM)
	_assist_bar = ProgressBar.new()
	_bar_style(_assist_bar, 8)
	_assist_bar.custom_minimum_size = Vector2(220, 8)
	_assist_bar.max_value = 4.6
	_assist_bar.min_value = -0.4
	_assist_bar.show_percentage = false
	_assist_log = _label("", 14, UiTheme.MUTED)
	for n in [_assist_clock, _assist_tide, _assist_level, _assist_bar, _assist_log]:
		v.add_child(n)
	_stamina = ProgressBar.new()
	_bar_style(_stamina, 5)
	_stamina.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stamina.position = Vector2(24, -28)
	_stamina.size = Vector2(180, 5)
	_stamina.show_percentage = false
	_stamina.max_value = 100
	_stamina.modulate.a = 0.0
	add_child(_stamina)

func _build_radio() -> void:
	# A frosted glass panel: the scene shows through, blurred, so the text
	# stays legible over sky or snow without a heavy slab.
	var kit := UiTheme.glass_panel(RADIO_PAD)
	_radio = kit[0]
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
	v.add_theme_constant_override("separation", RADIO_GAP)
	(kit[1] as Control).add_child(v)
	# Header: a small amber "on air" light and the speaker.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var dot := ColorRect.new()
	dot.color = UiTheme.ACCENT
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(dot)
	_radio_speaker = _label("", RADIO_SPEAKER_SIZE, UiTheme.ACCENT, "ui_bold")
	head.add_child(_radio_speaker)
	_radio_text = _label("", RADIO_TEXT_SIZE, UiTheme.CREAM)
	_radio_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	_radio_text.add_theme_constant_override("shadow_offset_y", 1)
	_radio_text.add_theme_constant_override("line_spacing", 5)
	_radio_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_opts = HBoxContainer.new()
	_radio_opts.add_theme_constant_override("separation", RADIO_GAP)
	for i in 2:
		var b := Button.new()
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_vertical = Control.SIZE_FILL
		UiTheme.style_button(b, "choice", RADIO_OPT_SIZE)
		b.pressed.connect(RadioSystem.choose.bind(i))
		_radio_opts.add_child(b)
		_opt_buttons.append(b)
	for n in [head, _radio_text, _radio_opts]:
		v.add_child(n)
	_layout_radio()

## The radio panel widens with the subtitle size so large text still fits.
func _layout_radio() -> void:
	var k: float = float(Settings.v("subtitle_scale"))
	var w: float = clampf(RADIO_WIDTH + (k - 1.0) * 480.0, RADIO_WIDTH, 1220.0)
	_radio.offset_left = -w * 0.5
	_radio.offset_right = w * 0.5
	_radio.offset_bottom = -56.0
	_radio.offset_top = -56.0
	_radio.custom_minimum_size = Vector2(w, 0)
	var inner := w - RADIO_PAD.x * 2.0
	_radio_text.custom_minimum_size = Vector2(inner, 0)
	for b in _opt_buttons:
		b.custom_minimum_size = Vector2((inner - RADIO_GAP) * 0.5, 0)

## "New radio message": a small padded tag at the top of the screen on a solid
## colour, so it reads as a notice rather than part of the world.
func _build_banner() -> void:
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiTheme.pill(Color(POSTER_TEAL.r, POSTER_TEAL.g, POSTER_TEAL.b, 0.96), Vector2(20, 12)))
	tag.anchor_left = 0.5
	tag.anchor_right = 0.5
	tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tag.offset_top = 28.0
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.z_index = 6
	tag.visible = false
	add_child(tag)
	_banner = tag
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	tag.add_child(row)
	var dot := ColorRect.new()                          # small brass indicator light
	dot.color = UiTheme.ACCENT
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dot)
	row.add_child(_label("New radio message", 22, CREAM, "display"))

func show_banner() -> void:
	var calm: bool = Settings.v("reduce_motion")
	_banner.visible = true
	_banner.offset_top = 28.0 if calm else 8.0
	_banner.modulate.a = 1.0 if calm else 0.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	if not calm:
		_banner_tween.set_parallel(true)
		_banner_tween.tween_property(_banner, "offset_top", 28.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.25)
		_banner_tween.set_parallel(false)
	_banner_tween.tween_interval(1.8)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.35)
	_banner_tween.tween_callback(func(): _banner.visible = false)

func _type_in(text: String) -> void:
	_radio_text.text = '"' + text + '"'
	if _type_tween:
		_type_tween.kill()
	if Settings.v("reduce_motion"):
		_radio_text.visible_characters = -1
		return
	_radio_text.visible_characters = 0
	_type_tween = create_tween()
	_type_tween.tween_property(_radio_text, "visible_characters", _radio_text.text.length(), _radio_text.text.length() / TYPE_CPS)
	_type_tween.tween_callback(func(): _radio_text.visible_characters = -1)

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

func _title_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	UiFonts.style(b, "display", 32)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", AMBER)
	b.add_theme_color_override("font_focus_color", AMBER)
	b.add_theme_color_override("font_pressed_color", POSTER_BRASS)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	return b

## Title: a live view of Gannet Rock at dusk (Main drives the backdrop) with
## the menu column on the left (ui/title_screen.gd). New watch plays the
## prologue (ui/prologue_player.gd), then the setup tutorial.
func _build_title() -> void:
	title_screen = TitleScreen.new()
	title_screen.z_index = 4
	add_child(title_screen)
	_title = title_screen
	_title_panel = title_screen.panel
	_continue_btn = title_screen.continue_btn
	_endings_label = title_screen.endings_label
	var seen: Array = SaveSystem.endings_seen()
	if seen.size() > 0:
		_endings_label.text = "Endings found: " + ", ".join(seen.map(func(k): return String(k).to_upper()))
	title_screen.new_watch.connect(_start_prologue)
	title_screen.continue_game.connect(func():
		_title.visible = false
		continue_pressed.emit())
	title_screen.settings.connect(func(): settings_requested.emit())
	prologue = ProloguePlayer.new()
	prologue.z_index = 5
	add_child(prologue)
	prologue.finished.connect(_open_tutorial)

func _start_prologue() -> void:
	_title.visible = false
	prologue.play()

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
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_tut_back = _tut_button("Back", Vector2(150, 56), false)
	_tut_back.pressed.connect(func(): _tut_go(_tut_idx - 1))
	_tut_next = _tut_button("Next", Vector2(280, 56), true)
	_tut_next.pressed.connect(func(): _tut_go(_tut_idx + 1))
	row.add_child(_tut_back)
	row.add_child(_tut_next)
	for n in [_tut_title, _tut_body, row]:
		v.add_child(n)
	_tut_pages = TutorialData.pages_for("kb")

## A clearly visible button: filled, with a hover and focus state, sized to be easy to hit.
func _tut_button(text: String, min_size: Vector2, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	UiFonts.style(b, "ui_bold", 20 if primary else 17)
	var fill := Color(0.85, 0.62, 0.22, 0.95) if primary else Color(1, 1, 1, 0.10)
	var hover := Color(0.95, 0.72, 0.3, 1.0) if primary else Color(1, 1, 1, 0.2)
	var text_col := Color("1a1308") if primary else CREAM
	b.add_theme_color_override("font_color", text_col)
	b.add_theme_color_override("font_hover_color", text_col)
	b.add_theme_color_override("font_focus_color", text_col)
	b.add_theme_color_override("font_pressed_color", text_col)
	b.add_theme_stylebox_override("normal", _flat_box(fill, Color(0, 0, 0, 0), 20, 12))
	b.add_theme_stylebox_override("hover", _flat_box(hover, Color(0, 0, 0, 0), 20, 12))
	b.add_theme_stylebox_override("pressed", _flat_box(hover, Color(0, 0, 0, 0), 20, 12))
	var focus := _flat_box(hover, Color(0, 0, 0, 0), 20, 12)
	focus.set_border_width_all(2)
	focus.border_color = Color.WHITE
	b.add_theme_stylebox_override("focus", focus)
	return b

func _open_tutorial() -> void:
	_title.visible = true
	_title_panel.visible = false
	_tut.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE      # the buttons need a cursor
	_tut_device = ""
	_tut_go(0)

## Prompts show the key for whatever the player last touched.
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.4):
		_pad_input = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_pad_input = false

## Esc / B steps back through the setup pages, so there is always a way out.
func _unhandled_input(event: InputEvent) -> void:
	if _tut != null and _tut.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tut_go(_tut_idx - 1)

func _tut_pick(device: String) -> void:
	_tut_device = device
	_tut_pages = TutorialData.pages_for(device)
	_tut_go(1)

## Page 0 asks how the player is playing; pages 1..n show only that device's controls.
func _tut_go(i: int) -> void:
	if i < 0:
		_tut.visible = false
		_title_panel.visible = true
		return
	if i > 0 and i - 1 >= _tut_pages.size():
		_tut.visible = false
		_title.visible = false
		new_game_pressed.emit()
		return
	_tut_idx = i
	for ch in _tut_body.get_children():
		ch.queue_free()
	_tut_back.text = "Back" if i > 0 else "Title"
	if i == 0:
		_tut_title.text = "How are you playing?"
		_tut_next.visible = false
		var intro := _label("Pick one and the next pages show only those controls. You can change this any time in Settings.", 16, Color("cfd6d6"))
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intro.custom_minimum_size = Vector2(820, 0)
		_tut_body.add_child(intro)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 24)
		_tut_body.add_child(gap)
		var choices := HBoxContainer.new()
		choices.alignment = BoxContainer.ALIGNMENT_CENTER
		choices.add_theme_constant_override("separation", 24)
		var kb := _tut_button("Keyboard and mouse", Vector2(320, 84), true)
		kb.pressed.connect(_tut_pick.bind("kb"))
		var pad := _tut_button("Gamepad", Vector2(320, 84), true)
		pad.pressed.connect(_tut_pick.bind("pad"))
		choices.add_child(kb)
		choices.add_child(pad)
		_tut_body.add_child(choices)
		kb.grab_focus.call_deferred()
		return
	var pg: Dictionary = _tut_pages[i - 1]
	_tut_title.text = pg["title"]
	_tut_next.visible = true
	var rows: Array = pg["rows"]
	if rows.size() > 0:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 48)
		grid.add_theme_constant_override("v_separation", 10)
		for r in rows.size():
			for cell in rows[r]:
				grid.add_child(_label(cell, 17, AMBER if r == 0 else Color("e8dfc8")))
		_tut_body.add_child(grid)
	if pg["text"] != "":
		var t := _label(pg["text"], 16)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(820, 0)
		_tut_body.add_child(t)
	_tut_next.text = "Next" if i < _tut_pages.size() else "Step into the cottage"
	_tut_next.grab_focus.call_deferred()      # Enter / Space / A advance without the mouse

# --- toasts, modal panel, day card --------------------------------------

func _build_toasts() -> void:
	# Arthur's short inner-voice notes: a frosted pill, bottom centre.
	var nkit := UiTheme.glass_panel(Vector2(26, 12), 999)
	_note_box = nkit[0]
	_note_box.anchor_left = 0.5
	_note_box.anchor_right = 0.5
	_note_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_note_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_box.modulate.a = 0.0
	add_child(_note_box)
	_note = _label("", NOTE_SIZE, Color("ffe9c4"))
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(nkit[1] as Control).add_child(_note)
	_hold_bar = ProgressBar.new()
	_bar_style(_hold_bar, 6)
	_hold_bar.set_anchors_preset(Control.PRESET_CENTER)
	_hold_bar.position = Vector2(-80, 78)
	_hold_bar.size = Vector2(160, 6)
	_hold_bar.show_percentage = false
	_hold_bar.max_value = 1.0
	_hold_bar.visible = false
	add_child(_hold_bar)

## Rounded track + amber fill for the small progress bars.
func _bar_style(bar: ProgressBar, h: int) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.38)
	bg.set_corner_radius_all(h)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiTheme.ACCENT
	fill.set_corner_radius_all(h)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

func show_note(text: String) -> void:
	_note.text = text
	# Short notes hug their text; long ones wrap at a readable width.
	var w: float = minf(_note.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _note.get_theme_font_size("font_size")).x + 4.0, 720.0)
	_note.custom_minimum_size = Vector2(w, 0)
	_place_note()
	_note_box.modulate.a = 1.0
	_note_t = 3.5 + text.length() * 0.03

## The journal and the tide table: a sheet of paper Arthur holds up. Title
## and tab chips on top, a ruled line, the handwritten page, key hints below.
func _build_modal() -> void:
	_modal = PanelContainer.new()
	_modal.add_theme_stylebox_override("panel", UiTheme.paper())
	_modal.anchor_left = 0.5
	_modal.anchor_right = 0.5
	_modal.anchor_top = 0.5
	_modal.anchor_bottom = 0.5
	_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	_modal.offset_left = -430.0
	_modal.offset_right = 430.0
	_modal.offset_top = -255.0
	_modal.offset_bottom = 255.0
	_modal.visible = false
	_modal.z_index = 4
	add_child(_modal)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_modal.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_modal_title = _label("", 32, UiTheme.PAPER_INK, "display")
	_modal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_modal_title)
	_modal_tabs = HBoxContainer.new()
	_modal_tabs.add_theme_constant_override("separation", 6)
	_modal_tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for t in ["Log", "Satchel", "Tapes"]:
		var chip := PanelContainer.new()
		chip.add_child(_label(t, 15, UiTheme.PAPER_INK, "ui_bold"))
		_modal_tabs.add_child(chip)
	head.add_child(_modal_tabs)
	var rule := ColorRect.new()
	rule.color = UiTheme.PAPER_EDGE
	rule.custom_minimum_size = Vector2(0, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_body = _label("", 17, UiTheme.PAPER_INK)
	_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_body.custom_minimum_size = Vector2(740, 0)
	_modal_scroll = ScrollContainer.new()
	_modal_scroll.custom_minimum_size = Vector2(760, 330)
	_modal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll.add_child(_modal_body)
	_modal_hint = _label("", 14, Color(0.4, 0.33, 0.22))
	for n in [head, rule, _modal_scroll, _modal_hint]:
		v.add_child(n)

## Highlights the current journal page's chip (ink fill), or hides the chips.
func _set_tabs(page: int) -> void:
	_modal_tabs.visible = page >= 0
	for i in _modal_tabs.get_child_count():
		var chip := _modal_tabs.get_child(i) as PanelContainer
		var on := i == page
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiTheme.PAPER_INK if on else Color(0, 0, 0, 0)
		sb.border_color = UiTheme.PAPER_INK if on else UiTheme.PAPER_EDGE
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(999)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 3
		sb.content_margin_bottom = 4
		chip.add_theme_stylebox_override("panel", sb)
		(chip.get_child(0) as Label).add_theme_color_override("font_color", UiTheme.PAPER if on else Color(UiTheme.PAPER_INK, 0.7))

func _open_modal(title: String, body: String) -> void:
	_modal_title.text = title
	_set_tabs(_journal_page)
	var keys := "Close   E · Tab · Esc        Scroll   W / S"
	_modal_hint.text = keys + ("        Turn page   A / D" if _journal_page >= 0 else "")
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
	_ending_title = _label("Low Tide", 16, UiTheme.MUTED, "ui_bold")
	_ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_name = _label("", 44, Color.WHITE, "display")
	_ending_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_body = _label("", 19, Color("dde1e4"))
	_ending_body.add_theme_constant_override("line_spacing", 4)
	_ending_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_body.custom_minimum_size = Vector2(760, 0)
	_ending_hint = _label("E   Return to title", 15, UiTheme.CREAM, "ui_bold")
	_ending_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint_pill := PanelContainer.new()
	hint_pill.add_theme_stylebox_override("panel", UiTheme.pill(Color(1, 1, 1, 0.08)))
	hint_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint_pill.add_child(_ending_hint)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	for n in [_ending_title, _ending_name, _ending_body, gap, hint_pill]:
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
	# Tape subtitles: frosted glass at the top, a different voice from the radio.
	var kit := UiTheme.glass_panel(Vector2(28, 18), UiTheme.RADIUS, Color(0.07, 0.055, 0.04, 0.66))
	_tape_panel = kit[0]
	_tape_panel.anchor_left = 0.5
	_tape_panel.anchor_right = 0.5
	_tape_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tape_panel.offset_left = -390.0
	_tape_panel.offset_right = 390.0
	_tape_panel.offset_top = 26.0
	_tape_panel.visible = false
	add_child(_tape_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	(kit[1] as Control).add_child(v)
	_tape_title = _label("", TAPE_TITLE_SIZE, Color("e2bd78"), "ui_bold")
	_tape_text = _label("", TAPE_TEXT_SIZE, Color("f4ead6"), "tape")
	_tape_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tape_text.custom_minimum_size = Vector2(724, 0)
	_tape_text.add_theme_constant_override("line_spacing", 4)
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
	_open_modal("Keeper's journal", "\n".join(body))

## Day cards: a bold band across the screen with big display type.
func _build_card() -> void:
	_card = Control.new()
	_full(_card)
	_card.modulate.a = 0.0
	_card.z_index = 3
	add_child(_card)
	_card_band = ColorRect.new()
	_card_band.color = Color(POSTER_TEAL.r, POSTER_TEAL.g, POSTER_TEAL.b, 0.94)
	_card_band.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_card_band.anchor_right = 1.0
	_card_band.offset_top = -270.0
	_card_band.offset_bottom = -70.0
	_card_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_card_band)
	# Hairline brass edges, like the rule on a printed poster.
	for edge in [0.0, 1.0]:
		var line := ColorRect.new()
		line.color = Color(POSTER_BRASS.r, POSTER_BRASS.g, POSTER_BRASS.b, 0.7)
		line.anchor_right = 1.0
		line.anchor_top = edge
		line.anchor_bottom = edge
		line.offset_top = -1.0 if edge > 0.5 else 0.0
		line.offset_bottom = 0.0 if edge > 0.5 else 1.0
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card_band.add_child(line)
	var c := CenterContainer.new()
	_full(c)
	_card_band.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	c.add_child(v)
	var rule := ColorRect.new()
	rule.color = POSTER_BRASS
	rule.custom_minimum_size = Vector2(110, 4)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_title = _label("", 84, CREAM, "display")
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_sub = _label("", 24, Color(1, 0.86, 0.6), "display")
	_card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for n in [rule, _card_title, _card_sub]:
		v.add_child(n)

func show_card(title: String, sub: String, seconds := 3.0) -> void:
	_card_title.text = title
	_card_sub.text = sub.replace("  -  ", "   ·   ")
	_card_sub.visible = sub != ""
	var tw := create_tween()
	if Settings.v("reduce_motion"):
		_card_band.scale.y = 1.0
		tw.tween_property(_card, "modulate:a", 1.0, 0.4)
	else:
		_card_band.pivot_offset = Vector2(0, 100)
		_card_band.scale.y = 0.0
		tw.set_parallel(true)
		tw.tween_property(_card_band, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_card, "modulate:a", 1.0, 0.3)
		tw.set_parallel(false)
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
			_note_box.modulate.a = maxf(0.0, _note_t / 0.8)
	if Input.is_action_just_pressed("radio_1"): RadioSystem.choose(0)
	if Input.is_action_just_pressed("radio_2"): RadioSystem.choose(1)
	if Input.is_action_just_pressed("radio_dismiss"): RadioSystem.dismiss()

	_bino.visible = player.binoculars
	_reticle.visible = not _title.visible and not prologue.visible
	_reticle.get_child(0).visible = not player.binoculars
	if player.binoculars:
		_bino_range.text = "Distance: %d m" % player.bino_dist if player.bino_dist >= 0 else "Distance: --- m"
		_bino_label.text = player.bino_label if player.bino_label != "" else "Scanning the horizon..."
	_prompt_box.visible = player.nearby != null and not player.binoculars
	if player.nearby:
		_prompt_key.text = "A" if _pad_input else "E"
		_prompt.text = ("Hold   " if player.nearby.hold_time > 0.0 else "") + player.nearby.get_title()
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
## Sized from its minimum size every frame (never from its current size,
## which would never shrink back), centred, and kept above the radio panel.
func _place_note() -> void:
	var want := _note_box.get_combined_minimum_size()
	var vh: float = get_viewport().get_visible_rect().size.y
	var y: float = vh - 120.0 - want.y * 0.5
	if _radio.visible:
		y = minf(y, _radio.global_position.y - want.y - 14.0)
	_note_box.offset_left = -want.x * 0.5
	_note_box.offset_right = want.x * 0.5
	_note_box.offset_top = y
	_note_box.offset_bottom = y + want.y

## Radio, tape and toast text follow the "subtitle size" accessibility setting.
func apply_text_scale() -> void:
	var k: float = float(Settings.v("subtitle_scale"))
	_radio_speaker.add_theme_font_size_override("font_size", int(RADIO_SPEAKER_SIZE * k))
	_radio_text.add_theme_font_size_override("font_size", int(RADIO_TEXT_SIZE * k))
	for b in _opt_buttons:
		b.add_theme_font_size_override("font_size", int(RADIO_OPT_SIZE * k))
	_tape_title.add_theme_font_size_override("font_size", int(TAPE_TITLE_SIZE * k))
	_tape_text.add_theme_font_size_override("font_size", int(TAPE_TEXT_SIZE * k))
	_note.add_theme_font_size_override("font_size", int(NOTE_SIZE * k))
	_layout_radio()

func _on_line(speaker: String, text: String, options: Array) -> void:
	if not _radio.visible:
		show_banner()                      # a new call, not a follow-up line
	_radio.visible = true
	_radio_speaker.text = speaker
	_type_in(text)
	_radio_opts.visible = options.size() > 0
	for i in 2:
		_opt_buttons[i].visible = i < options.size()
		if i < options.size():
			_opt_buttons[i].text = "%d  %s" % [i + 1, options[i].get("text", "")]

func _on_reply(speaker: String, text: String) -> void:
	_radio_speaker.text = speaker
	_type_in(text)
	_radio_opts.visible = false

func fade_out(duration := 0.7) -> void:
	create_tween().tween_property(_fade, "modulate:a", 1.0, duration)

func fade_in(duration := 0.9) -> void:
	create_tween().tween_property(_fade, "modulate:a", 0.0, duration)

func show_title(on: bool) -> void:
	_title.visible = on
