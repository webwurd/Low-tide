extends SceneTree
## Dev tool: renders art vantages to PNG (needs a display or xvfb). Forward+:
##   xvfb-run -a godot --rendering-driver vulkan -s tests/screenshot.gd -- /out/dir [filter]
## In a container without a GPU, point Vulkan at lavapipe first:
##   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json
## `filter` (optional) only renders shots whose name contains it.

var main: Node3D
var out := "/tmp"
var filter := ""
var Terr = preload("res://world/terrain.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		filter = args[1]
	root.size = Vector2i(1280, 720)
	var clock := root.get_node("GameClock")
	var dd := root.get_node("DayDirector")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _wait(10)
	await _snap("00_title")
	main.hud._open_tutorial()
	await _wait(4)
	await _snap("01_tutorial_controls")
	main.hud._tut_go(3)
	await _wait(10)
	main.hud.visible = false

	# --- interiors (clock frozen indoors) ---
	clock.set_time(1, 420.0)
	await _shoot("10_cottage", "cottage", main.interiors.spawn["cottage"], 0.6, -0.05)
	await _shoot("11_cottage_stove_side", "cottage", main.interiors.spawn["cottage"] + Vector3(-3.5, 0, 0.5), 0.9, -0.05)
	await _shoot("12_cottage_desk", "cottage", main.interiors.spawn["cottage"] + Vector3(-1.2, 0, 1.2), -0.75, -0.25)
	await _shoot("13_watch_room", "tower_base", main.interiors.spawn["tower_base"], 0.0, 0.0)
	dd.lamp_lit = true; main.interiors.set_lamp(true)
	clock.set_time(1, 1000.0)
	await _shoot("14_lantern_room_lit", "tower_top", main.interiors.spawn["tower_top"], 0.8, 0.0)
	dd.lamp_lit = false; main.interiors.set_lamp(false)
	main._apply_island_lamp()

	# --- day 1 (fog) through the day, from the pier ---
	var pier: Vector3 = main.island.spawn_point
	clock.set_time(1, 425.0)
	await _shoot("20_d1_dawn_pier", "outdoors", pier, 0.0, 0.08)
	clock.set_time(1, 720.0)
	await _shoot("21_d1_noon_pier", "outdoors", pier, 0.0, 0.08)
	clock.set_time(1, 600.0)
	await _shoot("22_d1_cottage_exterior", "outdoors", _ground(-4.0, 11.0), 0.45, 0.0)

	# --- day 5 (clear, spring low): the hero day ---
	clock.set_time(5, 560.0)
	await _shoot("30_d5_morning_pier", "outdoors", pier, 0.0, 0.08)
	clock.set_time(5, 915.0)
	await _shoot("31_d5_golden_lighthouse", "outdoors", _ground(9.0, 6.0), 0.95, 0.32)
	await _shoot("32_d5_golden_east_bar", "outdoors", _ground(24.0, 4.0), -1.45, 0.02)
	clock.set_time(5, 965.0)
	await _shoot("33_d5_dusk_west", "outdoors", _ground(-14.0, 6.0), 1.75, 0.04)
	await _shoot("34_d5_pier_marks", "outdoors", pier + Vector3(-0.6, 0, 3.0), -1.2, -0.35)
	dd.lamp_lit = true; dd.weights_wound = true
	main._apply_island_lamp()
	clock.set_time(5, 1080.0)
	await _shoot("35_d5_night_beam", "outdoors", pier, 0.0, 0.3)
	dd.lamp_lit = false; dd.weights_wound = false
	main._apply_island_lamp()

	# --- the other weathers ---
	clock.set_time(3, 700.0)
	await _shoot("40_d3_dense_fog", "outdoors", _ground(-6.0, -12.0), 2.6, 0.0)
	clock.set_time(4, 700.0)
	await _shoot("41_d4_storm", "outdoors", main.island.cottage_exit() + Vector3(1, 0, 3), PI + 0.45, 0.0)
	clock.set_time(6, 830.0)
	await _shoot("42_d6_cold_wreck", "outdoors", _ground(64.0, 9.0), -1.65, -0.02)
	clock.set_time(7, 440.0)
	await _shoot("43_d7_dawn_haze_cave", "outdoors", _ground(-60.0, -4.0), 1.45, 0.0)
	quit(0)

func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, Terr.height(x, z) + 0.05, z)

func _shoot(shot: String, loc: String, pos: Vector3, yaw: float, pitch: float) -> void:
	if filter != "" and not shot.contains(filter):
		return
	main._place(loc, pos, yaw)
	var p = main.player
	p.locked = true
	p.pitch = pitch
	p.cam.rotation.x = pitch
	p.rotation.y = yaw
	main.started = true
	root.get_node("GameClock").paused = true
	await _wait(14)
	await _snap(shot)

func _snap(name: String) -> void:
	if filter != "" and not name.contains(filter):
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("saved ", name)

func _wait(n: int) -> void:
	for i in n:
		await process_frame
