extends Node
## JSON autosave in user://. Saved at the start of each day and at wait anchors.

const VERSION := 1
var path := "user://lowtide_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(path)

func save_game(location: String) -> bool:
	var d := {
		"version": VERSION, "location": location,
		"clock": {"day": GameClock.day, "minute": GameClock.minute_of_day},
		"state": GameState.to_dict(), "director": DayDirector.to_dict(),
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d))
	return true

## Applies a save to all autoloads; returns the saved location ("" on failure).
func load_game() -> String:
	if not has_save():
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _valid(parsed):
		push_warning("Ignoring a damaged save file.")
		return ""
	GameClock.set_time(int(parsed["clock"]["day"]), float(parsed["clock"]["minute"]))
	GameState.from_dict(parsed["state"])
	DayDirector.from_dict(parsed["director"])
	TideSystem.refresh()
	return String(parsed["location"])

## The day recorded in the save, or 0 when there is no usable save. Reads the
## file only; nothing is applied (load_game() does that).
func peek_day() -> int:
	if not has_save():
		return 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _valid(parsed):
		return 0
	return int(parsed["clock"]["day"])

## A save is only applied if every part is present and the right type, so a
## truncated or hand-edited file can't leave the game half-loaded.
func _valid(d: Variant) -> bool:
	if typeof(d) != TYPE_DICTIONARY or int(d.get("version", 0)) != VERSION:
		return false
	if typeof(d.get("location")) != TYPE_STRING:
		return false
	var c: Variant = d.get("clock")
	if typeof(c) != TYPE_DICTIONARY:
		return false
	for k in ["day", "minute"]:
		if not c.has(k) or (typeof(c[k]) != TYPE_FLOAT and typeof(c[k]) != TYPE_INT):
			return false
	return typeof(d.get("state")) == TYPE_DICTIONARY and typeof(d.get("director")) == TYPE_DICTIONARY

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## Endings seen across playthroughs (kept even when a run's save is deleted).
var endings_path := "user://lowtide_endings.json"

func endings_seen() -> Array:
	if not FileAccess.file_exists(endings_path):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(endings_path))
	return parsed if typeof(parsed) == TYPE_ARRAY else []

func record_ending(kind: String) -> void:
	var seen := endings_seen()
	if not seen.has(kind):
		seen.append(kind)
		seen.sort()
		var f := FileAccess.open(endings_path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(seen))
