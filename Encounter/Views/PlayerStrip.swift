//
//  PlayerStrip.swift
//  Encounter
//
//  Always-visible panel pinned to the bottom of EncounterRunnerView
//  via .safeAreaInset(edge: .bottom). Shows all player slots.
//
//  The editingPlayer binding is set here and threads down to each row;
//  the sheet itself is presented by EncounterRunnerView (outside safeAreaInset)
//  so SwiftUI can anchor it to the top-level hosting controller.
//

import DHKit
import DHModels
import SwiftUI

struct PlayerStrip: View {
  let session: EncounterSession
  @Binding var editingPlayer: PlayerState?

  var body: some View {
    VStack(spacing: 0) {
      Divider()
      VStack(spacing: 4) {
        ForEach(session.playerSlots) { player in
          PlayerStripRow(player: player, session: session, editingPlayer: $editingPlayer)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 6)
      .background(.regularMaterial)
    }
  }
}

#Preview {
  @Previewable @State var editingPlayer: PlayerState? = nil
  let session = EncounterSession(
    name: "Goblin Ambush",
    playerSlots: [
      PlayerState(
        name: "Aric Stonehammer",
        maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3),
      PlayerState(
        name: "Lira Dawnwhisper",
        maxHP: 5, currentHP: 3, maxStress: 7, currentStress: 2,
        evasion: 14, thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2),
    ]
  )
  VStack {
    Spacer()
    PlayerStrip(session: session, editingPlayer: $editingPlayer)
  }
  .sheet(item: $editingPlayer) { player in
    PlayerEditPopover(player: player, session: session)
  }
}
