class_name FoleySynth
## Procedural foley: the small physical sounds of the keeper's routine. Doors,
## stairs, the stove and its crackle, the clockwork weights, the lamp, chairs and bed,
## paper and pen, the barometer glass, the pocket watch, radio static between lines,
## menu clicks, and the Day 4 rain and thunder.
## Pure static functions with local RNGs (deterministic, thread-safe). Mono, 22.05 kHz.
## Loops are built seamless: events wrap around the buffer end and filters run twice.

const RATE := 22050

# ---- building blocks ---------------------------------------------------------

static func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b

## Adds src into dst at `at` seconds. wrap=true wraps the overflow to the start (loops).
static func _add(dst: PackedFloat32Array, src: PackedFloat32Array, at: float, gain := 1.0, wrap := false) -> void:
	var start := int(at * RATE)
	var n := dst.size()
	for i in src.size():
		var j := start + i
		if j >= n:
			if not wrap:
				return
			j = j % n
		dst[j] += src[i] * gain

static func _noise(rng: RandomNumberGenerator, n: int) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		b[i] = rng.randf() * 2.0 - 1.0
	return b

## One-pole low-pass in place. loop=true runs twice so the end state matches the start.
static func _lp(b: PackedFloat32Array, fc: float, loop := false) -> void:
	var a := 1.0 - exp(-TAU * fc / RATE)
	var y := 0.0
	if loop:                       # warm-up pass: the state at the end becomes the start state
		for i in b.size():
			y += a * (b[i] - y)
	for i in b.size():
		y += a * (b[i] - y)
		b[i] = y

## One-pole high-pass in place (input minus its low-passed self).
static func _hp(b: PackedFloat32Array, fc: float) -> void:
	var a := 1.0 - exp(-TAU * fc / RATE)
	var y := 0.0
	for i in b.size():
		y += a * (b[i] - y)
		b[i] -= y

## State-variable band-pass in place. loop=true: two passes for a seamless loop.
## fc is capped at RATE/6: above that the Chamberlin filter goes unstable at low Q.
static func _bp(b: PackedFloat32Array, fc: float, q: float, loop := false) -> void:
	var f := 2.0 * sin(PI * minf(fc, RATE / 6.0) / RATE)
	var damp := 1.0 / q
	var low := 0.0
	var band := 0.0
	var src := b.duplicate()
	for p in (2 if loop else 1):
		for i in src.size():
			low += f * band
			var high := src[i] - low - damp * band
			band += f * high
			b[i] = band

## A struck resonance: decaying sine partials. parts = [[freq, amp, decay/s], ...].
static func _ring(parts: Array, seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	for p in parts:
		var w: float = TAU * float(p[0]) / RATE
		var e: float = p[1]
		var dec := exp(-float(p[2]) / RATE)
		for i in b.size():
			b[i] += sin(w * i) * e
			e *= dec
	return b

## Short noise burst with an exponential decay, optionally band-passed.
static func _burst(rng: RandomNumberGenerator, seconds: float, decay: float, fc := 0.0, q := 1.0) -> PackedFloat32Array:
	var b := _noise(rng, int(seconds * RATE))
	if fc > 0.0:
		_bp(b, fc, q)
	for i in b.size():
		b[i] *= exp(-decay * float(i) / RATE)
	return b

## Wood creak: a stick-slip impulse train whose rate glides (f0 -> f1 Hz), coloured by
## two body resonances. The core of hinges, chairs, stairs and the bed.
static func _creak(rng: RandomNumberGenerator, seconds: float, f0: float, f1: float, res1 := 700.0, res2 := 1500.0) -> PackedFloat32Array:
	var b := _buf(seconds)
	var ph := 0.0
	var n := b.size()
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t) * (1.0 + 0.25 * (rng.randf() - 0.5))
		ph += f / RATE
		if ph >= 1.0:
			ph -= 1.0
			b[i] = 1.0 + rng.randf() * 0.6
	var a := b.duplicate()
	_bp(a, res1, 6.0)
	_bp(b, res2, 8.0)
	for i in n:
		var t := float(i) / n
		var env := smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.7, 1.0, t))
		b[i] = (a[i] * 0.8 + b[i] * 0.5) * env
	return b

## Brown-ish rumble that loops cleanly (crossfaded head/tail).
static func _rumble(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var fade := 2000
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var last := 0.0
	for i in n + fade:
		last = (last + 0.02 * (rng.randf() * 2.0 - 1.0)) / 1.02
		raw[i] = last * 2.8
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = raw[i]
	for i in fade:
		var k := float(i) / fade
		out[i] = raw[i] * k + raw[n + i] * (1.0 - k)
	return out

## Fade the edges (one-shots only) and scale the peak.
static func _finish(b: PackedFloat32Array, peak_target := 0.75, fade_out := 0.05) -> PackedFloat32Array:
	var peak := 0.0
	for v in b:
		peak = maxf(peak, absf(v))
	var k := peak_target / peak if peak > 0.0 else 1.0
	var fi := int(0.002 * RATE)
	var fo := mini(int(fade_out * RATE), b.size())
	for i in b.size():
		var g := k
		if i < fi: g *= float(i) / fi
		var from_end := b.size() - 1 - i
		if from_end < fo: g *= float(from_end) / fo
		b[i] *= g
	return b

static func _norm_loop(b: PackedFloat32Array, peak_target: float) -> PackedFloat32Array:
	var peak := 0.0
	for v in b:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in b.size():
			b[i] *= peak_target / peak
	return b

static func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r

# ---- one-shots -----------------------------------------------------------------

## Latch click, then a slow hinge creak.
static func door_open(seed_value := 1) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(1.1)
	_add(b, _burst(rng, 0.02, 260.0, 2400.0, 1.5), 0.0, 0.8)
	_add(b, _ring([[2150.0, 0.25, 60.0], [3900.0, 0.1, 90.0]], 0.08), 0.0)
	_add(b, _creak(rng, 0.75, 150.0, 240.0 + rng.randf() * 60.0, 650.0, 1350.0), 0.12, 0.6)
	return _finish(b, 0.7, 0.15)

## A heavy door swinging home: wooden thud, then the latch.
static func door_close(seed_value := 2) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(0.7)
	var thud := _ring([[68.0, 1.0, 14.0], [112.0, 0.5, 20.0], [190.0, 0.25, 30.0]], 0.5)
	var body := _burst(rng, 0.25, 22.0)
	_lp(body, 420.0)
	_add(b, thud, 0.0)
	_add(b, body, 0.0, 0.9)
	_add(b, _burst(rng, 0.015, 300.0, 2600.0, 1.5), 0.075, 0.45)
	_add(b, _ring([[2300.0, 0.15, 70.0]], 0.06), 0.075)
	return _finish(b, 0.75, 0.1)

## Up or down the tower stairs: four creaky wooden treads.
static func stairs(seed_value := 3) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(2.0)
	for k in 4:
		var at := k * 0.42 + rng.randf() * 0.04
		var step := _ring([[95.0 + rng.randf() * 25.0, 0.8, 26.0], [180.0, 0.3, 40.0]], 0.25)
		_add(b, step, at)
		if rng.randf() < 0.7:
			_add(b, _creak(rng, 0.3, 120.0, 170.0, 800.0, 1600.0), at + 0.03, 0.35)
	return _finish(b, 0.65, 0.15)

## Lighting the stove: iron door clank, match, the fire catching with a whoomph.
static func stove(seed_value := 4) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(2.6)
	_add(b, _ring([[620.0, 0.5, 18.0], [1450.0, 0.35, 26.0], [2380.0, 0.2, 35.0], [3310.0, 0.1, 50.0]], 0.5), 0.0)
	_add(b, _burst(rng, 0.03, 120.0, 1200.0, 1.0), 0.0, 0.5)
	_add(b, _match(rng), 0.55, 0.6)
	var catch_ := _noise(rng, int(1.3 * RATE))
	_lp(catch_, 380.0)
	for i in catch_.size():
		var t := float(i) / RATE
		catch_[i] *= smoothstep(0.0, 0.35, t) * exp(-1.6 * maxf(0.0, t - 0.35)) * 2.5
	_add(b, catch_, 0.95)
	for k in 6:
		_add(b, _pop(rng), 1.3 + rng.randf() * 1.1, 0.4 + rng.randf() * 0.4)
	return _finish(b, 0.7, 0.3)

static func _match(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var b := _noise(rng, int(0.45 * RATE))
	_bp(b, 3200.0, 1.2)
	for i in b.size():
		var t := float(i) / RATE
		var scratch := smoothstep(0.0, 0.03, t) * (1.0 - smoothstep(0.1, 0.16, t)) * (0.6 + 0.4 * sin(t * 260.0))
		var flare := smoothstep(0.14, 0.17, t) * exp(-9.0 * maxf(0.0, t - 0.17)) * 1.6
		b[i] *= scratch + flare
	return b

## A single crackle pop (embers, rain drops, radio crackle).
static func _pop(rng: RandomNumberGenerator, bright := 1800.0) -> PackedFloat32Array:
	var b := _burst(rng, 0.02 + rng.randf() * 0.02, 180.0 + rng.randf() * 120.0)
	_hp(b, bright)
	return b

## Winding the clockwork weights: a ratchet pawl clicking over a groaning drum.
static func winding(seed_value := 5) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(3.0)
	var at := 0.05
	var k := 0
	while at < 2.6:
		var click := _ring([[3100.0 + rng.randf() * 200.0, 0.5, 120.0], [5200.0, 0.2, 180.0], [1250.0, 0.3, 60.0]], 0.06)
		_add(b, click, at, 1.0 if k % 2 == 0 else 0.7)
		_add(b, _burst(rng, 0.005, 600.0, 4000.0, 1.0), at, 0.4)
		at += 0.14 + rng.randf() * 0.03 + (0.12 if k % 6 == 5 else 0.0)   # a breath every turn of the crank
		k += 1
	var groan := _buf(2.8)
	for i in groan.size():
		var t := float(i) / RATE
		groan[i] = sin(TAU * (88.0 + 6.0 * sin(t * 4.5)) * t) * 0.18 * smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(2.3, 2.8, t))
	_add(b, groan, 0.0)
	return _finish(b, 0.65, 0.2)

## Lighting the lamp: match, the mantle catching, a soft pressure hiss.
static func lamp(seed_value := 6) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(2.6)
	_add(b, _match(rng), 0.0, 0.8)
	var whump := _noise(rng, int(0.7 * RATE))
	_lp(whump, 260.0)
	for i in whump.size():
		var t := float(i) / RATE
		whump[i] *= smoothstep(0.0, 0.08, t) * exp(-6.0 * t) * 4.0
	_add(b, whump, 0.75)
	var hiss := _noise(rng, int(1.6 * RATE))
	_bp(hiss, 5200.0, 0.8)
	for i in hiss.size():
		var t := float(i) / RATE
		hiss[i] *= 0.08 * smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(1.0, 1.6, t))
	_add(b, hiss, 0.85)
	return _finish(b, 0.65, 0.2)

## Settling into the armchair / bench: a creak and a cushion sigh.
static func chair(seed_value := 7) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(1.0)
	_add(b, _creak(rng, 0.55, 90.0, 140.0, 520.0, 1150.0), 0.0)
	_add(b, _rustle(rng, 0.5, 0.25), 0.15, 0.5)
	return _finish(b, 0.55, 0.15)

## Climbing into bed: a long low frame creak and blankets.
static func bed(seed_value := 8) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(1.6)
	_add(b, _creak(rng, 0.8, 70.0, 110.0, 420.0, 950.0), 0.0)
	_add(b, _rustle(rng, 1.1, 0.4), 0.3, 0.8)
	return _finish(b, 0.55, 0.25)

## Fabric: low-passed noise with a slow flutter.
static func _rustle(rng: RandomNumberGenerator, seconds: float, amp: float) -> PackedFloat32Array:
	var b := _noise(rng, int(seconds * RATE))
	_bp(b, 1800.0, 0.7)
	var flutter := 0.0
	for i in b.size():
		var t := float(i) / b.size()
		flutter += 0.002 * ((rng.randf()) - flutter)
		b[i] *= amp * (0.4 + 6.0 * flutter) * sin(PI * t)
	return b

## A page turning: a crisp swish with paper crinkle.
static func page(seed_value := 9) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _noise(rng, int(0.42 * RATE))
	_hp(b, 900.0)
	_lp(b, 7000.0)
	var crinkle := 0.5
	for i in b.size():
		var t := float(i) / b.size()
		if i % 300 == 0:
			crinkle = 0.35 + rng.randf() * 0.65
		var env := smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(0.55, 1.0, t))
		b[i] *= env * crinkle
	_add(b, _burst(rng, 0.03, 120.0, 600.0, 1.0), 0.3, 0.6)   # the page lands
	return _finish(b, 0.5, 0.05)

## Pen on paper: a few scratchy strokes.
static func pen(seed_value := 10) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(1.5)
	var at := 0.05
	while at < 1.3:
		var len_s := 0.08 + rng.randf() * 0.18
		var s := _noise(rng, int(len_s * RATE))
		_bp(s, 2800.0 + rng.randf() * 900.0, 2.5)
		for i in s.size():
			var t := float(i) / s.size()
			s[i] *= sin(PI * t) * (0.6 + 0.4 * sin(float(i) * 0.02))
		_add(b, s, at)
		at += len_s + 0.03 + rng.randf() * 0.09
	return _finish(b, 0.4, 0.1)

## Tapping the barometer glass twice with a knuckle.
static func tap(seed_value := 11) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(0.6)
	for k in 2:
		var at := k * 0.19
		_add(b, _ring([[1780.0, 0.5, 45.0], [4150.0, 0.25, 70.0], [640.0, 0.4, 35.0]], 0.3), at, 1.0 - k * 0.25)
		_add(b, _burst(rng, 0.01, 400.0, 1500.0, 1.0), at, 0.5)
	return _finish(b, 0.6, 0.1)

## A soft menu click.
static func click(seed_value := 12) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _ring([[1350.0, 0.6, 140.0], [2900.0, 0.2, 220.0]], 0.07)
	_add(b, _burst(rng, 0.006, 700.0, 3000.0, 1.0), 0.0, 0.3)
	return _finish(b, 0.45, 0.01)

## Distant thunder: a dull crack, then a long rolling rumble.
static func thunder(seed_value := 13) -> PackedFloat32Array:
	var rng := _rng(seed_value)
	var b := _buf(7.0)
	var crack := _noise(rng, int(0.6 * RATE))
	_lp(crack, 900.0)
	for i in crack.size():
		crack[i] *= exp(-7.0 * float(i) / RATE)
	_add(b, crack, 0.1, 0.6)
	var roll := _rumble(rng, 6.8)
	_lp(roll, 140.0)
	var bumps: Array = []
	for k in 5:
		bumps.append([0.2 + rng.randf() * 4.0, 0.6 + rng.randf() * 1.2])
	for i in roll.size():
		var t := float(i) / RATE
		var env := 0.25 * exp(-0.35 * t)
		for bp in bumps:
			env += exp(-pow((t - float(bp[0])) / float(bp[1]), 2.0)) * 0.5
		roll[i] *= env * smoothstep(0.0, 0.15, t)
	_add(b, roll, 0.0)
	return _finish(b, 0.8, 0.8)

# ---- loops ---------------------------------------------------------------------

## Wood stove crackle: low fire roar plus random ember pops. 6 s seamless loop.
static func stove_crackle() -> PackedFloat32Array:
	var rng := _rng(21)
	var b := _rumble(rng, 6.0)
	_lp(b, 220.0, true)
	for i in b.size():
		b[i] *= 0.35
	for k in 46:
		var g := rng.randf()
		_add(b, _pop(rng, 1200.0 + rng.randf() * 1800.0), rng.randf() * 6.0, 0.15 + g * g * 0.9, true)
	return _norm_loop(b, 0.55)

## Radio static between lines: band-limited hiss with crackle. 3 s seamless loop.
static func radio_static() -> PackedFloat32Array:
	var rng := _rng(22)
	var b := _noise(rng, int(3.0 * RATE))
	_bp(b, 1900.0, 0.9, true)
	var n := b.size()
	for i in n:
		b[i] *= 0.3 * (0.75 + 0.25 * sin(TAU * 2.0 * i / n))   # 2 slow wobbles per loop
	for k in 24:
		_add(b, _pop(rng, 2500.0), rng.randf() * 3.0, 0.2 + rng.randf() * 0.6, true)
	return _norm_loop(b, 0.5)

## Pocket watch: five beats a second, tick-tock. 1 s seamless loop.
static func watch_tick() -> PackedFloat32Array:
	var rng := _rng(23)
	var b := _buf(1.0)
	for k in 5:
		var tick := _ring([[3600.0, 0.6, 600.0], [6100.0, 0.35, 900.0], [2200.0, 0.2, 500.0]], 0.02)
		var at := 0.1 + k * 0.2           # off the loop seam
		_add(b, tick, at, 1.0 if k % 2 == 0 else 0.7)
		_add(b, _burst(rng, 0.003, 1500.0, 5000.0, 1.0), at, 0.2)
	return _norm_loop(b, 0.5)

## Rain: broadband hiss, a damp low wash and dense droplets. 4 s seamless loop.
static func rain() -> PackedFloat32Array:
	var rng := _rng(24)
	var n := int(4.0 * RATE)
	var hiss := _noise(rng, n)
	_bp(hiss, 2600.0, 0.6, true)
	var wash := _rumble(rng, 4.0)
	_lp(wash, 400.0, true)
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		b[i] = hiss[i] * 0.45 + wash[i] * 0.35
	for k in 420:
		var g := rng.randf()
		_add(b, _pop(rng, 2000.0 + rng.randf() * 3000.0), rng.randf() * 4.0, 0.05 + g * g * 0.35, true)
	return _norm_loop(b, 0.55)
