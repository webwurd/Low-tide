extends Node3D
## Wires the world together and runs the daily loop: locations (outdoors +
## three interiors), rituals, day/night + weather lighting, travel fades,
## forced-home, sleep, autosave.
## Tests set `autostart = true` before adding to the tree to skip the title.

const NIGHT_FOG := Color("0d1520")
const INDOOR_AMBIENT := Color("6a5846")

var autostart := false
var player: Player
var island: Island
var interiors: Interiors
var ocean: Ocean
var hud: HUD
var menus: Menus
var env: Environment
var sun: DirectionalLight3D
var rain: CPUParticles3D
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
	DayDirector.week_ended.connect(func(): hud.show_card("ONE WEEK ON GANNET ROCK", "End of the current build. Story content arrives in M6.", 6.0))
	_place("cottage", interiors.spawn["cottage"], 0.0)
	if autostart:
		hud.show_title(false)
		new_game()

# --- game start / load --------------------------------------------------

func new_game() -> void:
	GameState.reset()
	DayDirector.begin_day(1)
	_forced_home_done = false
	_place("cottage", interiors.spawn["cottage"], 0.0)
	_begin()
	_autosave()
	hud.show_card("DAY 1", DayDirector.data().title + "  -  " + DayDirector.data().weather, 3.5)

func continue_game() -> void:
	var loc := SaveSystem.load_game()
	if loc == "":
		new_game()
		return
	_apply_island_lamp()
	var sp: Vector3 = interiors.spawn.get(loc, interiors.spawn["cottage"])
	_place(loc, sp, 0.0)
	_begin()
	hud.show_card("DAY %d" % GameClock.day, DayDirector.data().title + "  -  " + DayDirector.data().weather, 3.0)

func _begin() -> void:
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
	DayDirector.complete_ritual("stove")
	GameState.note("Coffee. Black, strong, a little burnt.")

func _on_barometer() -> void:
	DayDirector.complete_ritual("barometer")
	GameState.note(DayDirector.data().barometer)

func _on_tide_table() -> void:
	DayDirector.complete_ritual("tide_table")
	hud.show_tide_table(GameClock.day, TideSystem.extremes_for_day(GameClock.day))

func _on_weights() -> void:
	if DayDirector.weights_wound:
		GameState.note("The weights are already wound for today.")
		return
	DayDirector.complete_ritual("weights")
	_apply_island_lamp()
	GameState.note("Weights wound. The lens will turn all night.")

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
	hud.fade_out(1.0)
	await get_tree().create_timer(1.3).timeout
	if DayDirector.sleep():
		_forced_home_done = false
		_apply_island_lamp()
		interiors.set_lamp(false)
		_place("cottage", interiors.spawn["bed"], 0.0)
		_autosave()
		hud.fade_in(1.2)
		hud.show_card("DAY %d" % GameClock.day, DayDirector.data().title + "  -  " + DayDirector.data().weather, 3.5)
	else:
		hud.show_card("ONE WEEK ON GANNET ROCK", "End of the current build. Story content arrives in M6.", 6.0)
	await get_tree().create_timer(0.8).timeout
	player.locked = false
	_busy = false

func _apply_island_lamp() -> void:
	island.set_lamp(DayDirector.lamp_lit, DayDirector.weights_wound, _daylight())
	interiors.set_lamp(DayDirector.lamp_lit)

# --- lighting / weather ---------------------------------------------------

func _daylight() -> float:
	var m := GameClock.minute_of_day
	return smoothstep(390.0, 450.0, m) * (1.0 - smoothstep(945.0, 1020.0, m))

func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	sun.position = Vector3(-45, 75, 35)
	add_child(sun)
	sun.look_at(Vector3.ZERO)

## Brightness / exposure / bloom from the Lighting settings.
func _apply_display_settings() -> void:
	env.adjustment_enabled = true
	env.adjustment_brightness = float(Settings.v("brightness"))
	env.tonemap_exposure = 0.95 * float(Settings.v("exposure"))
	env.glow_enabled = bool(Settings.v("glow"))

func _build_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 900
	rain.lifetime = 0.8
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(22, 0.5, 22)
	rain.direction = Vector3(0.15, -1, 0)
	rain.spread = 3.0
	rain.initial_velocity_min = 22.0
	rain.initial_velocity_max = 26.0
	rain.gravity = Vector3.ZERO
	var bm := BoxMesh.new()
	bm.size = Vector3(0.015, 0.45, 0.015)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.75, 0.82, 0.9, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.material = m
	rain.mesh = bm
	rain.emitting = false
	add_child(rain)

func _apply_lighting() -> void:
	_apply_display_settings()
	var dd := DayDirector.data()
	var outdoors := location == "outdoors"
	if not outdoors:
		env.fog_enabled = false
		env.background_color = Color.BLACK
		env.ambient_light_color = INDOOR_AMBIENT
		env.ambient_light_energy = 0.8
		sun.visible = false
		rain.emitting = false
		return
	var d := clampf(_daylight() * dd.light_scale, 0.0, 1.0)
	var fog_col := NIGHT_FOG.lerp(dd.fog_tint, d)
	env.fog_enabled = true
	env.fog_density = dd.fog_density * lerpf(1.5, 1.0, smoothstep(390.0, 660.0, GameClock.minute_of_day)) * float(Settings.v("fog_scale"))   # morning mist burns off
	env.fog_light_color = fog_col
	env.background_color = fog_col
	env.ambient_light_color = Color("6f84a6").lerp(Color("9fb4c7"), d)
	env.ambient_light_energy = lerpf(0.3, 0.4, d) + float(Settings.v("night_assist")) * (1.0 - d) * 0.45
	sun.visible = true
	sun.light_color = Color("5f78a8").lerp(Color("dce6f0"), d)
	sun.light_energy = lerpf(0.14, 0.6, d)
	sun.shadow_enabled = d > 0.15 and Settings.shadow_distance() > 0.0
	sun.directional_shadow_max_distance = maxf(Settings.shadow_distance(), 1.0)
	island.set_lamp(DayDirector.lamp_lit, DayDirector.weights_wound, _daylight())
	rain.emitting = dd.rain
	rain.global_position = player.global_position + Vector3(0, 14, 0)

# --- frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	_elapsed += delta
	if not started:
		GameClock.paused = true
		return
	GameClock.paused = location != "outdoors" or ending_kind != ""
	if location == "outdoors":
		var pp := player.global_position
		GameState.zone = Terrain.zone_at(pp.x, pp.z, pp.y)
	_apply_lighting()
	var dd := DayDirector.data()
	ocean.set_wave_height(dd.wave_height)
	AudioDirector.weather_db = dd.wind_db
	AudioDirector.update_ambient(_elapsed, player.global_position.y if location == "outdoors" else 0.0, TideSystem.current_height)
	if Input.is_action_just_pressed("debug_skip") and OS.is_debug_build():
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
	_boat.set_meta("label", "RELIEF BOAT // FIRST LIGHT")
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
		player.bino_label = "RELIEF BOAT // FIRST LIGHT"
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
