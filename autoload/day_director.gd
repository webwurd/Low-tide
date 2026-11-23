extends Node
## Runs the daily structure: Morning rituals -> Expedition -> Evening.
## Pure state + rules; Main performs the travel/fades/lighting.

enum Phase { MORNING, EXPEDITION, EVENING }

signal phase_changed(phase: int)
signal ritual_done(id: String)
signal day_started(day: int)
signal week_ended

const FIRST_FOUR := ["stove", "weights", "barometer", "tide_table"]
const RITUALS := ["stove", "weights", "barometer", "tide_table", "checkin"]
const DUSK_MINUTE := 990.0          # 16:30 Clara nudges
const FORCED_HOME_MINUTE := 1260.0  # 21:00 Arthur heads in on his own

var phase := Phase.MORNING
var rituals: Dictionary = {}
var weights_wound := false
var lamp_lit := false
var log_written := false
var evening_call_done := false
var dusk_nudged := false

func data() -> DayData:
	return Days.get_day(GameClock.day)

func begin_day(day: int) -> void:
	GameClock.set_time(day, Days.WAKE_MINUTE)
	rituals.clear()
	weights_wound = false
	lamp_lit = false
	log_written = false
	evening_call_done = false
	dusk_nudged = false
	_set_phase(Phase.MORNING)
	day_started.emit(day)

func _set_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)

func complete_ritual(id: String) -> void:
	if rituals.has(id):
		return
	rituals[id] = true
	if id == "weights":
		weights_wound = true
	ritual_done.emit(id)

func ritual_count() -> int:
	return rituals.size()

func can_check_in() -> bool:
	for r in FIRST_FOUR:
		if not rituals.has(r):
			return false
	return true

func morning_complete() -> bool:
	return rituals.size() >= RITUALS.size()

func step_outside() -> void:
	if phase == Phase.MORNING:
		_set_phase(Phase.EXPEDITION)

func lamp_ready() -> bool:
	return GameClock.minute_of_day >= data().lamp_after

func light_lamp() -> void:
	lamp_lit = true
	_set_phase(Phase.EVENING)

func force_evening() -> void:
	if phase != Phase.EVENING:
		_set_phase(Phase.EVENING)

func write_log() -> void:
	if log_written:
		return
	log_written = true
	GameState.add_log(GameClock.day, LogEntries.compose(GameClock.day))

func start_evening_call() -> void:
	evening_call_done = true

func can_sleep() -> bool:
	return lamp_lit and log_written and evening_call_done

func sleep_blockers() -> String:
	if not lamp_lit: return "The lamp isn't lit yet."
	if not log_written: return "I haven't written up the log."
	if not evening_call_done: return "I should call Clara before turning in."
	return ""

## Ends the day. Returns false when the final day has been completed.
func sleep() -> bool:
	if GameClock.day >= Days.LAST_DAY:
		week_ended.emit()
		return false
	begin_day(GameClock.day + 1)
	return true

func to_dict() -> Dictionary:
	return {"phase": phase, "rituals": rituals, "weights_wound": weights_wound, "lamp_lit": lamp_lit,
		"log_written": log_written, "evening_call_done": evening_call_done, "dusk_nudged": dusk_nudged}

func from_dict(d: Dictionary) -> void:
	phase = int(d.get("phase", 0))
	rituals = d.get("rituals", {})
	weights_wound = d.get("weights_wound", false)
	lamp_lit = d.get("lamp_lit", false)
	log_written = d.get("log_written", false)
	evening_call_done = d.get("evening_call_done", false)
	dusk_nudged = d.get("dusk_nudged", false)
