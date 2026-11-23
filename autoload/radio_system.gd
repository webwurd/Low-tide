extends Node
## Non-blocking VHF radio. Never pauses movement. Higher-priority
## conversations preempt lower ones; the rest queue. Panels read the signals.

signal line_shown(speaker: String, text: String, options: Array)
signal reply_shown(speaker: String, text: String)
signal hidden

var active := false
var current: Dictionary = {}
var awaiting_choice := false
var _queue: Array = []
var _pending_next := ""
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

static func reading_time(text: String) -> float:
	return 2.5 + text.length() * 0.05

func play(conv: Dictionary) -> void:
	if conv.is_empty():
		return
	var prio: int = conv.get("priority", 1)
	if active:
		var cur_prio: int = current.get("priority", 1)
		if prio > cur_prio:
			_queue.push_front(conv)
			_finish()
			return
		if prio == 0:
			return    # idle chatter never queues behind a live call
		_queue.append(conv)
		return
	_show(conv)

func choose(index: int) -> void:
	if not awaiting_choice:
		return
	var opts: Array = current.get("options", [])
	if index < 0 or index >= opts.size():
		return
	var opt: Dictionary = opts[index]
	awaiting_choice = false
	GameState.trust += int(opt.get("trust", 0))
	for f in opt.get("set", []):
		GameState.set_flag(String(f))
	for f in opt.get("clear", []):
		GameState.clear_flag(String(f))
	_pending_next = String(opt.get("next", ""))
	AudioDirector.play_sfx("squelch")
	reply_shown.emit("CH-16 // CLARA (REPLY)", opt.get("reply", ""))
	_timer.start(reading_time(opt.get("reply", "")))

func dismiss() -> void:
	if active:
		_finish()

func _show(conv: Dictionary) -> void:
	active = true
	current = conv
	var opts: Array = conv.get("options", [])
	awaiting_choice = opts.size() > 0
	AudioDirector.play_sfx("squelch")
	line_shown.emit(conv.get("speaker", ""), conv.get("text", ""), opts)
	# Unanswered calls fall silent after a long grace period.
	_timer.start(30.0 if awaiting_choice else reading_time(conv.get("text", "")))

func _on_timeout() -> void:
	_finish()

func _finish() -> void:
	_timer.stop()
	active = false
	awaiting_choice = false
	current = {}
	var nxt := _pending_next
	_pending_next = ""
	if nxt != "":
		_queue.push_front(Conversations.get_conv(nxt))
	while _queue.size() > 0 and _queue[0].is_empty():
		_queue.pop_front()
	if _queue.size() > 0:
		_show.call_deferred(_queue.pop_front())    # a follow-up replaces the panel; no hide in between
	else:
		hidden.emit()
