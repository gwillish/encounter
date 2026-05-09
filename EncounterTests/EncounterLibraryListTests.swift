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

  // On iOS the list rows use NavigationLink(value:), which ViewInspector cannot
  // traverse. The macOS path uses EncounterLibraryRow directly and is traversable.
  #if os(macOS)
    @Test func rendersRowsForEachDefinition() throws {
      @State var selection: EncounterDefinition.ID? = nil
      let definitions = [
        EncounterDefinition(name: "Goblin Ambush"),
        EncounterDefinition(name: "Dragon's Lair"),
      ]
      let sut = EncounterLibraryList(
        definitions: definitions,
        selection: Binding(get: { selection }, set: { selection = $0 }),
        onRename: { _ in },
        onDelete: { _ in },
        playerStore: PlayerStore(directory: .temporaryDirectory),
        compendium: Compendium(),
        sessionRegistry: SessionRegistry()
      )
      let texts = try sut.inspect().findAll(ViewType.Text.self)
      let strings = texts.compactMap { try? $0.string() }
      #expect(strings.contains("Goblin Ambush"), "Each definition name should appear in the list")
    }
  #endif

  @Test func emptyListRendersNoRows() throws {
    @State var selection: EncounterDefinition.ID? = nil
    let sut = EncounterLibraryList(
      definitions: [],
      selection: Binding(get: { selection }, set: { selection = $0 }),
      onRename: { _ in },
      onDelete: { _ in },
      playerStore: PlayerStore(directory: .temporaryDirectory),
      compendium: Compendium(),
      sessionRegistry: SessionRegistry()
    )
    let names = try sut.inspect().findAll(ViewType.Text.self)
    #expect(names.isEmpty, "Empty definitions produce no text rows")
  }
}
