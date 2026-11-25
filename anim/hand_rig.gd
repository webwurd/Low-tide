class_name HandRig extends Node3D
## First-person hand and oilskin sleeve built from MeshKit boxes (PROTOTYPE).
## Faces -Z; the sleeve trails back toward the camera. `curl` closes the fingers
## (0 open, 1 fist) and `thumb` folds the thumb across the palm. Left hand =
## side -1 (geometry is mirrored by placement, never by negative scale).

const SKIN := Color(0.78, 0.52, 0.4)
const SLEEVE := Color(0.92, 0.62, 0.08)
const CUFF := Color(0.62, 0.44, 0.1)

var side := 1.0
var _prox: Array[Node3D] = []
var _mid: Array[Node3D] = []
var _thumb_a: Node3D
var _thumb_b: Node3D

@export var curl := 0.0: set = set_curl
@export var thumb := 0.0: set = set_thumb

func _init(p_side := 1.0) -> void:
	side = p_side
	scale = Vector3.ONE * 1.5      # viewmodel hands are drawn bigger than life so they read on screen
	_build()

static func _mesh(mat: String, size: Vector3, center: Vector3, tint: Color, bevel := 0.006) -> MeshInstance3D:
	var k := MeshKit.new()
	k.tint = tint
	k.box(mat, size, center, bevel, 1)
	var mi := MeshInstance3D.new()
	mi.mesh = k.commit(false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func _build() -> void:
	add_child(_mesh("linen", Vector3(0.088, 0.026, 0.092), Vector3.ZERO, SKIN, 0.009))
	var xs := [-0.033, -0.011, 0.011, 0.033]
	var lens := [0.062, 0.072, 0.068, 0.054]
	for i in 4:
		var a := Node3D.new()
		a.position = Vector3(xs[i] * side, 0.0, -0.046)
		a.add_child(_mesh("linen", Vector3(0.019, 0.019, lens[i] * 0.55), Vector3(0, 0, -lens[i] * 0.275), SKIN, 0.006))
		var b := Node3D.new()
		b.position = Vector3(0, 0, -lens[i] * 0.55)
		b.add_child(_mesh("linen", Vector3(0.017, 0.017, lens[i] * 0.5), Vector3(0, 0, -lens[i] * 0.25), SKIN, 0.006))
		a.add_child(b)
		add_child(a)
		_prox.append(a)
		_mid.append(b)
	_thumb_a = Node3D.new()
	_thumb_a.position = Vector3(0.046 * side, 0.0, -0.018)
	_thumb_a.rotation.y = -0.55 * side
	_thumb_a.add_child(_mesh("linen", Vector3(0.022, 0.02, 0.04), Vector3(0, 0, -0.02), SKIN, 0.007))
	_thumb_b = Node3D.new()
	_thumb_b.position = Vector3(0, 0, -0.04)
	_thumb_b.add_child(_mesh("linen", Vector3(0.019, 0.017, 0.032), Vector3(0, 0, -0.016), SKIN, 0.006))
	_thumb_a.add_child(_thumb_b)
	add_child(_thumb_a)
	# Oilskin sleeve with a knitted cuff, trailing back and down toward the shoulder.
	var sleeve := Node3D.new()
	sleeve.position = Vector3(0, 0, 0.044)
	sleeve.rotation.x = deg_to_rad(112.0)
	sleeve.rotation.z = -0.18 * side
	var k := MeshKit.new()
	k.tint = CUFF
	k.cylinder("linen", 0.046, 0.046, 0.05, 14, 0.0, true)
	k.tint = SLEEVE
	k.lathe("linen", PackedVector2Array([Vector2(0.05, 0.05), Vector2(0.062, 0.3), Vector2(0.075, 0.7)]), 14, true)
	var mi := MeshInstance3D.new()
	mi.mesh = k.commit(false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sleeve.add_child(mi)
	add_child(sleeve)
	set_curl(curl)
	set_thumb(thumb)

func set_curl(v: float) -> void:
	curl = v
	for i in _prox.size():
		_prox[i].rotation.x = -v * (1.15 - 0.08 * i)
		_mid[i].rotation.x = -v * 1.35

func set_thumb(v: float) -> void:
	thumb = v
	if _thumb_a:
		_thumb_a.rotation.y = (-0.55 + v * 0.9) * side
		_thumb_a.rotation.x = -v * 0.25
		_thumb_b.rotation.x = -v * 0.5
