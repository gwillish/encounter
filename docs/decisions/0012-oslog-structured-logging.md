# ADR-0012: OSLog structured logging in service types

**Status:** Accepted
**Date:** 2026-03-21

## Context

CLI-driven development (`xcodebuild test`) needs visibility into app behavior
without an interactive debugger. `print()` works but produces unstructured output
with no subsystem or category tagging. `os.Logger` provides structured output
visible in both Console.app and terminal stderr.

## Decision

Add `os.Logger` instances to `Compendium` and `EncounterSession` using the app's
bundle ID as the subsystem:

```swift
private let logger = Logger(subsystem: "gwillish.Encounter", category: "Compendium")
private let logger = Logger(subsystem: "gwillish.Encounter", category: "EncounterSession")
```

Log levels used:
- `.info` — load start/completion, slot defeated, round advanced
- `.debug` — per-mutation stat changes (HP after damage, stress after apply)
- `.warning` — slot ID not found in mutation methods
- `.error` — load failures with error description

## Options Considered

- **`print()` statements (rejected):** No subsystem/category. No log level
  filtering. Clutters output indiscriminately.
- **Third-party logging framework (rejected):** Unnecessary dependency for
  structured logging that the OS already provides.
- **OSLog (chosen):** Zero overhead when not observed. Integrates with Console.app
  for live device debugging. All output visible in `xcodebuild test` terminal via
  stderr, which is the primary dev loop.

## Consequences

- Logger instances are `private let` on `@MainActor` classes — not `nonisolated`.
- All test output including logger messages is visible in the terminal during
  `xcodebuild test` runs (routed to stderr).
- Future service types (`ContentStore`, `EncounterStore`) should follow the same
  pattern with their own category names.
