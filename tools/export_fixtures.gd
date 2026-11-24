extends SceneTree
## Exports golden fixtures from the Godot build for the Unity/C# port.
## The Godot game is the oracle: C# tests must reproduce these results.
##   godot --headless -s tools/export_fixtures.gd
## Inputs : unity/Fixtures/spec.json (hand-authored states and scenarios)
## Outputs: unity/Fixtures/*.json (deterministic: run twice, diff is empty)

var dir := ""
var spec: Dictionary = {}
var clock
var tide
var state
var director
var radio
var react
var Conv
var Terr
var Dys
var Cond
var LogE
var End
var hidden_count := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	dir = ProjectSettings.globalize_path("res://") + "unity/Fixtures"
	spec = JSON.parse_string(FileAccess.get_file_as_string(dir + "/spec.json"))
	clock = root.get_node("GameClock"); tide = root.get_node("TideSystem"); state = root.get_node("GameState")
	director = root.get_node("DayDirector"); radio = root.get_node("RadioSystem"); react = root.get_node("ReactiveDirector")
	Conv = load("res://story/conversations.gd"); Terr = load("res://world/terrain.gd"); Dys = load("res://story/days.gd")
	Cond = load("res://story/conditions.gd"); LogE = load("res://story/log_entries.gd"); End = load("res://story/endings.gd")
	react.auto = false
	radio.hidden.connect(func(): hidden_count += 1)
	var counts := {}
	counts["tide"] = _tide()
	counts["terrain"] = _terrain()
	counts["days"] = _days()
	counts["conditions"] = _conditions()
	counts["conversations"] = _conversations()
	counts["reactions"] = _reactions()
	counts["radio"] = await _radio()
	counts["trust_sim"] = await _trust_sim()
	counts["log_entries"] = _log_entries()
	counts["save"] = _save()
	counts["endings"] = _endings()
	_write("meta", {"counts": counts, "generator": "tools/export_fixtures.gd"})
	print("fixtures written: ", counts)
	quit(0)

func _write(name: String, data) -> void:
	var f := FileAccess.open("%s/%s.json" % [dir, name], FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "", true, true))
	f.close()

# ---- state ---------------------------------------------------------------

func _reset_radio() -> void:
	radio._queue.clear()
	radio._pending_next = ""
	if radio.active:
		radio.dismiss()
	radio._queue.clear()
	radio._pending_next = ""

func _apply(s: Dictionary) -> void:
	_reset_radio()
	state.reset()
	director.begin_day(int(s["day"]))
	clock.set_time(int(s["day"]), float(s["minute"]))
	state.trust = int(s["trust"])
	var fdays: Dictionary = s.get("flag_days", {})
	for f in s["flags"]:
		state.set_flag(String(f))
		if fdays.has(f):
			state.flag_day[f] = int(fdays[f])
	for it in s["items"]:
		state.items.append(String(it))
	var disc = s["discovered"]
	if typeof(disc) == TYPE_DICTIONARY:
		for k in disc:
			state.discovered[k] = true
			state.discovered_day[k] = int(disc[k])
	state.zone = String(s["zone"])
	state.location = String(s["location"])
	director.phase = int(s["phase"])
	tide.refresh()

func _canon(conv: Dictionary) -> String:
	if conv.is_empty():
		return ""
	var parts: Array = [str(conv["speaker"]), str(int(conv["priority"])), str(conv["text"])]
	for o in conv.get("options", []):
		parts.append("%s~%d~%s~%s~%s~%s" % [o.get("text", ""), int(o.get("trust", 0)), ",".join(PackedStringArray(o.get("set", []))),
			",".join(PackedStringArray(o.get("clear", []))), String(o.get("next", "")), o.get("reply", "")])
	return "|".join(PackedStringArray(parts))

func _conv_sig(conv: Dictionary) -> Dictionary:
	if conv.is_empty():
		return {"hash": "", "head": ""}
	return {"hash": _canon(conv).sha256_text(), "head": String(conv["text"]).left(32), "options": conv.get("options", []).size()}

# ---- tide ----------------------------------------------------------------

func _tide() -> int:
	var samples: Array = []
	var m := 0.0
	while m <= 1440.0 * 7:
		samples.append([m, tide.water_height_abs(m)])
		m += 15.0
	m = 3.3
	while m <= 1440.0 * 7:
		samples.append([m, tide.water_height_abs(m)])
		m += 37.0
	var storm: Array = []
	m = 0.0
	while m <= 1440.0 * 7:
		storm.append([m, tide.storm_weight(m)])
		m += 60.0
	var ext := {}
	var lows := {}
	for d in range(1, 8):
		ext[str(d)] = tide.extremes_for_day(d)
		lows[str(d)] = tide.low_minute_of_day(d)
	var bands: Array = []
	# Explicit literals (not an accumulating loop) so exact band boundaries are unambiguous.
	for depth in [-0.5, -0.1, 0.0, 0.01, 0.1, 0.29, 0.3, 0.31, 0.5, 0.69, 0.7, 0.71, 0.9, 0.94, 0.95, 0.96, 1.0, 1.5]:
		bands.append([depth, tide.depth_band(depth), tide.speed_multiplier(depth)])
	var gates: Array = []
	for h in [-0.4, 0.2, 2.0, 2.1, 2.11, 3.0, 4.2]:
		gates.append([h, tide.sandbars_open(h)])
	var whd: Array = []
	for d in range(1, 8):
		for mm in [0.0, 390.0, 600.0, 900.0, 1439.0]:
			whd.append([d, mm, tide.water_height(d, mm)])
	_write("tide", {"samples": samples, "storm": storm, "extremes": ext, "low_minute_of_day": lows, "bands": bands, "gates": gates, "water_height": whd})
	return samples.size()

# ---- terrain --------------------------------------------------------------

func _terrain() -> int:
	var heights: Array = []
	var zones: Array = []
	var surfaces: Array = []
	var x := -105.0
	var xs: Array = []
	while x <= 105.0:
		xs.append(x)
		x += 7.0
	for z in xs:
		for xx in xs:
			var h: float = Terr.height(xx, z)
			heights.append(h)
			zones.append(Terr.zone_at(xx, z, h))
			surfaces.append(Terr.surface_at(xx, z, h))
	var named := {
		"summit": Vector2(0, -4), "pier_mid": Vector2(0, 24), "pier_end": Vector2(0, 36), "cottage_pad": Terr.COTTAGE_POS, "cove": Terr.COVE_C,
		"vault": Terr.VAULT_C, "east_stack": Vector2(76, 6), "west_stack": Vector2(-74, -8), "east_bar": Vector2(45, 4.0 + sin(20.0 * 0.07) * 3.5),
		"west_bar": Vector2(-45, -6.0 + cos(-20.0 * 0.08) * 3.0), "north_bar": Vector2(-10, -34), "south_bar": Vector2(15, 38),
	}
	var points: Array = []
	for k in named:
		var p: Vector2 = named[k]
		var h2: float = Terr.height(p.x, p.y)
		points.append({"name": k, "x": p.x, "z": p.y, "height": h2, "zone": Terr.zone_at(p.x, p.y, h2), "surface": Terr.surface_at(p.x, p.y, h2)})
	# causeway lane profile: height vs lateral offset at the lane's midpoint
	var a: Vector2 = Terr.SOUTH_A
	var d: Vector2 = (Terr.SOUTH_B - a).normalized()
	var n := Vector2(d.y, -d.x)
	var mid: Vector2 = a + d * 20.0
	var lane: Array = []
	var off := 0.0
	while off <= 4.5:
		var q: Vector2 = mid + n * off
		lane.append([off, Terr.height(q.x, q.y)])
		off += 0.1
	_write("terrain", {"min": -105.0, "step": 7.0, "count": xs.size(), "heights": heights, "zones": zones, "surfaces": surfaces, "points": points,
		"lane": lane, "lane_mid": [mid.x, mid.y], "pier": {"top": Terr.PIER_TOP, "on_pier": [Terr.on_pier(0, 20), Terr.on_pier(5, 20), Terr.on_pier(0, 5), Terr.on_pier(1.85, 12.5), Terr.on_pier(1.86, 12.5)]}})
	return heights.size()

# ---- days -----------------------------------------------------------------

func _days() -> int:
	var out: Array = []
	for n in range(1, 8):
		var dd = Dys.get_day(n)
		out.append({"day": dd.day, "title": dd.title, "weather": dd.weather, "barometer": dd.barometer, "fog_density": dd.fog_density,
			"fog_tint": dd.fog_tint.to_html(false), "light_scale": dd.light_scale, "rain": dd.rain, "wave_height": dd.wave_height,
			"wind_db": dd.wind_db, "lamp_after": dd.lamp_after, "morning_conv": dd.morning_conv, "evening_conv": dd.evening_conv})
	_write("days", {"wake_minute": Dys.WAKE_MINUTE, "last_day": Dys.LAST_DAY, "days": out})
	return out.size()

# ---- conditions ------------------------------------------------------------

func _conditions() -> int:
	var res := {}
	var n := 0
	for s in spec["states"]:
		_apply(s)
		var row := {}
		for c in spec["conditions"]:
			row[c] = Cond.check([c])
			n += 1
		res[s["name"]] = row
	_write("conditions", {"results": res})
	return n

# ---- conversations -----------------------------------------------------------

func _conversations() -> int:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://dialogue/dialogue.json"))
	var ids: Array = raw["convs"].keys()
	ids.sort()
	ids.append("opening")
	ids.append("no_such_conv")
	var res := {}
	var n := 0
	for s in spec["states"]:
		_apply(s)
		var row := {}
		for id in ids:
			row[id] = _conv_sig(Conv.get_conv(id))
			n += 1
		res[s["name"]] = row
	_write("conversations", {"ids": ids, "results": res, "reactions": raw["reactions"], "tape_ids": raw["tapes"].keys()})
	return n

# ---- reactions ----------------------------------------------------------------

func _reactions() -> int:
	var out := {}
	var n := 0
	for sc in spec["reaction_scenarios"]:
		_apply(sc["state"])
		var results: Array = []
		for step in sc["steps"]:
			if step[0] == "tick":
				var id: String = react.tick()
				results.append(id)
				_reset_radio()
				n += 1
			else:
				clock.advance(float(step[1]))
				tide.refresh()
		out[sc["name"]] = {"ticks": results, "trust": state.trust, "flags": _flags()}
	_write("reactions", out)
	return n

func _flags() -> Array:
	var f: Array = []
	for k in state.flags:
		if state.flags[k]:
			f.append(k)
	f.sort()
	return f

# ---- radio ---------------------------------------------------------------------

func _radio_snapshot() -> Dictionary:
	var q: Array = []
	for c in radio._queue:
		q.append(c.get("id", ""))
	return {"active": radio.active, "current": radio.current.get("id", ""), "awaiting": radio.awaiting_choice, "queue": q,
		"hidden": hidden_count, "trust": state.trust, "flags": _flags()}

func _radio() -> int:
	var out := {}
	var n := 0
	for sc in spec["radio_scenarios"]:
		_apply(sc["state"])
		hidden_count = 0
		var snaps: Array = []
		for op in sc["ops"]:
			match op[0]:
				"play": radio.play(Conv.get_conv(String(op[1])))
				"choose": radio.choose(int(op[1]))
				"dismiss": radio.dismiss()
			await process_frame
			snaps.append(_radio_snapshot())
			n += 1
		out[sc["name"]] = snaps
	_reset_radio()
	_write("radio", out)
	return n

# ---- trust simulation (whole week through the real radio code) ------------------------

func _sim_script(day: int) -> Array:
	match day:
		1: return [{"conv": "morning_d1"}, {"give": "canister"}, {"conv": "shipwreck"}, {"give": "tape_1"}, {"conv": "seacave"}, {"conv": "evening_d1"}]
		2: return [{"conv": "morning_d2"}, {"flag": "heard_tape_1"}, {"conv": "evening_d2"}]
		3: return [{"conv": "morning_d3"}, {"give": "cable_tag"}, {"conv": "cable"}, {"give": "tape_3"}, {"flag": "heard_tape_3"}, {"conv": "evening_d3"}]
		4: return [{"conv": "morning_d4"}, {"conv": "midday_d4"}, {"give": "tape_4"}, {"flag": "heard_tape_4"}, {"conv": "evening_d4"}]
		5: return [{"conv": "morning_d5"}, {"give": "tape_2"}, {"conv": "vault"}, {"flag": "heard_tape_2"}, {"conv": "evening_d5"}]
		6: return [{"give": "tape_5"}, {"flag": "heard_tape_5"}, {"give": "tape_6"}, {"flag": "heard_tape_6"}, {"conv": "morning_d6"}, {"conv": "evening_d6"}]
		_: return [{"conv": "morning_d7"}, {"conv": "evening_d7"}]

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

func _sim_say(id: String, policy: String, n: Array) -> Array:
	var chosen: Array = []
	_reset_radio()
	var conv: Dictionary = Conv.get_conv(id)
	if conv.is_empty():
		return chosen
	radio.play(conv)
	for guard in 6:
		if not radio.active:
			break
		var opts: Array = radio.current.get("options", [])
		if opts.size() > 0 and radio.awaiting_choice:
			var idx := _sim_pick(opts, policy, n)
			chosen.append(idx)
			radio.choose(idx)
		radio.dismiss()
		await process_frame
	return chosen

func _trust_sim() -> int:
	var out := {}
	var steps_total := 0
	for policy in spec["trust_policies"]:
		state.reset()
		var counter := [0]
		var steps: Array = []
		var offered: Array = []
		var t6 := 0
		for day in range(1, 8):
			director.begin_day(day)
			for step in _sim_script(day):
				if step.has("give"): state.give_item(step["give"])
				if step.has("flag"): state.set_flag(step["flag"])
				if step.has("conv"):
					var cid: String = step["conv"]
					if cid == "evening_d6": t6 = state.trust
					if cid == "evening_d7":
						for o in Conv.get_conv("evening_d7")["options"]:
							offered.append(String(o["set"][0]) if o.has("set") else "?")
					var resolved: Dictionary = Conv.get_conv(cid)
					var chosen: Array = await _sim_say(cid, policy, counter)
					steps.append({"conv": cid, "sig": _conv_sig(resolved), "chosen": chosen, "trust": state.trust, "flags": _flags()})
					steps_total += 1
		var ending := ""
		for k in ["a", "b", "c"]:
			if state.has_flag("ending_" + k): ending = k
		out[policy] = {"steps": steps, "t6": t6, "t7": state.trust, "offered": offered, "ending": ending, "items": state.items.duplicate(),
			"admitted": state.has_flag("clara_admitted"), "partial": state.has_flag("clara_partial"), "stonewalled": state.has_flag("clara_stonewalled")}
	_write("trust_sim", out)
	return steps_total

# ---- log entries -----------------------------------------------------------------------

func _log_entries() -> int:
	var out := {}
	for sc in spec["log_scenarios"]:
		_apply(sc["state"])
		out[sc["name"]] = LogE.compose(int(sc["compose_day"]))
	_write("log_entries", out)
	return out.size()

# ---- save -------------------------------------------------------------------------------

func _save() -> int:
	var save = root.get_node("SaveSystem")
	state.reset()
	director.begin_day(4)
	clock.set_time(4, 777.5)
	state.trust = 5
	for f in ["reported_canister", "heard_tape_1", "clara_shared_father"]:
		state.set_flag(f)
	state.flag_day["heard_tape_1"] = 2
	state.give_item("canister"); state.give_item("tape_1")
	state.discovered["shipwreck"] = true; state.discovered_day["shipwreck"] = 1
	state.discovered["lighthouse"] = true; state.discovered_day["lighthouse"] = 4
	state.reaction_last["r_east_bar_first"] = 596.0
	state.add_log(1, "Glass 30.1 and steady. Fog, then.")
	state.add_log(2, "Quiet day. Nothing new to record.")
	director.phase = 2
	director.rituals = {"stove": true, "weights": true}
	director.weights_wound = true
	director.lamp_lit = true
	director.log_written = false
	director.evening_call_done = false
	director.dusk_nudged = true
	save.path = "user://fx_save.json"
	save.save_game("tower_top")
	var raw = JSON.parse_string(FileAccess.get_file_as_string(save.path))
	save.delete_save()
	var expect := {"location": "tower_top", "day": 4, "minute": 777.5, "trust": 5, "flags": _flags(), "items": state.items.duplicate(), "version": save.VERSION,
		"discovered": state.discovered.keys(), "logbook_count": state.logbook.size(), "phase": director.phase, "rituals": director.rituals.keys(),
		"weights_wound": director.weights_wound, "lamp_lit": director.lamp_lit, "dusk_nudged": director.dusk_nudged}
	_write("save", {"raw": raw, "expect": expect})
	return 1

# ---- endings -----------------------------------------------------------------------------

func _endings() -> int:
	var out := {}
	for k in ["a", "b", "c"]:
		for combo in [["clara_admitted"], ["clara_partial"], []]:
			state.reset()
			for f in combo:
				state.set_flag(f)
			out["%s|%s" % [k, ",".join(PackedStringArray(combo))]] = {"name": End.ending_name(k), "body": End.body(k)}
	_write("endings", out)
	return out.size()
