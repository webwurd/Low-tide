# Audio checklist

**There are no audio asset files.** Every sound is synthesised at startup by `autoload/audio_director.gd`
(22.05 kHz, mono, 16-bit). To listen to them as ordinary files:

```bash
godot --headless -s tools/export_audio.gd -- /some/output/dir     # default: res://audio/preview (git-ignored)
```

Automated checks (in `tests/run_tests.gd`) confirm each sound is audible, un-clipped, finite, and that the
four looping beds have no click at the loop point. **Nobody has judged tone by ear yet. That is what this list is for.**

Legend: **Listen for** = what "right" should sound like. **Tune** = where to change it.

## A. Ambient beds (looping, always on)
| ID | What it is | Hear it | Listen for | Tune |
|---|---|---|---|---|
| `surf_bed` | Low-passed brown noise (340 Hz): the sea | Anywhere outdoors; swells louder/softer every ~10 s; louder at high tide; muffled -14 dB indoors | Soft, breathing surf, not a hiss or hum. Swell should feel slow and natural | `update_ambient()`: swell rate `0.65`, base `-20 dB`, tide gain |
| `wind_bed` | Band-passed noise (620 Hz, Q 2.2): wind | Louder up high (summit, lantern); much louder on Day 4 (storm) | Whistling, not whining; should rise as you climb | `update_ambient()`: altitude gain `0.45 dB/m`; `DayData.wind_db` |
| `tape_hiss` | High band-passed noise: cassette hiss | Only while a tape plays (cottage cassette player) | Quiet, steady tape hiss under the subtitles, never tiring | player volume `-21.5 dB` in `_ready()` |

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
| `bell_north_1` `bell_east_2` `bell_south_3` `bell_west_4` | Inharmonic bell at 440 / 523 / 349 / 392 Hz | Four buoys around the island; **1 / 2 / 3 / 4 strikes = N / E / S / W**; best judged on Day 3 (dense fog) | Buoys sound like bells, not synths; you can tell direction and count; pitches distinct but not clashing |
| `hydrophone_ping` | 1400 Hz sonar blip | *(new in M6)* West echo cave, every 14 s until the buoy is switched off | Cold, faint, eerie |
| `boat_engine` | Low diesel thump + noise, seamless loop | *(new in M6)* Relief boat in the ending scene | Distant, approaching; never harsh |

## D. Mixing questions
- Is the bed (surf + wind) too loud under the radio voice-line text, or too quiet to feel alone?
- Do indoors feel properly sheltered (-14 dB surf and wind)? Does the stove need its own crackle (see below)?
- Do bells carry far enough in fog (3D positional, up to 450 m) without cutting through the radio?
- Does `squelch_0` drown subtle moments (tape playback)?

## E. Missing audio (known gaps; not bugs)
Rain on the storm day (Day 4), door open/close, stove crackle, clockwork weights winding, lamp lighting, armchair/bench,
page/journal turn, pocket-watch tick, radio static *between* lines, Clara's voice (text-only), music stings, the
ending's closing sting. Plan: foley and stings in M7.
