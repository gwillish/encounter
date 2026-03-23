//
//  PlayerStrip.swift
//  Encounter
//
//  Always-visible panel pinned to the bottom of EncounterRunnerView
//  via .safeAreaInset(edge: .bottom). Shows all player slots.
//

import SwiftUI

struct PlayerStrip: View {
  let session: EncounterSession

  var body: some View {
    VStack(spacing: 0) {
      Divider()
      VStack(spacing: 4) {
        ForEach(session.playerSlots) { player in
          PlayerStripRow(player: player, session: session)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 6)
      .background(.regularMaterial)
    }
  }
}

#Preview {
  let session = EncounterSession(
    name: "Goblin Ambush",
    playerSlots: [
      PlayerSlot(
        name: "Aric Stonehammer",
        maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3),
      PlayerSlot(
        name: "Lira Dawnwhisper",
        maxHP: 5, currentHP: 3, maxStress: 7, currentStress: 2,
        evasion: 14, thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2),
    ]
  )
  VStack {
    Spacer()
    PlayerStrip(session: session)
  }
}
