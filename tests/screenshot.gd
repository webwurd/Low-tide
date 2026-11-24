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
	main.hud._tape_title.text = "Tape 1: Walt, January 1976"
	main.hud._tape_text.text = "I keep telling myself you'd laugh at me, talking to a machine."
	main.hud._tape_panel.visible = true
	await _wait(4)
	await _snap(out, "15_tape_playing")
	# M5 locations
	var Terr2 = load("res://world/terrain.gd")
	clock.set_time(1, 450.0)
	await _shoot("16_north_cove", "outdoors", Vector3(-10.5, Terr2.height(-10.5, -38.0) + 0.1, -38.0), 0.6435, 0.0)
	clock.set_time(5, 6410.0 - 1440.0 * 4)
	await _shoot("17_south_reef_spring_low", "outdoors", Vector3(16.0, Terr2.height(16.0, 50.0) + 0.1, 50.0), -2.94, 0.0)
	clock.set_time(3, 540.0)
	await _shoot("18_dense_fog_day3", "outdoors", main.island.spawn_point, -PI / 2.0, 0.0)
	clock.set_time(2, 640.0)
	await _shoot("19_day2_overcast_buoy", "outdoors", main.island.spawn_point, -2.6, 0.02)
	# A1: causeway sign + lane poles at the spring low (looking south down the lane)
	var Tt = load("res://world/terrain.gd")
	var ca: Vector2 = Tt.SOUTH_A
	var cd: Vector2 = (Tt.SOUTH_B - ca).normalized()
	var eye: Vector2 = ca - cd * 6.0
	clock.set_time(5, 6410.0 - 1440.0 * 4)
	await _shoot("20_causeway_sign_and_poles", "outdoors", Vector3(eye.x, Tt.height(eye.x, eye.y) + 0.1, eye.y), atan2(-cd.x, -cd.y), 0.05)
	var eye2: Vector2 = ca + cd * 4.0
	await _shoot("21_lane_between_poles", "outdoors", Vector3(eye2.x, Tt.height(eye2.x, eye2.y) + 0.1, eye2.y), atan2(-cd.x, -cd.y), 0.0)
	var sp2: Vector2 = ca - cd * 3.0 + Vector2(cd.y, -cd.x) * 3.5
	await _shoot("22_causeway_sign_board", "outdoors", Vector3(sp2.x, Tt.height(sp2.x, sp2.y - 9.0) + 0.1, sp2.y - 9.0), PI, 0.18)
	# M6: journal scroll + ending scene + end card
	st.reset()
	for tid in ["tape_1", "tape_2", "tape_3", "tape_4", "tape_5", "tape_6"]:
		st.give_item(tid)
		st.set_flag("heard_" + tid)
	await _shoot("23_journal_six_tapes", "cottage", main.interiors.spawn["cottage"], 0.6, -0.05)
	main.hud._journal_page = 2
	main.hud._render_journal()
	await _wait(6)
	await _snap(out, "23_journal_six_tapes")
	main.hud._modal_scroll.scroll_vertical = 520
	await _wait(3)
	await _snap(out, "24_journal_scrolled")
	main.hud.close_modal()
	st.reset()
	root.get_node("DayDirector").begin_day(7)
	root.get_node("DayDirector").lamp_lit = true
	st.set_flag("clara_admitted")
	main.ending_reload = false
	main.hud._card.modulate.a = 0.0
	Engine.time_scale = 6.0
	main.player.locked = false
	main.start_ending("a")
	var t_end := Time.get_ticks_msec()
	while not main._boat_arrived and Time.get_ticks_msec() - t_end < 40000:
		if main._boat != null and main._boat.position.distance_to(main._boat_target) < 40.0 and not FileAccess.file_exists("/tmp/_shot25"):
			await _snap(out, "25_ending_boat_light_binoculars")
			var f := FileAccess.open("/tmp/_shot25", FileAccess.WRITE); f.close()
		await process_frame
	await _wait(10)
	await _snap(out, "26_ending_boat_arrived")
	await create_timer(3.5).timeout
	await _wait(10)
	await _snap(out, "27_ending_card_a")
	Engine.time_scale = 1.0
	# M7: menus
	Engine.time_scale = 1.0
	main.hud._ending_panel.visible = false
	main.hud._card.modulate.a = 0.0
	main.hud._tape_panel.visible = false
	main._place("cottage", main.interiors.spawn["cottage"], 0.6)
	# typography pass: radio at the default and the largest subtitle size, day card, tide table
	var convs = load("res://story/conversations.gd")
	var long_text: String = convs.get_conv("evening_d6").get("text", "")
	if long_text == "":
		long_text = "All right, Arthur. You've earned this. My father piloted the boat that took June Haskell to the reef. He told the Navy the tide table said one hour. They said two."
	var opts := [{"text": "Tell her about the canister and the cable vault"}, {"text": "Say nothing and keep the tapes to yourself for now"}]
	var cfg := root.get_node("Settings")
	for sc in [1.0, 1.8]:
		cfg.set_v("subtitle_scale", sc)
		main.hud.apply_text_scale()
		main.hud._on_line(convs.SPEAKER, long_text, opts)
		await _wait(6)
		await _snap(out, "28_radio_scale_%d" % int(sc * 10))
	cfg.set_v("subtitle_scale", 1.0)
	main.hud.apply_text_scale()
	main.hud._on_reply("Clara, replying", "Copy that, Arthur. Keep the lamp lit.")
	await _wait(4)
	await _snap(out, "28_radio_reply")
	main.hud._radio.visible = false
	main.hud.show_card("Day 5", "Spring low, clear", 6.0)
	await _wait(25)
	await _snap(out, "29_day_card")
	main.hud._card.modulate.a = 0.0
	main.hud.show_tide_table(5, root.get_node("TideSystem").extremes_for_day(5))
	await _wait(5)
	await _snap(out, "29_tide_table")
	main.hud.close_modal()
	for k in ["b", "c"]:
		main._show_ending_card(k)
		await _wait(60)
		await _snap(out, "27_ending_card_" + k)
		main.hud._ending_panel.visible = false
	var menus = main.menus
	menus.open_pause()
	await _wait(6)
	await _snap(out, "30_pause_menu")
	menus._show_only("settings")
	var sm = menus.settings_menu()
	for t in 5:
		sm.tabs.current_tab = t
		await _wait(5)
		await _snap(out, "31_settings_%d_%s" % [t, sm.tabs.get_child(t).name])
	menus._open_controls()
	await _wait(5)
	await _snap(out, "36_controls_reference")
	menus.resume()
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
