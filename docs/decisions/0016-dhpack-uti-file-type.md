# ADR-0016: .dhpack custom file type with public.json UTI conformance

**Status:** Accepted
**Date:** 2026-03-21

## Context

Community adversary packs need to be transferable between GMs via AirDrop,
Messages, email, and the Files app. This requires registering a custom file type
with the OS so the system knows Encounter is the handler.

## Decision

Register a custom file type with extension `.dhpack` and UTI
`gwillish.Encounter.dhpack`. A `.dhpack` file is a JSON file in the
seansbox/daggerheart-srd format — just renamed. It can contain adversaries,
environments, or both.

**UTI conformance chain:**
```
gwillish.Encounter.dhpack → public.json → public.text → public.data → public.item
```

Conforming to `public.json` (not just `public.data`) means the system recognizes
the file as JSON content — text editors can open it, Quick Look can preview it,
and JSON-aware apps understand it.

**Swift declaration:**
```swift
extension UTType {
    static let dhpack = UTType(exportedAs: "gwillish.Encounter.dhpack",
                               conformingTo: .json)
}
```

`static let` (not `var`) is correct for an exported type — the value is stable
for the app's lifetime since the app declares it in `Info.plist`. Computed
properties are appropriate for *imported* types (owned by other apps) where the
system registration can change at runtime.

**Info.plist keys required:**
- `UTExportedTypeDeclarations` — declares ownership of the type
- `CFBundleDocumentTypes` — registers the app as a handler

**Import handling:** `onOpenURL` + `.fileImporter` in `EncounterApp`, not
`DocumentGroup`. The app is not document-centric; files are imported into the
content source registry rather than being the primary unit of work.

**Export:** `ShareLink` with `FileRepresentation(contentType: .dhpack)` via the
`Transferable` protocol.

## Options Considered

- **Conform to `public.data` only (rejected):** Works for basic file handling
  but misses Quick Look integration and JSON-aware app compatibility.
- **Conform to `public.json` (chosen):** Better system integration, no downside.
- **Plain `.json` extension (rejected):** No app-specific type registration.
  System cannot distinguish a `.dhpack` from any other JSON file; AirDrop won't
  offer Encounter as the handler.
- **`DocumentGroup` for import (rejected):** Forces a document lifecycle that
  conflicts with the content-source-registry architecture.

## Consequences

- iOS and macOS share the same UTI since they share the bundle ID
  `gwillish.Encounter`. No cross-platform conflict.
- `.dhpack` files airdropped or emailed to a device with Encounter installed
  open directly in the app.
- Content validation (checking the JSON is a valid adversary pack) happens in
  the `DataRepresentation` import handler using `JSONDecoder` + schema checks,
  throwing `LocalizedError` for user-facing error messages.
