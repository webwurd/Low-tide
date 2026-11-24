# Unity port plan: PARKED

> **Decision (project owner): stay with Godot.** The Unity port is parked, not deleted. The engine-free C# core
> and its Godot-fixture parity tests remain in `unity/` as a verified starting point if the decision is ever
> revisited. Nothing in the Godot build depends on `unity/`, and the main test gate treats the C# tests as optional.
> The original plan follows for reference.

# Unity port plan (final build: Unity 6 LTS + URP, C#)

**Status:** Godot 4.4 build (M1-M6) is the reference and is frozen apart from shared data and fixture export.
The final product is built in Unity under `unity/`. Steam integration is deferred.

## Strategy
1. **Godot is the oracle.** `tools/export_fixtures.gd` runs the real Godot game logic and writes golden data to `unity/Fixtures/*.json` (inputs live in `unity/Fixtures/spec.json`). Exports are deterministic.
2. **Engine-free C# core** (`unity/Assets/Scripts/Core`, asmdef `LowTide.Core`, `noEngineReferences`): tide, terrain math, conditions, conversations, radio, day director, reactions, saves, endings, trust simulation. Uses Newtonsoft.Json. C# language level 9 (what Unity 6 supports).
3. **Parity tests** (`unity/Assets/Tests/EditMode`, NUnit) compare the core to the fixtures. The same test sources run two ways: `dotnet test` (no Unity needed) and the Unity Test Runner.
4. **Unity game layer** (`LowTide.Game`, later): world, player, UI, audio, lighting, ending scenes. Built in code at runtime from one bootstrap scene, mirroring the Godot structure.
5. **Shared data:** `dialogue/dialogue.json` is the single source of truth; `tools/sync_unity_data.sh` copies it to `unity/Assets/StreamingAssets/` (checked by both test suites).

## Where each Godot module goes
| Godot | C# (Core unless noted) |
|---|---|
| `autoload/tide_system.gd` | `TideModel` |
| `world/terrain.gd` (height, zone, surface) | `TerrainMath` (float32 `Vec2` like Godot so boundaries match). Mesh/colour: Game layer |
| `story/conditions.gd` | `Conditions` |
| `story/conversations.gd` + `dialogue.json` | `Conversations`, `Conv`, `ReactionDef`, `TapeDef` |
| `autoload/radio_system.gd` | `RadioLogic` (host owns the timer) |
| `autoload/day_director.gd` | `DayDirector` |
| `autoload/reactive_director.gd` | `ReactiveDirector` |
| `autoload/game_state.gd`, `game_clock.gd` | `GameState`, `GameClock` |
| `autoload/save_system.gd` | `SaveData` (same JSON schema; Godot saves load in C#) |
| `story/days.gd`, `items.gd`, `log_entries.gd`, `endings.gd` | `Days`, `Items`, `LogEntries`, `Endings` |
| trust simulation in tests | `TrustSimulation` |
| `player/`, `world/island.gd`, `interiors.gd`, `ocean.*`, `ui/hud.gd`, `main.gd` | Game layer (U2-U5) |
| `autoload/audio_director.gd` (synth) | Import the rendered WAV catalogue (`tools/export_audio.gd`); stings synthesised later |

## Stages
| Stage | Scope | Status |
|---|---|---|
| U0 Bootstrap | `unity/` skeleton, manifest, asmdefs, gitignore | **Skeleton written; not yet opened in Unity** (ProjectSettings are generated on first open) |
| U1 Core | Port + fixture-parity tests | **Done. 27 parity tests pass under `dotnet test`**; Unity EditMode run pending |
| U2 World + player | Terrain/ocean/island/interiors, controller, interaction, binoculars | Needs Unity access |
| U3 UI + typography | Input System, HUD, radio, journal, tutorial, chosen fonts via TMP | Needs Unity access; fonts pending specimen choice |
| U4 Audio | WAV catalogue, mixer buses, 3D bells/ping/boat, procedural stings | Needs Unity access |
| U5 Loop + look | Day loop, endings scenes, painterly pass, Settings/pause menus | Needs Unity access |
| U6 Perf + build | Steam Deck-class budget, Windows/Linux builds | Needs Unity access |

Unity itself is not reachable from the cloud sandbox. U2+ run on the user's computer through Remote Control (see `unity/README.md`).

## Running the checks
```bash
GODOT=/path/to/godot tools/run_all_tests.sh     # Godot suite + fixtures-are-fresh + dotnet parity tests
```
After changing game data or logic in Godot: `tools/sync_unity_data.sh`, then re-export fixtures
(`godot --headless -s tools/export_fixtures.gd`), run the gate, commit `unity/Fixtures`.
