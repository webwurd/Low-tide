class_name StingSynth
## Procedural placeholder music: sparse plucked guitar (Karplus-Strong) and bowed-cello pads,
## with a little room tone. Pure functions with local RNGs, so they are thread-safe and
## deterministic. Replace with composed audio later by dropping files into res://audio/stings/
## named after NAMES (AudioDirector prefers a file when it exists).

const RATE := 22050
const NAMES := ["sting_end_a", "sting_end_b", "sting_end_c", "sting_confront", "sting_june", "sting_walt"]

## Plucked string: a noise burst circulating in a delay line that low-passes itself.
## The delay is fractional (linear interpolation) and compensates the half-sample the
## two-point average adds, so notes land in tune instead of snapping to whole samples.
static func pluck(freq: float, dur: float, amp := 0.6, bright := 0.6, seed_value := 1) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var d := RATE / freq - 0.5
	var n1 := int(floor(d))
	var frac := d - n1
	var size := n1 + 2
	var line := PackedFloat32Array()
	line.resize(size)
	var lp := 0.0
	for i in n1 + 1:
		lp += bright * ((rng.randf() * 2.0 - 1.0) - lp)
		line[i] = lp
	var total := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	var decay := 0.9985 if freq < 200.0 else 0.9965
	var prev := 0.0
	for i in total:
		var w := (i + n1 + 1) % size
		var delayed := line[(w - n1 + size) % size] * (1.0 - frac) + line[(w - n1 - 1 + size) % size] * frac
		var y := (delayed + prev) * 0.5 * decay
		prev = delayed
		line[w] = y
		out[i] = y * amp
	return out

## Bowed cello-ish voice: two slightly detuned saws, vibrato, dark low-pass, slow swell.
static func bowed(freq: float, dur: float, amp := 0.35, attack := 1.0, release := 1.5, vibrato_hz := 4.8) -> PackedFloat32Array:
	var total := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	var p1 := 0.0
	var p2 := 0.0
	var lp := 0.0
	var cutoff := 1.0 - exp(-TAU * minf(freq * 5.0, 1100.0) / RATE)
	for i in total:
		var t := float(i) / RATE
		var vib := 1.0 + 0.0035 * sin(TAU * vibrato_hz * t) * minf(1.0, t / 1.5)
		p1 = fposmod(p1 + freq * vib / RATE, 1.0)
		p2 = fposmod(p2 + freq * 1.004 * vib / RATE, 1.0)
		var raw := (2.0 * p1 - 1.0) * 0.6 + (2.0 * p2 - 1.0) * 0.4
		lp += cutoff * (raw - lp)
		var env := minf(1.0, t / attack) * minf(1.0, (dur - t) / release)
		out[i] = lp * amp * env * env
	return out

static func mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, at_seconds: float) -> void:
	var start := int(at_seconds * RATE)
	for i in src.size():
		if start + i < dst.size():
			dst[start + i] += src[i]

## Three comb filters: a small room. Returns a new buffer.
static func room(buf: PackedFloat32Array, mix := 0.28) -> PackedFloat32Array:
	var out := buf.duplicate()
	for pair in [[0.037, 0.55], [0.053, 0.5], [0.071, 0.45]]:
		var d := int(pair[0] * RATE)
		var fb: float = pair[1]
		var comb := PackedFloat32Array()
		comb.resize(buf.size())
		for i in buf.size():
			var prev := comb[i - d] if i >= d else 0.0
			comb[i] = buf[i] + prev * fb
		for i in buf.size():
			out[i] += comb[i] * mix * 0.45
	return out

## Fades the edges (no clicks) and normalises the peak.
static func finish(buf: PackedFloat32Array, peak_target := 0.8) -> PackedFloat32Array:
	var peak := 0.0
	for v in buf:
		peak = maxf(peak, absf(v))
	var k := peak_target / peak if peak > 0.0 else 1.0
	var fade_in := int(0.02 * RATE)
	var fade_out := int(0.8 * RATE)
	for i in buf.size():
		var g := k
		if i < fade_in: g *= float(i) / fade_in
		var from_end := buf.size() - 1 - i
		if from_end < fade_out: g *= float(from_end) / fade_out
		buf[i] *= g
	return buf

static func render(sting: String) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	var length := 10.0
	match sting:
		"sting_end_a":      # resolved: D major arpeggio over a warm cello
			length = 11.0
			buf.resize(int(length * RATE))
			mix_into(buf, bowed(73.42, 10.0, 0.30, 1.8, 3.0), 0.0)
			var notes := [146.83, 220.0, 293.66, 369.99, 440.0]
			for i in notes.size():
				mix_into(buf, pluck(notes[i], 4.5, 0.55, 0.55, 11 + i), 0.5 + i * 0.7)
		"sting_end_b":      # quiet: open fifth, two soft high notes
			length = 12.0
			buf.resize(int(length * RATE))
			mix_into(buf, bowed(73.42, 11.0, 0.32, 3.2, 3.5, 4.2), 0.0)
			mix_into(buf, bowed(110.0, 10.0, 0.22, 3.8, 3.5, 4.6), 0.8)
			mix_into(buf, pluck(440.0, 4.0, 0.30, 0.45, 21), 4.6)
			mix_into(buf, pluck(293.66, 4.0, 0.26, 0.45, 22), 7.0)
		"sting_end_c":      # lonely: three falling notes, unresolved
			length = 12.0
			buf.resize(int(length * RATE))
			mix_into(buf, bowed(55.0, 11.0, 0.16, 2.5, 3.5, 4.0), 0.0)
			mix_into(buf, pluck(220.0, 5.0, 0.50, 0.5, 31), 0.4)
			mix_into(buf, pluck(174.61, 5.0, 0.46, 0.5, 32), 2.9)
			mix_into(buf, pluck(164.81, 6.0, 0.40, 0.45, 33), 5.6)
		"sting_confront":   # tension: a minor second under a slow swell
			length = 10.0
			buf.resize(int(length * RATE))
			mix_into(buf, bowed(73.42, 9.5, 0.28, 3.0, 3.0, 4.4), 0.0)
			mix_into(buf, bowed(77.78, 8.5, 0.18, 4.0, 3.0, 5.0), 1.0)
			mix_into(buf, pluck(146.83, 4.0, 0.35, 0.4, 41), 4.5)
		"sting_june":       # tender: A minor figure
			length = 9.0
			buf.resize(int(length * RATE))
			mix_into(buf, bowed(110.0, 8.0, 0.18, 2.0, 3.0), 0.5)
			var jn := [164.81, 220.0, 261.63, 329.63]
			for i in jn.size():
				mix_into(buf, pluck(jn[i], 4.0, 0.42, 0.5, 51 + i), 0.3 + i * 0.95)
		_:                  # sting_walt: two falling notes
			length = 9.0
			buf.resize(int(length * RATE))
			mix_into(buf, bowed(98.0, 8.5, 0.22, 2.2, 3.0, 4.6), 0.0)
			mix_into(buf, pluck(196.0, 5.0, 0.45, 0.5, 61), 0.2)
			mix_into(buf, pluck(146.83, 5.5, 0.42, 0.5, 62), 2.2)
	return finish(room(buf))
