# Low Tide: Steam branding kit

Everything for the store page, generated from code so it stays in step with the game's palette.

| Path | What it is |
|---|---|
| `index.html` | Store page draft, brand guide and asset kit (three tabs). Open it in a browser, or serve this folder. |
| `scene.js` | The key-art painter, logo builder and Steam asset specs (`LT.ASSETS`). |
| `wordmark.js` | Kerned, outlined wordmarks for directions b, c and h (generated). |
| `assets/*.png` | Art with no logo: library hero, page background, key art. |
| `assets/game/*.jpg` | Eight real 1920 x 1080 captures from the Godot build (see below). |
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
- `assets/game` holds eight real captures: the night beam, the storm on Day 4, the south reef and the causeway at the Day 5 spring low, the causeway sign, the north cove, the journal and the tide table.
- A trailer is still to do.

## Retaking the screenshots
The captures come from `tests/screenshot.gd` at 1920 x 1080 (the script itself renders 1280 x 720; change `root.size`). That script leaves the tape-player bar on screen in its later frames, so for store shots hide it after the `15_tape_playing` frame (`main.hud._tape_panel.visible = false`). Needs Godot 4.4 and xvfb:

```bash
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-method gl_compatibility -s tests/screenshot.gd -- /some/output/dir
```

These were taken from `main` after the Charm pass (PR #2). The art overhaul in PR #4 will change how the game looks, so retake them once it lands.
