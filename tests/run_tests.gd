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

	print("== shared data")
	var root_dlg := FileAccess.get_file_as_string("res://dialogue/dialogue.json")
	var unity_copy := ProjectSettings.globalize_path("res://") + "unity/Assets/StreamingAssets/dialogue.json"
	ok(FileAccess.file_exists(unity_copy) and FileAccess.get_file_as_string(unity_copy) == root_dlg, "Unity's copy of dialogue.json is identical (run tools/sync_unity_data.sh if not)")

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

	print("== sky (Atmosphere / SkyRig)")
	var atm := Atmosphere.new()
	ok(atm.sun_direction(700.0).y > 0.2 and atm.day_factor(700.0) > 0.99, "sun is well up at 11:40")
	ok(atm.day_factor(1200.0) < 0.01, "it is fully night at 20:00")
	ok(atm.sun_direction(430.0).x > 0.5 and atm.sun_direction(960.0).x < -0.5, "sun rises in the east (+x) and sets in the west (-x)")
	ok(atm.sun_direction(700.0).z > 0.5, "noon sun is in the south")
	ok(atm.moon_direction(1200.0).y > 0.2, "moon is up at night")
	var sky_jump := 0.0
	var prev: Dictionary = atm.sample(0.0)
	for m in range(1, 1440):
		var cur: Dictionary = atm.sample(float(m))
		for k in ["sky_top", "sky_horizon", "fog_color"]:
			var a: Color = prev[k]
			var bb: Color = cur[k]
			sky_jump = maxf(sky_jump, absf(a.r - bb.r) + absf(a.g - bb.g) + absf(a.b - bb.b))
		prev = cur
	ok(sky_jump < 0.06, "sky colours change smoothly through the whole day (max step %.4f)" % sky_jump)
	var noon: Dictionary = atm.sample(700.0)
	ok((noon["sky_top"] as Color).b - (noon["sky_top"] as Color).r > 0.2, "a noon sky is properly blue")
	ok(float(atm.sample(1200.0)["stars"]) > 0.9 and float(noon["stars"]) < 0.01, "stars at night, none at noon")
	ok(WeatherLook.preset("overcast").cloud_cover > 0.85 and WeatherLook.preset("clear").cloud_cover < 0.4, "overcast weather hides the sky; clear weather shows it")
	ok((atm.sample(430.0)["sky_horizon"] as Color).r > (atm.sample(430.0)["sky_horizon"] as Color).b, "dawn horizon is warm")
	# The key light hands over from sun to moon in each twilight: dir*fade and
	# colour*fade must stay continuous (no jump in shadows or colour).
	var key_jump := 0.0
	var key_prev := Vector3.ZERO
	var col_prev := Vector3.ZERO
	for m in range(0, 1440):
		var kl: Dictionary = atm.key_light(float(m))
		var c: Color = atm.sample(float(m))["sun_color"]
		var kv: Vector3 = (kl["dir"] as Vector3) * float(kl["fade"])
		var kc := Vector3(c.r, c.g, c.b) * float(kl["fade"])
		if m > 0:
			key_jump = maxf(key_jump, maxf(kv.distance_to(key_prev), kc.distance_to(col_prev)))
		key_prev = kv
		col_prev = kc
	ok(key_jump < 0.06, "key light is continuous across sunrise and sunset (max step %.4f)" % key_jump)
	var swap_m := atm.sunset_minute + 25.0
	ok(float(atm.key_light(swap_m)["fade"]) < 0.001 and float(atm.key_light(atm.sunrise_minute - 20.0)["fade"]) < 0.001, "key light is fully faded where sun and moon swap")
	ok(atm.key_light(swap_m - 1.0)["is_sun"] and not atm.key_light(swap_m + 1.0)["is_sun"], "the swap itself happens inside the dark band")

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

	print("== tide: storm day + tables")
	var storm_min := 99.0
	var storm_max := -99.0
	for m in range(1440 * 3 + 240, 1440 * 4 - 1):
		var h: float = tide.water_height_abs(m)
		storm_min = minf(storm_min, h); storm_max = maxf(storm_max, h)
	ok(storm_min > tide.SANDBAR_CLOSED_AT, "storm day: low water stays above the bar gate (min %.2f)" % storm_min)
	ok(storm_max <= 4.2 and storm_max < 4.7 - 0.3, "storm day: highs stay under the pier deck (max %.2f)" % storm_max)
	var ex: Array = tide.extremes_for_day(1)
	var first_low: Array = ex.filter(func(e): return not e["high"])
	ok(ex.size() >= 3 and first_low.size() >= 1 and absf(first_low[0]["minute"] - 450.0) < 0.5, "tide table day 1 lists the 07:30 low")
	ok(ex[0]["minute"] < ex[1]["minute"], "tide table is sorted by time")
	var day_two_low: Array = tide.extremes_for_day(2).filter(func(e): return not e["high"])
	ok(day_two_low.size() >= 1 and absf(day_two_low[0]["minute"] - 500.0) < 5.0, "day 2 low is ~50 min later (%d)" % int(day_two_low[0]["minute"]))
	ok(load("res://story/days.gd").get_day(4).rain and load("res://story/days.gd").get_day(4).weather == "Storm", "day 4 data: storm with rain")
	for d in range(1, 8):
		ok(load("res://story/conversations.gd").get_conv("morning_d%d" % d).size() > 0 and load("res://story/conversations.gd").get_conv("evening_d%d" % d).size() > 0, "day %d has morning + evening conversations" % d)

	print("== save/load round trip")
	var save := root.get_node("SaveSystem")
	save.path = "user://test_save.json"
	save.delete_save()
	state.reset()
	clock.set_time(3, 777.0)
	state.discover("shipwreck")
	state.trust = 4
	state.add_log(2, "test entry")
	var director := root.get_node("DayDirector")
	director.rituals = {"stove": true}
	director.lamp_lit = true
	ok(save.save_game("tower_top") and save.has_save(), "save file written")
	state.reset(); director.rituals = {}; director.lamp_lit = false
	clock.set_time(1, 100.0)
	var loc: String = save.load_game()
	ok(loc == "tower_top", "location restored")
	ok(clock.day == 3 and absf(clock.minute_of_day - 777.0) < 0.01, "clock restored")
	ok(state.discovered.has("shipwreck") and state.discovered_day["shipwreck"] == 3 or state.discovered_day.get("shipwreck", 0) == 3, "discoveries + discovery day restored")
	ok(state.trust == 4 and state.logbook.size() == 1 and state.logbook[0]["day"] == 2, "trust + logbook restored")
	ok(director.rituals.has("stove") and director.lamp_lit, "director state restored")
	save.delete_save()

	print("== full day loop (headless, simulated play)")
	state.reset()
	var main: Node3D = load("res://main.tscn").instantiate()
	main.autostart = true
	root.add_child(main)
	await _frames(5)
	var player = main.player
	ok(main.location == "cottage" and director.phase == 0, "new game starts in the cottage, morning phase")
	ok(clock.day == 1 and absf(clock.minute_of_day - 390.0) < 0.5, "day 1 begins at 06:30")
	await _frames(30)
	ok(player.is_on_floor(), "Arthur stands on the cottage floor")
	var t0: float = clock.minute_of_day
	await create_timer(1.2).timeout
	ok(clock.minute_of_day == t0, "clock is frozen while indoors")

	# door is gated until the morning rituals are done
	await _use(main, "door_cottage_out")
	await create_timer(0.3).timeout
	ok(main.location == "cottage" and director.phase == 0, "front door stays shut before the rituals are done")

	await _use(main, "stove")
	await _use(main, "barometer")
	await _use(main, "radio_desk")
	ok(not director.rituals.has("checkin") and not radio.active, "radio check-in refused before the other rituals")
	await _use(main, "tide_table")
	ok(director.rituals.has("stove") and director.rituals.has("barometer") and director.rituals.has("tide_table"), "stove, barometer, tide table done")
	ok(main.hud.modal_open, "tide table panel opened")
	_send_action("interact", true); await _frames(3); _send_action("interact", false)
	await _frames(3)
	ok(not main.hud.modal_open and not player.ui_lock, "tide table closes with interact")

	# wind the weights: tower, hold-to-use
	main._place("tower_base", main.interiors.spawn["tower_base"], 0.0)
	await _frames(10)
	await _use(main, "weights", 0.8)
	ok(not director.weights_wound, "a short press does not wind the weights")
	await _use(main, "weights", 3.4)
	ok(director.weights_wound and director.rituals.has("weights"), "holding E winds the weights")

	main._place("cottage", main.interiors.spawn["cottage"], 0.0)
	await _frames(10)
	await _use(main, "radio_desk")
	ok(director.rituals.has("checkin") and radio.active, "check-in plays Clara's morning call")
	radio.choose(0)
	radio.dismiss()
	ok(director.morning_complete(), "all five morning rituals complete")

	# step out the front door
	await _use(main, "door_cottage_out")
	await create_timer(1.6).timeout
	ok(main.location == "outdoors" and director.phase == 1, "front door leads outdoors; phase is EXPEDITION")
	ok(player.global_position.distance_to(main.island.cottage_exit()) < 2.5, "Arthur steps out at the cottage door")
	ok(absf(player.global_position.y - 8.0) < 0.6, "cottage door stands on solid ground (y %.2f, pad 8.0)" % player.global_position.y)
	var t1: float = clock.minute_of_day
	await create_timer(2.2).timeout
	ok(clock.minute_of_day - t1 > 1.5 and clock.minute_of_day - t1 < 3.0, "clock runs ~1 game-min/sec outdoors (+%.2f)" % (clock.minute_of_day - t1))

	print("== outdoors regression (pier, binoculars, sandbar, swept)")
	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(40)
	ok(player.is_on_floor(), "player stands on the pier (y=%.2f)" % player.global_position.y)
	near(player.global_position.y, Terr.PIER_TOP, 0.2, "standing at deck height")
	Input.action_press("move_forward")
	var z0: float = player.global_position.z
	await _frames(240)
	Input.action_release("move_forward")
	ok(player.global_position.z < z0 - 5.0, "forward input moves Arthur north (z %.1f -> %.1f)" % [z0, player.global_position.z])

	main._place("outdoors", Vector3(0, 10.25, -0.9), 0.0)
	await _frames(15)
	ok(player.nearby != null and player.nearby.id == "lighthouse", "lighthouse door in range")
	await _use(main, "lighthouse")
	await create_timer(1.6).timeout
	ok(main.location == "tower_base" and state.discovered.has("lighthouse"), "lighthouse door leads to the watch room and logs the landmark")
	ok(radio.active, "first visit triggers Clara's lighthouse line")
	radio.dismiss()
	await _use(main, "stairs_up")
	await create_timer(1.6).timeout
	ok(main.location == "tower_top", "stairs lead up to the lantern room")
	await _use(main, "stairs_down")
	await create_timer(1.6).timeout
	ok(main.location == "tower_base", "stairs lead back down")

	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(10)
	player.yaw = 0.0
	player.pitch = 0.0
	Input.action_press("binoculars")
	await _frames(30)
	ok(player.binoculars and player.cam.fov < 40.0, "binoculars narrow the FOV (%.1f)" % player.cam.fov)
	var to_lamp: Vector3 = Vector3(0, 30, -6) - (player.global_position + Vector3(0, 1.72, 0))
	player.pitch = atan2(to_lamp.y, -to_lamp.z)
	await _frames(5)
	ok(player.bino_label.to_lower().contains("lighthouse"), "rangefinder identifies the lighthouse ('%s', %d m)" % [player.bino_label, player.bino_dist])
	Input.action_release("binoculars")
	await _frames(5)

	clock.set_time(1, 450.0 + 372.5)
	tide.refresh()
	var t_before: float = clock.abs_minute()
	var zc: float = 4.0 + sin(20.0 * 0.07) * 3.5
	player.teleport(Vector3(45.0, Terr.height(45.0, zc) + 0.2, zc), 0.0)
	var swept_fired := [false]
	player.swept.connect(func(): swept_fired[0] = true)
	await _frames(20)
	ok(swept_fired[0], "standing on a submerged sandbar sweeps Arthur")
	await create_timer(2.8).timeout
	ok(player.global_position.distance_to(main.island.spawn_point) < 1.5, "swept Arthur is returned to the pier")
	ok(clock.abs_minute() - t_before >= 44.0, "swept costs ~45 game minutes (%.1f)" % (clock.abs_minute() - t_before))
	ok(radio.active, "Clara reacts on the radio after being swept")
	radio.dismiss()
	await _frames(60)
	ok(not main._sweeping, "no sweep loop on the pier at 4.2 m high water")

	print("== clues, dusk, evening")
	state.discover("shipwreck")
	clock.set_time(1, 960.0)
	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(5)
	clock.set_time(1, 995.0)
	await _frames(5)
	ok(director.dusk_nudged, "Clara nudges Arthur at 16:30 dusk")
	radio.dismiss()
	main._place("tower_top", main.interiors.spawn["tower_top"], 0.0)
	clock.set_time(1, 700.0)
	await _frames(10)
	await _use(main, "lamp", 2.6)
	ok(not director.lamp_lit, "lamp refuses to light before 15:00")
	clock.set_time(1, 1000.0)
	await _use(main, "lamp", 2.6)
	ok(director.lamp_lit and director.phase == 2, "lamp lit after 15:00; phase is EVENING")
	ok(main.island.beam_spinning and main.island.beam_arms[0].visible, "outside beam is lit and sweeping (weights wound + lamp lit)")
	var tw: float = clock.minute_of_day
	await _use(main, "bench")
	await create_timer(1.6).timeout
	ok(absf(clock.minute_of_day - (tw + 60.0)) < 1.0, "waiting at the bench passes an hour")

	main._place("cottage", main.interiors.spawn["cottage"], 0.0)
	await _frames(10)
	await _use(main, "radio_desk")
	ok(not director.evening_call_done, "evening call refused before the log is written")
	await _use(main, "bed")
	ok(clock.day == 1, "cannot sleep before the evening tasks are done")
	await _use(main, "log_desk")
	ok(director.log_written and state.logbook.size() == 1, "log entry written")
	ok(state.logbook[0]["text"].contains("PELAGIC"), "log entry records the clue found today")
	await _use(main, "radio_desk")
	ok(director.evening_call_done and radio.active, "evening call plays")
	radio.choose(0)
	radio.dismiss()
	main.hud.toggle_logbook()
	ok(main.hud.modal_open, "logbook opens with Tab")
	main.hud.close_modal()
	save.path = "user://test_save.json"
	await _use(main, "bed")
	await create_timer(3.0).timeout
	ok(clock.day == 2 and absf(clock.minute_of_day - 390.0) < 1.0, "sleeping begins day 2 at 06:30")
	ok(director.phase == 0 and director.rituals.is_empty() and not director.lamp_lit and not director.weights_wound, "day 2 rituals and lamp reset")
	ok(save.has_save(), "autosave written when the new day begins")
	ok(not main.island.beam_spinning, "beam is dark again on the new morning")
	save.delete_save()

	print("== forced home + week end")
	clock.set_time(2, 1259.2)
	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(5)
	await create_timer(1.8).timeout
	ok(main.location == "cottage" and director.phase == 2, "Arthur is forced home at 21:00 and the evening begins")
	clock.set_time(7, 1200.0)
	director.lamp_lit = true; director.log_written = true; director.evening_call_done = true
	var ended := [false]
	director.week_ended.connect(func(): ended[0] = true)
	await _use(main, "bed")
	await create_timer(1.2).timeout
	ok(not ended[0] and clock.day == 7, "day 7: cannot sleep before choosing what to do about the tapes")
	state.set_flag("ending_a")
	await _use(main, "bed")
	await create_timer(1.6).timeout
	ok(ended[0] and clock.day == 7, "sleeping on day 7 after an ending is chosen ends the week without a day 8")
	state.clear_flag("ending_a")
	main.ending_kind = ""
	main.ending_reload = false

	await create_timer(1.5).timeout     # let the day-7 sleep sequence finish unlocking Arthur
	_reset_radio(radio)
	print("== M4: conditions + dialogue variants")
	var Cond = load("res://story/conditions.gd")
	var Conv = load("res://story/conversations.gd")
	var react := root.get_node("ReactiveDirector")
	var tapes := root.get_node("TapePlayer")
	react.auto = false
	state.reset()
	director.begin_day(1)
	clock.set_time(1, 596.0)
	tide.refresh()
	state.trust = 3
	state.set_flag("a")
	state.items.append("canister")
	state.zone = "east_bar"
	ok(Cond.check(["flag:a", "trust>=3", "has:canister", "!has:tape_1", "zone:east_bar,west_bar", "day==1", "time>=500"]), "conditions: AND of flag/trust/item/zone/day/time")
	ok(not Cond.check(["flag:b"]) and not Cond.check(["trust>3"]) and not Cond.check(["zone:pier"]), "conditions: failing clauses fail")
	ok(Cond.check(["tide>=1.4", "tide:rising"]) and not Cond.check(["tide:falling"]), "conditions: tide level and direction at 09:56 (%.2f m)" % tide.current_height)
	ok(Cond.check(["phase:morning"]) and Cond.check(["!phase:evening"]), "conditions: phase")

	state.reset(); state.items.append("canister"); state.set_flag("reported_canister")
	ok(Conv.get_conv("evening_d1")["text"].contains("Thank you for telling me"), "evening_d1: reported variant")
	state.clear_flag("reported_canister"); state.set_flag("withheld_canister")
	ok(Conv.get_conv("evening_d1")["text"].contains("care to tell me"), "evening_d1: withheld variant")
	state.reset()
	ok(Conv.get_conv("evening_d1")["text"].contains("first day on the rock"), "evening_d1: fallback variant")
	state.set_flag("reported_canister"); state.trust = 2
	ok(Conv.get_conv("morning_d2")["text"].contains("Slept better"), "morning_d2: trusting variant")
	state.clear_flag("reported_canister"); state.set_flag("withheld_canister")
	ok(Conv.get_conv("morning_d2")["text"].contains("straight with me"), "morning_d2: withheld variant")
	var filt: Dictionary = Conv.get_conv("evening_d2")
	ok(filt["options"].size() == 2, "options capped at two for the radio UI")

	print("== M4: report / withhold, satchel, reactions")
	state.reset()
	director.begin_day(1)
	clock.set_time(1, 596.0)
	tide.refresh()
	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(5)
	_reset_radio(radio)
	await _use(main, "shipwreck")
	ok(state.has_item("canister"), "taking the canister puts it in the satchel")
	ok(radio.active and radio.current["id"] == "shipwreck", "Clara asks what was in the hull")
	radio.choose(1)
	ok(state.has_flag("withheld_canister") and not state.has_flag("reported_canister") and state.trust == -1, "withholding sets the flag and costs trust")
	radio.dismiss()
	await _frames(3)
	var wreck_it = null
	for n in get_nodes_in_group("interactable"):
		if n.id == "shipwreck": wreck_it = n
	ok(wreck_it != null and not wreck_it.is_available(), "canister pickup disappears once taken")

	# Reactive lines: west stack + withheld canister -> Clara probes
	_reset_radio(radio)
	main._place("outdoors", Vector3(-71.0, 7.0, -8.0), 0.0)
	await _frames(20)
	ok(state.zone == "west_stack", "zone detection: west stack (%s)" % state.zone)
	ok(react.tick() == "r_west_withheld", "Clara probes about the withheld canister on the west stack")
	radio.choose(0)
	ok(state.has_flag("reported_canister") and not state.has_flag("withheld_canister") and state.trust == 1, "confessing later flips the flags and nets trust (%d)" % state.trust)
	radio.dismiss()
	ok(react.tick() == "", "one-shot reactions do not repeat")

	var zc2: float = 4.0 + sin(20.0 * 0.07) * 3.5
	main._place("outdoors", Vector3(45.0, Terr.height(45.0, zc2) + 0.1, zc2), 0.0)
	await _frames(20)
	ok(state.zone == "east_bar", "zone detection: east bar (%s)" % state.zone)
	ok(react.tick() == "r_east_bar_first", "first time on the east bar: Clara's warning")
	radio.dismiss()
	ok(react.tick() == "r_bar_rising", "rising water on a bar: Clara warns (%.2f m)" % tide.current_height)
	radio.dismiss()
	ok(react.tick() == "", "reaction cooldown holds")
	clock.set_time(1, 450.0)
	tide.refresh()
	ok(react.tick() == "", "no bar warning at dead low water")

	print("== M4: chained replies, items, tapes, journal")
	_reset_radio(radio)
	radio.play({"id": "t", "speaker": "X", "priority": 2, "text": "hi", "options": [{"text": "a", "reply": "r", "next": "react_cottage_curious", "trust": 0}]})
	radio.choose(0)
	radio.dismiss()
	await _frames(3)
	ok(radio.active and radio.current.get("id", "") == "react_cottage_curious", "a reply can chain into a follow-up conversation")
	radio.dismiss()
	await _frames(2)

	main._place("cottage", main.interiors.spawn["cottage"], 0.0)
	await _frames(10)
	await _use(main, "shelf_logs")
	ok(state.has_item("uni_logs"), "shelf logbooks go in the satchel")
	await _use(main, "cassette_player")
	ok(not tapes.playing, "cassette player does nothing without a tape")
	state.give_item("tape_1")
	tapes.speed = 40.0
	await _use(main, "cassette_player")
	await _frames(3)
	ok(tapes.playing, "cassette player starts the tape")
	await create_timer(2.0).timeout
	ok(state.has_flag("heard_tape_1") and not tapes.playing, "tape plays to the end and is marked heard")

	main.hud._journal_page = 1
	main.hud._render_journal()
	ok(main.hud._modal_body.text.contains("Pelagic canister") and main.hud._modal_body.text.contains("University logbooks"), "journal satchel page lists items")
	main.hud._journal_page = 2
	main.hud._render_journal()
	ok(main.hud._modal_body.text.contains("June"), "journal tapes page shows the transcript of a heard tape")
	main.hud.close_modal()

	state.reset()
	clock.set_time(1, 900.0)
	state.set_flag("reported_canister"); state.set_flag("heard_tape_1")
	state.discover("shipwreck")
	var LogE = load("res://story/log_entries.gd")
	var entry: String = LogE.compose(1)
	ok(entry.contains("PELAGIC") and entry.contains("Told Clara about the canister") and entry.contains("June"), "log entry records finds, reports and tapes")

	state.reset(); state.give_item("tape_1"); state.set_flag("withheld_canister"); state.trust = -2
	save.path = "user://test_save.json"
	save.save_game("cottage")
	state.reset()
	save.load_game()
	ok(state.has_item("tape_1") and state.has_flag("withheld_canister") and state.trust == -2 and state.flag_day.has("withheld_canister"), "satchel, flags and flag days survive save/load")
	save.delete_save()

	print("== M5: island blockout, tides and surfaces")
	_reset_radio(radio)
	state.reset()
	director.begin_day(1)
	# crest heights along each route
	var north_h := _route_heights(Terr, [Terr.NORTH_A, Terr.NORTH_B, Terr.COVE_C])
	var south_h := _route_heights(Terr, [Terr.SOUTH_A, Terr.SOUTH_B, Terr.VAULT_C])
	ok(north_h.max() > 0.9 and north_h.max() < 1.5, "north cove shelf stands ~1.2 m (max %.2f)" % north_h.max())
	ok(south_h.min() > -1.15 and south_h.min() < -0.85, "south reef bar crest is ~-1.0 m (lowest on route %.2f)" % south_h.min())
	# tidal windows: deepest water over the route's highest-needed point = water - lowest ground on the route past the island shore
	var north_low: float = _route_min(Terr, [Terr.NORTH_B, Terr.COVE_C, Terr.NORTH_A.lerp(Terr.NORTH_B, 0.4)])
	ok(0.2 - north_low < 0.95, "north cove is walkable at an ordinary low (0.2 m)")
	ok(3.0 - north_low > 0.95, "north cove is cut off at 3.0 m")
	var south_min: float = south_h.min()
	ok(0.2 - south_min > tide.SWEPT_DEPTH, "south reef is NOT walkable at an ordinary low (depth %.2f)" % (0.2 - south_min))
	ok(-0.4 - south_min < tide.SWEPT_DEPTH, "south reef IS walkable at the day-5 spring low (depth %.2f)" % (-0.4 - south_min))
	# Walkable minutes (absolute) over the whole week: all must sit inside the day-5 spring lows.
	var open_mins: Array = []
	for m in range(0, 1440 * 7):
		if tide.water_height_abs(float(m)) - south_min < tide.SWEPT_DEPTH:
			open_mins.append(m)
	var outside := 0
	var daytime := 0
	for m in open_mins:
		var near_a: bool = absf(m - (1440 * 4 + tide.low_minute_of_day(5))) <= 80.0
		var near_b: bool = absf(m - (1440 * 4 + tide.low_minute_of_day(5) + 745.0)) <= 80.0
		if not (near_a or near_b):
			outside += 1
		if near_a:
			daytime += 1
	ok(open_mins.size() > 0 and outside == 0, "south reef opens only around the two day-5 spring lows (%d min total, %d stray)" % [open_mins.size(), outside])
	ok(daytime > 45 and daytime < 140, "daytime spring-low window is %d min" % daytime)

	ok(Terr.surface_at(0.0, 20.0, Terr.PIER_TOP) == "wood", "surface: pier is wood")
	ok(Terr.surface_at(Terr.VAULT_C.x, Terr.VAULT_C.y, 0.5) == "concrete", "surface: vault pad is concrete")
	ok(Terr.surface_at(Terr.COVE_C.x, Terr.COVE_C.y, 1.2) == "gravel", "surface: cove is gravel")
	ok(Terr.surface_at(45.0, 4.0, 1.6) == "sand", "surface: east bar is sand")
	ok(Terr.surface_at(10.0, 8.0, 1.8) == "wet", "surface: intertidal rock is wet (%s)" % Terr.surface_at(10.0, 8.0, 1.8))
	ok(Terr.surface_at(0.0, -4.0, 10.2) == "rock", "surface: summit is rock")
	ok(Terr.zone_at(Terr.VAULT_C.x, Terr.VAULT_C.y, 0.5) == "south_reef", "zone: south reef")
	ok(Terr.zone_at(15.0, 40.0, -1.0) == "south_bar", "zone: south bar")
	ok(Terr.zone_at(Terr.COVE_C.x, Terr.COVE_C.y, 1.2) == "north_cove", "zone: north cove")
	ok(Terr.zone_at(-10.0, -34.0, 0.9) == "north_bar", "zone: north bar")

	var buoys := get_nodes_in_group("bell_buoy")
	var strikes: Array = []
	var pitches: Dictionary = {}
	for b in buoys:
		strikes.append(b.strikes)
		pitches[b.pitch] = true
	strikes.sort()
	ok(buoys.size() == 4 and strikes == [1, 2, 3, 4] and pitches.size() == 4, "four bell buoys with 1-4 strikes and distinct pitches")
	var bearings_ok := true
	for b in buoys:
		var pos: Vector3 = b.global_position
		var want: Vector3 = [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)][b.strikes - 1]
		if pos.normalized().dot(want) < 0.6:
			bearings_ok = false
	ok(bearings_ok, "buoy strike counts match compass points (1 N, 2 E, 3 S, 4 W)")

	print("== M5: walking every route with the real physics")
	clock.set_time(1, 450.0)         # day 1, low water 0.2 m
	clock.time_scale = 0.0           # freeze the tide while walking
	Engine.time_scale = 4.0
	var east_ok: bool = await _walk(main, [Vector3(18, 0, 4), _bar(25, true), _bar(45, true), _bar(65, true), Vector3(74, 0, 8)])
	ok(east_ok, "walk: east bar to the wreck stack at low water")
	var west_ok: bool = await _walk(main, [Vector3(-18, 0, -4), _bar(-30, false), _bar(-50, false), _bar(-66, false), Vector3(-71, 0, -8)])
	ok(west_ok, "walk: west bar to the echo cave at low water")
	var cove_ok: bool = await _walk(main, [Vector3(Terr.NORTH_A.x, 0, Terr.NORTH_A.y), Vector3(-10, 0, -34), Vector3(Terr.NORTH_B.x, 0, Terr.NORTH_B.y), Vector3(Terr.COVE_C.x, 0, Terr.COVE_C.y + 3.0)])
	ok(cove_ok and state.zone == "north_cove", "walk: north bar to the cove at low water (zone %s)" % state.zone)
	_reset_radio(radio)

	clock.set_time(1, 450.0)         # ordinary low: vault must be out of reach
	var vault_low: bool = await _walk(main, [Vector3(Terr.SOUTH_A.x, 0, Terr.SOUTH_A.y), Vector3(15, 0, 38), Vector3(Terr.SOUTH_B.x, 0, Terr.SOUTH_B.y), Vector3(Terr.VAULT_C.x, 0, Terr.VAULT_C.y - 2.0)])
	ok(not vault_low, "walk: the vault is out of reach at an ordinary low (Arthur is swept)")
	await create_timer(1.2).timeout
	await create_timer(1.6).timeout
	_reset_radio(radio)
	clock.set_time(5, tide.low_minute_of_day(5))    # the spring low
	tide.refresh()
	var vault_spring: bool = await _walk(main, [Vector3(Terr.SOUTH_A.x, 0, Terr.SOUTH_A.y), Vector3(15, 0, 38), Vector3(Terr.SOUTH_B.x, 0, Terr.SOUTH_B.y), Vector3(Terr.VAULT_C.x, 0, Terr.VAULT_C.y - 2.0)], 90.0)
	ok(vault_spring and state.zone == "south_reef", "walk: the vault pad IS reachable at the day-5 spring low (zone %s)" % state.zone)
	Engine.time_scale = 1.0
	clock.time_scale = 1.0

	print("== A1: 2 m causeway lane + markers")
	var lane_a: Vector2 = Terr.SOUTH_A
	var lane_d: Vector2 = (Terr.SOUTH_B - lane_a).normalized()
	var lane_n := Vector2(lane_d.y, -lane_d.x)
	clock.time_scale = 0.0
	Engine.time_scale = 4.0
	for off in [1.8, -1.8]:
		_reset_radio(radio)
		clock.set_time(5, tide.low_minute_of_day(5))
		tide.refresh()
		var pts: Array = []
		for sdist in [0.0, 10.0, 20.0, 30.0, 36.0]:
			var q: Vector2 = lane_a + lane_d * sdist + lane_n * off
			pts.append(Vector3(q.x, 0, q.y))
		pts.append(Vector3(Terr.VAULT_C.x, 0, Terr.VAULT_C.y - 2.0))
		var lane_ok: bool = await _walk(main, pts, 90.0)
		ok(lane_ok, "walk: reef lane reachable at %.1f m off the centreline" % off)
		await _settle(main)
	_reset_radio(radio)
	clock.set_time(5, tide.low_minute_of_day(5))
	tide.refresh()
	var bad_pts: Array = []
	for sdist in [0.0, 10.0, 20.0, 30.0, 36.0]:
		var q2: Vector2 = lane_a + lane_d * sdist + lane_n * 3.0
		bad_pts.append(Vector3(q2.x, 0, q2.y))
	var lane_bad: bool = await _walk(main, bad_pts, 60.0)
	ok(not lane_bad, "walk: 3.0 m off the centreline Arthur is swept")
	await _settle(main)
	_reset_radio(radio)
	Engine.time_scale = 1.0
	clock.time_scale = 1.0
	var lane_mid: Vector2 = lane_a + lane_d * 20.0
	near(Terr.height(lane_mid.x, lane_mid.y), -1.0, 0.01, "lane centre is -1.0 m")
	var edge2: Vector2 = lane_mid + lane_n * 2.0
	near(Terr.height(edge2.x, edge2.y), -1.0, 0.01, "lane is still dead level at exactly 2.0 m")
	var edge24: Vector2 = lane_mid + lane_n * 2.45
	ok(-0.4 - Terr.height(edge24.x, edge24.y) > tide.SWEPT_DEPTH, "ground at 2.45 m is deep enough to sweep Arthur at the spring low")
	ok(get_nodes_in_group("reef_pole").size() == 14, "14 lane-edge poles are placed")
	ok(get_nodes_in_group("reef_sign_board").size() == 1, "the causeway sign is placed")
	var sign_top: float = get_nodes_in_group("reef_sign_board")[0].get_meta("board_y")
	ok(sign_top > 4.2 + 0.5, "sign board stays above the 4.2 m high tide")

	print("== M5: cove and vault content")
	_reset_radio(radio)
	state.reset()
	state.zone = "north_cove"
	main._place("outdoors", Vector3(Terr.COVE_C.x, Terr.height(Terr.COVE_C.x, Terr.COVE_C.y) + 0.1, Terr.COVE_C.y + 1.0), 0.0)
	await _frames(15)
	ok(react.tick() == "r_north_cove_first", "Clara greets the north cove")
	radio.dismiss()
	await _use(main, "cable")
	ok(state.has_item("cable_tag") and state.discovered.has("cable"), "the cable tag goes in the satchel")
	radio.choose(0)
	ok(state.has_flag("reported_cable"), "reporting the cable sets the flag")
	_reset_radio(radio)
	main._place("outdoors", Vector3(Terr.VAULT_C.x, Terr.height(Terr.VAULT_C.x, Terr.VAULT_C.y) + 0.1, Terr.VAULT_C.y - 2.0), 0.0)
	await _frames(15)
	await _use(main, "vault")
	ok(state.has_item("tape_2") and state.discovered.has("vault"), "June's cassette comes out of the vault")
	_reset_radio(radio)
	state.give_item("tape_1")
	tapes.speed = 40.0
	main._place("cottage", main.interiors.spawn["cottage"], 0.0)
	await _frames(10)
	await _use(main, "cassette_player")
	await _frames(3)
	ok(tapes.playing and tapes.current == "tape_1", "cassette player plays tape 1 first")
	await create_timer(2.5).timeout
	ok(state.has_flag("heard_tape_1"), "tape 1 marked heard")
	await _use(main, "cassette_player")
	await create_timer(2.5).timeout
	ok(state.has_flag("heard_tape_2"), "...then tape 2 (June's recording)")
	state.reset(); state.give_item("tape_2"); state.set_flag("reported_vault")
	var Conv2 = load("res://story/conversations.gd")
	ok(Conv2.get_conv("evening_d5")["text"].contains("You brought it up"), "evening_d5 reacts to a reported vault")

	print("== A2: audio catalog sanity")
	var catalog: Dictionary = root.get_node("AudioDirector").catalog()
	ok(catalog.size() >= 28, "audio catalog lists %d sounds" % catalog.size())
	var loops := ["surf_bed", "wind_bed", "tape_hiss", "boat_engine"]
	var all_sane := true
	for nm in catalog:
		var st := _audio_stats(catalog[nm])
		var sane: bool = st["rms"] > 0.003 and st["peak"] < 0.99 and not st["nan"] and st["seconds"] > 0.05
		if not sane:
			all_sane = false
			printerr("  FAIL: audio '%s' stats %s" % [nm, st])
	ok(all_sane, "every catalogued sound is audible, unclipped and finite")
	for nm in loops:
		var st2 := _audio_stats(catalog[nm])
		ok(catalog[nm].loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s is a looping stream" % nm)
		ok(st2["wrap_jump"] <= st2["mean_step"] * 6.0 + 0.002, "%s loop seam has no click (jump %.4f vs mean step %.4f)" % [nm, st2["wrap_jump"], st2["mean_step"]])

	print("== M6: trust simulation (whole week through the real radio code)")
	await create_timer(1.5).timeout
	react.auto = false
	var sim_honest: Dictionary = await _sim_play("honest")
	var sim_bad: Dictionary = await _sim_play("dishonest")
	var sim_mix3: Dictionary = await _sim_play("mixed3")
	var sim_mix2: Dictionary = await _sim_play("mixed2")
	print("  trust: honest %d/%d  dishonest %d/%d  mixed3 %d/%d  mixed2 %d/%d  (day6 eve / final)" % [sim_honest["t6"], sim_honest["t7"], sim_bad["t6"], sim_bad["t7"], sim_mix3["t6"], sim_mix3["t7"], sim_mix2["t6"], sim_mix2["t7"]])
	ok(sim_honest["admitted"] and sim_honest["offered"] == ["ending_a", "ending_b"] and sim_honest["ending"] == "b", "honest week: Clara admits everything; A and B offered; reaches ending B")
	ok(sim_bad["stone"] and not sim_bad["admitted"] and sim_bad["offered"] == ["ending_a", "ending_c"] and sim_bad["ending"] == "c", "dishonest week: Clara stonewalls; A and C offered; reaches ending C")
	ok(sim_mix3["partial"] and not sim_mix3["admitted"] and sim_mix3["offered"] == ["ending_a", "ending_c"], "one dishonest answer in three loses the full confession (partial)")
	ok(sim_mix2["partial"] and sim_mix2["ending"] != "", "an even mix still reaches an ending via the partial route")
	ok(sim_honest["t6"] >= 16 and sim_honest["t6"] - 12 >= 4, "honest play clears the high-trust threshold (12) with margin (%d)" % sim_honest["t6"])
	ok(sim_bad["t6"] < 3, "dishonest play lands below the mid-trust threshold (%d)" % sim_bad["t6"])
	for sim in [sim_honest, sim_bad, sim_mix3, sim_mix2]:
		ok(sim["ending"] != "", "no dead ends: every policy reaches an ending (%s)" % sim["ending"])
	ok(not (sim_honest["offered"].has("ending_c")) and not (sim_bad["offered"].has("ending_b")), "B only at high trust; C never offered to a fully trusting Arthur")

	print("== M6: tapes, pickups, reactions, journal")
	state.reset()
	director.begin_day(1)
	_reset_radio(radio)
	var floor_it = _find_it("floorboard")
	var locker_it = _find_it("locker")
	var tin_it = _find_it("tin")
	var svc_it = _find_it("buoy_service")
	ok(not floor_it.is_available() and not locker_it.is_available() and not tin_it.is_available() and not svc_it.is_available(), "day 1: no late-game pickups are available")
	clock.set_time(3, 600.0)
	ok(floor_it.is_available() and not locker_it.is_available(), "day 3: the loose floorboard opens, the locker does not")
	clock.set_time(4, 600.0)
	ok(locker_it.is_available() and not tin_it.is_available(), "day 4: the lantern locker opens; the cove tin still needs tape 4 heard")
	state.set_flag("heard_tape_4")
	ok(tin_it.is_available() and not svc_it.is_available(), "tin opens once Walt's last tape is heard; the service hatch needs day 6")
	clock.set_time(6, 600.0)
	ok(svc_it.is_available(), "day 6: the buoy service hatch opens")
	state.give_item("tape_3"); state.give_item("tape_6")
	ok(not floor_it.is_available() and not svc_it.is_available(), "taken pickups disappear")

	var Conv3 = load("res://story/conversations.gd")
	var want := {"tape_3": "Ruth", "tape_4": "Wickenden", "tape_5": "I said one hour", "tape_6": "Dad"}
	for tid in want:
		var txt := ""
		for l in Conv3.tape(tid).get("lines", []):
			txt += String(l["text"]) + " "
		ok(txt.contains(want[tid]), "%s transcript carries its story beat ('%s')" % [tid, want[tid]])
	tapes.speed = 80.0
	main._place("cottage", main.interiors.spawn["cottage"], 0.0)
	state.reset()
	for tid in ["tape_1", "tape_2", "tape_3", "tape_4", "tape_5", "tape_6"]:
		tapes.play(tid)
		await create_timer(1.8).timeout
	ok(["tape_1", "tape_2", "tape_3", "tape_4", "tape_5", "tape_6"].all(func(t): return state.has_flag("heard_" + t)), "all six tapes play through and are marked heard")

	var hidden_count := [0]
	var hid_cb := func(): hidden_count[0] += 1
	radio.hidden.connect(hid_cb)
	_reset_radio(radio)
	hidden_count[0] = 0
	radio.play({"id": "t", "speaker": "X", "priority": 2, "text": "a", "options": [{"text": "x", "reply": "r", "next": "end_c", "trust": 0}]})
	radio.choose(0)
	radio.dismiss()
	await _frames(2)
	ok(radio.active and radio.current.get("id", "") == "end_c" and hidden_count[0] == 0, "a chained follow-up replaces the panel without hiding it in between")
	radio.dismiss()
	ok(hidden_count[0] == 1, "the panel hides exactly once, after the last line")
	radio.hidden.disconnect(hid_cb)

	state.reset()
	clock.set_time(4, 740.0)
	state.location = "cottage"
	ok(react.tick() == "r_storm_midday", "Clara's storm-day midday call reaches Arthur indoors")
	radio.dismiss()
	ok(react.tick() == "", "...and only once")
	state.location = "cottage"
	clock.set_time(3, 740.0)
	state.reset()
	ok(react.tick() == "", "...and not on other days")

	state.reset()
	for tid in ["tape_1", "tape_2", "tape_3", "tape_4", "tape_5", "tape_6"]:
		state.give_item(tid)
		state.set_flag("heard_" + tid)
	main.hud._journal_page = 2
	main.hud._render_journal()
	await _frames(4)
	var vbar = main.hud._modal_scroll.get_v_scroll_bar()
	ok(vbar.max_value > main.hud._modal_scroll.size.y + 50.0, "journal tapes page scrolls when six transcripts are heard (content %.0f > view %.0f)" % [vbar.max_value, main.hud._modal_scroll.size.y])
	main.hud.close_modal()
	var json_text := FileAccess.get_file_as_string("res://dialogue/dialogue.json")
	ok(not json_text.contains("Rockland"), "the real station name 'Rockland' is gone from the script")
	ok(json_text.contains("Station Penobscot"), "...replaced by the fictional Station Penobscot")

	print("== M6: ending scenes")
	var save2 := root.get_node("SaveSystem")
	save2.endings_path = "user://test_endings.json"
	if FileAccess.file_exists(save2.endings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save2.endings_path))
	main.ending_reload = false
	Engine.time_scale = 6.0
	for kind in ["a", "b", "c"]:
		state.reset()
		director.begin_day(7)
		if kind == "a": state.set_flag("clara_admitted")
		main.ending_kind = ""
		main._boat = null
		main._boat_arrived = false
		main._busy = false
		main.player.locked = false
		_reset_radio(radio)
		save2.path = "user://test_save.json"
		save2.save_game("cottage")
		main.start_ending(kind)
		var t_wait := Time.get_ticks_msec()
		while not main.hud._ending_panel.visible and (Time.get_ticks_msec() - t_wait) < 60000:
			await process_frame
		ok(main.hud._ending_panel.visible and main.hud._ending_name.text == main.ENDINGS[kind]["name"], "ending %s: end card shows '%s'" % [kind.to_upper(), main.ENDINGS[kind]["name"]])
		ok(main.location == "outdoors" and main.player.global_position.distance_to(Vector3(0, Terr.PIER_TOP, 31.0)) < 3.0, "ending %s: Arthur stands on the pier at dawn" % kind.to_upper())
		if kind == "c":
			ok(main._boat == null and not main.player.binoculars, "ending C: no boat, no binoculars: just the beam and static")
		else:
			ok(main._boat != null and main._boat_arrived and main.player.binoculars and main.player.bino_label.to_lower().contains("relief boat"), "ending %s: relief boat arrives and is seen through the binoculars (%s)" % [kind.to_upper(), main.player.bino_label])
		ok(save2.endings_seen().has(kind) and not save2.has_save(), "ending %s is recorded and the run's save is removed" % kind.to_upper())
		if kind == "b":
			ok(state.has_flag("buoy_off"), "ending B switches the buoy off")
			var hydros := get_nodes_in_group("hydrophone")
			ok(hydros.size() == 1 and not hydros[0].is_live(), "ending B silences the hydrophone ping")
		if kind == "a":
			ok(main._ending_body("a").contains("Dunmore"), "ending A epilogue reflects Clara's full admission")
		if main._boat != null:
			main._boat.remove_from_group("bino_target")
			main._boat.queue_free()
		main.hud._ending_panel.visible = false
		main.hud._ending_open = false
		main.player.binoculars = false
	Engine.time_scale = 1.0
	ok(save2.endings_seen() == ["a", "b", "c"], "all three endings recorded across runs")
	main._on_ending_closed()
	ok(clock.day == 1 and state.discovered.is_empty() and state.ending == "", "closing the end card resets the game to a fresh Day 1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save2.endings_path))

	print("== M7: settings, rebinding, menus")
	var cfg := root.get_node("Settings")
	cfg.path = "user://test_settings.cfg"
	cfg.delete_saved_settings()
	cfg.reset_defaults(); cfg.reset_bindings()
	main.ending_kind = ""
	main.started = true
	main._busy = false
	main.player.locked = false
	main.player.ui_lock = false
	paused = false
	_reset_radio(radio)
	state.reset()
	director.begin_day(1)
	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(20)

	cfg.set_v("vol_master", 7.0)
	near(cfg.v("vol_master"), 1.0, 0.0001, "settings are clamped to their range")
	cfg.set_v("nonsense", 1)
	ok(not cfg.values.has("nonsense"), "unknown settings are ignored")
	cfg.set_v("invert_y", 1)
	ok(cfg.v("invert_y") == true, "booleans are coerced")
	cfg.set_v("msaa", 9)
	ok(cfg.v("msaa") == 3, "integer settings are clamped (msaa 9 -> 3)")
	cfg.reset_defaults()

	cfg.set_preset(0)
	ok(cfg.v("quality_preset") == 0 and cfg.v("shadow_quality") == 1 and absf(cfg.v("render_scale") - 0.75) < 0.001, "Low preset applies its bundle")
	cfg.set_v("msaa", 3)
	ok(cfg.v("quality_preset") == 4, "changing one graphics setting by hand switches the preset to Custom")
	cfg.set_preset(3)
	ok(cfg.v("fps_cap") == 60 and Engine.max_fps == 60, "Steam Deck preset caps the frame rate at 60 and applies it to the engine")
	cfg.set_preset(2)
	ok(Engine.max_fps == 0 and cfg.v("shadow_quality") == 3, "High preset removes the cap")

	cfg.set_v("vol_ambience", 0.5)
	var amb: int = AudioServer.get_bus_index("Ambience")
	ok(amb >= 0 and absf(AudioServer.get_bus_volume_db(amb) - linear_to_db(0.5)) < 0.01, "ambience slider sets the Ambience bus volume (%.2f dB)" % AudioServer.get_bus_volume_db(amb))
	cfg.set_v("vol_sfx", 0.0)
	ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "volume 0 mutes the bus")
	cfg.set_v("vol_master", 0.25)
	ok(absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.25)) < 0.01, "master volume drives the Master bus")
	var audio := root.get_node("AudioDirector")
	ok(audio._surf.bus == "Ambience" and audio._hiss.bus == "Radio", "ambient beds are on Ambience, tape hiss on Radio")
	audio.play_sfx("wood_0")
	cfg.reset_defaults()

	cfg.set_v("ui_scale", 1.25)
	near(root.content_scale_factor, 1.25, 0.001, "interface size scales the window content")
	cfg.set_v("ui_scale", 1.0)

	print("-- bindings")
	ok(cfg.binding_text("interact", "kb") == "E" and cfg.binding_text("interact", "pad") == "A", "defaults: interact = E / A")
	var f_key := InputEventKey.new(); f_key.physical_keycode = KEY_F
	var cleared: Array = cfg.rebind("interact", f_key)
	ok(cfg.binding_text("interact", "kb") == "F" and cleared.is_empty(), "interact rebinds to F")
	ok(InputMap.action_has_event("interact", f_key) and not InputMap.action_has_event("interact", _key_ev(KEY_E)), "InputMap really changed (F in, E out)")
	cleared = cfg.rebind("watch", _key_ev(KEY_F))
	ok(cleared == ["Inspect / use"] and cfg.binding_text("interact", "kb") == "(unbound)", "binding a key already in use unbinds the other action and says so")
	var x_btn := InputEventJoypadButton.new(); x_btn.button_index = JOY_BUTTON_X
	cfg.rebind("interact", x_btn)
	ok(cfg.binding_text("interact", "pad") == "X", "gamepad button rebinds independently of the keyboard")
	var stick := InputEventJoypadButton.new(); stick.button_index = JOY_BUTTON_Y
	ok(cfg.rebind("move_forward", stick).is_empty() and cfg.binding_text("move_forward", "pad").begins_with("Left stick"), "movement stays fixed to the stick on gamepad")
	cfg.save_settings()
	cfg.reset_bindings()
	ok(cfg.binding_text("interact", "kb") == "E" and cfg.binding_text("watch", "kb") == "Q" and cfg.binding_text("interact", "pad") == "A", "reset restores every default binding")
	cfg.load_settings()
	ok(cfg.binding_text("watch", "kb") == "F" and cfg.binding_text("interact", "pad") == "X", "custom bindings survive a save/load round trip")
	cfg.reset_bindings()
	for ev in [_key_ev(KEY_G), x_btn, f_key]:
		ok(cfg.ev_to_dict(cfg.dict_to_ev(cfg.ev_to_dict(ev))) == cfg.ev_to_dict(ev), "event serialisation round-trips (%s)" % cfg.event_text(ev))

	print("-- persistence")
	cfg.reset_defaults()
	cfg.set_v("mouse_sens", 1.7); cfg.set_v("brightness", 1.2); cfg.set_v("toggle_hold", true); cfg.set_v("subtitle_scale", 1.4); cfg.set_v("vol_music", 0.3)
	ok(cfg.save_settings() and FileAccess.file_exists(cfg.path), "settings file is written")
	cfg.values = cfg.DEFAULTS.duplicate()
	ok(cfg.load_settings() and absf(cfg.v("mouse_sens") - 1.7) < 0.001 and cfg.v("toggle_hold") == true and absf(cfg.v("subtitle_scale") - 1.4) < 0.001 and absf(cfg.v("vol_music") - 0.3) < 0.001, "settings survive a save/load round trip")
	cfg.reset_defaults()

	print("-- effects in play")
	var pl = main.player
	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(30)
	state.set_flag("binoculars_ready")      # Clara has mentioned them
	cfg.set_v("toggle_binoculars", true)
	_send_action("binoculars", true); await _frames(3); _send_action("binoculars", false); await _frames(3)
	ok(pl.binoculars, "toggle mode: one tap raises the binoculars and they stay up")
	_send_action("binoculars", true); await _frames(3); _send_action("binoculars", false); await _frames(3)
	ok(not pl.binoculars, "...and a second tap lowers them")
	cfg.set_v("toggle_binoculars", false)
	await _frames(5)
	ok(not pl.binoculars, "hold mode: released means down")

	cfg.set_v("reduce_motion", false)
	Input.action_press("move_forward")
	var span := [999.0, -999.0]
	for i in 60:
		await process_frame
		span[0] = minf(span[0], pl.cam.position.y); span[1] = maxf(span[1], pl.cam.position.y)
	Input.action_release("move_forward")
	ok(span[1] - span[0] > 0.02, "walking bobs the camera (range %.3f m)" % (span[1] - span[0]))
	cfg.set_v("reduce_motion", true)
	main._place("outdoors", main.island.spawn_point, 0.0)
	await _frames(20)
	span = [999.0, -999.0]
	Input.action_press("move_forward")
	for i in 60:
		await process_frame
		span[0] = minf(span[0], pl.cam.position.y); span[1] = maxf(span[1], pl.cam.position.y)
	Input.action_release("move_forward")
	ok(span[1] - span[0] < 0.005, "reduce motion removes the head-bob (range %.4f m)" % (span[1] - span[0]))
	cfg.set_v("reduce_motion", false)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var mouse_ok := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if mouse_ok:
		pl.pitch = 0.0
		var mm := InputEventMouseMotion.new(); mm.relative = Vector2(0, 100)
		pl._unhandled_input(mm)
		var normal: float = pl.pitch
		pl.pitch = 0.0
		cfg.set_v("invert_y", true)
		pl._unhandled_input(mm)
		ok(normal < 0.0 and pl.pitch > 0.0 and absf(absf(normal) - absf(pl.pitch)) < 1e-6, "invert Y flips the vertical look direction")
		cfg.set_v("invert_y", false)
		pl.pitch = 0.0
		cfg.set_v("mouse_sens", 2.0)
		pl._unhandled_input(mm)
		ok(absf(pl.pitch) > absf(normal) * 1.9, "mouse sensitivity scales look speed (%.4f vs %.4f)" % [absf(pl.pitch), absf(normal)])
		cfg.set_v("mouse_sens", 1.0)
	else:
		print("  (skipped: this display driver will not capture the mouse)")

	state.reset(); director.begin_day(1)
	main._place("tower_base", main.interiors.spawn["tower_base"], 0.0)
	await _frames(10)
	cfg.set_v("toggle_hold", true)
	await _use(main, "weights")
	await create_timer(3.6).timeout
	ok(director.weights_wound, "toggle hold-to-use: a single press winds the weights by itself")
	cfg.set_v("toggle_hold", false)

	main._place("cottage", main.interiors.spawn["cottage"], 0.0)
	await _frames(10)
	cfg.set_v("toggle_watch", true)
	_send_action("watch", true); await _frames(3); _send_action("watch", false); await _frames(3)
	ok(main.hud._watch.visible, "toggle mode: tapping the watch key leaves the watch up")
	_send_action("watch", true); await _frames(3); _send_action("watch", false); await _frames(3)
	ok(not main.hud._watch.visible, "...and tapping again puts it away")
	cfg.set_v("toggle_watch", false)

	cfg.set_v("subtitle_scale", 1.5)
	ok(main.hud._radio_text.get_theme_font_size("font_size") == int(17 * 1.5) and main.hud._tape_text.get_theme_font_size("font_size") == int(20 * 1.5), "subtitle size scales the radio and tape text")
	cfg.set_v("subtitle_scale", 1.0)

	cfg.set_v("brightness", 1.3); cfg.set_v("exposure", 1.0); cfg.set_v("glow", true)
	main._apply_lighting()
	var base_exposure: float = main.env.tonemap_exposure
	cfg.set_v("exposure", 1.2)
	main._apply_lighting()
	ok(absf(main.env.adjustment_brightness - 1.3) < 0.001 and absf(main.env.tonemap_exposure - base_exposure * 1.2) < 0.001 and main.env.glow_enabled, "brightness, exposure and bloom reach the environment")
	cfg.set_v("glow", false)
	main._apply_lighting()
	ok(not main.env.glow_enabled, "turning bloom off turns it off")
	cfg.reset_defaults()
	cfg.set_v("shadow_quality", 0)
	main._place("outdoors", main.island.spawn_point, 0.0)
	clock.set_time(1, 700.0)
	main._apply_lighting()
	ok(not main.sun.shadow_enabled, "shadows off turns the sun's shadows off")
	cfg.set_v("shadow_quality", 3)
	main._apply_lighting()
	ok(main.sun.shadow_enabled and main.sun.directional_shadow_max_distance >= 220.0, "high shadow quality draws shadows farther")
	cfg.reset_defaults()
	cfg.set_v("ocean_detail", 0)
	ok(main.ocean.mesh.subdivide_width == 120, "ocean detail Low halves the wave mesh")
	cfg.set_v("ocean_detail", 2)
	ok(main.ocean.mesh.subdivide_width == 240, "...and High restores it")
	cfg.set_v("night_assist", 1.0)
	clock.set_time(1, 1200.0)
	main._apply_lighting()
	var assisted: float = main.env.ambient_light_energy
	cfg.set_v("night_assist", 0.0)
	main._apply_lighting()
	ok(assisted > main.env.ambient_light_energy + 0.3, "night brightness assist lifts the dark (%.2f vs %.2f)" % [assisted, main.env.ambient_light_energy])
	cfg.reset_defaults()
	clock.set_time(1, 700.0)

	print("-- menus")
	var menus = main.menus
	ok(not menus.is_open() and not paused, "menus start closed")
	_send_action("pause", true); await _frames(3); _send_action("pause", false); await _frames(3)
	ok(menus.is_open() and paused, "Esc opens the pause menu and pauses the game")
	var t_paused0: float = clock.minute_of_day
	await create_timer(0.8).timeout
	ok(clock.minute_of_day == t_paused0, "the clock does not run while paused")
	_send_action("pause", true); await _frames(3); _send_action("pause", false); await _frames(3)
	ok(not menus.is_open() and not paused, "Esc again resumes")
	main.hud.show_tide_table(1, tide.extremes_for_day(1))
	_send_action("pause", true); await _frames(3); _send_action("pause", false); await _frames(3)
	ok(not main.hud.modal_open and not menus.is_open(), "Esc closes an open journal page first, without pausing")

	menus.open_pause()
	menus._show_only("settings")
	var sm = menus.settings_menu()
	ok(sm.visible and sm.tabs.get_tab_count() == 5, "Settings has five tabs")
	sm.controls["vol_radio"].value = 0.4
	near(cfg.v("vol_radio"), 0.4, 0.001, "a slider writes straight to Settings")
	sm.controls["shadow_quality"].select(1)
	sm.controls["shadow_quality"].item_selected.emit(1)
	ok(cfg.v("shadow_quality") == 1 and cfg.v("quality_preset") == 4, "a dropdown writes to Settings (and flips the preset to Custom)")
	sm.controls["quality_preset"].select(3)
	sm.controls["quality_preset"].item_selected.emit(3)
	ok(cfg.v("quality_preset") == 3 and cfg.v("fps_cap") == 60 and sm.controls["fps_cap"].selected == FPS_CAPS_IDX_60, "choosing a preset in the menu applies it and updates the other controls")
	var glow_flip: bool = not cfg.DEFAULTS["glow"]
	sm.controls["glow"].button_pressed = glow_flip
	ok(cfg.v("glow") == glow_flip, "a checkbox writes to Settings")
	cfg.set_v("vol_master", 0.9)
	near(sm.controls["vol_master"].value, 0.9, 0.001, "changes from elsewhere refresh the menu controls")
	sm.tabs.current_tab = 2
	sm._reset_tab()
	ok(cfg.v("glow") == cfg.DEFAULTS["glow"] and absf(cfg.v("brightness") - 1.0) < 0.001 and absf(cfg.v("vol_master") - 0.9) < 0.001, "Reset this tab restores only that tab's settings")
	sm.tabs.current_tab = 3
	sm._begin_capture("binoculars", "kb", sm.bind_buttons["binoculars|kb"])
	ok(sm.is_capturing() and sm.bind_buttons["binoculars|kb"].text.begins_with("Press"), "clicking a binding waits for a key")
	sm.apply_capture(_key_ev(KEY_V))
	ok(not sm.is_capturing() and sm.bind_buttons["binoculars|kb"].text.contains("V") and sm.bind_buttons["binoculars|pad"].text == "LT", "capturing a key rebinds it and refreshes the labels")
	ok(sm.bind_buttons["move_forward|pad"].disabled and not sm.bind_buttons["interact|pad"].disabled, "gamepad movement bindings are locked, button bindings are not")
	cfg.reset_bindings()
	menus.back()
	ok(menus.is_open() and paused, "Back from Settings returns to the pause menu")
	menus.back()
	ok(not menus.is_open() and not paused, "Back from the pause menu resumes")
	menus.open_settings_from_title()
	ok(menus.is_open() and not paused, "Settings opened from the title does not pause the game")
	menus.back()
	ok(not menus.is_open(), "...and closes cleanly")
	menus.open_pause()
	menus._open_controls()
	ok(menus._ctl_title.text.contains("Moving about"), "the pause menu shows the controls reference")
	menus.resume()
	ok(not paused, "resume unpauses")
	cfg.reset_defaults(); cfg.reset_bindings()
	cfg.delete_saved_settings()

	print("== M7b: music stings")
	var aud := root.get_node("AudioDirector")
	var cat2: Dictionary = aud.catalog()
	for nm in ["sting_end_a", "sting_end_b", "sting_end_c", "sting_confront", "sting_june", "sting_walt"]:
		var st3 := _audio_stats(cat2[nm])
		ok(cat2.has(nm) and st3["seconds"] > 5.0 and st3["seconds"] < 14.0 and st3["peak"] < 0.9 and st3["rms"] > 0.03 and cat2[nm].loop_mode == AudioStreamWAV.LOOP_DISABLED, "%s is a %.1f s unlooped sting at a sane level (rms %.3f)" % [nm, st3["seconds"], st3["rms"]])
		ok(absf(cat2[nm].data.decode_s16(0)) < 400 and absf(cat2[nm].data.decode_s16(cat2[nm].data.size() - 2)) < 400, "%s fades in and out (no click at the edges)" % nm)
	ok(aud._sting_player.bus == "Music", "stings play on the Music bus")
	aud.play_sting("sting_june")
	ok(aud.sting_playing() == "sting_june", "a sting can be played")
	aud._sting_player.stop()
	state.reset()
	tapes.finished.emit("tape_2")
	ok(aud.sting_playing() == "sting_june" and state.has_flag("sting_tape_2"), "finishing June's tape plays her sting")
	aud._sting_player.stop()
	tapes.finished.emit("tape_2")
	ok(aud.sting_playing() == "", "...but only once per run")
	tapes.finished.emit("tape_4")
	ok(aud.sting_playing() == "sting_walt", "Walt's last tape has its own sting")
	tapes.finished.emit("tape_1")
	aud._sting_player.stop()
	tapes.finished.emit("tape_1")
	ok(aud.sting_playing() == "", "ordinary tapes get no music")
	state.reset(); director.begin_day(6); state.trust = 13
	_reset_radio(radio)
	radio.play(load("res://story/conversations.gd").get_conv("evening_d6"))
	ok(aud.sting_playing() == "sting_confront", "Clara's Day 6 confrontation opens with a sting")
	aud._sting_player.stop()
	_reset_radio(radio)
	radio.play(load("res://story/conversations.gd").get_conv("evening_d6"))
	ok(aud.sting_playing() == "", "...once only")
	_reset_radio(radio)
	radio.play(load("res://story/conversations.gd").get_conv("morning_d1"))
	ok(aud.sting_playing() == "", "everyday calls have no music")
	_reset_radio(radio)
	for kind in ["a", "b", "c"]:
		aud._sting_player.stop()
		main._show_ending_card(kind)
		ok(aud.sting_playing() == "sting_end_" + kind, "ending %s has its own sting" % kind.to_upper())
	aud._sting_player.stop()
	if FileAccess.file_exists(root.get_node("SaveSystem").endings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(root.get_node("SaveSystem").endings_path))

	print("== review fixes (PR #1)")
	# 1. gamepad capture can always be cancelled
	menus.open_pause()
	menus._show_only("settings")
	var rsm = menus.settings_menu()
	var esc := _key_ev(KEY_ESCAPE)
	esc.pressed = true
	rsm.tabs.current_tab = 3
	rsm._begin_capture("binoculars", "pad", rsm.bind_buttons["binoculars|pad"])
	rsm._input(esc)
	ok(not rsm.is_capturing() and rsm._hint.text == "Cancelled.", "Esc cancels a gamepad rebind capture (a keyboard-only player is not stuck)")
	rsm._begin_capture("binoculars", "pad", rsm.bind_buttons["binoculars|pad"])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	rsm._input(click)
	ok(not rsm.is_capturing(), "a mouse click cancels a gamepad rebind capture")
	rsm._begin_capture("binoculars", "pad", rsm.bind_buttons["binoculars|pad"])
	rsm._input(InputEventMouseMotion.new())
	var small_stick := InputEventJoypadMotion.new()
	small_stick.axis = JOY_AXIS_LEFT_X
	small_stick.axis_value = 0.3
	rsm._input(small_stick)
	ok(rsm.is_capturing(), "mouse movement and small stick motion do not disturb a gamepad capture")
	var pad_btn := InputEventJoypadButton.new()
	pad_btn.button_index = JOY_BUTTON_Y
	pad_btn.pressed = true
	rsm._input(pad_btn)
	ok(not rsm.is_capturing() and rsm.bind_buttons["binoculars|pad"].text.contains("Y"), "a gamepad button still rebinds")
	rsm._begin_capture("binoculars", "kb", rsm.bind_buttons["binoculars|kb"])
	rsm._input(esc)
	ok(not rsm.is_capturing(), "Esc still cancels a keyboard capture")
	cfg.reset_bindings()

	# 3. Pause can never lose its last keyboard binding
	cfg.rebind("pause", _key_ev(KEY_F10))
	ok(cfg.rebind_blocked("interact", _key_ev(KEY_F10)) != "", "taking Pause's only keyboard key is refused")
	ok(cfg.rebind("interact", _key_ev(KEY_F10)).is_empty() and cfg.binding_text("pause", "kb").contains("F10") and not cfg.binding_text("interact", "kb").contains("F10"), "...and nothing changes")
	rsm._begin_capture("interact", "kb", rsm.bind_buttons["interact|kb"])
	rsm.apply_capture(_key_ev(KEY_F10))
	ok(rsm._hint.text.begins_with("Pause needs a keyboard key"), "the menu explains why it was refused")
	ok(cfg.rebind_blocked("interact", _key_ev(KEY_G)) == "", "other keys are fine")
	var stolen: Array = cfg.rebind("pause", _key_ev(KEY_E))
	ok(stolen.size() > 0 and cfg.binding_text("pause", "kb").contains("E"), "Pause itself can still take a key from another action")
	cfg.reset_bindings()
	menus.resume()

	# 2. a preempted call's follow-up plays after the urgent call
	_reset_radio(radio)
	radio.play({"id": "low", "speaker": "X", "priority": 2, "text": "a", "options": [{"text": "x", "reply": "r", "next": "react_cottage_curious", "trust": 0}]})
	radio.choose(0)
	radio.play({"id": "urgent", "speaker": "X", "priority": 3, "text": "b", "options": []})
	ok(radio.active and radio.current.get("id", "") == "urgent", "an urgent call takes over at once")
	radio.dismiss()
	ok(radio.active and radio.current.get("id", "") == "react_cottage_curious", "...and the interrupted call's follow-up plays after it, not before")
	_reset_radio(radio)
	# the next call is current in the same frame, so nothing can slip in between
	radio.play({"id": "a", "speaker": "X", "priority": 2, "text": "a", "options": []})
	radio.play({"id": "b", "speaker": "X", "priority": 2, "text": "b", "options": []})
	radio.dismiss()
	ok(radio.active and radio.current.get("id", "") == "b", "dismissing shows the queued call immediately")
	radio.play({"id": "c", "speaker": "X", "priority": 2, "text": "c", "options": []})
	ok(radio.current.get("id", "") == "b" and radio._queue.size() == 1, "a new call queues behind it instead of replacing it")
	_reset_radio(radio)

	# 4. cancelling a tape stops it cleanly
	var old_speed: float = tapes.speed
	tapes.speed = 200.0
	state.reset()
	var fin := [0]
	var fin_cb := func(_id): fin[0] += 1
	tapes.finished.connect(fin_cb)
	tapes.play("tape_1")
	ok(tapes.playing and aud._hiss.playing, "a tape starts playing with the hiss")
	tapes.cancel()
	ok(not tapes.playing and tapes.current == "" and not aud._hiss.playing, "cancel stops the tape and the hiss")
	await create_timer(1.2).timeout
	ok(fin[0] == 0 and not state.has_flag("heard_tape_1"), "a cancelled tape is never marked heard")
	tapes.play("tape_2")
	await create_timer(1.5).timeout
	ok(fin[0] == 1 and state.has_flag("heard_tape_2") and not tapes.playing, "a later tape plays normally")
	tapes.finished.disconnect(fin_cb)
	tapes.speed = old_speed
	state.reset()

	# 5. damaged saves are rejected before anything is applied
	save.path = "user://test_save.json"
	save.delete_save()
	state.reset(); director.begin_day(2)
	clock.set_time(2, 321.0)
	state.trust = 7
	state.ending = "b"
	save.save_game("cottage")
	var good: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save.path))
	var bad_cases := {}
	var no_state := good.duplicate(true); no_state.erase("state"); bad_cases["missing state"] = JSON.stringify(no_state)
	var bad_clock := good.duplicate(true); bad_clock["clock"] = {"day": "x"}; bad_cases["wrong clock types"] = JSON.stringify(bad_clock)
	var no_loc := good.duplicate(true); no_loc.erase("location"); bad_cases["missing location"] = JSON.stringify(no_loc)
	bad_cases["not json"] = "{\"version\": 1, \"clock\": "
	for case_name in bad_cases:
		var f := FileAccess.open(save.path, FileAccess.WRITE)
		f.store_string(bad_cases[case_name])
		f.close()
		clock.set_time(5, 100.0)
		state.trust = 1
		var r: String = save.load_game()
		ok(r == "" and clock.day == 5 and absf(clock.minute_of_day - 100.0) < 0.01 and state.trust == 1, "a damaged save (%s) is ignored and nothing is half-applied" % case_name)
	var f2 := FileAccess.open(save.path, FileAccess.WRITE)
	f2.store_string(JSON.stringify(good))
	f2.close()
	state.reset()
	ok(save.load_game() == "cottage" and clock.day == 2 and state.trust == 7, "an intact save still loads")
	# 6. the ending in progress is saved
	ok(state.ending == "b", "the ending in progress survives save and load")
	var old_save := good.duplicate(true); old_save["state"].erase("ending")
	var f3 := FileAccess.open(save.path, FileAccess.WRITE)
	f3.store_string(JSON.stringify(old_save))
	f3.close()
	state.ending = "c"
	save.load_game()
	ok(state.ending == "", "a save from before this field loads with no ending")
	save.delete_save()
	state.reset()

	print("-- typography: standard capitalisation")
	var shouty: Array = []
	var seen := [0]    # lambdas capture ints by value, so count in an array
	var scan := func(txt: String, where: String) -> void:
		seen[0] += 1
		if _shouty(txt):
			shouty.append("%s: '%s'" % [where, txt.replace("\n", " / ")])
	var stack: Array = [main.hud, main.menus]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is Label or n is Button or n is CheckBox or n is OptionButton:
			scan.call(n.text, "%s.%s" % [n.get_class(), n.name])
		if n is OptionButton:
			for i in n.item_count:
				scan.call(n.get_item_text(i), "option %s" % n.name)
		if n is TabContainer:
			for i in n.get_tab_count():
				scan.call(n.get_tab_title(i), "tab")
	var ending_mod = load("res://story/endings.gd")
	for k in ["a", "b", "c"]:
		scan.call(ending_mod.ending_name(k), "ending " + k)
	for pg in load("res://ui/tutorial_data.gd").pages():
		scan.call(pg.title, "tutorial title")
		scan.call(pg.text, "tutorial text")
		for row in pg.rows:
			for cell in row:
				scan.call(cell, "tutorial row")
	for t in ["tape_1", "tape_2", "tape_3", "tape_4", "tape_5", "tape_6"]:
		scan.call(String(load("res://story/conversations.gd").tape(t).get("title", "")), t)
	scan.call(load("res://story/conversations.gd").SPEAKER, "speaker")
	scan.call(load("res://story/conversations.gd").SPEAKERS["arthur"], "speaker arthur")
	for lbl in ["Low tide", "High tide", "Rising", "Falling"]:
		scan.call(lbl, "tide label")
	scan.call(clock.hhmm(), "clock")
	scan.call(main._day_subtitle(), "day card subtitle")
	ok(seen[0] > 150, "capitalisation scan covers the whole UI (%d strings)" % seen[0])
	ok(shouty.is_empty(), "no all-caps UI text outside key names and acronyms: %s" % [shouty])
	ok(_shouty("LOW TIDE") and _shouty("NEW WATCH") and _shouty("Tape 1 - WALT JANUARY") and not _shouty("Low tide") and not _shouty("MSAA") and not _shouty("W A S D") and not _shouty("Hold LB / LT"), "the capitalisation guard flags shouting but allows key names")

	print("-- radio panel layout")
	var all_ok := true
	var worst := ""
	var longest: Dictionary = {}
	var conv_ids: Array = load("res://story/conversations.gd")._json.get("convs", {}).keys()
	for cid in conv_ids:
		for variant in load("res://story/conversations.gd")._json["convs"][cid]:
			if String(variant.get("text", "")).length() > String(longest.get("text", "")).length():
				longest = variant.duplicate()
				longest["id"] = cid
	ok(longest.has("text"), "found the longest radio line (%s, %d chars)" % [longest.get("id", ""), String(longest.get("text", "")).length()])
	var long_opts: Array = [{"text": "I will check the east bar before the water comes back up and then call you from the cottage"}, {"text": "Understood, I will stay inside until the tide has turned and the light is on"}]
	for sc in [1.0, 1.5, 1.8]:
		cfg.set_v("subtitle_scale", sc)
		main.hud.apply_text_scale()
		main.hud._on_line(load("res://story/conversations.gd").SPEAKER, longest.get("text", ""), long_opts)
		await _frames(4)
		# Headless runs use a stand-in text height (about 3x real), so measure width
		# exactly and estimate height from line counts. Screenshots check the real thing.
		var r: Rect2 = main.hud._radio.get_global_rect()
		var fs_text: float = 17.0 * sc
		var fs_opt: float = 14.0 * sc
		var opt_w: float = main.hud._opt_buttons[0].size.x
		var opt_lines: float = 1.0
		for o in long_opts:
			opt_lines = maxf(opt_lines, ceilf((String(o["text"]).length() + 3) * fs_opt * 0.6 / maxf(opt_w - 20.0, 1.0)))
		var est_h: float = 32.0 + fs_text * 1.0 + main.hud._radio_text.get_line_count() * fs_text * 1.45 + opt_lines * fs_opt * 1.6 + 30.0
		var cx: float = r.position.x + r.size.x * 0.5
		var inside: bool = r.position.x >= 0.0 and r.end.x <= 1280.0 and absf(cx - 640.0) < 1.0 and est_h <= 720.0 - 60.0 - 40.0
		if not inside:
			all_ok = false
			worst = "scale %.1f -> %s, estimated height %.0f" % [sc, r, est_h]
	ok(all_ok, "the radio panel stays inside 1280x720 with the longest line at every subtitle size %s" % worst)
	cfg.reset_defaults()
	main.hud.apply_text_scale()
	main.hud._radio.visible = false

	print("== playtest 1: binoculars are unlocked by Clara's first check-in")
	var bino_day: int = clock.day
	var bino_flag: bool = state.has_flag("binoculars_ready")
	state.clear_flag("binoculars_ready")
	clock.day = 1
	main.hud.close_modal()
	main.player.locked = false
	main.player.ui_lock = false
	ok(not state.binoculars_ready(), "on Day 1 the binoculars are locked until the check-in")
	Input.action_press("binoculars")
	await _frames(6)
	ok(not main.player.binoculars, "holding the binoculars key does nothing before Clara mentions them")
	Input.action_release("binoculars")
	await _frames(3)
	main._unlock_binoculars()
	ok(state.has_flag("binoculars_ready") and state.binoculars_ready(), "the first check-in unlocks them")
	Input.action_press("binoculars")
	await _frames(6)
	ok(main.player.binoculars, "after the check-in the key raises them")
	Input.action_release("binoculars")
	await _frames(3)
	state.clear_flag("binoculars_ready")
	clock.day = 2
	ok(state.binoculars_ready(), "older saves (past Day 1) keep their binoculars")
	clock.day = bino_day
	if bino_flag:
		state.set_flag("binoculars_ready")
	var conv_lib = load("res://story/conversations.gd")      # loaded at runtime: it needs the autoloads
	ok(conv_lib.get_conv("morning_d1")["text"].contains("binoculars"), "Clara's first call mentions the binoculars")

	print("== playtest 1: setup tutorial")
	var hud = main.hud
	hud._open_tutorial()
	await _frames(2)
	ok(hud._tut.visible and hud._tut_idx == 0 and not hud._tut_next.visible, "tutorial opens on the 'how are you playing' choice")
	ok(TutorialData.pages_for("kb")[0]["rows"][1].size() == 2 and TutorialData.pages_for("pad")[0]["rows"][1].size() == 2, "per-device tutorial pages carry one controls column")
	hud._tut_pick("pad")
	await _frames(3)
	var tut_text := ""
	for ch in hud._tut_body.get_children():
		for l in ch.get_children():
			if l is Label:
				tut_text += (l as Label).text + "|"
	ok(hud._tut_idx == 1 and "Left stick" in tut_text and not ("W A S D" in tut_text), "gamepad choice shows only gamepad controls (%s)" % tut_text.left(60))
	ok(hud._tut_next.custom_minimum_size.x >= 240.0 and hud._tut_next.custom_minimum_size.y >= 48.0 and hud._tut_next.visible, "the Next button is large and visible")
	var tut_esc := InputEventAction.new()
	tut_esc.action = "ui_cancel"
	tut_esc.pressed = true
	hud._unhandled_input(tut_esc)
	ok(hud._tut_idx == 0, "Esc / B steps back to the choice, so there is always a way out")
	hud._tut_pick("kb")
	for _i in 2:
		hud._tut_go(hud._tut_idx + 1)
	await _frames(2)
	ok(hud._tut_next.text == "Step into the cottage" and hud._tut.visible, "the last tutorial page offers 'Step into the cottage'")
	hud._tut.visible = false
	hud._title.visible = false

	print("\n%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

## True when a visible string reads as shouting: a word of 5+ capitals, or a
## line of 6+ letters that is mostly capitals. Short key names and acronyms
## (W A S D, LB, LT, L3, MSAA, FXAA) are fine.
func _shouty(txt: String) -> bool:
	var letters := 0
	var upper := 0
	for i in txt.length():
		var ch := txt[i]
		if ch.to_upper() != ch.to_lower():
			letters += 1
			if ch == ch.to_upper():
				upper += 1
	if letters >= 6 and float(upper) / float(letters) >= 0.8:
		return true
	for w in txt.split(" ", false):
		var core := ""
		for i in w.length():
			if w[i].to_upper() != w[i].to_lower():
				core += w[i]
		if core.length() >= 5 and core == core.to_upper():
			return true
	return false

## Terrain heights sampled along a polyline of Vector2 points (every metre).
func _route_heights(Terr, pts: Array) -> Array:
	var out: Array = []
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b))
		for k in n + 1:
			var q: Vector2 = a.lerp(b, float(k) / maxf(n, 1))
			out.append(Terr.height(q.x, q.y))
	return out

func _route_min(Terr, pts: Array) -> float:
	var m := 99.0
	for q in pts:
		m = minf(m, Terr.height(q.x, q.y))
	return m

## A point on the east/west bar centre line.
func _bar(x: float, east: bool) -> Vector3:
	if east:
		return Vector3(x, 0, 4.0 + sin((x - 25.0) * 0.07) * 3.5)
	return Vector3(x, 0, -6.0 + cos((x + 25.0) * 0.08) * 3.0)

## Walk Arthur through waypoints with the real controller. Returns false if swept or stuck.
func _walk(main, pts: Array, max_s := 60.0) -> bool:
	var Terr = load("res://world/terrain.gd")
	var p = main.player
	var swept := [false]
	var cb := func(): swept[0] = true
	p.swept.connect(cb)
	var first: Vector3 = pts[0]
	root.get_node("TideSystem").refresh()      # the clock was just set; do not walk on last frame's water level
	main._place("outdoors", Vector3(first.x, Terr.height(first.x, first.z) + 0.2, first.z), 0.0)
	await _frames(10)
	var t_start := Time.get_ticks_msec()
	var reached := true
	for i in range(1, pts.size()):
		var target: Vector3 = pts[i]
		while true:
			var here := Vector2(p.global_position.x, p.global_position.z)
			var to := Vector2(target.x, target.z) - here
			if to.length() < 2.0:
				break
			if swept[0] or (Time.get_ticks_msec() - t_start) / 1000.0 > max_s:
				reached = false
				print("  (note: walk ended early: swept=%s pos=%s target=%s water=%.2f depth=%.2f t=%.1fs)" % [swept[0], p.global_position, target, root.get_node("TideSystem").current_height, p.water_depth, (Time.get_ticks_msec() - t_start) / 1000.0])
				break
			p.yaw = atan2(-to.x, -to.y)
			Input.action_press("move_forward")
			await process_frame
		if not reached:
			break
	Input.action_release("move_forward")
	p.swept.disconnect(cb)
	return reached

func _find_it(id: String):
	for n in get_nodes_in_group("interactable"):
		if n.id == id:
			return n
	return null

## ---- trust simulation (plays the real radio code day by day) ----
func _sim_play(policy: String) -> Dictionary:
	var state := root.get_node("GameState")
	var director := root.get_node("DayDirector")
	var Conv = load("res://story/conversations.gd")
	state.reset()
	var n := [0]
	var t6 := 0
	var offered: Array = []
	for day in range(1, 8):
		director.begin_day(day)
		for step in _sim_script(day):
			if step.has("give"): state.give_item(step["give"])
			if step.has("flag"): state.set_flag(step["flag"])
			if step.has("conv"):
				if step["conv"] == "evening_d6":
					t6 = state.trust
				if step["conv"] == "evening_d7":
					for o in Conv.get_conv("evening_d7")["options"]:
						offered.append(String(o["set"][0]) if o.has("set") else "?")
				await _sim_say(step["conv"], policy, n)
	var ending := ""
	for k in ["a", "b", "c"]:
		if state.has_flag("ending_" + k): ending = k
	return {"t6": t6, "t7": state.trust, "admitted": state.has_flag("clara_admitted"), "partial": state.has_flag("clara_partial"),
		"stone": state.has_flag("clara_stonewalled"), "offered": offered, "ending": ending}

func _sim_script(day: int) -> Array:
	match day:
		1: return [{"conv": "morning_d1"}, {"give": "canister"}, {"conv": "shipwreck"}, {"give": "tape_1"}, {"conv": "seacave"}, {"conv": "evening_d1"}]
		2: return [{"conv": "morning_d2"}, {"flag": "heard_tape_1"}, {"conv": "evening_d2"}]
		3: return [{"conv": "morning_d3"}, {"give": "cable_tag"}, {"conv": "cable"}, {"give": "tape_3"}, {"flag": "heard_tape_3"}, {"conv": "evening_d3"}]
		4: return [{"conv": "morning_d4"}, {"conv": "midday_d4"}, {"give": "tape_4"}, {"flag": "heard_tape_4"}, {"conv": "evening_d4"}]
		5: return [{"conv": "morning_d5"}, {"give": "tape_2"}, {"conv": "vault"}, {"flag": "heard_tape_2"}, {"conv": "evening_d5"}]
		6: return [{"give": "tape_5"}, {"flag": "heard_tape_5"}, {"give": "tape_6"}, {"flag": "heard_tape_6"}, {"conv": "morning_d6"}, {"conv": "evening_d6"}]
		_: return [{"conv": "morning_d7"}, {"conv": "evening_d7"}]

func _sim_say(id: String, policy: String, n: Array) -> void:
	var radio := root.get_node("RadioSystem")
	var Conv = load("res://story/conversations.gd")
	radio._queue.clear()
	radio._pending_next = ""
	if radio.active:
		radio.dismiss()
	radio._queue.clear()
	var conv: Dictionary = Conv.get_conv(id)
	if conv.is_empty():
		return
	radio.play(conv)
	for guard in 6:
		if not radio.active:
			break
		var opts: Array = radio.current.get("options", [])
		if opts.size() > 0 and radio.awaiting_choice:
			radio.choose(_sim_pick(opts, policy, n))
		radio.dismiss()
		await process_frame

func _sim_pick(opts: Array, policy: String, n: Array) -> int:
	n[0] += 1
	for i in opts.size():
		var sets: Array = opts[i].get("set", [])
		if sets.has("ending_a") or sets.has("ending_b") or sets.has("ending_c"):
			var want := "ending_b" if policy == "honest" else ("ending_c" if policy == "dishonest" else "ending_a")
			for j in opts.size():
				if opts[j].get("set", []).has(want):
					return j
			return 0
	var best := 0
	var worst := 0
	for i in opts.size():
		if int(opts[i].get("trust", 0)) > int(opts[best].get("trust", 0)): best = i
		if int(opts[i].get("trust", 0)) < int(opts[worst].get("trust", 0)): worst = i
	match policy:
		"honest": return best
		"dishonest": return worst
		"mixed3": return worst if n[0] % 3 == 0 else best
		_: return worst if n[0] % 2 == 0 else best

## Peak / RMS / NaN / loop-seam statistics for a 16-bit mono AudioStreamWAV.
func _audio_stats(stream) -> Dictionary:
	var data: PackedByteArray = stream.data
	var n := data.size() / 2
	var peak := 0.0
	var sum_sq := 0.0
	var step_sum := 0.0
	var prev := 0.0
	var first := 0.0
	var last := 0.0
	for i in n:
		var v := float(data.decode_s16(i * 2)) / 32768.0
		if i == 0:
			first = v
		else:
			step_sum += absf(v - prev)
		peak = maxf(peak, absf(v))
		sum_sq += v * v
		prev = v
		last = v
	return {"peak": peak, "rms": sqrt(sum_sq / maxf(n, 1)), "nan": is_nan(sum_sq), "seconds": float(n) / stream.mix_rate,
		"mean_step": step_sum / maxf(n - 1, 1), "wrap_jump": absf(first - last)}

## Wait out any sweep/respawn sequence so the next walk starts clean.
func _settle(main) -> void:
	for i in 400:
		if not main._sweeping and not main.player.locked and not main._busy:
			return
		await process_frame
	await process_frame

func _key_ev(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	return e

const FPS_CAPS_IDX_60 := 2

func _reset_radio(radio) -> void:
	radio._queue.clear()
	radio._pending_next = ""
	for i in 4:
		if radio.active:
			radio.dismiss()
			radio._queue.clear()

## Walk Arthur to an interactable (by id) and use it: tap, or hold for `hold` seconds.
func _use(main: Node3D, id: String, hold := 0.0) -> void:
	var target = null
	for n in get_nodes_in_group("interactable"):
		if n.id == id:
			target = n
	if target == null:
		failures += 1
		printerr("  FAIL: no interactable '%s'" % id)
		return
	var p = main.player
	var base: Vector3 = target.global_position - Vector3(0, 1.1, 0)
	p.teleport(base + Vector3(0, 0.05, 0), p.yaw)
	await _frames(4)
	if hold > 0.0:
		Input.action_press("interact")
		await create_timer(hold).timeout
		Input.action_release("interact")
	else:
		_send_action("interact", true)
		await _frames(2)
		_send_action("interact", false)
	await _frames(3)

func _send_action(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)

func _frames(n: int) -> void:
	for i in n:
		await process_frame
