# ADR-0036: Player-owned state boundary — Hope excluded, GM-applied conditions included

**Status:** Accepted
**Date:** 2026-03-22

## Context

The encounter runner needs to track some player-facing state so the GM can
manage combat effectively. But the app is a GM tool, not a character sheet.
We needed a clear rule for which player state belongs in this app and which
belongs to the player (and eventually a future player-side app).

The two concrete decisions that forced this question:
1. **Hope** — GMs grant Hope to players; players track their balance and spend it.
2. **Conditions** — GMs apply conditions (Restrained, Vulnerable, Hidden) to
   players; the GM needs to see and manage them during combat.

## Decision

The GM app tracks state the GM **controls and applies**. It does not replicate
state that belongs to the player.

**Included in `PlayerSlot`:**
- `currentHP` / `maxHP` — GM applies damage; needs to track it
- `currentStress` / `maxStress` — GM applies stress; needs to track it
- `currentArmorSlots` / `armorSlots` — GM tracks armor consumption
- `conditions: Set<Condition>` — GM applies conditions (Restrained, Vulnerable,
  Hidden); must see and toggle them mid-combat
- `evasion`, `thresholdMajor`, `thresholdSevere` — reference values the GM
  needs when resolving attacks against players

**Excluded from `PlayerSlot`:**
- **Hope** — the GM grants Hope, but the *player* tracks their balance and decides
  when to spend it. Hope management is a player-side responsibility. Including it
  here would pull in player-sheet territory without providing meaningful GM value.
- Character advancement, class features, ancestry traits — out of scope for the
  encounter lifecycle entirely.

**Architecture consideration:** The model must leave the door open for a future
player-side app to share Hope (and other player state) bidirectionally via a sync
layer. `PlayerSlot` should not have fields that would conflict with that future
sync design.

## Options Considered

**Track all player state in the GM app** — complete information at the GM's
fingertips, but couples the app to full character sheet data. Scope creep; out
of scope per Principle 2 (the encounter is the unit of work).

**Track Hope in the GM app** — some GMs want visibility into player Hope pools
to pace Fear generation and encounter difficulty. However, Hope spend decisions
belong to the player; making the GM the authoritative tracker creates confusion
about who owns the value. Deferred pending playtesting to determine if GM
visibility is actually needed at the table.

**Exclude all player tracking** — the runner can't function without HP, stress,
and armor. GMs need enough player state to resolve incoming attacks and apply
damage correctly.

**GM-controlled state only (chosen)** — clean boundary: the GM app owns what
the GM does at the table. Player-decision state (Hope, resource spends) stays
with the player.

## Consequences

- `PlayerSlot` has no Hope field. This is intentional and should not be added
  without revisiting this ADR.
- The player popover in the runner exposes HP, Stress, Armor Slots, and
  Conditions — not Hope or any other player-sheet data.
- Hope tracking may be reconsidered after playtesting reveals whether GMs
  genuinely need GM-side visibility into player Hope balances.
- A future player companion app that tracks Hope must be designed with a sync
  interface that does not conflict with the existing `PlayerSlot` model.
- The `Condition` type (Hidden, Restrained, Vulnerable, custom) is shared
  between `AdversarySlot` and `PlayerSlot` — conditions are always GM-applied
  in the runner.
