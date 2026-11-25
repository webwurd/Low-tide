class_name DoorRig extends Node3D
## Hinge pivot for a baked door mesh (PROTOTYPE). wrap() inserts a pivot at the
## hinge edge at load time, so it keeps working when the asset factory
## regenerates the door. `angle` is radians about the hinge; negative swings the
## free edge toward the door's +Z (front) side.

var panel: MeshInstance3D
var grab: Marker3D            # where a hand takes hold (the latch), moves with the door
var _base := Transform3D.IDENTITY

@export var angle := 0.0: set = set_angle

static func wrap(door: MeshInstance3D, hinge_local: Vector3, latch_local: Vector3) -> DoorRig:
	var rig := DoorRig.new()
	rig.name = String(door.name) + "Hinge"
	var parent := door.get_parent()
	rig._base = door.transform * Transform3D(Basis(), hinge_local)
	parent.add_child(rig)
	rig.transform = rig._base
	door.reparent(rig, false)
	door.transform = Transform3D(Basis(), -hinge_local)
	rig.panel = door
	rig.grab = Marker3D.new()
	rig.grab.position = latch_local - hinge_local
	rig.add_child(rig.grab)
	return rig

func set_angle(a: float) -> void:
	angle = a
	transform = Transform3D(_base.basis * Basis(Vector3.UP, a), _base.origin)
