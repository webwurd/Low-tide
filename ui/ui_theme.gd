class_name UITheme
## Low Tide's UI look: Work Sans for interface text, Cormorant Garamond for
## titles and cards, warm parchment text on deep slate, amber accents.
## Applied to the root window so every Control inherits it. The asset factory
## also saves it to res://ui/low_tide_theme.tres for tweaking in the editor;
## that file wins when present.

const PATH := "res://ui/low_tide_theme.tres"
const INK := Color("e8dfc8")
const AMBER := Color("ffb84d")
const SLATE := Color(0.055, 0.08, 0.105, 0.9)

static var _cache: Theme

static func get_theme() -> Theme:
	if _cache:
		return _cache
	if ResourceLoader.exists(PATH):
		_cache = load(PATH)
	else:
		_cache = build()
	return _cache

## OpenType tag for the variable "weight" axis.
static func _wght() -> int:
	return TextServerManager.get_primary_interface().name_to_tag("wght")

static func ui_font(weight := 420) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = load("res://assets/fonts/WorkSans.ttf")
	f.variation_opentype = {_wght(): weight}
	return f

## Serif display face; `tracking` adds letter spacing in pixels.
static func title_font(weight := 600, tracking := 0) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = load("res://assets/fonts/CormorantGaramond.ttf")
	f.variation_opentype = {_wght(): weight}
	f.spacing_glyph = tracking
	return f

static func panel(bg := SLATE, border := Color(0.85, 0.7, 0.42, 0.28), radius := 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 12
	return sb

static func build() -> Theme:
	var t := Theme.new()
	t.default_font = ui_font()
	t.default_font_size = 16
	t.set_color("font_color", "Label", INK)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_stylebox("panel", "PanelContainer", panel())
	# Buttons: quiet text with an amber rule that grows on focus/hover.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.0)
	normal.set_content_margin_all(10)
	normal.content_margin_left = 14
	normal.border_color = Color(1, 0.72, 0.3, 0.0)
	normal.border_width_left = 2
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 0.85, 0.6, 0.07)
	hover.border_color = Color(1, 0.72, 0.3, 0.9)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(1, 0.85, 0.6, 0.14)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("focus", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", normal)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color("fff2d6"))
	t.set_color("font_focus_color", "Button", Color("fff2d6"))
	t.set_color("font_pressed_color", "Button", AMBER)
	t.set_color("font_disabled_color", "Button", Color(0.6, 0.6, 0.6, 0.5))
	t.set_font_size("font_size", "Button", 17)
	t.set_font("font", "Button", ui_font(500))
	# Thin progress bars (stamina, hold-to-use).
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(0, 0, 0, 0.35); bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new(); fill.bg_color = Color(1, 0.8, 0.5, 0.85); fill.set_corner_radius_all(2)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", fill)
	# Option buttons + check boxes used by the settings panel.
	t.set_stylebox("normal", "OptionButton", panel(Color(0, 0, 0, 0.25), Color(1, 0.8, 0.5, 0.25), 4))
	t.set_stylebox("hover", "OptionButton", panel(Color(1, 0.85, 0.6, 0.08), Color(1, 0.72, 0.3, 0.7), 4))
	t.set_stylebox("focus", "OptionButton", panel(Color(1, 0.85, 0.6, 0.08), Color(1, 0.72, 0.3, 0.7), 4))
	t.set_stylebox("panel", "PopupMenu", panel(Color(0.06, 0.09, 0.12, 0.97)))
	return t
