# ADR-0037: Player level as prep-time data; party tier via median for difficulty matching

**Status:** Accepted
**Date:** 2026-04-05

## Context

The SRD encounter budget formula `(3 × playerCount) + 2` does not include player tier,
but tier enters the system in two ways:

1. **`lowerTierAdversary` adjustment (+1):** The SRD awards a budget bonus when you
   include an adversary from a lower tier than the party. This was previously a
   manual GM toggle with no automatic detection.
2. **Adversary stat benchmarks:** Each adversary has a tier (1–4) that describes its
   intended challenge level. The GM needs to see at a glance whether adversaries in
   the roster are appropriately matched to the party.

Neither of these is possible without knowing the party's level.

Level was also absent from `Player` and `PlayerConfig` in DHModels. Without it, the
app cannot derive party tier, cannot auto-detect the adjustment, and cannot highlight
mismatched adversaries.

A separate question is how `level` fits against ADR-0036 (player-owned state). That
ADR excludes character advancement from the GM app — but level for difficulty purposes
is distinct: it is static prep-time configuration (set once before the session), not
a value that changes during combat. It belongs in `Player` / `PlayerConfig` for the
same reason evasion and damage thresholds do — the GM needs it to set up a fair fight.

## Decision

### `Player` and `PlayerConfig`

Add `level: Int` (valid range 1–10, default `1`) to both types. The field must be
preserved through `Player.asConfig()`. Decoding is additive — missing `level` in
existing JSON defaults to `1` (Tier 1).

### Tier derivation (SRD mapping)

| Levels | Tier |
|--------|------|
| 1      | 1    |
| 2–4    | 2    |
| 5–7    | 3    |
| 8–10   | 4    |

A `DifficultyBudget.tier(forLevel:)` static function encodes this mapping.

### Party tier

Party tier is the tier corresponding to the **median character level**, with ties
resolved by **rounding the median up** before mapping to tier.

Examples:
- [1] → median 1 → T1
- [2, 3, 4, 5] → median 3.5 → ceil → 4 → T2
- [4, 5] → median 4.5 → ceil → 5 → T3
- [7, 8, 9] → median 8 → T4

Rationale for median: protects against a single low-level character dragging the whole
party's effective tier down, while not letting one high-level outlier over-represent
the group. Average would be skewed by outliers; min/max are too conservative/aggressive.

Rationale for rounding up: when the median straddles a tier boundary, the party has at
least as many characters in the higher tier as the lower. Rounding up gives slightly
more adversary budget latitude, which keeps encounters from feeling soft.

A `DifficultyBudget.partyTier(levels:)` static function encodes this logic.
Empty input returns `1` as a safe default.

### Auto-detection of `lowerTierAdversary`

`DifficultyBudget.suggestedAdjustments` gains optional `adversaryTiers: [Int]` and
`partyTier: Int?` parameters. When `partyTier` is non-nil and at least one adversary
has a known tier strictly less than `partyTier`, `.lowerTierAdversary` is inserted
into the auto-detected set.

`lowerTierAdversary` remains available as a manual GM toggle; auto-detection only
adds it when mechanically detectable.

### Adversary tier highlighting in the builder

Adversary roster rows display a tier badge and are tinted:
- **Below party tier** — amber tint
- **Above party tier** — red tint
- **Matching tier** — no decoration

Highlighting is informational only. No adversary is blocked, filtered, or requires
confirmation. A roster of many below-tier adversaries will still read as challenging
in the budget numbers.

## Options Considered

**Exclude level from the GM app entirely (rejected):** Without level, `lowerTierAdversary`
cannot be auto-detected and the builder cannot give tier-matching guidance. The manual
toggle provides no feedback about whether it is appropriate to use.

**Capture level as a runtime value in `PlayerSlot` (rejected):** Level does not change
during a session. It is setup data, not live combat state. Placing it in `PlayerSlot`
would co-locate a prep value with mutable session tracking state, violating the
catalog/runtime split (ADR-0003). It belongs in `Player` and `PlayerConfig`.

**Use average instead of median for party tier (rejected):** A single high-level character
pulling the average up would over-represent their tier. Median is more robust to outliers.

**Round down on median boundary (rejected):** Rounding down when the median sits exactly
between tiers would treat a party with equal representation in two tiers as the lower one,
making encounters feel easier than expected. Rounding up is the safer choice.

**Show tier range instead of a single value for mixed parties (rejected):** A range (e.g.
"T2–T3") makes the auto-detection rule for `lowerTierAdversary` ambiguous and adds
UI complexity for an edge case. A single derived value with a documented rounding rule
is simpler and deterministic.

## Consequences

- `Player` and `PlayerConfig` gain a `level` field; `AddPlayerForm` and `PlayerForm`
  gain a level input (1–10).
- `DifficultyBudget` gains `tier(forLevel:)` and `partyTier(levels:)` static functions.
- `DifficultyAssessorView` reads player levels from `playerConfigs` and passes party
  tier to `suggestedAdjustments`; `lowerTierAdversary` moves from purely manual to
  auto-detectable.
- `AdversaryRosterRow` gains tier badges and tinting in the builder.
- The `lowerTierAdversary` toggle remains available; auto-detection never overrides a
  GM who has manually set it.
- Level is explicitly not a live session value — it is not exposed in the runner's
  player strip popover and does not appear in `PlayerSlot`.
