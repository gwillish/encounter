# ADR-0026: Compendium three-tier content lookup

**Status:** Accepted
**Date:** 2026-03-21

## Context

The content architecture (ADR-0015) introduces community source packs alongside
the existing SRD bundle and homebrew entries. `Compendium` needs a lookup
strategy that lets source packs be added and removed independently, while
maintaining a clear priority order when multiple sources define an adversary
with the same ID.

## Decision

Add a **nested sources dictionary** as the middle tier:

```
homebrew → sources → srd
```

```swift
private var srdAdversariesByID:     [String: Adversary]            // keyed by slug
private var sourcesAdversariesByID: [String: [String: Adversary]]  // keyed by sourceID → slug
private var homebrewAdversariesByID:[String: Adversary]            // keyed by slug
```

The resolved `adversariesByID` computed property merges in order:
1. Start with the SRD dictionary.
2. Merge each source pack in turn (later packs win on collision).
3. Merge homebrew (always wins).

Source packs are managed via `replaceSourceContent(sourceID:adversaries:environments:)`
and `removeSourceContent(sourceID:)`.

## Options Considered

- **Option A — Flat sources dict, keyed by adversary slug (rejected):** A single
  `[String: Adversary]` merged from all packs is simpler to implement, but
  removing one pack requires rebuilding the entire merged dict from scratch.
  There is no record of which pack contributed each entry.
- **Option B — Nested dict keyed by sourceID, then slug (chosen):** Each pack
  is an independent sub-dictionary. Adding and removing packs is O(1) in the
  outer dict. The merge at read time is straightforward and the contribution of
  each entry is traceable.

## Consequences

- `adversariesByID` and `environmentsByID` are computed properties that merge
  on every access. For typical compendium sizes this is negligible; if profiling
  shows it is a hotspot, the merged result can be cached and invalidated on
  mutation.
- The same three-tier pattern applies symmetrically to environments.
- `Compendium` now has four internal dictionaries per content type (srd,
  sources-nested, homebrew) plus the computed merged view.
- Within the sources tier, pack conflict resolution is first-write-wins on
  iteration order. If deterministic priority across packs becomes necessary,
  `ContentSource` will need an explicit priority field.
