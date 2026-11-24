# Low Tide: Brand Guide

Full visual version: `marketing/steam/index.html` (Brand guide tab). Assets: `marketing/steam/`.

## Idea
**One light on a dark sea.** Low Tide is a quiet, cold mystery about a lonely place and something left there. The identity is stern letters, a lot of dark, and one warm point of light that someone keeps lit.

## Logo
`LOW TIDE` in Marcellus capitals, set wide like text cut into stone. **The I in TIDE is the lighthouse**: its stem is the tower and the lamp burns above it. The lamp lays a thin beam across the title and a broken streak of light into the water, and the letters reflect faintly beneath a hairline waterline. The standalone mark is a drawn tower, its lamp and its reflection.

- Files: `marketing/steam/logo/*.svg` (wordmark, flat, ink for light paper, mark, icon). Text is outlined.
- Clear space: the height of the L on every side.
- Below 220 px wide use the flat version (no reflection or beam).
- The lamp is always amber (Ember on light paper) and never leaves the I.
- Over key art, set the logo on dark water and omit the beam where it would run parallel to the painted one.
- Regenerate: `cd marketing/steam && python3 tools/build_wordmark.py && node export.mjs`.

References (what we took): Dark Souls (one warm accent against cold type), Return of the Obra Dinn (inscriptional lettering), Firewatch (a mark that works alone), Edith Finch / Ethan Carter / Dear Esther (restraint, wide serif capitals, empty dark).
Dropped: stencil (reads as a war game), cutting letters at the waterline (the L became an I), the earlier half-sun mark (too gentle).

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
Marcellus (display, and the title), IBM Plex Sans (text), IBM Plex Mono (anything the island measures), Reenie Beanie (Arthur's logbook only). All SIL OFL, from Google Fonts.

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
Developer and publisher names, release date and price are placeholders on the store page.
