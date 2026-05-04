//
//  AdversaryRunnerRowSnapshotTests.swift
//  EncounterTests
//
//  Visual snapshot tests for AdversaryRunnerRow (Tier 3 — Snapshot).
//  Mirrors the nine states defined in RunnerRowExplorationView.
//

#if os(iOS)
import DHKit
import DHModels
import SnapshotTesting
import SwiftUI
import Testing

@testable import Encounter

@MainActor
@Suite("AdversaryRunnerRow snapshots")
struct AdversaryRunnerRowSnapshotTests {

  private static let compendium: Compendium = {
    let c = Compendium()
    c.addAdversary(Adversary(
      id: "goblin-brute", name: "Goblin Brute", tier: 1, role: .minion,
      flavorText: "Tough and mean.", difficulty: 8,
      thresholdMajor: 5, thresholdSevere: 10,
      hp: 10, stress: 5,
      attackModifier: "+2", attackName: "Club",
      attackRange: .melee, damage: "1d8 phy"
    ))
    c.addAdversary(Adversary(
      id: "shadow-stalker", name: "Shadow Stalker", tier: 2, role: .solo,
      flavorText: "Moves unseen.", difficulty: 14,
      thresholdMajor: 8, thresholdSevere: 15,
      hp: 18, stress: 8,
      attackModifier: "+5", attackName: "Shadow Claw",
      attackRange: .veryClose, damage: "2d6+3 phy"
    ))
    return c
  }()

  private func row(_ slot: AdversaryState, opacity: Double = 1) -> some View {
    AdversaryRunnerRow(slot: slot, compendium: Self.compendium)
      .opacity(opacity)
      .padding()
  }

  @Test func normal() {
    assertSnapshot(
      of: row(AdversaryState(adversaryID: "goblin-brute", maxHP: 10, maxStress: 5)),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func damaged() {
    assertSnapshot(
      of: row(AdversaryState(adversaryID: "goblin-brute", maxHP: 10, maxStress: 5, currentHP: 5)),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func highStress() {
    assertSnapshot(
      of: row(AdversaryState(
        adversaryID: "goblin-brute", maxHP: 10, maxStress: 5,
        currentHP: 8, currentStress: 4
      )),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func singleCondition() {
    assertSnapshot(
      of: row(AdversaryState(
        adversaryID: "goblin-brute", maxHP: 10, maxStress: 5,
        currentHP: 7, conditions: [.vulnerable]
      )),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func multipleConditions() {
    assertSnapshot(
      of: row(AdversaryState(
        adversaryID: "goblin-brute", maxHP: 10, maxStress: 5,
        currentHP: 6, currentStress: 2, conditions: [.restrained, .vulnerable]
      )),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func soloFull() {
    assertSnapshot(
      of: row(AdversaryState(adversaryID: "shadow-stalker", maxHP: 18, maxStress: 8)),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func soloCritical() {
    assertSnapshot(
      of: row(AdversaryState(
        adversaryID: "shadow-stalker", maxHP: 18, maxStress: 8,
        currentHP: 4, currentStress: 6, conditions: [.hidden, .vulnerable]
      )),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func defeated() {
    assertSnapshot(
      of: row(
        AdversaryState(
          adversaryID: "goblin-brute", maxHP: 10, maxStress: 5,
          currentHP: 0, isDefeated: true
        ),
        opacity: 0.4
      ),
      as: .image(layout: SnapshotLayout.row)
    )
  }

  @Test func unknownAdversary() {
    assertSnapshot(
      of: row(AdversaryState(adversaryID: "unknown-beast", maxHP: 8, maxStress: 3, currentHP: 5)),
      as: .image(layout: SnapshotLayout.row)
    )
  }
}
#endif
