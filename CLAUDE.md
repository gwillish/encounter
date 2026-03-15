# Encounter — Claude Code Context

Daggerheart encounter prep and run app for iOS and macOS, targeting game masters who need to set up and track encounters at the table.
Built with SwiftUI, targeting Xcode 26.3 / Swift 6.

---

## Project Structure

```
Encounter/
├── Encounter/                  # App target (auto-synced with Xcode file system)
│   ├── Models/                 # Data model layer — start here
│   │   ├── Adversary.swift         # Catalog types: Adversary, AdversaryType, AttackRange, FeatureType, AdversaryFeature
│   │   ├── DaggerheartEnvironment.swift  # Catalog type: DaggerheartEnvironment
│   │   ├── EncounterSession.swift  # Runtime types: EncounterSession, AdversarySlot, EnvironmentSlot
│   │   └── Compendium.swift        # @Observable data store; loads JSON from bundle
│   ├── Resources/
│   │   ├── adversaries.json    # SRD adversary data (seansbox/daggerheart-srd format)
│   │   └── environments.json   # SRD environment data
│   ├── ContentView.swift       # Root view (stub)
│   └── EncounterApp.swift      # App entry point
├── EncounterTests/             # Swift Testing unit tests
│   └── EncounterTests.swift    # Model tests (Adversary decoding, EncounterSession mutations)
├── EncounterUITests/           # XCUITest UI tests
├── docs/
│   └── data-schema.md          # Daggerheart JSON schema reference + source links
└── CLAUDE.md                   # This file
```

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
  loaded from JSON. These are the static SRD/homebrew definitions.
- **Runtime models** (`EncounterSession`, `AdversarySlot`, `EnvironmentSlot`) — mutable
  state for a live encounter being run at the table.

`Compendium` bridges the two: it loads catalog data and provides lookups so the session
can resolve `adversaryID` slugs to full `Adversary` structs when needed.

### SwiftUI integration (intended pattern)

```swift
// EncounterApp.swift
@State private var compendium = Compendium()

WindowGroup {
    ContentView()
        .environment(compendium)
        .task { try? await compendium.load() }
}

// In a view:
@Environment(Compendium.self) var compendium
@State private var session = EncounterSession(name: "New Encounter")
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

The bundled `adversaries.json` and `environments.json` in `Encounter/Resources/` are
sample/stub files. Replace them with the full SRD exports from seansbox/daggerheart-srd
to get the complete adversary list.

---

## Testing

Tests use **Swift Testing** (`import Testing`), not XCTest.

```bash
# Run unit tests from CLI (adjust scheme/destination as needed)
xcodebuild test \
  -scheme Encounter \
  -destination 'platform=macOS' \
  -resultBundlePath TestResults.xcresult
```

Test coverage priorities:
1. `Adversary` JSON decoding (both threshold formats, all field variants)
2. `EncounterSession` mutations (damage, stress, fear/hope, turn order)
3. `Compendium` loading and lookup correctness
4. UI flows for encounter setup and live tracking (UITests)

---

## Git

- **Never commit on behalf of the user.** Do not create commits unless explicitly asked.
- **No Claude attribution in commits.** Do not add `Co-Authored-By: Claude` or any Anthropic/AI attribution lines to commit messages.

---

## Conventions

- **File naming:** One primary type per file, filename matches type name.
  Exception: `EncounterSession.swift` contains `AdversarySlot` and `EnvironmentSlot`.
- **Access control:** `public` on all model types/properties (anticipates potential
  future Swift Package extraction). Views should be `internal`.
- **No force-unwrap** in model or view code. Use `guard let` or optional chaining.
- **No UIKit imports** — SwiftUI only, using `#if os(iOS)` / `#if os(macOS)` for
  platform-specific adaptations.
- **Daggerheart-specific naming:** Use game terms as-is (`hp`, `stress`, `fear`, `hope`,
  `difficulty`, `thresholds`). Do not rename to generic terms like `health` or `defense`.

---

## Known Gaps / Next Steps

- [ ] `ContentView.swift` is a stub — needs compendium browser + encounter runner UI
- [ ] `adversaries.json` / `environments.json` are sample data — replace with full SRD export
- [ ] No dice rolling logic yet — `damage` strings are stored raw (e.g. `"1d12+2 phy"`)
- [ ] No persistence layer — `EncounterSession` is in-memory only
- [ ] Player-facing content (classes, ancestries) not yet modelled
- [ ] Horde adversary rules (shared HP pool, modified attack) not yet implemented in session
- [ ] No iCloud sync or handoff between iOS and macOS
