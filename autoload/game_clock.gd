extends Node
## 1 game minute per real second outdoors; paused indoors / in cutscenes.

var time_scale := 1.0
var day := 1
var minute_of_day := 375.0      # 06:15
var paused := true

signal day_changed(new_day: int)

func _process(delta: float) -> void:
	if not paused:
		advance(delta * time_scale)

func abs_minute() -> float:
	return (day - 1) * 1440.0 + minute_of_day

func advance(minutes: float) -> void:
	minute_of_day += minutes
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
	return "%02d:%02d %s" % [h12, m % 60, "PM" if h24 >= 12 else "AM"]
