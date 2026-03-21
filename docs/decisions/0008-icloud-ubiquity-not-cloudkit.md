# ADR-0008: iCloud sync via ubiquity container, not CloudKit

**Status:** Accepted
**Date:** 2026-03-15

## Context

Encounter definitions should sync between a GM's iPhone and Mac. Apple provides
two sync mechanisms: iCloud Drive (ubiquity containers) and CloudKit (record API).

## Decision

Use iCloud Drive via `FileManager.default.url(forUbiquityContainerIdentifier:)`.
Encounter files are stored in the ubiquity container's `Documents/Encounters/`
directory. When iCloud is unavailable the store falls back to
`applicationSupport` with no change to the consumer API.

The directory is resolved asynchronously at startup. `EncounterStore` exposes
a `relocate(to:)` method so the app can switch from local to iCloud storage
after the async check completes.

## Options Considered

- **iCloud Drive / ubiquity container (chosen):** Files sync automatically
  with no backend implementation. GMs can access encounter files in the Files
  app. Human-readable JSON is inspectable and shareable outside the app.
- **CloudKit record API (rejected for v1):** More flexible conflict resolution
  and real-time sync, but requires a CloudKit container setup, schema definition,
  authentication handling, and record-level conflict logic. Significant backend
  work not justified for v1.
- **No sync (rejected):** GM would need to manually transfer files between
  devices. Unacceptable for a table tool.

## Consequences

- iCloud Documents entitlement (`com.apple.developer.ubiquity-container-identifiers`)
  must be present in the provisioning profile for sync to work.
- During local development without a signing identity, the store falls back to
  `applicationSupport` — see ADR-0007.
- CloudKit can be substituted later without changing the consumer API since
  `EncounterStore` abstracts the directory location.
- File conflicts (two devices editing the same encounter simultaneously) are
  handled by iCloud's last-write-wins semantics. No merge UI needed for v1.
