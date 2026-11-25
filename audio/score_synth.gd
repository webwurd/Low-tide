class_name ScoreSynth
## Procedural score: the adaptive background music. Every cue is composed by a small
## rule-based generator from a per-day PALETTE (key, mode, tempo, metre, instruments),
## so each of the seven days has its own colour, and each day has separate cues for the
## morning (warm, indoors), the expedition (outdoors), the night, the tide turning, a
## breathing pad under the sea, and an undertow layer for when the water is rising
## around Arthur. All functions are pure with local RNGs (thread-safe, deterministic).
##
## Instruments, per the bible (sparse acoustic guitar, solo cello, ambient piano):
## Karplus-Strong guitar and bowed cello (shared with StingSynth), a soft additive piano,
## a glass/celesta voice for the fog and frost days, and a cello tremolo for the storm.
## A composed file at res://audio/music/<cue>.(ogg|wav|mp3) replaces any cue.

const RATE := 22050

const IONIAN := [0, 2, 4, 5, 7, 9, 11]
const DORIAN := [0, 2, 3, 5, 7, 9, 10]
const PHRYGIAN := [0, 1, 3, 5, 7, 8, 10]
const LYDIAN := [0, 2, 4, 6, 7, 9, 11]
const AEOLIAN := [0, 2, 3, 5, 7, 8, 10]
const HARMONIC_MINOR := [0, 2, 3, 5, 7, 8, 11]

## root: tonic in Hz (accompaniment register; melody sits an octave up, bass an octave down).
## prog / night_prog: chords as scale degrees (0 = tonic triad). density: 0..1 how busy.
## lead / accomp: instrument and texture for the expedition cues. verb: room size.
const PALETTES := {
	1: {"name": "First Watch", "root": 146.83, "scale": DORIAN, "bpm": 66.0, "meter": 4,
		"prog": [0, 3, 6, 4], "night_prog": [0, 5, 3, 4], "lead": "guitar", "accomp": "arp",
		"density": 0.65, "verb": 1.0, "bright": 0.55, "pad_cut": 520.0},
	2: {"name": "Grey Water", "root": 110.0, "scale": AEOLIAN, "bpm": 58.0, "meter": 4,
		"prog": [0, 5, 2, 6], "night_prog": [0, 3, 5, 4], "lead": "cello", "accomp": "block",
		"density": 0.5, "verb": 1.2, "bright": 0.45, "pad_cut": 420.0},
	3: {"name": "Wool", "root": 164.81, "scale": PHRYGIAN, "bpm": 46.0, "meter": 4,
		"prog": [0, 1, 0, 6], "night_prog": [0, 6, 1, 0], "lead": "glass", "accomp": "sparse",
		"density": 0.35, "verb": 1.8, "bright": 0.4, "pad_cut": 360.0},
	4: {"name": "The Blow", "root": 130.81, "scale": HARMONIC_MINOR, "bpm": 88.0, "meter": 4,
		"prog": [0, 5, 3, 4], "night_prog": [0, 3, 5, 4], "lead": "cello", "accomp": "tremolo",
		"density": 0.9, "verb": 0.9, "bright": 0.5, "pad_cut": 340.0},
	5: {"name": "Spring Low", "root": 196.0, "scale": LYDIAN, "bpm": 76.0, "meter": 4,
		"prog": [0, 1, 5, 4], "night_prog": [0, 5, 1, 4], "lead": "guitar", "accomp": "arp",
		"density": 0.85, "verb": 1.1, "bright": 0.7, "pad_cut": 700.0},
	6: {"name": "Frost", "root": 123.47, "scale": AEOLIAN, "bpm": 52.0, "meter": 3,
		"prog": [0, 3, 5, 4], "night_prog": [0, 5, 6, 4], "lead": "piano", "accomp": "glass",
		"density": 0.5, "verb": 1.5, "bright": 0.6, "pad_cut": 620.0},
	7: {"name": "Last Light", "root": 146.83, "scale": IONIAN, "bpm": 60.0, "meter": 4,
		"prog": [0, 4, 5, 3], "night_prog": [0, 3, 4, 0], "lead": "guitar", "accomp": "arp",
		"density": 0.6, "verb": 1.3, "bright": 0.55, "pad_cut": 560.0},
}

const PAD_SECONDS := 24.0
const UNDERTOW_SECONDS := 16.0

## Every cue the game asks for on a given day (the title theme is "title").
static func day_cues(day: int) -> Array:
	var p := "d%d_" % day
	return [p + "pad", p + "day_0", p + "morning_0", p + "night_0", p + "day_1", p + "swell_open",
		p + "swell_close", p + "undertow", p + "morning_1", p + "night_1", p + "day_2"]

static func is_loop(cue: String) -> bool:
	return cue.ends_with("_pad") or cue.ends_with("_undertow")

static func palette(day: int) -> Dictionary:
	return PALETTES[clampi(day, 1, 7)]

## Renders a cue by name: "title", "d<day>_<kind>[_<index>]".
static func render(cue: String) -> PackedFloat32Array:
	if cue == "title":
		return render_phrase(1, "title", 0)
	var parts := cue.split("_")
	var day := int(parts[0].substr(1))
	var kind := parts[1]
	match kind:
		"pad": return render_pad(day)
		"undertow": return render_undertow(day)
		"swell": return render_swell(day, parts[2] == "open")
	return render_phrase(day, kind, int(parts[2]) if parts.size() > 2 else 0)

# ---- pitch helpers -------------------------------------------------------

## Frequency of scale degree `deg` (0 = tonic; 7 = tonic an octave up; negatives go down).
static func freq(pal: Dictionary, deg: int) -> float:
	var sc: Array = pal["scale"]
	var octave := floori(deg / 7.0)
	var step: int = sc[posmod(deg, 7)]
	return pal["root"] * pow(2.0, (step + 12 * octave) / 12.0)

## The triad on a scale degree, as degrees.
static func triad(deg: int) -> Array:
	return [deg, deg + 2, deg + 4]

static func _nearest_chord_tone(deg: int, chord: Array) -> int:
	var best := deg
	var bd := 99
	for c in chord:
		for o in [-14, -7, 0, 7, 14]:
			var d: int = c + o
			if absi(d - deg) < bd:
				bd = absi(d - deg)
				best = d
	return best

# ---- voices --------------------------------------------------------------

## Soft felt piano: a few slightly stretched partials, upper ones dying faster, a
## tiny hammer thump, and a short release.
static func piano(f: float, dur: float, amp := 0.4) -> PackedFloat32Array:
	var total := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	var bright := clampf(220.0 / f, 0.5, 1.6)
	var rel := mini(int(0.35 * RATE), total)
	for k in range(1, 6):
		var fk := f * k * sqrt(1.0 + 0.0004 * k * k)
		if fk > RATE * 0.42:
			break
		var ak := pow(1.0 / k, 1.4) * (bright if k > 1 else 1.0)
		var dk := (0.9 + 0.7 * k) * pow(f / 220.0, 0.35)
		var w := TAU * fk / RATE
		var dec := exp(-dk / RATE)
		var e := ak
		for i in total:
			out[i] += sin(w * i) * e
			e *= dec
	var hammer := mini(int(0.012 * RATE), total)
	var x := 0.0
	var seed_val := int(f * 7.0)
	for i in hammer:
		seed_val = (seed_val * 1103515245 + 12345) & 0x7fffffff
		x += 0.3 * ((float(seed_val) / 0x7fffffff * 2.0 - 1.0) - x)
		out[i] += x * 0.12 * (1.0 - float(i) / hammer)
	var atk := mini(int(0.004 * RATE), total)
	for i in total:
		var g := amp
		if i < atk: g *= float(i) / atk
		var from_end := total - 1 - i
		if from_end < rel: g *= float(from_end) / rel
		out[i] *= g
	return out

## Glass / celesta: a pure tone with a fifth-above shimmer and a long ring.
static func glass(f: float, dur: float, amp := 0.3) -> PackedFloat32Array:
	var total := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	var w1 := TAU * f / RATE
	var w2 := TAU * f * 3.0 / RATE
	var w3 := TAU * f * 4.01 / RATE
	var atk := int(0.03 * RATE)
	var rel := mini(int(0.6 * RATE), total)
	for i in total:
		var t := float(i) / RATE
		var v := sin(w1 * i) * exp(-0.55 * t) + sin(w2 * i) * 0.18 * exp(-2.2 * t) + sin(w3 * i) * 0.07 * exp(-3.5 * t)
		var g := amp
		if i < atk: g *= float(i) / atk
		var from_end := total - 1 - i
		if from_end < rel: g *= float(from_end) / rel
		out[i] = v * g
	return out

## Cello tremolo (storm): a bowed note with fast amplitude pulsing.
static func tremolo(f: float, dur: float, amp := 0.25, rate := 7.0) -> PackedFloat32Array:
	var out := StingSynth.bowed(f, dur, amp, minf(1.2, dur * 0.3), minf(1.0, dur * 0.3), 5.5)
	for i in out.size():
		out[i] *= 0.55 + 0.45 * sin(TAU * rate * float(i) / RATE)
	return out

static func _voice(inst: String, f: float, dur_s: float, amp: float, bright: float, seed_val: int) -> PackedFloat32Array:
	match inst:
		"guitar": return StingSynth.pluck(f, dur_s + 2.2, amp * 1.15, bright, seed_val)
		"piano": return piano(f, dur_s + 2.6, amp)
		"glass": return glass(f, dur_s + 3.0, amp * 0.8)
		"cello": return StingSynth.bowed(f, dur_s + 0.5, amp * 0.6, minf(0.7, dur_s * 0.45), minf(0.9, dur_s * 0.5 + 0.2), 5.0)
	return StingSynth.pluck(f, dur_s + 2.0, amp, bright, seed_val)

# ---- effects -------------------------------------------------------------

## Mono Schroeder/Freeverb-style reverb: four damped combs into two allpasses.
## Returns a longer buffer (the tail is appended).
static func reverb(buf: PackedFloat32Array, size := 1.0, wet := 0.3, damp := 0.35, tail_s := 3.5) -> PackedFloat32Array:
	var n := buf.size() + int(tail_s * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in buf.size():
		out[i] = buf[i]
	var wet_buf := PackedFloat32Array()
	wet_buf.resize(n)
	var k := float(RATE) / 44100.0 * size
	var fb := clampf(0.80 + 0.06 * size, 0.8, 0.9)
	for base in [1116, 1188, 1277, 1356]:
		var d := maxi(int(base * k), 1)
		var line := PackedFloat32Array()
		line.resize(d)
		var idx := 0
		var lp := 0.0
		for i in n:
			var x := buf[i] if i < buf.size() else 0.0
			var y := line[idx]
			lp = y * (1.0 - damp) + lp * damp
			line[idx] = x + lp * fb
			idx += 1
			if idx >= d: idx = 0
			wet_buf[i] += y
	for base in [556, 441]:
		var d := maxi(int(base * k), 1)
		var line := PackedFloat32Array()
		line.resize(d)
		var idx := 0
		for i in n:
			var x := wet_buf[i]
			var b := line[idx]
			line[idx] = x + b * 0.5
			wet_buf[i] = b - x * 0.5
			idx += 1
			if idx >= d: idx = 0
	for i in n:
		out[i] += wet_buf[i] * wet * 0.25
	return out

static func _lowpass_loop(buf: PackedFloat32Array, fc: float) -> void:
	var a := 1.0 - exp(-TAU * fc / RATE)
	var y := 0.0
	for pass_i in 2:          # second pass starts from the end state: seamless loop
		for i in buf.size():
			y += a * (buf[i] - y)
			if pass_i == 1:
				buf[i] = y

static func _normalise(buf: PackedFloat32Array, peak_target: float) -> void:
	var peak := 0.0
	for v in buf:
		peak = maxf(peak, absf(v))
	if peak <= 0.0:
		return
	var k := peak_target / peak
	for i in buf.size():
		buf[i] *= k

# ---- phrases (one-shots, played with silences between them) ---------------

const RHYTHMS_4 := [[1.0, 1.0, 2.0], [1.5, 0.5, 2.0], [0.5, 0.5, 1.0, 2.0], [2.0, 1.0, 1.0], [1.0, 0.5, 0.5, 2.0], [3.0, 1.0], [1.0, 1.0, 1.0, 1.0]]
const RHYTHMS_3 := [[1.0, 2.0], [2.0, 1.0], [1.0, 1.0, 1.0], [1.5, 0.5, 1.0], [3.0]]
const ARP_4 := [[0, 1, 2, 3, 2, 1, 2, 1], [0, 2, 1, 3, 1, 2, 0, 2], [0, 1, 2, 1, 3, 2, 1, 2]]
const ARP_3 := [[0, 1, 2, 3, 2, 1], [0, 2, 3, 2, 1, 2]]

## A short musical phrase: 4 bars (8 for the title), chords from the day's
## progression, a two-bar motif and its answer, bass swells under each bar.
## kind: "day" (expedition, outdoors), "morning" (warm guitar, indoors),
## "night" (piano and cello), "title".
static func render_phrase(day: int, kind: String, idx: int) -> PackedFloat32Array:
	var pal := palette(day)
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 1000 + {"day": 100, "morning": 200, "night": 300, "title": 400}.get(kind, 0) + idx * 17
	var meter: int = pal["meter"]
	var bpm: float = pal["bpm"]
	var lead: String = pal["lead"]
	var accomp: String = pal["accomp"]
	var density: float = pal["density"]
	var prog: Array = (pal["night_prog"] if kind == "night" else pal["prog"]).duplicate()
	var bars := 4
	var bass_on := true
	var melody_on := true
	match kind:
		"morning":
			bpm *= 0.92; lead = "guitar"; accomp = "arp"; density = clampf(density * 0.8, 0.35, 0.7)
			if day == 4: accomp = "block"       # even the storm morning is warm by the stove
		"night":
			bpm *= 0.8; lead = "piano"; accomp = "block" if day != 3 and day != 6 else "glass"; density *= 0.7
		"title":
			bpm = 60.0; bars = 8; lead = "guitar"; accomp = "arp"; density = 0.55
	# Variety between a day's cues: rotate the progression, and sometimes rest the melody
	# (a "breath": accompaniment and swells only) or drop the bass.
	for r in idx % prog.size():
		prog.push_back(prog.pop_front())
	if idx == 0 and prog[0] != 0:
		prog[0] = 0
	if kind != "title" and idx == 1:
		melody_on = rng.randf() < 0.5
	if kind == "morning" and idx == 1:
		bass_on = false
	var beat := 60.0 / bpm
	var bar_s := beat * meter
	var length := bar_s * bars + 0.6
	var buf := PackedFloat32Array()
	buf.resize(int(length * RATE) + int(4.0 * RATE))
	var bright: float = pal["bright"]
	var seed_n := 1 + day * 97 + idx * 13 + bars

	# --- bass: one swelling cello note per bar (fog: one long drone) ---
	if bass_on:
		if accomp == "sparse":
			StingSynth.mix_into(buf, StingSynth.bowed(freq(pal, -7), length + 1.0, 0.2, length * 0.35, length * 0.4, 4.2), 0.0)
		else:
			for b in bars:
				var chord_root: int = prog[b % prog.size()]
				var bdeg := chord_root - 7 if chord_root < 4 else chord_root - 14
				StingSynth.mix_into(buf, StingSynth.bowed(freq(pal, bdeg), bar_s + 0.6, 0.2, bar_s * 0.45, bar_s * 0.4, 4.4), b * bar_s)

	# --- accompaniment ---
	for b in bars:
		var chord := triad(prog[b % prog.size()])
		var t0 := b * bar_s
		match accomp:
			"arp":
				var pats: Array = ARP_3 if meter == 3 else ARP_4
				var pat: Array = pats[(idx + b / 2) % pats.size()]
				for s in pat.size():
					if s > 0 and rng.randf() > 0.35 + density * 0.6:
						continue
					var ci: int = pat[s]
					var deg: int = chord[ci] if ci < 3 else chord[0] + 7
					seed_n += 1
					StingSynth.mix_into(buf, StingSynth.pluck(freq(pal, deg), 2.6, 0.26, bright * 0.9, seed_n), t0 + s * beat * 0.5 + rng.randf() * 0.012)
			"block":
				for c in chord:
					StingSynth.mix_into(buf, piano(freq(pal, c), bar_s + 1.5, 0.12), t0 + rng.randf() * 0.03)
				if meter == 4 and rng.randf() < density:
					var top: int = chord[2]
					StingSynth.mix_into(buf, piano(freq(pal, top), beat * 2.0 + 1.0, 0.08), t0 + beat * 2.0)
			"sparse":
				if rng.randf() < 0.45 + density:
					var deg2: int = chord[rng.randi() % 3] + 7
					StingSynth.mix_into(buf, glass(freq(pal, deg2), 5.0, 0.16), t0 + beat * float(rng.randi() % meter))
			"glass":
				for s in meter:
					if s > 0 and rng.randf() > density:
						continue
					var deg3: int = chord[(s + b) % 3] + 7
					StingSynth.mix_into(buf, glass(freq(pal, deg3), 3.5, 0.12), t0 + s * beat)
			"tremolo":
				StingSynth.mix_into(buf, tremolo(freq(pal, chord[0]), bar_s + 0.4, 0.16, 7.0), t0)
				StingSynth.mix_into(buf, tremolo(freq(pal, chord[2]), bar_s + 0.4, 0.11, 7.0), t0)
				for s in meter:          # low pulse on every beat, like a heart going
					StingSynth.mix_into(buf, piano(freq(pal, chord[0] - 7), beat * 0.9, 0.16 if s == 0 else 0.09), t0 + s * beat)

	# --- melody: a two-bar motif, then its answer over the next chords ---
	if melody_on:
		var rhythms: Array = RHYTHMS_3 if meter == 3 else RHYTHMS_4
		var motif: Array = []       # [beat_offset, dur_beats, degree_offset_from_chord_root]
		var deg_rel: int = [0, 2, 4][rng.randi() % 3] + 7
		var at := 0.0
		for mb in 2:
			var rh: Array = rhythms[rng.randi() % rhythms.size()]
			for d in rh:
				motif.append([at, d, deg_rel])
				at += d
				deg_rel = clampi(deg_rel + [-2, -1, -1, 1, 1, 2, 0][rng.randi() % 7], 4, 13)
		var halves := bars / 2
		for h in halves:
			var chord_root: int = prog[(h * 2) % prog.size()]
			var last_chord := triad(prog[(h * 2 + 1) % prog.size()])
			for i in motif.size():
				var m: Array = motif[i]
				var final_note := i == motif.size() - 1
				if not final_note and i > 0 and rng.randf() < (1.0 - density) * 0.45:
					continue           # a rest keeps it breathing
				var deg4: int = chord_root + m[2]
				if h > 0 and not final_note and rng.randf() < 0.3:
					deg4 += [-1, 1][rng.randi() % 2]
				if final_note:
					deg4 = 7 if (h == halves - 1 and (day == 7 or kind == "title")) else _nearest_chord_tone(deg4, last_chord)
				deg4 = clampi(deg4, 3, 15)
				var t := h * 2 * bar_s + float(m[0]) * beat
				var dur := float(m[1]) * beat
				seed_n += 1
				var f := freq(pal, deg4)
				StingSynth.mix_into(buf, _voice(lead, f, dur, 0.42, bright, seed_n), t + rng.randf() * 0.015)
				if lead == "cello" and kind == "day" and day == 2 and final_note:
					StingSynth.mix_into(buf, piano(f * 2.0, 3.0, 0.1), t)

	var verb: float = pal["verb"]
	if kind == "night":
		verb *= 1.2
	var wet := 0.35 if verb < 1.4 else 0.5
	var outb := reverb(buf, verb, wet, 0.35, 2.0)
	return StingSynth.finish(outb, 0.7)

# ---- swells: when the tide turns at the bars ------------------------------

## A slow orchestral breath: a bowed chord crescendos and fades. Opening bars:
## the tonic chord with an added ninth and a ringing high note; closing bars:
## the tonic darkened by a semitone rub.
static func render_swell(day: int, opening: bool) -> PackedFloat32Array:
	var pal := palette(day)
	var length := 11.0
	var buf := PackedFloat32Array()
	buf.resize(int(length * RATE))
	var degs := [-7, 0, 4, 7, 9] if opening else [-7, 0, 2, 4]
	var amps := [0.2, 0.16, 0.13, 0.11, 0.08]
	for i in degs.size():
		var f := freq(pal, degs[i])
		StingSynth.mix_into(buf, StingSynth.bowed(f, 9.0 - i * 0.4, amps[i], 4.2 + i * 0.3, 3.5, 4.0 + i * 0.35), i * 0.25)
	if opening:
		StingSynth.mix_into(buf, glass(freq(pal, 11), 5.0, 0.12), 4.3)
		StingSynth.mix_into(buf, StingSynth.pluck(freq(pal, 7), 4.0, 0.3, pal["bright"], day * 3 + 1), 4.2)
	else:
		var rub: float = pal["root"] * pow(2.0, 1.0 / 12.0)        # a semitone above the tonic
		StingSynth.mix_into(buf, StingSynth.bowed(rub, 6.5, 0.09, 3.5, 2.5, 5.2), 2.5)
		StingSynth.mix_into(buf, piano(freq(pal, -14), 4.0, 0.25), 5.0)
	return StingSynth.finish(reverb(buf, pal["verb"], 0.4, 0.35, 2.0), 0.7)

# ---- loops ---------------------------------------------------------------

## The swell pad: a dark, slowly breathing chord bed under the sea, moving between
## the tonic and the progression's third chord. Every frequency is rounded to a whole
## number of cycles per loop, so the loop point is seamless.
static func render_pad(day: int) -> PackedFloat32Array:
	var pal := palette(day)
	var L := PAD_SECONDS
	var n := int(L * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var b := PackedFloat32Array()
	b.resize(n)
	var prog: Array = pal["prog"]
	var chords := [[-7, 0, 2, 4], [prog[2] - 7, prog[2], prog[2] + 2, prog[2] + 4]]
	for ci in 2:
		var dst: PackedFloat32Array = a if ci == 0 else b
		for vi in 4:
			var deg: int = chords[ci][vi]
			var f0 := freq(pal, deg)
			for detune in [1.0, 1.0035]:
				var f := roundf(f0 * detune * L) / L
				var inc := f / RATE
				var ph := fposmod(vi * 0.31 + detune, 1.0)
				var lfo_k := float(vi + 1)                # whole LFO cycles per loop
				var lfo_w := TAU * lfo_k / n
				var amp := (0.22 if vi == 0 else 0.13) * (1.0 if detune == 1.0 else 0.8)
				for i in n:
					ph += inc
					if ph >= 1.0: ph -= 1.0
					dst[i] += (2.0 * ph - 1.0) * amp * (0.7 + 0.3 * sin(lfo_w * i + vi))
	_lowpass_loop(a, pal["pad_cut"])
	_lowpass_loop(b, pal["pad_cut"] * 1.1)
	_lowpass_loop(a, pal["pad_cut"] * 1.6)
	_lowpass_loop(b, pal["pad_cut"] * 1.6)
	var out := PackedFloat32Array()
	out.resize(n)
	var w := TAU / n
	for i in n:
		var wa := 0.5 + 0.5 * cos(w * i)
		out[i] = a[i] * wa + b[i] * (1.0 - wa)
	_normalise(out, 0.6)
	return out

## The undertow: low cello cluster with a pulsing tremolo and a heartbeat thump.
## Fades in under everything when the water is rising around Arthur. Seamless loop.
static func render_undertow(day: int) -> PackedFloat32Array:
	var pal := palette(day)
	var L := UNDERTOW_SECONDS
	var n := int(L * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var root: float = pal["root"] * 0.5
	var voices := [[root, 0.3], [root * pow(2.0, 1.0 / 12.0), 0.18], [root * 0.5, 0.25], [root * 1.5, 0.08]]
	for v in voices:
		for detune in [1.0, 1.004]:
			var f: float = roundf(v[0] * detune * L) / L
			var inc := f / RATE
			var ph: float = detune * 0.37
			for i in n:
				ph += inc
				if ph >= 1.0: ph -= 1.0
				out[i] += (2.0 * ph - 1.0) * v[1]
	_lowpass_loop(out, 260.0)
	_lowpass_loop(out, 400.0)
	var trem_w := TAU * (6.0 * L) / n               # 6 Hz, whole cycles per loop
	var beat_n := int(0.8 * RATE)                   # 20 beats per 16 s loop
	for i in n:
		out[i] *= 0.62 + 0.38 * sin(trem_w * i)
		var bt := float(i % beat_n) / RATE
		var bt2 := float((i + int(0.22 * RATE)) % beat_n) / RATE   # "lub-dub"
		out[i] += sin(TAU * 52.0 * bt) * exp(-bt * 11.0) * 0.55 + sin(TAU * 48.0 * bt2) * exp(-bt2 * 13.0) * 0.3
	_normalise(out, 0.6)
	return out
