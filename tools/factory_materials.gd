class_name FactoryMaterials
## Writes the material library to res://assets/materials/*.tres.
## Painterly materials share art/painterly.gdshader; a few special surfaces
## (glass, glow, paper) are StandardMaterial3D. Tune any of them in the
## Inspector afterwards: re-running the factory overwrites them, so move a
## hand-tuned material out of the list below (or edit the values here).

const DIR := "res://assets/materials/"
const TEX := "res://assets/textures/"

static func build_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var P := {}   # name -> [albedo, texture, scale, extra params]
	# Lighthouse + exteriors
	P["whitewash"] = ["e4e1d8", "stone_courses", 0.22, {"roughness": 0.82, "normal_strength": 0.7, "macro_strength": 0.3}]
	P["keeper_red"] = ["8f2d2d", "stone_courses", 0.22, {"roughness": 0.66, "normal_strength": 0.6, "macro_strength": 0.25}]
	P["red_paint"] = ["8a2c2a", "wood", 0.7, {"roughness": 0.55, "detail_strength": 0.6}]
	P["green_paint"] = ["2f4a3e", "wood", 0.7, {"roughness": 0.55, "detail_strength": 0.6}]
	P["trim_white"] = ["e2ded2", "wood", 0.8, {"roughness": 0.7, "detail_strength": 0.6, "normal_strength": 0.3}]
	P["clapboard"] = ["74828a", "clapboard", 0.55, {"roughness": 0.84, "normal_strength": 0.9}]
	P["shingle"] = ["7a3330", "shingle", 0.6, {"roughness": 0.9, "normal_strength": 1.0, "wet_response": 1.0}]
	P["granite"] = ["8a8480", "granite", 0.22, {"roughness": 0.92, "normal_strength": 0.8, "tide_wet": true, "macro_strength": 0.35, "macro_tint": Color("ffe4dc"), "object_space": false}]
	P["granite_dark"] = ["5a6064", "granite", 0.3, {"roughness": 0.9, "normal_strength": 0.9, "tide_wet": true, "macro_strength": 0.35, "macro_tint": Color("e0f0ff"), "object_space": false}]
	P["brick"] = ["7a4a3e", "stone_courses", 0.9, {"roughness": 0.9, "normal_strength": 1.2}]
	P["iron"] = ["2c3237", "rust", 0.6, {"roughness": 0.5, "metallic": 0.55, "detail_strength": 0.45, "specular": 0.5}]
	P["rust_metal"] = ["6d6863", "rust", 0.5, {"roughness": 0.72, "metallic": 0.25, "tide_wet": true}]
	P["brass"] = ["d0a04a", "rust", 0.8, {"roughness": 0.32, "metallic": 0.9, "detail_strength": 0.2, "specular": 0.6}]
	P["copper_green"] = ["5f8a7c", "rust", 0.6, {"roughness": 0.6, "metallic": 0.2, "detail_strength": 0.5}]
	P["wood_weathered"] = ["8f877c", "wood", 0.7, {"roughness": 0.9, "normal_strength": 0.9, "tide_wet": true, "wet_response": 1.0}]
	P["wood_dark"] = ["4d4136", "wood", 0.6, {"roughness": 0.88, "normal_strength": 0.9, "tide_wet": true, "macro_strength": 0.3}]
	P["wood_wreck"] = ["5c5248", "wood", 0.5, {"roughness": 0.9, "normal_strength": 1.1, "tide_wet": true, "macro_strength": 0.4, "macro_tint": Color("d8e6c8")}]
	P["rope"] = ["b49c74", "fabric", 3.0, {"roughness": 0.95, "normal_strength": 0.6}]
	P["buoy_red"] = ["b0402e", "rust", 0.5, {"roughness": 0.5, "detail_strength": 0.55, "tide_wet": true}]
	P["canister"] = ["c98a2a", "rust", 0.9, {"roughness": 0.5, "metallic": 0.3, "detail_strength": 0.7}]
	P["rubber"] = ["1e2124", "plaster", 1.0, {"roughness": 0.7, "detail_strength": 0.3}]
	P["seaweed"] = ["4b4a2a", "moss", 0.8, {"roughness": 0.4, "wrap": 0.7, "tide_wet": true}]
	P["barnacle"] = ["b0a99a", "granite", 1.2, {"roughness": 0.95, "normal_strength": 1.4}]
	P["paint_white"] = ["e8e0c8", "plaster", 1.0, {"roughness": 0.75, "detail_strength": 0.5}]
	# Vegetation
	P["spruce"] = ["2b3d33", "moss", 0.7, {"roughness": 0.95, "wrap": 0.7, "rim_strength": 0.6, "shadow_fill": 0.7, "macro_strength": 0.35, "macro_tint": Color("e8f0c8"), "object_space": false}]
	P["bark"] = ["4d3d32", "bark", 1.2, {"roughness": 0.95, "normal_strength": 1.2}]
	P["shrub"] = ["5d5a36", "moss", 1.0, {"roughness": 0.95, "wrap": 0.7, "rim_strength": 0.6, "macro_strength": 0.4, "macro_tint": Color("ffd8a0"), "object_space": false}]
	# Interiors
	P["plaster"] = ["d6ccba", "plaster", 0.5, {"roughness": 0.9, "normal_strength": 0.4}]
	P["plaster_cool"] = ["aeb4b4", "plaster", 0.5, {"roughness": 0.9, "normal_strength": 0.4}]
	P["wainscot"] = ["5d6e66", "clapboard", 1.6, {"roughness": 0.6, "normal_strength": 0.8}]
	P["wood_floor"] = ["6e4c33", "wood", 0.6, {"roughness": 0.55, "normal_strength": 0.6, "specular": 0.5}]
	P["wood_warm"] = ["7a5232", "wood", 0.9, {"roughness": 0.5, "normal_strength": 0.5, "specular": 0.5}]
	P["wood_beam"] = ["4a3526", "wood", 0.5, {"roughness": 0.8, "normal_strength": 1.0}]
	P["stone_floor"] = ["5c6064", "granite", 0.5, {"roughness": 0.8, "normal_strength": 0.6}]
	P["stove_iron"] = ["24282c", "rust", 0.8, {"roughness": 0.55, "metallic": 0.45, "detail_strength": 0.35}]
	P["enamel"] = ["e6e0d2", "plaster", 1.2, {"roughness": 0.3, "detail_strength": 0.3, "specular": 0.6}]
	P["enamel_blue"] = ["3d5a78", "plaster", 1.2, {"roughness": 0.3, "detail_strength": 0.3, "specular": 0.6}]
	P["quilt"] = ["3f5f80", "fabric", 1.4, {"roughness": 0.95, "wrap": 0.6}]
	P["quilt_red"] = ["8a3a32", "fabric", 1.4, {"roughness": 0.95, "wrap": 0.6}]
	P["linen"] = ["d8cfbc", "fabric", 1.6, {"roughness": 0.95, "wrap": 0.6}]
	P["wool_red"] = ["7a3b32", "fabric", 1.2, {"roughness": 0.95, "wrap": 0.6}]
	P["rug"] = ["7c4a38", "fabric", 0.8, {"roughness": 0.98, "wrap": 0.5}]
	P["leather"] = ["5a3a2a", "plaster", 1.0, {"roughness": 0.6, "detail_strength": 0.5}]
	P["book"] = ["b8ae9c", "plaster", 2.0, {"roughness": 0.8, "detail_strength": 0.4}]
	P["radio_case"] = ["46544a", "rust", 0.9, {"roughness": 0.6, "metallic": 0.2, "detail_strength": 0.35}]
	P["bakelite"] = ["2a2624", "plaster", 1.0, {"roughness": 0.35, "detail_strength": 0.2, "specular": 0.6}]
	for name in P:
		var d: Array = P[name]
		_painterly(name, Color(d[0]), d[1], d[2], d[3])
	# Special surfaces
	_glass("glass", Color(0.72, 0.82, 0.86, 0.22), 0.04)
	_glass("glass_lantern", Color(0.8, 0.86, 0.85, 0.12), 0.02)
	_glow("lamp_lit", Color("ffd27d"), 6.0)
	_glow("lamp_off", Color("2a2f33"), 0.0)
	_glow("fire", Color("ff8a2a"), 5.0)
	_glow("dial_glow", Color("ffb84d"), 2.5)
	_glow("bulb", Color("ffcf8a"), 4.0)
	_paint_window()
	_paper("paper_tide", TEX + "tide_table_paper.png")
	_paper("paper_log", TEX + "logbook_page.png")
	_paper("paper_chart", TEX + "chart.png")
	print("  materials done")

static func _painterly(name: String, albedo: Color, tex: String, scale: float, extra: Dictionary) -> void:
	var m := ShaderMaterial.new()
	m.shader = load("res://art/painterly.gdshader")
	m.set_shader_parameter("albedo", albedo)
	m.set_shader_parameter("detail_tex", load(TEX + tex + "_albedo.png"))
	m.set_shader_parameter("normal_tex", load(TEX + tex + "_normal.png"))
	m.set_shader_parameter("macro_tex", load(TEX + "macro_breakup.png"))
	m.set_shader_parameter("tex_scale", scale)
	for k in extra:
		m.set_shader_parameter(k, extra[k])
	_save(m, name)

static func _glass(name: String, c: Color, rough: float) -> void:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = 0.7
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_save(m, name)

static func _glow(name: String, c: Color, energy: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.darkened(0.2) if energy > 0.0 else c
	m.roughness = 0.4
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energy
	_save(m, name)

## Window glass: dark reflective pane by day, warm lamplit glow by night.
## Island drives `emission_energy` from the time of day.
static func _paint_window() -> void:
	var m := ShaderMaterial.new()
	m.shader = load("res://art/painterly.gdshader")
	m.set_shader_parameter("albedo", Color("1c2228"))
	m.set_shader_parameter("detail_tex", load(TEX + "plaster_albedo.png"))
	m.set_shader_parameter("normal_tex", load(TEX + "plaster_normal.png"))
	m.set_shader_parameter("macro_tex", load(TEX + "macro_breakup.png"))
	m.set_shader_parameter("detail_strength", 0.3)
	m.set_shader_parameter("roughness", 0.12)
	m.set_shader_parameter("specular", 0.7)
	m.set_shader_parameter("emission_color", Color("ffb066"))
	m.set_shader_parameter("emission_energy", 1.5)
	_save(m, "window_glow")

static func _paper(name: String, tex: String) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(tex)
	m.roughness = 0.92
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_save(m, name)

static func _save(m: Material, name: String) -> void:
	var p := DIR + name + ".tres"
	var err := ResourceSaver.save(m, p)
	if err != OK:
		push_error("failed to save " + p)
	m.take_over_path(p)
