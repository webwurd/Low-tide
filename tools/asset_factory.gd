class_name AssetFactory
## Runs every asset builder in dependency order. See tools/build_assets.sh.

static func build_all(tree: SceneTree) -> void:
	print("materials")
	FactoryMaterials.build_all()
	print("looks")
	_looks()
	print("props")
	PropAssets.build_all()
	print("island")
	IslandAssets.build_all()
	print("vegetation")
	VegetationAssets.build_all()
	print("hands")
	HandAssets.build_all()
	print("interiors")
	await InteriorAssets.build_all(tree)

## Writes the tunable look resources (only if missing, so Inspector tweaks survive).
static func _looks() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/looks"))
	var p := "res://art/looks/atmosphere.tres"
	if not ResourceLoader.exists(p):
		ResourceSaver.save(Atmosphere.new(), p)
	for key in WeatherLook.KEYS:
		var wp := "res://art/looks/weather_%s.tres" % key
		if not ResourceLoader.exists(wp):
			ResourceSaver.save(WeatherLook.preset(key), wp)
