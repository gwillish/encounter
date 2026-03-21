# ADR-0032: SRD seeding via bundle version stamp

**Status:** Accepted
**Date:** 2026-03-21

## Context

The content architecture (ADR-0015) uses a writable Application Support
directory as the live content store, seeded from the app bundle on first
launch. This gives `ContentFetcher` a stable on-disk location to read from
and allows the SRD to be updated independently of the app (via source fetch),
while the bundle remains the guaranteed fallback.

Two problems must be solved:

1. **Atomicity** — if seeding is interrupted mid-write (crash, kill), the
   writable directory must not be left in a partially-written state that
   causes decoding errors on the next launch.

2. **Re-seeding** — when a new app version ships updated bundled SRD data,
   the writable `srd/` directory must be refreshed. Without a mechanism to
   detect this, stale data from the previous seed would persist indefinitely.

## Decision

`ContentWriter.seedSRDIfNeeded(bundleVersion:)` performs the following:

1. Read a `srd/bundle_version` stamp file from the writable directory.
2. Compare it to `CFBundleVersion` passed by the caller.
3. **If they match** — seeding is already current; return immediately.
4. **If they differ (or the stamp is absent)** — copy `adversaries.json` and
   `environments.json` from the bundle into the writable `srd/` directory,
   then write the new `CFBundleVersion` to the stamp file.

All writes use **temp-file-then-`replaceItemAt`** atomicity:

```swift
try data.write(to: temp, options: .atomic)           // atomic within temp dir
_ = try FileManager.default.replaceItemAt(dest, withItemAt: temp)  // atomic cross-dir move
```

If the app is killed between writing a content file and writing the stamp,
the stamp remains at the old version (or absent), so seeding will re-run and
complete cleanly on the next launch.

## Options Considered

- **Seed on every launch (rejected):** Correct for atomicity but copies
  megabytes of JSON every launch for no benefit once seeded.
- **Seed only if `srd/` is absent (rejected):** Does not re-seed after a
  bundle update ships new SRD data.
- **Bundle version stamp (chosen):** Cheap check (one file read), correct
  for both first launch and bundle updates, atomic against crashes.

## Consequences

- `ContentWriter.seedSRDIfNeeded` is `nonisolated` and is called from a
  `Task.detached` inside `ContentStore.loadOnStartup()` — it never blocks
  the main actor.
- `CFBundleVersion` (the build number) is used, not `CFBundleShortVersionString`
  (the marketing version), because build numbers increment on every build
  whereas marketing versions may stay constant across patch releases.
- If the GM has already fetched a newer SRD via a source URL, re-seeding
  replaces only the `srd/` tier. Source pack content in `sources/<id>/` is
  unaffected.
- The stamp file approach extends naturally to other bundled resources (e.g.
  a default `environments.json` update) by writing the same stamp.
