class_name Ocean extends MeshInstance3D
## The sea. Rises and falls with TideSystem; swell size comes from the day's
## weather; grid density follows the "ocean_detail" setting. Look lives in
## res://assets/materials/ocean.tres (built by the asset factory) so it can be
## tuned in the Inspector. Water depth comes from the depth buffer, so no
## terrain height texture is needed.

const MAT := "res://assets/materials/ocean.tres"
const SIZE := 900.0
## Grid subdivisions for low / medium / high. The Gerstner swell's shortest
## wave is ~6 m, so High keeps vertices under 4 m apart; Low halves that.
const DETAIL := [120, 180, 240]

## Speed of the water's motion: 1 in play, 0 freezes the sea (a new player's
## title screen). The shader reads `flow_time`, which only advances at this rate.
var time_scale := 1.0
var _flow_t := 0.0

func _ready() -> void:
	if ResourceLoader.exists(MAT):
		material_override = load(MAT).duplicate()
	else:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://world/ocean.gdshader")
		material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 4.0
	set_detail(int(Settings.v("ocean_detail")))
	Settings.changed.connect(func(k: String):
		if k == "ocean_detail":
			set_detail(int(Settings.v("ocean_detail"))))

func set_detail(level: int) -> void:
	var n: int = DETAIL[clampi(level, 0, 2)]
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	plane.subdivide_width = n
	plane.subdivide_depth = n
	mesh = plane

func _process(delta: float) -> void:
	position.y = TideSystem.current_height
	_flow_t += delta * time_scale
	(material_override as ShaderMaterial).set_shader_parameter("flow_time", _flow_t)

func set_wave_height(h: float) -> void:
	(material_override as ShaderMaterial).set_shader_parameter("wave_height", h)
