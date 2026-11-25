class_name SeaWind extends RefCounted
## The living sea and wind: a cheap control model (a few floats per frame) that
## drives the ambient bed layers in AudioDirector so the soundscape never settles
## into a pattern.
##
## Sea: waves arrive at random intervals. Each builds (the body layer swells), breaks
## (a burst of foam, the filter opens), then washes back up the shingle over several
## seconds. Every minute or two a set of 3-5 bigger waves rolls in with longer washes.
## Wind: a slow lull/drift (two incommensurate cycles, ~47 s and ~83 s) plus random
## gusts that rise, hold and fall; gusts bring up a whistling layer and push the band
## of the wind upward.
## Everything scales with the day's weather (wave height, wind, fog, rain).

const SET_SIZE := Vector2i(3, 5)

var rng := RandomNumberGenerator.new()
var profile: Dictionary = {}
var t := 0.0

# sea state
var _waves: Array = []           # [age, amp, build, wash]
var _next_wave := 1.5
var _next_set := 45.0
var _set_left := 0
var body := 0.0                  # 0..~1.5: water moving (wash layer)
var foam := 0.0                  # 0..~1.5: breaking fizz
var deep := 0.5                  # slow ground swell

# wind state
var gust := 0.0                  # 0..1 current gust strength (smoothed)
var _gust_target := 0.0
var _gust_hold := 0.0
var _next_gust := 6.0
var lull := 0.5

func _init(seed_value := -1) -> void:
	if seed_value < 0:
		rng.randomize()          # a different sea every session
	else:
		rng.seed = seed_value
	profile = profile_for(0.14, 0.0, 0.011, false)
	t = rng.randf() * 500.0       # random phase for the slow drifts
	_next_set = rng.randf_range(20.0, 60.0)

## The day's weather as sea and wind behaviour.
## wave_height (m, 0.06 still .. 0.45 storm), wind_db (0..8 extra), fog density, rain.
static func profile_for(wave_height: float, wind_db: float, fog: float, rain: bool) -> Dictionary:
	var storm := clampf(maxf(wind_db / 8.0, 1.0 if rain else 0.0), 0.0, 1.0)
	var calm := clampf((0.14 - wave_height) / 0.08, 0.0, 1.0)     # 1 = glassy (Day 7)
	var foggy := clampf((fog - 0.012) / 0.028, 0.0, 1.0)            # 1 = dense fog (Day 3)
	var clear := clampf((0.008 - fog) / 0.005, 0.0, 1.0) * (1.0 - storm)
	return {
		"storm": storm, "calm": calm, "foggy": foggy, "clear": clear,
		# seconds between waves (min, max); storms pound, clear days are sparser
		"wave_min": lerpf(6.5, 3.8, storm) + calm * 3.0 + clear * 1.5,
		"wave_max": lerpf(12.0, 6.5, storm) + calm * 5.0 + clear * 3.0,
		"set_min": lerpf(80.0, 35.0, storm), "set_max": lerpf(160.0, 70.0, storm),
		"wave_amp": clampf(0.75 + (wave_height - 0.14) * 1.5, 0.45, 1.2),
		"surf_db": clampf((wave_height - 0.14) * 12.0, -2.5, 1.5) - foggy * 1.5,
		"foam": lerpf(0.55, 1.0, storm) * (1.0 - 0.35 * foggy) * (1.0 - 0.4 * calm),
		"cut_lo": lerpf(420.0, 520.0, storm) * (1.0 - 0.35 * foggy),
		"cut_hi": lerpf(1500.0, 2200.0, storm) * (1.0 - 0.45 * foggy) * (1.0 + 0.15 * clear),
		# wind
		"gust_every": lerpf(26.0, 5.0, storm) + calm * 25.0,
		"gust_depth": lerpf(0.4, 1.0, storm) * (1.0 - 0.6 * calm),
		"wind_base": lerpf(0.85, 0.8, storm) * (1.0 - 0.45 * calm),
		"band": lerpf(560.0, 680.0, storm) * (1.0 - 0.2 * foggy),
	}

func set_weather(wave_height: float, wind_db: float, fog: float, rain: bool) -> void:
	profile = profile_for(wave_height, wind_db, fog, rain)

## Advance the model by dt seconds.
func step(dt: float) -> void:
	t += dt
	_step_sea(dt)
	_step_wind(dt)

func _step_sea(dt: float) -> void:
	var p := profile
	_next_set -= dt
	if _next_set <= 0.0:
		_set_left = rng.randi_range(SET_SIZE.x, SET_SIZE.y)
		_next_set = rng.randf_range(p["set_min"], p["set_max"])
		_next_wave = minf(_next_wave, 2.0)
	_next_wave -= dt
	if _next_wave <= 0.0:
		var big := _set_left > 0
		var amp: float = p["wave_amp"] * (rng.randf_range(1.05, 1.4) if big else rng.randf_range(0.45, 1.0))
		var build := rng.randf_range(1.6, 3.0) * (1.25 if big else 1.0)
		var wash := rng.randf_range(2.8, 5.5) * (1.6 if big else 1.0)
		_waves.append([0.0, amp, build, wash])
		if big:
			_set_left -= 1
		var gap := rng.randf_range(p["wave_min"], p["wave_max"])
		var roll := rng.randf()
		if roll < 0.22:
			gap *= rng.randf_range(0.35, 0.6)       # a quick follow-up wave
		elif roll < 0.4:
			gap *= rng.randf_range(1.5, 2.2)        # a lull
		_next_wave = gap * (0.75 if _set_left > 0 else 1.0)
	var b := 0.0
	var f := 0.0
	var i := 0
	while i < _waves.size():
		var w: Array = _waves[i]
		w[0] += dt
		var age: float = w[0]
		var amp: float = w[1]
		var build: float = w[2]
		var wash: float = w[3]
		if age < build:
			var k := age / build
			b += amp * k * k
		else:
			var after := age - build
			b += amp * exp(-after / wash)
			f += amp * minf(1.0, after / 0.12) * exp(-after / (wash * 0.3))
		if age > build + wash * 4.0:
			_waves.remove_at(i)
		else:
			i += 1
	body = minf(b, 1.6)
	foam = minf(f * float(p["foam"]), 1.6)
	# Ground swell: two slow incommensurate cycles, nudged by recent breaks.
	deep = 0.5 + 0.22 * sin(t * TAU / 61.0) + 0.18 * sin(t * TAU / 97.0 + 2.1) + 0.15 * minf(body, 1.0)

func _step_wind(dt: float) -> void:
	var p := profile
	lull = 0.5 + 0.25 * sin(t * TAU / 47.0) + 0.25 * sin(t * TAU / 83.0 + 1.3)
	_next_gust -= dt
	if _next_gust <= 0.0 and _gust_target == 0.0:
		_gust_target = rng.randf_range(0.35, 1.0) * float(p["gust_depth"])
		_gust_hold = rng.randf_range(0.8, 4.0)
		_next_gust = -log(maxf(rng.randf(), 0.02)) * float(p["gust_every"]) + 2.0   # Poisson arrivals
	if _gust_target > 0.0 and gust >= _gust_target - 0.02:
		_gust_hold -= dt
		if _gust_hold <= 0.0:
			_gust_target = 0.0
	var rate := rng.randf_range(0.3, 0.7) if _gust_target > gust else rng.randf_range(0.12, 0.3)
	gust = move_toward(gust, _gust_target, dt * rate)

## Linear gains (0..~1.6) for each bed layer, and the two filter cutoffs (Hz).
func mix() -> Dictionary:
	var p := profile
	return {
		"wash": 0.4 + 0.6 * body,
		"deep": deep,
		"foam": foam,
		"sea_cut": lerpf(p["cut_lo"], p["cut_hi"], clampf(foam * 0.8 + body * 0.2, 0.0, 1.0)),
		"wind": p["wind_base"] * (0.55 + 0.45 * lull) + gust * 0.4,
		"whistle": pow(gust, 1.5) * (0.4 + 0.6 * float(p["storm"])),
		"wind_cut": p["band"] * (1.0 + 0.9 * gust + 0.25 * (lull - 0.5)),
	}

## 0..1 "how big is the sea right now" (replaces the old fixed sine swell).
func swell() -> float:
	return clampf(body * 0.75, 0.0, 1.0)
