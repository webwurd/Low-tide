extends Node
## Plays cassette tapes as timed subtitle lines (text-only for now; each line
## can later carry an audio clip). The HUD shows lines as they arrive.

signal started(title: String)
signal line_shown(text: String)
signal finished(id: String)

var speed := 1.0            # tests raise this
var playing := false
var current := ""

func is_heard(id: String) -> bool:
	return GameState.has_flag("heard_" + id)

func play(id: String) -> void:
	if playing:
		return
	var tape := Conversations.tape(id)
	if tape.is_empty():
		GameState.note("The tape is blank.")
		return
	playing = true
	current = id
	AudioDirector.play_sfx("clunk")
	AudioDirector.set_tape(true)
	started.emit(String(tape.get("title", id)))
	var t_prev := 0.0
	for l in tape.get("lines", []):
		var t := float(l["t"])
		if t > t_prev:
			await get_tree().create_timer((t - t_prev) / speed).timeout
		t_prev = t
		line_shown.emit(String(l["text"]))
	await get_tree().create_timer(3.0 / speed).timeout
	AudioDirector.set_tape(false)
	AudioDirector.play_sfx("clunk")
	GameState.set_flag("heard_" + id)
	playing = false
	current = ""
	finished.emit(id)
