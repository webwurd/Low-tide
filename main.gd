extends Node3D
## Wires the world together: environment, island, ocean, player, HUD.
## Tests set `autostart = true` before adding to the tree to skip the title.

const FOG := Color("526373")

var autostart := false
var player: Player
var island: Island
var hud: HUD
var started := false
var _sweeping := false
var _elapsed := 0.0

func _ready() -> void:
	_build_environment()
	island = Island.new()
	add_child(island)
	island.build()
	add_child(Ocean.new())
	player = Player.new()
	add_child(player)
	player.teleport(island.spawn_point, 0.0)
	player.swept.connect(_on_swept)
	hud = HUD.new()
	hud.player = player
	add_child(hud)
	hud.start_pressed.connect(start_game)
	if autostart:
		hud.show_title(false)
		start_game()

func start_game() -> void:
	if started:
		return
	started = true
	GameClock.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().create_timer(0.9).timeout.connect(func():
		RadioSystem.play(Conversations.get_conv("opening")))

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9fb4c7")
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_light_color = FOG
	env.fog_density = 0.011
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("dce6f0")
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	sun.position = Vector3(-45, 75, 35)
	add_child(sun)
	sun.look_at(Vector3.ZERO)

func _process(delta: float) -> void:
	_elapsed += delta
	if not started:
		return
	AudioDirector.update_ambient(_elapsed, player.global_position.y, TideSystem.current_height)
	if Input.is_action_just_pressed("debug_skip") and OS.is_debug_build():
		GameClock.advance(60.0)
		AudioDirector.play_sfx("squelch")
	if Input.is_action_just_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and started and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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
