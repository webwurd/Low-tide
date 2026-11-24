class_name UiFonts
## Central place for UI typography. Four roles:
##   "display"  Oswald SemiBold, wide-tracked: day cards, banners, title (poster voice)
##   "ui"       Inter Regular: radio, prompts, body text (quiet and legible)
##   "ui_bold"  Inter SemiBold: buttons, speaker tags, small caps labels
##   "paper"    Caveat SemiBold: Arthur's own handwriting (journal, inner-voice notes)
## All SIL OFL; licences are in ui/fonts/ and docs/licences.md.

const ROLE_FILES := {
	"display": "res://ui/fonts/Oswald-SemiBold.ttf",
	"ui": "res://ui/fonts/Inter-Regular.ttf",
	"ui_bold": "res://ui/fonts/Inter-SemiBold.ttf",
	"paper": "res://ui/fonts/Caveat-SemiBold.ttf",
}
## Extra letter-spacing per role (pixels), for the poster look.
const TRACKING := {"display": 3}
static var _cache: Dictionary = {}

## Returns the Font for a role, or null to use the theme default.
static func get_font(role: String) -> Font:
	if not ROLE_FILES.has(role):
		return null
	if not _cache.has(role):
		var path: String = ROLE_FILES[role]
		var f: Font = load(path) if ResourceLoader.exists(path) else null
		if f != null and TRACKING.has(role):
			var v := FontVariation.new()
			v.base_font = f
			v.spacing_glyph = int(TRACKING[role])
			f = v
		_cache[role] = f
	return _cache[role]

## Applies a role's font (if any) and a size to a Control.
static func style(c: Control, role: String, size: int) -> void:
	var f := get_font(role)
	if f:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", size)
