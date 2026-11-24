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

# --- M6.5 helpers (title screen, prologue): the same fonts via UiFonts ------

const INK := Color("e8dfc8")
const SLATE := Color(0.055, 0.08, 0.105, 0.9)

## UI face (Work Sans) at a given variable weight.
static func ui_font(weight := 420) -> Font:
	return UiFonts.weighted("ui", weight)

## Display face (Cormorant Garamond) at a weight, with optional letter spacing.
static func title_font(weight := 600, tracking := 0) -> Font:
	var f := UiFonts.weighted("display", weight)
	if f is FontVariation and tracking != 0:
		(f as FontVariation).spacing_glyph = tracking
	return f

## Panel style shared by the title and prologue overlays.
static func panel(bg := SLATE, border := BORDER, radius := 6) -> StyleBoxFlat:
	var sb := box(bg, border, radius, 16)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 12
	return sb

# --- Box system (UI overhaul): one look for every panel, card and button ------
# Tokens: every box uses these radii, paddings, colours and the soft shadow, so
# surfaces read as one family. Sizes are for the 1280x720 canvas (the Steam
# Deck's 1280x800 expands it; nothing is scaled down).

const RADIUS := 12                       ## panels
const RADIUS_SMALL := 8                  ## buttons, chips
const PAD := Vector2(30, 22)             ## panel padding (x, y)
const PAD_SMALL := Vector2(18, 12)       ## chip / button padding
const CREAM := Color("f1e8d2")           ## body text on dark
const MUTED := Color("b9b2a2")           ## secondary text on dark
const ACCENT := Color("e9ab4f")          ## amber, a touch softer than AMBER for fills
const PAPER := Color("ece2c9")
const PAPER_EDGE := Color("c9b88f")
const PAPER_INK := Color("2b2418")
const GLASS := Color(0.04, 0.06, 0.08, 0.64)
const MIN_TEXT := 14                     ## nothing smaller anywhere

## A soft drop shadow shared by every floating box.
static func _shadow(sb: StyleBoxFlat, size := 22) -> void:
	sb.shadow_color = Color(0, 0, 0, 0.32)
	sb.shadow_size = size
	sb.shadow_offset = Vector2(0, 6)

## Outline + shadow for a frosted glass panel. The panel's own background is
## transparent: add_frost() puts the blurred, tinted backdrop inside it.
static func glass_frame(radius := RADIUS) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(1, 0.94, 0.82, 0.10)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(0)
	_shadow(sb)
	sb.anti_aliasing_size = 1.2
	return sb

## Builds a frosted glass panel: returns [panel, body]. Put content in `body`
## (a MarginContainer with the standard padding); `panel` is what you place.
static func glass_panel(pad := PAD, radius := RADIUS, tint := GLASS) -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", glass_frame(radius))
	add_frost(panel, radius, tint)
	var body := MarginContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_theme_constant_override("margin_left", int(pad.x))
	body.add_theme_constant_override("margin_right", int(pad.x))
	body.add_theme_constant_override("margin_top", int(pad.y))
	body.add_theme_constant_override("margin_bottom", int(pad.y))
	panel.add_child(body)
	return [panel, body]

## Adds the frosted backdrop as the first child of a container panel.
static func add_frost(panel: Container, radius := RADIUS, tint := GLASS) -> ColorRect:
	var fr := ColorRect.new()
	fr.name = "Frost"
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://ui/frost.gdshader")
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("radius", float(radius))
	fr.material = m
	fr.resized.connect(func(): m.set_shader_parameter("size", fr.size))
	panel.add_child(fr)
	panel.move_child(fr, 0)
	return fr

## Paper: the journal and the tide table are things Arthur holds.
static func paper(radius := 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = PAPER_EDGE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 44
	sb.content_margin_right = 44
	sb.content_margin_top = 34
	sb.content_margin_bottom = 26
	_shadow(sb, 28)
	return sb

## A pill (toasts, tags). `bg` is the fill.
static func pill(bg: Color, pad := PAD_SMALL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(999)
	sb.content_margin_left = pad.x + 6
	sb.content_margin_right = pad.x + 6
	sb.content_margin_top = pad.y - 2
	sb.content_margin_bottom = pad.y - 2
	_shadow(sb, 14)
	return sb

## Button states for the three kinds used across the game:
##   "primary"   filled amber, dark text (one per screen: the thing to do next)
##   "secondary" quiet glass chip, cream text, amber edge on focus
##   "choice"    a radio reply: glass chip with an amber left edge when active
static func style_button(b: Button, kind := "secondary", size := 18) -> void:
	UiFonts.style(b, "ui_bold" if kind != "choice" else "ui", size)
	var states := {}
	match kind:
		"primary":
			states = {"normal": Color(ACCENT, 0.96), "hover": ACCENT.lightened(0.12), "pressed": ACCENT.darkened(0.1), "focus": ACCENT.lightened(0.12)}
			for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
				b.add_theme_color_override(c, Color("1c140a"))
		_:
			states = {"normal": Color(1, 1, 1, 0.07), "hover": Color(1, 0.8, 0.5, 0.16), "pressed": Color(1, 0.75, 0.4, 0.26), "focus": Color(1, 0.8, 0.5, 0.16)}
			b.add_theme_color_override("font_color", CREAM)
			for c in ["font_hover_color", "font_focus_color"]:
				b.add_theme_color_override(c, Color.WHITE)
			b.add_theme_color_override("font_pressed_color", ACCENT)
	for st in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[st]
		sb.set_corner_radius_all(RADIUS_SMALL)
		sb.content_margin_left = PAD_SMALL.x
		sb.content_margin_right = PAD_SMALL.x
		sb.content_margin_top = PAD_SMALL.y
		sb.content_margin_bottom = PAD_SMALL.y
		sb.anti_aliasing_size = 1.0
		if kind != "primary" and st != "normal":
			sb.border_color = ACCENT
			sb.border_width_left = 3
		if st == "focus":
			sb.border_color = Color.WHITE if kind == "primary" else ACCENT
			sb.set_border_width_all(2)
			if kind != "primary":
				sb.border_width_left = 3
		b.add_theme_stylebox_override(st, sb)
