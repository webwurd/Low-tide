class_name Ocean extends MeshInstance3D

const DETAIL := [36, 54, 72]       # grid subdivisions: low, medium, high
const HEIGHT_TEX_SIZE := 192

static var _height_tex: ImageTexture

func _ready() -> void:
	set_detail(int(Settings.v("ocean_detail")))
	Settings.changed.connect(func(k: String):
		if k == "ocean_detail":
			set_detail(int(Settings.v("ocean_detail"))))
	if material_override == null:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://world/ocean.gdshader")
		mat.set_shader_parameter("height_tex", _terrain_texture())
		material_override = mat
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Terrain heights baked once into a float texture so the shader knows how deep the water is.
static func _terrain_texture() -> ImageTexture:
	if _height_tex == null:
		var n := HEIGHT_TEX_SIZE
		var img := Image.create(n, n, false, Image.FORMAT_RF)
		var size := 210.0
		for iz in n:
			for ix in n:
				var x := -size / 2.0 + (ix + 0.5) / n * size
				var z := -size / 2.0 + (iz + 0.5) / n * size
				img.set_pixel(ix, iz, Color(Terrain.height(x, z), 0, 0))
		_height_tex = ImageTexture.create_from_image(img)
	return _height_tex

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

func set_sky_color(c: Color) -> void:
	(material_override as ShaderMaterial).set_shader_parameter("sky_color", c)
