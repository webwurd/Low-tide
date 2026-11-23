extends SceneTree
## Headless test runner (no addons).
##   godot --headless -s tests/run_tests.gd
## Exits non-zero on any failure.

var failures := 0
var checks := 0

func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("  FAIL: " + msg)
	else:
		print("  ok:   " + msg)

func near(a: float, b: float, tol: float, msg: String) -> void:
	ok(absf(a - b) <= tol, "%s (got %.3f, want %.3f)" % [msg, a, b])

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var tide := root.get_node("TideSystem")
	var clock := root.get_node("GameClock")
	var radio := root.get_node("RadioSystem")
	var state := root.get_node("GameState")

	print("== tide model")
	near(tide.water_height(1, 450.0), 0.2, 0.01, "day 1 low water 07:30")
	near(tide.water_height(1, 450.0 + 372.5), 4.2, 0.01, "high water half a cycle later")
	near(tide.low_minute_of_day(1), 450.0, 0.01, "day 1 first low")
	near(tide.low_minute_of_day(3) - tide.low_minute_of_day(2), 50.0, 5.0, "lows drift ~50 min/day")
	near(tide.water_height(5, tide.low_minute_of_day(5)), -0.4, 0.01, "day 5 spring low")
	var max_jump := 0.0
	for m in range(0, 1440 * 7):
		max_jump = maxf(max_jump, absf(tide.water_height_abs(m + 1.0) - tide.water_height_abs(m)))
	ok(max_jump < 0.05, "tide is continuous across all 7 days incl. midnights (max step %.4f m/min)" % max_jump)
	var mn := 99.0
	var mx := -99.0
	for m in range(0, 1440 * 7):
		var h: float = tide.water_height_abs(m)
		mn = minf(mn, h); mx = maxf(mx, h)
	near(mn, -0.4, 0.01, "week minimum is the day-5 spring low")
	near(mx, 4.2, 0.01, "week maximum is 4.2 m")
	ok(tide.depth_band(0.2) == "splash" and tide.depth_band(0.5) == "knee"
		and tide.depth_band(0.9) == "thigh" and tide.depth_band(1.0) == "swept", "depth bands")
	ok(tide.sandbars_open(2.1) and not tide.sandbars_open(2.11), "sandbar gate at 2.1 m")
	near(tide.speed_multiplier(0.5), 0.6, 0.001, "knee-deep speed x0.6")

	print("== terrain")
	var Terr = load("res://world/terrain.gd")
	for x in [30.0, 45.0, 60.0]:
		var zc: float = 4.0 + sin((x - 25.0) * 0.07) * 3.5
		var h: float = Terr.height(x, zc)
		ok(h > 1.4 and h < 1.8, "east sandbar crest at x=%d is ~1.6 m (%.2f)" % [x, h])
	for x in [-30.0, -45.0, -60.0]:
		var zc2: float = -6.0 + cos((x + 25.0) * 0.08) * 3.0
		var h2: float = Terr.height(x, zc2)
		ok(h2 > 1.4 and h2 < 1.9, "west sandbar crest at x=%d is ~1.6 m (%.2f)" % [x, h2])
	near(Terr.height(0.0, -4.0), 10.2, 0.2, "summit plateau ~10.2 m")
	ok(Terr.height(0.0, 12.5) < Terr.PIER_TOP + 0.5 and Terr.height(0.0, 12.5) > Terr.PIER_TOP - 0.5, "pier meets hillside at z=12.5")
	ok(Terr.PIER_TOP > 4.2 + 0.28, "pier deck clears max high tide + wave height")
	ok(Terr.height(76.0, 6.0) > 4.0, "east stack stays above high tide")
	ok(Terr.height(-74.0, -8.0) > 4.0, "west stack stays above high tide")

	print("== radio")
	state.trust = 0
	radio.play(load("res://story/conversations.gd").get_conv("lighthouse"))
	ok(radio.active and radio.awaiting_choice, "conversation opens and awaits choice")
	radio.choose(1)
	ok(state.trust == 1, "choice applies trust delta")
	radio.dismiss()
	ok(not radio.active, "dismiss closes the radio")

	print("== full game smoke (headless, simulated play)")
	clock.set_time(1, 375.0)
	var main: Node3D = load("res://main.tscn").instantiate()
	main.autostart = true
	root.add_child(main)
	await _frames(5)
	var player = main.player
	ok(player != null and main.island != null, "main scene builds player + island")
	ok(player.global_position.distance_to(main.island.spawn_point) < 1.0, "player spawns on the pier")
	await _frames(40)
	ok(player.is_on_floor(), "player stands on the pier (floor y=%.2f)" % player.global_position.y)
	near(player.global_position.y, Terr.PIER_TOP, 0.2, "standing at deck height")

	# Walk north (forward = -Z) off the pier and up the hill using real input actions.
	Input.action_press("move_forward")
	var z0: float = player.global_position.z
	await _frames(240)
	Input.action_release("move_forward")
	ok(player.global_position.z < z0 - 5.0, "forward input moves Arthur north (z %.1f -> %.1f)" % [z0, player.global_position.z])

	# Interaction: teleport next to the lighthouse and press interact.
	player.teleport(Vector3(0, 11.0, -1.5), 0.0)
	await _frames(10)
	ok(player.nearby != null and player.nearby.id == "lighthouse", "lighthouse inspectable in range")
	_send_action("interact", true)
	await _frames(2)
	_send_action("interact", false)
	ok(state.discovered.has("lighthouse"), "interact discovers the lighthouse")
	ok(radio.active, "interact opens a radio call")
	radio.dismiss()

	# Binoculars rangefinder
	player.teleport(Vector3(0, 4.8, 24), PI * 0.0)
	await _frames(10)
	player.yaw = 0.0
	player.pitch = deg_to_rad(10.0)
	Input.action_press("binoculars")
	await _frames(30)
	ok(player.binoculars and player.cam.fov < 40.0, "binoculars narrow the FOV (%.1f)" % player.cam.fov)
	# Aim straight at the lantern room from the pier: pitch = atan(dy/dz)
	var to_lamp: Vector3 = Vector3(0, 30, -6) - (player.global_position + Vector3(0, 1.72, 0))
	player.yaw = 0.0
	player.pitch = atan2(to_lamp.y, -to_lamp.z)
	await _frames(5)
	ok(player.bino_label.contains("LIGHTHOUSE"), "rangefinder identifies the lighthouse ('%s', %d m)" % [player.bino_label, player.bino_dist])
	player.pitch = 0.0
	await _frames(3)
	ok(player.bino_label == "", "rangefinder clears when looking at open sea")
	Input.action_release("binoculars")
	await _frames(5)

	# Swept scenario: stand mid-bar at high water.
	clock.set_time(1, 450.0 + 372.5)          # high water 4.2 m
	tide.refresh()
	var t_before: float = clock.abs_minute()
	player.teleport(Vector3(45.0, Terr.height(45.0, 4.0 + sin(20.0 * 0.07) * 3.5) + 0.2, 4.0 + sin(20.0 * 0.07) * 3.5), 0.0)
	var swept_fired := [false]
	player.swept.connect(func(): swept_fired[0] = true)
	await _frames(20)
	ok(swept_fired[0], "standing on a submerged sandbar sweeps Arthur")
	await _frames(200)    # fade + respawn timer (2.2 s @ ~60fps; headless frames are fast, so wait on time)
	await create_timer(2.6).timeout
	ok(player.global_position.distance_to(main.island.spawn_point) < 1.5, "swept Arthur is returned to the pier")
	ok(clock.abs_minute() - t_before >= 44.0, "swept costs ~45 game minutes (%.1f)" % (clock.abs_minute() - t_before))
	ok(radio.active, "Clara reacts on the radio after being swept")

	# Pier is safe at the highest tide
	await _frames(60)
	ok(not main._sweeping, "no sweep loop on the pier at 4.2 m high water")
	near(tide.current_height, 4.2, 0.2, "water is at high tide during the pier check")

	print("\n%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _send_action(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)

func _frames(n: int) -> void:
	for i in n:
		await process_frame
