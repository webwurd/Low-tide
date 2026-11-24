class_name TitleScreen extends Control
## Title menu over a live view of Gannet Rock at dusk (Main drives the 3D
## backdrop while this is visible). New Watch starts the prologue; Continue
## appears when a save exists; Settings opens the full settings menu (Menus);
## Quit leaves the game.

signal new_watch
signal continue_game
signal settings

var panel: Control                 # the menu column (hidden while a sub-panel is open)
var continue_btn: Button
var endings_label: Label           # "Endings found: ..." (set by the HUD)
var _new_btn: Button
var _first_focus: Button

func _ready() -> void:
	# Already in the tree here, so offsets must be set too (plain
	# set_anchors_preset would keep the current zero-size rect).
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Soft left-side shade so the type sits on the scene, not on a box.
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 0.78])
	g.colors = PackedColorArray([Color(0.02, 0.035, 0.05, 0.78), Color(0.02, 0.035, 0.05, 0.42), Color(0.02, 0.035, 0.05, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(1, 0)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 96)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 64)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)
	panel = col

	var kicker := _label("Gannet Rock Light Station", UiTheme.ui_font(500), 13, Color(1, 0.86, 0.62, 0.85))
	kicker.add_theme_constant_override("outline_size", 0)
	var title := _label("Low Tide", UiTheme.title_font(600, 2), 96, Color("f3ead6"))
	var sub := _label("Maine coast  ·  winter, 1998", UiTheme.title_font(500, 1), 22, Color(0.85, 0.82, 0.76, 0.85))
	col.add_child(kicker)
	col.add_child(title)
	col.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 44)
	col.add_child(gap)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 2)
	menu.custom_minimum_size = Vector2(300, 0)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(menu)
	continue_btn = _button(menu, "Continue the watch", func(): continue_game.emit())
	continue_btn.visible = SaveSystem.has_save()
	_new_btn = _button(menu, "New watch", func(): new_watch.emit())
	_button(menu, "Settings", func(): settings.emit())
	_button(menu, "Quit", func(): get_tree().quit())
	_first_focus = continue_btn if continue_btn.visible else _new_btn

	endings_label = _label("", UiTheme.ui_font(420), 13, Color(0.85, 0.82, 0.76, 0.6))
	col.add_child(endings_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	var foot := _label("Mouse, keyboard or gamepad  ·  Enter / A to choose", UiTheme.ui_font(400), 12, Color(0.85, 0.82, 0.76, 0.5))
	col.add_child(foot)
	visibility_changed.connect(_on_visible)
	_on_visible()

func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", UiTheme.title_font(600, 1))
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _on_visible() -> void:
	if visible and is_inside_tree():
		continue_btn.visible = SaveSystem.has_save()
		# Re-pick every time: the save can appear or disappear between visits.
		_first_focus = continue_btn if continue_btn.visible else _new_btn
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 1.2)
		if _first_focus:
			_first_focus.grab_focus.call_deferred()
