# Low Tide: Steam branding kit

Everything for the store page, generated from code so it stays in step with the game's palette.

| Path | What it is |
|---|---|
| `index.html` | Store page draft, brand guide and asset kit (three tabs). Open it in a browser, or serve this folder. |
| `scene.js` | The key-art painter, logo builder and Steam asset specs (`LT.ASSETS`). |
| `wordmark.js` | Kerned, outlined wordmark and tower glyph paths (generated from Marcellus). |
| `assets/*.png` | Steam-sized PNGs: header, small, main, vertical and library capsules, library hero, page background, logo, icon, key art. |
| `logo/*.svg` | Vector wordmark (with reflection, flat, ink) and the mark/icon. Text is outlined. |
| `export.mjs` | Renders `assets/` and `logo/`. |
| `tools/build_wordmark.py` | Rebuilds `wordmark.js` from Marcellus (SIL OFL). Needs `fonttools` and `uharfbuzz`. |
| `explore/` | Logo exploration: the typeface audition and the concept comps. Not used by the build. |

## Regenerate

```bash
cd marketing/steam
node export.mjs                    # everything
node export.mjs main_capsule       # one asset
python3 tools/build_wordmark.py    # only if the wordmark spacing changes (pip install fonttools uharfbuzz)
```

`export.mjs` needs Playwright with Chromium, and network access to Google Fonts for the capsule type (Marcellus, IBM Plex Mono).

## Steam rules these follow

- Capsules carry the logo and are readable at their smallest displayed size.
- `library_hero.png`, `page_background.png` (fades into the store page blue `#1b2838`) and `key_art.png` contain no text. Steam draws the logo over the library hero.
- Real screenshots (1920 x 1080, at least five) and the trailer still need capturing from the build.
