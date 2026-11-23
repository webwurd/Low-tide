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
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return ""
	GameClock.set_time(int(parsed["clock"]["day"]), float(parsed["clock"]["minute"]))
	GameState.from_dict(parsed["state"])
	DayDirector.from_dict(parsed["director"])
	TideSystem.refresh()
	return String(parsed["location"])

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
