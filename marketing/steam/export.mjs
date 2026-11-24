// Renders Steam assets and vector logos.
//   assets/<kind>.png            art with no logo (library hero, page background, key art)
//   assets/<variant>/<kind>.png  everything that carries the logo, per direction (b, c, h)
//   logo/<variant>/*.svg         wordmark, ink wordmark, mark, icon (text is outlined)
// Usage: node export.mjs [b|c|h ...] [asset kind ...]     (no args = everything)
// Needs: playwright (chromium) and network access to fonts.googleapis.com for the capsule taglines.
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const VARIANTS = ['b', 'c', 'h'];
const args = process.argv.slice(2);

const browser = await chromium.launch();
const page = await browser.newPage();
page.on('pageerror', (e) => console.error('page error:', e.message));
await page.goto(pathToFileURL(path.join(here, 'export.html')).href, { waitUntil: 'networkidle' });
await page.evaluate(async () => {
  await Promise.all([document.fonts.load('600 40px "Cormorant Garamond"'), document.fonts.load('500 20px "IBM Plex Mono"')]);
});

const allKinds = await page.evaluate(() => Object.entries(LT.ASSETS).map(([k, a]) => [k, !!a.shared]));
const wantV = args.filter((a) => VARIANTS.includes(a)), wantK = args.filter((a) => !VARIANTS.includes(a));
const variants = wantV.length ? wantV : VARIANTS;
const kinds = allKinds.filter(([k]) => !wantK.length || wantK.includes(k));

async function render(kind, variant, file) {
  const dataUrl = await page.evaluate(async ([k, v]) => {
    const c = document.getElementById('c');
    await LT.renderAsset(c, k, 1, v);
    return c.toDataURL('image/png');
  }, [kind, variant]);
  mkdirSync(path.dirname(file), { recursive: true });
  writeFileSync(file, Buffer.from(dataUrl.split(',')[1], 'base64'));
  console.log('wrote', path.relative(here, file));
}

for (const [kind, shared] of kinds) {
  if (shared) { await render(kind, 'b', path.join(here, 'assets', `${kind}.png`)); continue; }
  for (const v of variants) await render(kind, v, path.join(here, 'assets', v, `${kind}.png`));
}

if (!wantK.length) {
  for (const v of variants) {
    const logos = await page.evaluate((v) => ({
      'low-tide_wordmark.svg': LT.logoSVG({ variant: v, id: 'w' }),
      'low-tide_wordmark_ink.svg': LT.logoSVG({ variant: v, id: 'i', fill: '#162029', onLight: true }),
      'low-tide_mark.svg': LT.logoSVG({ variant: v, layout: 'mark', id: 'm' }),
      'low-tide_icon.svg': LT.logoSVG({ variant: v, layout: 'mark', id: 'k', bg: '#162029', beam: false }),
    }), v);
    mkdirSync(path.join(here, 'logo', v), { recursive: true });
    for (const [name, svg] of Object.entries(logos)) {
      writeFileSync(path.join(here, 'logo', v, name), svg);
      console.log('wrote', `logo/${v}/${name}`);
    }
  }
}
await browser.close();
