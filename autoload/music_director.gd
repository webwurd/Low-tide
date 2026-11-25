extends Node
## Adaptive background score. Music arrives in swells and recedes into the sea:
## short phrases with silences between them, over a pad that breathes with the
## surf, chosen from the day's palette (see audio/score_synth.gd) and the moment:
##
##   title     the title theme, with pauses
##   morning   warm guitar by the stove (indoors, morning rituals, daytime interiors)
##   day       the day's own expedition music + the swell pad (outdoors)
##   night     piano and cello after dusk, pad lower
##   silent    endings (the stings own them) or "Stings only" in Settings
##
## Layered on top: a swell when the tide turns at the bars, and the undertow, which
## fades in as water rises around Arthur and stops new phrases while he is in danger.
## Music ducks under radio lines, fades out for tapes and under the stings.
## Main calls tick(ctx, delta) every frame. All cues render on worker threads;
## nothing ever blocks the main thread waiting for one.

const PHRASE_DB := -9.0
const PAD_DB := -21.0
const UNDERTOW_MAX_DB := -8.0
const SILENT_DB := -60.0
const DUSK_MINUTE := 990.0
const DAWN_MINUTE := 360.0

## Seconds of silence between phrases, per mood: [min, max]. "Sparse" multiplies them.
const GAPS := {"title": [5.0, 9.0], "morning": [14.0, 32.0], "day": [20.0, 50.0], "night": [22.0, 48.0]}
const POOLS := {"morning": ["morning_0", "morning_1"], "day": ["day_0", "day_1", "day_2"], "night": ["night_0", "night_1"]}

var mood := ""
var day := 0
var level := 2                     # Settings "music_score": 0 stings only, 1 sparse, 2 full
var danger := 0.0
var _gap := 3.0
var _last_cue := ""
var _rng := RandomNumberGenerator.new()
var _phrase: AudioStreamPlayer
var _pads: Array[AudioStreamPlayer] = []
var _pad_cue := ["", ""]
var _active_pad := 0
var _undertow: AudioStreamPlayer
var _duck := 0.0                   # dB, smoothed
var _phrase_fade := 0.0            # dB offset applied while fading a phrase out
var _fading := false
var _pending_swell := ""
var _streams: Dictionary = {}      # cue -> AudioStream
var _data: Dictionary = {}         # cue -> PackedFloat32Array (finished renders)
var _tasks: Dictionary = {}        # cue -> WorkerThreadPool task id
var _mutex := Mutex.new()

func _ready() -> void:
	_rng.seed = 1999
	_phrase = _player()
	for i in 2:
		_pads.append(_player())
	_undertow = _player()
	request("title")
	request_day(1)
	TideSystem.threshold_crossed.connect(_on_tide_turn)

func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = SILENT_DB
	add_child(p)
	return p

func _exit_tree() -> void:
	for cue in _tasks:
		if _tasks[cue] != -1:
			WorkerThreadPool.wait_for_task_completion(_tasks[cue])
	_tasks.clear()

# ---- rendering -------------------------------------------------------------

func request(cue: String) -> void:
	if _streams.has(cue) or _tasks.has(cue) or _file_stream(cue) != null:
		return
	_tasks[cue] = WorkerThreadPool.add_task(_render.bind(cue), false, "score " + cue)

func request_day(d: int) -> void:
	for cue in ScoreSynth.day_cues(d):
		request(cue)

func _render(cue: String) -> void:
	var data := ScoreSynth.render(cue)
	_mutex.lock()
	_data[cue] = data
	_mutex.unlock()

func _file_stream(cue: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://audio/music/%s.%s" % [cue, ext]
		if ResourceLoader.exists(path):
			var st: AudioStream = load(path)
			if ScoreSynth.is_loop(cue):
				if st is AudioStreamOggVorbis or st is AudioStreamMP3:
					st.loop = true
			_streams[cue] = st
			return st
	return null

## The stream for a cue if it is ready, else null (never waits).
func ready_stream(cue: String) -> AudioStream:
	if _streams.has(cue):
		return _streams[cue]
	var fs := _file_stream(cue)
	if fs != null:
		return fs
	if not _tasks.has(cue):
		request(cue)
		return null
	if _tasks[cue] != -1:
		if not WorkerThreadPool.is_task_completed(_tasks[cue]):
			return null
		WorkerThreadPool.wait_for_task_completion(_tasks[cue])
	_tasks.erase(cue)
	_mutex.lock()
	var data: PackedFloat32Array = _data.get(cue, PackedFloat32Array())
	_data.erase(cue)
	_mutex.unlock()
	if data.is_empty():
		return null
	_streams[cue] = _wav(data, ScoreSynth.is_loop(cue))
	return _streams[cue]

## Blocking variant for tests and the audio exporter.
func stream_now(cue: String) -> AudioStream:
	request(cue)
	if _tasks.has(cue) and _tasks[cue] != -1:
		WorkerThreadPool.wait_for_task_completion(_tasks[cue])
		_tasks[cue] = -1           # waited: the id is no longer valid
	var st := ready_stream(cue)
	return st

## Frees cues from days other than `keep` and the next one (memory stays ~20 MB).
func _evict(keep: int) -> void:
	for cue in _streams.keys():
		if cue == "title":
			continue
		var d := int(cue.split("_")[0].substr(1))
		if d != keep and d != keep + 1 and not _is_playing(_streams[cue]):
			_streams.erase(cue)

func _is_playing(st: AudioStream) -> bool:
	if _phrase.playing and _phrase.stream == st:
		return true
	for p in _pads:
		if p.playing and p.stream == st:
			return true
	return _undertow.playing and _undertow.stream == st

# ---- moods -----------------------------------------------------------------

## Which music fits this moment. ctx keys: started, ending, location, phase
## (DayDirector.Phase), minute, level.
static func choose_mood(ctx: Dictionary) -> String:
	if int(ctx.get("level", 2)) == 0:
		return "silent"
	if not ctx.get("started", false):
		return "title"
	if str(ctx.get("ending", "")) != "":
		return "silent"
	var minute: float = ctx.get("minute", 600.0)
	var night: bool = int(ctx.get("phase", 0)) == 2 or minute >= DUSK_MINUTE or minute < DAWN_MINUTE
	if night:
		return "night"
	if str(ctx.get("location", "cottage")) == "outdoors":
		return "day"
	return "morning"

## How threatening the water is (0..1) from the depth at Arthur's feet.
static func danger_from(depth: float, outdoors: bool) -> float:
	if not outdoors:
		return 0.0
	return clampf((depth - 0.2) / (TideSystem.SWEPT_DEPTH - 0.2), 0.0, 1.0)

func tick(ctx: Dictionary, delta: float) -> void:
	level = int(ctx.get("level", 2))
	var d := int(ctx.get("day", 1))
	if d != day:
		day = d
		request_day(day)
		request_day(mini(day + 1, 7))
		_evict(day)
	var m := choose_mood(ctx)
	if m != mood:
		_change_mood(m)
	var outdoors := str(ctx.get("location", "")) == "outdoors"
	var target_danger := danger_from(float(ctx.get("depth", 0.0)), outdoors) if mood == "day" or mood == "night" else 0.0
	danger = move_toward(danger, target_danger, delta * (0.5 if target_danger > danger else 0.2))

	# Ducking: radio lines pull the music down; tapes and stings silence it.
	var duck_target := 0.0
	if ctx.get("radio", false):
		duck_target = -8.0
	if ctx.get("tape", false) or ctx.get("sting", false):
		duck_target = -60.0
	_duck = move_toward(_duck, duck_target, delta * (60.0 if duck_target < _duck else 6.0))

	_update_phrase(delta, ctx)
	_update_pad(delta, ctx, outdoors)
	_update_undertow(delta)

func _change_mood(m: String) -> void:
	var from := mood
	mood = m
	if _phrase.playing:
		_fading = true
	# A new place or time introduces itself soon; leaving the title is quicker still.
	_gap = _rng.randf_range(1.5, 3.0) if from == "title" or from == "" else _rng.randf_range(4.0, 9.0)
	if m == "title":
		_gap = 0.8

func _update_phrase(delta: float, ctx: Dictionary) -> void:
	if _fading:
		_phrase_fade -= delta * 12.0
		if _phrase_fade <= -40.0 or not _phrase.playing:
			_phrase.stop()
			_fading = false
			_phrase_fade = 0.0
	_phrase.volume_db = PHRASE_DB + _duck + _phrase_fade - danger * 10.0 + (2.0 if mood == "title" else 0.0)
	if _phrase.playing or _fading:
		return
	if mood == "silent" or ctx.get("tape", false) or ctx.get("sting", false):
		return
	if danger > 0.35:
		return
	_gap -= delta
	if _gap > 0.0:
		return
	var cue := _pending_swell if _pending_swell != "" else _next_cue()
	_pending_swell = ""
	var st := ready_stream(cue)
	if st == null:
		_gap = 1.0                 # still rendering: try again shortly
		return
	_last_cue = cue
	_phrase.stream = st
	_phrase_fade = 0.0
	_phrase.volume_db = PHRASE_DB + _duck
	_phrase.play()
	var g: Array = GAPS.get(mood, [20.0, 40.0])
	_gap = _rng.randf_range(g[0], g[1]) * (2.5 if level == 1 else 1.0)

func _next_cue() -> String:
	if mood == "title":
		return "title"
	var pool: Array = POOLS.get(mood, POOLS["day"])
	var choices: Array = []
	for c in pool:
		var cue := "d%d_%s" % [day, c]
		if cue != _last_cue:
			choices.append(cue)
	return choices[_rng.randi() % choices.size()]

## The sandbars opening or closing: the next thing the score plays is a swell.
func _on_tide_turn(open: bool) -> void:
	if mood != "day" and mood != "night":
		return
	_pending_swell = "d%d_swell_%s" % [day, "open" if open else "close"]
	if _phrase.playing:
		_fading = true
	_gap = 0.5

func _update_pad(delta: float, ctx: Dictionary, outdoors: bool) -> void:
	var want := ""
	if level == 2 and (mood == "day" or mood == "night"):
		want = "d%d_pad" % day
	if want != "" and _pad_cue[_active_pad] != want:
		var st := ready_stream(want)
		if st != null:
			_active_pad = 1 - _active_pad
			var p := _pads[_active_pad]
			p.stream = st
			p.volume_db = SILENT_DB
			p.play(_rng.randf() * ScoreSynth.PAD_SECONDS)
			_pad_cue[_active_pad] = want
	var swell: float = ctx.get("swell", 0.5)
	var target := PAD_DB + swell * 6.0 + _duck * 0.6 - (3.0 if mood == "night" else 0.0) - (9.0 if not outdoors else 0.0) + danger * 4.0
	for i in 2:
		var p := _pads[i]
		var tdb := target if (i == _active_pad and want != "" and _pad_cue[i] == want) else SILENT_DB
		p.volume_db = move_toward(p.volume_db, tdb, delta * (10.0 if tdb > p.volume_db else 8.0) if absf(tdb - p.volume_db) < 20.0 else delta * 15.0)
		if tdb == SILENT_DB and p.volume_db <= SILENT_DB + 0.5 and p.playing:
			p.stop()
			_pad_cue[i] = ""

func _update_undertow(delta: float) -> void:
	var want := "d%d_undertow" % day
	if danger > 0.01 and (not _undertow.playing or _undertow.stream != _streams.get(want)):
		var st := ready_stream(want)
		if st != null:
			_undertow.stream = st
			_undertow.volume_db = SILENT_DB
			_undertow.play()
	if not _undertow.playing:
		return
	var tdb := lerpf(SILENT_DB, UNDERTOW_MAX_DB, pow(danger, 0.6)) + minf(_duck, 0.0) * 0.3
	_undertow.volume_db = tdb
	if danger <= 0.0:
		_undertow.stop()

## Name of the phrase/swell cue playing right now ("" if none).
func playing_cue() -> String:
	return _last_cue if _phrase.playing else ""

func pad_playing() -> bool:
	for p in _pads:
		if p.playing and p.volume_db > SILENT_DB + 1.0:
			return true
	return false

## Everything the score can play, for the exporter and tests (renders synchronously).
func catalog(days: Array = [1, 2, 3, 4, 5, 6, 7]) -> Dictionary:
	var out := {"music_title": stream_now("title")}
	for d in days:
		for cue in ScoreSynth.day_cues(d):
			out["music_" + cue] = stream_now(cue)
	return out

func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = ScoreSynth.RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w
