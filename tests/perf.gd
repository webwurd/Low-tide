extends SceneTree
## Dev tool: per-vantage render budget report (triangles, draw calls,
## objects) for one quality preset. Counts, not timings: they are what
## predicts GPU cost on the Steam Deck, and they are stable on any driver.
##   xvfb-run -a godot --rendering-driver vulkan -s tests/perf.gd -- [low|medium|high]

var main: Node3D
var Terr = preload("res://world/terrain.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var q := "high"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		q = args[0]
	var settings := root.get_node("Settings")
	settings.quality = {"low": 0, "medium": 1, "high": 2}.get(q, 2)
	root.size = Vector2i(1280, 800)
	main = load("res://main.tscn").instantiate()
	main.autostart = true
	root.add_child(main)
	await _wait(10)
	main.hud.visible = false
	var clock := root.get_node("GameClock")
	print("quality preset: ", q)
	print("%-26s %10s %10s %8s" % ["vantage", "triangles", "drawcalls", "objects"])
	clock.set_time(5, 600.0)
	await _probe("pier, looking at island", "outdoors", main.island.spawn_point, 0.0)
	await _probe("summit, looking south", "outdoors", Vector3(-3, Terr.height(-3, -12) + 0.05, -12), PI)
	await _probe("east bar, looking west", "outdoors", Vector3(30, Terr.height(30, 4) + 0.05, 4), PI / 2.0)
	clock.set_time(5, 1080.0)
	await _probe("night, beam on", "outdoors", main.island.spawn_point, 0.0)
	await _probe("cottage interior", "cottage", main.interiors.spawn["cottage"], 0.6)
	await _probe("lantern room", "tower_top", main.interiors.spawn["tower_top"], 0.8)
	quit(0)

func _probe(label: String, loc: String, pos: Vector3, yaw: float) -> void:
	main._place(loc, pos, yaw)
	main.player.locked = true
	main.player.rotation.y = yaw
	root.get_node("GameClock").paused = true
	await _wait(12)
	var rs := RenderingServer
	var tris := rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var calls := rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var objs := rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("%-26s %10d %10d %8d" % [label, tris, calls, objs])

func _wait(n: int) -> void:
	for i in n:
		await process_frame
