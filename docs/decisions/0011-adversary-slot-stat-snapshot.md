# ADR-0011: AdversarySlot snapshots maxHP and maxStress at creation

**Status:** Accepted
**Date:** 2026-03-15

## Context

When a GM adds an adversary to a session, the slot needs to clamp HP and stress
to the adversary's maximum values. The question is whether to look up those
maximums from the `Compendium` at mutation time, or snapshot them when the slot
is created.

Early implementations of `applyStress` and `heal` required a `Compendium`
parameter so they could look up the catalog maximum on each call.

## Decision

`AdversarySlot` snapshots `maxHP` and `maxStress` from the catalog `Adversary`
at slot creation time. These are stored as `let` properties. Mutation methods
(`applyStress`, `heal`) use the snapshot values — no `Compendium` parameter.

```swift
public let maxHP: Int
public let maxStress: Int
```

The factory `AdversarySlot.from(_:customName:)` reads these from the `Adversary`
struct at the moment the slot is added to the session.

## Options Considered

- **Look up from Compendium at mutation time (rejected):** Required passing
  `Compendium` as a parameter to every mutation method. Complicates call sites.
  Silently produces wrong results if a homebrew adversary is removed mid-session
  (orphan returns `nil`, lookup falls back to `Int.max`).
- **Snapshot at creation (chosen):** Slot is self-contained. Mutations are
  simple and testable without a Compendium. Correct behavior is preserved even
  if the source adversary is edited or deleted after the session starts.

## Consequences

- HP and stress clamping works correctly even for orphaned homebrew slots.
- `AdversarySlot` can be mutated without injecting `Compendium` into every
  call site.
- If a GM edits an adversary's max HP mid-session, existing slots retain the
  original value. This is intentional — sessions are snapshots of the build
  state at start time.
- `PlayerSlot` follows the same pattern: `maxHP`, `maxStress`, and `armorSlots`
  are all snapshotted from `PlayerConfig` at session creation.
