# ADR-0023: Difficulty budget color thresholds and adjustment model

**Status:** Accepted
**Date:** 2026-03-16

## Context

The SRD's Battle Points system provides a numerical budget for sizing encounters.
The `DifficultyAssessorView` needs to communicate how the current roster sits
relative to that budget in a way that is immediately readable at a glance.

## Decision

**Color thresholds** (remaining BP after cost vs. budget):

| Remaining BP | Color | Label |
|---|---|---|
| ≥ 4 | Teal | Too Easy |
| 1–3 | Green | Well Matched |
| 0 | Green | Exactly on Budget |
| −1 to −3 | Amber | Challenging |
| −4 to −6 | Red | Dangerous |
| ≤ −7 | Pulsing red | Likely TPK |

**Adjustment model:**

Auto-detected (read-only labels, based on roster composition):
- `multipleSolos` (2+ Solo types) → −2 BP (SRD rule)
- `noBigThreats` (no Bruiser/Horde/Leader/Solo) → +2 BP (SRD rule)

GM-discretionary toggles (4 options the GM enables manually):
- `easierFight` → −1 BP
- `harderFight` → +2 BP
- `boostedDamage` → −2 BP
- `lowerTierAdversary` → +1 BP

The assessor is always visible at the bottom of the builder via `.safeAreaInset`.

## Options Considered

- **Binary safe/unsafe indicator (rejected):** Too coarse. GMs often intentionally
  build challenging or easy encounters. A gradient gives nuance.
- **Numeric only, no color (rejected):** Numbers alone require the GM to know the
  thresholds mentally. Color communicates the assessment at a glance.
- **Pulsing animation at all danger levels (rejected):** Alarm fatigue. Reserve
  animation for the most severe case (likely TPK) only.

## Consequences

- Small overspend (−1 to −3) is amber, not red — intentional challenge design
  should not feel like an error.
- Large overspend (≤ −7) uses animation to flag genuine danger without the GM
  having to read numbers.
- The difficulty meter and assessor design are deferred to the adversary creation
  session (see ADR-0025) for refinement. Current thresholds may be adjusted
  based on playtesting feedback.
