class_name Days
## The seven days. Weather and structure are final-ish; the radio text they
## point at is placeholder until M6.

const WAKE_MINUTE := 390.0     # 06:30
const LAST_DAY := 7

static var _cache: Dictionary = {}

static func get_day(n: int) -> DayData:
	n = clampi(n, 1, LAST_DAY)
	if not _cache.has(n):
		_cache[n] = _build(n)
	return _cache[n]

static func _mk(n: int, title: String, weather: String, baro: String, fog: float, tint: String,
		light := 1.0, rain := false, wave := 0.14, wind := 0.0, lamp_after := 900.0) -> DayData:
	var d := DayData.new()
	d.day = n; d.title = title; d.weather = weather; d.barometer = baro
	d.fog_density = fog; d.fog_tint = Color(tint); d.light_scale = light
	d.rain = rain; d.wave_height = wave; d.wind_db = wind; d.lamp_after = lamp_after
	d.morning_conv = "morning_d%d" % n
	d.evening_conv = "evening_d%d" % n
	return d

static func _build(n: int) -> DayData:
	match n:
		1: return _mk(1, "First Watch", "Fog", "Barometer: 30.1 and steady. Fog, then.", 0.011, "526373")
		2: return _mk(2, "Grey Water", "Overcast", "Barometer: 29.9, easing down. Grey all day.", 0.008, "5a6670", 0.9)
		3: return _mk(3, "Wool", "Dense fog", "Barometer: 30.0. The glass is calm; the fog is thick as wool.", 0.040, "6a7882", 0.75)
		4: return _mk(4, "The Blow", "Storm", "Barometer: 28.7 and falling. The needle's nearly off the dial.", 0.017, "3d4852", 0.5, true, 0.45, 8.0, 600.0)
		5: return _mk(5, "Spring Low", "Clear", "Barometer: 30.5, high and clean. A cold, clear one.", 0.003, "6f8ba3", 1.0, false, 0.1)
		6: return _mk(6, "Frost", "Cold, clear", "Barometer: 30.4. Frost on the inside of the window.", 0.004, "7894a8", 1.0, false, 0.1)
		_: return _mk(7, "Last Light", "Still, dawn haze", "Barometer: 30.2. Not a breath of wind.", 0.006, "8a8f94", 1.0, false, 0.06)
