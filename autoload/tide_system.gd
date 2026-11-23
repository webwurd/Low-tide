extends Node
## Tide model. Water height is interpolated (cosine) between alternating
## low/high extremes spaced HALF_CYCLE apart. Lows drift ~50 min later per day.

const HALF_CYCLE := 372.5          # minutes between a low and the next high
const DAY_MINUTES := 1440.0
const FIRST_LOW_MINUTE := 450.0    # Day 1 low water at 07:30
const DAILY_DRIFT := 50.0
const LOW_HEIGHT := 0.2
const HIGH_HEIGHT := 4.2
const SANDBAR_CLOSED_AT := 2.1
const SWEPT_DEPTH := 0.95

# Per-day overrides of low-water height (day index starts at 1).
const LOW_OVERRIDES := {5: -0.4}

signal threshold_crossed(open: bool)
var _was_open := true

func low_minute_of_day(day: int) -> float:
	return FIRST_LOW_MINUTE + DAILY_DRIFT * (day - 1)

func _low_height(day: int) -> float:
	return LOW_OVERRIDES.get(day, LOW_HEIGHT)

## Absolute minutes since the start of day 1 -> water height in metres.
func water_height_abs(abs_minute: float, day: int = 1) -> float:
	var anchor := low_minute_of_day(day) + DAY_MINUTES * (day - 1)
	var phase := fposmod(abs_minute - anchor, HALF_CYCLE * 2.0) / (HALF_CYCLE * 2.0)
	var t := (1.0 - cos(phase * TAU)) / 2.0   # 0 at low, 1 at high
	return lerpf(_low_height(day), HIGH_HEIGHT, t)

func water_height(day: int, minute_of_day: float) -> float:
	return water_height_abs(minute_of_day + DAY_MINUTES * (day - 1), day)

func sandbars_open(height: float) -> bool:
	return height <= SANDBAR_CLOSED_AT

## Depth band by water depth at the player's feet.
func depth_band(depth: float) -> String:
	if depth <= 0.0: return "dry"
	if depth <= 0.3: return "splash"
	if depth <= 0.7: return "knee"
	if depth <= SWEPT_DEPTH: return "thigh"
	return "swept"

func speed_multiplier(depth: float) -> float:
	match depth_band(depth):
		"knee": return 0.6
		"thigh": return 0.35
		"swept": return 0.0
		_: return 1.0

func update_gate(height: float) -> void:
	var open := sandbars_open(height)
	if open != _was_open:
		_was_open = open
		threshold_crossed.emit(open)
