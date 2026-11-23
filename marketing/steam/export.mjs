// Renders every Steam asset to marketing/steam/assets and the vector logos to marketing/steam/logo.
// Usage: node export.mjs [kind ...]      (no args = everything)
// Needs: playwright (chromium) and network access to fonts.googleapis.com for the capsule type.
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const outAssets = path.join(here, 'assets');
const outLogo = path.join(here, 'logo');
mkdirSync(outAssets, { recursive: true });
mkdirSync(outLogo, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage();
page.on('pageerror', (e) => console.error('page error:', e.message));
await page.goto(pathToFileURL(path.join(here, 'export.html')).href, { waitUntil: 'networkidle' });
await page.evaluate(async () => {
  await Promise.all([document.fonts.load('400 40px Gloock'), document.fonts.load('500 20px "IBM Plex Mono"')]);
});

const kinds = process.argv.slice(2).length ? process.argv.slice(2) : await page.evaluate(() => Object.keys(LT.ASSETS));
for (const kind of kinds) {
  const dataUrl = await page.evaluate(async (k) => {
    const c = document.getElementById('c');
    await LT.renderAsset(c, k);
    return c.toDataURL('image/png');
  }, kind);
  const file = path.join(outAssets, `${kind}.png`);
  writeFileSync(file, Buffer.from(dataUrl.split(',')[1], 'base64'));
  console.log('wrote', path.relative(here, file));
}

if (!process.argv.slice(2).length) {
  const logos = await page.evaluate(() => ({
    'low-tide_wordmark.svg': LT.logoSVG({ id: 'w' }),
    'low-tide_wordmark_flat.svg': LT.logoSVG({ id: 'f', reflect: false }),
    'low-tide_wordmark_ink.svg': LT.logoSVG({ id: 'i', fill: '#162029', sun1: '#d9822b', sun2: '#d9822b' }),
    'low-tide_mark.svg': LT.logoSVG({ id: 'm', layout: 'mark' }),
    'low-tide_icon.svg': LT.logoSVG({ id: 'k', layout: 'mark', bg: '#162029' }),
  }));
  for (const [name, svg] of Object.entries(logos)) {
    writeFileSync(path.join(outLogo, name), svg);
    console.log('wrote logo/' + name);
  }
}
await browser.close();
