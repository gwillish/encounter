# ADR-0014: Adversary identity — slug ID with source field

**Status:** Accepted
**Date:** 2026-03-21

## Context

Adversaries from the SRD, from downloaded community packs, and from user-created
homebrew all need to coexist in the `Compendium`. The question is how to identify
them uniquely and how to handle cases where a homebrew entry intentionally replaces
an SRD entry with the same conceptual identity.

Three options were considered:

- **A:** Keep bare slug `id`, add a `source: String` field
- **B:** Composite key `(source, id)` — no implicit shadowing
- **C:** Keep bare slug, add explicit `overrides: String?` field

## Decision

**Option A:** The `id` field remains a bare slug string (e.g., `"ironguard-bandit"`)
for upstream JSON compatibility with the seansbox/daggerheart-srd format. A
`source: String` field is added to every `Adversary` to identify its origin.

Well-known source values:
- `"srd"` — bundled SRD content (default when decoding JSON without this field)
- `"homebrew"` — user-created adversaries
- A URL slug or UUID string for downloaded content packs

`Compendium` maintains separate `srdAdversariesByID` and
`homebrewAdversariesByID` dictionaries. The merged `adversariesByID` computed
property applies homebrew entries over SRD entries when IDs collide. When a
collision occurs it is treated as an **explicit override** and surfaced to the GM
(warning on creation, visible badge or label in the UI).

## Options Considered

- **Option A — source field (chosen):** Backward-compatible with upstream JSON
  (decoded as optional with default `"srd"`). Enables source-based filtering.
  Override semantics are implicit (same slug) but surfaced explicitly in the UI.
- **Option B — composite key (rejected):** More precise but breaks compatibility
  with existing JSON format and all encounter definitions that store adversary IDs.
  Adds lookup complexity everywhere.
- **Option C — `overrides` field (deferred):** Useful when GMs create modified
  versions of SRD creatures, but most valuable in the adversary creation flow.
  Can be added later without breaking existing data.

## Consequences

- `source` decodes as optional with default `"srd"` — all existing JSON is
  compatible without modification.
- When a non-SRD adversary shares an `id` with an SRD entry, the compendium
  treats it as an override and can expose `overriddenSRDEntries` for UI warnings.
- Compendium filtering by source is architecturally supported; the UI can expose
  it without data model changes.
- The `overrides` field from Option C remains available as a future addition for
  the adversary creation flow.
