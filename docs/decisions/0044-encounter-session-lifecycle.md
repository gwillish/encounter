# ADR-0044: Encounter Session Lifecycle (Running / Paused)

**Status:** Accepted
**Date:** 2026-05-03

## Context

Prior to this decision, `EncounterSession` had no explicit lifecycle state. A session was implicitly "active" when present in `SessionRegistry` and not `.isOver`. Pausing did not exist as an operation — the GM could background the app and the session would persist on disk via `SessionStore`, but there was no explicit "pause" affordance in the UI.

This created two problems:

1. **No in-progress signal in the encounter list.** The encounter library row had no way to indicate a session was waiting to be resumed short of the launch-time `ResumePromptView` sheet, which only appeared at startup.
2. **Resume flow was a modal launch-time interruption.** The six-variable state machine in `ContentView` drove a sheet that appeared once at launch and was gone. If the GM dismissed it accidentally, recovery required navigating manually.

## Decision

Add a `SessionPhase` enum and `phase` property to `EncounterSession` in DHKit:

```swift
public enum SessionPhase: String, Codable, Sendable {
    case running
    case paused
}

// On EncounterSession:
public var phase: SessionPhase = .running
```

Add two methods:

```swift
public func pause() { phase = .paused }
public func resume() { phase = .running }
```

`SessionStore` persists and restores `phase` as part of the session JSON. No migration needed for existing sessions on disk — they decode without a `phase` field and default to `.running` (which is the correct assumption: if a session was saved without a phase, it was interrupted while running).

### Lifecycle transitions

```
(session created) → .running
  ├── user taps Pause → .paused → saved to SessionStore → returns to encounter list
  │     ├── user taps Resume → .running → re-enters run mode
  │     └── user taps End (from paused) → session deleted from SessionStore + SessionRegistry
  └── user taps End Encounter (while running) → session deleted
```

### In-progress badge

`EncounterLibraryRow` receives `isPaused: Bool` from its parent. When `true`, the row shows an "In Progress" capsule badge and the run-affordance label changes to "Resume". This replaces the launch-time `ResumePromptView`.

Derivation in the parent (list or panel):

```swift
let pausedDefinitionIDs: Set<EncounterDefinition.ID> = Set(
    sessionRegistry.sessions.values
        .filter { $0.phase == .paused }
        .compactMap { $0.definitionID }
)
```

### Retirement of `ResumePromptView`

The launch-time sheet (`ResumePromptView`, `ResumeTarget`, `ResumeSheetPayload`) is retired. Paused sessions are always visible inline. The six-state-variable resume logic in `ContentView` is removed.

## Options Considered

- **Keep implicit state, improve launch-time sheet (rejected).** Would still require the complex modal coordination and fails to provide a persistent in-progress signal once the sheet is dismissed.
- **Add `.ended` phase (considered, deferred).** An `.ended` phase could represent sessions that completed combat (all adversaries defeated) vs. sessions that were manually stopped. This is useful for future session history or analytics. Deferred — the current `isOver` computed property (`currentHP <= 0` for all adversaries) already captures the defeated state. A formal `.ended` case can be added without breaking the current decision.
- **Phase on `SessionRegistry` only, not on the model (rejected).** Moving the phase into the app-layer `SessionRegistry` would lose the information on the next app launch when the registry is rebuilt from `SessionStore`. It must live on the persisted model.

## Consequences

- DHKit package (`gwillish/DHModels`) requires a PR adding `SessionPhase`, `phase`, `pause()`, and `resume()` to `EncounterSession`.
- `SessionStore` in the app encodes/decodes `phase`; existing sessions on disk without a `phase` field default gracefully to `.running`.
- `EncounterLibraryRow` gains an `isPaused: Bool` parameter.
- `EncounterRunnerView` gains a Pause toolbar button that calls `session.pause()`, invokes `SessionStore.save(_:)`, and pops the navigation stack (iOS) or sets `windowMode = .encounterPrep` (macOS/iPadOS).
- `ResumePromptView.swift` and `ResumeTarget.swift` are deleted once all reference sites are removed.
