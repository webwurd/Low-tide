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
var indoors := false
var weather_db := 0.0
## The sea swell, 0..1 (the score's pad breathes with it).
var swell := 0.5
var _hiss: AudioStreamPlayer

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
	_variants["gravel"] = [_thud(210.0, 90.0, 0.09, "saw", 1400.0, 0.7, 0.9), _thud(210.0, 90.0, 0.09, "saw", 1400.0, 0.7, 0.9), _thud(210.0, 90.0, 0.09, "saw", 1400.0, 0.7, 0.9)]
	_variants["concrete"] = [_thud(160.0, 100.0, 0.07, "triangle", 1800.0, 0.9, 0.1), _thud(160.0, 100.0, 0.07, "triangle", 1800.0, 0.9, 0.1)]
	_variants["wet"] = [_thud(120.0, 60.0, 0.12, "sine", 500.0, 0.9, 0.7), _thud(120.0, 60.0, 0.12, "sine", 500.0, 0.9, 0.7)]
	_variants["splash"] = [_splash(), _splash()]
	_variants["squelch"] = [_squelch()]
	_variants["foghorn"] = [_foghorn()]
	_sting_player = AudioStreamPlayer.new()
	_sting_player.bus = "Music"
	add_child(_sting_player)
	_start_sting_render()
	_variants["clunk"] = [_thud(90.0, 40.0, 0.12, "triangle", 500.0, 1.0, 0.3)]
	var hiss := PackedFloat32Array()
	hiss.resize(RATE * 2)
	for i in hiss.size():
		hiss[i] = (_rng.randf() * 2.0 - 1.0) * 0.12
	_hiss = _loop_player(_bandpass(hiss, 3200.0, 0.6), -200.0, "Radio")
	_hiss.stop()
	_hiss.volume_db = -21.5   # hiss stream is now unclipped (22 dB quieter at source)

func _process(delta: float) -> void:
	if not foghorn_enabled or GameClock.paused:
		return
	_foghorn_timer -= delta
	if _foghorn_timer <= 0.0:
		play_sfx("foghorn", -14.0)
		_foghorn_timer = 26.0 + _rng.randf() * 14.0

## time: seconds (for swell), altitude: player y, tide: water height (m).
func update_ambient(time: float, altitude: float, tide: float) -> void:
	swell = 0.5 + 0.5 * sin(time * 0.65)
	var muffle := -14.0 if indoors else 0.0
	_surf.volume_db = -20.0 + swell * 5.0 + clampf(tide - 1.0, 0.0, 3.0) * 1.0 + muffle + weather_db * 0.5
	_wind.volume_db = -30.0 + clampf(altitude, 0.0, 25.0) * 0.45 + muffle + weather_db

func set_tape(on: bool) -> void:
	if on and not _hiss.playing:
		_hiss.play()
	elif not on:
		_hiss.stop()

## Which mixer bus each one-shot plays on (see Settings AUDIO_BUSES).
const SFX_BUS := {"squelch": "Radio", "foghorn": "Ambience", "sting": "Music"}

func play_sfx(sfx_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var list: Array = _variants.get(sfx_name, [])
	if list.is_empty():
		return
	if sfx_name == "squelch":
		volume_db += Settings.vol_to_db(float(Settings.v("radio_static")))
	for p in _pool:
		if not p.playing:
			p.stream = list[_rng.randi() % list.size()]
			p.bus = SFX_BUS.get(sfx_name, "SFX")
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return

var _bells: Dictionary = {}
var _extra: Dictionary = {}
var _sting_data: Dictionary = {}       # name -> PackedFloat32Array (rendered on worker threads)
var _sting_tasks: Dictionary = {}      # name -> WorkerThreadPool task id
var _sting_streams: Dictionary = {}
var _sting_player: AudioStreamPlayer
var _sting_mutex := Mutex.new()

## The four bell-buoy pitches (strike count = compass point).
const BELL_PITCHES := {"bell_north_1": 440.0, "bell_east_2": 523.0, "bell_south_3": 349.0, "bell_west_4": 392.0}

## Every procedurally generated stream by name, for the preview exporter and
## the audio sanity tests.
func catalog() -> Dictionary:
	var out := {"surf_bed": _surf.stream, "wind_bed": _wind.stream, "tape_hiss": _hiss.stream,
		"hydrophone_ping": ping_stream(), "boat_engine": boat_engine_stream()}
	for k in _variants:
		var arr: Array = _variants[k]
		for i in arr.size():
			out["%s_%d" % [k, i]] = arr[i]
	for k in BELL_PITCHES:
		out[k] = bell_stream(BELL_PITCHES[k])
	for k in StingSynth.NAMES:
		out[k] = sting_stream(k)
	return out

# ---- music stings (rendered in the background so startup does not stall) ----

## Worker tasks must be collected before exit, or the engine never shuts down.
func _exit_tree() -> void:
	for id in _sting_tasks.values():
		WorkerThreadPool.wait_for_task_completion(id)
	_sting_tasks.clear()

func _start_sting_render() -> void:
	for n in StingSynth.NAMES:
		_sting_tasks[n] = WorkerThreadPool.add_task(_render_sting.bind(n), false, "render " + n)

func _render_sting(sting: String) -> void:
	var data := StingSynth.render(sting)
	_sting_mutex.lock()
	_sting_data[sting] = data
	_sting_mutex.unlock()

## The stream for a sting. Prefers a composed file res://audio/stings/<name>.(ogg|wav|mp3) if present.
func sting_stream(sting: String) -> AudioStream:
	if _sting_streams.has(sting):
		return _sting_streams[sting]
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://audio/stings/%s.%s" % [sting, ext]
		if ResourceLoader.exists(path):
			_sting_streams[sting] = load(path)
			return _sting_streams[sting]
	if _sting_tasks.has(sting):
		WorkerThreadPool.wait_for_task_completion(_sting_tasks[sting])
		_sting_tasks.erase(sting)
	_sting_mutex.lock()
	var data: PackedFloat32Array = _sting_data.get(sting, PackedFloat32Array())
	_sting_mutex.unlock()
	if data.is_empty():
		return null
	_sting_streams[sting] = _wav(data)
	return _sting_streams[sting]

func play_sting(sting: String, volume_db := -4.0) -> void:
	var st := sting_stream(sting)
	if st == null:
		return
	_sting_player.stream = st
	_sting_player.volume_db = volume_db
	_sting_player.play()

func sting_active() -> bool:
	return _sting_player.playing

func sting_playing() -> String:
	if _sting_player.playing:
		for k in _sting_streams:
			if _sting_streams[k] == _sting_player.stream:
				return k
	return ""

## Hydrophone ping: short sonar-style blip, repeated by world/hydrophone.gd.
func ping_stream() -> AudioStreamWAV:
	if _extra.has("ping"):
		return _extra["ping"]
	var n := int(RATE * 1.4)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = (sin(TAU * 1400.0 * t) * exp(-5.0 * t) + sin(TAU * 2800.0 * t) * 0.25 * exp(-9.0 * t)) * 0.55 * minf(1.0, t * 400.0)
	_extra["ping"] = _wav(out)
	return _extra["ping"]

## Relief-boat engine: low diesel thump over filtered noise. Seamless 3 s loop
## (frequencies are whole cycles per loop).
func boat_engine_stream() -> AudioStreamWAV:
	if _extra.has("boat"):
		return _extra["boat"]
	var noise := _lowpass(_brown_noise(3.0), 160.0)
	var n := noise.size()
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var thump := sin(TAU * 51.0 * t) * (0.55 + 0.45 * sin(TAU * (25.0 / 3.0) * t))
		out[i] = noise[i] * 1.2 + thump * 0.35
	_extra["boat"] = _wav(out, true)
	return _extra["boat"]

## Bell-buoy strike: inharmonic partials with long decay. Cached per pitch.
func bell_stream(freq: float) -> AudioStreamWAV:
	if _bells.has(freq):
		return _bells[freq]
	var n := int(RATE * 3.2)
	var out := PackedFloat32Array()
	out.resize(n)
	var ratios := [1.0, 2.76, 5.4]
	var amps := [1.0, 0.5, 0.25]
	var decays := [1.1, 1.8, 3.0]
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in 3:
			v += sin(TAU * freq * ratios[k] * t) * amps[k] * exp(-decays[k] * t)
		out[i] = v * 0.35 * minf(1.0, t * 200.0)
	_bells[freq] = _wav(out)
	return _bells[freq]

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

func _loop_player(samples: PackedFloat32Array, db: float, bus := "Ambience") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.stream = _wav(samples, true)
	p.volume_db = db
	add_child(p)
	p.play()
	return p

## Brown noise that loops without a click: generate `fade` extra samples and
## blend them into the head, so the last sample flows straight into the first.
func _brown_noise(seconds: float) -> PackedFloat32Array:
	var n := int(RATE * seconds)
	var fade := 2000
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var last := 0.0
	for i in n + fade:
		last = (last + 0.02 * (_rng.randf() * 2.0 - 1.0)) / 1.02
		raw[i] = last * 2.8
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = raw[i]
	for i in fade:
		var a := float(i) / fade
		out[i] = raw[i] * a + raw[n + i] * (1.0 - a)
	return out

## One-pole low-pass. Runs the buffer twice and keeps the second pass, so the
## filter state at the end matches the start (needed for seamless loops).
func _lowpass(src: PackedFloat32Array, fc: float) -> PackedFloat32Array:
	var a := 1.0 - exp(-TAU * fc / RATE)
	var out := PackedFloat32Array()
	out.resize(src.size())
	var y := 0.0
	for pass_i in 2:
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
	for pass_i in 2:
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
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.9:
		for i in n:
			out[i] *= 0.9 / peak
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
