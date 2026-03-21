# ADR-0020: Naming, access control, and domain language conventions

**Status:** Accepted
**Date:** 2026-03-15

## Context

A consistent set of naming and access control conventions prevents drift across
a growing codebase and makes the code easier to read alongside the Daggerheart
SRD, which uses specific game terminology.

## Decision

**File naming:** One primary type per file; filename matches the type name.
Exception: `EncounterSession.swift` contains `AdversarySlot`, `EnvironmentSlot`,
and `PlayerSlot` as closely related supporting types.

**Access control:**
- `public` on all model types and their properties. This anticipates potential
  future extraction as a Swift Package.
- Views are `internal` (default). View types are not intended for external use.

**No force-unwrap:** Model and view code uses `guard let` or optional chaining.
Force-unwrap is never acceptable in non-test code.

**Domain language:** Use Daggerheart game terms as-is in code. Do not rename to
generic equivalents:
- `hp` not `health` or `hitPoints`
- `stress` not `exhaustion`
- `fear` / `hope` not `resource` or `currency`
- `difficulty` / `thresholds` not `armorClass` / `damageResistance`
- `evasion` not `defense`

## Options Considered

- **Generic naming (rejected):** `health`, `defense`, etc. are more familiar to
  developers from other game contexts, but create a translation layer between the
  SRD and the code. A GM reading the code alongside the rulebook should see the
  same terms in both places.
- **Daggerheart terms (chosen):** Zero translation overhead. The SRD is the
  source of truth; the code speaks the same language.

## Consequences

- `internal` access on views means the view layer is not a public API boundary.
  This is correct — views are implementation details.
- `public` model types allow tests in `EncounterTests` to access all properties
  directly without `@testable import`.
- Any deviation from these conventions (force-unwrap, UIKit import, generic
  naming) should be flagged in code review as a convention violation.
