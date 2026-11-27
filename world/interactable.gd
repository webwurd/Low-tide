class_name Interactable extends Node3D
## A thing Arthur can inspect or use. Found via the "interactable" group.
## `used` fires on every use. `conversation` plays only the first time.
## hold_time > 0 means the player must hold the interact button.
## `highlight_paths` point at the meshes that glow softly (warm rim) while
## this is the thing Arthur would use; the painterly shader's per-instance
## `highlight` uniform does the drawing.

@export var id := ""
@export var title := "Inspect"
@export var radius := 4.5
@export var conversation := ""
@export var hold_time := 0.0
@export var give_item := ""                 ## satchel item granted on use (M4)
@export var highlight_paths: Array[NodePath] = []

var title_fn: Callable = Callable()     # () -> String   dynamic prompt
var visible_fn: Callable = Callable()   # () -> bool     false hides it entirely

signal used

var _glow := 0.0
var _glow_target := 0.0

func _ready() -> void:
	add_to_group("interactable")
	set_process(false)

func get_title() -> String:
	if title_fn.is_valid():
		return title_fn.call()
	return title

func is_available() -> bool:
	if visible_fn.is_valid():
		return visible_fn.call()
	return true

func interact() -> void:
	var first := GameState.discover(id)
	if give_item != "":
		GameState.give_item(give_item)
	used.emit()
	if first and conversation != "":
		RadioSystem.play(Conversations.get_conv(conversation))

## Called by the player: 1 (or true) = the thing Arthur is looking at, a small
## value = in reach but not focused (dim), 0 (or false) = none.
func set_highlight(level = true) -> void:
	_glow_target = clampf(float(level), 0.0, 1.0)
	set_process(true)

## Where to aim at: the centre of the highlight meshes (a door's panel, the bed),
## falling back to the node itself, so big objects are targeted by their middle.
func focus_point() -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for p in highlight_paths:
		var g := get_node_or_null(p) as GeometryInstance3D
		if g:
			sum += g.global_transform * g.get_aabb().get_center()
			n += 1
	return sum / float(n) if n > 0 else global_position

func _process(delta: float) -> void:
	_glow = move_toward(_glow, _glow_target, delta * 3.0)
	var pulse := _glow * (0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.003))
	for p in highlight_paths:
		var g := get_node_or_null(p) as GeometryInstance3D
		if g:
			g.set_instance_shader_parameter("highlight", pulse)
	if _glow == _glow_target and _glow == 0.0:
		set_process(false)
