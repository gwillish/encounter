# ADR-0025: Adversary creator and difficulty meter — deferred to dedicated session

**Status:** Accepted
**Date:** 2026-03-21

## Context

GMs need to create custom adversaries for their campaigns. The adversary creation
flow requires power-level validation (does this adversary's stats fit the expected
range for its tier and type?) and a visual difficulty meter that integrates
validation feedback. These features are design-intensive and closely coupled.

## Decision

Both features are deferred to a single dedicated design-and-build session. They
are not in scope for the current iteration.

Draft design notes (to be refined in that session):

**Adversary creation flow (proposed):**
1. Identity step — name, type, tier; selecting these surfaces an "expected stat
   ranges" reference panel pulled from SRD adversaries of the same type/tier
2. Stats step — HP, Stress, Difficulty, Thresholds, Attack modifier; inline range
   indicators per field (colored bar or label: within range / above average /
   outlier); soft guidance only, not blocking
3. Attack & Features step — attack name, range, damage string; feature list
   (add action/reaction/passive with name and text)
4. Review — full stat card preview as it appears in Compendium; summary of any
   out-of-range stats

**Difficulty meter (proposed):**
- Horizontal gradient bar (green → yellow → orange → red) with a fill that moves
  based on total BP vs. budget
- Collapsed meter always visible at bottom of builder; tap to expand full
  breakdown showing per-adversary BP cost
- Integrated with adversary creation to validate new adversaries against
  tier expectations

**Power validation options (to decide in that session):**
- Inline range bars next to numeric fields (preferred)
- Summary warnings at review step
- "Similar adversaries" reference panel (2–3 SRD adversaries of the same type/tier)

**Open question:** Where do created adversaries live — auto to a "My Adversaries"
source, or prompt the GM to select a source?

## Consequences

- No adversary creation UI is built until the dedicated session.
- `DifficultyBudget` pure functions (ADR-0010) are already in place; the meter
  visual layer builds on top of them.
- The current `DifficultyAssessorView` color threshold design (ADR-0023) may
  be revised during the dedicated session based on how the meter and creator
  interact.
