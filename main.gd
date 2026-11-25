extends Node3D
## Wires the world together and runs the daily loop: locations (outdoors +
## three interiors), rituals, day/night + weather lighting, travel fades,
## forced-home, sleep, autosave.
## Tests set `autostart = true` before adding to the tree to skip the title.


var autostart := false
var player: Player
var island: Island
var interiors: Interiors
var ocean: Ocean
var hud: HUD
var menus: Menus
var sky_rig: SkyRig
var env: Environment                 # = sky_rig.env (kept for tests and tools)
var sun: DirectionalLight3D          # = sky_rig.key_light (sun by day, moon by night)
var rain: GPUParticles3D
var title_cam: Camera3D
var tender: Node3D
var _title_t := 0.0
var _pro_shot := 0
var _pro_t := 0.0
var _pro_len := 8.0
## Title backdrop: dusk on a clear day, lamp lit, beam sweeping. Purely
## visual: the clock, director and save state are never touched.
const TITLE_MINUTE := 978.0
const TITLE_DAY := 5
var location := "cottage"          # outdoors | cottage | tower_base | tower_top
var started := false
var _busy := false
var _sweeping := false
var _elapsed := 0.0
var _forced_home_done := false
var ending_kind := ""
var ending_reload := true          # tests turn this off
var _boat: Node3D
var _boat_target := Vector3.ZERO
var _boat_speed := 2.4
var _boat_arrived := false
var _boat_player: AudioStreamPlayer3D

const ENDINGS := Endings.DATA

func _ready() -> void:
	_build_environment()
	island = Island.new()
	add_child(island)
	island.build()
	interiors = Interiors.new()
	add_child(interiors)
	interiors.build()
	ocean = Ocean.new()
	add_child(ocean)
	player = Player.new()
	add_child(player)
	player.swept.connect(_on_swept)
	_build_rain()
	hud = HUD.new()
	hud.player = player
	add_child(hud)
	hud.new_game_pressed.connect(new_game)
	hud.continue_pressed.connect(continue_game)
	menus = Menus.new()
	add_child(menus)
	hud.settings_requested.connect(menus.open_settings_from_title)
	menus.resumed.connect(_on_resumed)
	menus.title_requested.connect(_return_to_title)
	menus.quit_requested.connect(func(): get_tree().quit())
	_wire_interactables()
	RadioSystem.hidden.connect(_on_radio_hidden)
	RadioSystem.line_shown.connect(func(_sp, _tx, _op): _on_radio_line_for_sting())
	TapePlayer.finished.connect(_on_tape_finished)
	hud.ending_closed.connect(_on_ending_closed)
	DayDirector.week_ended.connect(func(): hud.show_card("One week on Gannet Rock", "The relief boat is due at first light.", 6.0))
	_place("cottage", interiors.spawn["cottage"], 0.0)
	title_cam = Camera3D.new()
	title_cam.name = "TitleCam"
	title_cam.fov = 52.0
	title_cam.far = 900.0
	add_child(title_cam)
	tender = Node3D.new()
	tender.name = "Tender"
	var hull := MeshInstance3D.new()
	hull.mesh = load("res://assets/models/tender.res")
	tender.add_child(hull)
	tender.visible = false
	add_child(tender)
	hud.prologue.shot_requested.connect(func(i, secs):
		_pro_shot = i; _pro_t = 0.0; _pro_len = secs + 2.5)
	_set_title_mode(true)
	if autostart:
		hud.show_title(false)
		new_game()

# --- game start / load --------------------------------------------------

func new_game() -> void:
	TapePlayer.cancel()
	GameState.reset()
	hud.prologue.apply_to_state()
	DayDirector.begin_day(1)
	_forced_home_done = false
	_place("cottage", interiors.spawn["cottage"], 0.0)
	_begin()
	_autosave()
	hud.show_card("Day 1", _day_subtitle(), 3.5)

func continue_game() -> void:
	TapePlayer.cancel()
	var loc := SaveSystem.load_game()
	if loc == "":
		new_game()
		return
	TideSystem.resync()
	_apply_island_lamp()
	var sp: Vector3 = interiors.spawn.get(loc, interiors.spawn["cottage"])
	_place(loc, sp, 0.0)
	_begin()
	hud.show_card("Day %d" % GameClock.day, _day_subtitle(), 3.0)

## "First Watch, fog": title in title case, the weather as ordinary lower-case text.
func _day_subtitle() -> String:
	var dd := DayDirector.data()
	return "%s, %s" % [dd.title, dd.weather.to_lower()]

func _begin() -> void:
	_set_title_mode(false)
	started = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.refresh_log()

func _autosave() -> void:
	SaveSystem.save_game(location)

# --- locations ----------------------------------------------------------

func _place(loc: String, pos: Vector3, yaw: float) -> void:
	location = loc
	GameState.location = loc
	GameState.zone = loc
	var indoor := loc != "outdoors"
	player.indoors = indoor
	player.teleport(pos, yaw)
	AudioDirector.indoors = indoor
	if not indoor:
		_forced_home_done = false if GameClock.minute_of_day < DayDirector.FORCED_HOME_MINUTE else _forced_home_done

## Fade out, move, fade in. Await-able.
func travel(loc: String, pos: Vector3, yaw := 0.0) -> void:
	if _busy:
		return
	_busy = true
	player.locked = true
	AudioDirector.play_transition(location, loc)
	hud.fade_out(0.35)
	await get_tree().create_timer(0.45).timeout
	_place(loc, pos, yaw)
	hud.fade_in(0.45)
	await get_tree().create_timer(0.35).timeout
	player.locked = false
	_busy = false

# --- interactables -------------------------------------------------------

func _wire_interactables() -> void:
	var i := interiors.its
	# outdoors doors
	island.cottage_door.used.connect(func(): travel("cottage", interiors.spawn["cottage"], 0.0))
	island.tower_door.used.connect(func(): travel("tower_base", interiors.spawn["tower_base"], 0.0))
	# cottage
	i["door_cottage_out"].title_fn = func():
		if DayDirector.phase == DayDirector.Phase.MORNING and not DayDirector.morning_complete():
			return "Step outside  (morning: %d/5)" % DayDirector.ritual_count()
		return "Step outside"
	i["door_cottage_out"].used.connect(_on_cottage_exit)
	i["stove"].used.connect(_on_stove)
	i["barometer"].used.connect(_on_barometer)
	i["tide_table"].used.connect(_on_tide_table)
	i["radio_desk"].title_fn = func():
		return "Evening call with Clara" if DayDirector.phase == DayDirector.Phase.EVENING else "Radio check-in with Clara"
	i["radio_desk"].used.connect(_on_radio_desk)
	i["log_desk"].used.connect(_on_log_desk)
	i["chair_cottage"].used.connect(_wait_hour)
	i["bed"].used.connect(_on_bed)
	i["cassette_player"].title_fn = func():
		var id := _next_tape()
		if id == "":
			return "Cassette player (no tapes)"
		return ("Play: " if not TapePlayer.is_heard(id) else "Replay: ") + Items.title(id)
	i["cassette_player"].used.connect(_on_cassette)
	# tower
	i["weights"].used.connect(_on_weights)
	i["stairs_up"].used.connect(func(): travel("tower_top", interiors.spawn["tower_top"], 0.0))
	i["door_tower_out"].used.connect(func(): travel("outdoors", island.tower_exit(), 0.0))
	i["stairs_down"].used.connect(func(): travel("tower_base", interiors.spawn["from_above"], PI))
	i["lamp"].used.connect(_on_lamp)
	i["bench"].used.connect(_wait_hour)

func _on_cottage_exit() -> void:
	if DayDirector.phase == DayDirector.Phase.MORNING and not DayDirector.morning_complete():
		GameState.note("Morning first: stove, glass, tide table, the weights, then Clara.")
		return
	DayDirector.step_outside()
	travel("outdoors", island.cottage_exit(), Terrain.COTTAGE_YAW + PI)

func _on_stove() -> void:
	if not DayDirector.rituals.has("stove"):
		AudioDirector.play_sfx("stove", -5.0)
	DayDirector.complete_ritual("stove")
	GameState.note("Coffee. Black, strong, a little burnt.")

func _on_barometer() -> void:
	AudioDirector.play_sfx("tap", -8.0)
	DayDirector.complete_ritual("barometer")
	GameState.note(DayDirector.data().barometer)

func _on_tide_table() -> void:
	AudioDirector.play_sfx("page", -6.0)
	DayDirector.complete_ritual("tide_table")
	hud.show_tide_table(GameClock.day, TideSystem.extremes_for_day(GameClock.day))

func _on_weights() -> void:
	if DayDirector.weights_wound:
		GameState.note("The weights are already wound for today.")
		return
	AudioDirector.play_sfx("winding", -5.0)
	DayDirector.complete_ritual("weights")
	_apply_island_lamp()
	GameState.note("Weights wound. The lens will turn all night.")

## Clara's first check-in mentions the binoculars; from then on Arthur can raise them.
func _unlock_binoculars() -> void:
	if GameState.has_flag("binoculars_ready"):
		return
	GameState.set_flag("binoculars_ready")
	GameState.note("Binoculars ready: hold %s (or %s on a gamepad)." % [Settings.binding_text("binoculars", Settings.KB), Settings.binding_text("binoculars", Settings.PAD)])

func _on_radio_desk() -> void:
	var D := DayDirector
	if D.phase == D.Phase.MORNING:
		if D.rituals.has("checkin"):
			GameState.note("Already checked in this morning.")
		elif not D.can_check_in():
			GameState.note("Clara can wait a minute. Stove, glass, tide table, weights first.")
		else:
			D.complete_ritual("checkin")
			RadioSystem.play(Conversations.get_conv(D.data().morning_conv))
			_unlock_binoculars()
	elif D.phase == D.Phase.EVENING:
		if D.evening_call_done and not D.final_pending():
			GameState.note("Already spoke with Clara tonight.")
		elif not D.lamp_lit or not D.log_written:
			GameState.note("Lamp and log first, then I'll call Clara.")
		else:
			D.start_evening_call()
			RadioSystem.play(Conversations.get_conv(D.data().evening_conv))
	else:
		GameState.note("Nothing to report yet.")

## Lowest-numbered unheard tape in the satchel (story order, not pickup order);
## if all are heard, the highest-numbered one for replay; "" if none.
func _next_tape() -> String:
	var ids: Array = []
	for id in GameState.items:
		if String(id).begins_with("tape_"):
			ids.append(String(id))
	if ids.is_empty():
		return ""
	ids.sort()
	for id in ids:
		if not TapePlayer.is_heard(id):
			return id
	return ids[ids.size() - 1]

func _on_cassette() -> void:
	var id := _next_tape()
	if id == "":
		GameState.note("No tapes in the satchel yet.")
	elif TapePlayer.playing:
		GameState.note("The tape is already playing.")
	else:
		TapePlayer.play(id)

func _on_log_desk() -> void:
	if DayDirector.phase != DayDirector.Phase.EVENING:
		GameState.note("Nothing to write up until the day's done.")
	elif DayDirector.log_written:
		GameState.note("Log's written. Open it any time with Tab.")
	else:
		AudioDirector.play_sfx("pen", -6.0)
		DayDirector.write_log()
		hud.refresh_log()
		GameState.note("Wrote up the day's entry.")

func _on_lamp() -> void:
	var D := DayDirector
	if D.lamp_lit:
		GameState.note("The lamp is lit.")
	elif not D.lamp_ready():
		GameState.note("Too early to light the lamp.")
	else:
		AudioDirector.play_sfx("lamp", -5.0)
		D.light_lamp()
		_apply_island_lamp()
		interiors.set_lamp(true)
		GameState.note("Lamp lit. The beam sweeps out over the water.")

func _wait_hour() -> void:
	if _busy:
		return
	if GameClock.minute_of_day >= 1320.0:
		GameState.note("Too tired to sit up any longer. Bed.")
		return
	_busy = true
	player.locked = true
	AudioDirector.play_sfx("chair", -6.0)
	hud.fade_out(0.4)
	await get_tree().create_timer(0.55).timeout
	GameClock.advance(60.0)
	TideSystem.refresh()
	_autosave()
	hud.fade_in(0.5)
	await get_tree().create_timer(0.4).timeout
	player.locked = false
	_busy = false
	GameState.note("An hour passes. %s." % GameClock.hhmm())

func _on_bed() -> void:
	if _busy:
		return
	if not DayDirector.can_sleep():
		GameState.note(DayDirector.sleep_blockers())
		return
	_busy = true
	player.locked = true
	AudioDirector.play_sfx("bed", -6.0)
	hud.fade_out(1.0)
	await get_tree().create_timer(1.3).timeout
	if DayDirector.sleep():
		_forced_home_done = false
		_apply_island_lamp()
		interiors.set_lamp(false)
		_place("cottage", interiors.spawn["bed"], 0.0)
		_autosave()
		hud.fade_in(1.2)
		hud.show_card("Day %d" % GameClock.day, _day_subtitle(), 3.5)
	else:
		hud.show_card("One week on Gannet Rock", "The relief boat is due at first light.", 6.0)
	await get_tree().create_timer(0.8).timeout
	player.locked = false
	_busy = false

func _apply_island_lamp() -> void:
	island.set_lamp(DayDirector.lamp_lit, DayDirector.weights_wound, _daylight())
	interiors.set_lamp(DayDirector.lamp_lit)

# --- lighting / weather ---------------------------------------------------

func _daylight() -> float:
	return sky_rig.daylight(GameClock.minute_of_day)

func _build_environment() -> void:
	sky_rig = SkyRig.new()
	sky_rig.name = "SkyRig"
	add_child(sky_rig)
	env = sky_rig.env
	sun = sky_rig.key_light

## Rain: velocity-aligned streaks (GPU), plus a soft film layer under the HUD.
func _build_rain() -> void:
	rain = GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 2800 if SkyRig.tier() >= 1 else 1200
	rain.lifetime = 0.9
	rain.visibility_aabb = AABB(Vector3(-16, -24, -16), Vector3(32, 30, 32))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(15, 0.5, 15)
	pm.direction = Vector3(0.22, -1, 0.05)
	pm.spread = 4.0
	pm.initial_velocity_min = 22.0
	pm.initial_velocity_max = 28.0
	pm.gravity = Vector3.ZERO
	pm.particle_flag_align_y = true
	pm.scale_min = 0.7
	pm.scale_max = 1.2
	rain.process_material = pm
	var streak := QuadMesh.new()
	streak.size = Vector2(0.018, 0.75)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.8, 0.86, 0.92, 0.32)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.roughness = 0.2
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	streak.material = m
	rain.draw_pass_1 = streak
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rain.emitting = false
	add_child(rain)
	var film := CanvasLayer.new()
	film.name = "Film"
	film.layer = 5
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fm := ShaderMaterial.new()
	fm.shader = load("res://ui/post.gdshader")
	rect.material = fm
	film.add_child(rect)
	add_child(film)

func _apply_lighting() -> void:
	var dd := DayDirector.data()
	var outdoors := location == "outdoors"
	sky_rig.apply(outdoors, GameClock.minute_of_day, dd)
	if not outdoors:
		rain.emitting = false
		var o := sky_rig.outside_colors(GameClock.minute_of_day, dd)
		interiors.set_outside(_daylight() * dd.light_scale, o[0], o[1], o[2])
		return
	island.set_lamp(DayDirector.lamp_lit, DayDirector.weights_wound, _daylight())
	rain.emitting = dd.rain
	rain.global_position = player.global_position + Vector3(0, 14, 0)

# --- title backdrop + prologue crossing ------------------------------------

func _set_title_mode(on: bool) -> void:
	title_cam.current = on
	player.cam.current = not on
	# Nothing the player does before the game starts (keys, mouse, a stray controller)
	# may turn or move Arthur behind the title, tutorial and prologue.
	player.locked = on
	tender.visible = false
	if not on:
		_apply_island_lamp()

## Slow drift from the south-west shore towards the light, then back.
func _update_title_backdrop(delta: float) -> void:
	_title_t += delta
	var a := sin(_title_t * 0.035) * 0.5 + 0.5
	var pos := Vector3(-30.0, 3.4, 34.0).lerp(Vector3(-18.0, 4.2, 40.0), a)
	title_cam.global_position = pos + Vector3(0, sin(_title_t * 0.21) * 0.15, 0)
	title_cam.look_at(Vector3(-4.0, 13.5, -4.0).lerp(Vector3(0.0, 14.5, -6.0), a), Vector3.UP)
	var dd := Days.get_day(TITLE_DAY)
	sky_rig.apply(true, TITLE_MINUTE, dd)
	ocean.set_wave_height(dd.wave_height)
	island.set_lamp(true, true, sky_rig.daylight(TITLE_MINUTE))
	rain.emitting = false

## Prologue crossing: ride the tender through the dawn fog towards the light.
func _update_prologue(delta: float) -> void:
	_pro_t += delta
	tender.visible = true
	var path := Prologue.shot_path(_pro_shot)
	var f := clampf(_pro_t / _pro_len, 0.0, 1.0)
	var pos: Vector3 = (path[0] as Vector3).lerp(path[1], f)
	var fwd: Vector3 = ((path[1] as Vector3) - (path[0] as Vector3)).normalized()
	var bob := sin(_elapsed * 0.9) * 0.12
	tender.global_position = pos + Vector3(0, TideSystem.current_height - 0.35 + bob, 0)
	tender.look_at(tender.global_position + fwd, Vector3.UP)
	tender.rotate_object_local(Vector3.FORWARD, sin(_elapsed * 0.7) * 0.035)
	tender.rotate_object_local(Vector3.RIGHT, sin(_elapsed * 0.9 + 0.6) * 0.02)
	title_cam.global_position = tender.global_transform * Vector3(0.35, 2.45, 1.0)
	var look: Vector3 = (tender.global_position + fwd * 60.0 + Vector3(0, 2.0, 0)).lerp(path[2], 0.35 + 0.4 * f)
	title_cam.look_at(look, Vector3.UP)
	var minute := 402.0 + _pro_shot * 6.0 + f * 5.0
	var dd := Days.get_day(1)
	sky_rig.apply(true, minute, dd)
	ocean.set_wave_height(0.22)
	island.set_lamp(true, true, sky_rig.daylight(minute))
	rain.emitting = false

# --- frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	_elapsed += delta
	if not started:
		GameClock.paused = true
		AudioDirector.raining = false          # the title screen is quiet
		AudioDirector.stove_lit = false
		AudioDirector.set_radio_static(false)
		if title_cam.current:
			if hud.prologue.visible:
				_update_prologue(delta)
			else:
				tender.visible = false
				_update_title_backdrop(delta)
		return
	GameClock.paused = location != "outdoors" or ending_kind != ""
	if location == "outdoors":
		var pp := player.global_position
		GameState.zone = Terrain.zone_at(pp.x, pp.z, pp.y)
	_apply_lighting()
	var dd := DayDirector.data()
	ocean.set_wave_height(dd.wave_height)
	AudioDirector.weather_db = dd.wind_db
	AudioDirector.raining = dd.rain
	AudioDirector.stove_lit = DayDirector.rituals.has("stove")
	AudioDirector.in_cottage = location == "cottage"
	AudioDirector.set_radio_static(RadioSystem.active)
	AudioDirector.update_ambient(_elapsed, player.global_position.y if location == "outdoors" else 0.0, TideSystem.current_height)
	if OS.is_debug_build() and Input.is_action_just_pressed("debug_skip"):
		GameClock.advance(60.0)
	_check_day_events()
	_update_ending_scene(delta)

func _check_day_events() -> void:
	if location != "outdoors" or _busy:
		return
	var m := GameClock.minute_of_day
	if m >= DayDirector.DUSK_MINUTE and not DayDirector.dusk_nudged:
		DayDirector.dusk_nudged = true
		RadioSystem.play(Conversations.get_conv("dusk_nudge"))
	if m >= DayDirector.FORCED_HOME_MINUTE and not _forced_home_done:
		_forced_home_done = true
		DayDirector.force_evening()
		RadioSystem.play(Conversations.get_conv("forced_home"))
		travel("cottage", interiors.spawn["cottage"], 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if hud.modal_open:
		hud.close_modal()
	elif menus.is_open():
		menus.back()
	elif started and ending_kind == "" and not _busy:
		open_pause()

func open_pause() -> void:
	if not started or menus.is_open():
		return
	menus.open_pause()

func _on_resumed() -> void:
	if started and not hud.modal_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _return_to_title() -> void:
	TapePlayer.cancel()
	# Leaving mid-expedition means heading home: Continue always resumes indoors.
	SaveSystem.save_game(location if location != "outdoors" else "cottage")
	GameState.reset()
	DayDirector.begin_day(1)
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and started and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not hud.modal_open and not menus.is_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Swept by the tide: fade, return to the pier, lose 45 minutes, Clara reacts.
func _on_swept() -> void:
	if _sweeping:
		return
	_sweeping = true
	player.locked = true
	hud.fade_out(0.7)
	await get_tree().create_timer(2.2).timeout
	player.teleport(island.spawn_point, 0.0)
	GameClock.advance(45.0)
	TideSystem.refresh()
	hud.fade_in(0.9)
	player.locked = false
	_sweeping = false
	RadioSystem.play(Conversations.get_conv("swept"))

# --- endings -----------------------------------------------------------------

## Music is rare: only turning points get a sting (once each per run).
const CONVERSATION_STINGS := {"evening_d6": "sting_confront"}
const TAPE_STINGS := {"tape_2": "sting_june", "tape_4": "sting_walt"}

func _on_radio_line_for_sting() -> void:
	var id: String = RadioSystem.current.get("id", "")
	if CONVERSATION_STINGS.has(id) and not GameState.has_flag("sting_" + id):
		GameState.set_flag("sting_" + id)
		AudioDirector.play_sting(CONVERSATION_STINGS[id])

func _on_tape_finished(id: String) -> void:
	if TAPE_STINGS.has(id) and not GameState.has_flag("sting_" + id):
		GameState.set_flag("sting_" + id)
		AudioDirector.play_sting(TAPE_STINGS[id])

func _on_radio_hidden() -> void:
	if ending_kind != "":
		return
	for k in ["a", "b", "c"]:
		if GameState.has_flag("ending_" + k):
			start_ending(k)
			return

## Dawn on the pier. A and B end on the relief boat's light seen through the
## binoculars; C ends on the sweeping beam and static.
func start_ending(kind: String) -> void:
	if ending_kind != "":
		return
	ending_kind = kind
	GameState.ending = kind
	_busy = true
	player.locked = true
	if kind == "b":
		GameState.set_flag("buoy_off")
	hud.fade_out(1.6)
	await get_tree().create_timer(2.0).timeout
	GameClock.set_time(7, 410.0)                       # first light
	TideSystem.refresh()
	_place("outdoors", Vector3(0.0, Terrain.PIER_TOP + 0.05, 31.0), PI)
	player.binoculars = false
	hud.fade_in(1.8)
	await get_tree().create_timer(3.5).timeout
	RadioSystem.play(Conversations.get_conv("ending_%s_radio" % kind))
	if kind == "c":
		await get_tree().create_timer(6.0).timeout
	else:
		_spawn_boat()
		player.binoculars = true
		while not _boat_arrived:
			await get_tree().process_frame
		await get_tree().create_timer(2.0).timeout
	_show_ending_card(kind)

func _spawn_boat() -> void:
	_boat = Node3D.new()
	_boat.position = Vector3(62.0, 0.3, 150.0)
	_boat_target = Vector3(6.0, 0.3, 58.0)
	add_child(_boat)
	var hull := MeshInstance3D.new()
	var hb := BoxMesh.new(); hb.size = Vector3(2.6, 1.0, 7.0)
	hull.mesh = hb
	var hm := StandardMaterial3D.new(); hm.albedo_color = Color("2a3138")
	hull.material_override = hm
	_boat.add_child(hull)
	var cabin := MeshInstance3D.new()
	var cb := BoxMesh.new(); cb.size = Vector3(1.8, 1.2, 2.2)
	cabin.mesh = cb
	cabin.material_override = hm
	cabin.position = Vector3(0, 1.0, 0.6)
	_boat.add_child(cabin)
	var lamp := MeshInstance3D.new()          # white masthead light, visible through fog
	var sph := SphereMesh.new(); sph.radius = 0.35; sph.height = 0.7
	lamp.mesh = sph
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1.0, 0.97, 0.85)
	lm.disable_fog = true
	lamp.material_override = lm
	lamp.position = Vector3(0, 2.4, 0.4)
	_boat.add_child(lamp)
	var omni := OmniLight3D.new()
	omni.light_color = Color(1.0, 0.95, 0.8)
	omni.light_energy = 3.0
	omni.omni_range = 30.0
	omni.position = lamp.position
	_boat.add_child(omni)
	_boat_player = AudioStreamPlayer3D.new()
	_boat_player.bus = "Ambience"
	_boat_player.stream = AudioDirector.boat_engine_stream()
	_boat_player.unit_size = 20.0
	_boat_player.max_distance = 300.0
	_boat_player.volume_db = -4.0
	_boat.add_child(_boat_player)
	_boat_player.play()
	_boat.look_at(_boat_target + Vector3(0, 0, 0))
	_boat.rotate_y(PI)         # bow (local -z in look_at) forward
	_boat.set_meta("label", "Relief boat, first light")
	_boat.add_to_group("bino_target")
	_boat_arrived = false

func _update_ending_scene(delta: float) -> void:
	if ending_kind == "":
		return
	if ending_kind == "c":
		# Look up at the beam from the pier.
		player.yaw = lerp_angle(player.yaw, 0.0, minf(1.0, delta * 1.5))
		player.pitch = lerpf(player.pitch, 0.45, minf(1.0, delta * 1.5))
	elif _boat != null:
		var to := _boat_target - _boat.position
		to.y = 0.0                              # the boat rides the water; judge arrival in the plane
		if to.length() > 1.0:
			_boat.position += to.normalized() * _boat_speed * delta
		else:
			_boat_arrived = true
		_boat.position.y = TideSystem.current_height + 0.25 + sin(Time.get_ticks_msec() * 0.0015) * 0.1
		var eye := player.global_position + Vector3(0, Player.EYE, 0)
		var dir := (_boat.global_position + Vector3(0, 2.4, 0) - eye)
		var want_yaw := atan2(-dir.x, -dir.z)
		var want_pitch := asin(clampf(dir.y / maxf(dir.length(), 0.001), -1.0, 1.0))
		player.yaw = lerp_angle(player.yaw, want_yaw, minf(1.0, delta * 2.0))
		player.pitch = lerpf(player.pitch, want_pitch, minf(1.0, delta * 2.0))
		player.bino_label = "Relief boat, first light"
		player.bino_dist = int(dir.length())
	player.rotation.y = player.yaw
	player.cam.rotation.x = player.pitch
	var want_fov := Player.FOV_BINO if player.binoculars else Player.FOV_NORMAL
	player.cam.fov = lerpf(player.cam.fov, want_fov, minf(1.0, delta * 3.0))

func _ending_body(kind: String) -> String:
	return Endings.body(kind)

func _show_ending_card(kind: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SaveSystem.record_ending(kind)
	SaveSystem.delete_save()
	AudioDirector.play_sting("sting_end_" + kind)
	hud.show_ending(kind, ENDINGS[kind]["name"], _ending_body(kind))

func _on_ending_closed() -> void:
	RadioSystem.dismiss()
	GameState.reset()
	DayDirector.begin_day(1)
	if ending_reload:
		get_tree().reload_current_scene()
