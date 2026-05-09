//
//  CompendiumSelectorSheetTests.swift
//  EncounterTests
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("CompendiumSelectorSheet")
struct CompendiumSelectorSheetTests {

  private static func makeAdversary(id: String, name: String) -> Adversary {
    Adversary(
      id: id, name: name, tier: 1, role: .minion,
      flavorText: "", difficulty: 8,
      thresholdMajor: 4, thresholdSevere: 8, hp: 3, stress: 2,
      attackModifier: "+1", attackName: "Club", attackRange: .melee, damage: "1d4 phy"
    )
  }

  private func makeSUT(
    adversaries: [Adversary] = [],
    onSelect: @escaping (Adversary) -> Void = { _ in }
  ) -> CompendiumSelectorSheet {
    let compendium = Compendium()
    for adversary in adversaries {
      compendium.addAdversary(adversary)
    }
    let contentStore = ContentStore(contentDirectory: .temporaryDirectory, compendium: compendium)
    return CompendiumSelectorSheet(
      compendium: compendium,
      contentStore: contentStore,
      onSelect: onSelect
    )
  }

  // MARK: - Filter bar

  @Test func showsAdversaryFilterBar() throws {
    let sut = makeSUT()
    // "All tiers" is a unique string rendered only by AdversaryFilterBar's tier Picker.
    let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    #expect(texts.contains("All tiers"), "AdversaryFilterBar tier picker should be present")
    #expect(texts.contains("All types"), "AdversaryFilterBar type picker should be present")
  }

  // MARK: - Adversary rows

  @Test func adversaryRowTapCallsOnSelect() throws {
    let goblin = Self.makeAdversary(id: "goblin", name: "Goblin")
    var selected: Adversary?
    let sut = makeSUT(adversaries: [goblin]) { selected = $0 }
    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let goblinButton = try #require(
      buttons.first { btn in
        let texts = (try? btn.findAll(ViewType.Text.self)) ?? []
        return texts.contains { (try? $0.string()) == "Goblin" }
      },
      "Expected a button labelled with the adversary name"
    )
    try goblinButton.tap()
    #expect(selected?.id == "goblin")
  }

  @Test func emptyCompendiumShowsEmptyState() throws {
    let sut = makeSUT()
    let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    #expect(texts.contains("No Adversaries"))
  }

  // MARK: - Toolbar buttons

  @Test func doneButtonPresent() throws {
    let sut = makeSUT()
    let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    #expect(texts.contains("Done"))
  }

  @Test func importDHPackButtonPresent() throws {
    let sut = makeSUT()
    let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    #expect(texts.contains("Import DHPack"))
  }
}
