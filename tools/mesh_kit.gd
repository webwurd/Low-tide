class_name MeshKit extends RefCounted
## Builds medium-poly, soft-bevelled meshes from primitives and merges them
## into one ArrayMesh with one surface per material (few draw calls). Used by
## the asset factory to author models in code; output is saved as .res.
##
##   var k := MeshKit.new()
##   k.push(Transform3D(Basis(), Vector3(0, 1, 0)))
##   k.box("wood", Vector3(2, 0.1, 0.3), Vector3.ZERO, 0.02)
##   k.pop()
##   var mesh := k.commit()
##
## Vertex colour = `tint` x ambient occlusion (darker near `ao_ground_y`);
## the painterly shader multiplies it into albedo.

const MAT_DIR := "res://assets/materials/"

var tint := Color(1, 1, 1)
var ao_ground_y := 0.0
var ao_range := 0.0          ## 0 disables ground AO
var ao_min := 0.6
var _stack: Array[Transform3D] = [Transform3D.IDENTITY]
var _surf := {}              # mat -> {v, n, c, i}

# --- transform stack ---------------------------------------------------------

func push(t: Transform3D) -> void:
	_stack.append(_stack.back() * t)

func pop() -> void:
	if _stack.size() > 1:
		_stack.pop_back()

func at(pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot).scaled(scl), pos)

# --- core emit ---------------------------------------------------------------

func _buf(mat: String) -> Dictionary:
	if not _surf.has(mat):
		_surf[mat] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(),
			"u": PackedVector2Array(), "i": PackedInt32Array()}
	return _surf[mat]

## Appends an indexed triangle list (local space) through the current transform.
func emit(mat: String, verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array,
		cols := PackedColorArray(), uvs := PackedVector2Array()) -> void:
	var b := _buf(mat)
	var t: Transform3D = _stack.back()
	var nb := t.basis.inverse().transposed()
	var base: int = b.v.size()
	for k in verts.size():
		var p := t * verts[k]
		b.v.append(p)
		b.n.append((nb * norms[k]).normalized())
		var c := tint
		if cols.size() > 0:
			c = c * cols[k]
		if ao_range > 0.0:
			var ao := lerpf(ao_min, 1.0, clampf((p.y - ao_ground_y) / ao_range, 0.0, 1.0))
			c = Color(c.r * ao, c.g * ao, c.b * ao)
		b.c.append(c)
		b.u.append(uvs[k] if uvs.size() > k else Vector2.ZERO)
	for k in idx:
		b.i.append(base + k)

## Merges everything into an ArrayMesh, one surface per material, with LODs.
func commit(lods := true) -> ArrayMesh:
	var im := ImporterMesh.new()
	for mat in _surf:
		var b: Dictionary = _surf[mat]
		if b.i.is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = b.v
		arr[Mesh.ARRAY_NORMAL] = b.n
		arr[Mesh.ARRAY_COLOR] = b.c
		arr[Mesh.ARRAY_TEX_UV] = b.u
		arr[Mesh.ARRAY_INDEX] = b.i
		var m: Material = null
		var p: String = MAT_DIR + mat + ".tres"
		if ResourceLoader.exists(p):
			m = load(p)
		else:
			push_warning("MeshKit: missing material " + p)
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, m, mat)
	if lods:
		im.generate_lods(25.0, 60.0, [])
	return im.get_mesh()

func tri_count() -> int:
	var n := 0
	for mat in _surf:
		n += _surf[mat].i.size() / 3
	return n

# --- primitives --------------------------------------------------------------

## Rounded box. `bevel` is the corner radius; `seg` rings around each edge.
func box(mat: String, size: Vector3, center := Vector3.ZERO, bevel := 0.03, seg := 1) -> void:
	var h := size * 0.5
	bevel = minf(bevel, minf(h.x, minf(h.y, h.z)) * 0.95)
	# Grid lines across each face: `seg` steps through each bevel zone. Points
	# are pushed onto the rounded surface below (clamp + offset along normal).
	var coords := func(e: float) -> PackedFloat32Array:
		var c := PackedFloat32Array()
		for k in seg + 1:
			c.append(-e + bevel * k / seg)
		for k in seg + 1:
			c.append(e - bevel + bevel * k / seg)
		return c
	var cx: PackedFloat32Array = coords.call(h.x)
	var cy: PackedFloat32Array = coords.call(h.y)
	var cz: PackedFloat32Array = coords.call(h.z)
	var inner := h - Vector3(bevel, bevel, bevel)
	var faces := [
		[Vector3.RIGHT, 2, 1], [Vector3.LEFT, 2, 1], [Vector3.UP, 0, 2],
		[Vector3.DOWN, 0, 2], [Vector3.BACK, 0, 1], [Vector3.FORWARD, 0, 1]]
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var idx := PackedInt32Array()
	var axes := [cx, cy, cz]
	for f in faces:
		var fn: Vector3 = f[0]
		var ua: int = f[1]
		var va: int = f[2]
		var us: PackedFloat32Array = axes[ua]
		var vs: PackedFloat32Array = axes[va]
		var start := verts.size()
		for j in vs.size():
			for i in us.size():
				var p := Vector3(fn.x * h.x, fn.y * h.y, fn.z * h.z)
				p[ua] = us[i]
				p[va] = vs[j]
				var q := p.clamp(-inner, inner)
				var d := p - q
				var n := d.normalized() if d.length() > 0.00001 else fn
				verts.append(center + q + n * bevel)
				norms.append(n)
		var w := us.size()
		for j in vs.size() - 1:
			for i in w - 1:
				var a := start + j * w + i
				var quad := [a, a + 1, a + w + 1, a + w]
				# Wind so the face points along fn.
				var e1 := verts[quad[1]] - verts[quad[0]]
				var e2 := verts[quad[2]] - verts[quad[0]]
				if e1.cross(e2).dot(fn) < 0.0:
					idx.append_array([quad[0], quad[1], quad[2], quad[0], quad[2], quad[3]])
				else:
					idx.append_array([quad[0], quad[2], quad[1], quad[0], quad[3], quad[2]])
	emit(mat, verts, norms, idx)

## Surface of revolution around +Y. `profile` = (radius, y) from bottom to top.
## Each profile segment gets its own ring pair (crisp bands); set `smooth` to
## share normals between segments for soft curves.
func lathe(mat: String, profile: PackedVector2Array, sides := 24, smooth := false,
		cap_bottom := false, cap_top := false, phase := 0.0) -> void:
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var idx := PackedInt32Array()
	var uvs := PackedVector2Array()
	var y_lo := INF; var y_hi := -INF
	for pr in profile:
		y_lo = minf(y_lo, pr.y); y_hi = maxf(y_hi, pr.y)
	var y_span := maxf(0.0001, y_hi - y_lo)
	var seg_n := PackedVector2Array()
	for k in profile.size() - 1:
		var d := profile[k + 1] - profile[k]
		seg_n.append(Vector2(d.y, -d.x).normalized())
	for k in profile.size() - 1:
		var n0 := seg_n[k]
		var n1 := seg_n[k]
		if smooth:
			if k > 0: n0 = (seg_n[k - 1] + seg_n[k]).normalized()
			if k < seg_n.size() - 1: n1 = (seg_n[k] + seg_n[k + 1]).normalized()
		var start := verts.size()
		for s in sides + 1:
			var a := phase + TAU * s / sides
			var dir := Vector3(cos(a), 0.0, sin(a))
			for e in 2:
				var pr := profile[k + e]
				var pn := n0 if e == 0 else n1
				verts.append(dir * pr.x + Vector3(0, pr.y, 0))
				norms.append((dir * pn.x + Vector3(0, pn.y, 0)).normalized())
				uvs.append(Vector2(float(s) / sides, 1.0 - (pr.y - y_lo) / y_span))
		for s in sides:
			var a0 := start + s * 2
			idx.append_array([a0, a0 + 3, a0 + 1, a0, a0 + 2, a0 + 3])
	if cap_bottom:
		_cap(verts, norms, idx, profile[0], sides, phase, false)
	if cap_top:
		_cap(verts, norms, idx, profile[profile.size() - 1], sides, phase, true)
	emit(mat, verts, norms, idx, PackedColorArray(), uvs)

func _cap(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array, pr: Vector2, sides: int, phase: float, top: bool) -> void:
	var c := verts.size()
	var n := Vector3.UP if top else Vector3.DOWN
	verts.append(Vector3(0, pr.y, 0)); norms.append(n)
	for s in sides + 1:
		var a := phase + TAU * s / sides
		verts.append(Vector3(cos(a) * pr.x, pr.y, sin(a) * pr.x)); norms.append(n)
	for s in sides:
		if top:
			idx.append_array([c, c + 1 + s, c + 2 + s])
		else:
			idx.append_array([c, c + 2 + s, c + 1 + s])

func cylinder(mat: String, r_bottom: float, r_top: float, height: float, sides := 16, y0 := 0.0, caps := true) -> void:
	lathe(mat, PackedVector2Array([Vector2(r_bottom, y0), Vector2(r_top, y0 + height)]), sides, false, caps, caps)

## A softened cylinder: small chamfer rings top and bottom catch the light.
func soft_cylinder(mat: String, r: float, height: float, sides := 16, chamfer := 0.02, y0 := 0.0, taper := 1.0) -> void:
	var rt := r * taper
	lathe(mat, PackedVector2Array([
		Vector2(0.0, y0), Vector2(r - chamfer, y0), Vector2(r, y0 + chamfer),
		Vector2(rt, y0 + height - chamfer), Vector2(rt - chamfer, y0 + height), Vector2(0.0, y0 + height)]),
		sides, true)

## A tube along a polyline (rope, rails, pipes).
func tube(mat: String, path: PackedVector3Array, radius: float, sides := 8) -> void:
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var idx := PackedInt32Array()
	var up := Vector3.UP
	for k in path.size():
		var fwd: Vector3
		if k == 0: fwd = path[1] - path[0]
		elif k == path.size() - 1: fwd = path[k] - path[k - 1]
		else: fwd = path[k + 1] - path[k - 1]
		fwd = fwd.normalized()
		if absf(fwd.dot(up)) > 0.95:
			up = Vector3.RIGHT
		var side := fwd.cross(up).normalized()
		var nup := side.cross(fwd).normalized()
		for s in sides + 1:
			var a := TAU * s / sides
			var n := side * cos(a) + nup * sin(a)
			verts.append(path[k] + n * radius)
			norms.append(n)
	var ring := sides + 1
	for k in path.size() - 1:
		for s in sides:
			var a0 := k * ring + s
			idx.append_array([a0, a0 + ring + 1, a0 + ring, a0, a0 + 1, a0 + ring + 1])
	emit(mat, verts, norms, idx)

## Extrudes a 2D polygon (XY plane, CCW) along Z, centred on z=0.
func extrude(mat: String, poly: PackedVector2Array, depth: float, cap_mat := "") -> void:
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var idx := PackedInt32Array()
	var hz := depth * 0.5
	var tri := Geometry2D.triangulate_polygon(poly)
	for side in [1.0, -1.0]:
		var start := verts.size()
		for p in poly:
			verts.append(Vector3(p.x, p.y, hz * side)); norms.append(Vector3(0, 0, side))
		for k in range(0, tri.size(), 3):
			if side > 0.0:
				idx.append_array([start + tri[k], start + tri[k + 2], start + tri[k + 1]])
			else:
				idx.append_array([start + tri[k], start + tri[k + 1], start + tri[k + 2]])
	if cap_mat != "" and cap_mat != mat:
		emit(cap_mat, verts, norms, idx)
		verts.clear(); norms.clear(); idx.clear()
	var ccw := Geometry2D.is_polygon_clockwise(poly) == false
	for k in poly.size():
		var a := poly[k]
		var b := poly[(k + 1) % poly.size()]
		var e := (b - a).normalized()
		var n2 := Vector2(e.y, -e.x) if ccw else Vector2(-e.y, e.x)
		var n := Vector3(n2.x, n2.y, 0)
		var s := verts.size()
		verts.append_array([Vector3(a.x, a.y, hz), Vector3(b.x, b.y, hz), Vector3(b.x, b.y, -hz), Vector3(a.x, a.y, -hz)])
		norms.append_array([n, n, n, n])
		if ccw:
			idx.append_array([s, s + 1, s + 2, s, s + 2, s + 3])
		else:
			idx.append_array([s, s + 2, s + 1, s, s + 3, s + 2])
	emit(mat, verts, norms, idx)

## Single quad (a,b,c,d counter-clockwise seen from the front, starting
## bottom-left). UVs map the full texture upright onto it.
func quad(mat: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, two_sided := false) -> void:
	var n := (b - a).cross(c - a).normalized()
	var uv := PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	emit(mat, PackedVector3Array([a, b, c, d]), PackedVector3Array([n, n, n, n]), PackedInt32Array([0, 2, 1, 0, 3, 2]), PackedColorArray(), uv)
	if two_sided:
		emit(mat, PackedVector3Array([a, b, c, d]), PackedVector3Array([-n, -n, -n, -n]), PackedInt32Array([0, 1, 2, 0, 2, 3]))

## Chiselled rock: an icosphere cut by random planes (flat, faceted faces like
## split granite) with soft noise; smooth normals give rounded edges.
func rock(mat: String, rng_seed: int, radius := 1.0, squash := Vector3(1.0, 0.7, 1.0), subdiv := 2, cuts := 9) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var ico := _icosphere(subdiv)
	var verts: PackedVector3Array = ico[0]
	var idx: PackedInt32Array = ico[1]
	var planes := []
	for c in cuts:
		var n := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1), rng.randf_range(-1, 1)).normalized()
		planes.append([n, rng.randf_range(0.62, 0.9)])
	planes.append([Vector3.DOWN, 0.45])   # flat-ish base
	var fn := FastNoiseLite.new()
	fn.seed = rng_seed
	fn.frequency = 1.4
	for k in verts.size():
		var p := verts[k]
		p *= 1.0 + fn.get_noise_3dv(p) * 0.12
		for pl in planes:
			var pn: Vector3 = pl[0]
			var d: float = pl[1]
			var over := p.dot(pn) - d
			if over > 0.0:
				p -= pn * over
		verts[k] = p * squash * radius
	# Smooth normals (area-weighted).
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	for k in range(0, idx.size(), 3):
		var a := verts[idx[k]]; var b := verts[idx[k + 1]]; var c := verts[idx[k + 2]]
		var fnrm := (c - a).cross(b - a)
		for j in 3:
			norms[idx[k + j]] += fnrm
	for k in norms.size():
		norms[k] = norms[k].normalized()
	emit(mat, verts, norms, idx)

static func _icosphere(subdiv: int) -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v := PackedVector3Array([
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)])
	for k in v.size():
		v[k] = v[k].normalized()
	var f := PackedInt32Array([0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2,
		10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1])
	for s in subdiv:
		var mid := {}
		var nf := PackedInt32Array()
		for k in range(0, f.size(), 3):
			var a := f[k]; var b := f[k + 1]; var c := f[k + 2]
			var ab := _mid(v, mid, a, b); var bc := _mid(v, mid, b, c); var ca := _mid(v, mid, c, a)
			nf.append_array([a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca])
		f = nf
	# Godot front faces are clockwise: flip winding.
	for k in range(0, f.size(), 3):
		var tmp := f[k + 1]; f[k + 1] = f[k + 2]; f[k + 2] = tmp
	return [v, f]

static func _mid(v: PackedVector3Array, cache: Dictionary, a: int, b: int) -> int:
	var key := mini(a, b) * 100000 + maxi(a, b)
	if cache.has(key):
		return cache[key]
	v.append(((v[a] + v[b]) * 0.5).normalized())
	cache[key] = v.size() - 1
	return v.size() - 1
