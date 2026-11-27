extends SceneTree
## Dev tool: renders the animation prototype clip to PNG frames (needs xvfb).
##   xvfb-run -a godot --rendering-method gl_compatibility -s tests/anim_clip.gd -- <outdir> [fps]
## Then: ffmpeg -framerate 30 -i <outdir>/f%04d.png -c:v libx264 -pix_fmt yuv420p clip.mp4
## Optional args: [2] "gloved" for the fingerless wool gloves, [3] a single time in seconds
## to render one frame (f0000.png) instead of the whole clip.
## Frames are deterministic: the AnimationPlayer is seeked to t = frame / fps.
## PROTOTYPE quality: a door swing and a pocket-watch raise, to judge the approach.

const LENGTH := 11.0
var main: Node3D
var out := "/tmp"
var fps := 30
var anim: Animation
var ap: AnimationPlayer
var cam: Camera3D
var door: DoorRig
var rhand: HandRig
var lhand: HandRig
var watch: WatchProp
var fade: ColorRect
var gripper: Grip               # 0 free .. 1 hand locked to the latch (animated)

class Grip extends Node:
	@export var grip := 0.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		fps = int(args[1])
	var gloved: bool = args.size() > 2 and args[2] == "gloved"
	var only_t := float(args[3]) if args.size() > 3 else -1.0
	root.size = Vector2i(1280, 720)
	main = load("res://main.tscn").instantiate()
	main.autostart = true
	root.add_child(main)
	for i in 12:
		await process_frame
	main.hud.hide()
	main.player.locked = true
	cam = main.player.cam
	root.get_node("GameClock").paused = true
	_stage()
	rhand.gloved = gloved
	lhand.gloved = gloved
	_build_anim()
	if only_t >= 0.0:
		ap.seek(only_t, true)
		_post(only_t)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/f0000.png" % out)
		quit(0)
		return
	for f in int(LENGTH * fps):
		var t := float(f) / fps
		ap.seek(t, true)
		_post(t)
		if fposmod(t, 0.5) < 0.5 / fps and OS.get_environment("ANIM_DEBUG") != "":
			print("t=%.2f cam=%s rhand_local=%s rhand_vis=%s door_angle=%.2f latch_cam=%s" % [t, cam.global_position, rhand.position, rhand.is_visible_in_tree(), door.angle, cam.to_local(door.grab.global_position)])
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/f%04d.png" % [out, f])
	print("frames written: ", int(LENGTH * fps))
	quit(0)

# --- scene ----------------------------------------------------------------

func _stage() -> void:
	var room: Node3D = main.interiors.get_child(0)
	var mesh: MeshInstance3D = room.get_node("Door")
	# hinge on the door's -X edge (strap hinges), latch near +X
	door = DoorRig.wrap(mesh, Vector3(-0.5, 0.0, 0.0), Vector3(0.36, 1.08, 0.1))
	# The wall behind the real door is solid, so fake daylight beyond it for the clip.
	var glow := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.12, 2.15)
	glow.mesh = q
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color.BLACK
	gm.emission_enabled = true
	gm.emission = Color(0.9, 0.95, 1.0)
	gm.emission_energy_multiplier = 3.0
	glow.material_override = gm
	glow.position = Vector3(1002.4, 1.075, 2.985)
	glow.rotation.y = PI
	main.add_child(glow)
	var l := OmniLight3D.new()
	l.position = Vector3(1002.4, 1.5, 2.55)
	l.light_color = Color(0.85, 0.93, 1.0)
	l.light_energy = 2.2
	l.omni_range = 6.0
	main.add_child(l)
	# viewmodel: hands parented to the camera
	var vm := Node3D.new()
	vm.name = "Viewmodel"
	cam.add_child(vm)
	rhand = HandRig.new(1.0)
	rhand.pose_a = &"relaxed"
	rhand.pose_b = &"grip_handle"
	lhand = HandRig.new(-1.0)
	lhand.pose_a = &"cup"
	vm.add_child(rhand)
	vm.add_child(lhand)
	watch = WatchProp.new()
	watch.position = Vector3(0.0, 0.028, -0.03)
	lhand.add_child(watch)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.add_child(fade)
	main.add_child(layer)

# --- animation ------------------------------------------------------------

func _path(node: Node, prop: String) -> NodePath:
	return NodePath("%s:%s" % [main.get_path_to(node), prop])

func _track(node: Node, prop: String) -> int:
	var tr := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr, _path(node, prop))
	anim.track_set_interpolation_type(tr, Animation.INTERPOLATION_LINEAR)
	return tr

## keys: [[time, value, transition?], ...]. Transition: 1 linear, -2 ease in/out, 0.5 ease out, 2 ease in.
func _keys(node: Node, prop: String, keys: Array) -> int:
	var tr := _track(node, prop)
	for k in keys:
		anim.track_insert_key(tr, k[0], k[1], k[2] if k.size() > 2 else 1.0)
	return tr

func _latch_cam(a: float) -> Vector3:
	var keep := door.angle
	door.angle = a
	var p: Vector3 = cam.to_local(door.grab.global_position)
	door.angle = keep
	return p

func _build_anim() -> void:
	anim = Animation.new()
	anim.length = LENGTH
	ap = AnimationPlayer.new()
	main.add_child(ap)
	ap.root_node = NodePath("..")
	var lib := AnimationLibrary.new()
	lib.add_animation("clip", anim)
	ap.add_animation_library("", lib)

	var spawn: Vector3 = main.interiors.spawn["cottage"]
	var p: CharacterBody3D = main.player
	var eye := 1.72
	# camera: walk to the door, cut, then stand at the window side for the watch
	var a_pos := Vector3(spawn.x, 0.05, 0.3)
	var b_pos := Vector3(spawn.x, 0.05, 2.25)      # arm's length from the latch
	var c_pos := Vector3(spawn.x, 0.05, 1.45)      # steps back as the door swings in
	var w_pos := Vector3(spawn.x - 1.0, 0.05, 0.4)
	_keys(p, "position", [
		[0.0, a_pos], [0.5, a_pos], [2.3, b_pos, -2.0], [2.8, b_pos], [3.9, c_pos, -2.0], [4.99, c_pos], [5.0, w_pos]])
	_keys(p, "rotation:y", [[0.0, PI], [4.99, PI], [5.0, 0.6]])
	_keys(cam, "rotation:x", [[0.0, -0.05], [0.5, -0.05], [2.2, -0.5, -2.0], [3.6, -0.5], [4.6, -0.12, -2.0], [4.99, -0.12], [5.0, -0.08]])
	var bob := [[0.0, eye]]
	for i in 7:
		bob.append([0.6 + i * 0.25, eye - (0.04 if i % 2 == 0 else 0.0)])
	bob.append([2.3, eye])
	for i in 4:
		bob.append([2.8 + i * 0.3, eye - (0.03 if i % 2 == 0 else 0.0)])
	bob.append([4.0, eye])
	bob.append([5.0, eye])
	_keys(cam, "position:y", bob)
	_keys(door, "angle", [[0.0, 0.0], [2.5, 0.0], [2.56, -0.035, 0.5], [2.66, -0.004], [2.78, -0.01],
		[3.7, -1.0, -2.0], [4.7, -1.6, 0.5]])
	_keys(fade, "modulate:a", [[0.0, 1.0], [0.35, 0.0, -2.0], [4.7, 0.0], [4.97, 1.0, -2.0], [5.04, 1.0], [5.35, 0.0, -2.0], [10.3, 0.0], [10.95, 1.0, -2.0]])

	# Probe where the latch is (in camera space) at the grasp and at the release, using
	# the tracks above, so the hand's free keys meet the door without a pop.
	ap.play("clip")
	ap.pause()
	ap.seek(2.3, true)
	var l0: Vector3 = cam.to_local(door.grab.global_position)
	ap.seek(3.4, true)
	var l_rel: Vector3 = cam.to_local(door.grab.global_position)

	# --- right hand + door ---
	var hidden_r := Vector3(0.34, -0.78, -0.26)
	_keys(rhand, "position", [[0.0, hidden_r], [1.7, hidden_r], [2.2, l0 + Vector3(0.0, 0.03, 0.1), -2.0], [2.35, l0],
		[3.4, l_rel], [4.3, hidden_r, -2.0]])
	_keys(rhand, "rotation", [[0.0, Vector3(0.4, -0.1, 0.0)], [1.7, Vector3(0.4, -0.1, 0.0)], [2.3, Vector3(-0.55, 0.15, -0.15), -2.0],
		[3.4, Vector3(-0.5, 0.3, -0.1)], [4.3, Vector3(0.4, -0.1, 0.0), -2.0]])
	_keys(rhand, "blend", [[0.0, 0.0], [2.0, 0.2], [2.5, 1.0, 0.5], [3.45, 1.0], [3.9, 0.0]])
	gripper = Grip.new()
	main.add_child(gripper)
	_keys(gripper, "grip", [[0.0, 0.0], [2.3, 0.0], [2.42, 1.0, 0.5], [3.4, 1.0], [3.62, 0.0, -2.0]])

	# --- left hand + watch ---
	var hidden_l := Vector3(-0.32, -0.8, -0.22)
	var hold_l := Vector3(-0.07, -0.12, -0.42)
	_keys(lhand, "position", [[0.0, hidden_l], [5.2, hidden_l], [5.9, hold_l, -2.0], [6.5, hold_l + Vector3(0.0, 0.004, 0.0)],
		[7.5, hold_l + Vector3(0.0, -0.003, 0.004)], [8.5, hold_l + Vector3(0.0, 0.004, 0.0)], [9.2, hold_l], [10.0, hidden_l, -2.0]])
	_keys(lhand, "rotation", [[0.0, Vector3(0.9, 0.3, 0.2)], [5.2, Vector3(0.9, 0.3, 0.2)], [5.9, Vector3(1.0, 0.12, 0.1), -2.0],
		[9.2, Vector3(1.0, 0.12, 0.1)], [10.0, Vector3(0.9, 0.3, 0.2), -2.0]])
	_keys(lhand, "curl", [[0.0, 0.0], [9.0, 0.0], [9.4, 0.3]])
	_keys(watch, "lid_open", [[0.0, 0.0], [6.3, 0.0], [6.46, 1.06, 0.5], [6.58, 1.0], [9.0, 1.0], [9.12, 0.0, 2.0]])
	_keys(watch, "clock_minutes", [[0.0, 418.0], [6.4, 418.0], [9.2, 423.0]])

	ap.seek(0.0, true)

## Procedural layer applied after the keyframes: a hand holding the latch follows
## the door wherever the keyframes put it.
func _post(_t: float) -> void:
	if gripper.grip > 0.0:
		var target: Vector3 = cam.to_local(door.grab.global_position) + Vector3(0.0, 0.02, 0.05)
		rhand.position = rhand.position.lerp(target, gripper.grip)
