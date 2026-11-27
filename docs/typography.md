# Typography

**Status:** decided and applied (M7c). Set B, chosen by the project owner from three specimens.

## Fonts
All three families are SIL Open Font License 1.1, bundled in `ui/fonts/` (WOFF, imported by Godot). The full licence text and each font's own copyright line are in `docs/licences.md`.

| Role (`UiFonts`) | Family and file | Used for |
|---|---|---|
| `display` | Cormorant Garamond, weight 600 (`assets/fonts/CormorantGaramond.ttf`) | Game title, day cards, ending names, menu and journal headings, prologue |
| `ui` | Work Sans, weight 420 (`assets/fonts/WorkSans.ttf`) | HUD, radio panel, prompts, menus, settings, tutorial. Also `ThemeDB.fallback_font`, so any unstyled control picks it up |
| `paper` | Caveat Medium (`Caveat-Medium.woff`) | Journal entries and the tide table, i.e. text written on paper in the fiction |
| `tape` | Cormorant Garamond 500, obliqued (`assets/fonts/CormorantGaramond.ttf`) | Subtitles for Walt's, June's, Tom's and Clara's tapes, so recordings read as a different voice from the live radio |

`UiFonts.get_font(role)` returns null if a file is missing or not yet imported, which falls back to the engine font. Nothing breaks without the files.

## Capitalisation rule
Use standard writing conventions. **No all-caps UI text.** The first version had forced capitals everywhere (`LOW TIDE`, `NEW WATCH`, `CH-16 // CLARA`) and the project owner found it "very AI looking or synthetic".

- Titles, buttons, menu headings, labels: sentence case, or normal title case for proper names (Low Tide, New watch, Keeper's journal, The Right Address).
- Separators are punctuation, not slashes or dashes with spaces: `Tape 1: Walt, January 1976`, `Relief boat, first light`.
- Keep key names and genuine acronyms as written: E, Q, LB, LT, L3, F1, W A S D, MSAA, FXAA.
- Text that is painted or stamped inside the fiction (for example the stamped canister) may stay in capitals. Mark those with a comment.
- A test (`tests/run_tests.gd`, section "typography") walks the HUD and menu control trees plus ending names, tape titles, speaker labels, tutorial pages and tide labels, and fails on any string that reads as shouting. If a new screen needs a legitimate all-caps word, adjust `_shouty()` rather than switching the test off.

## Layout notes
IBM Plex Mono is wide, so text wraps earlier than the old default font. Panels were widened (radio 780, tutorial 860x460, journal modal 780x440, settings 940x580) and long text wraps rather than clips. A test checks that the radio panel stays inside 1280x720 with the longest line at subtitle sizes 1.0, 1.5 and 1.8.

## Not verified here
I can check fit, wrapping and capitalisation in screenshots. Whether the typography *feels* right in the game is the owner's call. The user can swap any role by changing `UiFonts.ROLE_FILES`.

## M6.5 change
The art pass unified the type on the M6.5 set: Cormorant Garamond (display, tape) and Work Sans (ui), both variable
fonts used through `UiFonts.weighted(role, weight)`, with Caveat kept for text written on paper. Work Sans is
narrower than IBM Plex Mono, so the widened panels above still fit with room to spare.

## UI overhaul: one design system
`ui/ui_theme.gd` is the single source for UI styling (brief: `docs/ui_overhaul_brief.md`).
- **One colour family:** `ACCENT` (amber), `CREAM`, `MUTED`. `AMBER` and `TEXT` remain as aliases. The teal and brass of the day card and radio banner are `POSTER_TEAL` and `POSTER_BRASS`.
- **Type floor:** `UiTheme.label()` and `UiTheme.text_size()` clamp to `MIN_TEXT` (14 px), including when the subtitle scale is at 0.8. A test scans the HUD, prologue, title, pause and settings.
- **Menu items:** `UiTheme.style_menu_item()` is shared by the title and pause menus: no box, and a thin amber left rule on the focused or hovered entry. Amber is spent on focus.
- **Components:** `label`, `keycap`, `rule`, `style_button`, `glass_panel`, `paper`, `pill`.
- **Motion:** `UiTheme.fade_to()` and `UiTheme.appear()` jump straight to the end state under Reduce motion. The setting now covers fades and slides as well as head-bob.
