# Tiles · Type

A typewriter for a hand-drawn **tile font**. Type with your keyboard and letter-tiles drop onto a
grid; every tile's paths register exactly with its neighbours, so words, patterns and borders knit
together into one continuous piece. Generate little poems, scatter them organically across a
pattern field, animate the whole thing like a typewriter, and export print-ready SVG/PNG or a
looping GIF.

The whole app is a **single `index.html`** — no build step, no dependencies. The font (33 stroke-only
SVG tiles) is fetched live from `SVG/`, with a base64 copy embedded in the HTML as a fallback so the
page also works opened straight from disk.

## Try it

Open the hosted page (GitHub Pages), or locally:

```
python3 -m http.server 8777   # from the repo root
# then open http://localhost:8777/
```

macOS: just double-click `Open Typesetter.command` — it serves the folder and opens the app.
(First time: right-click → Open, to get past Gatekeeper.)

## Using it

| Keys | |
|---|---|
| `a`–`z` | place a letter tile |
| `1`–`7` | place a pattern tile |
| `Space` / `Enter` / `Backspace` | blank cell / new line / delete |
| arrows | move the cursor square |
| click a tile | rotate it 90° |

- **Stroke / Paper** — live ink colour, stroke width, paper colour, tile size. Alignment is by the
  vector path grid, so changing stroke width never shifts registration.
- **Poem** — drops one of ~45 built-in short poems onto the paper with organic indents, the empty
  field filled with randomly-rotated pattern tiles, an optional pattern-tile border, and an optional
  square canvas (social-media friendly). Reshuffle re-scatters the same poem; everything stays
  hand-editable afterwards.
- **Animate** — the composition reveals tile by tile (typewriter / letters-first / patterns-first /
  random order) with the cursor riding along. Export the animation as a looping **GIF** (encoder is
  built into the page) or **WebM**.
- **Export** — seamless **SVG** (vector) and **PNG** (up to 8×) of the current composition.

## The font

Each tile is a `52.5 × 52.5` artboard, pure stroke (no fills), drawn on a **50-unit registration
grid inset 1.25 from the edge** — the round-cap dots at the edges are the registration points.
Tiles are laid out on that 50-unit grid (viewBox `1.25 1.25 50 50`), so adjacent tiles' path points
land exactly on top of each other at any rotation. To extend the font, draw new tiles with the same
geometry and drop them in `SVG/`.

---

Tile font and artwork © Thomas Pavitte. All rights reserved.
