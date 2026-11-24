class_name UiFonts
## Central place for UI typography. Three roles: "display" (title, day cards, endings),
## "ui" (HUD, radio, prompts, menus), "paper" (journal, tide table).
## Until fonts are chosen the engine default is used. To adopt a font, drop the file in
## res://ui/fonts/ and fill ROLE_FILES: no other code changes.

const ROLE_FILES := {
	# "display": "res://ui/fonts/Display-SemiBold.woff",
	# "ui": "res://ui/fonts/UI-Regular.woff",
	# "paper": "res://ui/fonts/Paper.woff",
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

## Applies a role's font (if any) and a size to a Control.
static func style(c: Control, role: String, size: int) -> void:
	var f := get_font(role)
	if f:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", size)
