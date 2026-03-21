# ADR-0005: Swift Testing framework, not XCTest

**Status:** Accepted
**Date:** 2026-03-15

## Context

Apple ships two test frameworks: the legacy XCTest and the modern Swift Testing
(`import Testing`). New projects can choose either or use both.

## Decision

Use Swift Testing exclusively (`import Testing`). No XCTest in `EncounterTests`.
`EncounterUITests` continues to use XCUITest (which has no Swift Testing
equivalent for UI automation).

## Options Considered

- **Swift Testing only (chosen):** Modern, native Swift syntax (`#expect`,
  `@Test`, `@Suite`), better error messages, parameterized tests, integrates
  with Xcode and `xcodebuild` natively.
- **XCTest only:** Familiar but verbose. `setUp`/`tearDown` lifecycle is
  heavier than Swift Testing's structured approach.
- **Both:** Unnecessary complexity for a new project.

## Consequences

- All unit tests in `EncounterTests` use `import Testing`.
- `EncounterUITests` remains XCUITest — this is correct and not an exception.
- The two test suites are separated by the `UnitTests` / `AllTests` test plan
  split (see ADR-0006).
- CI and development commands must use `xcodebuild test` (which handles both
  frameworks), not `swift test` (which does not run XCUITest).
