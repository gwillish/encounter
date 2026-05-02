//
//  PlayerConditionsSectionTests.swift
//  EncounterTests
//
//  ViewInspector unit tests for PlayerConditionsSection.
//  Validates button presence, AX identifiers, AX values, and session mutations.
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("PlayerConditionsSection")
struct PlayerConditionsSectionTests {

  private static func makeSession(withHiddenCondition: Bool = false) -> EncounterSession {
    let session = EncounterSession(
      name: "Test",
      playerSlots: [
        PlayerState(
          name: "Aric",
          maxHP: 6, maxStress: 6, evasion: 12,
          thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3)
      ]
    )
    if withHiddenCondition {
      session.applyCondition(.hidden, to: session.playerSlots[0].id)
    }
    return session
  }

  // MARK: - Button presence

  @Test func buttonsPresentForAllStandardConditions() throws {
    let session = Self.makeSession()
    let sut = PlayerConditionsSection(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    #expect(
      buttons.count == Condition.standardConditions.count,
      "One button should be present for each standard condition")
  }

  // MARK: - Accessibility identifiers

  @Test func buttonIdentifiersMatchConditionDisplayNames() throws {
    let session = Self.makeSession()
    let sut = PlayerConditionsSection(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let identifiers = buttons.compactMap { try? $0.accessibilityIdentifier() }

    #expect(identifiers.contains("runner.player-edit.condition.hidden"))
    #expect(identifiers.contains("runner.player-edit.condition.restrained"))
    #expect(identifiers.contains("runner.player-edit.condition.vulnerable"))
  }

  // MARK: - Accessibility value (active / inactive)

  @Test func buttonAccessibilityValueIsActiveWhenConditionPresent() throws {
    let session = Self.makeSession(withHiddenCondition: true)
    let sut = PlayerConditionsSection(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let hiddenButton = buttons.first(where: {
      (try? $0.accessibilityIdentifier()) == "runner.player-edit.condition.hidden"
    })
    let button = try #require(hiddenButton, "Hidden button should be present")

    #expect(
      try button.accessibilityValue().string() == "active",
      "Button should report 'active' when the condition is applied to the player")
  }

  @Test func buttonAccessibilityValueIsInactiveWhenConditionAbsent() throws {
    let session = Self.makeSession()
    let sut = PlayerConditionsSection(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let hiddenButton = buttons.first(where: {
      (try? $0.accessibilityIdentifier()) == "runner.player-edit.condition.hidden"
    })
    let button = try #require(hiddenButton, "Hidden button should be present")

    #expect(
      try button.accessibilityValue().string() == "inactive",
      "Button should report 'inactive' when the condition is not applied")
  }

  // MARK: - Tap mutations

  @Test func tapHiddenButtonAppliesConditionToSession() throws {
    let session = Self.makeSession()
    let sut = PlayerConditionsSection(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let hiddenButton = buttons.first(where: {
      (try? $0.accessibilityIdentifier()) == "runner.player-edit.condition.hidden"
    })
    let button = try #require(hiddenButton, "Hidden button should be present")
    try button.tap()

    #expect(
      session.playerSlots[0].conditions.contains(.hidden),
      "Tapping the Hidden button should apply .hidden to the session")
  }

  @Test func tapActiveHiddenButtonRemovesConditionFromSession() throws {
    let session = Self.makeSession(withHiddenCondition: true)
    let sut = PlayerConditionsSection(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let hiddenButton = buttons.first(where: {
      (try? $0.accessibilityIdentifier()) == "runner.player-edit.condition.hidden"
    })
    let button = try #require(hiddenButton, "Hidden button should be present")
    try button.tap()

    #expect(
      !session.playerSlots[0].conditions.contains(.hidden),
      "Tapping the active Hidden button should remove .hidden from the session")
  }
}
