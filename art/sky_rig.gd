class_name SkyRig extends Node
## Owns the WorldEnvironment, the sky, the key light (sun by day, moon by
## night) and every post effect. Main calls `apply()` each frame; all look
## values come from the Atmosphere (time of day) and WeatherLook (per-day
## weather) resources so art can tune them without touching code.

const INDOOR_AMBIENT := Color("6a5846")

var atmos: Atmosphere
var env: Environment
var world_env: WorldEnvironment
var key_light: DirectionalLight3D
var sky_mat: ShaderMaterial
var cam_attr: CameraAttributesPractical
var look: WeatherLook
var _look_key := ""
var _quality := -1
var _indoors := -1

func _ready() -> void:
	atmos = Atmosphere.load_default()
	env = Environment.new()
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://art/sky.gdshader")
	sky_mat.set_shader_parameter("cloud_noise", load("res://art/cloud_noise.tres"))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Glow: lamps, windows and the low sun bloom softly.
	env.glow_enabled = true
	env.glow_normalized = false
	env.glow_intensity = 0.6
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.95
	env.glow_hdr_scale = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	for i in 7:
		env.set_glow_level(i, [0.0, 0.0, 1.0, 0.0, 1.0, 0.6, 0.0][i])
	# Grade.
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.05
	var grade_tex := GradientTexture1D.new()
	grade_tex.gradient = atmos.grade
	grade_tex.width = 256
	env.adjustment_color_correction = grade_tex
	# Fog (exponential + height) and volumetric fog for light shafts.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.4
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 110.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_ambient_inject = 0.35
	env.volumetric_fog_gi_inject = 0.5
	env.volumetric_fog_sky_affect = 0.0
	env.volumetric_fog_temporal_reprojection_enabled = true
	# SSAO / SSIL / SDFGI tuned for a 200 m island; gated by quality.
	env.ssao_radius = 1.6
	env.ssao_intensity = 1.5
	env.ssao_power = 1.6
	env.ssao_detail = 0.4
	env.ssao_light_affect = 0.12
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.7
	env.sdfgi_use_occlusion = true
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.35
	env.sdfgi_energy = 0.85
	env.sdfgi_bounce_feedback = 0.35
	env.sdfgi_read_sky_light = true
	env.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT
	world_env = WorldEnvironment.new()
	world_env.environment = env
	cam_attr = CameraAttributesPractical.new()
	cam_attr.dof_blur_far_enabled = true
	cam_attr.dof_blur_far_distance = 150.0
	cam_attr.dof_blur_far_transition = 140.0
	cam_attr.dof_blur_amount = 0.04
	world_env.camera_attributes = cam_attr
	add_child(world_env)

	key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.shadow_enabled = true
	key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key_light.directional_shadow_blend_splits = true
	key_light.directional_shadow_split_1 = 0.06
	key_light.directional_shadow_split_2 = 0.18
	key_light.directional_shadow_split_3 = 0.45
	key_light.shadow_bias = 0.03
	key_light.shadow_normal_bias = 1.4
	key_light.shadow_blur = 1.5
	key_light.light_angular_distance = 0.6
	key_light.light_volumetric_fog_energy = 1.3
	add_child(key_light)
	Settings.changed.connect(func(_k): _apply_quality())
	_apply_quality()

## Effect tier from the Settings quality preset: 0 = Low / Steam Deck,
## 1 = Medium, 2 = High; a Custom preset follows the shadow quality.
## Anti-aliasing and render scale are applied by Settings itself.
static func tier() -> int:
	match int(Settings.v("quality_preset")):
		0, 3: return 0
		1: return 1
		2: return 2
		_: return clampi(int(Settings.v("shadow_quality")) - 1, 0, 2)

func _apply_quality() -> void:
	var t := tier()
	env.sdfgi_enabled = t == 2
	env.ssil_enabled = t == 2
	env.ssao_enabled = t >= 1
	env.volumetric_fog_enabled = t >= 1
	cam_attr.dof_blur_far_enabled = t >= 1 and not bool(Settings.v("reduce_motion"))
	key_light.light_angular_distance = 0.6 if t == 2 else 0.0
	key_light.directional_shadow_max_distance = maxf(Settings.shadow_distance(), 1.0)
	env.glow_enabled = bool(Settings.v("glow"))
	env.adjustment_brightness = float(Settings.v("brightness"))

## Day factor: 0 at night .. 1 in full daylight.
func daylight(minute: float) -> float:
	return atmos.day_factor(minute)

func set_weather(dd: DayData) -> void:
	var key := WeatherLook.key_for(dd.weather)
	if key != _look_key:
		_look_key = key
		look = WeatherLook.for_weather(dd.weather)

func apply(outdoors: bool, minute: float, dd: DayData) -> void:
	set_weather(dd)
	if not outdoors:
		_apply_indoor(minute)
		return
	if _indoors != 0:
		_indoors = 0
		env.background_mode = Environment.BG_SKY
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.fog_enabled = true
		key_light.visible = true
	var s := atmos.sample(minute)
	var w := look
	var day := atmos.day_factor(minute)
	var cover := w.cloud_cover

	# Fog colour: time-of-day fog, pulled towards the day's tint by daylight.
	var fog_col: Color = s.fog_color.lerp(dd.fog_tint, w.fog_tint_amount * day) * w.tint
	var horizon: Color = (s.sky_horizon as Color) * w.tint
	var top: Color = (s.sky_top as Color).lerp(fog_col, cover * 0.35 * day) * w.tint
	sky_mat.set_shader_parameter("top_color", top)
	sky_mat.set_shader_parameter("horizon_color", horizon)
	sky_mat.set_shader_parameter("ground_color", fog_col.darkened(0.35))
	sky_mat.set_shader_parameter("fog_color", fog_col)
	sky_mat.set_shader_parameter("horizon_haze", clampf(0.45 + cover * 0.4, 0.0, 1.0))
	sky_mat.set_shader_parameter("sky_to_fog", w.sky_to_fog)
	sky_mat.set_shader_parameter("energy", 1.0)
	sky_mat.set_shader_parameter("cloud_cover", cover)
	sky_mat.set_shader_parameter("cloud_darkness", w.cloud_darkness)
	sky_mat.set_shader_parameter("cloud_speed", 0.002 + w.wind * 0.006)
	sky_mat.set_shader_parameter("cloud_lit", (s.cloud_lit as Color).lerp(fog_col, w.sky_to_fog * 0.5))
	sky_mat.set_shader_parameter("cloud_shade", (s.cloud_shade as Color).lerp(fog_col, w.sky_to_fog * 0.5))
	sky_mat.set_shader_parameter("stars", s.stars * (1.0 - cover))

	# Key light: the sun while it is up, the moon after dusk.
	# Key light: the sun while it is up, the moon after dusk. It fades to zero
	# across each twilight swap so shadows and colour never jump.
	var kl := atmos.key_light(minute)
	var is_sun: bool = kl["is_sun"]
	var fade: float = kl["fade"]
	var dir: Vector3 = kl["dir"]
	var sun_vis := clampf(1.0 - (cover - 0.55) * 2.6, 0.0, 1.0)
	var key_e: float = s.sun_energy * dd.light_scale * (w.sun_scale if is_sun else lerpf(1.0, 0.45, cover)) * fade
	var key_c: Color = s.sun_color
	key_light.basis = Basis.looking_at(-dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD)
	key_light.light_color = key_c
	key_light.light_energy = key_e
	key_light.shadow_enabled = key_e > 0.06 and fade > 0.02 and Settings.shadow_distance() > 0.0
	key_light.directional_shadow_max_distance = maxf(Settings.shadow_distance(), 1.0)
	sky_mat.set_shader_parameter("sun_dir", atmos.sun_direction(minute))
	sky_mat.set_shader_parameter("sun_color", key_c if is_sun else Color("ff9a5c"))
	sky_mat.set_shader_parameter("sun_visible", sun_vis * (1.0 if is_sun else 0.0))
	sky_mat.set_shader_parameter("sun_glow", lerpf(0.4, 1.0, sun_vis))
	sky_mat.set_shader_parameter("moon_dir", atmos.moon_direction(minute))
	sky_mat.set_shader_parameter("moon_visible", (1.0 - day) * (1.0 - cover * 0.85))

	# Ambient: mostly sky, tinted so shadows stay slate-violet.
	env.ambient_light_sky_contribution = 0.7
	env.ambient_light_color = s.ambient_color
	env.ambient_light_energy = s.ambient_energy * w.ambient_scale * lerpf(0.75, 1.0, dd.light_scale) \
		+ float(Settings.v("night_assist")) * (1.0 - day) * 0.45
	env.tonemap_exposure = s.exposure * float(Settings.v("exposure"))
	env.adjustment_brightness = float(Settings.v("brightness"))
	env.glow_enabled = bool(Settings.v("glow"))

	env.fog_light_color = fog_col
	env.fog_light_energy = 1.0
	var fog_k := float(Settings.v("fog_scale"))
	env.fog_density = dd.fog_density * w.fog_scale * fog_k
	env.fog_sun_scatter = 0.35 * day * sun_vis
	env.fog_height = TideSystem.current_height + 2.5
	env.fog_height_density = w.height_fog
	env.volumetric_fog_density = w.volumetric_density * fog_k
	env.volumetric_fog_albedo = fog_col.lightened(0.3)
	env.volumetric_fog_emission = fog_col
	env.volumetric_fog_emission_energy = 0.04
	env.adjustment_saturation = w.saturation

	RenderingServer.global_shader_parameter_set("sun_dir", dir)
	RenderingServer.global_shader_parameter_set("sun_color", key_c * clampf(key_e / 2.0, 0.0, 1.5))
	RenderingServer.global_shader_parameter_set("daylight", day)
	RenderingServer.global_shader_parameter_set("wetness", w.wetness)
	RenderingServer.global_shader_parameter_set("wind", w.wind)
	RenderingServer.global_shader_parameter_set("fog_tint", fog_col)
	RenderingServer.global_shader_parameter_set("tide_height", TideSystem.current_height)
	RenderingServer.global_shader_parameter_set("shadow_tint", (s.ambient_color as Color).darkened(0.45))

## Sky colours for interior window views: [top, horizon, sea].
func outside_colors(minute: float, dd: DayData) -> Array:
	set_weather(dd)
	var s := atmos.sample(minute)
	var day := atmos.day_factor(minute)
	var fog_col: Color = (s.fog_color as Color).lerp(dd.fog_tint, look.fog_tint_amount * day) * look.tint
	var horizon: Color = (s.sky_horizon as Color).lerp(fog_col, look.sky_to_fog) * look.tint
	var top: Color = (s.sky_top as Color).lerp(fog_col, look.cloud_cover * 0.5) * look.tint
	return [top, horizon, fog_col.darkened(0.45)]

func _apply_indoor(minute: float) -> void:
	if _indoors != 1:
		_indoors = 1
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.BLACK
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.fog_enabled = false
		key_light.visible = false
	env.ambient_light_color = INDOOR_AMBIENT
	env.ambient_light_energy = 0.35
	env.tonemap_exposure = float(Settings.v("exposure"))
	env.adjustment_brightness = float(Settings.v("brightness"))
	env.glow_enabled = bool(Settings.v("glow"))
	env.volumetric_fog_density = 0.006
	env.volumetric_fog_albedo = Color("d8c8b0")
	env.volumetric_fog_emission_energy = 0.0
	env.adjustment_saturation = 1.08
	RenderingServer.global_shader_parameter_set("daylight", atmos.day_factor(minute))
	RenderingServer.global_shader_parameter_set("wetness", 0.0)
	RenderingServer.global_shader_parameter_set("shadow_tint", Color("3a2c2a"))
