# Tiles · Type

A typewriter for a hand-drawn **tile font**. Type with your keyboard and letter-tiles drop onto a
grid; every tile's paths register exactly with its neighbours, so words, patterns and borders knit
together into one continuous piece. Generate little poems, scatter them organically across a
pattern field, animate the whole thing like a typewriter, and export print-ready SVG/PNG or a
looping GIF.

The whole app is a **single `index.html`** — no build step, no dependencies. The font (36 stroke-only
SVG tiles) is fetched live from `SVG/`, with a base64 copy embedded in the HTML as a fallback so the
page also works opened straight from disk.

## Try it

**Live:** https://thomaspavitte-beep.github.io/tiletype/

The hosted page opens the **player**: an ambient gallery that composes little tile poems, draws
them in strand by strand, and dissolves into the next — with prev/next, pause, a line-width
slider, sound, tile drift, and fullscreen in a small bar. Hover any line to light up its whole
connected strand and hear its note (longer strands ring lower).

Press **your words** in the player bar (or add **`?words`** to the URL) for the personalised
gallery: type your own words directly in the tile font on a clean sheet, press Enter twice, and
they weave themselves into the pattern field — then the gallery riffs on them, re-composing the
same words in a new layout and colourway, endlessly. Any key starts a new phrase; Esc returns to
the gallery's own poems.

Add **`?studio`** to the URL for the full tool (type with the font, scatter your own words,
colour strands, animate, export SVG/PNG/GIF/WebM).

Run it locally:

```
python3 -m http.server 8777   # from the repo root
# then open http://localhost:8777/
```

macOS: just double-click `Open Typesetter.command` — it serves the folder and opens the app.
(First time: right-click → Open, to get past Gatekeeper.)

## Using the studio (`?studio`)

| Keys | |
|---|---|
| `a`–`z` | place a letter tile |
| `0`–`9` | place a pattern tile |
| `Space` | random pattern tile (`⇧Space` = blank) |
| `Enter` / `Backspace` | new line / delete |
| arrows | move the cursor square |
| click a tile | rotate it 90° |

- **Stroke / Paper** — live ink colour, stroke width, paper colour, tile size. Alignment is by the
  vector path grid, so changing stroke width never shifts registration.
- **Poem** — drops one of ~45 built-in short poems — or **your own words** via the text box — onto
  the paper with organic indents, the empty
  field filled with randomly-rotated pattern tiles, an optional pattern-tile border, and an optional
  square canvas (social-media friendly). Reshuffle re-scatters the same poem; everything stays
  hand-editable afterwards.
- **Animate** — the composition reveals tile by tile (typewriter / letters-first / patterns-first /
  random order) with the cursor riding along. Export the animation as a looping **GIF** (encoder is
  built into the page) or **WebM**.
- **Export** — seamless **SVG** (vector) and **PNG** (up to 8×) of the current composition.

## The font

Each tile is an `840 × 840` artboard, pure stroke (no fills), drawn on an **800-unit registration
grid inset 20 from the edge** — the round-cap dots at the edges are the registration points.
Tiles are laid out on that 800-unit grid (viewBox `20 20 800 800`), so adjacent tiles' path points
land exactly on top of each other at any rotation. To extend the font, draw new tiles with the same
geometry and drop them in `SVG/`.

---

Tile font and artwork © Thomas Pavitte. All rights reserved.
