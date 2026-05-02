//
//  PlayerEditPopoverTests.swift
//  EncounterTests
//
//  ViewInspector unit tests for PlayerEditPopover.
//  Validates stat row presence, armor section visibility, and AX identifiers.
//

import DHKit
import DHModels
import SwiftUI
import Testing
import ViewInspector

@testable import Encounter

@MainActor
@Suite("PlayerEditPopover")
struct PlayerEditPopoverTests {

  private static func makeSession(armorSlots: Int = 3) -> EncounterSession {
    EncounterSession(
      name: "Test",
      playerSlots: [
        PlayerState(
          name: "Aric",
          maxHP: 6, maxStress: 6, evasion: 12,
          thresholdMajor: 5, thresholdSevere: 10, armorSlots: armorSlots)
      ]
    )
  }

  // MARK: - Stat row presence

  @Test func hpAndStressStatRowsAlwaysPresent() throws {
    let session = Self.makeSession()
    let sut = PlayerEditPopover(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let identifiers = buttons.compactMap { try? $0.accessibilityIdentifier() }

    #expect(identifiers.contains("runner.player-edit.hp.decrement"))
    #expect(identifiers.contains("runner.player-edit.hp.increment"))
    #expect(identifiers.contains("runner.player-edit.stress.decrement"))
    #expect(identifiers.contains("runner.player-edit.stress.increment"))
  }

  @Test func armorStatRowPresentWhenArmorSlotsNonZero() throws {
    let session = Self.makeSession(armorSlots: 3)
    let sut = PlayerEditPopover(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let identifiers = buttons.compactMap { try? $0.accessibilityIdentifier() }

    #expect(identifiers.contains("runner.player-edit.armor.decrement"))
    #expect(identifiers.contains("runner.player-edit.armor.increment"))
  }

  @Test func armorStatRowAbsentWhenArmorSlotsIsZero() throws {
    let session = Self.makeSession(armorSlots: 0)
    let sut = PlayerEditPopover(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let identifiers = buttons.compactMap { try? $0.accessibilityIdentifier() }

    #expect(!identifiers.contains("runner.player-edit.armor.decrement"))
    #expect(!identifiers.contains("runner.player-edit.armor.increment"))
  }

  // MARK: - Conditions section

  @Test func conditionsSectionIsEmbedded() throws {
    let session = Self.makeSession()
    let sut = PlayerEditPopover(player: session.playerSlots[0], session: session)

    let buttons = try sut.inspect().findAll(ViewType.Button.self)
    let identifiers = buttons.compactMap { try? $0.accessibilityIdentifier() }

    #expect(
      identifiers.contains("runner.player-edit.condition.hidden"),
      "PlayerConditionsSection should be embedded — its buttons should appear in the popover")
  }
}
