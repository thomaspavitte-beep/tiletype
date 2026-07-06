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
- `SVG/` — the font: 36 tile SVGs. `A.svg`–`Z.svg` and `0.svg`–`9.svg` (patterns). These are the source of
  truth for the artwork.
- `Open Typesetter.command` — double-click launcher (macOS). Serves this folder locally and opens
  the app in the browser so the font can be edited live (see "Running").

## The tile font (important geometry)
Every tile SVG is:
- `viewBox="0 0 840 840"` — a square artboard (clean integer coordinates).
- **Pure stroke** — `fill:none`, `stroke:#221f1f`, `stroke-width:40`,
  round caps. Shapes are `<path>` / `<line>` / `<circle>`. The zero-length `<line>`s are the
  round-cap **registration dots**.
- Drawn on an **800×800 registration grid inset 20 from the artboard edge**: the connection/path
  points sit at coordinates **20 … 820** on clean 100-unit steps.

**This 20 inset / 800-unit repeat is the key fact the app depends on.** Tiles are aligned by this
path grid, not by the 840 artboard — see "How rendering works".

## How the app works
- **Font loading** — on startup the app tries to **fetch** each SVG from `SVG/*.svg` (cache-busted,
  so edits show on refresh). If the page isn't served from `LETTERS/` (e.g. opened as a `file://`),
  it falls back to a **base64 copy embedded in the HTML** so it never comes up blank. The status
  line shows `36 live` vs `36 embedded`.
- **Key → tile map** — `a`–`z` → letters, `0`–`9` → pattern tiles (lowercase).
- **Recolour / restroke** — each tile is rendered inside an `<svg>` with an injected scoped style
  that forces `stroke:currentColor` and `stroke-width:var(--sw)`, so the panel controls (ink colour,
  stroke width) restyle the baked-in font live.
- **Document model** — `lines = [[cell,…],…]`, `cell = {key, rot} | {blank:true}`, plus a `caret {r,c}`.
  Free-growing lines (text-editor feel): letters/digits insert + advance, **Space** = a random
  pattern tile (random rotation; **Shift+Space** = blank cell), **Enter** = new line, **Backspace**
  = delete/merge, **arrows** move the caret.
- **Rotation** — click a placed tile to rotate it 90° (`rot` 0–3, CSS `transform:rotate`).
- **Cursor** — the ready cell is shown as a **subtle highlighted grid square** (`.cursor-cell`), not a
  text caret, so it adheres to the grid. Rows contain only real cells (no trailing spacer column —
  the paper is exactly `cols × size`); clicking free paper places the cursor on that grid square via
  a sheet-level click handler (slots stop propagation).
- **Controls** — ink colour, stroke width, paper background, tile size (zoom), Clear, Sample.
- **Poem mode** — a built-in bank of ~45 short original poems (`POEMS`, lowercase a–z only) plus a
  seeded layout engine (`composePoem` + `mulberry32`). A textarea + **Scatter my words** button set
  `poemState.custom` (sanitized to `[a-z0-9 ]`; digits become literal pattern tiles) — `composePoem`
  reads `custom || POEMS[idx]`, so Reshuffle and all sliders work on your own words too; **New
  poem** clears `custom` (back to the bank); ambient cycles the bank and snapshots/restores
  `custom`. **New poem** picks a poem; **Reshuffle**
  re-scatters the same poem with a new seed. Lines get random indents (organic, not left-aligned),
  and **every empty cell** (word gaps, indents, padding, spacer rows, inner border ring) is filled
  with a randomly-rotated **pattern tile** (`0`–`9`) with probability = Pattern density (default
  100% — a solid field of pattern with the words embedded; lower it for airier layouts). An optional
  **border** wraps the padded rectangle in a solid ring of pattern tiles. Sliders: Indent (0–6),
  Word gap (1–3), Pattern density (0–100%), **Field size** (0–10 — wraps that many extra rings of
  density-filled field around the words before squaring/border, scaling the composition up so the
  text floats in a larger field); Border checkbox; **Square canvas** checkbox (default on)
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
  (same rotate-about-centre math as export), snaps to 0.05, and union-finds segments whose endpoints
  coincide at points shared by exactly 2 segments (junctions >2 are left uncut; dots and
  circles/loops are excluded). Strands spanning **≥ 2 cells** get a **harmonious palette**: the
  **Hue slider** sets the base hue, strands take analogous hues (±35°) with seed-varied
  sat/lightness, ~10% complementary accents, bigger strands darker/stronger; **Recolour** reshuffles
  the variation while keeping the chosen hue;
  single-cell strands and dots stay ink — letter *bodies* remain readable, though letters' small
  edge arcs legitimately join field strands (they really do touch the boundary; 4–16 per letter).
  UI: **Colour strands** checkbox + **Recolour** (new seed). On screen colours are applied after
  every `render()` via inline `style.setProperty("stroke", …, "important")` (beats the injected
  `currentColor!important` rule); SVG/PNG exports get per-element inline styles via
  `colouredMarkup()`. GIF/WebM animation exports remain ink-only (per-key raster cache can't hold
  per-cell colours). Gotcha: `strandState`/`DRAWABLES` are declared with the document model because
  `render()` runs during control wire-up, before the engine block (TDZ otherwise).
- **Strand draw-on (trim path)** — `computeStrands()` also returns ordered **chains**: every group
  is a simple chain/cycle (fusion only at exactly-2 points), walked end-to-end recording per segment
  `{rev, len, offset}` (lengths cached in `tileGeometry`; dots len 0 pop in; circles trim around
  themselves). All 100% of segments belong to exactly one chain. **Draw** button + **Draw time**
  slider (2–20 s): seeded stagger, per-chain duration ∝ length, easeInOutCubic; per-frame the active
  segment gets the dash trick — `dasharray = len len`, `dashoffset = len−local` forward or
  `−(len−local)` when `rev` (draws from the segment's far end so the front flows continuously across
  tile boundaries). **Dots bloom/shrink**: a dot's visual size is its stroke-width, so the animator
  eases `stroke-width` 0↔full (inline `!important` override, removed at 100% so `var(--sw)` resumes);
  the WebM renderer scales the dot radius by the same progress. Stop/finish → `render()` restores
  clean state. **Export WebM** (in Strands)
  replays the same timeline on a canvas via cached per-key `Path2D`s + `setLineDash`/`lineDashOffset`
  (zero-length dots drawn as filled circles — canvas doesn't cap zero-length lines), recorded with
  a wall-clock `setInterval` (not rAF — keeps recording in background tabs). Future layers:
  hover-to-trace, fused single-path SVG export, GIF of the draw (needs colour quantizer).
- **Ambient gallery mode** — the **Ambient** button (Compose section) starts a fullscreen auto-play
  loop: compose a random poem (hue drifts +47° per cycle; `ambientFit` is a proper contain-fit —
  `size = min(W/cols, H/rows)` with viewport→screen fallbacks for hidden tabs — so the piece touches
  the window on one axis at zoom 100 and re-fits on resize/visibilitychange; with the
  **Ambient colours** checkbox on, each cycle also rolls a fresh paper/ink **colourway** tied to the
  cycle's hue via `ambientColourway()`/`hslToHex` — mostly tinted light paper with deep ink, ~35%
  inverted night cycles — restored on exit; the page backdrop (`#stageWrap` + `body`) is painted with the paper colour each
  cycle via `ambientBackdrop()` and the paper's shadow is dropped (`body.ambient #paper`), so
  fullscreen ambient is edge-to-edge immersive rather than a floating card — cleared on exit.
  In ambient/player the paper itself is `background:transparent !important` — the backdrop is
  the **single** colour surface (it fades 1.2 s between colourways; a painted paper would snap
  each cycle and visibly desync from the fade). Studio keeps the painted paper card;
  `computeStrands` lightens strand colours on dark paper,
  keyed off `params.bg` luminance, and `params.bg` is part of the strand cache signature), strand
  **draw-in** (9 s), **hold** (6 s), **undraw** (4 s, `runStrandAnim({reverse})` — the shared
  animator that also powers Draw/Stop), then the next poem, forever. Ambient forces strand colours
  on, hides the panel/hint/cursor via `body.ambient` CSS, and tolerates `requestFullscreen`
  rejection (runs in-page). **Any key, click, or leaving fullscreen exits**, restoring the user's
  exact prior composition, size, hue, and checkbox state from a snapshot.
- **Tile drift** — `Tile drift` checkbox (Compose): every 1.2 s a few random **pattern** tiles
  (2%, max 10; letters never move) quarter-turn clockwise via a `.slot svg` CSS transform
  transition, using cumulative degrees on `dataset.deg` so spins never reverse; the document state
  (`cell.rot`) is updated so exports/strands stay consistent, and with strand colours on the field
  re-fuses + recolours after each tick. Ticks skip while a draw/undraw/typewriter animation runs;
  a plain `render()` (any edit) resets to canonical transforms.
- **Public player mode** — the **default view** (no query param) after `loadFont()`: `startPlayer()`
  sets `ambient.player`, `body.player` (CSS hides the panel, shows `#playerBar`), forces the public
  recipe (border ON, square OFF, ambient colours ON) and runs `startAmbient({fullscreen:false})`.
  `?studio` boots the classic full app. In player mode clicks/keys do NOT exit the loop; keys:
  ←/→ prev/next, Space pause, F fullscreen. The bar (auto-hides after 3 s idle via `pokeBar`)
  has prev/pause/next, a **live stroke-width slider** (sets the `--sw` var directly on `#sheet`,
  no re-render, so animations survive), a **field-size slider** (`pPad2` — sets `poemOpts.pad`,
  re-lays the current piece at the new scale with the same poem+seed shown complete, parks in
  hold; synced with the studio's Field size slider), a **zoom slider** (`pZoom`, 100–400% — CSS
  `scale()` on `#paper`, instant, survives renders/cycles; `body.player #stageWrap` is
  `overflow:hidden` so the zoomed paper crops symmetrically), sound/drift proxies to the studio
  checkboxes, fullscreen,
  and a `?studio` link. **Prev/next**: `playerSkip(dir)` cancels the current phase, runs a 900 ms
  reverse dissolve, then `ambientCycle(replay?)` — `ambient.history` records each cycle's
  `{poemIdx, poemSeed, hue, ink, bg}` and prev replays the previous entry exactly. **Pause** parks
  on the held piece (`ambientArmHold` split out; the hold timer is cleared/re-armed).
- **Your words mode** — a personalised gallery reachable from the player bar ("your words") or
  `?words`. Three phases tracked in `words.phase` (`null | "typing" | "riff"`): **typing** — the
  ambient piece dissolves (900 ms reverse strand anim) to a clean sheet where the visitor types
  directly in the tile font (`typingFit()` sizes ~16 cols × `WORDS_MAX_LINES`+2 rows, 40–110 px;
  Space = blank gap, Enter = new line, Enter on an empty last line = **weave**; serif placard
  prompt `#wordsPrompt` shows while the sheet is empty; a hidden `#wordsKeys` input catches soft
  keyboards via `beforeinput`); **riff** — `composeWordsPiece()` converts the typed cells to
  `poemState.custom` and re-enters `ambientCycle()`, which in riff skips only the bank pick —
  same words, fresh seed/hue/colourway every cycle, forever (history entries carry `custom`, so
  prev/next replay riff variations exactly). Any writing key during the riff returns to a fresh
  sheet (carrying the letter in); Esc or the "gallery" button restores the bank loop. The mode
  trick: during typing `ambient.active=false` while `ambient.player` and the body classes stay
  on, which disarms all the loop timers/refits without touching `startAmbient`/`stopAmbient`.
  Weaving ≤3 letters temporarily floors `poemOpts.pad` at 2 (restored by `wordsRestorePad()`).
  Gotcha: `setPaused(false)` must run **before** cancelling `ambient.timer` — unpausing in
  "hold" re-arms the hold timer (this ordering is also fixed in `playerSkip`).
- **Hover a line** (player + studio, outside draw/undraw phases) — `computeStrands()` also returns
  `segIndex` ("r,c,ei" → chain) and `maxTotal`; a delegated `pointerover` on `#sheet` highlights the
  whole chain (its palette colour lifted +18 lightness, or a hue-based glow when colours are off)
  and, with sound on, plays `plingFreq(chain.total, maxTotal)` — one note per strand entry;
  `pointerleave`/drift-tick clear via `clearHover()`.
- **Sound** — `Sound` checkbox (Compose section), off by default; first tick lazily creates the
  `AudioContext` (gesture) and unticking suspends it (hard silence). Soft sine **plings** fire as
  strands complete during forward draws (pitch from `log(chain.total)` on a minor pentatonic across
  ~3 octaves from A2; gated to chains ≥ 0.75·PITCH and rate-limited to ~8/s), **typewriter clacks**
  (bandpass-filtered noise burst) on tile insertion, and a quiet detuned **drone** during ambient.
  All through one master gain (0.15). Note: `AudioContext.resume()` is async — `audioOn()` checks
  `state === "running"`, so sounds may skip the first instants after re-enabling.
- **Typewriter animation** — the composition reveals tile by tile (`revealOrder`: `typewriter`
  row-major, `letters first`, `patterns first`, or `random` — a seeded shuffle of every tile;
  speed slider = tiles/sec with per-tile jitter).
  **Play** veils tile slots (`.veiled`) and un-veils on a timer, moving the cursor square with the
  reveal front. **Export GIF** re-renders the reveal to an offscreen canvas — each tile is
  pre-rasterized at the **full 840 artboard** and drawn at `cell centre` (artboard centre =
  registration centre, so the 20-unit bleed overlaps neighbours exactly as on screen) — and encodes a
  looping GIF via an **inline GIF89a/LZW encoder** (no dependency; 32-colour ink→bg ramp palette,
  ≤120 frames, ~640px wide, long hold on the final frame). **Export WebM** records the same frame
  loop in real time via `canvas.captureStream` + `MediaRecorder` at higher resolution.

## How rendering works (the alignment decision)
Naively laying tiles flush by the 840 artboard puts adjacent path points **40 apart** (the 20
bleed on each side) — a visible misregistration. Instead:

- **On-screen:** each tile is rendered with `viewBox="20 20 800 800"` (constants `INSET=20`,
  `PITCH=800`) — the coordinate system is cropped to the registration grid, so adjacent tile
  boundaries fall exactly on the path points and neighbouring tiles' vectors coincide. `.slot svg`
  uses `overflow:visible` so edge dots render fully (they land on the neighbour's identical dot).
- **Export:** the same grid — overall `viewBox` has a small `INSET` margin, and each tile group is
  `translate(col*PITCH - INSET, row*PITCH - INSET)` with rotation about the tile centre `420`.

Because alignment is by the **path centreline**, it is **independent of stroke width** — changing the
Width control never shifts registration (only the visible line weight). The stroke also **scales with
the tile** (no `vector-effect:non-scaling-stroke`), matching the original font design.

## Hosting / deployment
The repo is `github.com/thomaspavitte-beep/tiletype`; `index.html` at the root is the site.
Two hosts deploy automatically on every push to `main`:

- **GitHub Pages (primary):** https://thomaspavitte-beep.github.io/tiletype/ — always the one to
  check. Builds occasionally lag after a push; kick one manually with
  `gh api -X POST repos/thomaspavitte-beep/tiletype/pages/builds`.
- **Netlify (secondary):** https://tile-type.netlify.app — already linked to the GitHub repo with
  auto-publishing from `main` (do not re-link). On the **Personal (paid) plan** since Jul 2026;
  every deploy costs Netlify credits (billing cycle starts the 30th). If the monthly credits ever
  run out, all deploys show "Skipped due to account credit usage exceeded" and the site silently
  freezes on the last published commit — manual "Trigger deploy" is ignored too until credits are
  added (auto recharge / add-on pack) or the cycle resets. If tile-type.netlify.app looks stale,
  check the deploys page for "Skipped" entries before debugging anything else.

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
- New tiles must follow the font's geometry (840 artboard, 20 registration inset) to stay aligned.
