# ADR-0013: Store all dates as ISO8601 Zulu

**Status:** Accepted
**Date:** 2026-03-21

## Context

`EncounterDefinition` stores `createdAt` and `modifiedAt` timestamps. Future
types (content source metadata, session records) will also need timestamps. When
files are shared between GMs in different time zones, synced via iCloud, or read
after a daylight-saving transition, locally-zoned timestamps produce ambiguous
or incorrect values.

## Decision

All dates stored in JSON or on disk are written in ISO8601 format with the UTC
(Zulu) offset: `2026-03-21T15:04:00Z`. Never store local-time dates.

Use `JSONEncoder.DateEncodingStrategy.iso8601` and
`JSONDecoder.DateDecodingStrategy.iso8601` on all coders. These use UTC by
default. When displaying dates in the UI, convert to the user's local time zone
via `Date` formatting — but never store local time.

## Options Considered

- **Local time zone (rejected):** Correct for single-device use but produces
  wrong sort order and ambiguous display when files cross time zones or DST
  boundaries.
- **Unix timestamp / `timeIntervalSinceReferenceDate` (rejected):** Unambiguous
  but not human-readable in raw JSON, which matters for a transparent file format.
- **ISO8601 Zulu (chosen):** Unambiguous, human-readable, universally parseable,
  and the standard for interchange formats.

## Consequences

- All `Date` properties in `Codable` types encode/decode as ISO8601 Zulu strings.
- In tests, construct dates from UTC references (not local `Date()` without a
  fixed zone) to avoid flaky assertions.
- Applies to: `EncounterDefinition.createdAt`/`modifiedAt`, future
  `ContentSource.lastFetched`, and any other timestamps added to the project.
