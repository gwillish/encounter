//
//  EncounterRunnerView.swift
//  Encounter
//
//  Live encounter running screen. Pushed from EncounterBuilderView
//  when the GM taps "Run Encounter".
//
//  Layout:
//   - Nav bar: encounter name + FearTrackerButton (trailing)
//   - Scrollable adversary list (active first, defeated greyed at bottom)
//   - PlayerStrip below the list in a VStack (NOT an overlay or safeAreaInset:
//     UICollectionView.hitTest returns self for all points in its bounds, so
//     any view rendered over it via overlay/safeAreaInset never receives touches.)
//
//  Presented via fullScreenCover (iOS) / sheet (macOS) from EncounterBuilderView,
//  NOT pushed via navigationDestination. NavigationStack push navigation adds a
//  full-screen back-swipe gesture view on iOS 26 that intercepts touches in the
//  PlayerStrip area. Modal presentation avoids that infrastructure entirely.
//
//  Player-edit sheet: EncounterRunnerContainer (below) owns editingPlayer state and
//  presents PlayerEditPopover ABOVE the NavigationStack. A .sheet nested inside a
//  NavigationStack inside a fullScreenCover is not reliably presented on iOS 26.
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

  @Binding var editingPlayer: PlayerState?

  @Environment(\.dismiss) private var dismiss
  @State private var expandedSlotID: UUID?
  @State private var showResetConfirmation = false

  // MARK: - Sorted slots (computed, non-mutating)
  // Active adversaries preserve original insertion order (stable sort).
  // Defeated adversaries accumulate at the bottom in defeat order.
  private var sortedAdversarySlots: [AdversaryState] {
    session.adversarySlots.sorted { !$0.isDefeated && $1.isDefeated }
  }

  var body: some View {
    VStack(spacing: 0) {
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
          Button("End Encounter") {
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

      PlayerStrip(session: session, editingPlayer: $editingPlayer)
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

/// Wraps EncounterRunnerView in a NavigationStack and presents PlayerEditPopover
/// as a ZStack overlay rather than a UIKit sheet. iOS 26 does not reliably present
/// a .sheet from within a fullScreenCover's NavigationStack content.
struct EncounterRunnerContainer: View {
  let session: EncounterSession
  let definition: EncounterDefinition
  let compendium: Compendium
  let sessionRegistry: SessionRegistry
  let sessionStore: SessionStore
  /// When provided, adds a "Done" button in the cancellation-action position.
  /// Used by the session-resume flow in ContentView.
  var onDone: (() -> Void)? = nil

  @State private var editingPlayer: PlayerState? = nil

  var body: some View {
    ZStack(alignment: .bottom) {
      NavigationStack {
        EncounterRunnerView(
          session: session,
          definition: definition,
          compendium: compendium,
          sessionRegistry: sessionRegistry,
          sessionStore: sessionStore,
          editingPlayer: $editingPlayer
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

      if editingPlayer != nil {
        Color.black.opacity(0.4)
          .ignoresSafeArea()
          .onTapGesture { editingPlayer = nil }
          .accessibilityHidden(true)
      }

      if let player = editingPlayer {
        PlayerEditCard(player: player, session: session) {
          editingPlayer = nil
        }
        .transition(.move(edge: .bottom))
      }
    }
    .animation(.easeInOut(duration: 0.25), value: editingPlayer != nil)
  }
}

// MARK: - Player edit card (overlay presentation)

/// Card that wraps PlayerEditPopover for overlay presentation inside the runner.
private struct PlayerEditCard: View {
  let player: PlayerState
  let session: EncounterSession
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        Button(action: onDismiss) {
          Image(systemName: "xmark.circle.fill")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Close player edit")
        .padding([.top, .trailing])
      }
      PlayerEditPopover(player: player, session: session)
    }
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .padding(.horizontal)
    .padding(.bottom)
    .accessibilityIdentifier("runner.player-edit-card")
  }
}
