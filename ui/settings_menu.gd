class_name SettingsMenu extends PanelContainer
## Graphics / Audio / Lighting / Controls / Accessibility. Every control writes through
## Settings.set_v(), so changes apply immediately and persist. Gamepad and keyboard can
## drive it (focus + ui_* actions); mouse works as usual.

signal back_pressed

const FPS_CAPS := [0, 30, 60, 90, 120, 144, 240]
var controls: Dictionary = {}          # setting key -> Control (tests drive these)
var bind_buttons: Dictionary = {}      # "action|device" -> Button
var tabs: TabContainer
var _hint: Label
var _capture_action := ""
var _capture_dev := ""
var _tab_keys: Array = []              # per tab: settings keys on it (for "reset this tab")

func _ready() -> void:
	theme = UiTheme.build()
	custom_minimum_size = Vector2(940, 580)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title := Label.new()
	title.text = "Settings"
	UiFonts.style(title, "display", 28)
	root.add_child(title)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	_build_graphics()
	_build_audio()
	_build_lighting()
	_build_controls()
	_build_access()
	_hint = Label.new()
	_hint.add_theme_color_override("font_color", UiTheme.AMBER)
	root.add_child(_hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var reset := Button.new()
	reset.text = "Reset this tab"
	reset.pressed.connect(_reset_tab)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): back_pressed.emit())
	row.add_child(reset)
	row.add_child(back)
	root.add_child(row)
	Settings.changed.connect(_on_setting_changed)
	Settings.bindings_changed.connect(_refresh_bindings)
	_refresh_bindings()

func focus_first() -> void:
	tabs.get_tab_bar().grab_focus()

# ---- builders --------------------------------------------------------------

func _page(title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	tabs.add_child(sc)
	_tab_keys.append([])
	return box

func _line(parent: Control, text: String, ctrl: Control) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(360, 0)
	h.add_child(l)
	ctrl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if ctrl is CheckBox else Control.SIZE_EXPAND_FILL
	h.add_child(ctrl)
	parent.add_child(h)

func _register(key: String, ctrl: Control) -> void:
	controls[key] = ctrl
	_tab_keys[tabs.get_tab_count() - 1].append(key)

func _slider(parent: Control, key: String, text: String, step := 0.05, percent := true) -> HSlider:
	var s := HSlider.new()
	var r: Array = Settings.RANGES[key]
	s.min_value = float(r[0]); s.max_value = float(r[1]); s.step = step
	s.value = float(Settings.v(key))
	s.custom_minimum_size = Vector2(260, 24)
	var val := Label.new()
	val.custom_minimum_size = Vector2(70, 0)
	val.text = _fmt(float(s.value), percent)
	s.value_changed.connect(func(x: float):
		val.text = _fmt(x, percent)
		Settings.set_v(key, x))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(s)
	h.add_child(val)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line(parent, text, h)
	_register(key, s)
	s.set_meta("value_label", val)
	s.set_meta("percent", percent)
	return s

func _fmt(x: float, percent: bool) -> String:
	return "%d%%" % int(round(x * 100.0)) if percent else "%.2f" % x

func _option(parent: Control, key: String, text: String, items: Array) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(String(it))
	o.select(int(Settings.v(key)))
	o.item_selected.connect(func(i: int): Settings.set_v(key, i))
	_line(parent, text, o)
	_register(key, o)
	return o

func _check(parent: Control, key: String, text: String) -> CheckBox:
	var c := CheckBox.new()
	c.text = "On"
	c.button_pressed = bool(Settings.v(key))
	c.toggled.connect(func(on: bool): Settings.set_v(key, on))
	_line(parent, text, c)
	_register(key, c)
	return c

func _build_graphics() -> void:
	var p := _page("Graphics")
	_option(p, "quality_preset", "Quality preset", ["Low", "Medium", "High", "Steam Deck", "Custom"])
	controls["quality_preset"].item_selected.disconnect(controls["quality_preset"].item_selected.get_connections()[0]["callable"])
	controls["quality_preset"].item_selected.connect(func(i: int): Settings.set_preset(i))
	_option(p, "window_mode", "Window mode", ["Windowed", "Borderless fullscreen", "Exclusive fullscreen"])
	_option(p, "vsync", "V-Sync", ["Off", "On", "Adaptive"])
	var fps := OptionButton.new()
	for c in FPS_CAPS:
		fps.add_item("Unlimited" if c == 0 else "%d fps" % c)
	fps.select(maxi(0, FPS_CAPS.find(int(Settings.v("fps_cap")))))
	fps.item_selected.connect(func(i: int): Settings.set_v("fps_cap", FPS_CAPS[i]))
	_line(p, "Frame rate cap", fps)
	_register("fps_cap", fps)
	_slider(p, "render_scale", "Render scale", 0.05)
	_option(p, "msaa", "Anti-aliasing (MSAA)", ["Off", "2x", "4x", "8x"])
	_option(p, "shadow_quality", "Shadow quality", ["Off", "Low", "Medium", "High"])
	_option(p, "ocean_detail", "Ocean detail", ["Low", "Medium", "High"])
	var note := Label.new()
	var method := RenderingServer.get_current_rendering_method()
	note.text = "Renderer: %s.  Render scale and MSAA apply to Forward+/Mobile; the Compatibility renderer ignores them." % method
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("9aa7b0"))
	p.add_child(note)

func _build_audio() -> void:
	var p := _page("Audio")
	_slider(p, "vol_master", "Master volume")
	_slider(p, "vol_ambience", "Ambience (sea, wind, bells)")
	_slider(p, "vol_sfx", "Footsteps and effects")
	_slider(p, "vol_radio", "Radio and tapes")
	_slider(p, "vol_music", "Music")
	_slider(p, "radio_static", "Radio static intensity")

func _build_lighting() -> void:
	var p := _page("Lighting")
	_slider(p, "brightness", "Brightness")
	_slider(p, "exposure", "Exposure")
	_slider(p, "night_assist", "Night brightness assist")
	_slider(p, "fog_scale", "Fog density")
	_check(p, "glow", "Bloom / glow")
	_slider(p, "beam_scale", "Lighthouse beam intensity")

func _build_controls() -> void:
	var p := _page("Controls")
	_slider(p, "mouse_sens", "Mouse sensitivity")
	_slider(p, "bino_sens", "Binocular sensitivity")
	_slider(p, "pad_sens", "Gamepad look speed")
	_slider(p, "deadzone", "Stick dead zone")
	_check(p, "invert_y", "Invert look Y")
	_check(p, "toggle_binoculars", "Binoculars: toggle, not hold")
	_check(p, "toggle_watch", "Pocket watch: toggle, not hold")
	_check(p, "toggle_hold", "Hold-to-use: tap once instead")
	var head := HBoxContainer.new()
	for t in ["Action", "Keyboard and mouse", "Gamepad"]:
		var l := Label.new()
		l.text = t
		l.add_theme_color_override("font_color", UiTheme.AMBER)
		l.custom_minimum_size = Vector2(260 if t == "Action" else 240, 0)
		head.add_child(l)
	p.add_child(head)
	for a in Settings.ACTIONS:
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.text = a[1]
		lab.custom_minimum_size = Vector2(260, 0)
		row.add_child(lab)
		for dev in [Settings.KB, Settings.PAD]:
			var b := Button.new()
			b.custom_minimum_size = Vector2(230, 0)
			if Settings.is_rebindable(a[0], dev):
				b.pressed.connect(_begin_capture.bind(a[0], dev, b))
			else:
				b.disabled = true
				b.tooltip_text = "Fixed to the sticks"
			bind_buttons["%s|%s" % [a[0], dev]] = b
			row.add_child(b)
		p.add_child(row)
	var reset := Button.new()
	reset.text = "Reset all bindings"
	reset.pressed.connect(func():
		Settings.reset_bindings()
		_hint.text = "Bindings reset to defaults.")
	p.add_child(reset)

func _build_access() -> void:
	var p := _page("Accessibility")
	_check(p, "assist_mode", "Assist readout always on")
	_check(p, "reduce_motion", "Reduce motion (no head-bob)")
	_slider(p, "ui_scale", "Interface size")
	_slider(p, "subtitle_scale", "Subtitle / radio text size")

# ---- behaviour --------------------------------------------------------------------

func _on_setting_changed(key: String) -> void:
	var c: Control = controls.get(key)
	if c == null:
		return
	var val = Settings.v(key)
	if c is HSlider:
		(c as HSlider).set_value_no_signal(float(val))
		var lbl: Label = c.get_meta("value_label")
		lbl.text = _fmt(float(val), c.get_meta("percent"))
	elif c is OptionButton:
		var ob := c as OptionButton
		if key == "fps_cap":
			ob.select(maxi(0, FPS_CAPS.find(int(val))))
		else:
			ob.select(int(val))
	elif c is CheckBox:
		(c as CheckBox).set_pressed_no_signal(bool(val))

func _reset_tab() -> void:
	var i := tabs.current_tab
	Settings.reset_defaults(_tab_keys[i])
	if tabs.get_child(i).name == "Controls":
		Settings.reset_bindings()
	_hint.text = "%s settings reset." % tabs.get_child(i).name

func _refresh_bindings() -> void:
	for a in Settings.ACTIONS:
		for dev in [Settings.KB, Settings.PAD]:
			var b: Button = bind_buttons.get("%s|%s" % [a[0], dev])
			if b:
				b.text = Settings.binding_text(a[0], dev)

func _begin_capture(action: String, dev: String, b: Button) -> void:
	_capture_action = action
	_capture_dev = dev
	b.text = "Press a key or mouse button..." if dev == Settings.KB else "Press a button..."
	_hint.text = "Esc cancels."

func is_capturing() -> bool:
	return _capture_action != ""

func _input(event: InputEvent) -> void:
	if _capture_action == "" or not visible:
		return
	var ev: InputEvent = null
	if _capture_dev == Settings.KB:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE:
				_end_capture("Cancelled.")
				get_viewport().set_input_as_handled()
				return
			ev = InputEventKey.new()
			(ev as InputEventKey).physical_keycode = event.physical_keycode
		elif event is InputEventMouseButton and event.pressed:
			ev = InputEventMouseButton.new()
			(ev as InputEventMouseButton).button_index = event.button_index
	else:
		if event is InputEventJoypadButton and event.pressed:
			ev = InputEventJoypadButton.new()
			(ev as InputEventJoypadButton).button_index = event.button_index
		elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.7 \
				and (event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT):
			ev = InputEventJoypadMotion.new()
			(ev as InputEventJoypadMotion).axis = event.axis
			(ev as InputEventJoypadMotion).axis_value = 1.0
	if ev == null:
		get_viewport().set_input_as_handled()
		return
	apply_capture(ev)
	get_viewport().set_input_as_handled()

## Applies a captured event to the action being rebound (also used by tests).
func apply_capture(ev: InputEvent) -> void:
	var cleared := Settings.rebind(_capture_action, ev)
	_end_capture("Unbound from: %s" % ", ".join(PackedStringArray(cleared)) if cleared.size() > 0 else "Bound.")

func _end_capture(msg: String) -> void:
	_capture_action = ""
	_capture_dev = ""
	_hint.text = msg
	_refresh_bindings()
