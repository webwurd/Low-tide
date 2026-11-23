extends Node
## Story state: discovered landmarks/clues, flags, hidden Trust value, logbook.

signal discovered_changed(id: String)
signal note_posted(text: String)      # Arthur's short inner-voice toasts

var discovered: Dictionary = {}       # id -> true
var discovered_day: Dictionary = {}   # id -> day first found
var flags: Dictionary = {}
var trust := 0
var logbook: Array = []               # [{day:int, text:String}]

func reset() -> void:
	discovered.clear(); discovered_day.clear(); flags.clear(); logbook.clear()
	trust = 0

func discover(id: String) -> bool:
	if id == "" or discovered.has(id):
		return false
	discovered[id] = true
	discovered_day[id] = GameClock.day
	discovered_changed.emit(id)
	return true

func set_flag(flag_name: String, value := true) -> void:
	flags[flag_name] = value

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func note(text: String) -> void:
	note_posted.emit(text)

func add_log(day: int, text: String) -> void:
	logbook.append({"day": day, "text": text})

func to_dict() -> Dictionary:
	return {"discovered": discovered, "discovered_day": discovered_day, "flags": flags,
		"trust": trust, "logbook": logbook}

func from_dict(d: Dictionary) -> void:
	reset()
	discovered = d.get("discovered", {})
	discovered_day = {}
	for k in d.get("discovered_day", {}):
		discovered_day[k] = int(d["discovered_day"][k])
	flags = d.get("flags", {})
	trust = int(d.get("trust", 0))
	logbook = []
	for e in d.get("logbook", []):
		logbook.append({"day": int(e["day"]), "text": String(e["text"])})
