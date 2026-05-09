//
//  EncounterLibraryRowTests.swift
//  EncounterTests
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("EncounterLibraryRow")
struct EncounterLibraryRowTests {

  // MARK: - Helpers

  private static func makeAdversary(id: String, role: AdversaryType = .standard) -> Adversary {
    Adversary(
      id: id, name: id, tier: 1, role: role,
      flavorText: "", difficulty: 1,
      thresholdMajor: 5, thresholdSevere: 10,
      hp: 4, stress: 3,
      attackModifier: "+1", attackName: "Strike", attackRange: .melee, damage: "1d6+1"
    )
  }

  // MARK: - Name display

  @Test func showsDefinitionName() throws {
    let def = EncounterDefinition(name: "Goblin Ambush")
    let sut = EncounterLibraryRow(definition: def, playerCount: nil, compendium: Compendium())
    let names = try sut.inspect().findAll(ViewType.Text.self)
    #expect(names.contains(where: { (try? $0.string()) == "Goblin Ambush" }))
  }

  // MARK: - Summary text

  @Test func noSummaryWhenPlayerCountNil() throws {
    let def = EncounterDefinition(name: "Test")
    let sut = EncounterLibraryRow(definition: def, playerCount: nil, compendium: Compendium())
    let texts = try sut.inspect().findAll(ViewType.Text.self)
    #expect(texts.count == 1, "Only the name text should appear when playerCount is nil")
  }

  @Test func showsNoAdversariesTextWhenEmpty() throws {
    let def = EncounterDefinition(name: "Test")
    let sut = EncounterLibraryRow(definition: def, playerCount: 4, compendium: Compendium())
    let texts = try sut.inspect().findAll(ViewType.Text.self)
    let strings = texts.compactMap { try? $0.string() }
    #expect(strings.contains("No adversaries added"))
  }

  @Test func showsDifficultyTextWhenAdversariesResolved() throws {
    let compendium = Compendium()
    compendium.addAdversary(Self.makeAdversary(id: "goblin", role: .minion))
    compendium.addAdversary(Self.makeAdversary(id: "goblin-archer", role: .ranged))

    var def = EncounterDefinition(name: "Test")
    def.adversaryIDs = ["goblin", "goblin", "goblin-archer"]

    let sut = EncounterLibraryRow(definition: def, playerCount: 4, compendium: compendium)
    let texts = try sut.inspect().findAll(ViewType.Text.self)
    let strings = texts.compactMap { try? $0.string() }
    #expect(strings.count > 1, "Difficulty summary should appear when adversaries resolve")
  }

  @Test func noSummaryWhenAdversariesUnresolved() throws {
    var def = EncounterDefinition(name: "Test")
    def.adversaryIDs = ["unknown-id"]
    let sut = EncounterLibraryRow(definition: def, playerCount: 4, compendium: Compendium())
    let texts = try sut.inspect().findAll(ViewType.Text.self)
    #expect(texts.count == 1, "No summary when adversaries cannot be resolved from compendium")
  }

  // MARK: - isPaused badge and resume label

  @Test func showsInProgressBadgeWhenPaused() throws {
    let def = EncounterDefinition(name: "Test")
    let sut = EncounterLibraryRow(
      definition: def, playerCount: nil, compendium: Compendium(), isPaused: true)
    let strings = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    #expect(strings.contains("In Progress"))
  }

  @Test func showsResumeLabelWhenPaused() throws {
    let def = EncounterDefinition(name: "Test")
    let sut = EncounterLibraryRow(
      definition: def, playerCount: nil, compendium: Compendium(), isPaused: true)
    let strings = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    #expect(strings.contains("Resume"))
  }

  @Test func showsNeitherBadgeNorResumeLabelWhenNotPaused() throws {
    let def = EncounterDefinition(name: "Test")
    let sut = EncounterLibraryRow(
      definition: def, playerCount: nil, compendium: Compendium(), isPaused: false)
    let strings = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    #expect(!strings.contains("In Progress"))
    #expect(!strings.contains("Resume"))
  }
}
