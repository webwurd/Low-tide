class_name UiTheme
## One Theme for all menus (pause, settings). HUD elements keep their own styling.

const BG := Color(0.05, 0.08, 0.11, 0.96)
const BORDER := Color(0.85, 0.7, 0.42, 0.3)
const AMBER := Color("ffb84d")
const TEXT := Color("efe4c8")

static func box(bg: Color, border := BORDER, radius := 3, margin := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb

static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16
	var f := UiFonts.get_font("ui")
	if f:
		t.default_font = f
	# Tab headings use the display face; body text stays quiet.
	var disp := UiFonts.get_font("display")
	if disp:
		t.set_font("font", "TabContainer", disp)
		t.set_font_size("font_size", "TabContainer", 19)
	t.set_color("font_color", "Label", TEXT)
	for c in ["Button", "CheckBox", "OptionButton"]:
		t.set_color("font_color", c, TEXT)
		t.set_color("font_hover_color", c, Color.WHITE)
		t.set_color("font_focus_color", c, AMBER)
		t.set_color("font_pressed_color", c, AMBER)
	t.set_stylebox("normal", "Button", box(Color(0.12, 0.17, 0.22, 0.95)))
	t.set_stylebox("hover", "Button", box(Color(0.18, 0.25, 0.31, 0.98), AMBER))
	t.set_stylebox("pressed", "Button", box(Color(0.25, 0.2, 0.1, 0.98), AMBER))
	t.set_stylebox("focus", "Button", box(Color(0.15, 0.2, 0.26, 0.98), AMBER))
	t.set_stylebox("normal", "OptionButton", box(Color(0.12, 0.17, 0.22, 0.95)))
	t.set_stylebox("hover", "OptionButton", box(Color(0.18, 0.25, 0.31, 0.98), AMBER))
	t.set_stylebox("focus", "OptionButton", box(Color(0.15, 0.2, 0.26, 0.98), AMBER))
	t.set_stylebox("panel", "PanelContainer", box(BG, BORDER, 4, 18))
	t.set_stylebox("panel", "TabContainer", box(Color(0.08, 0.11, 0.15, 0.9), BORDER, 2, 14))
	t.set_stylebox("tab_selected", "TabContainer", box(Color(0.2, 0.16, 0.08, 0.95), AMBER, 2, 8))
	t.set_stylebox("tab_unselected", "TabContainer", box(Color(0.1, 0.14, 0.18, 0.9), BORDER, 2, 8))
	t.set_stylebox("tab_hovered", "TabContainer", box(Color(0.16, 0.2, 0.25, 0.95), AMBER, 2, 8))
	t.set_stylebox("tab_focus", "TabContainer", box(Color(0.2, 0.16, 0.08, 0.95), AMBER, 2, 8))
	t.set_color("font_selected_color", "TabContainer", AMBER)
	t.set_color("font_unselected_color", "TabContainer", TEXT)
	t.set_color("font_hovered_color", "TabContainer", Color.WHITE)
	return t
