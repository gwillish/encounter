# ADR-0031: Adversary `source` field normalized to lowercase

**Status:** Accepted
**Date:** 2026-03-21

## Context

`Adversary.source` is a string tag identifying where an adversary originated
(ADR-0014). External JSON from the seansbox/daggerheart-srd format uses `"SRD"`,
some homebrew tools use `"Homebrew"` or `"homebrew"`, and future community packs
may use arbitrary strings. Inconsistent casing makes source comparisons fragile
and produces duplicates in any UI that groups by source.

During implementation the code was found to use `"SRD"` (uppercase) as the
default while ADR-0014 specified `"srd"` (lowercase) — a latent inconsistency.

## Decision

**Always store `source` in lowercase.** At decode time, the raw JSON value is
lowercased before assignment:

```swift
source = (try c.decodeIfPresent(String.self, forKey: .source) ?? "srd").lowercased()
```

The memberwise `init` default is `"srd"`. All internal comparisons use
lowercase strings.

External JSON may arrive in any case (`"SRD"`, `"Homebrew"`, `"Community Pack"`);
the decoder normalizes on import.

## Options Considered

- **Case-insensitive comparison at every callsite (rejected):** Every filter,
  group, or equality check would need `caseInsensitiveCompare`. Easy to miss,
  and the raw stored value remains inconsistent.
- **Normalize to uppercase (rejected):** No convention advantage over lowercase;
  lowercase is more idiomatic for slug-style identifiers.
- **Normalize to lowercase at decode time (chosen):** Single enforcement point.
  Stored values are always consistent. Comparisons use plain `==`.

## Consequences

- Any existing persisted `Adversary` values with uppercase `source` will be
  re-normalized the next time they pass through the decoder (e.g. after a
  content refresh or re-import). No migration is needed for in-memory or
  freshly decoded values.
- `"srd"` is the canonical source tag for SRD content. `"homebrew"` for
  user-created content. Community source pack IDs (ADR-0026) are already
  lowercase slugs and pass through unchanged.
- Tests that assert on `source` must use lowercase strings.
