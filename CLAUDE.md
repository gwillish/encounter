# Encounter — Claude Code Context

Daggerheart encounter prep and run app for iOS and macOS, primarily for game masters who need to set up and track encounters at the table.
Built with SwiftUI, targeting Xcode 26.3 / Swift 6.

---

## Project Structure

```
Encounter/
├── Encounter/                  # App target (auto-synced with Xcode file system)
│   ├── Models/                 # (empty) — all model types live in DaggerheartModels package
│   ├── Services/
│   │   ├── ContentFetcher.swift    # Fetches .dhpack files from remote URLs
│   │   ├── ContentStore.swift      # @Observable coordinator: source mgmt + Compendium reload
│   │   └── ContentWriter.swift     # Reads/writes .dhpack files in App Support directory
│   ├── Views/                  # SwiftUI views
│   ├── Resources/
│   │   # (adversaries.json and environments.json now bundled inside DaggerheartKit)
│   ├── ContentView.swift       # Root view
│   └── EncounterApp.swift      # App entry point
├── EncounterTests/             # Swift Testing unit tests
├── EncounterUITests/           # XCUITest UI tests
├── docs/
│   ├── data-schema.md          # Daggerheart JSON schema reference + source links
│   ├── first-principles.md     # Product principles — what the app is and isn't
│   ├── ui-development.md       # UI testing strategy, ViewInspector/XCUITest patterns, iOS 26 quirks
│   ├── ui-vocabulary.md        # Screen names, component glossary, navigation map
│   └── decisions/              # Architecture Decision Records (ADRs)
│       └── README.md           # ADR format, lifecycle, and superseded process
├── README.md                   # Project overview
├── CONTRIBUTING.md             # Contributor guidelines, scope boundaries, PR process
└── CLAUDE.md                   # This file
```

### DHModels package (gwillish/DHModels)

The package repo was formerly named `gwillish/DaggerheartModels`. It was renamed to
`DHModels`/`DHKit` to avoid using the DAGGERHEART Name Mark (DPCGL §2.5) in a
title-like position.

The app imports two products from this package:

| Product | Import | Contents |
|---|---|---|
| **DHModels** | `import DHModels` | Value types: `Adversary`, `DaggerheartEnvironment`, `EncounterDefinition`, `PlayerSlot`, `DHPackContent`, `ContentSource`, `ContentFingerprint`, `ContentStoreError`, `DifficultyBudget`, `Condition` |
| **DHKit** | `import DHKit` | `@Observable` stores: `Compendium`, `EncounterStore`, `EncounterSession`, `SessionRegistry`; also re-depends on DHModels |

**Import rule:** Any file that references value types needs `import DHModels`; any file
that uses the observable stores needs `import DHKit`. With `MemberImportVisibility`
active, both must be explicit — `import DHKit` alone does not expose DHModels types.

**Important:** The Xcode project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+).
Any `.swift` file added to `Encounter/` or its subdirectories is **automatically included**
in the build — no need to modify `project.pbxproj`.

---

## Build Configuration

- **Xcode version:** 26.3
- **Swift version:** 5.0 (with Swift 6 concurrency features active)
- **Deployment targets:** iOS 26.2, macOS 26.2, visionOS 26.2
- **Bundle ID:** `gwillish.Encounter`
- **Platforms:** `iphoneos iphonesimulator macosx xros xrsimulator`

### Key Swift flags active

| Flag | Value | Impact |
|---|---|---|
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | All non-isolated code defaults to @MainActor |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | Swift 6.1 approachable concurrency mode |
| `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` | `YES` | SE-0409 member import visibility |

**Concurrency guidance:** Because `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, all
model types must either be Sendable value types (structs/enums — preferred for catalog
data) or explicitly isolated @Observable classes (for mutable session state). Do not
add `nonisolated` without a specific reason.

---

## Architecture

### Catalog vs. Runtime split

The data layer has two distinct concerns:

- **Catalog models** (`Adversary`, `DaggerheartEnvironment`) — immutable value types
  loaded from JSON. These are the static SRD/homebrew definitions. Defined in **DaggerheartModels**.
- **Runtime models** (`EncounterSession`, `AdversarySlot`, `EnvironmentSlot`) — mutable
  state for a live encounter being run at the table. Defined in **DaggerheartKit**.

`Compendium` bridges the two: it loads catalog data and provides lookups so the session
can resolve `adversaryID` slugs to full `Adversary` structs when needed. Defined in **DaggerheartKit**.

### SwiftUI integration (intended pattern)

```swift
// EncounterApp.swift
import DHKit

@State private var compendium = Compendium()
@State private var store = EncounterStore(directory: EncounterStore.localDirectory)
@State private var sessionRegistry = SessionRegistry()

WindowGroup {
    ContentView()
        .environment(compendium)
        .environment(store)
        .environment(sessionRegistry)
        .task { try? await compendium.load() }
}

// In a view:
import DHKit
import DHModels

@Environment(Compendium.self) var compendium
```

---

## Daggerheart Game Reference

**Index:** [`daggerheart-resources/INDEX.md`](daggerheart-resources/INDEX.md)

The `daggerheart-resources/` directory is **read-only** reference material:
- `daggerheart-resources/daggerheart-srd/` — Markdown SRD (full rules + per-entity files for adversaries, classes, abilities, weapons, etc.)
- PDFs: full SRD, expanded adversary compendium (v1.5), errata, homebrew kit

Consult the index when you need to understand game mechanics, verify field meanings, or look up content while implementing app features.

---

## Data Sources

Full schema documentation: `docs/data-schema.md`

| Content | Source repo | Notes |
|---|---|---|
| Adversaries (SRD) | seansbox/daggerheart-srd → `.build/json/adversaries.json` | Primary JSON source |
| Environments (SRD) | seansbox/daggerheart-srd → `.build/json/environments.json` | Primary JSON source |
| Player content (classes, ancestries, items) | daggersearch/daggerheart-data | Not yet imported; no adversaries in this repo |
| Homebrew schema | Same as SRD JSON | Decoder accepts both `thresholds: "8/15"` and pre-split keys |

The bundled `adversaries.json` and `environments.json` in `Encounter/Resources/` contain
the complete SRD exports from seansbox/daggerheart-srd (129 adversaries, 19 environments).
See `Encounter/Resources/README.md` for license attribution.

---

## Development Loop

### Testing pyramid

| Tier | Tool | Speed | Use for |
|---|---|---|---|
| **1 — Model** | Swift Testing direct | ~0.1 ms | Model mutations, JSON decoding, persistence logic |
| **2 — View structure** | ViewInspector (EncounterTests) | ~1 ms | Element presence, bindings, AX labels, conditional render |
| **3 — Visual** | Xcode MCP `mcp__xcode__RenderPreview` | on-demand | Layout, colour, icon review during agent sessions |
| **4 — End-to-end** | XCUITest (EncounterUITests) | ~60 s | Full navigation flows, session lifecycle, real UIKit |

**Decision rule:** if the assertion can be expressed as "given this model state, the view
should have this structure / label / binding behaviour" → write a ViewInspector test in
`EncounterTests`. Only reach for XCUITest when the full running app and real UIKit are
required.

### Dependency injection rule

`@Environment` is for system-provided SwiftUI values only (`\.dismiss`, `\.scenePhase`,
`\.colorScheme`, etc.). All custom app stores (`Compendium`, `EncounterStore`,
`SessionRegistry`, `SessionStore`, `PlayerStore`, `ContentStore`) are passed as explicit
`init` parameters. `EncounterApp` is the sole composition root. See ADR-0041.

### Preview helpers

Use `PreviewData` factory methods (`PreviewData.compendium()`, `PreviewData.playerStore()`,
etc.) in `#Preview` blocks. All return empty instances using `.temporaryDirectory`; no
async loading or `.environment()` chains needed.

### Primary iteration cycle

```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=macOS'
```

This uses the `UnitTests` test plan (the scheme default) — UI tests are excluded so no
unlock prompt appears. Run this after every meaningful change.

To include UI tests (e.g. before a PR or release):

```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=macOS' \
  -testPlan AllTests
```

All test output — including `print()` calls and `Logger` messages routed to stderr — is
visible directly in the terminal. Prefer this over the interactive Xcode debugger for
CLI-driven iteration.

---

## UI Exploration Harness

A `#if DEBUG`-only mode for visual review of components and design proposals without
navigating through live app state. Enabled by the `-UIExploration` launch argument;
`ExplorationRootView` replaces `ContentView` entirely. Zero production footprint.

### When to use it

- Reviewing a new component in all its states before writing UI tests
- Comparing design proposals side-by-side (e.g. icon sets, layout variants)
- Taking deterministic screenshots for design or accessibility review
- Validating how a component looks with extreme data (very long names, max stress, etc.)

### How to invoke

**From Xcode:** Edit Scheme → Run → Arguments → Launch Arguments → add `-UIExploration`.

**From the terminal:**

```bash
# macOS
xcodebuild run -scheme Encounter -destination 'platform=macOS' \
  OTHER_SWIFT_FLAGS='-DDEBUG' \
  INFOPLIST_OTHER_PREPROCESSOR_FLAGS='-UIExploration'
```

**From XCUITest** (preferred for screenshots and CI):

```swift
class MyExplorationTests: ExplorationUITestCase {
  func testDesignLanguageScreenshot() throws {
    navigate(to: "exploration.design-language")
    screenshotScene(named: "design-language-ios")
  }
}
```

`ExplorationUITestCase` (in `EncounterUITests/`) sets `-UIExploration` automatically,
waits for the "Exploration" nav bar, and provides `navigate(to:)` and
`screenshotScene(named:)` helpers.

### Adding a new scene

1. Create the view in `Encounter/Views/Exploration/` inside `#if DEBUG`.
2. Add an entry to `ExplorationScene.all` in `ExplorationScene.swift`:

```swift
ExplorationScene(
  id: "exploration.my-scene",      // stable AX identifier for XCUITest
  title: "My Scene",
  subtitle: "One-line description"
) {
  MyExplorationView()
}
```

The scene appears automatically in the list on both platforms. No other wiring needed.

### Current scenes

| Scene ID | Content |
|---|---|
| `exploration.design-language` | Four icon proposals (ADR-0039) at 20/28/44pt + mock rows |
| `exploration.runner-row` | `AdversaryRunnerRow` in 9 states (normal, damaged, high-stress, single/multiple conditions, solo variants, defeated, unknown) |
| `exploration.player-strip` | `PlayerStrip` with two `EncounterSession` galleries — 4-player varied states and edge-case long names |

---

## Code Changes 

When making bulk renames or refactors, do NOT make unrequested additional renames. Only change what was explicitly asked for. If you think something else should be renamed, ask first.

---

## Interaction Style 

When working through a list of items (issues, review findings, renames), present them one at a time and wait for user input before proceeding to the next.


---

## Problem Solving 

When fixing build errors or investigating issues, always research the root cause before attempting a fix. Do not apply quick fixes without understanding the underlying problem (e.g., platform availability, import visibility rules).

---

## Testing

Tests use **Swift Testing** (`import Testing`), not XCTest.

Test coverage priorities:
1. `Adversary` JSON decoding (both threshold formats, all field variants)
2. `EncounterSession` mutations (damage, stress, fear/hope, turn order)
3. `Compendium` loading and lookup correctness
4. UI flows for encounter setup and live tracking (UITests)

Always run a clean build and full test suite after making changes. Never reuse stale test output or cached build results. Use `swift build` and `swift test` fresh each time.

For ViewInspector patterns, XCUITest element querying, AX tree debugging, and iOS 26
SwiftUI quirks, see [`docs/ui-development.md`](docs/ui-development.md).

---

## Architecture Decision Records

Significant architectural, data-format, and UX decisions are recorded as ADRs in
`docs/decisions/`. See `docs/decisions/README.md` for the full format and process.

### When to write an ADR

Write one when choosing between meaningfully different approaches, establishing a
project-wide convention, making a UX decision that constrains future work, or
deciding explicitly *not* to do something. Do not write one for routine
implementation details. At the end of any planning session, propose ADRs for
what was decided and let the user confirm which to write.

### ADR statuses

| Status | Meaning |
|---|---|
| **Proposed** | Under active exploration; not yet settled |
| **Accepted** | Decided and currently in effect |
| **Rejected** | Explored but not implemented; findings recorded to prevent re-exploring the same dead end |
| **Deprecated** | No longer applies; no direct replacement |
| **Superseded by ADR-NNNN** | A later decision replaced this one |

### Superseded / Mistake Process

**Never edit or delete an existing ADR.** If a decision was wrong or needs to change:

1. Write a **new ADR** with the next available number. Open its Context section
   with _"This supersedes [ADR-NNNN](NNNN-title.md)."_ Explain what changed and why.
2. Update the **original ADR's status line only** to:
   `Superseded by [ADR-NNNN](NNNN-title.md)`
3. Leave the original content completely intact below the status line.

### Branch explorations

A `Proposed` ADR on a feature branch documents an approach under exploration.
If the branch is discarded but the findings matter, cherry-pick just the ADR
file to `main` with status `Rejected` before deleting the branch. If nothing
was learned worth preserving, don't bring the ADR to `main`.

---

## Git

- **Never commit on behalf of the user.** Do not create commits unless explicitly asked.
- **No Claude attribution anywhere.** Do not add `Co-Authored-By: Claude` or any Anthropic/AI attribution lines to commit messages, issue comments, or pull request bodies.

---

## Conventions

- **File naming:** One primary type per file, filename matches type name.
  Exception: `EncounterSession.swift` contains `AdversarySlot` and `EnvironmentSlot`.
- **Access control:** `public` on all model types/properties in DaggerheartModels/DaggerheartKit.
  Views in the Encounter app target should be `internal`.
- **No force-unwrap** in model or view code. Use `guard let` or optional chaining.
- **No UIKit imports** — SwiftUI only, using `#if os(iOS)` / `#if os(macOS)` for
  platform-specific adaptations.
- **Daggerheart-specific naming:** Use game terms as-is (`hp`, `stress`, `fear`, `hope`,
  `difficulty`, `thresholds`). Do not rename to generic terms like `health` or `defense`.
- **Formatting:** `swift-format` (built-in Swift toolchain). Run before committing:
  `swift-format format --recursive --in-place Encounter/`

---

## Roadmap and Scope

- **Development roadmap:** GitHub issues organized by milestone (Phase 0 through Phase 6)
- **First principles and scope boundaries:** [`docs/first-principles.md`](docs/first-principles.md)
- **Contributor guidelines:** [`CONTRIBUTING.md`](CONTRIBUTING.md)

### Deferred (planned, not yet scheduled)

- LLM-assisted ad-hoc encounter generation from description
- Continuity/Handoff between Mac and iPhone mid-session
- Player companion app with live GM sync
- Hope tracking per player — pending playtesting to determine GM visibility needs
- In-app rules/condition tooltips — pending licensing clarity
