extends Node
## 1 game minute per real second outdoors; paused indoors / in cutscenes.

var time_scale := 1.0
var day := 1
var minute_of_day := 375.0      # 06:15
var paused := true
## The day only ends when Arthur sleeps; the clock stops at 23:59 until then.
var day_locked := true
const LAST_MINUTE := 1439.0

signal day_changed(new_day: int)

func _process(delta: float) -> void:
	if not paused:
		advance(delta * time_scale)

func abs_minute() -> float:
	return (day - 1) * 1440.0 + minute_of_day

func advance(minutes: float) -> void:
	minute_of_day += minutes
	if day_locked:
		minute_of_day = minf(minute_of_day, LAST_MINUTE)
		return
	while minute_of_day >= 1440.0:
		minute_of_day -= 1440.0
		day += 1
		day_changed.emit(day)

func set_time(d: int, minute: float) -> void:
	day = d
	minute_of_day = minute

func hhmm() -> String:
	var m := int(minute_of_day)
	var h24 := m / 60
	var h12 := h24 % 12
	if h12 == 0: h12 = 12
	return "%d:%02d %s" % [h12, m % 60, "pm" if h24 >= 12 else "am"]
