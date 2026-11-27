# UI overhaul brief

**Status:** research input for the UI overhaul. Read with `design_bible.md`, `brand_guide.md` and `typography.md`, which still rule.

## Sourcing caveat
Reference research was done by four search agents. They could not view images, and mobygames, rpgfan, gamepressure and the Outer Wilds wiki did not resolve from the build container. Everything below comes from reviews, guides and wiki text, not from looking at screenshots. Treat each observation as a lead and check it against a real screenshot before copying a detail. No image URLs were verified.

## Games studied and what we take
| Game | Take | Leave |
|---|---|---|
| Firewatch | Radio as the only voice; near-empty HUD with a single dot reticle; orange as the one accent; notes you carry | Slanted selection shapes (too graphic for our serif voice) |
| Return of the Obra Dinn | The book is the interface; printed headings, hand marks | One-bit look |
| Outer Wilds | Log as location list plus detail | Card web |
| What Remains of Edith Finch | Story text lives in the world, system text stays on screen | Per-story fonts |
| Disco Elysium | Result banner sits inside the panel where the choice was made; small secondary text must still be readable | Skill-check vocabulary |
| Death Stranding | Prompt is one glyph plus one verb; hold actions show progress only while held | Strand motif |
| Dead Space | Status lives on the object (watch, gauge), not a bar | Sci-fi chrome |
| Oxenfree / Life is Strange | Conversation never pauses; choices can lapse into silence | Speech bubbles |
| Pentiment | Dialogue speed, high contrast, instant text options | Period ornament |
| Prey | Q/E style tab switching; keep a visible Back (its absence is the warning) | |
| Journey | Charge shown as light on the object itself | |

## Principles for Low Tide
1. **Near-empty by default.** Reticle, one prompt, nothing else. Status is on the watch and the tide table. Add a Minimum HUD option that hides the reticle and prompts.
2. **Amber is for people and for focus.** Spend it on the focused control, the live radio, the lamp. Never on decoration. About 5% of the frame.
3. **One glyph, one verb.** Prompts read `E  Wind` with a hold ring only while held. Key-caps switch between keyboard and pad glyphs with the last input device.
4. **The radio never stops the game.** Narrow bottom-centre band, speaker identified with the on-air light, replies carry their `1` / `2` or D-pad glyph, glass tint strong enough over snow and bright sky, no dimming of the world.
5. **Paper is the object.** Journal and tide table are printed grids and headings in Cormorant Garamond; Caveat only for Arthur's own hand (log entries, annotations). Pages separated by a quiet tab or ruled edge, never by colour alone. Each empty page gets one in-voice line. Page change is a short low-contrast fade or slide, no bounce.
6. **One frame for title, pause and settings.** Same position, same type, same focus treatment, so nothing jumps. Pause dims with the frosted backdrop rather than a flat black.
7. **Keyboard and pad first.** Everything focusable, a visible and clickable Back everywhere, tabs on Q/E and bumpers.
8. **Motion is quiet and optional.** 120 to 400 ms ease-out fades and small slides, one shared helper, a hard no-op under Reduce motion.
9. **Readable at the floor.** Nothing under 14 px. Secondary text keeps contrast of at least 4.5:1 on the glass.
10. **Cards are one line and a whisper.** Day card is a single display line plus a short sub line, a short hold, a fade. No all-caps.

## Per-surface direction
- **Title / pause / settings:** left-aligned column in display serif, amber only on the focused item (thin left rule plus brighter text, no filled box). Endings-found and hints at 14 px or more. Settings gets section headings, one-line descriptions, real labels on toggles, and a layout that scales with the window.
- **Radio and tape subtitles:** shared component for HUD and prologue (the prologue currently duplicates it). Optional thin draining bar for timed priority calls, lapse to silence.
- **Prompt, toasts, banner, stamina, assist:** one compact vocabulary of glass pill, key-cap, hairline rule. Toasts in one place, fade quickly. Assist readout gets row hierarchy (time large, tide medium, log small).
- **Journal / tide table:** structured rows instead of one joined label, focusable tabs, styled scrollbar on paper, ui-scale aware size.
- **Day, ending and swept cards:** share one card component and palette; retire the separate teal and brass palette in favour of the main tokens unless it earns its place.
- **Watch and binoculars:** polish only; scale with UI scale; amber for winding state and range readout, styled readout labels.

## Not decided here
Whether the feel is right. Check in the game and in the before/after screenshots from `tests/ui_shots.gd`.
