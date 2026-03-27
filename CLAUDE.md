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
│   └── decisions/              # Architecture Decision Records (ADRs)
│       └── README.md           # ADR format, lifecycle, and superseded process
├── README.md                   # Project overview
├── CONTRIBUTING.md             # Contributor guidelines, scope boundaries, PR process
└── CLAUDE.md                   # This file
```

### DaggerheartModels package (gwillish/DaggerheartModels)

The app imports two products from this package:

| Product | Import | Contents |
|---|---|---|
| **DaggerheartModels** | `import DaggerheartModels` | Value types: `Adversary`, `DaggerheartEnvironment`, `EncounterDefinition`, `PlayerSlot`, `DHPackContent`, `ContentSource`, `ContentFingerprint`, `ContentStoreError`, `DifficultyBudget`, `Condition` |
| **DaggerheartKit** | `import DaggerheartKit` | `@Observable` stores: `Compendium`, `EncounterStore`, `EncounterSession`, `SessionRegistry`; also re-depends on DaggerheartModels |

**Import rule:** Any file that references value types needs `import DaggerheartModels`; any file
that uses the observable stores needs `import DaggerheartKit`. With `MemberImportVisibility`
active, both must be explicit — `import DaggerheartKit` alone does not expose DaggerheartModels types.

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
import DaggerheartKit

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
import DaggerheartKit
import DaggerheartModels

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

The primary iteration cycle is running unit tests from the terminal:

```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=macOS' \
  -resultBundlePath TestResults.xcresult
```

This uses the `UnitTests` test plan (the scheme default) — UI tests are excluded so no
unlock prompt appears. Run this after every meaningful change.

To include UI tests (e.g. before a PR or release):

```bash
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=macOS' \
  -testPlan AllTests \
  -resultBundlePath TestResults.xcresult
```

All test output — including `print()` calls and `Logger` messages routed to stderr — is
visible directly in the terminal. Prefer this over the interactive Xcode debugger for
CLI-driven iteration.

---

## Testing

Tests use **Swift Testing** (`import Testing`), not XCTest.

Test coverage priorities:
1. `Adversary` JSON decoding (both threshold formats, all field variants)
2. `EncounterSession` mutations (damage, stress, fear/hope, turn order)
3. `Compendium` loading and lookup correctness
4. UI flows for encounter setup and live tracking (UITests)

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
- **No Claude attribution in commits.** Do not add `Co-Authored-By: Claude` or any Anthropic/AI attribution lines to commit messages.

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
