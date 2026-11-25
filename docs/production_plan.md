# Low Tide — Production Plan

## Context
`webwurd/low-tide` is empty (the branch has no commits). Two inputs exist: the **Design Bible** (pillars, loop, mechanics, guardrails) and a **Milestone 1 prototype** (one Three.js HTML file containing a tide sim, a first-person controller, binoculars, a branching radio, procedural audio, and 4 landmarks). This plan turns them into a finishable game, fixes the gaps and contradictions found in them, and records the decisions made in Q&A.

### Decisions locked in (from Q&A)
| Topic | Decision |
|---|---|
| Engine | **Godot 4 (4.4 stable), GDScript**, Forward+ renderer. The prototype is kept as a reference spec, not ported line by line. |
| Platforms | PC/Steam (KB+M) and **gamepad / Steam Deck** as first-class targets. No web export. |
| Length | **7 days, ~2–3 hrs**. About 20–25 real minutes per in-game day. |
| Clock | Continuous outdoors at **1 game-min per real second**. "Wait" anchors (cottage armchair, lantern gallery bench). `T` skip is debug-only. |
| HUD | **Diegetic by default**: a raised pocket watch, a paper tide table, painted tide marks on the dock pilings, and the logbook. An **Assist Mode** setting restores a prototype-style readout. |
| Carrying | A **satchel of key items** (tapes, documents, canister) with no combining or crafting. The bible guardrail #3 gets amended to match. |
| Branching | A hidden **Trust** value plus report/withhold flags. These change Clara's tone, unlock optional evening talks, and pick one of **3 endings** of the same core truth. |
| Voice | **Text + procedural radio squelch** at first. The dialogue pipeline has an optional audio-clip slot per line so VO can be added later. |
| Art | **Stylized low-poly painterly**: flat shading, heavy fog, cool slate vs amber (#526373 / #3a434a / #ffb84d). |
| Mystery | **Cold War + personal grief** (draft below, needs your approval). |

---

## 1. Fixes to the bible and prototype (inconsistencies found)
1. **Water-depth rules are inconsistent.** The bible says bars sit at about 1.6m and close above 2.1m. The prototype blocks movement at 1.15m depth and respawns at 1.25m depth. New single spec, by water depth at Arthur's feet:
   - 0–0.3m (ankle): footsteps splash.
   - 0.3–0.7m (knee): 0.6× speed, cold-water audio, Clara warning if she's on the radio.
   - 0.7–0.95m (thigh): 0.35× speed, screen-edge chill.
   - Above 0.95m: swept, fade to black, Arthur returns to the South Landing Dock, contextual Clara line, and **+45 game-min lost**. No game over.
   - Open ocean stays a hard boundary.
2. **Tides shouldn't be a pure fixed sinusoid.** Real tides arrive about 50 min later each day. Each day gets a **data-driven tide table** (times of highs and lows, plus amplitude) and water height is interpolated between them. Lows drift later through the week, so each day's exploration window moves naturally. Day 5 is a **spring low (−0.4m)** that exposes a new location.
3. **The prototype's HUD violates Pillar 3.** It becomes Assist Mode (see above).
4. **The landmark checklist becomes the logbook.** Objectives are written in Arthur's hand, and there is no checklist UI.
5. **The "No inventory" guardrail is amended** to: "Satchel holds story items only. No combining, crafting, keys, or weight."
6. **The radio auto-hide timer** (6.5s) becomes reading-speed based, and the panel can be dismissed. Dialogue must never pause movement (already true; keep it).

---

## 2. Godot project architecture
```
project.godot
docs/            design_bible.md (amended), narrative_outline.md, tide_tables.md, dialogue_style.md
reference/       milestone_1_prototype.html (archived, read-only)
autoload/        GameClock.gd  TideSystem.gd  GameState.gd  SaveSystem.gd
                 AudioDirector.gd  Settings.gd  DayDirector.gd  RadioSystem.gd
player/          Player.tscn  player_controller.gd  binoculars.gd  pocket_watch.gd  satchel.gd  footsteps.gd
world/island/    GannetRock.tscn  terrain_builder.gd (port of getTerrainHeight → ArrayMesh + HeightMapShape3D)
world/ocean/     Ocean.tscn  ocean.gdshader (vertex waves, foam at shoreline depth)
world/interiors/ Cottage.tscn  LighthouseTower.tscn (stairs, watch room, lantern room)
interactables/   interactable.gd (base: Area3D + raycast focus + prompt)  rituals/*  clues/*  wait_anchor.gd
story/days/      day_01.tres … day_07.tres  (DayData resource: tide table, weather, scripted beats, unlock flags)
dialogue/        *.dialogue (Dialogue Manager addon)  conditions use GameState vars
ui/              radio_panel  logbook  assist_hud  interact_prompt  pause/settings  title
audio/           procedural/ (AudioStreamGenerator ports of CoastalAudioEngine)  sfx/  music_stings/
tests/           GUT unit tests
```
**Key systems and what they reuse from the prototype:**
- **GameClock**: game minutes, day index, time scale, and a pause flag for interiors and cutscenes. Replaces `updateTideClock` timekeeping.
- **TideSystem**: `get_water_height(day, minute)` from the DayData tide table using cosine interpolation between extremes. Emits `threshold_crossed(location_id, open/closed)` for the sandbar gates. The prototype's 0.2–4.2m range and 2.1m submerge rule become defaults.
- **Terrain**: port `getTerrainHeight()` (prototype lines 456–521) to GDScript as a one-time **editor tool** that bakes the mesh and collision. Hand-sculpt from there, because the procedural function is only the blockout.
- **Player**: CharacterBody3D. Walk 3.0 m/s, brisk 6.5 m/s with stamina. Head-bob and footstep surface detection come from terrain material IDs, not the x>25 hack. Binoculars narrow FOV 65°→20° with the dual-circle vignette shader and a rangefinder tied to `binoTarget` nodes.
- **RadioSystem**: wraps Dialogue Manager in a non-blocking panel. Choices are 1/2 or D-pad left/right. A queue gives priority (scripted > reactive > idle chatter). Conditions read location zone, time, tide state, satchel contents, flags, and trust.
- **AudioDirector**: ports the procedural ocean, wind, footsteps, squelch and foghorn. Adds tide-driven surf intensity, elevation-driven wind, a radio band-pass "analog warmth" bus, and buoy bells for fog navigation.
- **SaveSystem**: autosaves at the start of each day and at wait anchors (JSON in `user://`). There is no mid-expedition save, which suits the genre.
- **Input**: an InputMap with KB+M and gamepad parity. Pocket watch on `Q`/LB, binoculars on RMB/LT, interact on `E`/A, logbook on `Tab`/View.

---

## 3. Daily loop implementation
DayDirector runs each day as **Morning (indoor, clock paused until you step outside)** → **Expedition (clock live)** → **Evening (return to the tower, light the lamp, write the log, call Clara)**.
- Morning rituals are tactile one-button interactions: stove/coffee, wind the clockwork weights (hold to crank), read the barometer (sets the weather flavor line), check the tide table, then the Ch-16 check-in.
- The evening triggers when Arthur lights the lamp. If he's still outside at dusk, Clara nudges him on the radio, and the beam becomes the compass home.
- Logbook entries are auto-written from the clues found that day. "Sketches" are pre-drawn illustrations unlocked per clue, so there is no drawing mechanic.

---

## 4. Narrative outline (DRAFT for your approval)
**Truth:** In 1974, *Project Pelagic* was a joint Navy and university program that ran a hydrophone array from Gannet Rock to listen for Soviet submarines. Keeper **Walt Haskell** hosted it. His wife **June**, a university acoustician, drowned servicing the cable vault during a winter spring tide. The Navy classified it as "lost at sea, weather." Walt recorded cassette letters to June for years and then left. The array was never fully decommissioned. Clara's late father was the Coast Guard boatswain who ferried Pelagic crews. Clara has quietly kept the last buoy's battery alive, because its hydrophone still picks up the sound she believes is June's dropped field recorder, still transmitting a beacon pattern. That belief is grief, not fact.

| Day | Weather and tide | Beats |
|---|---|---|
| 1 | Fog, low tide midmorning | Tutorial rituals. East bar opens. **Canister "PROJECT PELAGIC 1974"**. Clara is warm and playful. |
| 2 | Overcast | West Echo Cave. **Warm acoustic buoy**. First cassette (Walt to June). Clara deflects about the buoy. |
| 3 | Dense fog | Navigate by foghorn and buoy bells. North cove: armored cable running into the sea. University logs list June. |
| 4 | Storm, high water all day | Indoor day in the tower and cottage. Tapes 3–4. The longest evening talk. Clara mentions her dad "worked the Pelagic boats." |
| 5 | Clear, **spring low −0.4m** | South reef **cable vault** exposed for a short window. June's last field log. Fresh service marks on the buoy (Coast Guard-issue battery). |
| 6 | Cold, clear | Arthur's evidence confronts Clara. How much she admits depends on Trust. |
| 7 | Dawn | Ending choice. **A**: send the tapes and log to June's family (Clara helps; bittersweet). **B**: let the buoy die and keep the secret together (intimate, quiet). **C** (low trust): report Clara (she goes silent; a lonely ending). Final shot: a boat light through the binoculars in A and B. |

Arthur's backstory is still open. My default: a recently widowed schoolteacher taking the winter post to be alone, which mirrors Walt.

---

## 5. Milestones
| # | Goal | Exit criteria |
|---|---|---|
| **M2: Godot greybox parity** | Port the prototype: terrain bake, ocean shader, tide-table TideSystem, player, binoculars, pocket watch, Assist HUD, radio panel (placeholder lines), 4 landmarks, swept-respawn, procedural audio, gamepad. | Prototype loop playable in Godot on PC and Deck. GUT tests pass for tide math and depth bands. |
| **M3: Day structure and interiors** ✅ | DayDirector, Morning/Expedition/Evening, cottage and tower interiors, rituals, wait anchors, save/load, 7 day tables, day/night + weather lighting, **controls tutorial in New Watch setup**. | Day 1→2 loop works end to end with autosave. |
| **M4: Narrative systems** ✅ | Data-driven dialogue (`dialogue/dialogue.json`: variants, `when` conditions, trust/flags, chained replies) instead of the Dialogue Manager addon (its repo is outside this session's GitHub scope), satchel, cassette player, 3-page journal (log / satchel / tapes), zone-aware reactive lines. | Day 1 + Day 2 scripted with report/withhold branching. |
| **M5: Full island blockout and weather** ✅ | North cove (cable hut + armored cable), south reef cable vault (Day 5 spring low only), 4 bell buoys (1 N / 2 E / 3 S / 4 W strikes) for fog navigation, morning mist + per-day fog, gravel/concrete/wet/sand/rock surfaces. | All locations reachable under the correct tides (verified by walking them with the real controller). |
| **M6: Content** | Write and implement Days 1–7, 4–6 tapes, and 3 endings. | Full playthrough on all 3 ending paths. |
| **M6.5: Ship-quality art pass** | Painterly "Firewatch" look on a real asset pipeline (see `docs/art_direction.md`): painted sky + sun path + layered colour fog + grade (SkyRig), generated textures and painterly materials, terrain splat and Gerstner sea, vegetation, landmark/interior scenes, hero models for every interactable, quality-aware lighting, export presets. **Title screen** with a live dusk backdrop; **prologue** (typed fragments with choices + the tender crossing; first-draft text). Supersedes the Charm pass art (#2) while keeping its UI/menus/settings. | Every screenshot vantage reads as finished art; tests pass; exported build matches the editor. |
| **M7: Polish, settings and ship (Godot)** | Unity port **parked** (decision: stay with Godot). M7 proceeds in Godot: Settings + pause menus, accessibility, central UI theme and font roles, procedural placeholder music stings, procedural painterly art pass, perf/quality presets, Windows/Linux export presets. Steam deferred. | Release candidate. |
| *(superseded)* M7: Art, audio, settings and ship | Stylized art pass, **typography** (see below), music stings, **Settings menu** (see below), pause menu with "replay controls tutorial", accessibility (subtitle size, hold→toggle), Deck perf (≥40 fps at 800p), Steam build. | Release candidate. |

### M5 design notes
- Day 5 has **two** spring lows (about 10:50 and 23:55). The reef is walkable for ~133 game minutes around the daytime one; the late one falls after Arthur is sent home at 21:00.
- The vault bar crest is -1.0 m; at the spring low (-0.4 m) the water is knee deep (0.6x speed). The causeway lane is **dead level out to exactly 2 m** from the centreline, then slopes 1:1 into the trench, so Arthur is safe within 2 m and swept from about 2.4 m. A sign post and 14 orange-tipped lane-edge poles (at +/-2 m) mark it. Terrain mesh resolution was raised to 0.7 m cells (was 1.17 m) so the lane is honoured by the physical mesh.
- Cassette player plays unheard tapes in story order, not pickup order.
- Tape 2 (June's recording) and the cable/vault conversations are draft text for M6.

### Audio
No audio asset files exist; everything is synthesised (`autoload/audio_director.gd`). See `docs/audio_checklist.md` for what to listen to and `tools/export_audio.gd` to render every sound to WAV. Automated sanity checks cover clipping, silence, NaN and loop-seam clicks.

### Settings menu spec (requested; reachable from the title screen and the pause menu)
- **Graphics:** quality presets (Low / Medium / High / Deck), resolution, window mode, vsync, FPS cap, render scale, shadow quality and distance, fog quality, MSAA/FXAA, ocean detail, Compatibility-renderer fallback for older GPUs.
- **Audio:** master, ambience (surf and wind), footsteps/SFX, radio/voice, music buses, radio static intensity, subtitles size and background, mono mix.
- **Lighting:** brightness/gamma slider, exposure, night-brightness assist (lifts the darkest scenes), fog density scale, bloom/glow toggle, lamp-beam intensity, optional colour-grade strength.
- **Controls:** rebinding for keyboard/mouse and gamepad, look sensitivity (separate for binoculars), invert Y, stick deadzone, hold-vs-toggle for binoculars/watch/interact-hold.
- **Accessibility:** Assist HUD default on/off, reduce head-bob, reduce screen shake/fade durations.
- Persisted to `user://settings.cfg` through the existing `Settings` autoload. The controls tutorial shown in New Watch setup (M3) can be replayed from here.

### Typography (requested)
Replace the placeholder default font with something different and fresh. Decision deferred; requirements, a text-surface inventory and an in-engine test plan are in `docs/typography.md`. Includes moving UI styling into one `Theme` resource.

**Next session (on approval):** scaffold the Godot project on `claude/tender-brahmagupta-k7oa6r`, commit `docs/` (amended bible, this plan, narrative outline, tide tables), archive the prototype in `reference/`, then start M2.

---

## 6. Remaining open questions (defaults assumed unless you say otherwise)
- Arthur's backstory: the widowed-teacher default above.
- Character names Walt, June and "Station Penobscot" are placeholders. (Resolved: renamed to the fictional "Station Penobscot".)
- Should Clara ever appear in person? Default: no, only the ending's boat light, which respects the two-person cast.
- Music composer or sourcing is TBD. Default: synthesised placeholder stings (M7b) and an adaptive score in swells (M7d), each replaceable by composed files.
- Is there a team or deadline? Default: solo or small team, no fixed date.

---

## 7. Verification
- **Unit + smoke tests (custom headless runner `tests/run_tests.gd`; GUT's repo is outside this session's GitHub scope):** tide interpolation against the tide tables, threshold events at 2.1m, depth-band classification, clock rollover and day advance, dialogue condition evaluation, save/load round-trip. Run with `godot --headless -s tests/run_tests.gd` (non-zero exit on failure). Screenshots: `xvfb-run -a godot --rendering-method gl_compatibility -s tests/screenshot.gd -- <outdir>`.
- **CI:** a GitHub Actions workflow using a Godot 4.4 headless container to run GUT and a Linux export smoke build.
- **Playtest checklist per milestone:** cross the East bar at low tide and get swept on the rising tide (fade, dock, Clara line, −45 min); binocular rangefinder labels; dialogue while walking; gamepad-only full loop; Assist toggle; Deck framerate via Godot's monitor overlay.
- **In this container:** install the Godot 4.4 headless Linux binary (if the network allows it) to run tests and a headless scene-load smoke test. Visual checks need your machine or a Deck.
