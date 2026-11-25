class_name HandRig extends Node3D
## First-person hand with oilskin sleeve and knitted cuff: the factory-built
## skinned model (scenes/hands/hand_<side>.tscn, tools/hand_assets.gd) posed
## from data (anim/poses/*.tres, HandPose).
##
##   var h := HandRig.new(1.0)            # right hand; -1.0 = left (mirrored geometry)
##   h.set_pose(&"grip_handle")           # snap to a pose
##   h.set_pose(&"pinch", 0.4)            # 40 % of the way from pose_a to pinch
##   h.blend_poses(&"relaxed", &"fist", t)
##   h.curl = 0.6; h.thumb = 1.0          # prototype floats, layered on top
##
## Keyable from an AnimationPlayer: pose_a, pose_b (StringName, discrete),
## blend, curl, thumb, gloved. Conventions: fingers -Z, palm +Y, sleeve
## trails back toward +Z and down, drawn 1.5x life size.

const SCENE := "res://scenes/hands/hand_%s.tscn"
const FINGER_BONES := [&"index_1", &"index_2", &"index_3", &"middle_1", &"middle_2", &"middle_3",
	&"ring_1", &"ring_2", &"ring_3", &"little_1", &"little_2", &"little_3", &"palm_ulnar"]
const THUMB_BONES := [&"thumb_1", &"thumb_2", &"thumb_3"]

var side := 1.0
var skeleton: Skeleton3D
var _hand: MeshInstance3D
var _glove: MeshInstance3D
var _ready_bones := false

@export var pose_a: StringName = &"relaxed": set = _set_pose_a
@export var pose_b: StringName = &"relaxed": set = _set_pose_b
@export_range(0.0, 1.0) var blend := 0.0: set = _set_blend
## Prototype compatibility: 0 = the pose as is, 1 = fingers in a fist.
@export_range(0.0, 1.0) var curl := 0.0: set = set_curl
## Prototype compatibility: 0 = the pose as is, 1 = thumb folded across the fingers.
@export_range(0.0, 1.0) var thumb := 0.0: set = set_thumb
## Fingerless wool glove over the hand.
@export var gloved := false: set = set_gloved

func _init(p_side := 1.0) -> void:
	side = 1.0 if p_side >= 0.0 else -1.0
	name = "HandRight" if side > 0.0 else "HandLeft"
	scale = Vector3.ONE * 1.5      # viewmodel hands are drawn bigger than life so they read on screen
	var model: Node3D = load(SCENE % ("right" if side > 0.0 else "left")).instantiate()
	model.name = "Model"
	add_child(model)
	skeleton = model.get_node("Skeleton3D")
	_hand = skeleton.get_node("Hand")
	_glove = skeleton.get_node("Glove")
	_ready_bones = true
	_apply()

## Blend toward `pose_name` by `weight` from pose_a. weight 1 makes it the base pose.
func set_pose(pose_name: StringName, weight := 1.0) -> void:
	if weight >= 1.0:
		pose_a = pose_name
		pose_b = pose_name
		blend = 0.0
	else:
		pose_b = pose_name
		blend = clampf(weight, 0.0, 1.0)

func blend_poses(a: StringName, b: StringName, t: float) -> void:
	pose_a = a
	pose_b = b
	blend = clampf(t, 0.0, 1.0)

func set_curl(v: float) -> void:
	curl = clampf(v, 0.0, 1.0)
	_apply()

func set_thumb(v: float) -> void:
	thumb = clampf(v, 0.0, 1.0)
	_apply()

func set_gloved(v: bool) -> void:
	gloved = v
	if _glove:
		_glove.visible = v

func _set_pose_a(v: StringName) -> void:
	pose_a = v
	_apply()

func _set_pose_b(v: StringName) -> void:
	pose_b = v
	_apply()

func _set_blend(v: float) -> void:
	blend = v
	_apply()

## The bone's current transform in this rig's space (before the rig's 1.5x scale).
func bone_transform(bone: StringName) -> Transform3D:
	update_now()
	return skeleton.get_bone_global_pose(skeleton.find_bone(bone))

## Recomputes bone globals immediately (the skeleton otherwise updates once a
## frame, and not at all outside the tree).
func update_now() -> void:
	skeleton.force_update_all_bone_transforms()

## Parents `node` to a bone so it follows the hand (a held prop, say).
func attach(node: Node3D, bone: StringName) -> BoneAttachment3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	ba.add_child(node)
	return ba

## Current pose-space rotation of every bone (what _apply writes), for tests.
func pose_rotation(bone: StringName) -> Quaternion:
	var a := HandPose.named(pose_a)
	var b := HandPose.named(pose_b)
	var q := a.rotation(bone, side) if a else Quaternion.IDENTITY
	if b and blend > 0.0:
		q = q.slerp(b.rotation(bone, side), blend)
	var fist := HandPose.named(&"fist")
	if fist:
		if curl > 0.0 and bone in FINGER_BONES:
			q = q.slerp(fist.rotation(bone, side), curl)
		if thumb > 0.0 and bone in THUMB_BONES:
			q = q.slerp(fist.rotation(bone, side), thumb)
	return q

func _apply() -> void:
	if not _ready_bones:
		return
	for k in skeleton.get_bone_count():
		var bn := StringName(skeleton.get_bone_name(k))
		var rest := skeleton.get_bone_rest(k)
		skeleton.set_bone_pose_rotation(k, rest.basis.get_rotation_quaternion() * pose_rotation(bn))
		skeleton.set_bone_pose_position(k, rest.origin)
