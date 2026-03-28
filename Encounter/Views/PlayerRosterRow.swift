//
//  PlayerRosterRow.swift
//  Encounter
//
//  Single row in the player roster inside EncounterBuilderView.
//  Shows name, HP, Stress, and Evasion.
//

import DHKit
import DHModels
import SwiftUI

struct PlayerRosterRow: View {
  let config: PlayerConfig

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(config.name)
        .font(.body)
      Text("HP: \(config.maxHP)  Stress: \(config.maxStress)  Evasion: \(config.evasion)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  List {
    PlayerRosterRow(
      config: PlayerConfig(
        name: "Aric Stonehammer",
        maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3
      ))
    PlayerRosterRow(
      config: PlayerConfig(
        name: "Lira Dawnwhisper",
        maxHP: 5, maxStress: 7, evasion: 14,
        thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2
      ))
  }
}
