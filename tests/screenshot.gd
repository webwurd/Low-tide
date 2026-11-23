extends SceneTree
## Dev tool: renders vantage points to PNG (needs a display or xvfb).
##   xvfb-run -a godot --rendering-method gl_compatibility -s tests/screenshot.gd -- /out/dir

var main: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var out := "/tmp"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	root.size = Vector2i(1280, 720)
	var clock := root.get_node("GameClock")
	var dd := root.get_node("DayDirector")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _wait(10)
	await _snap(out, "00_title")
	main.hud._open_tutorial()
	await _wait(4)
	await _snap(out, "01_tutorial_controls")
	main.hud._tut_go(1); await _wait(3); await _snap(out, "02_tutorial_tools")
	main.hud._tut_go(2); await _wait(3); await _snap(out, "03_tutorial_day")
	main.hud._tut_go(3)
	await _wait(10)
	main.hud._card.modulate.a = 0.0
	var p = main.player
	# interiors (indoors the clock is frozen, so lighting is constant)
	await _shoot("04_cottage", "cottage", main.interiors.spawn["cottage"], 0.6, -0.05)
	await _shoot("05_cottage_stove_side", "cottage", main.interiors.spawn["cottage"] + Vector3(-3.5, 0, 0.5), 0.9, -0.05)
	await _shoot("06_watch_room", "tower_base", main.interiors.spawn["tower_base"], 0.0, 0.0)
	dd.lamp_lit = true; main.interiors.set_lamp(true)
	await _shoot("07_lantern_room_lit", "tower_top", main.interiors.spawn["tower_top"], 0.8, 0.0)
	# outdoors: cottage exterior, night beam, storm
	var Terr = load("res://world/terrain.gd")
	clock.set_time(1, 600.0)
	await _shoot("08_cottage_exterior_day", "outdoors", Vector3(-4.0, Terr.height(-4.0, 11.0) + 0.05, 11.0), 0.45, 0.0)
	dd.weights_wound = true
	clock.set_time(1, 1080.0)
	await _shoot("09_night_beam", "outdoors", main.island.spawn_point, 0.0, 0.35)
	clock.set_time(4, 700.0)
	dd.lamp_lit = false
	await _shoot("10_storm_day", "outdoors", main.island.cottage_exit() + Vector3(1, 0, 3), PI + 0.45, 0.0)
	clock.set_time(5, 650.0)
	await _shoot("11_day5_spring_low_clear", "outdoors", main.island.spawn_point, 0.0, 0.05)
	# journal + tape panel (M4)
	var st := root.get_node("GameState")
	st.reset()
	st.give_item("canister"); st.give_item("tape_1"); st.give_item("uni_logs")
	st.set_flag("heard_tape_1")
	st.add_log(1, "Glass 30.1 and steady. Fog, then. East stack: old trawler wreck. Canister stamped PROJECT PELAGIC 1974 wedged in the hull. Told Clara about the canister.")
	await _shoot("12_journal_log", "cottage", main.interiors.spawn["cottage"], 0.6, -0.05)
	main.hud.show_card("", "", 0.0)
	main.hud._journal_page = 1
	main.hud._render_journal()
	await _wait(4)
	await _snap(out, "13_journal_satchel")
	main.hud._journal_page = 2
	main.hud._render_journal()
	await _wait(4)
	await _snap(out, "14_journal_tapes")
	main.hud.close_modal()
	main.hud._tape_title.text = "TAPE 1  -  WALT, JANUARY 1976"
	main.hud._tape_text.text = "I keep telling myself you'd laugh at me, talking to a machine."
	main.hud._tape_panel.visible = true
	await _wait(4)
	await _snap(out, "15_tape_playing")
	quit(0)

func _shoot(shot: String, loc: String, pos: Vector3, yaw: float, pitch: float) -> void:
	main._place(loc, pos, yaw)
	var p = main.player
	p.locked = true
	p.pitch = pitch
	p.cam.rotation.x = pitch
	p.rotation.y = yaw
	main.started = true
	root.get_node("GameClock").paused = true
	await _wait(10)
	await _snap(str(OS.get_cmdline_user_args()[0]), shot)

func _snap(out: String, name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("saved ", name)

func _wait(n: int) -> void:
	for i in n:
		await process_frame
