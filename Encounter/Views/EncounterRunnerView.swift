//
//  EncounterRunnerView.swift
//  Encounter
//
//  Live encounter running screen. Pushed onto the NavigationStack (iOS) /
//  presented as a sheet (macOS) from EncounterEditorView.
//
//  Layout:
//   - Nav bar: encounter name + FearTrackerButton (trailing)
//   - Scrollable list: adversary accordion rows first, player accordion rows below
//
//  Both adversary and player sections share a single expandedItemID binding so
//  only one card can be open at a time across the whole list.
//

import DHKit
import DHModels
import SwiftUI

struct EncounterRunnerView: View {
  let session: EncounterSession
  let definition: EncounterDefinition
  let compendium: Compendium
  let sessionRegistry: SessionRegistry
  let sessionStore: SessionStore

  @Environment(\.dismiss) private var dismiss
  @State private var expandedItemID: UUID?
  @State private var showResetConfirmation = false

  // Active adversaries preserve original insertion order (stable sort).
  // Defeated adversaries accumulate at the bottom in defeat order.
  private var sortedAdversarySlots: [AdversaryState] {
    session.adversarySlots.sorted { !$0.isDefeated && $1.isDefeated }
  }

  var body: some View {
    List {
      AdversaryRunnerSection(
        slots: sortedAdversarySlots,
        expandedItemID: $expandedItemID,
        session: session,
        compendium: compendium
      )
      PlayerRunnerSection(
        slots: session.playerSlots,
        expandedItemID: $expandedItemID,
        session: session
      )
    }
    .accessibilityIdentifier("runner.list")
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
        Button("Pause") {
          session.pause()
          Task { await sessionStore.save(session) }
          dismiss()
        }
        .accessibilityIdentifier("runner.pause-button")
      }
      ToolbarItem(placement: .secondaryAction) {
        Button("End Encounter") {
          let sessionID = session.id
          sessionRegistry.clearSession(for: definition.id)
          Task { await sessionStore.delete(sessionID: sessionID) }
          dismiss()
        }
        .accessibilityIdentifier("runner.end-button")
      }
      ToolbarItem(placement: .secondaryAction) {
        Button("Reset Session") {
          showResetConfirmation = true
        }
        .accessibilityIdentifier("runner.reset-button")
      }
    }
    .confirmationDialog(
      "Reset Session?",
      isPresented: $showResetConfirmation,
      titleVisibility: .visible
    ) {
      Button("Reset Session", role: .destructive) {
        let sessionID = session.id
        sessionRegistry.clearSession(for: definition.id)
        Task { await sessionStore.delete(sessionID: sessionID) }
        dismiss()
      }
      .accessibilityIdentifier("runner.reset-confirm-button")
    } message: {
      Text("The current session will be cleared. The encounter definition is not changed.")
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
  return EncounterRunnerContainer(
    session: session,
    definition: definition,
    compendium: compendium,
    sessionRegistry: PreviewData.sessionRegistry(),
    sessionStore: PreviewData.sessionStore()
  )
}

// MARK: - Presentation container

/// Wraps EncounterRunnerView in a NavigationStack.
/// When onDone is provided, adds a "Done" button used by the session-resume flow.
struct EncounterRunnerContainer: View {
  let session: EncounterSession
  let definition: EncounterDefinition
  let compendium: Compendium
  let sessionRegistry: SessionRegistry
  let sessionStore: SessionStore
  var onDone: (() -> Void)? = nil

  var body: some View {
    NavigationStack {
      EncounterRunnerView(
        session: session,
        definition: definition,
        compendium: compendium,
        sessionRegistry: sessionRegistry,
        sessionStore: sessionStore
      )
      .toolbar {
        if let onDone {
          ToolbarItem(placement: .cancellationAction) {
            Button("Done", action: onDone)
              .accessibilityIdentifier("runner.done-button")
          }
        }
      }
    }
  }
}
