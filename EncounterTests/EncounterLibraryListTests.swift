//
//  EncounterLibraryListTests.swift
//  EncounterTests
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("EncounterLibraryList")
struct EncounterLibraryListTests {

  private func makeList(
    definitions: [EncounterDefinition],
    pausedDefinitionIDs: Set<UUID> = []
  ) -> EncounterLibraryList {
    @State var selection: EncounterDefinition.ID? = nil
    return EncounterLibraryList(
      definitions: definitions,
      selection: Binding(get: { selection }, set: { selection = $0 }),
      onRename: { _ in },
      onDelete: { _ in },
      playerStore: PlayerStore(directory: .temporaryDirectory),
      compendium: Compendium(),
      pausedDefinitionIDs: pausedDefinitionIDs
    )
  }

  // On iOS the list rows use NavigationLink(value:), which ViewInspector cannot
  // traverse. The macOS path uses EncounterLibraryRow directly and is traversable.
  #if os(macOS)
    @Test func rendersRowsForEachDefinition() throws {
      let sut = makeList(definitions: [
        EncounterDefinition(name: "Goblin Ambush"),
        EncounterDefinition(name: "Dragon's Lair"),
      ])
      let strings = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(strings.contains("Goblin Ambush"), "Each definition name should appear in the list")
    }

    @Test func showsInProgressBadgeForPausedDefinition() throws {
      let definition = EncounterDefinition(name: "Goblin Ambush")
      let sut = makeList(
        definitions: [definition],
        pausedDefinitionIDs: [definition.id]
      )
      let strings = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(strings.contains("In Progress"))
    }

    @Test func doesNotShowBadgeForUnpausedDefinition() throws {
      let definition = EncounterDefinition(name: "Goblin Ambush")
      let sut = makeList(definitions: [definition], pausedDefinitionIDs: [])
      let strings = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(!strings.contains("In Progress"))
    }
  #endif

  @Test func emptyListRendersNoRows() throws {
    let sut = makeList(definitions: [])
    let names = try sut.inspect().findAll(ViewType.Text.self)
    #expect(names.isEmpty, "Empty definitions produce no text rows")
  }
}
