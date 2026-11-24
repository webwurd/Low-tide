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
- `tools/build_assets.sh` runs the asset factory headlessly: textures →
  import → materials, meshes and scenes. Output is committed under `assets/` and
  `scenes/`, like any authored asset.
- Hybrid drop-in: put `assets/models/<name>.glb` next to a generated
  `<name>.res` and `PropLoader` prefers the hand-made model.
- Materials use `art/painterly.gdshader` (soft wrap light, tinted shadows, sun rim,
  triplanar painted detail, wetness).
