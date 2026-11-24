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
var sky_rig: SkyRig
var title_cam: Camera3D
var tender: Node3D
var _pro_shot := 0
var _pro_t := 0.0
var _pro_len := 8.0
var _title_t := 0.0
## Title backdrop: dusk on a clear day, lamp lit, beam sweeping. Purely
## visual: the clock, director and save state are never touched.
const TITLE_MINUTE := 978.0
const TITLE_DAY := 5
var rain: CPUParticles3D
var location := "cottage"          # outdoors | cottage | tower_base | tower_top
var started := false
var _busy := false
var _sweeping := false
var _elapsed := 0.0
var _forced_home_done := false

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
	_wire_interactables()
	DayDirector.week_ended.connect(func(): hud.show_card("ONE WEEK ON GANNET ROCK", "End of the current build. Story content arrives in M6.", 6.0))
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
	GameState.reset()
	hud.prologue.apply_to_state()
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
	_set_title_mode(false)
	started = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.refresh_log()

func _autosave() -> void:
	SaveSystem.save_game(location)

# --- locations ----------------------------------------------------------

func _place(loc: String, pos: Vector3, yaw: float) -> void:
	location = loc
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
		if D.evening_call_done:
			GameState.note("Already spoke with Clara tonight.")
		elif not D.lamp_lit or not D.log_written:
			GameState.note("Lamp and log first, then I'll call Clara.")
		else:
			D.start_evening_call()
			RadioSystem.play(Conversations.get_conv(D.data().evening_conv))
	else:
		GameState.note("Nothing to report yet.")

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
	return sky_rig.daylight(GameClock.minute_of_day)

func _build_environment() -> void:
	sky_rig = SkyRig.new()
	sky_rig.name = "SkyRig"
	add_child(sky_rig)

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

# --- frame -----------------------------------------------------------------

func _set_title_mode(on: bool) -> void:
	title_cam.current = on
	player.cam.current = not on
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

func _process(delta: float) -> void:
	_elapsed += delta
	if not started:
		GameClock.paused = true
		if title_cam.current:
			if hud.prologue.visible:
				_update_prologue(delta)
			else:
				tender.visible = false
				_update_title_backdrop(delta)
		return
	GameClock.paused = location != "outdoors"
	_apply_lighting()
	var dd := DayDirector.data()
	ocean.set_wave_height(dd.wave_height)
	AudioDirector.weather_db = dd.wind_db
	AudioDirector.update_ambient(_elapsed, player.global_position.y if location == "outdoors" else 0.0, TideSystem.current_height)
	if Input.is_action_just_pressed("debug_skip") and OS.is_debug_build():
		GameClock.advance(60.0)
	if Input.is_action_just_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_check_day_events()

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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and started and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not hud.modal_open:
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
