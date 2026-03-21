# ADR-0015: Writable directory for all persistent content

**Status:** Accepted
**Date:** 2026-03-21

## Context

The app bundles SRD JSON in its resources, but bundle resources are read-only at
runtime. GMs need to download SRD updates (to get corrections or new content
without waiting for an App Store release) and add community content packs. These
all require a writable storage location.

## Decision

All persistent content data lives in a writable app-specific directory under
`Application Support/Encounter/`:

```
Application Support/Encounter/
├── srd/
│   ├── adversaries.json       ← SRD content (seeded from bundle on first launch)
│   └── environments.json
├── sources/
│   ├── <uuid>.meta.json       ← source metadata: name, url, lastFetched, contentHash
│   ├── <uuid>-adversaries.json
│   └── <uuid>-environments.json
└── homebrew/
    ├── adversaries.json       ← user-created adversaries (future)
    └── environments.json
```

**First launch:** Bundle JSON is copied into `srd/`. Subsequent launches read
from the writable directory only. The bundle serves as the installation-time seed
and read-only fallback.

**Load priority** (highest wins on ID collision):
homebrew → sources → srd/ → bundled fallback

## Options Considered

- **Read from bundle always, write overrides alongside (rejected):** Requires
  complex merge logic to reconcile bundle vs. override files. Bundle updates via
  App Store would conflict with downloaded overrides.
- **On-demand resources (rejected):** Adds App Store submission complexity.
  Designed for large asset bundles, not frequently updated JSON text files.
- **Writable directory (chosen):** Simple mental model. GM has full control.
  Offline-capable. SRD errors can be corrected by URL download without waiting
  for an App Store update cycle.

## Consequences

- A new `ContentStore` service owns the writable directory and the source
  registry. `Compendium` remains the in-memory merged view and lookup service.
- `EncounterStore` (encounter definitions) uses a separate path
  (`Documents/Encounters/`) — not mixed with content data.
- Dates in source metadata (`lastFetched`) are stored as ISO8601 Zulu
  (see ADR-0013).
- See ADR-0016 for the `.dhpack` file format used to import content packs.
- See ADR-0017 for the URL fetch and CDN strategy.
