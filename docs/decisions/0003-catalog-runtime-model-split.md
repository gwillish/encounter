# ADR-0003: Catalog vs. runtime model split

**Status:** Accepted
**Date:** 2026-03-15

## Context

Daggerheart data has two fundamentally different lifecycle concerns: static
reference data (adversary and environment definitions from the SRD) and mutable
in-session state (current HP, conditions, turn tracking). Conflating these makes
mutations harder to reason about and complicates future persistence decisions.

## Decision

Split the data layer into two distinct concerns:

**Catalog models** (`Adversary`, `DaggerheartEnvironment`) — immutable value types
loaded from JSON. These are static SRD/homebrew definitions that do not change
during a session.

**Runtime models** (`EncounterSession`, `AdversarySlot`, `EnvironmentSlot`,
`PlayerSlot`) — mutable state for a live encounter being run at the table.

`Compendium` bridges the two: it loads catalog data and provides lookups so the
session can resolve `adversaryID` slugs to full `Adversary` structs when needed.
`EncounterDefinition` is the saved representation of encounter prep that is
converted to a live `EncounterSession` at play time via
`EncounterSession.start(from:using:)`.

## Options Considered

- **Single unified model (rejected):** One `Adversary` type carries both static
  fields and mutable HP/stress state. Simple initially but creates mutation hazards
  when the same catalog entry is used across multiple session slots.
- **Catalog/runtime split (chosen):** Clean separation of concerns. Catalog data
  can be shared safely across sessions. Runtime state is owned by the session and
  isolated to it.

## Consequences

- `AdversarySlot` and `PlayerSlot` snapshot the catalog stats they need (`maxHP`,
  `maxStress`) at creation time so the session remains self-contained even if the
  source catalog entry is later edited or removed (homebrew orphan safety —
  see ADR-0011).
- `EncounterSession` is the single mutable owner of all runtime state.
- `Compendium` is a read-only lookup service during a running session.
- "Reset encounter" means clearing the session while keeping the definition.
