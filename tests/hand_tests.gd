class_name HandTests
## Checks for the first-person hand (anim/hand_rig.gd, anim/hand_pose.gd,
## tools/hand_assets.gd). Called from tests/run_tests.gd; `t` is the runner
## (ok / near). Uses CPU skinning of the committed mesh, so it runs headless.

const M := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
const TIPS := ["thumb", "index", "middle", "ring", "little"]

## Flex ranges (degrees, measured on the posed skeleton) that each pose must show.
const EXPECT := {
	"open": {"index_2": [-10, 8], "little_2": [-10, 8], "thumb_3": [-15, 5]},
	"relaxed": {"index_2": [15, 50], "little_2": [25, 60], "thumb_3": [5, 30]},
	"fist": {"index_1": [70, 100], "index_2": [85, 115], "middle_2": [85, 115], "little_2": [85, 115], "thumb_2": [20, 60]},
	"grip_handle": {"index_1": [40, 75], "index_2": [60, 95], "little_2": [60, 95]},
	"pinch": {"index_2": [30, 75], "ring_2": [60, 100], "thumb_1": [15, 60]},
	"press": {"index_1": [0, 30], "index_2": [0, 30], "middle_2": [60, 110]},
	"press_thumb": {"thumb_2": [-10, 12], "thumb_3": [-20, 5], "index_2": [50, 95]},
	"cup": {"index_2": [15, 45], "palm_ulnar": [3, 25]},
	"push_open_palm": {"palm": [-60, -20], "index_2": [-10, 8]},
	"two_hand_binoculars": {"index_2": [25, 60], "middle_2": [40, 80]},
	"point": {"index_1": [-10, 15], "index_2": [-10, 15], "middle_2": [85, 115], "ring_2": [85, 115]},
}

static func run(t) -> void:
	var r := HandRig.new(1.0)
	var l := HandRig.new(-1.0)
	t.root.add_child(r)            # skeletons only update their globals inside the tree
	t.root.add_child(l)
	var sk := r.skeleton
	t.ok(sk.get_bone_count() == HandAssets.BONES.size() and sk.get_bone_count() >= 17, "hand skeleton has %d bones (wrist, palm, ulnar metacarpal, 3 per finger, thumb 3)" % sk.get_bone_count())
	var parents_ok := true
	for k in HandAssets.BONES.size():
		var par: String = HandAssets.BONES[k][1]
		parents_ok = parents_ok and sk.get_bone_name(k) == HandAssets.BONES[k][0] \
			and sk.get_bone_parent(k) == (sk.find_bone(par) if par != "" else -1)
	t.ok(parents_ok, "bone names and hierarchy match HandAssets.BONES")
	t.ok(r.scale.x > 0.0 and l.scale.x > 0.0 and l.get_node("Model").transform.basis.determinant() > 0.0, "left hand is mirrored by geometry, not a negative scale")

	# Rest pose: a pose with no joints leaves every bone at rest, mesh undeformed.
	var mesh: ArrayMesh = (r.skeleton.get_node("Hand") as MeshInstance3D).mesh
	var arr := _skin_arrays(mesh)
	_pose_rest(r)
	var rest_v := skinned(r, arr)
	var max_d := 0.0
	for k in rest_v.size():
		max_d = maxf(max_d, rest_v[k].distance_to(arr[Mesh.ARRAY_VERTEX][k]))
	t.ok(max_d < 1e-5, "rest pose: skinned mesh equals the bind mesh (max %.6f m)" % max_d)
	var tip := _tip(r, "middle")
	t.ok(tip.z < -0.12 and absf(tip.y) < 0.01, "rest pose: fingers point -Z (middle tip at %s)" % tip)
	var tris := (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	var all_tris := 0
	for s in mesh.get_surface_count():
		all_tris += (mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	t.ok(tris >= 1500 and tris <= 3000, "skin mesh is %d triangles (1.5k-3k), %d with cuff and sleeve" % [tris, all_tris])
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arr)
	im.generate_lods(25.0, 60.0, [])
	t.ok(im.get_surface_lod_count(0) > 0, "hand mesh generates LODs (%d)" % im.get_surface_lod_count(0))
	var skin_ok := true
	for s in mesh.get_surface_count():
		skin_ok = skin_ok and (mesh.surface_get_format(s) & Mesh.ARRAY_FORMAT_BONES) != 0
	t.ok(skin_ok, "every hand surface (skin, cuff, sleeve) is skinned")

	# Every named pose loads and bends the joints it should.
	var palm_ok := true
	var palm_msg := ""
	var mirror_ok := true
	var mirror_err := 0.0
	var arr_l := _skin_arrays((l.skeleton.get_node("Hand") as MeshInstance3D).mesh)
	for p in HandPose.NAMES:
		var pose := HandPose.named(p)
		t.ok(pose != null and not pose.joints.is_empty(), "pose %s loads from anim/poses/%s.tres" % [p, p])
		if pose == null:
			continue
		r.set_pose(p)
		l.set_pose(p)
		var exp: Dictionary = EXPECT.get(String(p), {})
		var bends := true
		var got := []
		for b in exp:
			var f := measured_flex(r, b)
			got.append("%s %.0f" % [b, f])
			bends = bends and f >= exp[b][0] and f <= exp[b][1]
		t.ok(bends and not exp.is_empty(), "pose %s bends the expected joints (%s)" % [p, ", ".join(got)])
		# No finger passes through the palm.
		var deep := penetration(r, arr)
		if deep[0] < 0.55:
			palm_ok = false
			palm_msg += " %s:%s %.2f" % [p, deep[1], deep[0]]
		# Left mirrors right: bones and every skinned vertex.
		r.update_now()
		l.update_now()
		for k in r.skeleton.get_bone_count():
			var a := r.skeleton.get_bone_global_pose(k)
			var bb := l.skeleton.get_bone_global_pose(k)
			var mt := Transform3D(M * a.basis * M, Vector3(-a.origin.x, a.origin.y, a.origin.z))
			mirror_err = maxf(mirror_err, mt.origin.distance_to(bb.origin) + (mt.basis.x - bb.basis.x).length() + (mt.basis.z - bb.basis.z).length())
		var rv := skinned(r, arr)
		var lv := skinned(l, arr_l)
		for k in range(0, rv.size(), 7):
			mirror_err = maxf(mirror_err, Vector3(-rv[k].x, rv[k].y, rv[k].z).distance_to(lv[k]))
	t.ok(palm_ok, "no finger passes through the palm in any pose%s" % palm_msg)
	mirror_ok = mirror_err < 1e-4
	t.ok(mirror_ok, "left and right hands mirror each other in every pose (max error %.6f)" % mirror_err)

	# Contacts the poses exist for.
	r.set_pose(&"pinch")
	var d := _pad(r, "thumb").distance_to(_pad(r, "index"))
	t.ok(d < 0.012, "pinch: thumb and index pads meet (%.1f mm apart)" % (d * 1000.0))
	r.set_pose(&"fist")
	var fist_ok := true
	for f in ["index", "middle", "ring", "little"]:
		fist_ok = fist_ok and _tip(r, f).y > 0.008 and _tip(r, f).z > -0.06
	t.ok(fist_ok, "fist: every fingertip is tucked onto the palm")

	# Blending and the prototype's curl / thumb floats.
	r.blend_poses(&"open", &"fist", 0.5)
	var half := measured_flex(r, "index_2")
	t.ok(half > 35.0 and half < 65.0, "blend_poses open->fist at 0.5 is halfway (index_2 %.0f deg)" % half)
	r.set_pose(&"relaxed")
	r.set_pose(&"fist", 0.25)
	t.ok(r.pose_a == &"relaxed" and r.pose_b == &"fist" and is_equal_approx(r.blend, 0.25), "set_pose(name, weight) blends from the current pose")
	r.set_pose(&"relaxed")
	var base := measured_flex(r, "middle_2")
	r.curl = 0.0
	r.thumb = 0.0
	t.ok(is_equal_approx(measured_flex(r, "middle_2"), base), "curl 0 / thumb 0 leave the pose alone")
	r.curl = 0.5
	var mid := measured_flex(r, "middle_2")
	r.curl = 1.0
	var full := measured_flex(r, "middle_2")
	var fist_m: float = HandPose.named(&"fist").flex(&"middle_2")
	t.ok(mid > base + 5.0 and mid < full - 5.0 and absf(full - fist_m) < 0.5, "curl closes the fingers toward the fist (%.0f -> %.0f -> %.0f)" % [base, mid, full])
	var th0 := measured_flex(r, "thumb_2")
	r.thumb = 1.0
	t.ok(absf(measured_flex(r, "thumb_2") - HandPose.named(&"fist").flex(&"thumb_2")) < 0.5 and absf(measured_flex(r, "index_2") - HandPose.named(&"fist").flex(&"index_2")) < 0.5,
		"thumb folds only the thumb across the palm (thumb_2 %.0f -> %.0f)" % [th0, measured_flex(r, "thumb_2")])
	r.curl = 0.0
	r.thumb = 0.0
	var keyable := true
	for prop in ["curl", "thumb", "pose_a", "pose_b", "blend", "gloved"]:
		var found := false
		for pi in r.get_property_list():
			if pi.name == prop and (pi.usage & PROPERTY_USAGE_STORAGE) != 0:
				found = true
		keyable = keyable and found
	t.ok(keyable, "curl, thumb, pose_a, pose_b, blend and gloved are exported (keyable from an AnimationPlayer)")
	r.gloved = true
	t.ok((r.skeleton.get_node("Glove") as MeshInstance3D).visible, "gloved shows the fingerless wool glove")
	r.free()
	l.free()

# --- helpers (also used by tools while tuning poses) -------------------------

static func _skin_arrays(mesh: ArrayMesh) -> Array:
	for s in mesh.get_surface_count():
		if mesh.surface_get_name(s) == "skin":
			return mesh.surface_get_arrays(s)
	return mesh.surface_get_arrays(0)

static func _pose_rest(r: HandRig) -> void:
	for k in r.skeleton.get_bone_count():
		r.skeleton.set_bone_pose(k, r.skeleton.get_bone_rest(k))

## Linear-blend skinning on the CPU, in skeleton space.
static func skinned(r: HandRig, arr: Array) -> PackedVector3Array:
	r.update_now()
	var sk := r.skeleton
	var xf: Array[Transform3D] = []
	for k in sk.get_bone_count():
		xf.append(sk.get_bone_global_pose(k) * sk.get_bone_global_rest(k).affine_inverse())
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var w: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var out := PackedVector3Array()
	out.resize(v.size())
	for i in v.size():
		var p := Vector3.ZERO
		for j in 4:
			var wt := w[i * 4 + j]
			if wt > 0.0:
				p += (xf[bones[i * 4 + j]] * v[i]) * wt
		out[i] = p
	return out

## Flexion of a bone relative to its rest, in degrees (+ toward the palm).
static func measured_flex(r: HandRig, bone: String) -> float:
	var sk := r.skeleton
	var k := sk.find_bone(bone)
	var q := sk.get_bone_rest(k).basis.get_rotation_quaternion().inverse() * sk.get_bone_pose_rotation(k)
	var fwd := Basis(q) * Vector3.FORWARD
	return rad_to_deg(atan2(fwd.y, -fwd.z))

## Deepest finger vertex inside the palm core: [palm_inside value, finger]
## (1 = on the core's surface, smaller = deeper). Distal and middle
## phalanges and the thumb's last two bones are checked, in the palm's frame.
static func penetration(r: HandRig, arr: Array) -> Array:
	r.update_now()
	var sk := r.skeleton
	var palm := sk.find_bone("palm")
	var to_rest := sk.get_bone_global_rest(palm) * sk.get_bone_global_pose(palm).affine_inverse()
	var mirror := r.side < 0.0
	var check := {}
	for f in ["index", "middle", "ring", "little"]:
		check[sk.find_bone(f + "_2")] = f
		check[sk.find_bone(f + "_3")] = f
	check[sk.find_bone("thumb_2")] = "thumb"
	check[sk.find_bone("thumb_3")] = "thumb"
	var v := skinned(r, arr)
	var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var w: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var worst := [9.0, ""]
	for i in v.size():
		var b := bones[i * 4]
		if not check.has(b) or w[i * 4] < 0.6:
			continue
		var q := to_rest * v[i]
		if mirror:
			q.x = -q.x
		var val := HandAssets.palm_inside(q)
		if val < worst[0]:
			worst = [val, check[b]]
	return worst

## Fingertip (end of the last bone) in rig space.
static func _tip(r: HandRig, f: String) -> Vector3:
	r.update_now()
	var sk := r.skeleton
	var k := sk.find_bone(f + "_3")
	var lens: Array = HandAssets.THUMB.len if f == "thumb" else HandAssets.FINGER[f].len
	return sk.get_bone_global_pose(k) * Vector3(0, 0, -lens[2])

## Centre of the fingertip pad (palmar side of the last phalanx, near its end).
static func _pad(r: HandRig, f: String) -> Vector3:
	r.update_now()
	var sk := r.skeleton
	var k := sk.find_bone(f + "_3")
	var lens: Array = HandAssets.THUMB.len if f == "thumb" else HandAssets.FINGER[f].len
	return sk.get_bone_global_pose(k) * Vector3(0, 0.006, -lens[2] * 0.72)

## Per-pose report for tuning: flex of each bone, penetration, tip distances.
static func report(r: HandRig) -> void:
	var arr := _skin_arrays((r.skeleton.get_node("Hand") as MeshInstance3D).mesh)
	for p in HandPose.NAMES:
		r.set_pose(p)
		var pen := penetration(r, arr)
		var tips := []
		for f in TIPS:
			tips.append("%s(%.3f,%.3f,%.3f)" % [f.left(2), _tip(r, f).x, _tip(r, f).y, _tip(r, f).z])
		print("%-20s pen %.2f %-6s pinch %.1fmm  %s" % [p, pen[0], pen[1], _pad(r, "thumb").distance_to(_pad(r, "index")) * 1000.0, " ".join(tips)])
