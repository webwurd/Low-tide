class_name PocketWatch extends Control
## Brass pocket watch drawn procedurally; hands follow GameClock.

func _ready() -> void:
	custom_minimum_size = Vector2(150, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_d: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	draw_circle(c, r + 4.0, Color("2a241b"))
	draw_arc(c, r + 3.0, 0, TAU, 48, Color("9c7c44"), 3.0)
	draw_circle(c, r - 2.0, Color("f3ebd9"))
	for i in 12:
		var a := TAU * i / 12.0
		var d := Vector2(sin(a), -cos(a))
		var major := i % 3 == 0
		draw_line(c + d * (r - (14.0 if major else 9.0)), c + d * (r - 4.0), Color("1e293b"), 2.5 if major else 1.2)
	var m := GameClock.minute_of_day
	var min_a := TAU * fmod(m, 60.0) / 60.0
	var hr_a := TAU * fmod(m / 60.0, 12.0) / 12.0
	draw_line(c, c + Vector2(sin(hr_a), -cos(hr_a)) * (r * 0.5), Color("0f172a"), 4.0)
	draw_line(c, c + Vector2(sin(min_a), -cos(min_a)) * (r * 0.8), Color("991b1b"), 2.5)
	draw_circle(c, 4.0, Color("9c7c44"))
