//
//  AdversaryRunnerRowTests.swift
//  EncounterTests
//
//  ViewInspector unit tests for AdversaryRunnerSection's collapsed row button.
//  The accessibility label for the collapsed adversary row lives on the Button
//  in AdversaryRunnerSection (not on AdversaryRunnerRow itself).
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("AdversaryRunnerRow")
struct AdversaryRunnerRowTests {

  private static func makeCompendium(adversaryID: String = "goblin") -> Compendium {
    let c = Compendium()
    c.addAdversary(
      Adversary(
        id: adversaryID, name: "Goblin", tier: 1, role: .minion,
        flavorText: "", difficulty: 10,
        thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
        attackModifier: "+2", attackName: "Bite",
        attackRange: .veryClose, damage: "1d4 phy"
      ))
    return c
  }

  private static func makeSection(
    slot: AdversaryState,
    expandedSlotID: UUID? = nil
  ) -> (AdversaryRunnerSection, EncounterSession) {
    let session = EncounterSession(name: "Test", adversarySlots: [slot])
    var id: UUID? = expandedSlotID
    let binding = Binding(get: { id }, set: { id = $0 })
    let section = AdversaryRunnerSection(
      slots: [slot],
      expandedSlotID: binding,
      session: session,
      compendium: makeCompendium()
    )
    return (section, session)
  }

  // MARK: - Accessibility label

  @Test func accessibilityLabelIsCustomNameWhenNoConditions() throws {
    let slot = AdversaryState(
      adversaryID: "goblin", customName: "Goblin 1",
      maxHP: 3, maxStress: 2)
    let (sut, _) = Self.makeSection(slot: slot)

    let button = try sut.inspect().find(ViewType.Button.self)
    #expect(
      try button.accessibilityLabel().string() == "Goblin 1",
      "Label should be the custom name when no conditions are active")
  }

  @Test func accessibilityLabelIncludesConditionWhenPresent() throws {
    let slot = AdversaryState(
      adversaryID: "goblin", customName: "Goblin 1",
      maxHP: 3, maxStress: 2,
      conditions: [.restrained])
    let (sut, _) = Self.makeSection(slot: slot)

    let button = try sut.inspect().find(ViewType.Button.self)
    let label = try button.accessibilityLabel().string()

    #expect(
      label.contains("Restrained"),
      "Label '\(label)' should include the condition name")
  }

  @Test func accessibilityLabelIncludesDefeatedWhenSlotIsDefeated() throws {
    let slot = AdversaryState(
      adversaryID: "goblin", customName: "Goblin 1",
      maxHP: 3, maxStress: 2,
      currentHP: 0, isDefeated: true)
    let (sut, _) = Self.makeSection(slot: slot)

    let button = try sut.inspect().find(ViewType.Button.self)
    let label = try button.accessibilityLabel().string()

    #expect(
      label.contains("defeated"),
      "Label '\(label)' should include 'defeated' when the slot is defeated")
  }

  // MARK: - AX identifier

  @Test func collapsedRowHasCorrectIdentifier() throws {
    let slot = AdversaryState(
      adversaryID: "goblin", customName: "Goblin 1",
      maxHP: 3, maxStress: 2)
    let (sut, _) = Self.makeSection(slot: slot)

    let button = try sut.inspect().find(ViewType.Button.self)
    #expect(try button.accessibilityIdentifier() == "runner.adversary-row")
  }
}
