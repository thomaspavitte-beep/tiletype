# Tiles — Tile-Font Typesetter

A small creative tool for **typing with a hand-drawn tile font**. Press a key, the matching tile
drops onto a grid; build words/patterns, restyle the stroke, and export a seamless result.

This folder is the whole "typewriter" concept and is a standalone git repo (hostable on GitHub
Pages — the app is a static site rooted at `index.html`). It is self-contained and unrelated to
the other experiments in the parent `Tiles/` project.

## Files
- `index.html` — the entire app (one self-contained file: HTML + CSS + inline JS,
  renders tiles as inline SVG). No build step, no dependencies. Lives at the repo root so
  GitHub Pages serves it directly.
- `SVG/` — the font: 33 tile SVGs. `A.svg`–`Z.svg` and `1.svg`–`7.svg`. These are the source of
  truth for the artwork.
- `Open Typesetter.command` — double-click launcher (macOS). Serves this folder locally and opens
  the app in the browser so the font can be edited live (see "Running").

## The tile font (important geometry)
Every tile SVG is:
- `viewBox="0 0 52.5 52.5"` — a square artboard.
- **Pure stroke** — `fill:none`, `stroke:#221f1f` (letters) / `#231f20` (numbers), `stroke-width:2.5`,
  round caps. Shapes are `<path>` / `<line>` / `<circle>`. The zero-length `<line>`s are the
  round-cap **registration dots**.
- Drawn on a **50×50 registration grid inset 1.25 from the artboard edge**: the connection/path
  points sit at coordinates **1.25 … 51.25** on both axes (letter bodies are interior, ~7.45 … 45.05).

**This 1.25 inset / 50-unit repeat is the key fact the app depends on.** Tiles are aligned by this
path grid, not by the 52.5 artboard — see "How rendering works".

## How the app works
- **Font loading** — on startup the app tries to **fetch** each SVG from `SVG/*.svg` (cache-busted,
  so edits show on refresh). If the page isn't served from `LETTERS/` (e.g. opened as a `file://`),
  it falls back to a **base64 copy embedded in the HTML** so it never comes up blank. The status
  line shows `33 live` vs `33 embedded`.
- **Key → tile map** — `a`–`z` → letters, `1`–`7` → numbers (lowercase; digits 8/9/0 unused).
- **Recolour / restroke** — each tile is rendered inside an `<svg>` with an injected scoped style
  that forces `stroke:currentColor` and `stroke-width:var(--sw)`, so the panel controls (ink colour,
  stroke width) restyle the baked-in font live.
- **Document model** — `lines = [[cell,…],…]`, `cell = {key, rot} | {blank:true}`, plus a `caret {r,c}`.
  Free-growing lines (text-editor feel): letters/digits insert + advance, **Space** = blank cell,
  **Enter** = new line, **Backspace** = delete/merge, **arrows** move the caret.
- **Rotation** — click a placed tile to rotate it 90° (`rot` 0–3, CSS `transform:rotate`).
- **Cursor** — the ready cell is shown as a **subtle highlighted grid square** (`.cursor-cell`), not a
  text caret, so it adheres to the grid. Rows contain only real cells (no trailing spacer column —
  the paper is exactly `cols × size`); clicking free paper places the cursor on that grid square via
  a sheet-level click handler (slots stop propagation).
- **Controls** — ink colour, stroke width, paper background, tile size (zoom), Clear, Sample.
- **Poem mode** — a built-in bank of ~45 short original poems (`POEMS`, lowercase a–z only) plus a
  seeded layout engine (`composePoem` + `mulberry32`). **New poem** picks a poem; **Reshuffle**
  re-scatters the same poem with a new seed. Lines get random indents (organic, not left-aligned),
  and **every empty cell** (word gaps, indents, padding, spacer rows, inner border ring) is filled
  with a randomly-rotated **pattern tile** (`1`–`7`) with probability = Pattern density (default
  100% — a solid field of pattern with the words embedded; lower it for airier layouts). An optional
  **border** wraps the padded rectangle in a solid ring of pattern tiles. Sliders: Indent (0–6),
  Word gap (1–3), Pattern density (0–100%); Border checkbox; **Square canvas** checkbox (default on)
  pads the composition to N×N before the border, for social-media-ready square exports. The Compose
  section also has a **Square** button that pads any hand-typed grid to square with centred blanks.
  Output is ordinary `lines` cells, so a generated poem stays fully hand-editable and exports as usual.
- **Export** — `buildSVG()` composes the current grid into one SVG (vector); PNG is that SVG drawn to
  a canvas at 2×/4×/8×. Both are seamless and use the same registration grid as the screen. The
  background rect uses an inline `style="fill:…"` because the exported stylesheet's `rect{fill:none}`
  would override a plain `fill` attribute.
- **Strands** — the engine fuses lines that continue across tile boundaries. `extractInner` explodes
  multi-subpath paths so 1 element = 1 segment; `tileGeometry(key)` caches each segment's endpoints
  (via `getPointAtLength` in a hidden svg); `computeStrands()` maps endpoints to global grid coords
  (same rotate-about-26.25 math as export), snaps to 0.05, and union-finds segments whose endpoints
  coincide at points shared by exactly 2 segments (junctions >2 are left uncut; dots and
  circles/loops are excluded). Strands spanning **≥ 2 cells** get seeded golden-angle `hsl` colours;
  single-cell strands and dots stay ink — letter *bodies* remain readable, though letters' small
  edge arcs legitimately join field strands (they really do touch the boundary; 4–16 per letter).
  UI: **Colour strands** checkbox + **Recolour** (new seed). On screen colours are applied after
  every `render()` via inline `style.setProperty("stroke", …, "important")` (beats the injected
  `currentColor!important` rule); SVG/PNG exports get per-element inline styles via
  `colouredMarkup()`. GIF/WebM animation exports remain ink-only (per-key raster cache can't hold
  per-cell colours). Gotcha: `strandState`/`DRAWABLES` are declared with the document model because
  `render()` runs during control wire-up, before the engine block (TDZ otherwise). Future layers on
  this engine: draw-on strand animation, hover-to-trace, fused single-path export.
- **Typewriter animation** — the composition reveals tile by tile (`revealOrder`: `typewriter`
  row-major, `letters first`, `patterns first`, or `random` — a seeded shuffle of every tile;
  speed slider = tiles/sec with per-tile jitter).
  **Play** veils tile slots (`.veiled`) and un-veils on a timer, moving the cursor square with the
  reveal front. **Export GIF** re-renders the reveal to an offscreen canvas — each tile is
  pre-rasterized at the **full 52.5 artboard** and drawn at `cell centre` (artboard centre =
  registration centre, so the 1.25 bleed overlaps neighbours exactly as on screen) — and encodes a
  looping GIF via an **inline GIF89a/LZW encoder** (no dependency; 32-colour ink→bg ramp palette,
  ≤120 frames, ~640px wide, long hold on the final frame). **Export WebM** records the same frame
  loop in real time via `canvas.captureStream` + `MediaRecorder` at higher resolution.

## How rendering works (the alignment decision)
Naively laying tiles flush by the 52.5 artboard puts adjacent path points **2.5 apart** (the 1.25
bleed on each side) — a visible misregistration. Instead:

- **On-screen:** each tile is rendered with `viewBox="1.25 1.25 50 50"` (constants `INSET=1.25`,
  `PITCH=50`) — the coordinate system is cropped to the registration grid, so adjacent tile
  boundaries fall exactly on the path points and neighbouring tiles' vectors coincide. `.slot svg`
  uses `overflow:visible` so edge dots render fully (they land on the neighbour's identical dot).
- **Export:** the same grid — overall `viewBox` has a small `INSET` margin, and each tile group is
  `translate(col*PITCH - INSET, row*PITCH - INSET)` with rotation about the tile centre `26.25`.

Because alignment is by the **path centreline**, it is **independent of stroke width** — changing the
Width control never shifts registration (only the visible line weight). The stroke also **scales with
the tile** (no `vector-effect:non-scaling-stroke`), matching the original font design.

## Running
- **Live editing (recommended):** double-click `Open Typesetter.command`. It serves `LETTERS/` and
  opens `http://localhost:<port>/`. Edit any `SVG/*.svg`, then refresh the browser (⌘R)
  to see the change. (First time, macOS Gatekeeper may need: right-click → Open → Open.)
- **Any other way (double-click the HTML, etc.):** still works via the embedded font fallback, but
  edits to `SVG/` won't be reflected until re-embedded.

## Updating the font
The tiles in `SVG/` are the source of truth; the embedded copy in `index.html` is only a
fallback. If you change the SVGs and want the fallback (offline/`file://`) copy to match, the base64
`TILE_RAW` block in `index.html` must be regenerated (each entry is `key → base64 of the SVG file`).
When served via the launcher this is unnecessary — the live fetch always reflects the current files.

## Conventions when editing this app
- Keep it a **single self-contained `index.html`** — no build tooling, no external libs.
- Don't hard-code the 1.25/50 numbers ad hoc — use the `INSET` / `PITCH` constants.
- Preserve the **fetch-first, embedded-fallback** loading so the app never renders blank.
- New tiles must follow the font's geometry (52.5 artboard, 1.25 registration inset) to stay aligned.
