class_name Conversations
## Loads and resolves conversations from dialogue/dialogue.json (the single
## source of truth shared with the Unity port).

const SPEAKER := "Clara, Coast Guard dispatch (channel 16)"

static var _json: Dictionary = {}
static var _loaded := false

const JSON_PATH := "res://dialogue/dialogue.json"
const SPEAKERS := {"clara": SPEAKER, "arthur": "Arthur"}

static func reload() -> void:
	_loaded = false
	_json = {}

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(JSON_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(JSON_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_json = parsed
	else:
		push_error("dialogue.json failed to parse")

## Resolve a conversation id to a ready-to-play dictionary. JSON conversations
## are lists of variants; the first whose `when` holds wins. Options are
## filtered by their own `when` and capped at two (the radio UI shows 1 / 2).
static func get_conv(id: String) -> Dictionary:
	_load()
	var convs: Dictionary = _json.get("convs", {})
	if convs.has(id):
		for v in convs[id]:
			if Conditions.check(v.get("when", [])):
				return _normalize(id, v)
		return {}
	if id == "opening":
		return get_conv("morning_d1")
	return {}

static func _normalize(id: String, v: Dictionary) -> Dictionary:
	var opts: Array = []
	for o in v.get("options", []):
		if Conditions.check(o.get("when", [])) and opts.size() < 2:
			opts.append(o)
	return {"id": id, "speaker": SPEAKERS.get(v.get("speaker", "clara"), SPEAKER),
		"priority": int(v.get("priority", 2)), "text": v.get("text", ""), "options": opts}

static func reactions() -> Array:
	_load()
	return _json.get("reactions", [])

static func tape(id: String) -> Dictionary:
	_load()
	return _json.get("tapes", {}).get(id, {})
