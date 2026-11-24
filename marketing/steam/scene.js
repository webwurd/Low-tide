/* Low Tide — shared brand art.
 *   LT.PALETTE        brand colours
 *   LT.logoSVG(opts)  logo as an SVG string; variants b, c, h (needs wordmark.js)
 *   LT.drownedSVG()   the half-submerged title, for an outro card (not the logo)
 *   LT.drawScene()    the key-art painter (Canvas 2D, deterministic per seed)
 *   LT.ASSETS         Steam asset specs;  LT.renderAsset(canvas, kind)
 * Plain script (no modules) so index.html, export.html and Playwright can all load it.
 */
(function () {
  const LT = (window.LT = window.LT || {});

  const PAL = (LT.PALETTE = {
    deep: '#0d151d',     // Night Water, darkest
    night: '#162029',    // Night Water (Godot clear colour)
    granite: '#3a434a',  // Wet Granite
    slate: '#526373',    // Slate
    sea: '#7ea99b',      // Seafoam
    fog: '#dde5e4',      // Fog
    lantern: '#ffb84d',  // Lantern
    glow: '#ffd98a',     // Lantern, hot core
    ember: '#d9822b',    // Lantern, in shadow
  });

  /* ---------- helpers ---------- */
  function rng(seed) {
    let a = seed >>> 0;
    return function () {
      a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  const lerp = (a, b, t) => a + (b - a) * t;
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  function hex(c) {
    const n = parseInt(c.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function rgba(c, a) {
    const [r, g, b] = hex(c);
    return `rgba(${r},${g},${b},${a})`;
  }
  function mix(c1, c2, t) {
    const a = hex(c1), b = hex(c2);
    return `rgb(${Math.round(lerp(a[0], b[0], t))},${Math.round(lerp(a[1], b[1], t))},${Math.round(lerp(a[2], b[2], t))})`;
  }

  /* ---------- logo ---------- */
  // Three directions share one idea: a single amber light in a cold field.
  //  b  lowercase Cormorant; the dot of the i is the lamp.
  //  c  stencil capitals, one amber rule, a classification line (GANNET ROCK . 1998).
  //  h  Cormorant capitals; the I is the lighthouse, lamp above it, thin beam (fallback).
  LT.VARIANTS = {
    b: { key: 'b', label: 'B  Lowercase', short: 'Lowercase', tagFont: (px) => `600 ${px}px "Cormorant Garamond", serif`, tagCase: false, tagTrack: 0.4, eyebrow: true },
    c: { key: 'c', label: 'C  Stencil', short: 'Stencil', tagFont: (px) => `500 ${Math.round(px * 0.5)}px "IBM Plex Mono", monospace`, tagCase: true, tagTrack: 0.22, eyebrow: false },
    h: { key: 'h', label: 'H  Capitals', short: 'Capitals (fallback)', tagFont: (px) => `600 ${px}px "Cormorant Garamond", serif`, tagCase: false, tagTrack: 0.4, eyebrow: true },
  };
  LT.variant = 'b';

  function lampSVG(id, cx, cy, r, haloR, onLight) {
    const amber = onLight ? '#c46a14' : PAL.lantern, warm = onLight ? '#c46a14' : '#ffd98a', core = onLight ? '#e08a2a' : '#fff0c8';
    return {
      defs: `<radialGradient id="${id}-h"><stop offset="0" stop-color="${warm}" stop-opacity="${onLight ? 0 : 0.55}"/><stop offset=".3" stop-color="${amber}" stop-opacity="${onLight ? 0 : 0.2}"/><stop offset="1" stop-color="${amber}" stop-opacity="0"/></radialGradient>` +
            `<radialGradient id="${id}-c"><stop offset="0" stop-color="${core}"/><stop offset=".7" stop-color="${amber}"/><stop offset="1" stop-color="${amber}"/></radialGradient>`,
      body: `<circle cx="${cx}" cy="${cy}" r="${haloR}" fill="url(#${id}-h)"/><circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#${id}-c)"/>`,
    };
  }
  function beamSVG(id, cx, cy, x0, x1, onLight) {
    const amber = onLight ? '#c46a14' : PAL.lantern, warm = onLight ? '#c46a14' : '#ffd98a';
    return {
      defs: `<linearGradient id="${id}-bl" x1="1" x2="0"><stop offset="0" stop-color="${warm}" stop-opacity=".34"/><stop offset=".55" stop-color="${amber}" stop-opacity=".08"/><stop offset="1" stop-color="${amber}" stop-opacity="0"/></linearGradient>` +
            `<linearGradient id="${id}-br" x1="0" x2="1"><stop offset="0" stop-color="${warm}" stop-opacity=".34"/><stop offset=".55" stop-color="${amber}" stop-opacity=".08"/><stop offset="1" stop-color="${amber}" stop-opacity="0"/></linearGradient>`,
      body: `<path d="M${cx} ${cy} L${x0} ${cy - 68} L${x0} ${cy + 68}Z" fill="url(#${id}-bl)"/><path d="M${cx} ${cy} L${x1} ${cy - 68} L${x1} ${cy + 68}Z" fill="url(#${id}-br)"/>`,
    };
  }

  // opts: variant, layout 'line' | 'mark', fill, onLight, bg (square badge colour), line, beam, id
  LT.logoSVG = function (opts) {
    const o = Object.assign({ variant: LT.variant, layout: 'line', fill: PAL.fog, id: 'lt', bg: null, onLight: false, line: true }, opts);
    const v = o.variant, WM = LT.WORDMARKS[v], id = o.id, mark = o.layout === 'mark';
    const amber = o.onLight ? '#c46a14' : PAL.lantern, muted = o.onLight ? '#52606a' : '#9db0b3';
    let defs = '', body = '', bx0, bx1, by0, by1;
    const hair = (x0, x1, y) => (o.line ? `<path d="M${x0} ${y} H${x1}" stroke="${o.fill}" stroke-opacity="${o.onLight ? 0.5 : 0.32}" stroke-width="6" fill="none"/>` : '');

    if (v === 'b' && !mark) {
      const W = WM.w, L = WM.lamp, lamp = lampSVG(id, L.cx, L.cy, L.r * 1.05, L.r * 6.5, o.onLight);
      const beam = o.beam ? beamSVG(id, L.cx, L.cy, -0.04 * W, W * 1.05, o.onLight) : { defs: '', body: '' };
      defs = lamp.defs + beam.defs;
      body = beam.body + `<path d="${WM.d}" fill="${o.fill}"/>` + hair(-0.07 * W, W * 1.07, 120) + lamp.body;
      bx0 = -0.1 * W; bx1 = W * 1.1; by0 = L.cy - L.r * 6.5 - 10; by1 = 190;
    } else if (v === 'b' && mark) {
      const M = WM.mark, L = M.lamp, lamp = lampSVG(id, 0, L.cy, L.r * 1.05, L.r * 7, o.onLight);
      defs = lamp.defs;
      body = `<path d="${M.d}" transform="translate(${-M.cx} 0)" fill="${o.fill}"/>` + hair(-420, 420, 120) + lamp.body;
      bx0 = -430; bx1 = 430; by0 = L.cy - L.r * 7 - 10; by1 = 190;
    } else if (v === 'c' && !mark) {
      const W = WM.w, S = WM.sub, ruleY = 200, subY = ruleY + 12 + 130 + S.top;
      body = `<path d="${WM.d}" fill="${o.fill}"/><rect x="0" y="${ruleY}" width="${W}" height="12" fill="${amber}"/>` +
             `<path d="${S.d}" transform="translate(${(W - S.w) / 2} ${subY})" fill="${muted}"/>`;
      bx0 = -0.03 * W; bx1 = W * 1.03; by0 = -WM.top - 24; by1 = subY + 40;
    } else if (v === 'c' && mark) {
      const M = WM.mark;
      body = `<path d="${M.d}" transform="translate(${-M.w / 2} 0)" fill="${o.fill}"/><rect x="${-M.w / 2}" y="200" width="${M.w}" height="12" fill="${amber}"/>`;
      bx0 = -M.w / 2 - 120; bx1 = M.w / 2 + 120; by0 = -M.top - 100; by1 = 330;
    } else if (v === 'h' && !mark) {
      const W = WM.w, L = WM.lamp, lamp = lampSVG(id, L.cx, L.cy, L.r, 330, o.onLight);
      const beam = o.beam === false || o.onLight ? { defs: '', body: '' } : beamSVG(id, L.cx, L.cy, -0.05 * W, W * 1.06, o.onLight);
      defs = lamp.defs + beam.defs;
      body = beam.body + `<path d="${WM.d}" fill="${o.fill}"/>` + hair(-0.03 * W, W * 1.03, 0) + lamp.body;
      bx0 = -0.075 * W; bx1 = W * 1.075; by0 = L.cy - 340; by1 = 70;
    } else { // h mark: a drawn tower
      const cap = 654, W = 1500, cx = 750, cy = -(cap + 110), lamp = lampSVG(id, cx, cy, 38, 330, o.onLight);
      const beam = o.beam === false || o.onLight ? { defs: '', body: '' } : beamSVG(id, cx, cy, -60, W + 60, o.onLight);
      defs = lamp.defs + beam.defs;
      const tower = `M${cx - 74} 0 L${cx - 46} ${-cap} L${cx + 46} ${-cap} L${cx + 74} 0Z M${cx - 82} ${-cap - 4} H${cx + 82} V${-cap - 32} H${cx - 82}Z`;
      body = beam.body + `<path d="${tower}" fill="${o.fill}"/>` + hair(0, W, 0) + lamp.body;
      bx0 = 0; bx1 = W; by0 = cy - 340; by1 = 70;
    }

    let vb = [bx0, by0, bx1 - bx0, by1 - by0];
    let bg = '';
    if (o.bg) {
      const side = Math.max(vb[2], vb[3]) * (mark ? 1.18 : 1.1), mx = vb[0] + vb[2] / 2, my = vb[1] + vb[3] / 2;
      vb = [mx - side / 2, my - side / 2, side, side];
      bg = `<rect x="${vb[0]}" y="${vb[1]}" width="${side}" height="${side}" fill="${o.bg}"/>`;
    }
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb.map((n) => +n.toFixed(1)).join(' ')}" role="img" aria-label="Low Tide"><defs>${defs}</defs>${bg}${body}</svg>`;
  };

  // The half-drowned title: a waterline rising through the letters, with a rippled reflection below it.
  // Not part of the logo. Intended for an outro or a "swept" card. rise: 0 (standing) .. 1 (waterline at the cap line).
  LT.drownedSVG = function (opts) {
    const o = Object.assign({ variant: LT.variant, rise: 0.3, id: 'dr', fill: PAL.fog }, opts);
    const WM = LT.WORDMARKS[o.variant], top = WM.top, W = WM.w, id = o.id;
    const wl = -top * o.rise, depth = top * (0.95 - 0.25 * o.rise), n = 7;
    let clips = '', slices = '', y = wl + 5;
    for (let i = 0; i < n; i++) {
      const h = (depth / n) * (1.2 - 0.08 * i), op = 0.5 * Math.pow(1 - i / n, 1.4), dx = (i % 2 ? 1 : -1) * (10 + i * 8);
      clips += `<clipPath id="${id}-s${i}"><rect x="${-W}" y="${y.toFixed(1)}" width="${W * 3}" height="${h.toFixed(1)}"/></clipPath>`;
      slices += `<g clip-path="url(#${id}-s${i})"><g transform="translate(${dx} 0)" opacity="${op.toFixed(3)}"><g transform="translate(0 ${2 * wl}) scale(1 -1)"><use href="#${id}-art"/></g></g></g>`;
      y += h + 12 + i * 8;
    }
    const L = WM.lamp, lamp = L && L.cy + L.r * 2 < wl ? lampSVG(id, L.cx, L.cy, L.r * 1.05, L.r * 6, false) : { defs: '', body: '' };
    const vb = [-0.06 * W, -top - 420, W * 1.12, top * 2.3 + 420];
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb.map((n) => +n.toFixed(1)).join(' ')}" role="img" aria-label="Low Tide, half under water"><defs><clipPath id="${id}-a"><rect x="${-W}" y="${-top * 2}" width="${W * 3}" height="${top * 2 + wl}"/></clipPath><g id="${id}-art"><path d="${WM.d}" fill="${o.fill}"/></g>${clips}${lamp.defs}</defs>` +
      `<g clip-path="url(#${id}-a)"><use href="#${id}-art"/></g><path d="M${-0.04 * W} ${wl} H${W * 1.04}" stroke="${o.fill}" stroke-opacity=".5" stroke-width="6"/>${slices}${lamp.body}</svg>`;
  };

  /* ---------- scene ---------- */
  LT.drawScene = function (ctx, W, H, opts) {
    const o = Object.assign(
      {
        seed: 11, lx: 0.7, hz: 0.54, base: 0.72, lh: 0.5, barX: 0.38, pilX: 0.06, pilH: 0.55,
        fig: true, figT: 0.5, grain: 0.13, vig: 0.5, fogLow: 1, beams: true, dim: 0,
      },
      opts
    );
    const R = rng(o.seed);
    const u = H / 1000;
    const hz = o.hz * H, baseY = o.base * H, lx = o.lx * W, th = o.lh * H;
    const shelfH = 0.095 * H;
    const tb = baseY - shelfH * 0.92;                 // tower foot
    const lcx = lx, lcy = tb - th * 0.835;            // lantern centre

    function blur(px, fn) {
      ctx.save();
      ctx.filter = `blur(${(px * u).toFixed(1)}px)`;
      fn();
      ctx.restore();
    }
    function softEllipse(cx, cy, rx, ry, color) {
      ctx.save();
      ctx.translate(cx, cy);
      ctx.scale(rx, ry);
      const g = ctx.createRadialGradient(0, 0, 0, 0, 0, 1);
      g.addColorStop(0, color);
      g.addColorStop(1, color.replace(/[\d.]+\)$/, '0)'));
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(0, 0, 1, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
    }
    function fogBand(y, thick, a, color) {
      const g = ctx.createLinearGradient(0, y - thick, 0, y + thick);
      g.addColorStop(0, rgba(color, 0)); g.addColorStop(0.5, rgba(color, a)); g.addColorStop(1, rgba(color, 0));
      ctx.fillStyle = g; ctx.fillRect(0, y - thick, W, thick * 2);
      blur(18, () => {
        for (let i = 0; i < 9; i++) {
          softEllipse(R() * W, y + (R() - 0.5) * thick * 0.7, W * (0.12 + R() * 0.2), thick * (0.25 + R() * 0.35), rgba(color, a * (0.5 + R() * 0.7)));
        }
      });
    }
    function facets(poly, bb, n, amber) {
      ctx.save();
      ctx.beginPath(); poly.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.clip();
      for (let i = 0; i < n; i++) {
        const px = bb.x + R() * bb.w, py = bb.y + R() * bb.h, d = (0.04 + R() * 0.1) * bb.h;
        ctx.beginPath(); ctx.moveTo(px, py);
        ctx.lineTo(px + (R() - 0.3) * d * 2, py + (R() - 0.5) * d);
        ctx.lineTo(px + (R() - 0.5) * d, py + (R() - 0.1) * d * 1.6);
        ctx.closePath();
        const t = R();
        // light comes from the lantern side (amber) and the cold sky above (blue-white)
        const towardLamp = amber && Math.abs(px - lcx) < th * 0.9 && R() < 0.35;
        ctx.fillStyle = towardLamp ? rgba(PAL.lantern, 0.04 + R() * 0.1) : t < 0.5 ? `rgba(0,0,0,${0.08 + R() * 0.2})` : `rgba(150,180,198,${0.03 + R() * 0.09})`;
        ctx.fill();
      }
      ctx.restore();
    }
    function stack(x, w, h, tone, a) {
      const pts = [[x - w / 2, hz + 2 * u]];
      const n = 7, peak = 0.3 + R() * 0.4;
      for (let i = 1; i < n; i++) {
        const t = i / n;
        const prof = t < peak ? t / peak : (1 - t) / (1 - peak);
        pts.push([x - w / 2 + w * t, hz - h * Math.pow(prof, 0.75) * (0.82 + R() * 0.3)]);
      }
      pts.push([x + w / 2, hz + 2 * u]);
      ctx.fillStyle = rgba(tone, a);
      ctx.beginPath(); pts.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.fill();
    }

    /* sky */
    let g = ctx.createLinearGradient(0, 0, 0, hz);
    g.addColorStop(0, '#0a1219'); g.addColorStop(0.4, '#1b2b39'); g.addColorStop(0.78, '#3a4f60'); g.addColorStop(1, '#6e8087');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, hz + 2);
    // warm haze behind the light
    ctx.save(); ctx.translate(lcx, hz); ctx.scale(1.9, 0.62);
    g = ctx.createRadialGradient(0, 0, 0, 0, 0, H * 0.7);
    g.addColorStop(0, 'rgba(255,184,77,.34)'); g.addColorStop(0.4, 'rgba(230,160,100,.13)'); g.addColorStop(1, 'rgba(230,160,100,0)');
    ctx.fillStyle = g; ctx.fillRect(-W, -H, W * 2, H * 2); ctx.restore();
    // cloud streaks
    blur(22, () => {
      for (let i = 0; i < 16; i++) {
        const y = R() * hz * 0.92;
        softEllipse(R() * W, y, W * (0.14 + R() * 0.32), H * (0.012 + R() * 0.035), `rgba(176,196,208,${0.04 + R() * 0.07})`);
      }
    });

    /* far stacks and headlands */
    stack(o.lx > 0.5 ? W * 0.22 : W * 0.78, W * 0.16, H * 0.085, '#3d5160', 0.8);
    stack(o.lx > 0.5 ? W * 0.4 : W * 0.55, W * 0.045, H * 0.15, '#34495a', 0.9);   // East Stack
    stack(o.lx > 0.5 ? W * 0.47 : W * 0.4, W * 0.07, H * 0.07, '#3a4e5d', 0.85);
    stack(o.lx > 0.5 ? W * 0.9 : W * 0.1, W * 0.12, H * 0.06, '#405565', 0.8);
    fogBand(hz, 0.035 * H, 0.5, '#8aa0a8');

    /* water and flats */
    g = ctx.createLinearGradient(0, hz, 0, hz + 0.16 * H);
    g.addColorStop(0, '#506a76'); g.addColorStop(1, '#223742');
    ctx.fillStyle = g; ctx.fillRect(0, hz, W, 0.16 * H);
    g = ctx.createLinearGradient(0, hz + 0.1 * H, 0, H);
    g.addColorStop(0, '#223039'); g.addColorStop(0.5, '#162027'); g.addColorStop(1, '#0c1419');
    ctx.fillStyle = g; ctx.fillRect(0, hz + 0.1 * H, W, H);
    // sky mirrored in the wet sand
    g = ctx.createLinearGradient(0, hz + 0.1 * H, 0, H);
    g.addColorStop(0, 'rgba(150,175,185,.5)'); g.addColorStop(1, 'rgba(150,175,185,0)');
    ctx.fillStyle = g; ctx.fillRect(0, hz + 0.1 * H, W, H);
    // water lines on the far water
    for (let i = 0; i < 40; i++) {
      const y = hz + R() * 0.12 * H;
      ctx.fillStyle = `rgba(190,210,215,${0.04 + R() * 0.07})`;
      ctx.fillRect(R() * W, y, W * (0.02 + R() * 0.08), Math.max(1, 1.4 * u));
    }
    // lantern reflection column
    blur(2, () => {
      const y0 = baseY + 0.02 * H;
      for (let y = y0, k = 0; y < H; k++) {
        const t = (y - y0) / (H - y0);
        const w = lerp(0.012, 0.075, t) * H * (0.6 + R() * 0.8);
        ctx.fillStyle = rgba(PAL.lantern, 0.5 * (1 - t * 0.85));
        ctx.fillRect(lx - w / 2 + (R() - 0.5) * 0.006 * H, y, w, Math.max(1.2, lerp(2, 7, t) * u));
        y += lerp(5, 19, t) * u;
      }
    });
    // tide pools and rills
    for (let i = 0; i < 16; i++) {
      const t = Math.pow(R(), 0.8);
      const y = lerp(hz + 0.16 * H, H * 0.98, t);
      const x = R() * W;
      const rx = lerp(0.03, 0.17, t) * H * (0.6 + R()), ry = rx * 0.07;
      const near = Math.abs(x - lx) < 0.18 * W;
      ctx.fillStyle = near ? 'rgba(235,190,120,.22)' : 'rgba(150,175,185,.2)';
      ctx.beginPath(); ctx.ellipse(x, y, rx, ry, 0, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = 'rgba(0,0,0,.18)';
      ctx.beginPath(); ctx.ellipse(x, y + ry * 0.5, rx * 0.92, ry * 0.5, 0, 0, Math.PI * 2); ctx.fill();
    }

    /* the sandbar — a path of drier sand running to the rock */
    const bx0 = o.barX * W, bx1 = lx - th * 0.12;
    const yTop = baseY + 0.04 * H, yBot = H * 1.04;
    const barPt = (t) => {
      const e = 1 - t;
      const y = yTop + (yBot - yTop) * Math.pow(e, 1.7);
      const sway = Math.sin(t * 3.1 + 0.4) * 0.07 * W * (1 - t * 0.6);
      return [lerp(bx0, bx1, Math.pow(t, 1.15)) + sway * (1 - t), y, lerp(0.34, 0.035, Math.pow(t, 0.7)) * H];
    };
    const L = [], Rr = [];
    for (let i = 0; i <= 64; i++) {
      const [x, y, w] = barPt(i / 64);
      L.push([x - w, y]); Rr.push([x + w * (0.85 + 0.2 * Math.sin(i * 0.7)), y]);
    }
    const barPoly = L.concat(Rr.reverse());
    g = ctx.createLinearGradient(0, yTop, 0, H);
    g.addColorStop(0, '#8b9a9a'); g.addColorStop(0.5, '#55666a'); g.addColorStop(1, '#2f4046');
    ctx.fillStyle = g;
    ctx.beginPath(); barPoly.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.fill();
    // wet edge
    ctx.strokeStyle = 'rgba(205,228,222,.45)'; ctx.lineWidth = 2.4 * u;
    ctx.beginPath(); barPoly.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.stroke();
    // ripples
    ctx.save(); ctx.beginPath(); barPoly.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.clip();
    for (let i = 0; i < 260; i++) {
      const [x, y, w] = barPt(R());
      const tt = (y - yTop) / (yBot - yTop);
      ctx.strokeStyle = R() < 0.5 ? 'rgba(10,18,22,.14)' : 'rgba(210,225,225,.10)';
      ctx.lineWidth = lerp(1, 3.2, tt) * u;
      const len = w * (0.15 + R() * 0.5);
      const cx = x + (R() - 0.5) * w * 1.6;
      ctx.beginPath(); ctx.moveTo(cx - len / 2, y); ctx.quadraticCurveTo(cx, y - len * 0.07, cx + len / 2, y); ctx.stroke();
    }
    // amber on the sand nearest the light
    g = ctx.createRadialGradient(lx, yTop, 0, lx, yTop, 0.42 * H);
    g.addColorStop(0, 'rgba(255,184,77,.30)'); g.addColorStop(1, 'rgba(255,184,77,0)');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    ctx.restore();

    /* figure on the bar (Arthur, from behind, binoculars up) */
    if (o.fig) {
      const [fx, fy, fw] = barPt(o.figT);
      const fh = lerp(0.07, 0.25, 1 - o.figT) * H;
      const px = fx + fw * 0.05;
      ctx.save();
      // reflection
      ctx.save(); ctx.translate(px, fy); ctx.scale(1, -0.55); ctx.globalAlpha = 0.2; ctx.filter = `blur(${2 * u}px)`; person(ctx, fh, false); ctx.restore();
      ctx.translate(px, fy); person(ctx, fh, true);
      ctx.restore();
    }
    function person(c, h, rim) {
      c.save(); c.scale(h, h);
      c.fillStyle = '#070b0f';
      c.beginPath();                                                    // coat
      c.moveTo(-0.07, -0.76); c.lineTo(0.07, -0.76); c.lineTo(0.085, -0.33); c.lineTo(-0.085, -0.33); c.closePath(); c.fill();
      c.fillRect(-0.06, -0.34, 0.05, 0.34); c.fillRect(0.012, -0.34, 0.05, 0.34); // legs
      c.beginPath(); c.arc(0, -0.835, 0.052, 0, Math.PI * 2); c.fill();            // head
      c.beginPath(); c.arc(0, -0.855, 0.056, Math.PI, 0); c.fill();                 // cap
      c.lineWidth = 0.032; c.lineCap = 'round'; c.strokeStyle = '#070b0f';           // arms to the binoculars
      c.beginPath(); c.moveTo(-0.07, -0.73); c.lineTo(-0.075, -0.82); c.lineTo(-0.025, -0.845); c.stroke();
      c.beginPath(); c.moveTo(0.07, -0.73); c.lineTo(0.075, -0.82); c.lineTo(0.025, -0.845); c.stroke();
      c.fillRect(-0.06, -0.865, 0.12, 0.04);
      if (rim) {                                                                    // lantern rim light on the side facing it
        const s = lcx > 0 ? 1 : -1;
        c.strokeStyle = rgba(PAL.lantern, 0.55); c.lineWidth = 0.008;
        c.beginPath(); c.moveTo(s * 0.07, -0.76); c.lineTo(s * 0.085, -0.33); c.moveTo(s * 0.052, -0.84); c.lineTo(s * 0.058, -0.86); c.stroke();
      }
      c.restore();
    }

    /* rock shelf, tower, cottage */
    const rw = th * 0.82;
    const rockTop = tb + 0.012 * H, rockBot = baseY + 0.075 * H;
    const prof = (t) => Math.pow(clamp(1 - Math.pow(Math.abs(2 * t - 1), 1.7), 0, 1), 0.75);
    const rock = [];
    for (let i = 0; i <= 34; i++) {
      const t = i / 34;
      const jag = (R() - 0.5) * 0.018 * H * (prof(t) > 0.9 ? 0.4 : 1.6);
      rock.push([lx - rw + rw * 2 * t, rockBot - (rockBot - rockTop) * prof(t) + jag]);
    }
    for (let i = 14; i >= 0; i--) rock.push([lx - rw * 1.1 + rw * 2.2 * (i / 14), rockBot + 0.012 * H + (R() - 0.5) * 0.012 * H]);
    const rbb = { x: lx - rw, y: rockTop, w: rw * 2, h: rockBot - rockTop };
    g = ctx.createLinearGradient(0, rockTop, 0, rockBot);
    g.addColorStop(0, '#56636b'); g.addColorStop(0.45, '#35414a'); g.addColorStop(1, '#161f25');
    ctx.fillStyle = g; ctx.beginPath(); rock.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.fill();
    facets(rock, rbb, 160, true);
    // amber wash from the cottage windows and the lamp, wet-rock sheen at the foot
    g = ctx.createRadialGradient(lx, rockTop, 0, lx, rockTop, rw * 0.9);
    g.addColorStop(0, 'rgba(255,184,77,.16)'); g.addColorStop(1, 'rgba(255,184,77,0)');
    ctx.save(); ctx.beginPath(); rock.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.clip();
    ctx.fillStyle = g; ctx.fillRect(lx - rw * 1.2, rockTop, rw * 2.4, rockBot - rockTop);
    ctx.restore();

    // cottage (left of the tower, or right when the tower sits left of centre)
    if (o.cottage !== false) {
    const side = o.lx > 0.5 ? -1 : 1;
    const cw = th * 0.3, ch = th * 0.13, cx = lx + side * th * 0.34, cy = rockBot - (rockBot - rockTop) * prof(0.5 + (side * th * 0.34) / (2 * rw)) + 0.006 * H;
    ctx.fillStyle = '#26323a'; ctx.fillRect(cx - cw / 2, cy - ch, cw, ch);
    ctx.fillStyle = '#334049'; ctx.fillRect(cx - cw / 2, cy - ch, cw * 0.28, ch);
    ctx.fillStyle = '#12191f';                                                        // roof
    ctx.beginPath(); ctx.moveTo(cx - cw * 0.58, cy - ch); ctx.lineTo(cx, cy - ch - th * 0.075); ctx.lineTo(cx + cw * 0.58, cy - ch); ctx.closePath(); ctx.fill();
    ctx.fillRect(cx + cw * 0.18, cy - ch - th * 0.085, cw * 0.09, th * 0.07);       // chimney
    [-0.2, 0.22].forEach((fxk) => {
      const wx = cx + cw * fxk, wy = cy - ch * 0.72, ww = cw * 0.17, wh = ch * 0.42;
      softEllipse(wx, wy + wh / 2, ww * 2.6, wh * 2.4, 'rgba(255,184,77,.35)');
      ctx.fillStyle = PAL.lantern; ctx.fillRect(wx - ww / 2, wy, ww, wh);
      ctx.fillStyle = 'rgba(40,24,8,.55)'; ctx.fillRect(wx - 0.5 * u, wy, 1 * u, wh); ctx.fillRect(wx - ww / 2, wy + wh / 2, ww, 1 * u);
    });
    ctx.strokeStyle = 'rgba(190,205,210,.2)'; ctx.lineWidth = 5 * u; ctx.lineCap = 'round';  // smoke
    blur(3, () => {
      for (let k = 0; k < 2; k++) {
        ctx.beginPath();
        const sx = cx + cw * 0.225, sy = cy - ch - th * 0.09;
        ctx.moveTo(sx, sy);
        ctx.bezierCurveTo(sx + side * -10 * u, sy - 40 * u, sx + 22 * u * (k + 1), sy - 70 * u, sx + 8 * u, sy - (120 + k * 40) * u);
        ctx.stroke();
      }
    });
    }

    // tower
    const bw0 = th * 0.095, bw1 = th * 0.062, topBody = tb - th * 0.74;
    const tower = (yy) => lerp(bw0, bw1, (tb - yy) / (tb - topBody));
    g = ctx.createLinearGradient(lx - bw0, 0, lx + bw0, 0);
    g.addColorStop(0, '#d5dedc'); g.addColorStop(0.45, '#a3b3b6'); g.addColorStop(0.78, '#5b6b76'); g.addColorStop(1, '#2c3943');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.moveTo(lx - bw0, tb); ctx.lineTo(lx - bw1, topBody); ctx.lineTo(lx + bw1, topBody); ctx.lineTo(lx + bw0, tb); ctx.closePath(); ctx.fill();
    // slate band
    const b0 = tb - th * 0.36, b1 = tb - th * 0.5;
    g = ctx.createLinearGradient(lx - bw0, 0, lx + bw0, 0);
    g.addColorStop(0, '#46576a'); g.addColorStop(0.5, '#2e3d4d'); g.addColorStop(1, '#141c24');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.moveTo(lx - tower(b0), b0); ctx.lineTo(lx - tower(b1), b1); ctx.lineTo(lx + tower(b1), b1); ctx.lineTo(lx + tower(b0), b0); ctx.closePath(); ctx.fill();
    // amber spill on the lamp side of the tower, and a few lit slits
    g = ctx.createLinearGradient(0, topBody, 0, tb);
    g.addColorStop(0, 'rgba(255,184,77,.28)'); g.addColorStop(0.5, 'rgba(255,184,77,.06)'); g.addColorStop(1, 'rgba(255,184,77,0)');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.moveTo(lx - bw0, tb); ctx.lineTo(lx - bw1, topBody); ctx.lineTo(lx + bw1, topBody); ctx.lineTo(lx + bw0, tb); ctx.closePath(); ctx.fill();
    [0.12, 0.26, 0.62].forEach((f, i) => {
      const wy = tb - th * f;
      ctx.fillStyle = i === 1 ? PAL.lantern : '#1b232b';
      ctx.fillRect(lx - 0.006 * th, wy, 0.012 * th, 0.028 * th);
    });
    // gallery, lantern room, roof
    const gy = topBody, gw = bw1 * 1.55, gh = th * 0.026;
    ctx.fillStyle = '#18222a'; ctx.fillRect(lx - gw, gy - gh, gw * 2, gh);
    ctx.fillStyle = '#10181e'; ctx.fillRect(lx - bw1 * 1.15, gy, bw1 * 2.3, th * 0.012);
    ctx.fillStyle = 'rgba(16,24,30,.9)';
    for (let k = 0; k <= 12; k++) ctx.fillRect(lx - gw + (gw * 2 * k) / 12 - 0.5 * u, gy - gh - th * 0.028, 1.2 * u, th * 0.028);
    ctx.fillRect(lx - gw, gy - gh - th * 0.03, gw * 2, 1.3 * u);
    const lw = bw1 * 0.98, lt = gy - gh - th * 0.108;
    g = ctx.createLinearGradient(0, lt, 0, gy - gh);
    g.addColorStop(0, PAL.glow); g.addColorStop(1, PAL.lantern);
    ctx.fillStyle = g; ctx.fillRect(lx - lw, lt, lw * 2, th * 0.108);
    softEllipse(lcx, lcy, lw * 0.9, th * 0.06, 'rgba(255,248,225,.95)');
    ctx.fillStyle = '#1b252d';
    [-1, -0.34, 0.34, 1].forEach((k) => ctx.fillRect(lx + k * lw - 0.7 * u, lt, 1.4 * u, th * 0.108));
    ctx.beginPath(); ctx.moveTo(lx - lw * 1.2, lt); ctx.lineTo(lx, lt - th * 0.075); ctx.lineTo(lx + lw * 1.2, lt); ctx.closePath(); ctx.fillStyle = '#10181e'; ctx.fill();
    ctx.fillRect(lx - 0.8 * u, lt - th * 0.095, 1.6 * u, th * 0.03);

    /* the beam, through fog */
    if (o.beams) {
      ctx.save(); ctx.globalCompositeOperation = 'lighter';
      const toward = o.lx > 0.5 ? -1 : 1;
      blur(5, () => {
        [[toward, 0.008, 0.05, 1.1, 0.55], [-toward, 0.008, 0.03, 0.45, 0.25]].forEach(([dir, near, far, len, a]) => {
          const x1 = lcx + dir * W * len, tilt = 0.02 * H * dir * -1;
          const gg = ctx.createLinearGradient(lcx, 0, x1, 0);
          gg.addColorStop(0, `rgba(255,214,140,${a})`); gg.addColorStop(0.45, `rgba(255,190,100,${a * 0.22})`); gg.addColorStop(1, 'rgba(255,190,100,0)');
          ctx.fillStyle = gg;
          ctx.beginPath();
          ctx.moveTo(lcx, lcy - near * H); ctx.lineTo(x1, lcy + tilt - far * H); ctx.lineTo(x1, lcy + tilt + far * H); ctx.lineTo(lcx, lcy + near * H); ctx.closePath(); ctx.fill();
        });
      });
      softEllipse(lcx, lcy, th * 0.7, th * 0.5, 'rgba(255,200,120,.30)');
      softEllipse(lcx, lcy, th * 0.16, th * 0.16, 'rgba(255,236,190,.55)');
      ctx.restore();
    }

    /* fog between the rock and the viewer */
    fogBand(baseY + 0.09 * H, 0.04 * H, 0.22 * o.fogLow, '#8da2aa');
    fogBand(baseY + 0.24 * H, 0.07 * H, 0.12 * o.fogLow, '#8da2aa');

    /* foreground: rocks, tide piling, gulls */
    const rockMass = (x0, x1, top, jitter) => {
      const pts = [[x0, H + 5]];
      const n = 9;
      for (let i = 0; i <= n; i++) {
        const t = i / n, hump = Math.sin(t * Math.PI);
        pts.push([lerp(x0, x1, t), H - (H - top) * Math.pow(hump, 0.6) + (R() - 0.5) * jitter * H]);
      }
      pts.push([x1, H + 5]);
      return pts;
    };
    const fr = [
      rockMass(-0.05 * W, 0.2 * W, H * 0.8, 0.07),
      rockMass(0.12 * W, 0.3 * W, H * 0.9, 0.04),
      rockMass(0.88 * W, 1.05 * W, H * 0.86, 0.05),
    ];
    fr.forEach((pts) => {
      const xs = pts.map((p) => p[0]), ys = pts.map((p) => p[1]);
      const bb = { x: Math.min(...xs), y: Math.min(...ys), w: Math.max(...xs) - Math.min(...xs), h: H - Math.min(...ys) };
      g = ctx.createLinearGradient(0, bb.y, 0, H);
      g.addColorStop(0, '#1c262d'); g.addColorStop(1, '#070c10');
      ctx.fillStyle = g; ctx.beginPath(); pts.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.closePath(); ctx.fill();
      facets(pts, bb, 80, false);
      ctx.strokeStyle = 'rgba(150,185,200,.22)'; ctx.lineWidth = 1.6 * u;                      // cold rim along the top edge
      ctx.beginPath(); pts.slice(1, -1).forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]))); ctx.stroke();
    });

    // tide piling with painted foot marks (the in-game tide gauge)
    {
      const px = o.pilX * W, pw = 0.042 * H, ptop = H - o.pilH * H, pb = H + 4;
      g = ctx.createLinearGradient(px - pw / 2, 0, px + pw / 2, 0);
      g.addColorStop(0, '#3a474f'); g.addColorStop(0.55, '#1a232a'); g.addColorStop(1, '#090e12');
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.moveTo(px - pw / 2, pb); ctx.lineTo(px - pw * 0.46, ptop + pw * 0.4); ctx.lineTo(px + pw * 0.5, ptop); ctx.lineTo(px + pw / 2, pb); ctx.closePath(); ctx.fill();
      const feet = 12, step = (pb - 0.05 * H - ptop) / feet;
      for (let i = 0; i < feet; i++) {
        const y = pb - 0.03 * H - i * step * 0.98;
        const major = i % 5 === 0;
        ctx.fillStyle = rgba(PAL.fog, major ? 0.82 : 0.6);
        ctx.fillRect(px - pw * (major ? 0.5 : 0.36), y, pw * (major ? 1.0 : 0.72), (major ? 5 : 3) * u);
      }
      const wy = H - 0.2 * H;                                                       // waterline stain
      g = ctx.createLinearGradient(0, wy, 0, pb);
      g.addColorStop(0, 'rgba(70,110,95,0)'); g.addColorStop(1, 'rgba(70,110,95,.45)');
      ctx.fillStyle = g; ctx.fillRect(px - pw / 2, wy, pw, pb - wy);
    }
    // gulls
    ctx.strokeStyle = 'rgba(10,16,22,.75)'; ctx.lineCap = 'round';
    for (let i = 0; i < 4; i++) {
      const gx = (0.25 + R() * 0.6) * W, gy2 = (0.1 + R() * 0.28) * H, s = (9 + R() * 12) * u;
      ctx.lineWidth = Math.max(1, 1.8 * u);
      ctx.beginPath(); ctx.moveTo(gx - s, gy2 + s * 0.15); ctx.quadraticCurveTo(gx - s * 0.5, gy2 - s * 0.35, gx, gy2); ctx.quadraticCurveTo(gx + s * 0.5, gy2 - s * 0.35, gx + s, gy2 + s * 0.15); ctx.stroke();
    }

    // low fog drifting across the flats
    fogBand(H * 0.9, 0.07 * H, 0.1 * o.fogLow, '#a8bcc2');

    /* finish: dim, vignette, grain */
    if (o.dim) { ctx.fillStyle = `rgba(13,21,29,${o.dim})`; ctx.fillRect(0, 0, W, H); }
    g = ctx.createRadialGradient(W * 0.5, H * 0.5, H * 0.35, W * 0.5, H * 0.5, Math.max(W, H) * 0.75);
    g.addColorStop(0, 'rgba(6,10,14,0)'); g.addColorStop(1, `rgba(6,10,14,${o.vig})`);
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    if (o.grain) {
      const t = document.createElement('canvas'); t.width = t.height = 256;
      const tc = t.getContext('2d'), id = tc.createImageData(256, 256), rr = rng(o.seed + 99);
      for (let i = 0; i < id.data.length; i += 4) { const v = 90 + rr() * 80; id.data[i] = id.data[i + 1] = id.data[i + 2] = v; id.data[i + 3] = 255; }
      tc.putImageData(id, 0, 0);
      ctx.save(); ctx.globalCompositeOperation = 'overlay'; ctx.globalAlpha = o.grain;
      ctx.fillStyle = ctx.createPattern(t, 'repeat'); ctx.scale(Math.max(1, u * 1.2), Math.max(1, u * 1.2)); ctx.fillRect(0, 0, W / Math.max(1, u * 1.2), H / Math.max(1, u * 1.2));
      ctx.restore();
    }
  };

  /* ---------- Steam assets ---------- */
  // logo: {x, cy, w, align}; x is the left edge (or the centre when align is 'center'), cy the vertical centre, both as fractions.
  // Eyebrow and tagline are placed relative to the logo, so every direction lays out the same way.
  const SCENE_WIDE = { lx: 0.7, hz: 0.52, base: 0.72, lh: 0.52, barX: 0.42, pilX: 0.03, pilH: 0.6, figT: 0.4 };
  const PORTRAIT = { lx: 0.58, hz: 0.4, base: 0.55, lh: 0.36, barX: 0.3, pilX: 0.06, pilH: 0.34, figT: 0.5 };
  LT.ASSETS = {
    library_hero:     { w: 3840, h: 1240, shared: true, scene: { ...SCENE_WIDE, lx: 0.69, lh: 0.56, base: 0.7 } },
    page_background:  { w: 1438, h: 810,  shared: true, scene: { ...SCENE_WIDE, lx: 0.965, lh: 0.66, base: 0.8, barX: 0.8, pilX: 0.02, fig: false, cottage: false, dim: 0.5, vig: 0.75 }, fadeBottom: true },
    key_art:          { w: 1920, h: 1080, shared: true, scene: { ...SCENE_WIDE, lx: 0.66, lh: 0.58, base: 0.74 } },
    header_capsule:   { w: 920,  h: 430,  scene: { ...SCENE_WIDE, lx: 0.77, hz: 0.5, base: 0.78, lh: 0.62, barX: 0.5, pilX: 0.035, pilH: 0.7, fig: false }, scrim: 'left', logo: { x: 0.05, cy: 0.5, w: 0.46 }, tagline: true },
    small_capsule:    { w: 462,  h: 174,  scene: { ...SCENE_WIDE, lx: 0.84, lh: 0.62, base: 0.9, barX: 0.6, pilH: 0.8, fig: false, grain: 0.14 }, scrim: 'left', logo: { x: 0.05, cy: 0.5, w: 0.5 } },
    main_capsule:     { w: 1232, h: 706,  scene: { ...SCENE_WIDE, lx: 0.76, lh: 0.58, base: 0.74, barX: 0.7, figT: 0.3 }, scrim: 'bottom', logo: { x: 0.075, cy: 0.76, w: 0.4 }, tagline: true },
    vertical_capsule: { w: 748,  h: 896,  scene: PORTRAIT, scrim: 'bottom', logo: { x: 0.5, cy: 0.8, w: 0.74, align: 'center' }, eyebrow: true, tagline: true },
    library_capsule:  { w: 600,  h: 900,  scene: PORTRAIT, scrim: 'bottom', logo: { x: 0.5, cy: 0.8, w: 0.74, align: 'center' }, eyebrow: true, tagline: true },
    logo_transparent: { w: 1280, h: 720,  transparent: true, beam: true, logo: { x: 0.5, cy: 0.5, w: 0.8, align: 'center' } },
    community_icon:   { w: 184,  h: 184,  icon: true },
  };

  function loadSVG(svg, w) {
    return new Promise((res, rej) => {
      const img = new Image();
      img.onload = () => res(img);
      img.onerror = rej;
      img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg.replace('<svg ', `<svg width="${w}" `));
    });
  }

  // scale < 1 renders a smaller copy of the same composition (used by the store page preview).
  LT.renderAsset = async function (canvas, kind, scale, variant) {
    const A = Object.assign({}, LT.ASSETS[kind]);
    const V = LT.VARIANTS[variant || LT.variant];
    scale = scale || 1;
    A.w = Math.round(A.w * scale); A.h = Math.round(A.h * scale);
    canvas.width = A.w; canvas.height = A.h;
    const ctx = canvas.getContext('2d');
    const u = A.h / 1000;
    if (A.icon) {
      const img = await loadSVG(LT.logoSVG({ variant: V.key, layout: 'mark', bg: PAL.night, id: 'ic', beam: false }), A.w);
      ctx.drawImage(img, 0, 0, A.w, A.h);
      return canvas;
    }
    if (!A.transparent) LT.drawScene(ctx, A.w, A.h, A.scene);
    if (A.scrim) {
      let g;
      if (A.scrim === 'left') { g = ctx.createLinearGradient(0, 0, A.w * 0.75, 0); g.addColorStop(0, 'rgba(8,13,18,.82)'); g.addColorStop(1, 'rgba(8,13,18,0)'); }
      else { g = ctx.createLinearGradient(0, A.h * 0.45, 0, A.h); g.addColorStop(0, 'rgba(8,13,18,0)'); g.addColorStop(1, 'rgba(8,13,18,.85)'); }
      ctx.fillStyle = g; ctx.fillRect(0, 0, A.w, A.h);
    }
    if (A.fadeBottom) {
      const g = ctx.createLinearGradient(0, A.h * 0.55, 0, A.h);
      g.addColorStop(0, 'rgba(27,40,56,0)'); g.addColorStop(1, '#1b2838');  // Steam's page blue, so the art melts into the page
      ctx.fillStyle = g; ctx.fillRect(0, 0, A.w, A.h);
    }
    let lx = 0, ly = 0, lw = 0, lh = 0;
    if (A.logo) {
      lw = A.logo.w * A.w;
      const img = await loadSVG(LT.logoSVG({ variant: V.key, id: 'a', beam: !!A.beam && V.key === 'h' }), lw);
      lh = lw * (img.naturalHeight / img.naturalWidth);
      lx = A.logo.align === 'center' ? A.logo.x * A.w - lw / 2 : A.logo.x * A.w;
      ly = A.logo.cy * A.h - lh / 2;
      ctx.drawImage(img, lx, ly, lw, lh);
    }
    const type = (text, x, y, font, color, track, center) => {
      ctx.save();
      ctx.font = font; ctx.fillStyle = color; ctx.letterSpacing = track;
      ctx.textAlign = center ? 'center' : 'left'; ctx.textBaseline = 'alphabetic';
      ctx.shadowColor = 'rgba(0,0,0,.55)'; ctx.shadowBlur = 8 * u;
      ctx.fillText(text, x, y);
      ctx.restore();
    };
    const center = A.logo && A.logo.align === 'center';
    const tx = center ? lx + lw / 2 : lx;
    if (A.eyebrow && V.eyebrow) type('WINTER 1998 · GANNET ROCK', tx, ly - 16 * u * 1.6, `500 ${Math.round(Math.max(11, 17 * u * 1.5))}px "IBM Plex Mono", monospace`, PAL.sea, `${Math.round(3 * u * 1.6)}px`, center);
    if (A.tagline && !(V.tagCase && A.w / A.h > 1.6 && A.w < 1000)) {
      const px = Math.round(Math.max(22, 40 * u * (A.w / A.h > 1.6 ? 1.0 : 1.35)));
      const text = V.tagCase ? 'WHAT THE TIDE LEAVES.' : 'What the tide leaves.';
      type(text, tx, ly + lh + px * 1.15, V.tagFont(px), PAL.fog, `${(V.tagTrack * px * (V.tagCase ? 0.5 : 0.1)).toFixed(1)}px`, center);
    }
    return canvas;
  };
})();
