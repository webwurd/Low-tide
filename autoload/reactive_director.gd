extends Node
## Clara reacts to where Arthur is, the tide, and what he carries.
## Reactions live in dialogue.json ("reactions"): {id, when, conv, once, cooldown}.
## Checked once a second while Arthur is outdoors and the radio is idle.

var enabled := true
var auto := true            # tests turn this off and call tick() themselves
var _t := 0.0

func _process(delta: float) -> void:
	if not auto:
		return
	_t += delta
	if _t >= 1.0:
		_t = 0.0
		tick()

## Returns the id of the reaction played, or "".
func tick() -> String:
	if not enabled or RadioSystem.active:
		return ""
	for r in Conversations.reactions():
		if GameState.location != "outdoors" and not r.get("anywhere", false):
			continue
		var id: String = r["id"]
		if r.get("once", false) and GameState.has_flag("seen_" + id):
			continue
		var last: float = GameState.reaction_last.get(id, -1e9)
		if GameClock.abs_minute() - last < float(r.get("cooldown", 0)):
			continue
		if not Conditions.check(r.get("when", [])):
			continue
		var conv := Conversations.get_conv(r["conv"])
		if conv.is_empty():
			continue
		GameState.reaction_last[id] = GameClock.abs_minute()
		if r.get("once", false):
			GameState.set_flag("seen_" + id)
		RadioSystem.play(conv)
		return id
	return ""
