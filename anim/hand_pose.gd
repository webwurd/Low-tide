class_name HandPose extends Resource
## One hand pose as data (anim/poses/<name>.tres): rotation offsets from the
## rest hand (flat, fingers together and straight), per bone, in degrees.
## Written once for the right hand; the left hand mirrors it.
##
##   joints["index_2"] = Vector3(flex, spread, twist)
##     flex   +X: curl toward the palm (negative bends back)
##     spread  Y: + toward the thumb side
##     twist   Z: roll about the bone (+ turns the pad toward the thumb)
##   Bones left out stay at rest. Bone names: HandAssets.BONES.
##
## HandRig blends two poses (pose_a / pose_b / blend) and layers the old
## curl / thumb floats on top; key those properties from an AnimationPlayer.

const DIR := "res://anim/poses/"
## Every pose the rig ships with (anim/poses/<name>.tres).
const NAMES: Array[StringName] = [&"open", &"relaxed", &"fist", &"grip_handle", &"pinch", &"press",
	&"press_thumb", &"cup", &"push_open_palm", &"two_hand_binoculars", &"point"]

@export var joints: Dictionary = {}
@export_multiline var notes := ""

static var _cache := {}

## The named pose, cached. Unknown names return null (and warn once).
static func named(pose_name: StringName) -> HandPose:
	if _cache.has(pose_name):
		return _cache[pose_name]
	var p := DIR + String(pose_name) + ".tres"
	var res: HandPose = null
	if ResourceLoader.exists(p):
		res = load(p) as HandPose
	if res == null:
		push_warning("HandPose: no pose '%s'" % pose_name)
	_cache[pose_name] = res
	return res

## Pose-space rotation of one bone (relative to its rest). side 1 right, -1 left.
func rotation(bone: StringName, side := 1.0) -> Quaternion:
	return to_quat(joints.get(String(bone), joints.get(bone, Vector3.ZERO)), side)

static func to_quat(deg: Vector3, side := 1.0) -> Quaternion:
	# Spread in the parent's frame, then flex, then roll about the bone.
	var b := Basis(Vector3.UP, -deg_to_rad(deg.y) * side) * Basis(Vector3.RIGHT, deg_to_rad(deg.x)) \
		* Basis(Vector3.BACK, deg_to_rad(deg.z) * side)
	return b.get_rotation_quaternion()

## Degrees of flexion a pose gives a bone (for tests and tools).
func flex(bone: StringName) -> float:
	var v: Vector3 = joints.get(String(bone), Vector3.ZERO)
	return v.x
