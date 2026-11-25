#!/usr/bin/env python3
"""Outline the Low Tide wordmark variants into marketing/steam/wordmark.js.

  b  Cormorant Garamond semibold, lowercase. The dot of the i is the lamp.
  c  Big Shoulders Stencil, capitals, with an amber rule and "GANNET ROCK . 1998".
  h  Cormorant Garamond capitals. The I is the lighthouse (fallback).

Fonts are SIL OFL, fetched from Google Fonts. Text is kerned with HarfBuzz, tracked, then outlined,
so the logo never depends on a font at runtime.
Requires: pip install fonttools uharfbuzz
"""
import json, re, urllib.request
from pathlib import Path
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import RecordingPen

OUT = Path(__file__).resolve().parent.parent / "wordmark.js"
CACHE = Path("/tmp/lowtide-fonts"); CACHE.mkdir(exist_ok=True)


def fetch(family: str, weight: int) -> Path:
    dst = CACHE / (re.sub(r"\W+", "", family) + str(weight) + ".ttf")
    if dst.exists():
        return dst
    q = family.replace(" ", "+")
    css = urllib.request.urlopen(urllib.request.Request(
        f"https://fonts.googleapis.com/css2?family={q}:wght@{weight}", headers={"User-Agent": "Mozilla/5.0"})).read().decode()
    url = re.search(r"url\((https://[^)]+\.ttf)\)", css).group(1)
    raw = CACHE / "raw.ttf"; raw.write_bytes(urllib.request.urlopen(url).read())
    f = TTFont(raw)
    if "fvar" in f:  # variable font: pin the weight
        f = instancer.instantiateVariableFont(f, {"wght": weight})
    f.save(dst)
    return dst


def n(v):
    return ("%.1f" % v).rstrip("0").rstrip(".")


class Face:
    def __init__(self, family, weight):
        self.path = fetch(family, weight)
        self.tt = TTFont(self.path)
        self.gs = self.tt.getGlyphSet(); self.order = self.tt.getGlyphOrder(); self.cmap = self.tt.getBestCmap()
        self.k = 1000 / self.tt["head"].unitsPerEm
        self.hb = hb.Font(hb.Face(hb.Blob.from_file_path(str(self.path))))

    def glyph_bounds(self, name):
        bp = BoundsPen(self.gs); self.gs[name].draw(bp); return bp.bounds

    def set(self, text, track, space=None, scale=1.0):
        """Kern, track and outline `text`. Returns (path d, width, [(char, pen_x, glyph name)])."""
        buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
        hb.shape(self.hb, buf, {"kern": True})
        pen = SVGPathPen(self.gs, ntos=n); x = 0.0; placed = []
        for i, (info, pos) in enumerate(zip(buf.glyph_infos, buf.glyph_positions)):
            name = self.order[info.codepoint]; ch = text[info.cluster]
            self.gs[name].draw(TransformPen(pen, (self.k * scale, 0, 0, -self.k * scale, x + pos.x_offset * self.k * scale, 0)))
            placed.append((ch, x, name))
            adv = pos.x_advance * self.k * scale
            if ch == " " and space is not None:
                adv = space * scale
            x += adv + (track * scale if i < len(buf.glyph_infos) - 1 else 0)
        return pen.getCommands(), x, placed

    def dot_of_i(self):
        """Centre (x, y up) and radius of the dot on the font's own i, in 1000-unit space."""
        name = self.cmap[ord("i")]
        rec = RecordingPen(); self.gs[name].draw(rec)
        contours, cur = [], []
        for op, args in rec.value:
            cur += [p for p in args if p is not None]
            if op in ("closePath", "endPath"):
                contours.append(cur); cur = []
        dot = max(contours, key=lambda c: min(p[1] for p in c))
        xs = [p[0] for p in dot]; ys = [p[1] for p in dot]
        return ((min(xs) + max(xs)) / 2 * self.k, (min(ys) + max(ys)) / 2 * self.k, ((max(xs) - min(xs)) + (max(ys) - min(ys))) / 4 * self.k)


def top_of(face, d_text):
    # height above the baseline of the tallest glyph in the string (SVG y is negative up)
    ys = [face.glyph_bounds(face.cmap[ord(c)])[3] for c in d_text if c != " "]
    return max(ys) * face.k


def main():
    corm = Face("Cormorant Garamond", 600)
    stencil = Face("Big Shoulders Stencil Display", 800)
    mono = Face("IBM Plex Mono", 500)
    out = {}

    # ---- B: lowercase, the lamp is the dot of the i ----
    text = "low tıde"
    d, w, placed = corm.set(text, track=48, space=230)
    dx, dy, dr = corm.dot_of_i()
    ch, px, gname = next(p for p in placed if p[0] == "ı")
    gb = corm.glyph_bounds(gname)
    # lamp x: centre of the dotless stem (the dot sits over it); y and size from the font's own dot
    stem_cx = px + (gb[0] + gb[2]) / 2 * corm.k
    ccx = (gb[0] + gb[2]) / 2 * corm.k
    mark_d, _, _ = corm.set("ı", track=0)
    out["b"] = {"w": round(w, 1), "top": round(top_of(corm, text.replace("ı", "i")), 1), "d": d,
                "lamp": {"cx": round(stem_cx, 1), "cy": round(-dy, 1), "r": round(dr, 1)},
                "mark": {"d": mark_d, "w": round((gb[2] - gb[0]) * corm.k, 1), "cx": round(ccx, 1),
                         "top": round(gb[3] * corm.k, 1), "lamp": {"cx": round(ccx, 1), "cy": round(-dy, 1), "r": round(dr, 1)}}}

    # ---- C: stencil capitals, amber rule, small classification line ----
    text = "LOW TIDE"
    d, w, _ = stencil.set(text, track=150, space=170)
    top = top_of(stencil, text)
    sub_d, sub_w, _ = mono.set("GANNET ROCK · 1998", track=520)
    s = (w * 0.74) / sub_w
    sub_d, sub_w, _ = mono.set("GANNET ROCK · 1998", track=520, scale=s)
    sub_top = top_of(mono, "GANNET ROCK") * s
    mk_d, mk_w, _ = stencil.set("LT", track=150)
    out["c"] = {"w": round(w, 1), "top": round(top, 1), "d": d,
                "sub": {"d": sub_d, "w": round(sub_w, 1), "top": round(sub_top, 1)},
                "mark": {"d": mk_d, "w": round(mk_w, 1), "top": round(top, 1)}}

    # ---- H: capitals, the I is the lighthouse (fallback) ----
    text = "LOW TIDE"
    d, w, placed = corm.set(text, track=200, space=260)
    ch, px, gname = next(p for p in placed if p[0] == "I")
    gb = corm.glyph_bounds(gname)
    out["h"] = {"w": round(w, 1), "top": round(top_of(corm, text), 1), "d": d,
                "lamp": {"cx": round(px + (gb[0] + gb[2]) / 2 * corm.k, 1), "cy": 0, "r": 38}}
    out["h"]["lamp"]["cy"] = -round(out["h"]["top"] + 135, 1)

    OUT.write_text("/* Generated by tools/build_wordmark.py. Cormorant Garamond, Big Shoulders Stencil Display, IBM Plex Mono (SIL OFL). Do not edit. */\n"
                   "window.LT = window.LT || {};\nLT.WORDMARKS = " + json.dumps(out) + ";\n")
    for k, v in out.items():
        print(k, "width", v["w"], "top", v["top"], "lamp", v.get("lamp"))


main()
