extends Node
## Tide model. Extremes alternate low/high every HALF_CYCLE minutes on one
## continuous absolute timeline (minutes since 00:00 of day 1), so there are no
## discontinuities at midnight. Two cycles (1490 min) = one tidal day, which is
## why lows arrive ~50 min later each calendar day.
##
## Height between extremes is a cosine interpolation. Low-water height can be
## overridden per calendar day (day 5 = spring low).

const HALF_CYCLE := 372.5
const DAY_MINUTES := 1440.0
const FIRST_LOW_MINUTE := 450.0       # Day 1 low water at 07:30
const LOW_HEIGHT := 0.2
const HIGH_HEIGHT := 4.2
const SANDBAR_CLOSED_AT := 2.1        # bible: bars "submerge" above this
const SWEPT_DEPTH := 0.95
const LOW_OVERRIDES := {5: -0.4}      # calendar day -> low-water height

signal threshold_crossed(open: bool)
var current_height := 1.0
var _was_open := true

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	current_height = water_height_abs(GameClock.abs_minute())
	var open := sandbars_open(current_height)
	if open != _was_open:
		_was_open = open
		threshold_crossed.emit(open)

## Height of extreme number k (k even = low, k odd = high).
func _extreme_height(k: int) -> float:
	if k % 2 != 0:
		return HIGH_HEIGHT
	var t := FIRST_LOW_MINUTE + HALF_CYCLE * k
	var day := int(floor(t / DAY_MINUTES)) + 1
	return LOW_OVERRIDES.get(day, LOW_HEIGHT)

func water_height_abs(abs_minute: float) -> float:
	var k := int(floor((abs_minute - FIRST_LOW_MINUTE) / HALF_CYCLE))
	var t0 := FIRST_LOW_MINUTE + HALF_CYCLE * k
	var f := (abs_minute - t0) / HALF_CYCLE
	var s := (1.0 - cos(f * PI)) / 2.0
	return lerpf(_extreme_height(k), _extreme_height(k + 1), s)

func water_height(day: int, minute_of_day: float) -> float:
	return water_height_abs(DAY_MINUTES * (day - 1) + minute_of_day)

## First low-water time (minute of day) on a calendar day.
func low_minute_of_day(day: int) -> float:
	var day_start := DAY_MINUTES * (day - 1)
	var k := int(ceil((day_start - FIRST_LOW_MINUTE) / HALF_CYCLE))
	if k % 2 != 0:
		k += 1
	return FIRST_LOW_MINUTE + HALF_CYCLE * k - day_start

func sandbars_open(height: float) -> bool:
	return height <= SANDBAR_CLOSED_AT

func tide_label() -> String:
	var h := current_height
	var ahead := water_height_abs(GameClock.abs_minute() + 5.0)
	if h <= 0.9: return "LOW TIDE"
	if h >= 3.5: return "HIGH TIDE"
	return "RISING" if ahead > h else "FALLING"

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
