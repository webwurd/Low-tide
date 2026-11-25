extends SceneTree
## Dev tool: renders every HandPose on both hands, close up, for a contact sheet.
##   xvfb-run -a godot --rendering-driver vulkan -s tests/hand_sheet.gd -- <outdir> [stage] [views] [poses]
##     stage: studio (fast: a warm lamp key, violet fill, dark room) or
##            cottage (the game's cottage interior and its lighting; slow)
##     views: comma list of back,palm,side (default back,palm)
##     poses: comma list (default every HandPose.NAMES)
## Writes <outdir>/<pose>_<view>.png at 640x400; tile them with ImageMagick:
##   montage <outdir>/*_back.png ... -tile 4x -geometry +2+2 sheet.png

var out := "/tmp/hands"
var stage := "studio"
var views := ["back", "palm"]
var poses: Array = []
var cam: Camera3D
var hands: Array[HandRig] = []
var pivot: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	if args.size() > 1: stage = args[1]
	if args.size() > 2: views = Array(args[2].split(","))
	poses = Array(HandPose.NAMES) if args.size() < 4 else Array(args[3].split(","))
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(640, 400)
	var world := Node3D.new()
	root.add_child(world)
	if stage == "cottage":
		await _cottage(world)
	else:
		_studio(world)
	pivot = Node3D.new()
	world.add_child(pivot)
	for s in [-1.0, 1.0]:
		var h := HandRig.new(s)
		pivot.add_child(h)
		hands.append(h)
	for p in poses:
		for v in views:
			_place(StringName(p), v)
			for i in (3 if stage == "studio" else 6):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%s.png" % [out, p, v])
			print("  shot ", p, " ", v)
	quit(0)

## Hands in front of the camera. back: palms down, seen from above and behind
## (the player's view); palm: palms up; side: from the thumb side.
func _place(p: StringName, view: String) -> void:
	for h in hands:
		h.set_pose(p)
		var s := h.side
		var t := Transform3D()
		match view:
			"back":
				t.basis = Basis(Vector3.BACK, PI) * Basis(Vector3.RIGHT, -0.15)
				t.origin = Vector3(0.115 * s, 0.0, 0.0)
			"palm":
				t.basis = Basis(Vector3.RIGHT, 0.5)
				t.origin = Vector3(0.115 * s, 0.0, 0.0)
			"side":
				# Profile: fingers point right, the flexion axis looks at the camera.
				# Right hand (thumb toward the camera) above, left hand below.
				t.basis = Basis(Vector3.UP, -PI * 0.5) * Basis(Vector3.BACK, 0.25)
				t.origin = Vector3(0.0, 0.085 if s > 0.0 else -0.095, 0.0)
			"close", "closeup":
				# One hand at 0.3 m, three-quarter view of the back and thumb side
				# ("close" = right hand, "closeup" = left hand palm side).
				if view == "close":
					t.basis = Basis(Vector3.UP, 0.5) * Basis(Vector3.BACK, PI * 0.72)
				else:
					t.basis = Basis(Vector3.UP, -0.4) * Basis(Vector3.BACK, -0.55) * Basis(Vector3.RIGHT, 0.35)
				t.origin = Vector3(0.0, 0.0, 0.0)
		h.visible = not ((view == "close" and s < 0.0) or (view == "closeup" and s > 0.0))
		h.transform = t.scaled_local(Vector3.ONE * 1.5)
	# The camera sits where the view wants it relative to the hands; in the
	# cottage the camera is Arthur's, so the hands move instead.
	var tc := _view_cam(view)
	if stage == "studio":
		cam.transform = tc
	else:
		pivot.global_transform = cam.global_transform * tc.affine_inverse()

func _view_cam(view: String) -> Transform3D:
	var eye := Vector3(0.0, 0.30, 0.42)
	var at := Vector3(0.0, -0.01, -0.07)
	if view == "close" or view == "closeup":
		eye = Vector3(0.0, 0.17, 0.30); at = Vector3(0.0, -0.01, -0.09)
	elif view == "side":
		eye = Vector3(0.02, 0.05, 0.55); at = Vector3(0.02, -0.005, 0.0)
	return Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)

func _studio(world: Node3D) -> void:
	RenderingServer.global_shader_parameter_set("shadow_tint", Color("3c3a5c"))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1d1b22")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("5a5878")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()     # warm lamp / low winter sun from the left
	key.light_color = Color("ffc88a")
	key.light_energy = 2.0
	key.rotation = Vector3(-0.75, -0.9, 0.0)
	key.shadow_enabled = true
	world.add_child(key)
	var fill := OmniLight3D.new()            # cool window bounce from the right
	fill.light_color = Color("8fa7c8")
	fill.light_energy = 0.6
	fill.omni_range = 3.0
	fill.position = Vector3(0.8, 0.2, 0.5)
	world.add_child(fill)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.near = 0.02
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 0.30, 0.42), Vector3(0.0, -0.01, -0.07))

## The game's cottage, as tests/anim_clip.gd stages it: the hands float in front of
## Arthur's eye at the window side of the room.
func _cottage(_world: Node3D) -> void:
	var main: Node3D = load("res://main.tscn").instantiate()
	main.autostart = true
	root.add_child(main)
	for i in 12:
		await process_frame
	main.hud.hide()
	main.player.locked = true
	root.get_node("GameClock").paused = true
	var spawn: Vector3 = main.interiors.spawn["cottage"]
	main.player.position = Vector3(spawn.x - 1.0, 0.05, 0.4)
	main.player.rotation.y = 0.6
	cam = main.player.cam
	cam.rotation.x = -0.1
	cam.near = 0.02
	for i in 4:
		await process_frame
