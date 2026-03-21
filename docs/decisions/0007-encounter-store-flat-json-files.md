# ADR-0007: EncounterStore — flat directory of JSON files

**Status:** Accepted
**Date:** 2026-03-15

## Context

`EncounterDefinition` is the saved representation of encounter prep. It needs
to persist across app launches and, eventually, sync between devices. A
persistence strategy is needed.

## Decision

Each `EncounterDefinition` is stored as an individual JSON file named
`<UUID>.encounter.json` in a flat directory managed by `EncounterStore`.

The directory resolves at startup:
1. Check for iCloud ubiquity container availability (async).
2. If available: `<ubiquityContainer>/Documents/Encounters/`
3. If not: `<applicationSupport>/Encounters/`

`EncounterStore` exposes `create`, `save`, `delete`, and `duplicate` operations.
All mutating operations update both the in-memory `definitions` array and the
on-disk file atomically. Definitions are kept sorted by `modifiedAt` descending.

## Options Considered

- **Single JSON file with all encounters (rejected):** Simple reads but full
  rewrite on every save. Grows unbounded. Concurrent writes (future) would
  require locking.
- **SQLite / Core Data (rejected):** Heavy for what is structured JSON. Adds
  framework dependency. Harder to inspect/debug.
- **Flat JSON files per encounter (chosen):** Each file is self-contained,
  independently writable, and human-readable. iCloud Drive syncs individual
  files. No schema migrations needed for adding fields (Codable
  `decodeIfPresent` handles missing keys).
- **CloudKit records (rejected for v1):** More powerful but requires a
  CloudKit container, authentication, and conflict resolution logic.
  The ubiquity container approach gives file sync for free with no backend.

## Consequences

- File naming: `<UUID>.encounter.json`. The `.encounter` infix is the
  discriminator — `EncounterStore.load()` ignores files without it.
- `JSONEncoder` and `JSONDecoder` are created per-call (Swift 6 Sendability;
  encoders are not safely retained across actor boundaries).
- Dates are stored as ISO8601 Zulu strings (see ADR-0013).
- iCloud entitlements must be added before App Store submission. During
  development they may be disabled; the store falls back to
  `applicationSupport` gracefully.
- See ADR-0008 for the iCloud strategy.
