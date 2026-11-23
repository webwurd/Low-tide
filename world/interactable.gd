class_name Interactable extends Node3D
## A thing Arthur can inspect. Found via the "interactable" group.
## `conversation` is a key into Conversations; first use also logs `id`.

@export var id := ""
@export var title := "Inspect"
@export var radius := 4.5
@export var conversation := ""

signal used

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	GameState.discover(id)
	used.emit()
	if conversation != "":
		RadioSystem.play(Conversations.get_conv(conversation))
