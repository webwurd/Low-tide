class_name Interactable extends Node3D
## A thing Arthur can inspect or use. Found via the "interactable" group.
## `used` fires on every use. `conversation` plays only the first time.
## hold_time > 0 means the player must hold the interact button.

@export var id := ""
@export var title := "Inspect"
@export var radius := 4.5
@export var conversation := ""
@export var hold_time := 0.0

var title_fn: Callable = Callable()     # () -> String   dynamic prompt
var visible_fn: Callable = Callable()   # () -> bool     false hides it entirely

signal used

func _ready() -> void:
	add_to_group("interactable")

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
	used.emit()
	if first and conversation != "":
		RadioSystem.play(Conversations.get_conv(conversation))
