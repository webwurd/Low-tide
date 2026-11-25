@tool
class_name WeatherLook extends Resource
## How one day's weather bends the time-of-day look. One file per weather in
## res://art/looks/weather_<key>.tres (written by tools/build_assets.gd).

@export var cloud_cover := 0.35          ## 0 clear .. 1 solid overcast
@export var cloud_darkness := 0.0        ## storm clouds
@export var sun_scale := 1.0             ## direct light multiplier
@export var ambient_scale := 1.0
@export var saturation := 1.1
@export var sky_to_fog := 0.0            ## 0 keeps the painted sky, 1 washes it into the fog colour
@export var fog_scale := 1.0             ## multiplies DayData.fog_density
@export var fog_tint_amount := 0.55      ## how much DayData.fog_tint replaces the time-of-day fog colour
@export var height_fog := 0.03           ## extra fog density hugging the water
@export var volumetric_density := 0.012
@export var wind := 0.3                  ## sway + cloud drift
@export var wetness := 0.0               ## surfaces darken + gloss (rain)
@export var tint := Color(1, 1, 1)       ## final multiply on sky + fog

const KEYS := ["fog", "overcast", "dense_fog", "storm", "clear", "cold_clear", "dawn_haze"]

## Weather key for a DayData.weather string.
static func key_for(weather: String) -> String:
	match weather.to_lower():
		"fog": return "fog"
		"overcast": return "overcast"
		"dense fog": return "dense_fog"
		"storm": return "storm"
		"clear": return "clear"
		"cold, clear": return "cold_clear"
		_: return "dawn_haze"

static func for_weather(weather: String) -> WeatherLook:
	var key := key_for(weather)
	var p := "res://art/looks/weather_%s.tres" % key
	if ResourceLoader.exists(p):
		var w = load(p)
		if w is WeatherLook:
			return w
	return preset(key)

static func preset(key: String) -> WeatherLook:
	var w := WeatherLook.new()
	match key:
		"fog":
			w.cloud_cover = 0.8; w.sun_scale = 0.45; w.saturation = 1.0; w.sky_to_fog = 0.45
			w.fog_scale = 0.9; w.height_fog = 0.05; w.volumetric_density = 0.02; w.wind = 0.25
		"overcast":
			w.cloud_cover = 0.92; w.sun_scale = 0.3; w.ambient_scale = 1.1; w.saturation = 0.95
			w.sky_to_fog = 0.3; w.fog_scale = 0.9; w.height_fog = 0.02; w.volumetric_density = 0.012; w.wind = 0.45
		"dense_fog":
			w.cloud_cover = 0.95; w.sun_scale = 0.25; w.ambient_scale = 1.1; w.saturation = 0.9; w.sky_to_fog = 0.75
			w.fog_scale = 0.75; w.fog_tint_amount = 0.7; w.height_fog = 0.08; w.volumetric_density = 0.03; w.wind = 0.15
		"storm":
			w.cloud_cover = 1.0; w.cloud_darkness = 0.7; w.sun_scale = 0.08; w.ambient_scale = 0.9; w.saturation = 0.85
			w.sky_to_fog = 0.5; w.fog_scale = 0.8; w.fog_tint_amount = 0.7; w.height_fog = 0.04; w.volumetric_density = 0.025
			w.wind = 1.0; w.wetness = 1.0; w.tint = Color(0.86, 0.94, 0.96)
		"clear":
			w.cloud_cover = 0.28; w.sun_scale = 1.0; w.saturation = 1.18; w.sky_to_fog = 0.0
			w.fog_scale = 1.6; w.fog_tint_amount = 0.25; w.height_fog = 0.012; w.volumetric_density = 0.006; w.wind = 0.35
		"cold_clear":
			w.cloud_cover = 0.18; w.sun_scale = 1.0; w.saturation = 1.1; w.sky_to_fog = 0.0
			w.fog_scale = 1.6; w.fog_tint_amount = 0.3; w.height_fog = 0.015; w.volumetric_density = 0.007; w.wind = 0.2
			w.tint = Color(0.95, 0.98, 1.04)
		_:
			w.cloud_cover = 0.4; w.sun_scale = 0.75; w.saturation = 1.08; w.sky_to_fog = 0.35
			w.fog_scale = 1.0; w.fog_tint_amount = 0.35; w.height_fog = 0.05; w.volumetric_density = 0.018; w.wind = 0.05
	return w
