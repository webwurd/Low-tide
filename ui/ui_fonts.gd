class_name UiFonts
## Central place for UI typography (decision: docs/typography.md; M6.5 type set
## in docs/art_direction.md).
##   display : Cormorant Garamond (600)  - title, day cards, ending names, headings
##   ui      : Work Sans (420)           - HUD, radio, prompts, menus
##   ui_bold : Work Sans (600)           - buttons, speaker names, labels
##   paper   : Caveat Medium             - journal entries, tide table (handwriting)
##   tape    : Cormorant Garamond (500), obliqued - tape subtitles
## Cormorant Garamond and Work Sans are variable fonts (SIL OFL, assets/fonts/).
## A missing/unimported file yields null and the engine default is used.

const ROLE_FILES := {
	"display": "res://assets/fonts/CormorantGaramond.ttf",
	"ui": "res://assets/fonts/WorkSans.ttf",
	"ui_bold": "res://assets/fonts/WorkSans.ttf",
	"paper": "res://ui/fonts/Caveat-Medium.woff",
	"tape": "res://assets/fonts/CormorantGaramond.ttf",
}
const ROLE_WEIGHT := {"display": 600, "ui": 420, "ui_bold": 600, "tape": 500}
static var _cache: Dictionary = {}

## Returns the Font for a role, or null to use the theme default.
static func get_font(role: String) -> Font:
	if not ROLE_FILES.has(role):
		return null
	if not _cache.has(role):
		_cache[role] = _make(role, int(ROLE_WEIGHT.get(role, 0)))
	return _cache[role]

## A role's face at a specific variable weight (falls back to the role font).
static func weighted(role: String, weight: int) -> Font:
	var key := "%s@%d" % [role, weight]
	if not _cache.has(key):
		_cache[key] = _make(role, weight)
	return _cache[key]

static func _make(role: String, weight: int) -> Font:
	var path: String = ROLE_FILES[role]
	if not ResourceLoader.exists(path):
		return null
	var base: Font = load(path)
	if weight <= 0 and role != "tape":
		return base
	var f := FontVariation.new()
	f.base_font = base
	if weight > 0:
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	if role == "tape":
		f.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	return f

## Makes the "ui" font the default for every Control and Label3D without an explicit font.
static func install_default() -> void:
	var f := get_font("ui")
	if f:
		ThemeDB.fallback_font = f
		# The default theme keeps its own copy of the built-in font, which is what
		# Buttons and OptionButtons use, so set it as well.
		var dt := ThemeDB.get_default_theme()
		if dt:
			dt.default_font = f

## Applies a role's font (if any) and a size to a Control.
static func style(c: Control, role: String, size: int) -> void:
	var f := get_font(role)
	if f:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", size)

## Same, for a 3D label.
static func style_3d(l: Label3D, role: String) -> void:
	var f := get_font(role)
	if f:
		l.font = f
