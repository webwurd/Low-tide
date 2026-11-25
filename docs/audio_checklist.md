# Audio checklist

**There are no audio asset files.** Every sound is synthesised at startup by `autoload/audio_director.gd`
(22.05 kHz, mono, 16-bit). To listen to them as ordinary files:

```bash
godot --headless -s tools/export_audio.gd -- /some/output/dir     # default: res://audio/preview (git-ignored)
```

Automated checks (in `tests/run_tests.gd`) confirm each sound is audible, un-clipped, finite, and that the
looping beds have no click at the loop point. **Nobody has judged tone by ear yet. That is what this list is for.**

Legend: **Listen for** = what "right" should sound like. **Tune** = where to change it.

## A. Ambient beds (looping, always on)
| ID | What it is | Hear it | Listen for | Tune |
|---|---|---|---|---|
| `surf_bed` | Wash: low-passed brown noise (340 Hz), 7.3 s loop | Outdoors; rises as each wave builds and washes back; louder at high tide; muffled indoors (-14 dB and a lower filter) | Soft surf moving up the shingle, not a hiss or hum | `SeaWind.mix()` "wash"; `_update_beds()` base `-15.5 dB` |
| `surf_deep` | Ground swell: deep brown noise (160 Hz), 11.9 s loop | Under the wash; drifts on slow 61 s / 97 s cycles | Felt more than heard; weight, not rumble | "deep"; base `-22 dB` |
| `surf_foam` | Breaking fizz: band-passed white noise (1.7 kHz), 13.1 s loop | Bursts as each wave breaks, then fades with the wash; the Sea bus filter opens on the break | Foam and pebbles, never static | "foam", `cut_lo`/`cut_hi` |
| `wind_bed` | Band-passed noise (620 Hz, Q 2.2), 9.7 s loop | Always; slow lulls (47 s / 83 s cycles) plus random gusts; louder up high (0.45 dB/m) and on Day 4 | Wind that breathes; rises as you climb | "wind"; `DayData.wind_db` |
| `wind_whistle` | Narrow band (1.15 kHz, Q 6), 14.3 s loop | Only in gusts (most on Day 4); the Wind bus band rises with each gust | A whistle round the lantern, not a whine | "whistle", "wind_cut" |
| `tape_hiss` | High band-passed noise: cassette hiss (5.3 s loop) | Only while a tape plays (cottage cassette player) | Quiet, steady tape hiss under the subtitles, never tiring | player volume `-21.5 dB` in `_ready()` |

**Why it never repeats (playtest 1: "the sea and wind theme needs to be varied"):** the five bed loops have different, coprime-ish
lengths and start at a random point each session, and `audio/sea_wind.gd` mixes them live. Waves arrive at irregular intervals,
with quick doubles and lulls; a set of 3-5 bigger waves with longer washes comes in every 1-3 minutes. Wind gusts arrive at random
(Poisson) over slow lulls. Everything follows the day:

| Day weather | Sea | Wind |
|---|---|---|
| Ordinary (Days 1, 2) | a wave every ~6-12 s, sets every ~2 min | a gust every ~25 s |
| Dense fog (Day 3) | about 3 dB softer, muffled (lower filter), less foam | band slightly lower |
| Storm (Day 4) | pounding: a wave every ~4-6 s, frequent sets, about 4 dB louder, bright foam | a gust every ~5 s, whistling; about 2 dB louder |
| Clear (Days 5, 6) | sparser waves, brighter | as ordinary |
| Still dawn (Day 7) | slow, small waves | barely a breath |

The Sea and Wind buses send to **Ambience**, so the Ambience volume governs them. Tune in `SeaWind.profile_for()`.

## B. Footsteps (one-shots, 2-3 variants each, pitch-randomised)
| ID | Surface | Hear it | Listen for |
|---|---|---|---|
| `wood_0..2` | Pier, all interiors | Walk on the pier or inside | Hollow wooden thud |
| `sand_0..2` | East/west/south sandbars | Cross any bar | Soft wet crunch |
| `rock_0..2` | Summit, granite | Summit / most of the island | Hard boot-on-granite scuff |
| `gravel_0..2` | North cove shelf and bar | North cove | Loud shingle crunch |
| `concrete_0..1` | South reef vault pad | Vault pad (day 5 only) | Short, hard tap |
| `wet_0..1` | Barnacled intertidal rock (0.4 to 2.8 m, near the island) | Walk the shore line | Slappy, damp thump |
| `splash_0..1` | Layered when feet are in water | Wade to ankle depth or deeper | Quick splash on top of the footstep |
Checks: do surfaces sound clearly different? Does brisk walking feel faster (not just louder)? Any variant that sounds wrong or repeated? Tune in `_step_*()` / `_thud()` and `Player` stride (1.9 m walk / 2.4 m brisk).

## C. Radio, tape, instruments
| ID | What it is | Hear it | Listen for |
|---|---|---|---|
| `squelch_0` | VHF squelch beep + noise tail | Every radio call opens and every reply | Believable walkie-talkie "kssht"; not annoying after 100 repeats |
| `clunk_0` | Cassette deck thunk | Tape starts and stops | Mechanical click, short and low |
| `foghorn_0` | Two sawtooth tones (E2 + G#2) lowpassed | Random every 26-40 s outdoors, quieter inside | Distant, mournful, a little menacing; not cartoonish |
| `bell_north_1` `bell_east_2` `bell_south_3` `bell_west_4` | Inharmonic bell at 440 / 523 / 349 / 392 Hz | Four buoys around the island; **1 / 2 / 3 / 4 strikes = N / E / S / W**; ~1 s between strikes, an irregular 4.5-9 s pause between groups, slight force and pitch variation per strike; best judged on Day 3 (dense fog) | Buoys sound like bells, not synths; you can tell direction and count; pitches distinct but not clashing |
| `hydrophone_ping` | 1400 Hz sonar blip | *(new in M6)* West echo cave, every 14 s until the buoy is switched off | Cold, faint, eerie |
| `boat_engine` | Low diesel thump + noise, seamless loop | *(new in M6)* Relief boat in the ending scene | Distant, approaching; never harsh |

## C2. Music stings (placeholder, synthesised: Karplus-Strong guitar + bowed cello + a little room)
Rare by design (bible: no constant score). Each plays once per run, on the **Music** bus.
| ID | Where | Listen for |
|---|---|---|
| `sting_end_a` | Ending A end card | Warm D-major arpeggio over a low cello: resolved, hopeful |
| `sting_end_b` | Ending B end card | Open fifth swelling slowly, two soft high notes: hushed |
| `sting_end_c` | Ending C end card | Three falling plucked notes (A, F, E) over a very low drone: lonely, unresolved |
| `sting_confront` | Clara's Day 6 evening call opens | Minor second under a slow swell, one low pluck: unease |
| `sting_june` | June's tape (tape 2) ends | Tender A-minor figure |
| `sting_walt` | Walt's last tape (tape 4) ends | Two falling notes over a G cello |
Check: do they sound like instruments or like a synth? Too long, too loud over the end-card text, too cheesy? These are **placeholders**:
to use real music, drop `sting_end_a.ogg` (or `.wav`/`.mp3`) etc. into `res://audio/stings/` and it is used instead, with no code change.
Tune in `audio/sting_synth.gd` (`render()` phrases, note timings, levels).

## C3. Foley (synthesised in `audio/foley_synth.gd`)
Recorded files dropped into `res://audio/foley/<name>.(ogg|wav|mp3)` replace these with no code change.
| ID | What it is | Hear it | Listen for |
|---|---|---|---|
| `door_open_0..1` / `door_close_0..1` | Latch click + hinge creak; wooden thud + latch | Any door between outdoors and the cottage/tower | Heavy old door, not a squeaky cartoon hinge |
| `stairs_0..1` | Four creaky wooden treads | Tower stairs up/down | Weight on old wood |
| `stove_0` | Iron door clank, match, fire catching | Lighting the stove (once a day) | Cast iron; the whoomph of kindling |
| `stove_crackle` (loop) | Low fire roar + ember pops | Cottage, once the stove is lit, all day | Cosy, never like rain or static |
| `winding_0` | Ratchet pawl clicks over a groaning drum | Winding the weights | Heavy clockwork, a pause each turn of the crank |
| `lamp_0` | Match, mantle catching, pressure hiss | Lighting the lamp | Soft and satisfying |
| `chair_0..1` / `bed_0` | Wood creak + cushion/blanket rustle | Armchair or bench (wait an hour); going to bed | Comfortable, not horror-movie |
| `page_0..2` / `pen_0` | Paper swish with crinkle; pen strokes | Tide table, logbook open and page turns; writing the log | Paper, not wind |
| `tap_0` | Two knuckle taps on glass | Reading the barometer | The classic "tap the glass" |
| `watch_tick` (loop) | Five beats per second, tick-tock | Holding up the pocket watch (not when Assist pins it) | Tiny, precise, not a clock on the wall |
| `radio_static` (loop) | Band-limited hiss + crackle | Under every radio line while the panel is up; scales with "Radio static intensity" | Should frame Clara's lines, not tire the ear |
| `click_0` | Soft UI tick | Every button (title, pause, settings, radio replies); works while paused | Quiet, unobtrusive |
| `rain_bed` (loop) / `thunder_0..1` | Hiss + low wash + droplets; distant rolling thunder every 35-85 s | Day 4 (storm); muffled -12 dB indoors | Heavy coastal rain; thunder distant, not a jump-scare |

## C4. Adaptive score (placeholder, synthesised: `audio/score_synth.gd` + `autoload/music_director.gd`)
Music arrives in **swells, not a constant score**: a phrase of 15-30 s, then silence (14-50 s) before the next, over a dark pad
that breathes with the sea swell. Settings > Audio > **Score**: Full (default), Sparse (2.5x longer silences, no pad), Stings only.
Each day has its own palette:

| Day | Key / mode | Tempo | Lead + texture | Intent |
|---|---|---|---|---|
| 1 First Watch | D dorian | 66 | guitar, arpeggios | curious, settling in |
| 2 Grey Water | A aeolian | 58 | cello, piano chords | grey, heavy |
| 3 Wool | E phrygian | 46 | glass, sparse, long drone, big room | lost in fog |
| 4 The Blow | C harmonic minor | 88 | cello, tremolo + heartbeat pulse | storm, tension |
| 5 Spring Low | G lydian | 76 | guitar, busy arpeggios | bright, open |
| 6 Frost | B aeolian, 3/4 | 52 | piano, glass | cold, brittle |
| 7 Last Light | D major | 60 | guitar, resolves to the tonic | hushed, ending |

| Cue (per day `dN_`) | When | Listen for |
|---|---|---|
| `title` | Title screen, with pauses | Calm D-dorian guitar and cello; inviting, not epic |
| `morning_0..1` | Indoors in the morning / daytime interiors | Warm guitar by the stove |
| `day_0..2` | Outdoors in daylight | The day's colour (table above) |
| `night_0..1` | After 16:30 or in the evening phase | Piano and cello, slower |
| `pad` (loop) | Under the day/night music, volume follows the surf swell; -9 dB indoors | Felt more than heard; no audible loop point (24 s) |
| `swell_open` / `swell_close` | Sandbars open / close as the tide turns | A rising breath / a darker one with a semitone rub |
| `undertow` (loop) | Fades in as water rises past knee depth; stops new phrases | Low cello cluster, tremolo, heartbeat: dread, not panic |

Mixing rules: ducks -8 dB under radio lines; silent during tapes and stings; endings are left to the stings.
Composed files at `res://audio/music/<cue>.(ogg|wav|mp3)` (e.g. `d3_day_0.ogg`) replace any cue with no code change.
Tune in `ScoreSynth.PALETTES` (keys, tempi, instruments) and `MusicDirector.GAPS` / `*_DB` (silences, levels).

## D. Mixing questions
- Is the bed (surf + wind) too loud under the radio voice-line text, or too quiet to feel alone?
- Does the score sit *under* the sea, or compete with it? Are the silences between phrases long enough?
- Do indoors feel properly sheltered (-14 dB surf and wind)? Does the stove need its own crackle (see below)?
- Do bells carry far enough in fog (3D positional, up to 450 m) without cutting through the radio?
- Does `squelch_0` drown subtle moments (tape playback)?

## E. Missing audio (known gaps; not bugs)
Clara's voice (text-only), wind gusts/shutters on Day 4, gulls, the lens mechanism turning at night.
Stings (C2) and foley (C3) exist but are synthesised placeholders.
