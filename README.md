# Low Tide

A first-person narrative exploration game for PC, made in **Godot 4.4** (GDScript).

January 1998. You are Arthur, the winter keeper of Gannet Rock Light Station, a small island off the coast of Maine. The tide decides where you can walk. The only other voice is Clara, a Coast Guard dispatcher on VHF channel 16. You have seven days.

All seven days and all three endings are implemented. It is still in development: the writing is draft quality, the art is a first pass, and all audio is synthesised placeholder (see [Status](#status)).

## What is in the game

- **Seven days.** Each day has a morning (stove, barometer, tide table, wind the weights, radio check-in with Clara), an expedition (cross the sandbars while the tide allows), and an evening (light the lamp, write the log, call Clara, sleep).
- **The tide is the level design.** A continuous tide model. Low water arrives about 50 minutes later each day. Sandbars close when the water passes 2.1 m. Depth slows you and, if it gets too deep, sweeps you back to the dock. Day 4 is a storm that keeps the range high. Day 5 is a spring low (-0.4 m) that opens the south reef and the causeway.
- **A radio that never pauses the game.** Clara calls on channel 16. You answer with two choices while you keep moving. Your answers move a hidden Trust value, and what you report or withhold changes what she tells you.
- **Story objects.** Six cassette tapes, a satchel and a keeper's journal (log, satchel, tapes), bell buoys, a hydrophone, and landmarks: the wreck, the west sea cave, the north cove and the south reef vault.
- **Three endings:** *The Right Address*, *Left Quiet* and *On the Record*.
- **Diegetic interface.** A pocket watch, a paper tide table, painted tide marks on the dock pilings and the journal. An assist readout can be switched on in settings.
- **Systems.** Autosave and Continue, a pause menu, and full settings: graphics presets (including a Steam Deck preset), audio buses, lighting, remappable keyboard and gamepad bindings, and accessibility options (assist readout, reduce motion, UI and subtitle scale).
- **Look and sound.** A painted sky with sun and moon, ocean with shoreline foam, and a different weather for each day (fog, overcast, dense fog, storm, clear, cold and clear, dawn haze). Audio is synthesised at startup, with procedural music stings.

## Status

Work in progress. Be aware of the following:

- The writing is draft quality and is expected to get a polish pass. All of it is editable text in `dialogue/dialogue.json`.
- There are no audio asset files. Every sound is generated in code (`autoload/audio_director.gd`).
- Radio lines are text with a procedural squelch. There is no voice acting.
- Not implemented: localisation, achievements, cloud saves and Steam integration.
- The Unity port in `unity/` is parked. The Godot project is the reference build.

## Run it

1. Install **Godot 4.4** (the standard build, not .NET). Tested with 4.4.1.
2. Open `project.godot` in the Godot editor and press **F5**. The main scene is `main.tscn`.

The project uses the Forward+ renderer. Screenshots in this repository are rendered with the compatibility renderer (`--rendering-method gl_compatibility`).

Progress is saved to `user://lowtide_save.json` at the start of each day and at wait anchors, and **Continue** on the title screen resumes from it. Settings are in `user://lowtide_settings.cfg`. Endings you have seen are kept in `user://lowtide_endings.json`.

## Controls

Every binding can be changed in **Settings > Controls**.

| Action | Keyboard and mouse | Gamepad |
|---|---|---|
| Move | W A S D | Left stick |
| Look | Mouse | Right stick |
| Brisk walk (uses stamina) | Shift | Left stick click |
| Inspect / use (hold to wind or light) | E | A |
| Binoculars | B or right mouse button | Left trigger |
| Pocket watch | Q | Left bumper |
| Radio reply 1 / 2 | 1 / 2 | D-pad left / right |
| Dismiss radio | X | B |
| Journal | Tab | Back / View |
| Assist readout | F1 | Y |
| Pause | Esc | Start |

Binoculars, the pocket watch and the hold-to-use action can each be switched from hold to toggle in settings. In debug builds, **T** skips time.

## Tests

The suite is a custom headless runner (`tests/run_tests.gd`). It covers the tide model and depth bands, the clock, dialogue conditions, saves and a simulation of the whole week.

```bash
GODOT=/path/to/godot tools/run_all_tests.sh
```

`run_all_tests.sh` runs three steps: the Godot suite (must report `N checks, 0 failures`), a check that the fixtures in `unity/Fixtures` are up to date, and the C# parity tests for the parked Unity port. If you have no .NET SDK, skip the last step:

```bash
SKIP_DOTNET=1 GODOT=/path/to/godot tools/run_all_tests.sh
```

To run only the Godot suite, use `tools/run_tests.sh`. To render screenshots (needs a display or xvfb):

```bash
xvfb-run -a godot --rendering-method gl_compatibility -s tests/screenshot.gd -- /some/output/dir
```

## Repository layout

| Path | What is in it |
|---|---|
| `main.tscn`, `main.gd` | Entry scene: builds the world, the player and the interface |
| `autoload/` | Global singletons: game clock, tide system, game state, day director, saves, radio, audio director, tape player, reactive director, settings |
| `story/` | Day data, conversations, conditions, items, log entries and endings |
| `dialogue/` | `dialogue.json`: every radio line, tape and ending text |
| `world/` | Terrain, island, interiors, ocean, sky, bell buoys, hydrophone, interactables |
| `player/` | First-person controller |
| `ui/` | HUD, menus, settings menu, pocket watch, binocular shader, theme and bundled fonts |
| `audio/` | Procedural music sting synthesis (there are no audio files) |
| `tests/` | The headless test suite and the screenshot tool |
| `tools/` | Test runners, fixture and audio exporters |
| `docs/` | Design and production documents (below) |
| `unity/` | Parked Unity port of the game logic, with its own README |
| `reference/` | The original single-file HTML prototype, kept read-only |
| `marketing/` | Steam store page draft, logo and brand kit, screenshots |

## Documentation

- [Design bible](docs/design_bible.md): pillars, loop, mechanics and amendments
- [Production plan](docs/production_plan.md): decisions, milestones and verification
- [Narrative outline](docs/narrative_outline.md): the truth timeline, the seven days, trust and the endings
- [Dialogue format](docs/dialogue_format.md): how `dialogue.json` works
- [Typography](docs/typography.md) and [audio checklist](docs/audio_checklist.md)
- [Brand guide](docs/brand_guide.md): logo directions, colour, type, voice
- [Third-party licences](docs/licences.md): bundled fonts (SIL Open Font License 1.1)
- [Unity port plan](docs/unity_port_plan.md)
- [Steam kit](marketing/steam/README.md): store page draft and how to regenerate the art
