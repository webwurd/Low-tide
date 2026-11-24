class_name TextureKit
## Paints the game's tileable textures into res://assets/textures/ as PNGs.
## Detail textures are *multipliers* centred on ~0.5 (the painterly shader
## doubles them), so one texture serves many tints. Each gets a matching
## normal map derived from a height field. Everything tiles seamlessly.
## Run via tools/build_assets.sh; output is committed like painted art.

const OUT := "res://assets/textures/"
const N := 512

static func build_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var jobs := {
		"plaster": _plaster, "stone_courses": _stone_courses, "clapboard": _clapboard,
		"shingle": _shingle, "wood": _wood, "granite": _granite, "sand": _sand,
		"grass": _grass, "moss": _moss, "rust": _rust, "fabric": _fabric, "bark": _bark,
		"water": _water, "foam": _foam,
	}
	for name in jobs:
		var t := Time.get_ticks_msec()
		var res: Array = jobs[name].call()
		_save_rgb(OUT + name + "_albedo.png", res[0], N)
		_save_normal(OUT + name + "_normal.png", res[1], N, res[2])
		print("  texture %s (%d ms)" % [name, Time.get_ticks_msec() - t])
	_save_macro()
	_grass_card()
	_paper("tide_table_paper", true)
	_paper("logbook_page", false)
	_chart()
	print("  textures done")

# --- noise helpers -----------------------------------------------------------

static func _noise(seed: int, freq: float, octaves := 4, w := N, h := N,
		type := FastNoiseLite.TYPE_SIMPLEX_SMOOTH, cell_ret := -1) -> PackedFloat32Array:
	var fn := FastNoiseLite.new()
	fn.seed = seed
	fn.noise_type = type
	fn.frequency = freq
	fn.fractal_octaves = octaves
	if octaves <= 1:
		fn.fractal_type = FastNoiseLite.FRACTAL_NONE
	if cell_ret >= 0:
		fn.cellular_return_type = cell_ret
		fn.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	var img := fn.get_seamless_image(w, h, false, false, 0.1, true)
	img.convert(Image.FORMAT_L8)
	var data := img.get_data()
	var out := PackedFloat32Array()
	out.resize(w * h)
	for i in w * h:
		out[i] = data[i] / 255.0
	return out

## Bilinear sample with wrap-around (keeps stretched noise seamless).
static func _s(a: PackedFloat32Array, w: int, h: int, x: float, y: float) -> float:
	x = fposmod(x, w); y = fposmod(y, h)
	var x0 := int(x); var y0 := int(y)
	var x1 := (x0 + 1) % w; var y1 := (y0 + 1) % h
	var fx := x - x0; var fy := y - y0
	var a0 := lerpf(a[y0 * w + x0], a[y0 * w + x1], fx)
	var a1 := lerpf(a[y1 * w + x0], a[y1 * w + x1], fx)
	return lerpf(a0, a1, fy)

static func _hash(i: int, j := 0) -> float:
	var n := (i * 374761393 + j * 668265263) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float(n % 100000) / 100000.0

static func _save_rgb(path: String, col: PackedColorArray, size: int) -> void:
	var bytes := PackedByteArray()
	bytes.resize(size * size * 3)
	for i in size * size:
		var c := col[i]
		bytes[i * 3] = clampi(int(c.r * 255.0 + 0.5), 0, 255)
		bytes[i * 3 + 1] = clampi(int(c.g * 255.0 + 0.5), 0, 255)
		bytes[i * 3 + 2] = clampi(int(c.b * 255.0 + 0.5), 0, 255)
	var img := Image.create_from_data(size, size, false, Image.FORMAT_RGB8, bytes)
	img.save_png(ProjectSettings.globalize_path(path))

static func _save_rgba(path: String, col: PackedColorArray, w: int, h: int) -> void:
	var bytes := PackedByteArray()
	bytes.resize(w * h * 4)
	for i in w * h:
		var c := col[i]
		bytes[i * 4] = clampi(int(c.r * 255.0 + 0.5), 0, 255)
		bytes[i * 4 + 1] = clampi(int(c.g * 255.0 + 0.5), 0, 255)
		bytes[i * 4 + 2] = clampi(int(c.b * 255.0 + 0.5), 0, 255)
		bytes[i * 4 + 3] = clampi(int(c.a * 255.0 + 0.5), 0, 255)
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)
	img.save_png(ProjectSettings.globalize_path(path))

## Height field -> tangent-space normal map (OpenGL / Y+), wrapping at edges.
static func _save_normal(path: String, hgt: PackedFloat32Array, size: int, strength: float) -> void:
	var bytes := PackedByteArray()
	bytes.resize(size * size * 3)
	for y in size:
		var ym := ((y - 1 + size) % size) * size
		var yp := ((y + 1) % size) * size
		var yr := y * size
		for x in size:
			var dx := hgt[yr + (x + 1) % size] - hgt[yr + (x - 1 + size) % size]
			var dy := hgt[yp + x] - hgt[ym + x]
			var n := Vector3(-dx * strength, dy * strength, 1.0).normalized()
			var i := (yr + x) * 3
			bytes[i] = int((n.x * 0.5 + 0.5) * 255.0)
			bytes[i + 1] = int((n.y * 0.5 + 0.5) * 255.0)
			bytes[i + 2] = int((n.z * 0.5 + 0.5) * 255.0)
	var img := Image.create_from_data(size, size, false, Image.FORMAT_RGB8, bytes)
	img.save_png(ProjectSettings.globalize_path(path))

static func _arrays() -> Array:
	var c := PackedColorArray(); c.resize(N * N)
	var h := PackedFloat32Array(); h.resize(N * N)
	return [c, h]

static func _v(v: float, tint := Color(1, 1, 1)) -> Color:
	return Color(v * tint.r, v * tint.g, v * tint.b)

# --- detail textures ----------------------------------------------------------

static func _plaster() -> Array:
	var a := _arrays()
	var n1 := _noise(11, 0.006, 4)
	var n2 := _noise(12, 0.05, 3)
	for i in N * N:
		var v := 0.5 + (n1[i] - 0.5) * 0.12 + (n2[i] - 0.5) * 0.05
		a[0][i] = _v(v, Color(1.0, 0.99, 0.97))
		a[1][i] = n1[i] * 0.5 + n2[i] * 0.5
	return [a[0], a[1], 1.2]

static func _stone_courses() -> Array:
	# Whitewashed stone: 8 courses per tile, staggered blocks, soft mortar,
	# rain streaks running down from each course.
	var a := _arrays()
	var n1 := _noise(21, 0.02, 3)
	var streak := _noise(22, 0.04, 3, N, 32)
	var blotch := _noise(23, 0.008, 3)
	var rows := 8
	var rh := N / rows
	for y in N:
		var row := y / rh
		var ty := float(y % rh) / rh
		var bw := N / 4
		var off := (bw / 2) * (row % 2)
		for x in N:
			var xx := (x + off) % N
			var col_i := xx / bw
			var tx := float(xx % bw) / bw
			var edge := minf(minf(tx, 1.0 - tx) * bw, minf(ty, 1.0 - ty) * rh)
			var mortar := 1.0 - smoothstep(0.5, 3.5, edge)
			var i := y * N + x
			var block := (_hash(col_i, row) - 0.5) * 0.07
			var st := (_s(streak, N, 32, x, y * 32.0 / N) - 0.5) * 0.1 * (1.0 - ty)
			var v := 0.52 + block + (n1[i] - 0.5) * 0.06 + (blotch[i] - 0.5) * 0.08 - st - mortar * 0.09
			a[0][i] = _v(v, Color(1.0, 0.985, 0.96))
			a[1][i] = (1.0 - mortar) * 0.7 + n1[i] * 0.3 + block
	return [a[0], a[1], 2.0]

static func _clapboard() -> Array:
	# Lapped boards, 8 per tile: each board lighter at the top, with a shadow
	# line under the lap and a faint horizontal grain.
	var a := _arrays()
	var grain := _noise(31, 0.03, 3, 32, N)
	var n1 := _noise(32, 0.01, 3)
	var rh := N / 8
	for y in N:
		var board := y / rh
		var t := float(y % rh) / rh
		for x in N:
			var i := y * N + x
			var g := _s(grain, 32, N, x * 32.0 / N, y) - 0.5
			var lap := smoothstep(0.9, 1.0, t)
			var v := 0.55 - t * 0.07 + g * 0.06 + (n1[i] - 0.5) * 0.06 + (_hash(board, 7) - 0.5) * 0.05 - lap * 0.18
			a[0][i] = _v(v)
			a[1][i] = t * (1.0 - lap) + g * 0.05
	return [a[0], a[1], 3.0]

static func _shingle() -> Array:
	var a := _arrays()
	var n1 := _noise(41, 0.03, 3)
	var grain := _noise(42, 0.05, 2, N, 32)
	var rows := 8
	var rh := N / rows
	for y in N:
		var row := y / rh
		var t := float(y % rh) / rh
		# Random shingle widths per row.
		var bounds := PackedInt32Array([0])
		var acc := 0
		var k := 0
		while acc < N:
			acc += 40 + int(_hash(row, k) * 46.0)
			bounds.append(mini(acc, N))
			k += 1
		for x in N:
			var s := 0
			while s < bounds.size() - 1 and x >= bounds[s + 1]:
				s += 1
			var w := float(bounds[s + 1] - bounds[s])
			var tx := (x - bounds[s]) / w
			var gap := 1.0 - smoothstep(0.0, 2.5, minf(tx, 1.0 - tx) * w)
			var i := y * N + x
			var bottom := smoothstep(0.88, 1.0, t)
			var g := _s(grain, N, 32, x, y * 32.0 / N) - 0.5
			var v := 0.5 + (_hash(row * 31 + s, 3) - 0.5) * 0.16 + (n1[i] - 0.5) * 0.07 + g * 0.05 - gap * 0.22 - bottom * 0.15 + t * 0.03
			a[0][i] = _v(v, Color(1.0, 0.98, 0.97))
			a[1][i] = t * 0.8 * (1.0 - gap) + g * 0.05
	return [a[0], a[1], 3.5]

static func _wood() -> Array:
	# Weathered wood: long grain running along U, a few soft rings.
	var a := _arrays()
	var grain := _noise(51, 0.04, 4, 32, N)
	var fine := _noise(52, 0.15, 2, 64, N)
	var blot := _noise(53, 0.01, 3)
	for y in N:
		for x in N:
			var i := y * N + x
			var g := _s(grain, 32, N, x * 32.0 / N, y)
			var f := _s(fine, 64, N, x * 64.0 / N, y)
			var ring := sin((y + g * 40.0) * 0.21) * 0.5 + 0.5
			var v := 0.5 + (g - 0.5) * 0.12 + (f - 0.5) * 0.05 + (ring - 0.5) * 0.04 + (blot[i] - 0.5) * 0.08
			a[0][i] = _v(v)
			a[1][i] = g * 0.6 + f * 0.25 + ring * 0.15
	return [a[0], a[1], 2.5]

static func _granite() -> Array:
	var a := _arrays()
	var cells := _noise(61, 0.02, 1, N, N, FastNoiseLite.TYPE_CELLULAR, FastNoiseLite.RETURN_DISTANCE2_SUB)
	var cellv := _noise(62, 0.02, 1, N, N, FastNoiseLite.TYPE_CELLULAR, FastNoiseLite.RETURN_CELL_VALUE)
	var speck := _noise(63, 0.35, 1)
	var macro := _noise(64, 0.008, 4)
	for i in N * N:
		var crack := (1.0 - smoothstep(0.0, 0.05, cells[i])) * smoothstep(0.35, 0.6, macro[i])
		var sp := smoothstep(0.62, 0.8, speck[i]) * 0.1 - smoothstep(0.38, 0.2, speck[i]) * 0.06
		var v := 0.5 + (cellv[i] - 0.5) * 0.05 + (macro[i] - 0.5) * 0.16 + sp - crack * 0.07
		var warm := (cellv[i] - 0.5) * 0.06
		a[0][i] = Color(v * (1.0 + warm), v, v * (1.0 - warm * 0.5))
		a[1][i] = (1.0 - crack) * 0.35 + macro[i] * 0.5 + speck[i] * 0.15
	return [a[0], a[1], 3.0]

static func _sand() -> Array:
	var a := _arrays()
	var speck := _noise(71, 0.5, 1)
	var rip := _noise(72, 0.02, 2)
	var macro := _noise(73, 0.006, 3)
	for y in N:
		for x in N:
			var i := y * N + x
			var r := sin(y * TAU * 12.0 / N + rip[i] * 7.0) * 0.5 + 0.5
			var v := 0.5 + (speck[i] - 0.5) * 0.08 + (r - 0.5) * 0.04 + (macro[i] - 0.5) * 0.08
			a[0][i] = _v(v)
			a[1][i] = r * 0.7 + speck[i] * 0.3
	return [a[0], a[1], 1.5]

static func _grass() -> Array:
	# Winter grass seen from above: streaky blades, mixed tan and olive.
	var a := _arrays()
	var streak := _noise(81, 0.08, 3, N, 128)
	var clump := _noise(84, 0.04, 3)
	var patch := _noise(82, 0.008, 3)
	var fine := _noise(83, 0.3, 1)
	for y in N:
		for x in N:
			var i := y * N + x
			var s := lerpf(_s(streak, N, 128, x, y * 128.0 / N), clump[i], 0.55)
			var v := 0.5 + (s - 0.5) * 0.2 + (fine[i] - 0.5) * 0.1
			var hue := patch[i]
			var tint := Color(1.05, 1.0, 0.86).lerp(Color(0.9, 1.04, 0.92), hue)
			a[0][i] = _v(v, tint)
			a[1][i] = s
	return [a[0], a[1], 2.0]

static func _moss() -> Array:
	var a := _arrays()
	var n1 := _noise(91, 0.03, 4)
	var n2 := _noise(92, 0.2, 2)
	for i in N * N:
		var v := 0.5 + (n1[i] - 0.5) * 0.22 + (n2[i] - 0.5) * 0.1
		a[0][i] = _v(v, Color(0.97, 1.03, 0.95))
		a[1][i] = n1[i] * 0.6 + n2[i] * 0.4
	return [a[0], a[1], 2.0]

static func _rust() -> Array:
	# Painted metal: fine brushed base, rust blooms (baked orange), paint chips.
	var a := _arrays()
	var brush := _noise(101, 0.1, 2, N, 16)
	var bloom := _noise(102, 0.012, 4)
	var chip := _noise(103, 0.04, 3)
	for y in N:
		for x in N:
			var i := y * N + x
			var b := _s(brush, N, 16, x, y * 16.0 / N)
			var r := smoothstep(0.55, 0.72, bloom[i])
			var c := smoothstep(0.7, 0.74, chip[i])
			var base := Color(0.5, 0.5, 0.5) * (1.0 + (b - 0.5) * 0.08)
			var rust := Color(0.66, 0.4, 0.27) * (0.85 + bloom[i] * 0.3)
			var col := base.lerp(rust, r * 0.85)
			col = col.lerp(Color(0.33, 0.31, 0.3), c * 0.7)
			a[0][i] = col
			a[1][i] = 0.5 + r * 0.3 - c * 0.3 + b * 0.05
	return [a[0], a[1], 2.0]

static func _fabric() -> Array:
	var a := _arrays()
	var soft := _noise(111, 0.01, 3)
	for y in N:
		for x in N:
			var i := y * N + x
			var weave := 0.5 + 0.5 * sin(x * PI / 2.0) * sin(y * PI / 2.0)
			var v := 0.5 + (weave - 0.5) * 0.06 + (soft[i] - 0.5) * 0.12
			a[0][i] = _v(v)
			a[1][i] = weave * 0.3 + soft[i] * 0.7
	return [a[0], a[1], 1.5]

static func _bark() -> Array:
	var a := _arrays()
	var ridge := _noise(121, 0.05, 3, N, 32)
	var n := _noise(122, 0.05, 3)
	for y in N:
		for x in N:
			var i := y * N + x
			var r := _s(ridge, N, 32, x, y * 32.0 / N)
			var v := 0.48 + (r - 0.5) * 0.3 + (n[i] - 0.5) * 0.08
			a[0][i] = _v(v)
			a[1][i] = r
	return [a[0], a[1], 4.0]

static func _water() -> Array:
	# Height for the ocean's detail normals (two tiles blended in the shader).
	var a := _arrays()
	var n1 := _noise(131, 0.012, 4)
	var n2 := _noise(132, 0.03, 3)
	for i in N * N:
		a[0][i] = _v(0.5)
		a[1][i] = n1[i] * 0.65 + n2[i] * 0.35
	return [a[0], a[1], 6.0]

static func _foam() -> Array:
	# Foam lace: bright cellular webbing (albedo R = foam mask).
	var a := _arrays()
	var cells := _noise(141, 0.02, 1, N, N, FastNoiseLite.TYPE_CELLULAR, FastNoiseLite.RETURN_DISTANCE2_SUB)
	var n := _noise(142, 0.03, 3)
	for i in N * N:
		var web := 1.0 - smoothstep(0.0, 0.16, cells[i])
		var v := clampf(web * 0.8 + (n[i] - 0.4) * 0.6, 0.0, 1.0)
		a[0][i] = Color(v, v, v)
		a[1][i] = v
	return [a[0], a[1], 1.0]

# --- special textures ---------------------------------------------------------

static func _save_macro() -> void:
	# Low-frequency painterly breakup: three unrelated noises in R, G, B.
	var size := 256
	var r := _noise(201, 0.012, 3, size, size)
	var g := _noise(202, 0.02, 3, size, size)
	var b := _noise(203, 0.008, 2, size, size)
	var col := PackedColorArray(); col.resize(size * size)
	for i in size * size:
		col[i] = Color(r[i], g[i], b[i])
	_save_rgb(OUT + "macro_breakup.png", col, size)

static func _grass_card() -> void:
	# Alpha-tested tuft: ~16 tapered blades, dark at the root, pale at the tip.
	var w := 256; var h := 256
	var col := PackedColorArray(); col.resize(w * h)
	col.fill(Color(0.5, 0.45, 0.3, 0.0))
	for b in 18:
		var root := 30.0 + _hash(b, 1) * (w - 60.0)
		var lean := (_hash(b, 2) - 0.5) * 120.0
		var height := h * (0.55 + _hash(b, 3) * 0.45)
		var width := 4.0 + _hash(b, 4) * 5.0
		var shade := 0.8 + _hash(b, 5) * 0.4
		for yy in int(height):
			var t := yy / height
			var cx := root + lean * t * t
			var half := width * (1.0 - t) * 0.5 + 0.4
			var y := h - 1 - yy
			for x in range(int(cx - half - 1), int(cx + half + 2)):
				if x < 0 or x >= w:
					continue
				var d := absf(x - cx)
				var alpha := clampf(half - d + 0.5, 0.0, 1.0)
				if alpha <= 0.0:
					continue
				var v := lerpf(0.32, 0.86, pow(t, 0.8)) * shade
				var c := Color(v, v * 0.97, v * 0.8, alpha)
				var i := y * w + x
				if c.a > col[i].a or v > col[i].r:
					col[i] = Color(c.r, c.g, c.b, maxf(col[i].a, alpha))
	_save_rgba(OUT + "grass_card.png", col, w, h)

static func _paper(name: String, table: bool) -> void:
	# Aged paper with printed rules (tide table) or ruled lines and ink strokes
	# (logbook). Deliberately unreadable: shapes of writing, not text.
	var w := 512; var h := 512
	var fibre := _noise(301 if table else 302, 0.05, 3, w, h)
	var stain := _noise(303, 0.006, 3, w, h)
	var col := PackedColorArray(); col.resize(w * h)
	for y in h:
		for x in w:
			var i := y * w + x
			var v := 0.9 + (fibre[i] - 0.5) * 0.05 - smoothstep(0.6, 0.9, stain[i]) * 0.08
			var c := Color(v, v * 0.96, v * 0.86)
			var ink := 0.0
			if table:
				if y > 28 and y < 64:
					ink = 0.9 if (x > 24 and x < w - 24) else 0.0
				elif y > 80 and (y - 80) % 34 < 2 and x > 24 and x < w - 24:
					ink = 0.6
				elif y > 80 and (x == 24 or x == w - 25 or x == 180 or x == 340):
					ink = 0.6
				elif y > 90 and (y - 80) % 34 > 11 and (y - 80) % 34 < 21:
					var cell := (y - 80) / 34
					var cx := x % 160
					if cx > 40 and cx < 40 + 50 + int(_hash(cell, x / 160) * 50.0) and x > 30 and x < w - 30:
						ink = 0.75 if (x / 7) % 3 != 2 else 0.0
			else:
				if y > 40 and (y - 40) % 26 == 0:
					ink = 0.25
				var line := (y - 40) / 26
				var ly := (y - 40) % 26
				if line >= 0 and line < 15 and ly > 9 and ly < 21 and x > 40:
					var end := 120.0 + _hash(line, 9) * 330.0
					var wav := sin(x * 0.55 + line * 3.0) * 3.0 + sin(x * 0.13 + line) * 2.0
					if x < end and absf(ly - 15 - wav * 0.5) < 1.4 and _hash(x / 9, line) > 0.18:
						ink = 0.8
			c = c.lerp(Color(0.12, 0.13, 0.2) if not table else Color(0.18, 0.16, 0.15), ink)
			col[i] = c
	_save_rgb(OUT + name + ".png", col, w)

static func _chart() -> void:
	# Nautical-chart look for the chart table: pale sea, buff land, depth lines.
	var w := 512
	var land := _noise(401, 0.006, 4, w, w)
	var col := PackedColorArray(); col.resize(w * w)
	for i in w * w:
		var l := land[i]
		var c := Color(0.83, 0.87, 0.86)
		if l > 0.62:
			c = Color(0.9, 0.84, 0.66)
		elif absf(fposmod(l * 20.0, 1.0) - 0.5) < 0.04:
			c = Color(0.55, 0.64, 0.7)
		if absf(l - 0.62) < 0.006:
			c = Color(0.3, 0.28, 0.25)
		col[i] = c
	_save_rgb(OUT + "chart.png", col, w)
