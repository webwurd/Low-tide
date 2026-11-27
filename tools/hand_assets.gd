class_name HandAssets
## First-person hands for the viewmodel: a skinned mesh on a Skeleton3D, built
## in code like every other factory asset.
##
##   assets/models/hand_right.res, hand_left.res              skin + knitted cuff + oilskin sleeve
##   assets/models/hand_glove_right.res, hand_glove_left.res  fingerless wool glove (overlay)
##   scenes/hands/hand_right.tscn, hand_left.tscn             Skeleton3D + both meshes
##
## Conventions (unchanged from the prototype): fingers point -Z, the palm faces
## +Y, the sleeve trails back toward +Z and down, units are metres at life size
## (HandRig scales the whole rig 1.5x so it reads on screen). The right hand's
## thumb is on +X. The left hand is the right one reflected through x = 0
## (MeshKit.mirrored_x for the mesh, M*T*M for the bone rests): no negative scale.
##
## Every finger, the thumb and the palm are one continuous lofted surface each,
## skinned with weights blended across each joint, so knuckles bend without
## gaps. Finger roots are buried in the palm and the palm's front edge is
## weighted to the nearest finger, so the webbing follows a curling finger.
## Flexion is +X rotation in each bone's frame (-Z toward the palm, +Y).

const MODELS := "res://assets/models/"
const SCENES := "res://scenes/hands/"

## [bone, parent]. Index order is the skeleton's bone order.
const BONES := [
	["wrist", ""], ["palm", "wrist"], ["palm_ulnar", "palm"],
	["thumb_1", "palm"], ["thumb_2", "thumb_1"], ["thumb_3", "thumb_2"],
	["index_1", "palm"], ["index_2", "index_1"], ["index_3", "index_2"],
	["middle_1", "palm"], ["middle_2", "middle_1"], ["middle_3", "middle_2"],
	["ring_1", "palm_ulnar"], ["ring_2", "ring_1"], ["ring_3", "ring_2"],
	["little_1", "palm_ulnar"], ["little_2", "little_1"], ["little_3", "little_2"],
]
const FINGERS := ["index", "middle", "ring", "little"]
## Right hand. mcp: knuckle joint centre; yaw: splay in degrees (+ turns toward
## the little finger); len: phalanges; w: width at the root.
const FINGER := {
	"index":  {"mcp": Vector3(0.0300, 0.0005, -0.0455), "yaw": -5.0, "len": [0.040, 0.024, 0.0195], "w": 0.0200},
	"middle": {"mcp": Vector3(0.0100, 0.0, -0.0485), "yaw": -1.0, "len": [0.044, 0.027, 0.0205], "w": 0.0206},
	"ring":   {"mcp": Vector3(-0.0102, 0.0005, -0.0458), "yaw": 3.5, "len": [0.041, 0.026, 0.0200], "w": 0.0192},
	"little": {"mcp": Vector3(-0.0290, 0.0015, -0.0395), "yaw": 9.0, "len": [0.032, 0.0195, 0.0180], "w": 0.0170},
}
## Thumb: carpometacarpal joint, rest direction (yaw/pitch) and roll that turns
## the pad toward the fingers, then metacarpal + two phalanges.
const THUMB := {"cmc": Vector3(0.0205, 0.0045, 0.0335), "yaw": -40.0, "pitch": 10.0, "roll": 52.0,
	"len": [0.044, 0.031, 0.0265]}
const WRIST := Vector3(0.0, 0.0, 0.052)
const ULNAR := Vector3(-0.017, 0.0, 0.040)

const SLEEVE_TILT := 22.0        # degrees below horizontal that the forearm trails back

## Skin tint palette (multiplied into the `skin` albedo, which is the palest tone).
const T_BACK := Color(0.88, 0.80, 0.77)
const T_PALM := Color(0.98, 0.93, 0.90)
const T_COLD := Color(0.93, 0.68, 0.64)     # winter-red knuckles and fingertips
const T_NAIL := Color(1.0, 0.95, 0.91)
const FINGER_SIDES := 10
const GLOVE_OFFSET := 0.0018

static func build_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENES))
	var parts := build_kits()
	var right: MeshKit = parts["hand"]
	var glove: MeshKit = parts["glove"]
	var sides := {"right": [right, glove], "left": [right.mirrored_x(), glove.mirrored_x()]}
	for side in sides:
		var hk: MeshKit = sides[side][0]
		var gk: MeshKit = sides[side][1]
		var hm: Mesh = _su().kit_mesh(hk, "hand_" + side)
		var gm: Mesh = _su().kit_mesh(gk, "hand_glove_" + side)
		_save_scene(side, hm, gm)

## Builds the right hand's MeshKits: {"hand": skin + cuff + sleeve, "glove": glove}.
static func build_kits() -> Dictionary:
	var rest := rest_globals(1.0)
	var hand := MeshKit.new()
	var glove := MeshKit.new()
	_palm(hand, glove, rest)
	for f in FINGERS:
		_finger(hand, glove, rest, f)
	_thumb(hand, glove, rest)
	_cuff(hand)
	_sleeve(hand)
	return {"hand": hand, "glove": glove}

# --- skeleton ----------------------------------------------------------------

static func bone_index(bone_name: String) -> int:
	for k in BONES.size():
		if BONES[k][0] == bone_name:
			return k
	return -1

## Global rest transform of every bone, by name. side = 1 right, -1 left.
static func rest_globals(side := 1.0) -> Dictionary:
	var g := {}
	g["wrist"] = Transform3D(Basis(), WRIST)
	g["palm"] = Transform3D(Basis(), WRIST)
	g["palm_ulnar"] = Transform3D(Basis(), ULNAR)
	for f in FINGERS:
		var d: Dictionary = FINGER[f]
		var t := Transform3D(Basis(Vector3.UP, deg_to_rad(d.yaw)), d.mcp)
		var lens: Array = d.len
		for k in 3:
			g["%s_%d" % [f, k + 1]] = t
			t = t * Transform3D(Basis(), Vector3(0, 0, -lens[k]))
	var tb := Basis(Vector3.UP, deg_to_rad(THUMB.yaw)) * Basis(Vector3.RIGHT, deg_to_rad(THUMB.pitch)) \
		* Basis(Vector3.BACK, deg_to_rad(THUMB.roll))
	var tt := Transform3D(tb, THUMB.cmc)
	var tl: Array = THUMB.len
	for k in 3:
		g["thumb_%d" % (k + 1)] = tt
		tt = tt * Transform3D(Basis(), Vector3(0, 0, -tl[k]))
	if side < 0.0:
		var m := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
		for k in g:
			var t: Transform3D = g[k]
			g[k] = Transform3D(m * t.basis * m, Vector3(-t.origin.x, t.origin.y, t.origin.z))
	return g

static func make_skeleton(side := 1.0) -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	var g := rest_globals(side)
	for b in BONES:
		sk.add_bone(b[0])
	for k in BONES.size():
		var par: String = BONES[k][1]
		var gt: Transform3D = g[BONES[k][0]]
		if par != "":
			sk.set_bone_parent(k, bone_index(par))
			sk.set_bone_rest(k, (g[par] as Transform3D).affine_inverse() * gt)
		else:
			sk.set_bone_rest(k, gt)
	sk.reset_bone_poses()
	return sk

static func _save_scene(side: String, hand_mesh: Mesh, glove_mesh: Mesh) -> void:
	var root := Node3D.new()
	root.name = "Hand_" + side
	var sk := make_skeleton(1.0 if side == "right" else -1.0)
	root.add_child(sk)
	var skin := sk.create_skin_from_rest_transforms()
	for pair in [["Hand", hand_mesh, true], ["Glove", glove_mesh, false]]:
		var mi := MeshInstance3D.new()
		mi.name = pair[0]
		mi.mesh = pair[1]
		mi.skin = skin
		mi.skeleton = NodePath("..")
		mi.visible = pair[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sk.add_child(mi)
	_su().save_scene(root, SCENES + "hand_%s.tscn" % side)

## SceneUtil is loaded at run time: it references Interactable (and so the
## autoloads), which would stop headless `-s` tests that use HandAssets'
## shape data from compiling.
static func _su() -> GDScript:
	return load("res://tools/scene_util.gd")

# --- palm shape (shared with the tests) -------------------------------------

## Palm cross-section at z (right hand rest space): [half-width thumb side,
## half-width little side, dorsal half-thickness, palmar half-thickness].
static func palm_section(z: float) -> Array:
	var zs := [0.066, 0.050, 0.034, 0.018, 0.0, -0.020, -0.034, -0.042]
	var wt := [0.0290, 0.0305, 0.0365, 0.0405, 0.0420, 0.0430, 0.0430, 0.0425]
	var wl := [0.0285, 0.0300, 0.0350, 0.0390, 0.0410, 0.0415, 0.0412, 0.0405]
	var bd := [0.0165, 0.0165, 0.0160, 0.0155, 0.0148, 0.0138, 0.0130, 0.0126]
	var bp := [0.0160, 0.0168, 0.0168, 0.0158, 0.0140, 0.0128, 0.0124, 0.0122]
	return [_tab(zs, wt, z), _tab(zs, wl, z), _tab(zs, bd, z), _tab(zs, bp, z)]

## Linear table lookup with smoothstep easing (zs descending).
static func _tab(zs: Array, vs: Array, z: float) -> float:
	if z >= zs[0]:
		return vs[0]
	for k in zs.size() - 1:
		if z >= zs[k + 1]:
			var t: float = (zs[k] - z) / (zs[k] - zs[k + 1])
			t = t * t * (3.0 - 2.0 * t)
			return lerpf(vs[k], vs[k + 1], t)
	return vs[vs.size() - 1]

## Palmar pads: thenar (thumb ball), hypothenar, and a slight hollow.
static func _palm_pads(x: float, z: float) -> float:
	return 0.0058 * _g((x - 0.020) / 0.014) * _g((z - 0.026) / 0.017) \
		+ 0.0030 * _g((x + 0.026) / 0.012) * _g((z - 0.018) / 0.024) \
		+ 0.0016 * _g((z + 0.036) / 0.008) \
		- 0.0016 * _g(x / 0.014) * _g((z + 0.004) / 0.018)

static func _g(x: float) -> float:
	return exp(-x * x)

## < 1 inside the palm's core (rest space, pads ignored), used by the tests to
## check that no fingertip passes through the palm.
static func palm_inside(p: Vector3) -> float:
	if p.z > 0.066 or p.z < -0.045:
		return 9.0
	var s := palm_section(p.z)
	var w: float = s[0] if p.x > 0.0 else s[1]
	var b: float = s[2] if p.y < 0.0 else s[3]
	return pow(absf(p.x) / w, 2.6) + pow(absf(p.y) / b, 2.6)

static func _sp(c: float, e: float) -> float:
	return signf(c) * pow(absf(c), e)

# --- lofted surfaces ---------------------------------------------------------

## Closed loft: rings (equal size) joined into quads, optional poles that cap
## the first / last ring. Normals are smooth (area-weighted). Returns
## {v, n, i} with triangles wound for Godot (clockwise front faces).
static func _loft(rings: Array, centres: PackedVector3Array, pole_start: Variant, pole_end: Variant) -> Dictionary:
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	var n: int = (rings[0] as PackedVector3Array).size()
	for r in rings:
		verts.append_array(r)
	var tri := func(a: int, b: int, c: int, out: Vector3) -> void:
		var cr := (verts[b] - verts[a]).cross(verts[c] - verts[a])
		if cr.dot(out) > 0.0:
			idx.append_array([a, c, b])
		else:
			idx.append_array([a, b, c])
	for k in rings.size() - 1:
		for s in n:
			var a := k * n + s
			var b := k * n + (s + 1) % n
			var c := (k + 1) * n + (s + 1) % n
			var d := (k + 1) * n + s
			var mid := (verts[a] + verts[c]) * 0.5
			var out := mid - (centres[k] + centres[k + 1]) * 0.5
			tri.call(a, b, c, out)
			tri.call(a, c, d, out)
	for e in 2:
		var pole: Variant = pole_start if e == 0 else pole_end
		if pole == null:
			continue
		var ring := 0 if e == 0 else rings.size() - 1
		var nb := centres[1] if e == 0 else centres[rings.size() - 2]
		var axis: Vector3 = (pole as Vector3) - nb
		var pi_ := verts.size()
		verts.append(pole)
		for s in n:
			var a := ring * n + s
			var b := ring * n + (s + 1) % n
			var out := ((verts[a] + verts[b]) * 0.5 - centres[ring]).normalized() + axis.normalized()
			tri.call(pi_, a, b, out)
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	for t in range(0, idx.size(), 3):
		var a := verts[idx[t]]; var b := verts[idx[t + 1]]; var c := verts[idx[t + 2]]
		var fn := (c - a).cross(b - a)      # outward for clockwise winding
		for j in 3:
			norms[idx[t + j]] += fn
	for k in norms.size():
		norms[k] = norms[k].normalized()
	return {"v": verts, "n": norms, "i": idx}

## Pushes a lofted surface out along its normals (the glove over the skin).
static func _inflate(l: Dictionary, by: float) -> Dictionary:
	var v := PackedVector3Array()
	for k in l.v.size():
		v.append(l.v[k] + l.n[k] * by)
	return {"v": v, "n": l.n, "i": l.i}

## Packs per-vertex [[bone, weight], ...] into 4-slot bone/weight arrays.
static func _pack_weights(per_vertex: Array) -> Array:
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	for list in per_vertex:
		var merged := {}
		for bw in list:
			if bw[1] > 0.0001:
				merged[bw[0]] = merged.get(bw[0], 0.0) + bw[1]
		var pairs := []
		for b in merged:
			pairs.append([b, merged[b]])
		pairs.sort_custom(func(p, q): return p[1] > q[1])
		pairs.resize(mini(pairs.size(), 4))
		var total := 0.0
		for p in pairs:
			total += p[1]
		for k in 4:
			if k < pairs.size():
				bones.append(pairs[k][0])
				weights.append(pairs[k][1] / total)
			else:
				bones.append(0)
				weights.append(0.0)
	return [bones, weights]

static func _emit(kit: MeshKit, mat: String, l: Dictionary, cols: PackedColorArray, wts: Array) -> void:
	var packed := _pack_weights(wts)
	kit.emit(mat, l.v, l.n, l.i, cols, PackedVector2Array(), packed[0], packed[1])

# --- palm --------------------------------------------------------------------

static func _palm(hand: MeshKit, glove: MeshKit, rest: Dictionary) -> void:
	var sides := 20
	var zs := [0.066, 0.050, 0.036, 0.026, 0.016, 0.006, -0.004, -0.014, -0.024, -0.032, -0.038]
	var cap := [25.0, 50.0, 72.0]      # front cap ring angles (degrees)
	var cap_len := 0.011
	var rings := []
	var centres := PackedVector3Array()
	var z_last: float = zs[zs.size() - 1]
	var all_z := []
	for z in zs:
		all_z.append([z, 1.0, 0.0])
	for a in cap:
		var r := deg_to_rad(a)
		all_z.append([z_last - cap_len * sin(r), cos(r), sin(r)])
	for zr in all_z:
		var z: float = zr[0]
		var sc: float = zr[1]
		var capw: float = zr[2]
		var sec := palm_section(maxf(z, z_last))
		var ring := PackedVector3Array()
		for s in sides:
			var th := TAU * s / sides
			var c := cos(th); var sn := sin(th)
			var w: float = sec[0] if c > 0.0 else sec[1]
			var b: float = sec[3] if sn > 0.0 else sec[2]
			var x := w * _sp(c, 2.0 / 2.6) * sc
			var y := b * _sp(sn, 2.0 / (2.8 if sn > 0.0 else 2.3)) * sc
			var pz := z
			if sn > 0.0:
				y += _palm_pads(x, z) * pow(sn, 1.5) * sc
				pz -= 0.009 * pow(sn, 2.0) * capw       # palm pad reaches past the knuckles
			else:
				# Metacarpal heads: bumps along the dorsal knuckle line.
				var kn := 0.0
				for f in FINGERS:
					var mcp: Vector3 = FINGER[f].mcp
					kn += _g((x - mcp.x) / 0.0062) * _g((z - mcp.z - 0.006) / 0.009)
				y -= 0.0022 * kn * pow(-sn, 2.0)
			# Knuckle line: the middle knuckle sits furthest forward.
			pz -= 0.006 * capw * (1.0 - clampf(x * x / 0.0016, 0.0, 1.0)) - 0.004 * capw * clampf(-x / 0.04, 0.0, 1.0)
			ring.append(Vector3(x, y, pz))
		rings.append(ring)
		centres.append(Vector3(0, 0, z))
	var front := Vector3(0.002, 0.003, z_last - cap_len - 0.004)
	var l := _loft(rings, centres, null, front)
	var cols := PackedColorArray()
	var wts := []
	for p in l.v:
		cols.append(_palm_tint(p))
		wts.append(_palm_weights(p))
	_emit(hand, "skin", l, cols, wts)
	var gl := _inflate(l, GLOVE_OFFSET)
	var gcols := PackedColorArray()
	for p in l.v:
		gcols.append(Color(1, 1, 1) * lerpf(1.0, 0.82, _g((p.z + 0.05) / 0.01)))
	_emit(glove, "wool_glove", gl, gcols, wts)

static func _palm_tint(p: Vector3) -> Color:
	var sec := palm_section(p.z)
	var b: float = sec[3] if p.y > 0.0 else sec[2]
	var palmar := smoothstep(-0.35, 0.55, p.y / b)
	var c := T_BACK.lerp(T_PALM, palmar)
	# Cold-reddened knuckles on the back, warm flush at the heel of the thumb.
	var kn := 0.0
	for f in FINGERS:
		var mcp: Vector3 = FINGER[f].mcp
		kn += _g((p.x - mcp.x) / 0.007) * _g((p.z - mcp.z - 0.004) / 0.009)
	c = c.lerp(T_COLD, clampf(kn * (1.0 - palmar), 0.0, 1.0) * 0.8)
	c = c.lerp(T_COLD, _g((p.x - 0.022) / 0.012) * _g((p.z - 0.022) / 0.014) * palmar * 0.25)
	# Palm creases and the shade between the finger roots.
	var crease := _g((p.z + 0.020 + p.x * 0.25) / 0.0025) * palmar * 0.12
	crease += _g((p.z + 0.044) / 0.004) * 0.12
	return c * (1.0 - crease)

static func _palm_weights(p: Vector3) -> Array:
	var out := []
	# Finger roots: the front of the palm follows the nearest finger.
	var gs := []
	var gsum := 0.0
	for f in FINGERS:
		var g := _g((p.x - (FINGER[f].mcp as Vector3).x) / 0.0085)
		gs.append(g)
		gsum += g
	var ftotal := 0.0
	for k in FINGERS.size():
		var mcp: Vector3 = FINGER[FINGERS[k]].mcp
		var ramp := smoothstep(mcp.z + 0.011, mcp.z - 0.002, p.z)
		if p.y < 0.0:
			ramp *= 0.75
		var w: float = ramp * gs[k] / gsum
		out.append([bone_index(FINGERS[k] + "_1"), w])
		ftotal += w
	var rest := 1.0 - ftotal
	# Thumb ball moves with the thumb metacarpal.
	var th := 0.85 * _g((p.x - 0.024) / 0.012) * _g((p.z - 0.020) / 0.016) * smoothstep(-0.012, 0.006, p.y)
	th = minf(th, 0.85)
	# Ring/little side cups with the ulnar metacarpals.
	var ul := smoothstep(-0.003, -0.030, p.x) * smoothstep(0.045, 0.0, p.z) * 0.9
	var wr := smoothstep(0.040, 0.062, p.z)
	var others := th + ul
	var scale := 1.0
	if others > 0.9:
		scale = 0.9 / others
	th *= scale; ul *= scale
	var palm := maxf(0.0, 1.0 - th - ul)
	out.append([bone_index("thumb_1"), rest * th])
	out.append([bone_index("palm_ulnar"), rest * ul])
	out.append([bone_index("palm"), rest * palm * (1.0 - wr)])
	out.append([bone_index("wrist"), rest * palm * wr])
	return out

# --- fingers + thumb ---------------------------------------------------------

## A finger-like chain: a straight rest tube along the first bone's -Z, with
## knuckle bulges, a pad, a flattened nail bed and a rounded tip.
## prof: callable(s) -> [half-width, half-thickness]; joints at s = 0, j1, j2.
static func _chain(base: Transform3D, s0: float, length: float, joints: Array, prof: Callable,
		sides: int, start_closed: bool) -> Dictionary:
	var ss := []
	var bounds := [s0] + joints + [length]
	for k in bounds.size() - 1:
		var a: float = bounds[k]
		var b: float = bounds[k + 1]
		var fr := [0.0, 0.2, 0.5, 0.8] if k > 0 else [0.0, 0.34, 0.67]
		for f in fr:
			ss.append(lerpf(a, b, f))
	# Tip: body ends one tip radius early, then a rounded cap.
	var tip_r: float = prof.call(length)[1] * 1.05
	var body_end := length - tip_r
	var kept := []
	for s in ss:
		if s < body_end - 0.002:
			kept.append([s, 1.0, 0.0])
	for a in [0.0, 32.0, 58.0, 78.0]:
		var r := deg_to_rad(a)
		kept.append([body_end + tip_r * sin(r), cos(r), sin(r)])
	var rings := []
	var centres := PackedVector3Array()
	var params := []
	for e in kept:
		var s: float = e[0]
		var sc: float = e[1]
		var capf: float = e[2]
		var ab: Array = prof.call(minf(s, body_end))
		var ring := PackedVector3Array()
		var cy: float = -0.22 * ab[1] * capf        # the tip apex sits toward the nail
		for k in sides:
			var th := TAU * (k + 0.5) / sides
			var c := cos(th); var sn := sin(th)
			var hw: float = ab[0]
			var hh: float = ab[1]
			var f := 1.0
			for j in joints:
				var dj: float = s - j
				if sn < 0.0:
					f += 0.07 * _g(dj / 0.0055) * pow(-sn, 1.5)        # knuckle
				else:
					f -= 0.06 * _g(dj / 0.0032) * pow(sn, 2.0)         # crease
			if s > joints[joints.size() - 1]:
				var u: float = (s - joints[joints.size() - 1]) / (length - joints[joints.size() - 1])
				if sn > 0.0:
					f += 0.07 * sin(clampf(u, 0.0, 1.0) * PI) * pow(sn, 1.5)   # fingertip pad
				else:
					f -= 0.12 * smoothstep(0.25, 0.6, u) * pow(-sn, 3.0)        # flat nail bed
			var x := hw * _sp(c, 2.0 / 2.3) * f * sc
			var y: float = hh * _sp(sn, 2.0 / 2.3) * f * sc + cy
			ring.append(base * Vector3(x, y, -s))
		rings.append(ring)
		centres.append(base * Vector3(0, cy, -s))
		params.append(s)
	var tip_c := base * Vector3(0, -0.22 * tip_r, -length)
	var pole_s: Variant = null
	if start_closed:
		pole_s = base * Vector3(0, 0, -s0 + 0.004)
	var l := _loft(rings, centres, pole_s, tip_c)
	# Per-vertex arc parameter and angle around the tube (for weights / tints).
	var vs := []
	for r in rings.size():
		for k in sides:
			vs.append([params[r], sin(TAU * (k + 0.5) / sides), cos(TAU * (k + 0.5) / sides)])
	if start_closed:
		vs.append([s0, 0.0, 0.0])
	vs.append([length, -0.3, 0.0])
	l["s"] = vs
	return l

## Weights along a 3-joint chain: parent below joint 0, bones b0..b2 after.
static func _chain_weights(s: float, joints: Array, blend: Array, parent_w: Array, bones: Array) -> Array:
	var w0 := smoothstep(-blend[0], blend[0], s - joints[0])
	var w1 := smoothstep(-blend[1], blend[1], s - joints[1])
	var w2 := smoothstep(-blend[2], blend[2], s - joints[2])
	var out := []
	for pw in parent_w:
		out.append([pw[0], pw[1] * (1.0 - w0)])
	out.append([bones[0], w0 * (1.0 - w1)])
	out.append([bones[1], w1 * (1.0 - w2)])
	out.append([bones[2], w2])
	return out

static func _finger(hand: MeshKit, glove: MeshKit, rest: Dictionary, f: String) -> void:
	var d: Dictionary = FINGER[f]
	var lens: Array = d.len
	var base: Transform3D = rest[f + "_1"]
	var j1: float = lens[0]
	var j2: float = lens[0] + lens[1]
	var length: float = j2 + lens[2]
	var w: float = d.w
	var prof := func(s: float) -> Array:
		var u := clampf(s / length, 0.0, 1.0)
		var hw := w * 0.5 * lerpf(1.0, 0.80, u)
		return [hw, hw * lerpf(0.93, 0.86, u)]
	var l := _chain(base, -0.013, length, [0.0, j1, j2], prof, FINGER_SIDES, true)
	var parent := "palm_ulnar" if f == "ring" or f == "little" else "palm"
	var bones := [bone_index(f + "_1"), bone_index(f + "_2"), bone_index(f + "_3")]
	var cols := PackedColorArray()
	var wts := []
	for k in l.v.size():
		var sv: Array = l.s[k]
		var s: float = sv[0]
		var sn: float = sv[1]
		var cs: float = sv[2]
		wts.append(_chain_weights(s, [0.0, j1, j2], [0.0085, 0.0048, 0.0042], [[bone_index(parent), 1.0]], bones))
		cols.append(_finger_tint(s, sn, cs, [0.0, j1, j2], length))
	_emit(hand, "skin", l, cols, wts)
	_glove_part(glove, l, wts, j1 * 0.42)

static func _finger_tint(s: float, sn: float, cs: float, joints: Array, length: float) -> Color:
	var palmar := smoothstep(-0.5, 0.6, sn)
	var c := T_BACK.lerp(T_PALM, palmar)
	var cold := 0.0
	for k in range(1, joints.size()):
		cold += _g((s - joints[k]) / 0.005) * (1.0 - palmar) * 0.6
	cold += smoothstep(length - 0.014, length - 0.002, s) * 0.75     # fingertips
	c = c.lerp(T_COLD, clampf(cold, 0.0, 0.85))
	var u: float = (s - joints[joints.size() - 1]) / (length - joints[joints.size() - 1])
	var nail := smoothstep(0.3, 0.5, u) * smoothstep(-0.45, -0.8, sn) * smoothstep(0.85, 0.35, absf(cs))
	c = c.lerp(T_NAIL, nail * 0.9)
	var crease := 0.0
	for j in joints:
		crease += _g((s - j) / 0.0022) * palmar * 0.12
	# Shade where neighbouring fingers press together.
	crease += smoothstep(0.85, 1.0, absf(cs)) * smoothstep(0.01, -0.01, s - joints[1]) * 0.08
	return c * (1.0 - crease)

static func _thumb(hand: MeshKit, glove: MeshKit, rest: Dictionary) -> void:
	var tl: Array = THUMB.len
	var base: Transform3D = rest["thumb_1"]
	var j1: float = tl[0]
	var j2: float = tl[0] + tl[1]
	var length: float = j2 + tl[2]
	var prof := func(s: float) -> Array:
		# Thick at the buried base (the thenar mass carries on into the palm).
		var hw := lerpf(0.0132, 0.0118, smoothstep(0.012, j1, s))
		hw = lerpf(hw, 0.0106, smoothstep(j1, length, s))
		return [hw, hw * lerpf(0.92, 0.84, smoothstep(0.0, length, s))]
	var l := _chain(base, 0.010, length, [0.018, j1, j2], prof, 12, true)
	var bones := [bone_index("thumb_1"), bone_index("thumb_2"), bone_index("thumb_3")]
	var cols := PackedColorArray()
	var wts := []
	for k in l.v.size():
		var sv: Array = l.s[k]
		var s: float = sv[0]
		wts.append(_chain_weights(s, [0.012, j1, j2], [0.010, 0.0055, 0.0045], [[bone_index("palm"), 1.0]], bones))
		cols.append(_finger_tint(s, sv[1], sv[2], [0.0, j1, j2], length))
	_emit(hand, "skin", l, cols, wts)
	_glove_part(glove, l, wts, j1 + tl[1] * 0.35)

## Fingerless glove over one chain: the loft rings up to `s_end`, inflated,
## with the open edge rolled in toward the skin.
static func _glove_part(glove: MeshKit, l: Dictionary, wts: Array, s_end: float) -> void:
	var v := PackedVector3Array(); var n := PackedVector3Array(); var idx := PackedInt32Array()
	var gw := []
	var remap := {}
	var last_s := -INF
	for k in l.v.size():
		var s: float = l.s[k][0]
		if s <= s_end:
			last_s = maxf(last_s, s)
	for k in l.v.size():
		var s: float = l.s[k][0]
		if s > last_s:
			continue
		remap[k] = v.size()
		var by := GLOVE_OFFSET * (0.35 if s >= last_s - 0.0001 else 1.0)
		v.append(l.v[k] + l.n[k] * by)
		n.append(l.n[k])
		gw.append(wts[k])
	for t in range(0, l.i.size(), 3):
		var a: int = l.i[t]; var b: int = l.i[t + 1]; var c: int = l.i[t + 2]
		if remap.has(a) and remap.has(b) and remap.has(c):
			idx.append_array([remap[a], remap[b], remap[c]])
	var cols := PackedColorArray()
	for k in v.size():
		cols.append(Color(1, 1, 1))
	_emit(glove, "wool_glove", {"v": v, "n": n, "i": idx}, cols, gw)

# --- cuff + sleeve -----------------------------------------------------------

## Knitted storm cuff hugging the wrist, ribbed, with a rolled front edge.
static func _cuff(hand: MeshKit) -> void:
	var sides := 24
	# [z, radius scale, extra out]: inner lip -> rolled edge -> body into the sleeve.
	var prof := [[0.056, 0.86], [0.0505, 0.94], [0.0485, 1.0], [0.051, 1.04],
		[0.060, 1.035], [0.070, 1.04], [0.084, 1.06]]
	var rings := []
	var centres := PackedVector3Array()
	for pr in prof:
		var ring := PackedVector3Array()
		var z: float = pr[0]
		for s in sides:
			var th := TAU * s / sides
			var rib := 1.0 + (0.045 if s % 2 == 0 else -0.01)
			var sc: float = pr[1] * rib
			ring.append(Vector3(cos(th) * 0.0345 * sc, sin(th) * 0.0238 * sc + 0.0006, z))
		rings.append(ring)
		centres.append(Vector3(0, 0.0006, z))
	var l := _loft(rings, centres, null, null)
	var cols := PackedColorArray()
	var wts := []
	for k in l.v.size():
		var p: Vector3 = l.v[k]
		var ring: int = k / sides
		var front := 1.0 - smoothstep(0.053, 0.066, p.z)
		cols.append(Color(1, 1, 1) * (0.78 if ring == 0 else (0.9 if (k % sides) % 2 == 1 else 1.0)))
		wts.append([[bone_index("palm"), 0.45 * front], [bone_index("wrist"), 1.0 - 0.45 * front]])
	_emit(hand, "wool_knit", l, cols, wts)

## Oilskin sleeve: stiff waxed cotton with a hem and chunky painterly folds,
## trailing back and down from the cuff. Rigid on the wrist bone.
static func _sleeve(hand: MeshKit) -> void:
	var sides := 16
	var dirv := Vector3(0.0, -sin(deg_to_rad(SLEEVE_TILT)), cos(deg_to_rad(SLEEVE_TILT)))
	var start := Vector3(0.0, 0.001, 0.070)
	var steps := [[-0.010, 0.90], [-0.004, 0.97], [0.0, 1.0], [0.018, 1.03], [0.045, 1.04],
		[0.085, 1.12], [0.135, 1.21], [0.21, 1.32], [0.31, 1.42], [0.42, 1.48]]
	var rings := []
	var centres := PackedVector3Array()
	for st in steps:
		var t: float = st[0]
		# The hem sits level with the cuff; the forearm bends down behind it.
		var bend := smoothstep(0.0, 0.08, t)
		var c := start + Vector3(0, 0, t).lerp(dirv * t, bend)
		var ax := Vector3(0, 0, 1).lerp(dirv, bend).normalized()
		var side := Vector3.RIGHT
		var up := ax.cross(side).normalized()
		var ring := PackedVector3Array()
		for s in sides:
			var th := TAU * s / sides
			var r: float = st[1]
			var tt := maxf(t, 0.0)
			# Folds: a few long creases plus compression rings near the wrist.
			r *= 1.0 + 0.055 * sin(3.0 * th + 1.3 + tt * 9.0) * smoothstep(0.0, 0.05, tt)
			r *= 1.0 + 0.03 * sin(5.0 * th - tt * 14.0) * smoothstep(0.01, 0.06, tt) * (1.0 - smoothstep(0.15, 0.3, tt))
			r *= 1.0 + 0.04 * sin(tt * 75.0) * smoothstep(0.012, 0.03, tt) * (1.0 - smoothstep(0.08, 0.14, tt))
			var off := side * cos(th) * 0.043 * r + up * sin(th) * 0.033 * r
			ring.append(c + off)
		rings.append(ring)
		centres.append(c)
	var l := _loft(rings, centres, null, null)
	var cols := PackedColorArray()
	for k in l.v.size():
		var ring: int = k / sides
		# Hem edge and the inside of the opening read darker.
		cols.append(Color(1, 1, 1) * (0.55 if ring == 0 else (0.85 if ring == 1 else 1.0)))
	var wts := []
	for k in l.v.size():
		wts.append([[bone_index("wrist"), 1.0]])
	_emit(hand, "oilskin", l, cols, wts)
