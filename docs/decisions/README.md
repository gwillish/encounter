# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the Encounter
project. Each file captures one significant decision: the context that made it
necessary, what was decided, the alternatives considered, and the consequences.

## File naming

```
NNNN-short-title.md
```

Numbers are zero-padded to four digits and assigned sequentially. The title is a
short lowercase slug describing the decision.

## Statuses

| Status | Meaning |
|---|---|
| **Proposed** | Under active exploration; not yet settled |
| **Accepted** | Decided and currently in effect |
| **Rejected** | Explored but not implemented; findings recorded to prevent re-exploring the same dead end |
| **Deprecated** | No longer applies; no direct replacement |
| **Superseded by [ADR-NNNN](NNNN-title.md)** | A later decision replaced this one |

## Branch explorations

An ADR on a feature branch may start as `Proposed` while the approach is being
explored. When the branch concludes:

- **Branch merges:** update the ADR status to `Accepted` (or `Rejected` if the
  exploration ruled something out).
- **Branch is discarded, findings matter:** cherry-pick just the ADR file to
  `main` with status `Rejected` and a brief findings section before deleting the
  branch. The dead end is now documented so no one re-explores it.
- **Branch is discarded, nothing worth preserving:** don't bring the ADR to
  `main`. Small or fast explorations don't need a permanent record.

## Template

```markdown
# ADR-NNNN: Title

**Status:** Accepted
**Date:** YYYY-MM-DD

## Context

Why this decision was needed. What problem or constraint prompted it.

## Decision

What was decided, stated plainly.

## Options Considered

- **Option A (chosen):** description — chosen because ...
- **Option B:** description — rejected because ...

## Consequences

What this decision means going forward. Trade-offs accepted. Things that become
easier or harder as a result.
```

## Superseded / Mistake Process

**Never edit or delete an existing ADR.** If a decision was wrong, incomplete,
or needs to change direction:

1. Write a **new ADR** with the next available number. Open its Context section
   with: _"This supersedes [ADR-NNNN](NNNN-title.md)."_ Explain what changed,
   why the original decision was wrong or no longer applies, and what the new
   direction is.

2. Update the **original ADR's status line only** to:
   `Superseded by [ADR-NNNN](NNNN-title.md)`

3. Leave the original ADR's content completely intact below the status line.

The result is a navigable chain: reading the original shows the first reasoning;
the status line points to the correction; reading the new ADR explains why the
change was made. Future agents and developers can follow the full arc of any
decision without guesswork.

## When to write an ADR

Write one when:

- Choosing between meaningfully different architectural approaches
- Establishing a project-wide convention (naming, data formats, date handling)
- Making a UX or product decision that constrains future work
- Deciding explicitly *not* to do something that might otherwise seem obvious

Do not write one for routine implementation details that can be changed without
downstream impact.
