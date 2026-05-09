//
//  EncounterLibraryRowSnapshotTests.swift
//  EncounterTests
//
//  Visual snapshot tests for EncounterLibraryRow (Tier 3 — Snapshot).
//

#if os(iOS)
  import DHKit
  import DHModels
  import SnapshotTesting
  import SwiftUI
  import Testing

  @testable import Encounter

  @MainActor
  @Suite("EncounterLibraryRow snapshots")
  struct EncounterLibraryRowSnapshotTests {

    @Test func notPaused() {
      assertSnapshot(
        of: EncounterLibraryRow(
          definition: EncounterDefinition(name: "Goblin Ambush"),
          playerCount: 4,
          compendium: Compendium()
        ).padding(),
        as: .image(layout: SnapshotLayout.row)
      )
    }

    @Test func paused() {
      assertSnapshot(
        of: EncounterLibraryRow(
          definition: EncounterDefinition(name: "Goblin Ambush"),
          playerCount: nil,
          compendium: Compendium(),
          isPaused: true
        ).padding(),
        as: .image(layout: SnapshotLayout.row)
      )
    }

    @Test func pausedLongName() {
      assertSnapshot(
        of: EncounterLibraryRow(
          definition: EncounterDefinition(
            name: "The Ancient Dragon's Lair — A Very Long Encounter Name"),
          playerCount: nil,
          compendium: Compendium(),
          isPaused: true
        ).padding(),
        as: .image(layout: SnapshotLayout.row)
      )
    }
  }
#endif
