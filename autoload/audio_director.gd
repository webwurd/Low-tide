extends Node
## Procedural audio (no external assets). Ports the prototype's Web Audio
## synth: looping surf + wind beds, surface footsteps, radio squelch, foghorn.
## All samples are generated once at startup into AudioStreamWAV buffers.

const RATE := 22050
const POOL := 6

var _rng := RandomNumberGenerator.new()
var _surf: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _variants: Dictionary = {}     # name -> Array[AudioStreamWAV]
var _foghorn_timer := 14.0
var foghorn_enabled := true

func _ready() -> void:
	_rng.seed = 1998
	var noise := _brown_noise(4.0)
	_surf = _loop_player(_lowpass(noise, 340.0), -17.0)
	_wind = _loop_player(_bandpass(noise, 620.0, 2.2), -28.0)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_variants["wood"] = [_step_wood(), _step_wood(), _step_wood()]
	_variants["sand"] = [_step_sand(), _step_sand(), _step_sand()]
	_variants["rock"] = [_step_rock(), _step_rock(), _step_rock()]
	_variants["splash"] = [_splash(), _splash()]
	_variants["squelch"] = [_squelch()]
	_variants["foghorn"] = [_foghorn()]

func _process(delta: float) -> void:
	if not foghorn_enabled or GameClock.paused:
		return
	_foghorn_timer -= delta
	if _foghorn_timer <= 0.0:
		play_sfx("foghorn", -14.0)
		_foghorn_timer = 26.0 + _rng.randf() * 14.0

## time: seconds (for swell), altitude: player y, tide: water height (m).
func update_ambient(time: float, altitude: float, tide: float) -> void:
	var swell := 0.5 + 0.5 * sin(time * 0.65)
	_surf.volume_db = -20.0 + swell * 5.0 + clampf(tide - 1.0, 0.0, 3.0) * 1.0
	_wind.volume_db = -30.0 + clampf(altitude, 0.0, 25.0) * 0.45

func play_sfx(sfx_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var list: Array = _variants.get(sfx_name, [])
	if list.is_empty():
		return
	for p in _pool:
		if not p.playing:
			p.stream = list[_rng.randi() % list.size()]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return

func play_footstep(surface: String, brisk := false, wet := false) -> void:
	var pitch := 0.92 + _rng.randf() * 0.16
	play_sfx(surface, -6.0 if not brisk else -3.0, pitch)
	if wet:
		play_sfx("splash", -9.0, pitch)

# --- synthesis helpers -------------------------------------------------

func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

func _loop_player(samples: PackedFloat32Array, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = _wav(samples, true)
	p.volume_db = db
	add_child(p)
	p.play()
	return p

func _brown_noise(seconds: float) -> PackedFloat32Array:
	var n := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		last = (last + 0.02 * (_rng.randf() * 2.0 - 1.0)) / 1.02
		out[i] = last * 2.8
	# Crossfade the tail into the head so the loop point does not click.
	var fade := 2000
	for i in fade:
		var a := float(i) / fade
		out[n - fade + i] = out[n - fade + i] * (1.0 - a) + out[i] * a
	return out

func _lowpass(src: PackedFloat32Array, fc: float) -> PackedFloat32Array:
	var a := 1.0 - exp(-TAU * fc / RATE)
	var out := PackedFloat32Array()
	out.resize(src.size())
	var y := 0.0
	for i in src.size():
		y += a * (src[i] - y)
		out[i] = y
	return out

func _bandpass(src: PackedFloat32Array, fc: float, q: float) -> PackedFloat32Array:
	var f := 2.0 * sin(PI * fc / RATE)
	var damp := 1.0 / q
	var low := 0.0
	var band := 0.0
	var out := PackedFloat32Array()
	out.resize(src.size())
	for i in src.size():
		low += f * band
		var high := src[i] - low - damp * band
		band += f * high
		out[i] = band * 1.5
	return out

func _thud(f0: float, f1: float, dur: float, wave: String, cutoff: float, gain: float, noise_amt := 0.0) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var lp := 0.0
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var fj := _rng.randf() * 20.0
	for i in n:
		var t := float(i) / n
		var f := f0 * pow(f1 / f0, t) + fj
		phase += f / RATE
		var s := 0.0
		match wave:
			"triangle": s = 4.0 * absf(fposmod(phase, 1.0) - 0.5) - 1.0
			"saw": s = 2.0 * fposmod(phase, 1.0) - 1.0
			_: s = sin(phase * TAU)
		s += noise_amt * (_rng.randf() * 2.0 - 1.0)
		lp += a * (s - lp)
		out[i] = lp * gain * exp(-5.0 * t)
	return _wav(out)

func _step_wood() -> AudioStreamWAV: return _thud(115.0, 48.0, 0.11, "triangle", 420.0, 1.1)
func _step_sand() -> AudioStreamWAV: return _thud(180.0, 70.0, 0.1, "sine", 900.0, 0.8, 0.5)
func _step_rock() -> AudioStreamWAV: return _thud(140.0, 55.0, 0.09, "saw", 650.0, 0.8, 0.25)

func _splash() -> AudioStreamWAV:
	var n := int(RATE * 0.25)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		lp += 0.35 * ((_rng.randf() * 2.0 - 1.0) - lp)
		out[i] = lp * 0.5 * exp(-6.0 * t)
	return _wav(out)

func _squelch() -> AudioStreamWAV:
	var n := int(RATE * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		if t < 0.14:
			var f := 1450.0 if t < 0.04 else 1120.0
			s += sin(TAU * f * t) * 0.35 * exp(-t * 18.0)
		if t > 0.1:
			s += (_rng.randf() * 2.0 - 1.0) * 0.22 * exp(-(t - 0.1) * 14.0)
		out[i] = s
	return _wav(out)

func _foghorn() -> AudioStreamWAV:
	var n := int(RATE * 3.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp1 := 0.0
	var a := 1.0 - exp(-TAU * 260.0 / RATE)
	for i in n:
		var t := float(i) / RATE
		var s := (2.0 * fposmod(82.41 * t, 1.0) - 1.0) + (2.0 * fposmod(103.83 * t, 1.0) - 1.0)
		lp1 += a * (s - lp1)
		var env := 0.0
		if t < 0.6: env = t / 0.6
		elif t < 2.2: env = 1.0
		else: env = exp(-(t - 2.2) * 2.6)
		out[i] = lp1 * env * 0.5
	return _wav(out)
