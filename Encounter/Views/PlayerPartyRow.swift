//
//  PlayerPartyRow.swift
//  Encounter
//
//  A single row in the party or roster section of PartyOverviewView.
//  Shows name and key stats: HP, Stress, Evasion, and Armor.
//

import DHModels
import SwiftUI

struct PlayerPartyRow: View {
  let player: Player

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(player.name)
        .font(.body)
      HStack(spacing: 12) {
        statLabel("HP", value: player.maxHP)
        statLabel("Stress", value: player.maxStress)
        statLabel("Evasion", value: player.evasion)
        if player.armorSlots > 0 {
          statLabel("Armor", value: player.armorSlots)
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 2)
  }

  private func statLabel(_ label: String, value: Int) -> some View {
    Text("\(label): \(value)")
  }
}

#Preview {
  List {
    PlayerPartyRow(
      player: Player(
        name: "Aric Stonehammer",
        maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3
      ))
    PlayerPartyRow(
      player: Player(
        name: "Lira Dawnwhisper",
        maxHP: 5, maxStress: 7, evasion: 14,
        thresholdMajor: 4, thresholdSevere: 8, armorSlots: 0
      ))
  }
}
