//
//  EncounterRunnerView.swift
//  Encounter
//
//  Live encounter running screen. Pushed from EncounterBuilderView
//  when the GM taps "Run Encounter".
//
//  Layout:
//   - Nav bar: "<name> · R<round>" + FearTrackerButton (trailing)
//   - Scrollable adversary list (active first, defeated greyed at bottom)
//   - PlayerStrip pinned to bottom via .safeAreaInset
//

import DHKit
import DHModels
import SwiftUI

struct EncounterRunnerView: View {
  let session: EncounterSession
  let definition: EncounterDefinition

  @Environment(Compendium.self) private var compendium
  @Environment(SessionRegistry.self) private var sessionRegistry
  @State private var expandedSlotID: UUID?

  // MARK: - Sorted slots (computed, non-mutating)
  // Active adversaries preserve original insertion order (stable sort).
  // Defeated adversaries accumulate at the bottom in defeat order.
  private var sortedAdversarySlots: [AdversarySlot] {
    session.adversarySlots.sorted { !$0.isDefeated && $1.isDefeated }
  }

  var body: some View {
    List {
      AdversaryRunnerSection(
        slots: sortedAdversarySlots,
        expandedSlotID: $expandedSlotID,
        session: session,
        compendium: compendium
      )
    }
    .accessibilityIdentifier("runner.adversary-list")
    .navigationTitle(session.name)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        FearTrackerButton(session: session)
          .accessibilityIdentifier("runner.fear-tracker-button")
      }
      ToolbarItem(placement: .secondaryAction) {
        Button("Reset Session") {
          sessionRegistry.resetSession(
            for: definition.id,
            definition: definition,
            compendium: compendium
          )
        }
        .accessibilityIdentifier("runner.reset-button")
      }
    }
    .safeAreaInset(edge: .bottom) {
      PlayerStrip(session: session)
        .accessibilityIdentifier("runner.player-strip")
    }
  }
}

#Preview {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  compendium.addAdversary(
    Adversary(
      id: "orc", name: "Orc Bruiser", tier: 2, role: .bruiser,
      flavorText: "Massive and relentless.", difficulty: 14,
      thresholdMajor: 10, thresholdSevere: 20, hp: 8, stress: 4,
      attackModifier: "+5", attackName: "Great Axe",
      attackRange: .veryClose, damage: "2d10+4 phy"
    ))
  let definition = EncounterDefinition(
    name: "Goblin Ambush",
    adversaryIDs: ["goblin", "goblin", "orc"],
    playerConfigs: [
      PlayerConfig(
        name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3),
      PlayerConfig(
        name: "Lira", maxHP: 5, maxStress: 7, evasion: 14,
        thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2),
    ]
  )
  let session = EncounterSession.make(from: definition, using: compendium)
  return NavigationStack {
    EncounterRunnerView(session: session, definition: definition)
  }
  .environment(compendium)
  .environment(SessionRegistry())
}
