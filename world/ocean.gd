class_name Ocean extends MeshInstance3D

const DETAIL := [36, 54, 72]       # grid subdivisions: low, medium, high

func _ready() -> void:
	set_detail(int(Settings.v("ocean_detail")))
	Settings.changed.connect(func(k: String):
		if k == "ocean_detail":
			set_detail(int(Settings.v("ocean_detail"))))
	if material_override == null:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://world/ocean.gdshader")
		material_override = mat
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_detail(level: int) -> void:
	var n: int = DETAIL[clampi(level, 0, 2)]
	var plane := PlaneMesh.new()
	plane.size = Vector2(520, 520)
	plane.subdivide_width = n
	plane.subdivide_depth = n
	mesh = plane

func _process(_delta: float) -> void:
	position.y = TideSystem.current_height

func set_wave_height(h: float) -> void:
	(material_override as ShaderMaterial).set_shader_parameter("wave_height", h)
