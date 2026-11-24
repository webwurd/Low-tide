class_name Ocean extends MeshInstance3D
## The sea. Rises and falls with TideSystem; swell size comes from the day's
## weather. Look lives in res://assets/materials/ocean.tres (built by the
## asset factory) so it can be tuned in the Inspector.

const MAT := "res://assets/materials/ocean.tres"

func _ready() -> void:
	var plane := PlaneMesh.new()
	var detailed := Settings.quality >= Settings.Quality.MEDIUM
	plane.size = Vector2(900, 900)
	plane.subdivide_width = 240 if detailed else 140
	plane.subdivide_depth = plane.subdivide_width
	mesh = plane
	if ResourceLoader.exists(MAT):
		material_override = load(MAT).duplicate()
	else:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://world/ocean.gdshader")
		material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 4.0

func _process(_delta: float) -> void:
	position.y = TideSystem.current_height

func set_wave_height(h: float) -> void:
	(material_override as ShaderMaterial).set_shader_parameter("wave_height", h)
