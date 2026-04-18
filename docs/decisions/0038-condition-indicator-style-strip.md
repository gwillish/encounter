# ADR-0038 — Condition Indicator Style in Player Strip Row

**Status:** Accepted

## Context

The player strip row (`PlayerStripRow`) needs to surface active conditions at a glance
during a live encounter. Three options were considered:

1. **SF Symbol icons** — per-condition icons (e.g. `eye.slash` for Hidden). Compact but
   requires icon-to-meaning mapping that isn't obvious mid-game.
2. **Filled dots, always shown** — three fixed dot slots, grayed when inactive. Makes the
   presence of three condition slots visible at all times.
3. **Filled dot + text label, active only** — a small dot paired with the condition name,
   rendered only when the condition is applied. Nothing shown when no conditions are active.

The strip row is already dense (name, HP pip track, stress pip track, armor count). Adding
three always-visible dots would consume horizontal space even when no conditions are active,
which is the common case.

SF Symbol icons are not chosen because their meaning is not immediately legible without
prior learning, and consistency with the popover toggle labels (which use text) matters
more than icon compactness at this size.

## Decision

Active conditions in the player strip row are shown as a **filled dot + text label**,
rendered **only when the condition is applied**. When no conditions are active, no
indicator appears and no space is reserved.

The same convention applies to any future strip-style compact row (e.g. adversary compact
view, if one is added).

## Consequences

- Strip rows are visually clean when no conditions are active (the common case).
- At most three small pill-style indicators appear; unlikely to overflow at typical name
  lengths with 2–6 players.
- Future custom conditions follow the same dot + label pattern automatically.
- Contrast: the popover toggle buttons use full bordered button style with orange tint —
  the dot + label is intentionally lighter, read-only at a glance.
