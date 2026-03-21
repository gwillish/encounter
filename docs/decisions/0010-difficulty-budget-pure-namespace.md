# ADR-0010: DifficultyBudget as a pure static namespace

**Status:** Accepted
**Date:** 2026-03-15

## Context

The SRD defines a Battle Points (BP) system for sizing encounters. This logic
needs to live somewhere in the app. The question is whether it belongs as methods
on a model type, a service object, or a standalone namespace.

## Decision

`DifficultyBudget` is a `public enum` with no cases — a pure static namespace.
All functions are `static`. It holds no state and takes no dependencies.

Key functions:
- `cost(for adversaryType:)` — BP cost per adversary type
- `baseBudget(playerCount:)` — formula: `(3 × playerCount) + 2`
- `totalCost(for adversaryTypes:)` — sum of costs for a roster
- `rating(adversaryTypes:playerCount:budgetAdjustment:)` — returns a `Rating`
  struct with remaining BP and suggested adjustments

Adjustments are expressed as an `Adjustment` enum with associated point values.
Auto-detected adjustments (`multipleSolos`, `noBigThreats`) are separated from
GM-discretionary toggles (`easierFight`, `harderFight`, `boostedDamage`,
`lowerTierAdversary`).

## Options Considered

- **Methods on `EncounterDefinition` (rejected):** Adds budget logic to a type
  whose purpose is serializable prep state. Harder to test in isolation.
- **Methods on `Compendium` (rejected):** Budget calculation has no dependency on
  catalog data. Wrong abstraction.
- **Pure static namespace (chosen):** No state, no dependencies, fully testable
  as pure functions. Can be called from any context including tests without
  setting up an environment.

## Consequences

- `DifficultyBudget` functions can be called directly in tests without mocking.
- The `DifficultyAssessorView` calls these functions directly, passing the
  adversary type array from the current builder state.
- Difficulty meter and adversary creation validation (future) will call the same
  functions — no duplication needed.
