# Low Tide: Brand Guide

Full visual version: `marketing/steam/index.html` (Brand guide tab, with a live switch between logo directions). Assets: `marketing/steam/`.

## Idea
**One light on a dark sea.** Low Tide is a quiet, cold mystery about a lonely place and something left there. The identity is stern letters, a lot of dark, and one warm point of light that someone keeps lit. No fun, no cute: no reflections, no sun.

## Logo: two directions and a fallback
All three share one idea: a single amber light in a cold field.

| | Direction | What it is |
|---|---|---|
| **B** | Lowercase | `low tide` in Cormorant Garamond semibold. The dot of the i is the lamp, sized and placed from the font's own dot, over a hairline. Quiet, literary. Mark: the lowercase i and its lamp. |
| **C** | Stencil | `LOW TIDE` in Big Shoulders Stencil Display, one amber rule, and a classification line `GANNET ROCK . 1998` in IBM Plex Mono. Stamped like the PROJECT PELAGIC canister. Mark: an LT monogram over the rule. |
| **H** | Capitals (fallback) | `LOW TIDE` in Cormorant capitals. The I is the lighthouse; the lamp burns above it and lays a thin beam across the title. Mark: a drawn tower. |

Pick one for release. B is the default in the preview.

- Files: `marketing/steam/logo/<direction>/*.svg` (wordmark, ink for light paper, mark, icon). Text is kerned and outlined.
- Capsules, hero and icon PNGs per direction: `marketing/steam/assets/<direction>/`. Art with no logo: `marketing/steam/assets/`.
- Clear space: the height of the tallest letter on every side.
- The lamp, or C's amber rule, is the only warm element. Amber (Ember on light paper). No glow beyond the lamp's own, no bevels, no reflections.
- Over key art, set the logo on dark water. Only H carries a beam, and it is left off over key art where it would run parallel to the painted one.
- Regenerate: `cd marketing/steam && python3 tools/build_wordmark.py && node export.mjs`.

References (what we took): Dark Souls (one warm accent against cold type), Return of the Obra Dinn (inscriptional lettering), Firewatch (a mark that works alone), Edith Finch / Ethan Carter / Dear Esther (restraint, wide serif capitals, empty dark).
Dropped: the half-sun mark (too gentle); cutting letters at the waterline in the logo (the L became an I); a rippled reflection under the logo (fussy).

## Outro / swept card (idea, not part of the logo)
The submerged title (letters cut by a rising waterline, rippled reflection beneath, lamp still lit above the water) is kept for the game, not the logo. `LT.drownedSVG()` in `marketing/steam/scene.js` draws it, and the Brand guide tab has a live demo.
- **Swept card:** when Arthur is swept to the South Landing Dock (bible: no game over), hold black for a second, bring the title up with the waterline already high, and let it fall as the dock fades in.
- **Ending card:** over the final shot of a quiet ending, let the tide rise through the title and hold.
- **Godot:** render the title to a texture; draw it in a ColorRect with a shader that discards pixels below a `waterline` uniform; draw the same texture flipped under the line in slices with a sine UV offset; tween the uniform up while the surf bed swells.

## Tagline
- **What the tide leaves.** (primary)
- One keeper. One radio. Seven tides.
- Mind the tide. (Clara's line, in the game rather than on the box)

## Colour (extends the Design Bible palette)
| Name | Hex | Role |
|---|---|---|
| Night Water | `#162029` | Ground, UI panels (matches the Godot clear colour) |
| Slate | `#526373` | Sky, distance |
| Wet Granite | `#3a434a` | Rock, shadows with body |
| Seafoam | `#7ea99b` | Small accents, the wet edge |
| Fog | `#dde5e4` | Type, the tower, the logo |
| Lantern | `#ffb84d` | The lamp, lit windows, the one button |
| Ember | `#d9822b` | Lantern in shadow, ink logo |

Amber is for people. About 5 percent of a frame, never above 10.

## Type
Cormorant Garamond (display, taglines, direction B and H), Big Shoulders Stencil Display (direction C title only), IBM Plex Sans (text), IBM Plex Mono (anything the island measures), Reenie Beanie (Arthur's logbook only). All SIL OFL, from Google Fonts.

## Voice
Plain, dry, exact. Write like a keeper's log: the number, the time, the thing seen. Never breathless, never jokey.
- Use: keeper, the glass, the bar, low water, tide table, logbook, the lamp, channel 16.
- Avoid: epic, immersive, haunting, unravel, journey, race against time, survive.

## Art direction
1. Every frame has a waterline.
2. Amber is for people.
3. The lighthouse is the tallest thing.
4. Fog hides, the lamp reveals. Flat-shaded facets and a little grain.
5. Small figure, large place. Arthur from behind; Clara never on screen.

## Open items
Choose B, C or H. Developer and publisher names, release date and price are placeholders on the store page.
