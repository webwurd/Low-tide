# Typography

**Decided (UI pass):** three-face system, roles in `ui/ui_fonts.gd`, licences in `docs/licences.md`. Display = Oswald (poster voice: day cards, banners, title). UI = Inter (radio, prompts, menus). Paper = Caveat (journal, Arthur's inner voice). The text below is the original brief.

## Original brief (deferred to M7)

**Status:** every piece of UI text currently uses Godot's built-in default font. It is a placeholder.
**Direction from the project owner:** use something *different and fresh*, not the stock default and not a generic "retro typewriter" look.

## Where text appears today (all in `ui/hud.gd` unless noted)
| Surface | Notes |
|---|---|
| Title + setup tutorial (controls table, "a day on Gannet Rock") | Large display title, then a 3-column key table: needs clear, legible body text |
| Radio panel (Clara) + reply options | Short spoken lines; most-read text in the game |
| Interact prompt, Arthur's inner-voice toasts, hold bar | Small, over busy 3D scenes: needs strong legibility |
| Day cards ("DAY 2", title, weather) | Display use |
| Journal modal: log, satchel, tapes | Paper-coloured page; long-form reading; good candidate for a handwritten/hand-set face |
| Tide table (paper modal) | Tabular numerals matter |
| Tape panel (Walt's subtitles) | Could differ from Clara's radio text to signal a different voice/medium |
| Binocular overlay readout, Assist HUD, pocket watch | Instrument-style numerals and caps |
| `Label3D` numerals on pier pilings (`world/island.gd`) | Painted marks: large, simple digits |

## Requirements for the chosen font(s)
- Licence allows bundling and redistribution in a commercial game (SIL OFL or equivalent). Record the licence in `docs/licences.md`.
- Covers Latin + punctuation used in the script (curly quotes, em dash, ellipsis) and **tabular figures** for the tide table and clock.
- Reads clearly at 12-18 px over fog and dark interiors, at Steam Deck resolution (1280x800).
- Works with Godot's `FontFile`/`FontVariation` (TTF/OTF; variable fonts are fine).

## Plan for M7
1. Shortlist 3-4 candidate families and test them in-engine on the real screens listed above (screenshots via `tests/screenshot.gd`).
2. Probably a **small system of 2-3 faces**, not one: e.g. a distinctive display face (title, day cards), a highly legible UI/body face (radio, prompts, tutorial), and an optional hand-set or handwritten face for diegetic paper (journal, tide table, tape labels). One of each, to keep it cohesive.
3. Centralise: create a single `Theme` resource (`ui/theme.tres`) assigned at the HUD root, so fonts and sizes live in one place instead of per-label overrides (today `_label()` in `hud.gd` sets size/colour per call).
4. Add a font-scale / "larger text" accessibility option alongside the M7 Settings menu.
5. Update the tutorial screen, Label3D tide marks and binocular overlay to use the new faces.
