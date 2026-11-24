# Low Tide: Steam branding kit

Everything for the store page, generated from code so it stays in step with the game's palette.

| Path | What it is |
|---|---|
| `index.html` | Store page draft, brand guide and asset kit (three tabs). Open it in a browser, or serve this folder. |
| `scene.js` | The key-art painter, logo builder and Steam asset specs (`LT.ASSETS`). |
| `wordmark.js` | Kerned, outlined wordmarks for directions b, c and h (generated). |
| `assets/*.png` | Art with no logo: library hero, page background, key art. |
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
- Real screenshots (1920 x 1080, at least five) and the trailer still need capturing from the build.
