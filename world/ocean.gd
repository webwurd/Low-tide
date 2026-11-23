class_name Ocean extends MeshInstance3D

func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(520, 520)
	plane.subdivide_width = 72
	plane.subdivide_depth = 72
	mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = load("res://world/ocean.gdshader")
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(_delta: float) -> void:
	position.y = TideSystem.current_height
