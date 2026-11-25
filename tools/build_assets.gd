extends SceneTree
## Low Tide asset factory. Writes committed game assets:
##   textures   -> res://assets/textures/*.png        (TextureKit)
##   import     -> sets VRAM compression / normal-map flags in *.import
##   assets     -> materials, meshes, scenes, look resources (needs imported textures)
##   hands      -> materials + first-person hands only (fast iteration on tools/hand_assets.gd)
## Use tools/build_assets.sh, which runs the stages with a Godot import between them.
##   godot --headless -s tools/build_assets.gd -- <stage>

func _initialize() -> void:
	var stage := "assets"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		stage = args[0]
	var t := Time.get_ticks_msec()
	match stage:
		"textures":
			load("res://tools/texture_kit.gd").build_all()
		"import":
			_set_import_flags()
		"assets":
			await _build_assets()
		"hands":
			load("res://tools/factory_materials.gd").build_all()
			load("res://tools/hand_assets.gd").build_all()
		_:
			printerr("unknown stage ", stage)
			quit(1)
			return
	print("stage %s done in %.1fs" % [stage, (Time.get_ticks_msec() - t) / 1000.0])
	quit(0)

## Textures are 3D assets: VRAM-compressed with mipmaps; normal maps flagged
## so they use the RGTC/BC5 path. Only rewrites a file when something changes.
func _set_import_flags() -> void:
	var dir := "res://assets/textures/"
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".png.import"):
			continue
		var p := dir + f
		var cfg := ConfigFile.new()
		if cfg.load(p) != OK:
			continue
		var is_normal := f.contains("_normal")
		var is_ui := f.begins_with("ui_")
		var want := {
			"compress/mode": 0 if is_ui else 2,
			"mipmaps/generate": not is_ui,
			"compress/normal_map": 1 if is_normal else 2,
			"detect_3d/compress_to": 0,
		}
		var changed := false
		for k in want:
			if cfg.get_value("params", k, null) != want[k]:
				cfg.set_value("params", k, want[k])
				changed = true
		if changed:
			cfg.save(p)
			print("  import flags: ", f)

## Loaded at runtime: the builders reference autoload singletons (through
## Interactable), which a `-s` script can't see at its own compile time.
func _build_assets() -> void:
	await load("res://tools/asset_factory.gd").build_all(self)
