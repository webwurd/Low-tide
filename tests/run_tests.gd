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
	ok(player.bino_label.contains("LIGHTHOUSE"), "rangefinder identifies the lighthouse ('%s', %d m)" % [player.bino_label, player.bino_dist])
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
	await create_timer(1.6).timeout
	ok(ended[0] and clock.day == 7, "sleeping on day 7 ends the week without a day 8")

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

	print("\n%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

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
