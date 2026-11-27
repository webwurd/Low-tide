extends SceneTree
## Dev tool: renders every boxed UI surface over a real in-game frame, at the
## sizes the game ships for (1280x720 and Steam Deck 1280x800), so type size,
## weight, padding and contrast are judged as the player sees them.
##   xvfb-run -a godot --rendering-driver vulkan -s tests/ui_shots.gd -- <outdir> [WxH ...] [filter]
## Defaults to both 1280x720 and 1280x800.

var main: Node3D
var out := "/tmp"
var sizes: Array[Vector2i] = []
var filter := ""
var tag := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	for a in args.slice(1):
		if a.contains("x") and a.split("x").size() == 2 and a.split("x")[0].is_valid_int():
			sizes.append(Vector2i(int(a.split("x")[0]), int(a.split("x")[1])))
		else:
			filter = a
	if sizes.is_empty():
		sizes = [Vector2i(1280, 720), Vector2i(1280, 800)]
	main = load("res://main.tscn").instantiate()
	main.autostart = true
	root.add_child(main)
	await _wait(20)
	for sz in sizes:
		tag = "%dx%d" % [sz.x, sz.y]
		DisplayServer.window_set_size(sz)
		root.size = sz
		await _wait(6)
		await _surfaces()
	quit(0)

func _surfaces() -> void:
	var hud = main.hud
	var clock := root.get_node("GameClock")
	var st := root.get_node("GameState")
	hud._card.modulate.a = 0.0
	# Backdrop: the pier on a clear morning (busy enough to test contrast).
	clock.set_time(5, 600.0)
	main._place("outdoors", main.island.spawn_point, 0.0)
	main.player.locked = true
	main.player.pitch = 0.05
	main.player.cam.rotation.x = 0.05
	clock.paused = true
	await _wait(12)
	await _snap("00_backdrop")

	# Radio: a long line with two replies, then a reply line.
	var convs = load("res://story/conversations.gd")
	var opts := [{"text": "Tell her about the canister and the cable vault"}, {"text": "Say nothing and keep the tapes to yourself for now"}]
	hud._on_line(convs.SPEAKER, "Morning, Arthur. Glass is holding at thirty point one, fog through noon. The east bar opens around ten if you want a look at that wreck.", opts)
	if hud._type_tween: hud._type_tween.kill()
	hud._radio_text.visible_characters = -1
	await _wait(6)
	await _snap("10_radio_line_options")
	hud._on_reply(convs.SPEAKER, "Copy that. Keep the lamp lit.")
	if hud._type_tween: hud._type_tween.kill()
	hud._radio_text.visible_characters = -1
	await _wait(4)
	await _snap("11_radio_reply")
	hud._radio.visible = false
	hud.show_banner()
	await _wait(25)
	await _snap("12_banner")

	# Toast note + interaction prompt.
	hud.show_note("Coffee. Black, strong, a little burnt.")
	await _wait(4)
	await _snap("20_toast")
	hud._note_box.modulate.a = 0.0

	# Day card.
	hud.show_card("Day 5", "Spring Low, clear", 6.0)
	await _wait(30)
	await _snap("30_day_card")
	hud._card.modulate.a = 0.0

	# Tape subtitles.
	hud._tape_title.text = "Tape 1: Walt, January 1976"
	hud._tape_text.text = "I keep telling myself you'd laugh at me, talking to a machine."
	hud._tape_panel.visible = true
	await _wait(4)
	await _snap("40_tape")
	hud._tape_panel.visible = false

	# Journal pages + tide table.
	st.give_item("canister"); st.give_item("tape_1"); st.give_item("uni_logs")
	st.add_log(1, "Glass 30.1 and steady. Fog, then. East stack: old trawler wreck. Canister stamped PROJECT PELAGIC 1974 wedged in the hull.")
	for pg in 3:
		hud._journal_page = pg
		hud._render_journal()
		await _wait(5)
		await _snap("5%d_journal_page_%d" % [pg, pg])
	hud.close_modal()
	hud.show_tide_table(5, root.get_node("TideSystem").extremes_for_day(5))
	await _wait(5)
	await _snap("55_tide_table")
	hud.close_modal()

	# Title screen (fades in over 1.2 s).
	main._set_title_mode(true)
	hud._title.visible = true
	await create_timer(1.6).timeout
	await _wait(4)
	await _snap("58_title")

	# Setup tutorial pages (over the title backdrop).
	main._set_title_mode(true)
	hud._open_tutorial()
	await _wait(10)
	await _snap("60_tutorial_device")
	hud._tut_pick("kb")
	await _wait(5)
	await _snap("61_tutorial_page")
	hud._tut.visible = false
	hud._title.visible = false
	main._set_title_mode(false)

	# Prologue card (fully typed, with choices).
	var pro = hud.prologue
	pro.play()
	pro._shot_left = 0.0
	pro._next()
	if pro._typing: pro._typing.kill()
	pro._show_choices(pro._beats[pro._i])
	await create_timer(1.6).timeout
	await _wait(6)
	await _snap("70_prologue_card")
	pro._finish()
	await _wait(60)
	# Finishing the prologue opens the setup tutorial: put everything back.
	hud._tut.visible = false
	hud._title.visible = false
	main._set_title_mode(false)
	main._place("outdoors", main.island.spawn_point, 0.0)
	main.player.locked = true
	await _wait(6)

	# Pause + settings.
	var menus = main.menus
	menus.open_pause()
	await _wait(6)
	await _snap("80_pause")
	menus._show_only("settings")
	var sm = menus.settings_menu()
	for t in [0, 2]:
		sm.tabs.current_tab = t
		await _wait(5)
		await _snap("8%d_settings_tab_%d" % [t + 1, t])
	menus.resume()
	await _wait(4)

func _snap(name: String) -> void:
	if filter != "" and not name.contains(filter):
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("%s/%s_%s.png" % [out, tag, name])
	print("saved ", tag, " ", name)

func _wait(n: int) -> void:
	for i in n:
		await process_frame
