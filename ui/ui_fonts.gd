class_name UiFonts
## Central place for UI typography (decision: docs/typography.md).
##   display : Newsreader SemiBold   - title, day cards, ending names, headings
##   ui      : IBM Plex Mono Regular - HUD, radio, prompts, menus
##   paper   : Caveat Medium         - journal entries, tide table
##   tape    : Newsreader Italic     - tape subtitles
## A missing/unimported file yields null and the engine default is used.

const ROLE_FILES := {
	"display": "res://ui/fonts/Newsreader-SemiBold.woff",
	"ui": "res://ui/fonts/IBMPlexMono-Regular.woff",
	"paper": "res://ui/fonts/Caveat-Medium.woff",
	"tape": "res://ui/fonts/Newsreader-Italic.woff",
}
static var _cache: Dictionary = {}

## Returns the Font for a role, or null to use the theme default.
static func get_font(role: String) -> Font:
	if not ROLE_FILES.has(role):
		return null
	if not _cache.has(role):
		var path: String = ROLE_FILES[role]
		_cache[role] = load(path) if ResourceLoader.exists(path) else null
	return _cache[role]

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
