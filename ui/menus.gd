class_name Menus extends CanvasLayer
## Pause menu, controls reference and Settings, on one layer that keeps running while the
## tree is paused. Settings can also be opened from the title screen (no pause).

signal resumed
signal title_requested
signal quit_requested

var _dim: ColorRect
var _pause: PanelContainer
var _controls: PanelContainer
var _settings: SettingsMenu
var _ctl_title: Label
var _ctl_body: VBoxContainer
var _ctl_idx := 0
var _pages: Array = []
var _from_title := false
var _resume_btn: Button
var _center: CenterContainer
var _pause_theme: Theme

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_theme = UiTheme.build()
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.05, 0.62)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	add_child(_dim)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(_center)
	_build_pause()
	_build_controls()
	_settings = SettingsMenu.new()
	_settings.visible = false
	_settings.back_pressed.connect(back)
	_center.add_child(_settings)

func _build_pause() -> void:
	_pause = PanelContainer.new()
	_pause.theme = _pause_theme
	_pause.visible = false
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(340, 0)
	v.add_theme_constant_override("separation", 10)
	_pause.add_child(v)
	var t := Label.new()
	t.text = "Paused"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.style(t, "display", 30)
	v.add_child(t)
	_resume_btn = _btn(v, "Resume", resume)
	_btn(v, "Settings", func(): _show_only("settings"))
	_btn(v, "Controls", func(): _open_controls())
	_btn(v, "Save and return to title", func():
		close_all()
		title_requested.emit())
	_btn(v, "Quit game", func(): quit_requested.emit())
	_center.add_child(_pause)

func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _build_controls() -> void:
	_pages = TutorialData.pages()
	_controls = PanelContainer.new()
	_controls.theme = _pause_theme
	_controls.visible = false
	_controls.custom_minimum_size = Vector2(760, 440)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_controls.add_child(v)
	_ctl_title = Label.new()
	UiFonts.style(_ctl_title, "display", 24)
	_ctl_body = VBoxContainer.new()
	_ctl_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_btn(row, "Previous", func(): _ctl_go(_ctl_idx - 1))
	_btn(row, "Next", func(): _ctl_go(_ctl_idx + 1))
	_btn(row, "Back", back)
	for n in [_ctl_title, _ctl_body, row]:
		v.add_child(n)
	_center.add_child(_controls)

func _ctl_go(i: int) -> void:
	_ctl_idx = clampi(i, 0, _pages.size() - 1)
	var pg: Dictionary = _pages[_ctl_idx]
	_ctl_title.text = pg["title"]
	for ch in _ctl_body.get_children():
		ch.queue_free()
	var rows: Array = pg["rows"]
	if rows.size() > 0:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 28)
		grid.add_theme_constant_override("v_separation", 8)
		for r in rows.size():
			for cell in rows[r]:
				var l := Label.new()
				l.text = cell
				l.add_theme_color_override("font_color", UiTheme.AMBER if r == 0 else UiTheme.TEXT)
				grid.add_child(l)
		_ctl_body.add_child(grid)
	if pg["text"] != "":
		var t := Label.new()
		t.text = pg["text"]
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(720, 0)
		_ctl_body.add_child(t)

func _open_controls() -> void:
	_ctl_go(0)
	_show_only("controls")

# ---- state ---------------------------------------------------------------------------

func is_open() -> bool:
	return _dim.visible

func is_paused_menu() -> bool:
	return _pause.visible or _controls.visible or (_settings.visible and not _from_title)

func _show_only(which: String) -> void:
	_dim.visible = true
	_pause.visible = which == "pause"
	_controls.visible = which == "controls"
	_settings.visible = which == "settings"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match which:
		"pause": _resume_btn.grab_focus()
		"settings": _settings.focus_first()

func open_pause() -> void:
	_from_title = false
	get_tree().paused = true
	_show_only("pause")

func open_settings_from_title() -> void:
	_from_title = true
	_show_only("settings")

func resume() -> void:
	close_all()
	resumed.emit()

func close_all() -> void:
	_dim.visible = false
	_pause.visible = false
	_controls.visible = false
	_settings.visible = false
	Settings.save_settings()
	get_tree().paused = false

## Escape / Back: one level up.
func back() -> void:
	if _settings.is_capturing():
		return
	if _settings.visible or _controls.visible:
		if _from_title:
			_from_title = false
			_dim.visible = false
			_settings.visible = false
			Settings.save_settings()
		else:
			_show_only("pause")
	elif _pause.visible:
		resume()

## While the tree is paused Main no longer receives input, so the menu layer handles Esc itself.
func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		back()

func settings_menu() -> SettingsMenu:
	return _settings
