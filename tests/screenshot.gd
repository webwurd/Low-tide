extends SceneTree
## Dev tool: renders a few vantage points to PNG (needs a display or xvfb).
##   xvfb-run -a godot --rendering-method gl_compatibility -s tests/screenshot.gd -- /out/dir

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var out := "/tmp"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	root.size = Vector2i(1280, 720)
	var clock := root.get_node("GameClock")
	var tide := root.get_node("TideSystem")
	clock.set_time(1, 375.0)
	var main: Node3D = load("res://main.tscn").instantiate()
	main.autostart = true
	root.add_child(main)
	await _wait(30)
	root.get_node("Settings").assist_mode = true
	var shots := [
		["pier_start", Vector3(0, 4.8, 24), 0.0, 0.08, 375.0, false],
		["summit", Vector3(-3, 11.9, 4), 0.2, 0.05, 375.0, false],
		["east_bar", Vector3(32, 2.6, 2), -PI / 2.0, 0.0, 375.0, false],
		["east_bar_high_tide", Vector3(32, 2.6, 2), -PI / 2.0, 0.0, 450.0 + 372.5, false],
		["binoculars_lighthouse", Vector3(0, 4.8, 24), 0.0, 0.70, 375.0, true],
		["pier_pilings_assist", Vector3(2.0, 4.8, 22), 1.2, -0.45, 450.0 + 200.0, false],
		["cottage_evening", Vector3(-4, 10.7, 9), 0.5, 0.0, 17 * 60.0, false],
	]
	for s in shots:
		clock.set_time(1, s[4])
		tide.refresh()
		main.player.teleport(s[1], s[2])
		main.player.pitch = s[3]
		main.player.locked = true
		main.player.binoculars = s[5]
		if s[5]:
			main.player.cam.fov = 20.0
		else:
			main.player.cam.fov = 65.0
		main.player.cam.rotation.x = s[3]
		main.player.rotation.y = s[2]
		clock.paused = true
		await _wait(8)
		var img := root.get_texture().get_image()
		img.save_png("%s/%s.png" % [out, s[0]])
		print("saved ", s[0])
		clock.paused = false
	quit(0)

func _wait(n: int) -> void:
	for i in n:
		await process_frame
