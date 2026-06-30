# Scorekeeper — Roku SceneGraph Channel

A card-game scoreboard for Roku. Supports 1–8 players, remote-driven, with
per-round score history, two-column overflow layout, and a number-entry overlay
for direct score correction.

---

## Repackaging — ALWAYS use `comp`

```bash
comp
```

This shell alias zips the channel correctly. **Never use raw `zip` commands.**
The alias is defined in the user's shell config. If it's missing, check `~/.zshrc`.

---

## Architecture

```
HomeScene (extends Scene)
└── Scoreboard (extends Group)        — owns ALL game state + key handling
    ├── TeamPanel × N  (extends Group) — presentational only; N created dynamically
    ├── addPlayerBox   (static Group)  — show/hide; Scoreboard positions it
    └── NumberEntry    (extends Group) — presentational + own key handling while focused
```

**Separation of concerns — preserve this:**
- `Scoreboard.brs` is the single source of truth for all scores, player names,
  cursors, and focus. It pushes values down to children via public fields. It owns
  `onKeyEvent` for all d-pad navigation.
- `TeamPanel.brs` has no game logic. It only reacts to field changes and redraws
  itself. Don't add scoring rules here.
- `NumberEntry.brs` owns key handling only while it holds focus (set explicitly by
  `Scoreboard.brs`). It reports results back via `confirmedValue` / `cancelled`
  fields that Scoreboard observes.

TeamPanels are created dynamically in `setupPlayers(n)` via
`CreateObject("roSGNode", "TeamPanel")` — there are no static `<TeamPanel>` tags in
any XML file.

---

## Cursor system (Scoreboard.brs)

Each player has their own cursor index stored in `m.cursors[i]`:

| Value | Meaning |
|-------|---------|
| `-2` | Name row (default on game start; opens rename dialog on OK) |
| `-1` | No cursor shown (used when a panel does not have focus) |
| `0..count-1` | A specific round row |
| `count` | Append slot (the + button) |

`syncCursorDisplays()` writes `m.cursors[focusedIdx]` to the focused panel and
`-1` to all others. `syncDestCursor(sourceCursor)` mirrors a cursor value onto a
newly-focused player, clamping if their round count differs.

**Cursor navigation rules:**
- Down from name → round 0 (or append if no rounds)
- Down from last round → append slot (blocked at max rounds, see below)
- Up from round 0 → name
- Up from append → last round

---

## Two-column layout (TeamPanel.brs — `rebuildRounds`)

Triggered when `rounds.count() >= 10`.

**Split point** (`splitAt`): `max(10, ceil(N/2))` where N = rounds.count().
- Rounds 0 to splitAt-1 go in the left column.
- Rounds splitAt+ go in the right column.
- The append slot (or "Max rounds" notice) always appears at the bottom of the
  right column.

**Dynamic lineHeight** (shrinks once right column exceeds 10 rows):
```
leftSlots  = splitAt
rightSlots = rounds.count() - splitAt + 1   (rounds + append slot)
maxSlots   = max(leftSlots, rightSlots)
lineHeight = clamp(int(650 / maxSlots), 36, 60)
```
Font drops from `LargeBoldSystemFont` to `MediumBoldSystemFont` when
`lineHeight < 50`. Square size for the + button scales with lineHeight
(`int(lineHeight * 0.65)`, clamped 20–40).

**Available height for rounds:** 650px (roundsGroup y=102 to divider2 y=752).

---

## Max rounds cap (36)

- At 36 rounds the + append slot is replaced by a muted "Max rounds" label.
- The cursor is blocked from advancing past round 35 (`moveCursor` in Scoreboard.brs).
- `exitEditMode` and `syncDestCursor` clamp the cursor to `count-1` instead of
  `count` when `count >= 36`.
- 36 is chosen because `int(650/18) = 36px` exactly hits the lineHeight floor.

---

## Panel layout by player count (`computeLayout` in Scoreboard.brs)

| Players | contentLeft | contentWidth | minGap | Notes |
|---------|-------------|--------------|--------|-------|
| 1–2 | 160 | 1600 | — | fixed pw=420; 1-player centered, 2-player gap=500 |
| 3–4 | 160 | 1600 | 10 | |
| 5–6 | 80 | 1746 | 10 | leaves room for add-player button at right |
| 7 | 20 | 1806 | 5 | panels end at x≈1826, add button fits to right |
| 8 | 20 | 1880 | 5 | no add button (max players); uses nearly full width |

`panelWidth = (contentWidth - (n-1)*minGap) / n`, clamped 150–800px.
Panels are translated to `[panelStartX + i*(panelWidth+panelGap), 120]`.

---

## TeamPanel layout constants

All coordinates are on a 1920×1080 FHD canvas.

| Node | Position / Size |
|------|----------------|
| `focusRing` | width=panelWidth, height=820; gold `0xD4AF37FF` when focused |
| `nameLabel` | translation=[margin, 20], height=50 |
| `divider1` | translation=[margin, 76], height=2 |
| `roundsGroup` | translation=[margin, 102] — rounds rendered here |
| `divider2` | translation=[margin, 752], height=2 |
| `totalLabel` | translation=[margin, 760], height=56, `LargeBoldSystemFont` |

`margin` = `layoutMargin(panelWidth)`: pw≥400→40, pw≥250→20, else→10.
`cw` (content width) = `panelWidth - 2*margin`.
Divider2 and totalLabel always span full `cw` (even in two-column mode).

---

## Background

`images/background_fhd.png` — user-provided poker-table green background image.
Referenced from `HomeScene.xml` as a `<Poster>` node at 1920×1080.

A Python/Pillow generation script lives at:
`/private/tmp/claude-501/.../scratchpad/gen_bg.py`
(session-specific path — regenerate from scratch if lost; the approach is
documented in git history / prior conversation).

`BackgroundDeco.xml` / `BackgroundDeco.brs` still exist in the zip but are unused.
`HomeScene.xml` no longer references them.

---

## hintLabel

Defined in `Scoreboard.xml` at `translation="[360, 990]"`.
- Hidden (`visible=false`) in `init()` — not shown during the player-count dialog.
- Shown (`visible=true`) in `onPlayerCountChange()` once a player count is chosen.
- Text updates via `refreshHint()`: different text in edit mode vs. navigation mode.

---

## addPlayerBox

Static group defined in `Scoreboard.xml`. Shown/hidden via `visible`.
Positioned by `positionAddPlayerBox()`: `xPos = lastPanelX + panelWidth + 20`.
Highlighted gold when `focusedIdx == panels.count()`, grey otherwise.
Hidden automatically when player count reaches 8.

---

## Timers (repeat-hold for score adjustment)

Three timers in `Scoreboard.xml`, all observed in `Scoreboard.brs`:
- `repeatDelayTimer` (0.5s) — initial delay before repeat starts
- `repeatTimer` (0.15s) — repeat interval
- `repeatAccelTimer` (2.0s) — triggers ×10 step mode after hold

---

## Known gotchas

1. **`ui_resolutions=fhd` in manifest is mandatory.** All XML uses FHD coordinates
   (1920×1080). Setting it to `hd` silently scales everything against a 1280×720
   canvas — nodes go off-screen with no console error. Check this first if any node
   "isn't rendering."

2. **Don't redeclare built-in node fields in `<interface>`.** Aliasing `visible`
   collides with the built-in field and silently breaks visibility toggling. Use a
   distinct name for any custom alias.

3. **`onChange` only fires when the value actually changes.** If you set a field to
   the same value it already holds, the observer won't fire. Force a change via a
   sentinel value first if needed.

4. **macOS Sequoia "Local Network" privacy permission** gates per-app LAN access
   separately from router/firewall config. A blocked app gets `sendto: No route to
   host` at the network layer even when ARP and routing tables look fine. Check
   System Settings → Privacy & Security → Local Network if a specific app (e.g.
   VS Code's terminal) can't reach the Roku while other tools can.

5. **Poster URI must exactly match the filename in `images/`.** If a background
   image isn't showing with no error, verify the `uri="pkg:/images/..."` in
   `HomeScene.xml` matches the actual filename byte-for-byte.

---

## Roadmap / not yet built

- **Win detection / highlighting** — flag the player(s) with the highest total.
- **Score reset** — return all scores to zero without re-entering player count.
- **Persisting scores across restarts** — use `roRegistry`.
- **NumberEntry overlay** — the component exists but is currently wired as a
  direct-edit (up/down on a round); the full number-entry overlay flow may need
  revisiting.
