# Low Tide: Steam branding kit

Everything for the store page, generated from code so it stays in step with the game's palette.

| Path | What it is |
|---|---|
| `index.html` | Store page draft, brand guide and asset kit (three tabs). Open it in a browser, or serve this folder. |
| `scene.js` | The key-art painter, logo builder and Steam asset specs (`LT.ASSETS`). |
| `wordmark.js` | Kerned, outlined wordmarks for directions b, c and h (generated). |
| `assets/*.png` | Art with no logo: library hero, page background, key art. |
| `assets/game/*.jpg` | Nine real 1920 x 1080 captures from the Godot build (see below). |
| `assets/b`, `c`, `h` | Steam-sized PNGs per logo direction: header, small, main, vertical and library capsules, library logo, icon. |
| `logo/b`, `c`, `h` | Vector wordmark, ink wordmark (for light paper), mark and icon per direction. Text is outlined. |
| `export.mjs` | Renders `assets/` and `logo/`. |
| `tools/build_wordmark.py` | Rebuilds `wordmark.js` from Cormorant Garamond, Big Shoulders Stencil Display and IBM Plex Mono (SIL OFL). Needs `fonttools` and `uharfbuzz`. |
| `explore/` | Logo exploration: the typeface audition and the concept comps. Not used by the build. |

## Regenerate

```bash
cd marketing/steam
node export.mjs                    # everything
node export.mjs c main_capsule     # one direction, one asset
python3 tools/build_wordmark.py    # only if the wordmark spacing changes (pip install fonttools uharfbuzz)
```

`export.mjs` needs Playwright with Chromium, and network access to Google Fonts for the capsule type (Cormorant Garamond, IBM Plex Mono).

## Steam rules these follow

- Pick one direction (b, c or h) and upload its folder. Capsules carry the logo and are readable at their smallest displayed size.
- `library_hero.png`, `page_background.png` (fades into the store page blue `#1b2838`) and `key_art.png` contain no text. Steam draws the logo over the library hero.
- `assets/game` holds nine real captures: the night beam, golden hour at the Day 5 spring low, the cottage, the desk, the lantern room, a foggy dawn pier, the Day 4 storm, the watch room and the keeper's journal.
- A trailer is still to do.

## Retaking the screenshots
The captures come from `tests/screenshot.gd` (see `tools/shots.sh`). Store shots need 1920 x 1080, but the script renders 1280 x 720 (`root.size`), so use a copy with the size changed. On a machine with no GPU the software Vulkan driver works but is slow, about two minutes per frame at 720p, so render only the shots you need. The script takes a name filter, or a comma-separated list if you patch the filter check.

```bash
# After godot --headless --import
VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 1920x1080x24" \
  godot --path . --rendering-driver vulkan -s tests/screenshot.gd -- /some/output/dir 31_d5_golden
```

Note about `tests/screenshot.gd`: it keeps the HUD hidden for the whole run, so UI frames need `main.hud.visible = true` (or use `tests/ui_shots.gd`). The tutorial call that used to leave the game on the title screen is fixed (`_tut_go(4)` starts the game).

The captures here were taken from `main` after the art pass (PR #4), the UI box overhaul (#10) and the audio work. The adaptive score (#7) does not change how the game looks. Retake them if the look changes again.
