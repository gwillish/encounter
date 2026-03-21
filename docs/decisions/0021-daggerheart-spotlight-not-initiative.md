# ADR-0021: Daggerheart uses spotlight, not initiative order

**Status:** Accepted
**Date:** 2026-03-21

## Context

Many tabletop RPGs (D&D 5e, Pathfinder) use an initiative track: a numbered
sequence that determines exactly whose turn comes next. The original Encounter app
architecture included `turnOrder: [UUID]` and `advanceTurn()` on `EncounterSession`,
modelled on this assumption.

Daggerheart uses a different model entirely.

## Decision

Daggerheart uses a **spotlight** model, not initiative order:

- The GM spends Fear to take an adversary action. This is a GM resource decision,
  not a fixed sequence.
- After an adversary acts, the spotlight passes to the **players as a group** —
  any player can act, not a specific one.
- Players pass the spotlight back to the GM (or the GM spends Fear to interrupt).
- There is no numbered turn order. "Whose turn is it?" is always: GM or players.

The runner UI should reflect this binary spotlight (GM side / Player side), not
a sequential initiative track.

## Options Considered

- **Traditional turn order UI (rejected):** Misrepresents the game mechanics.
  Would confuse GMs familiar with Daggerheart and require tracking data the game
  doesn't use.
- **GM/Player spotlight toggle (correct model):** The runner needs to communicate
  whether it is currently the GM's action opportunity or the players'.

## Consequences

- `turnOrder: [UUID]` and `advanceTurn()` on `EncounterSession` reflect an
  incorrect assumption about the game. These should be reconsidered or removed
  when the runner UI is next revisited.
- The runner does not need a "Next Turn" button cycling through individual combatants.
- Fear pool management (ADR-0023) is the GM's primary action economy mechanism
  and should be prominently surfaced in the runner.
- The `currentRound` counter remains valid — rounds are a real concept in
  Daggerheart even without fixed turn order.
