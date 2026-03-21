# ADR-0030: DHPackContent dual-format decoding

**Status:** Accepted
**Date:** 2026-03-21

## Context

`.dhpack` files are JSON content packs in the seansbox/daggerheart-srd format
(ADR-0024). Two JSON structures appear in the wild:

1. **Keyed object** — a pack wrapper with named arrays:
   ```json
   { "adversaries": […], "environments": […] }
   ```
   This is the purpose-built pack format, allowing a single file to carry
   both adversaries and environments.

2. **Bare array** — a direct seansbox export:
   ```json
   [ { "id": "…", … }, … ]
   ```
   GMs may generate these directly from the seansbox build pipeline and
   rename them `.dhpack` for import.

## Decision

`DHPackContent` tries the **keyed object format first**; if that fails it
treats the root as a **bare adversary array** with no environments:

```swift
init(from decoder: Decoder) throws {
    if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
        adversaries  = (try? keyed.decode([Adversary].self, forKey: .adversaries))  ?? []
        environments = (try? keyed.decode([DaggerheartEnvironment].self, forKey: .environments)) ?? []
    } else {
        adversaries  = try decoder.singleValueContainer().decode([Adversary].self)
        environments = []
    }
}
```

Absent keys in the keyed format decode as empty arrays rather than throwing,
so a pack containing only adversaries or only environments is accepted.

## Options Considered

- **Keyed format only (rejected):** Rejects bare seansbox exports. GMs would
  need to wrap their exports in a `{"adversaries":[…]}` object before import —
  unnecessary friction.
- **Bare array only (rejected):** Cannot carry environments in a single file
  without a wrapper.
- **Dual-format with keyed-first fallback (chosen):** Accepts both without
  requiring the GM to know which format they have. The keyed format is tried
  first because it is the more specific structure.

## Consequences

- Any valid seansbox adversary JSON array can be imported as a `.dhpack` directly.
- Packs that contain only environments must use the keyed format; bare
  environment arrays are not supported (environments-only packs are uncommon).
- `DHPackContent` is `nonisolated` so it is decodable from `ContentFetcher`'s
  `nonisolated` decode method under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
