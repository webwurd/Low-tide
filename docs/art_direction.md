# Low Tide — Art Direction (M6.5)

Touchstone: the *feel* of Firewatch, transplanted to a Maine island in winter 1998.
We borrow principles, never assets or compositions.

## Principles
1. **The sky sets the palette.** Every outdoor frame is lit by the sky: ambient,
   reflections and fog all sample it. Change the sky and the island follows.
2. **Depth reads as colour layers.** Near rock is saturated and dark; the sea stacks
   are a step lighter and bluer; the distant mainland ridges are flat silhouettes in
   the fog colour. Aerial perspective does most of the work, not detail.
3. **Warm key, cool shadow.** Sunlight is low and golden for much of the short winter
   day. Shadows never go black or grey: they are tinted slate-violet.
4. **Shape first, texture second.** Medium-poly forms with soft bevels and chunky
   silhouettes. Textures are low-contrast, painted-looking breakup, never photographic.
   No outlines, no faceted low-poly, no micro-detail noise.
5. **Amber means people.** The lamp, the cottage windows and the stove are the only
   saturated warm light at night. They bloom.

## Palette key
| Role | Colour |
|---|---|
| Slate fog / day sky horizon | `#526373` → `#8fa7b8` |
| Wet granite | `#3a434a` |
| Dry granite highlight | `#9a8f88` (pink-grey) |
| Winter grass | `#a08a55` → `#6f6a3e` |
| Spruce | `#2c3d36` |
| Sea, deep → shallow | `#14303d` → `#2f6b6e` |
| Foam | `#dfe6e3` |
| Whitewash | `#e4e1d8` |
| Keeper red | `#8f2d2d` |
| Lamp amber | `#ffb84d` |
| Shadow tint | `#3c3a5c` |
| Golden-hour sun | `#ffb070` |

## Time of day (winter, ~44°N)
Sunrise ~07:05, sunset ~16:05; the sun peaks at ~24° in the south. Night fog is
deep blue-black (`#0d1520`), lit by the moon and the lighthouse beam.

| Key | Sky (zenith / horizon) | Sun |
|---|---|---|
| Night | `#060b14` / `#121d2b` | moonlight `#7f95c4`, low |
| Dawn 07:00 | `#33405e` / `#e39a7a` | `#ff9a5c` |
| Morning | `#4f7399` / `#c9cfcf` | `#ffd2a0` |
| Noon | `#5b84ad` / `#b7c9d4` | `#fff0dc` |
| Golden 15:15 | `#4d6a92` / `#f0b07a` | `#ffa860` |
| Dusk 16:20 | `#2a3152` / `#d9776a` | `#ff7a4a`, fading |

Weather presets scale these: fog and overcast desaturate and lift the horizon
into the fog colour, storm darkens and greens it, clear days push saturation.
Values live in `art/looks/*.tres` and can be tuned in the Inspector.

## Geometry budgets
| Asset class | Triangles |
|---|---|
| Small prop | 300–1,500 |
| Interactable hero prop | up to 3,000 |
| Landmark (lighthouse, cottage) | 8k–20k |
| Spruce | 600–900 |
| Grass card cluster | 8–24 |
| Terrain render mesh | ~130k (collision stays on the coarse grid) |

## Pipeline
- `tools/build_assets.sh` runs the asset factory: paint textures, import, then
  build materials, models, scenes and look resources. Output is committed under
  `assets/`, `scenes/` and `art/looks/` like any authored asset.
  - `tools/texture_kit.gd`: tileable painted textures + normal maps.
  - `tools/factory_materials.gd`: the material library (`assets/materials/`).
  - `tools/mesh_kit.gd`: bevelled boxes, lathes, tubes, extrusions, chiselled
    rocks, merged per material with LODs.
  - `tools/prop_assets.gd`: hero props (every interactable) and furniture.
  - `tools/island_assets.gd`, `tools/vegetation_assets.gd`,
    `tools/interior_assets.gd`: the scenes the game loads.
- **Hybrid drop-in:** put `assets/models/<name>.glb` next to a generated
  `<name>.res` and `PropLoader` uses the hand-made model at load time.
- **Look tuning without code:** `art/looks/atmosphere.tres` (time-of-day keys,
  sun path, colour grade) and `art/looks/weather_*.tres` (per-weather looks).
  The factory only writes these if they are missing, so Inspector edits survive.
- Shaders: `art/painterly.gdshader` (all props), `art/terrain.gdshader`,
  `world/ocean.gdshader`, `art/foliage.gdshader`, `art/sky.gdshader`,
  `art/beam.gdshader`, `art/window_view.gdshader`, `ui/post.gdshader`.

## Lighting
- Outdoors: one key light (sun by day, moon by night) with soft 4-split
  shadows; sky-driven ambient and reflections; exponential + height fog with
  aerial perspective; volumetric fog for shafts and the beam; glow; grade.
- Interiors: shadowed lamp/stove lights, window spill lights and window views
  that follow the outside sky. Bounce light comes from SDFGI + SSIL on High.
  (The plan named LightmapGI; Godot can only bake it from the editor, and
  real-time GI also handles the lamp being lit or dark, so it was not used.)

## Quality presets (`Settings.quality`, `--quality=low|medium|high`)
| | High (PC) | Medium | Low (Steam Deck / older GPUs) |
|---|---|---|---|
| GI | SDFGI + SSIL | none | none |
| SSAO, volumetric fog, DOF | on | on | off |
| Shadow distance | 220 m, PCSS | 160 m | 110 m |
| AA | MSAA 4x | MSAA 2x | FXAA |
| Render scale | 1.0 | 1.0 | 0.77 (FSR) |
| Sea mesh | 240 x 240 | 240 x 240 | 140 x 140 |
| Rain particles | 2800 | 2800 | 1200 |

`tests/perf.gd` reports triangles / draw calls / objects per vantage for a preset.

## Presentation
- **Type:** Cormorant Garamond (titles, cards, prologue) and Work Sans (UI),
  both SIL OFL 1.1, bundled with their licences in `assets/fonts/`.
  `ui/ui_theme.gd` applies them game-wide.
- **Title screen** (`ui/title_screen.gd`): a live view of Gannet Rock at dusk,
  lamp lit, from a slowly drifting camera. New watch / Continue / Settings / Quit.
- **Prologue** (`story/prologue.gd`, `ui/prologue_player.gd`): typed fragments
  of Arthur's year with choices (backstory flags + starting trust), intercut
  with the Coast Guard tender crossing in dawn fog. First-draft text; rewrite
  in M6. Hold Esc / B to skip.
- A faint vignette + film grain (`ui/post.gdshader`) sits under the HUD.

## Verification
- `godot --headless -s tests/run_tests.gd` (gameplay, unchanged by the art pass).
- `tools/shots.sh <dir>` renders every vantage (title, prologue, interiors,
  each weather, dawn to night). `LAVAPIPE=1` renders on a CPU-only machine.
- `godot --headless --export-pack "Linux / Steam Deck" build/LowTide.pck` then
  `godot --main-pack build/LowTide.pck` checks the exported data boots.
