extends Node
## Story state: discovered landmarks/clues, flags, hidden Trust value.

signal discovered_changed(id: String)

var discovered: Dictionary = {}
var flags: Dictionary = {}
var trust := 0

func discover(id: String) -> bool:
	if discovered.has(id):
		return false
	discovered[id] = true
	discovered_changed.emit(id)
	return true

func set_flag(name: String, value := true) -> void:
	flags[name] = value

func has_flag(name: String) -> bool:
	return flags.get(name, false)
