//
//  PlayerRosterSection.swift
//  Encounter
//
//  Read-only section in EncounterEditorView showing the active party
//  members that will be snapshotted when the encounter is started.
//  Players are managed via PartyOverviewView (macOS) or EncounterAndPartyRootView (iOS).
//

import DHModels
import SwiftUI

struct PlayerRosterSection: View {
  let players: [Player]

  var body: some View {
    Section {
      ForEach(players) { player in
        PlayerPartyRow(player: player)
          .accessibilityIdentifier("builder.player-row")
      }
    } header: {
      Text("Players")
    } footer: {
      if players.isEmpty {
        Text(
          "No players in party. Add players in the Party tab before running an encounter."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview("Empty") {
  Form {
    PlayerRosterSection(players: [])
  }
}

#Preview("With players") {
  Form {
    PlayerRosterSection(
      players: [
        Player(
          name: "Aric", level: 3, maxHP: 6, maxStress: 6, evasion: 12,
          thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3),
        Player(
          name: "Lira", level: 5, maxHP: 5, maxStress: 7, evasion: 14,
          thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2),
      ])
  }
}
