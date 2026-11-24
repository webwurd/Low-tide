@tool
class_name Atmosphere extends Resource
## Time-of-day look for Gannet Rock in winter. Each array has one entry per key
## in `minutes`; values are interpolated (smoothly) between keys and wrap at
## midnight. Saved as res://art/looks/atmosphere.tres so it can be tuned in the
## Inspector; these defaults are what tools/build_assets.gd writes out.
## Sun: rises ~07:05 (SE), sets ~16:05 (SW), peaks ~24 deg in the south.

@export var minutes := PackedFloat32Array([
	0.0, 380.0, 405.0, 428.0, 470.0, 600.0, 720.0, 840.0, 915.0, 962.0, 990.0, 1030.0, 1440.0])
@export var sky_top := PackedColorArray([
	Color("060b14"), Color("08101c"), Color("232c48"), Color("3a4a70"), Color("4f7399"), Color("5a82ab"),
	Color("5b84ad"), Color("587ea6"), Color("4d6a92"), Color("3a4670"), Color("232a48"), Color("0a1220"), Color("060b14")])
@export var sky_horizon := PackedColorArray([
	Color("121d2b"), Color("162233"), Color("8e6a72"), Color("e8a07a"), Color("d6c6b4"), Color("c4d0d4"),
	Color("b7c9d4"), Color("c6c8c2"), Color("f0b07a"), Color("ec8a5e"), Color("a45a62"), Color("1d2536"), Color("121d2b")])
## Direct light colour and energy (the sun by day, the moon at night).
@export var sun_color := PackedColorArray([
	Color("7f95c4"), Color("7f95c4"), Color("6a6f9a"), Color("ff9a5c"), Color("ffcf9e"), Color("ffe6c8"),
	Color("fff0dc"), Color("ffe2bc"), Color("ffaa62"), Color("ff7a4a"), Color("8a6a9a"), Color("7f95c4"), Color("7f95c4")])
@export var sun_energy := PackedFloat32Array([
	0.22, 0.22, 0.05, 0.9, 1.7, 2.1, 2.2, 2.1, 1.85, 1.05, 0.05, 0.2, 0.22])
## Ambient (sky light) tint + energy. The sky itself drives ambient; this
## multiplies it so shadows keep their slate-violet colour.
@export var ambient_color := PackedColorArray([
	Color("41507a"), Color("41507a"), Color("5c5a7e"), Color("8a7a8e"), Color("97a2b8"), Color("a3b3c6"),
	Color("a8b8ca"), Color("a5afbf"), Color("a38a96"), Color("8a6a82"), Color("4e4a6e"), Color("3e4a70"), Color("41507a")])
@export var ambient_energy := PackedFloat32Array([
	0.55, 0.55, 0.6, 0.85, 1.0, 1.05, 1.05, 1.05, 1.0, 0.9, 0.7, 0.55, 0.55])
@export var fog_color := PackedColorArray([
	Color("0d1520"), Color("101a28"), Color("5a5266"), Color("b88a7c"), Color("a9b2b6"), Color("9fb0bc"),
	Color("9db2c0"), Color("a7b1b4"), Color("c99a7a"), Color("b67466"), Color("5a4458"), Color("121b29"), Color("0d1520")])
@export var cloud_lit := PackedColorArray([
	Color("1a2234"), Color("1d2638"), Color("a07a88"), Color("ffc49a"), Color("f2ece4"), Color("f4f2ee"),
	Color("f6f4f0"), Color("f2ebe0"), Color("ffcc96"), Color("ff9e72"), Color("8a5a72"), Color("1e2638"), Color("1a2234")])
@export var cloud_shade := PackedColorArray([
	Color("0b111c"), Color("0d1420"), Color("4a4462"), Color("8a6a7e"), Color("9eabbb"), Color("a6b6c6"),
	Color("a9b8c8"), Color("a2aab8"), Color("9a7a8e"), Color("7a5068"), Color("3a3050"), Color("0e1522"), Color("0b111c")])
@export var exposure := PackedFloat32Array([
	1.25, 1.25, 1.15, 1.0, 0.95, 0.92, 0.9, 0.92, 0.95, 1.0, 1.1, 1.25, 1.25])
@export var star_amount := PackedFloat32Array([
	1.0, 1.0, 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.9, 1.0])

## Sun path in degrees (azimuth from north, clockwise; north is -Z).
@export var sunrise_minute := 425.0
@export var sunset_minute := 965.0
@export var sunrise_azimuth := 122.0
@export var sunset_azimuth := 238.0
@export var noon_elevation := 24.0
@export var moon_azimuth := 160.0
@export var moon_elevation := 34.0

## Colour grade (per-channel curve applied after tonemapping).
@export var grade: Gradient

func _init() -> void:
	if grade == null:
		grade = Gradient.new()
		grade.offsets = PackedFloat32Array([0.0, 0.18, 0.55, 1.0])
		grade.colors = PackedColorArray([Color(0.035, 0.03, 0.07), Color(0.17, 0.165, 0.21), Color(0.56, 0.55, 0.53), Color(1.0, 0.975, 0.92)])

static func load_default() -> Atmosphere:
	var p := "res://art/looks/atmosphere.tres"
	if ResourceLoader.exists(p):
		var a = load(p)
		if a is Atmosphere:
			return a
	return Atmosphere.new()

## Returns the interpolated look at `minute` (0..1440) as a Dictionary.
func sample(minute: float) -> Dictionary:
	var m := fposmod(minute, 1440.0)
	var i := 0
	while i < minutes.size() - 2 and m >= minutes[i + 1]:
		i += 1
	var span := maxf(0.001, minutes[i + 1] - minutes[i])
	var t := clampf((m - minutes[i]) / span, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return {
		"sky_top": sky_top[i].lerp(sky_top[i + 1], t),
		"sky_horizon": sky_horizon[i].lerp(sky_horizon[i + 1], t),
		"sun_color": sun_color[i].lerp(sun_color[i + 1], t),
		"sun_energy": lerpf(sun_energy[i], sun_energy[i + 1], t),
		"ambient_color": ambient_color[i].lerp(ambient_color[i + 1], t),
		"ambient_energy": lerpf(ambient_energy[i], ambient_energy[i + 1], t),
		"fog_color": fog_color[i].lerp(fog_color[i + 1], t),
		"cloud_lit": cloud_lit[i].lerp(cloud_lit[i + 1], t),
		"cloud_shade": cloud_shade[i].lerp(cloud_shade[i + 1], t),
		"exposure": lerpf(exposure[i], exposure[i + 1], t),
		"stars": lerpf(star_amount[i], star_amount[i + 1], t),
	}

## 0 at night, 1 in full day (sun above the horizon), smooth at the edges.
func day_factor(minute: float) -> float:
	return smoothstep(sunrise_minute - 25.0, sunrise_minute + 20.0, minute) * \
		(1.0 - smoothstep(sunset_minute - 10.0, sunset_minute + 25.0, minute))

## Unit vector pointing from the world towards the sun.
func sun_direction(minute: float) -> Vector3:
	var t := (minute - sunrise_minute) / (sunset_minute - sunrise_minute)
	var az := deg_to_rad(lerpf(sunrise_azimuth, sunset_azimuth, t))
	var el := deg_to_rad(maxf(2.5, sin(clampf(t, 0.0, 1.0) * PI) * noon_elevation))
	return _dir(az, el)

func moon_direction(minute: float) -> Vector3:
	# Drifts slowly west through the night.
	var night_t := fposmod(minute - sunset_minute, 1440.0) / (1440.0 - (sunset_minute - sunrise_minute))
	var az := deg_to_rad(moon_azimuth + (night_t - 0.5) * 60.0)
	return _dir(az, deg_to_rad(moon_elevation))

static func _dir(az: float, el: float) -> Vector3:
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el)).normalized()
