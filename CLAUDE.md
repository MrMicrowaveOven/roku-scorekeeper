# Scorekeeper — Roku SceneGraph Channel

A simple two-team scoreboard app for Roku. Remote-driven, with an
on-screen number-entry overlay for direct score correction.

## Architecture

```
HomeScene (extends Scene)
└── Scoreboard (extends Group)        — owns ALL game state + key handling
    ├── TeamPanel "leftPanel"  (extends Group)  — presentational only
    ├── TeamPanel "rightPanel" (extends Group)  — presentational only
    └── NumberEntry (extends Group)             — presentational + own key handling while focused
```

**Separation of concerns is deliberate and should be preserved:**
- `Scoreboard.brs` is the single source of truth for `leftScore`, `rightScore`,
  and which team is focused. It pushes values down to children via public
  fields (`score`, `teamName`, `focused`). It owns `onKeyEvent` for d-pad
  navigation/increment/decrement and opens/closes the `NumberEntry` overlay.
- `TeamPanel.brs` has no game logic. It only reacts to field changes
  (`onScoreChange`, `onTeamNameChange`, `onFocusedChange`) and updates its own
  labels/focus ring. Don't add scoring rules here.
- `NumberEntry.brs` owns key handling **only** while it holds focus (set
  explicitly by `Scoreboard.brs` via `setFocus(true)` when opened). It
  reports results back via the `confirmedValue` / `cancelled` fields, which
  `Scoreboard.brs` observes.

Each `TeamPanel` instance is the same component, instantiated twice with
different `id`, `translation`, and `teamName` — write shared UI pieces once,
configure via fields/attributes, not by copy-pasting XML.

## Known gotchas (hard-won today, don't relearn these)

1. **`ui_resolutions` in the manifest must match the coordinate space the
   XML files are actually written for.** `hd` = 1280×720 design canvas,
   `fhd` = 1920×1080. All current component XML files use FHD coordinates
   (e.g. translations in the 1300–1900 range), so the manifest **must** say
   `ui_resolutions=fhd`. Setting it to `hd` doesn't crash anything and
   produces no console error — it just silently auto-scales every
   coordinate against the wrong canvas size, which can push nodes
   completely off-screen while making others look oversized. If a node
   "isn't rendering" with no error in the console, check this first.

2. **Don't redeclare a node's built-in fields in `<interface>`.** Every
   SceneGraph node already has fields like `visible`, `opacity`, etc.
   Redeclaring `visible` with an `alias` (as an earlier draft of
   `NumberEntry.xml` did) collides with the built-in field and silently
   breaks visibility toggling. If you need an alias, give it a distinct
   field name instead of overloading a built-in one.

3. **macOS Sequoia (15.x) "Local Network" privacy permission** gates
   per-app access to LAN devices, separately from any router/firewall
   config. A blocked app gets a misleading `sendto: No route to host`
   at the *network* layer — ARP, routing tables, and PF rules can all
   look completely valid while this permission is the actual cause.
   Check System Settings → Privacy & Security → Local Network if a
   specific app (e.g. VS Code's integrated terminal) can't reach a LAN
   device that other tools/devices reach fine.

## Conventions for future components

- New reusable UI pieces: presentational component (XML + BRS) with public
  `<interface>` fields, instantiated by whatever owns the state — follow the
  `TeamPanel` pattern.
- Centralize game rules/state in the parent that owns the screen (currently
  `Scoreboard.brs`), not in individual child components.
- Keep coordinates consistent with `ui_resolutions=fhd` (1920×1080 canvas).
- Icon/splash assets live in `images/` — `icon_focus_hd.png` (290×218) and
  `splash_fhd.png` (1920×1080), referenced from `manifest`.

## Roadmap / not yet built

- Multi-team support (currently hardcoded to exactly two `TeamPanel`
  instances — will likely need dynamic node creation via
  `CreateObject("roSGNode", "TeamPanel")` in a loop rather than static XML
  children, plus a way to cycle focus across N teams instead of just
  left/right).
- Win detection / highlighting.
- Score reset.
- Persisting scores across channel restarts (`roRegistry`).
