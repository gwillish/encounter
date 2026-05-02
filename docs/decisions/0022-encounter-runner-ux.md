# ADR-0022: Encounter runner UX — accordion cards, player strip, fear tracker

**Status:** Superseded by [ADR-0042](0042-player-runner-section.md)
**Date:** 2026-03-17

## Context

The live encounter runner needs to surface a lot of information (multiple
adversaries with HP/stress/conditions, all players, the Fear pool) while keeping
the GM's hands free for the table. The layout must prioritize the most common
mid-combat actions.

## Decision

**Adversary cards — accordion expansion:**
Only one adversary card is expanded at a time. The collapsed state shows the
adversary name and a HP pip track. Expanding reveals damage threshold buttons
(Minor / Major / Severe → 1/2/3 HP removed), a +Stress button, condition toggles
(Hidden, Restrained, Vulnerable), and a stat reference section. Defeated adversaries
sort to the bottom at 40% opacity — still visible for reference, not in the way.

Damage is applied via threshold buttons rather than a numeric entry field.
The GM picks the threshold based on the roll result; the app applies the correct
mark count. Numeric damage input is deferred to a future iteration.

**Player strip — always visible:**
Pinned to the bottom of the screen via `.safeAreaInset(edge: .bottom)`. Shows all
players simultaneously — name, HP pips, stress pips, armor slots remaining. Tapping
a player row opens a popover with stepper controls for HP, Stress, and Armor.

The strip is always visible regardless of which adversary card is open. GMs need
to update player state at any moment, not only when a player's "turn" is active
(Daggerheart has no individual player turns — see ADR-0021).

**Fear tracker — nav bar popover:**
A persistent flame icon + count in the trailing navigation bar position. Tapping
opens a compact popover with one-tap spend amounts (+1, −1, −2, −3 Fear). Always
accessible at zero scroll cost.

## Options Considered

- **Inline +/− controls per player in the strip (rejected):** Too narrow for
  three stats (HP, Stress, Armor). A popover accommodates all three without
  crowding.
- **Dedicated Fear screen (rejected):** Full screen for a single counter is
  wasteful. A popover from the persistent nav bar button is sufficient.
- **All adversary cards expanded simultaneously (rejected):** Too much information
  at once. The accordion keeps focus on the active adversary.

## Consequences

- `PipTrack` is a reusable component used for HP, Stress, and Armor pips
  throughout the runner. Falls back to a text counter above 10 pips.
- The accordion state (which card is expanded) is local view state, not session
  state — it resets if the GM navigates away.
- The player popover stepper pattern should be consistent for any future
  player-tracking additions (conditions, Hope, etc.).
