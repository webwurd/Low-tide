class_name SkyModel
## Pure maths for the sky: where the sun and moon are at a given minute, and the
## colour palette for that light. No nodes, so it is unit-tested headless.
## Winter Maine: a low sun that rises in the east (+x), crosses the south (+z)
## and sets in the west (-x). Sunrise ~06:50, sunset ~16:30.

const RISE := 400.0
const SET := 1000.0
const MAX_ELEVATION := 0.42          # radians (~24 deg): a low winter sun

# name: [zenith, horizon, glow]
const PALETTE_NIGHT := ["080d1c", "1a2842", "3a4f7a"]
const PALETTE_TWILIGHT := ["1f2d55", "d8785c", "ff8a5a"]
const PALETTE_GOLDEN := ["46709f", "f0b27a", "ffa050"]
const PALETTE_DAY := ["5b8fbf", "c9dde6", "fff0cc"]

## Unit vector pointing at the sun. y < 0 means below the horizon.
static func sun_dir(minute: float) -> Vector3:
	var a := (minute - RISE) / (SET - RISE) * PI
	var e := sin(a) * MAX_ELEVATION
	return Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e)).normalized()

## The moon rides opposite the sun, a little higher so it clears the sea haze.
static func moon_dir(minute: float) -> Vector3:
	var s := sun_dir(minute)
	return Vector3(-s.x, clampf(-s.y * 1.4, -1.0, 1.0), -s.z).normalized()

static func _c(hex: String) -> Color:
	return Color(hex)

static func _mix(a: Array, b: Array, t: float) -> Array:
	return [_c(a[0]).lerp(_c(b[0]), t), _c(a[1]).lerp(_c(b[1]), t), _c(a[2]).lerp(_c(b[2]), t)]

## Colour bands for a sun height (sun_dir().y). Continuous in `h`.
static func bands(h: float) -> Array:
	if h < -0.2:
		return _mix(PALETTE_NIGHT, PALETTE_NIGHT, 0.0)
	if h < 0.0:
		return _mix(PALETTE_NIGHT, PALETTE_TWILIGHT, smoothstep(-0.2, 0.0, h))
	if h < 0.08:
		return _mix(PALETTE_TWILIGHT, PALETTE_GOLDEN, smoothstep(0.0, 0.08, h))
	if h < 0.26:
		return _mix(PALETTE_GOLDEN, PALETTE_DAY, smoothstep(0.08, 0.26, h))
	return _mix(PALETTE_DAY, PALETTE_DAY, 0.0)

## Full sky description for the shader and the scene lighting.
##   cloud: 0 clear .. 1 overcast;  fog_tint/fog_density from DayData;
##   light_scale: DayData.light_scale (storms are dark).
static func describe(minute: float, cloud: float, fog_tint: Color, fog_density: float, light_scale: float) -> Dictionary:
	var sd := sun_dir(minute)
	var h := sd.y
	var b := bands(h)
	var zenith: Color = b[0]
	var horizon: Color = b[1]
	var glow: Color = b[2]
	# Overcast pulls the whole sky toward a flat grey-blue that follows the day's fog tint.
	var day_amt := smoothstep(-0.12, 0.2, h)
	var grey := fog_tint.lerp(Color.WHITE, 0.18) * Color(1, 1, 1, 1)
	var over := clampf(cloud, 0.0, 1.0)
	var murk := pow(over, 1.4) * 0.85
	zenith = zenith.lerp(grey.darkened(0.12 + (1.0 - light_scale) * 0.5), murk * day_amt)
	horizon = horizon.lerp(grey, murk * 0.7 * day_amt)
	# Warmth survives overcast only a little; clear days keep their glow.
	var glow_str := (1.0 - murk * 0.75) * smoothstep(-0.12, 0.05, h) * (1.0 - smoothstep(0.1, 0.4, h) * 0.6)
	# Fog: the horizon band is the fog colour, and thick fog climbs the sky.
	var night_fog := Color("0d1520")
	var fog_col := night_fog.lerp(fog_tint, clampf(day_amt * light_scale, 0.0, 1.0))
	var golden := (1.0 - smoothstep(0.08, 0.3, h)) * smoothstep(-0.12, 0.04, h)
	fog_col = fog_col.lerp(horizon.lerp(glow, 0.35), golden * 0.45 * (1.0 - murk * 0.6))
	var haze := clampf(fog_density * 18.0, 0.12, 1.4)
	var star := 1.0 - smoothstep(-0.22, -0.02, h)
	star *= (1.0 - over * 0.85)
	return {
		"sun_dir": sd,
		"moon_dir": moon_dir(minute),
		"zenith": zenith,
		"horizon": horizon,
		"glow": glow,
		"glow_strength": glow_str,
		"fog_color": fog_col,
		"haze_height": haze,
		"cloud": over,
		"stars": star,
		"sun_height": h,
		"golden": golden,
	}

## Warm, low light at dawn/dusk, cool pale light at noon. (Moonlight is a separate light.)
static func sun_light_color(h: float, cloud: float) -> Color:
	var warm := Color("ff9f5a")
	var mid := Color("ffd9a8")
	var noon := Color("e6eef5")
	var c := warm.lerp(mid, smoothstep(0.0, 0.12, h)).lerp(noon, smoothstep(0.12, 0.3, h))
	return c.lerp(Color("c8d3dc"), clampf(cloud, 0.0, 1.0) * 0.6)
