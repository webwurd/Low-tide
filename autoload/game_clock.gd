extends Node
## 1 game minute per real second outdoors; paused indoors/cutscenes.

const OUTDOOR_SCALE := 1.0
var day := 1
var minute_of_day := 360.0
var paused := true

signal day_changed(new_day: int)

func _process(delta: float) -> void:
	if paused:
		return
	advance(delta * OUTDOOR_SCALE)

func advance(minutes: float) -> void:
	minute_of_day += minutes
	while minute_of_day >= 1440.0:
		minute_of_day -= 1440.0
		day += 1
		day_changed.emit(day)

func hhmm() -> String:
	var m := int(minute_of_day)
	return "%02d:%02d" % [m / 60, m % 60]
