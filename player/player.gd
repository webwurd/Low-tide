class_name Player extends CharacterBody3D
## First-person Arthur. Feet-origin CharacterBody3D; camera at eye height.
## Walk/brisk with stamina, head-bob, binoculars, depth-band wading, swept.

signal swept

const WALK := 3.2
const BRISK := 6.5
const EYE := 1.72
const GRAVITY := 18.0
const MOUSE_SENS := 0.0022
const BINO_SENS := 0.0008
const PAD_RATE := 2.6            # rad/s at full stick deflection
const FOV_NORMAL := 65.0
const FOV_BINO := 20.0
const WORLD_LIMIT := 95.0

var cam: Camera3D
var yaw := 0.0
var pitch := 0.0
var stamina := 100.0
var binoculars := false
var locked := false              # true during swept / cutscenes
var nearby: Interactable = null
var bino_label := ""
var bino_dist := -1
var water_depth := 0.0
var _bob_t := 0.0
var _stride := 0.0
var indoors := false              # interiors: no tide, no world limit, wooden steps
var ui_lock := false              # a modal panel (logbook, tide table) is open
var hold_progress := 0.0          # 0..1 while holding a hold-to-use interactable
var _hold_t := 0.0
var _hold_done := false
var _hold_active := false

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	cam = Camera3D.new()
	cam.position.y = EYE
	cam.fov = FOV_NORMAL
	cam.far = 450.0
	cam.current = true
	add_child(cam)
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50.0)

func _unhandled_input(event: InputEvent) -> void:
	if locked or ui_lock:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s: float = (BINO_SENS * float(Settings.v("bino_sens"))) if binoculars else (MOUSE_SENS * float(Settings.v("mouse_sens")))
		var inv := -1.0 if Settings.v("invert_y") else 1.0
		_look(-event.relative.x * s, -event.relative.y * s * inv)
	elif event.is_action_pressed("interact"):
		if nearby and nearby.hold_time <= 0.0:
			nearby.interact()

func _look(dyaw: float, dpitch: float) -> void:
	yaw += dyaw
	pitch = clampf(pitch + dpitch, -PI / 2.2, PI / 2.2)

func teleport(pos: Vector3, new_yaw := 0.0) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	yaw = new_yaw
	pitch = 0.0

func _physics_process(delta: float) -> void:
	if locked or ui_lock:
		velocity = Vector3.ZERO
		hold_progress = 0.0
		return
	if Settings.v("toggle_binoculars"):
		if Input.is_action_just_pressed("binoculars"):
			binoculars = not binoculars
	else:
		binoculars = Input.is_action_pressed("binoculars")
	var pad := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if pad != Vector2.ZERO:
		var rate: float = PAD_RATE * float(Settings.v("pad_sens")) * (0.35 if binoculars else 1.0)
		var inv_pad := -1.0 if Settings.v("invert_y") else 1.0
		_look(-pad.x * rate * delta, -pad.y * rate * delta * inv_pad)
	rotation.y = yaw
	cam.rotation.x = pitch

	water_depth = 0.0 if indoors else TideSystem.current_height - global_position.y
	var wade := TideSystem.speed_multiplier(water_depth)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var moving := input != Vector2.ZERO
	var wants_brisk := Input.is_action_pressed("sprint") and moving and stamina > 5.0 and not binoculars
	var speed := (BRISK if wants_brisk else WALK) * wade * (0.55 if binoculars else 1.0)
	if wants_brisk:
		stamina = maxf(0.0, stamina - delta * 28.0)
	else:
		stamina = minf(100.0, stamina + delta * 18.0)

	var dir := (global_transform.basis * Vector3(input.x, 0.0, input.y))
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, 40.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 40.0 * delta)
	if is_on_floor():
		velocity.y = -1.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	var p := global_position
	if not indoors:
		p.x = clampf(p.x, -WORLD_LIMIT, WORLD_LIMIT)
		p.z = clampf(p.z, -WORLD_LIMIT, WORLD_LIMIT)
		global_position = p

	# Head-bob + footsteps by distance walked
	var planar := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and planar > 0.3:
		_bob_t += delta * planar * 2.6
		cam.position.y = EYE + sin(_bob_t) * (0.0 if Settings.v("reduce_motion") else 0.045)
		_stride += planar * delta
		if _stride >= (1.9 if not wants_brisk else 2.4):
			_stride = 0.0
			var surf := "wood" if indoors else Terrain.surface_at(p.x, p.z, p.y)
			AudioDirector.play_footstep(surf, wants_brisk, water_depth > 0.05)
	else:
		cam.position.y = lerpf(cam.position.y, EYE, minf(1.0, delta * 8.0))

	var target_fov := FOV_BINO if binoculars else FOV_NORMAL
	if absf(cam.fov - target_fov) > 0.05:
		cam.fov = lerpf(cam.fov, target_fov, minf(1.0, delta * 10.0))

	_update_interaction()
	_update_hold(delta)
	_update_binoculars()
	if not indoors:
		if water_depth > TideSystem.SWEPT_DEPTH or p.y < -8.0:
			swept.emit()

func _update_hold(delta: float) -> void:
	var holdable := nearby != null and nearby.hold_time > 0.0
	if Settings.v("toggle_hold"):
		# Press once to start; it completes by itself while Arthur stays in range. Press again to cancel.
		if not holdable:
			_hold_t = 0.0
			hold_progress = 0.0
			_hold_active = false
			_hold_done = false
			return
		if Input.is_action_just_pressed("interact"):
			_hold_done = false
			_hold_active = not _hold_active
			if not _hold_active:
				_hold_t = 0.0
				hold_progress = 0.0
		if not _hold_active:
			return
	else:
		_hold_active = Input.is_action_pressed("interact") and holdable
		if not _hold_active:
			_hold_t = 0.0
			hold_progress = 0.0
			_hold_done = false if not Input.is_action_pressed("interact") else _hold_done
			return
	if _hold_done:
		return
	_hold_t += delta
	hold_progress = clampf(_hold_t / nearby.hold_time, 0.0, 1.0)
	if _hold_t >= nearby.hold_time:
		_hold_done = true
		_hold_active = false
		_hold_t = 0.0
		hold_progress = 0.0
		nearby.interact()

func _update_interaction() -> void:
	var eye := global_position + Vector3(0, EYE, 0)
	var best: Interactable = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if not it.is_available():
			continue
		var d := eye.distance_to(it.global_position)
		if d <= it.radius and d < best_d:
			best = it
			best_d = d
	nearby = best

func _update_binoculars() -> void:
	bino_label = ""
	bino_dist = -1
	if not binoculars:
		return
	var fwd := -cam.global_transform.basis.z
	var best_dot := 0.96
	for n in get_tree().get_nodes_in_group("bino_target"):
		var to: Vector3 = (n as Node3D).global_position - cam.global_position
		var dist := to.length()
		var dot := fwd.dot(to / dist)
		if dot > best_dot:
			best_dot = dot
			bino_label = n.get_meta("label")
			bino_dist = int(round(dist))
