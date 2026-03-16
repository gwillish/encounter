//
//  PlayerRosterSection.swift
//  Encounter
//
//  Form section listing player character configs for the encounter.
//  Shows a footer prompt when empty to encourage adding players
//  (player count drives the difficulty budget calculation).
//

import SwiftUI

struct PlayerRosterSection: View {
    let playerConfigs: [PlayerConfig]
    let onAddPlayer: () -> Void
    let onRemove: (IndexSet) -> Void

    var body: some View {
        Section {
            ForEach(playerConfigs) { config in
                PlayerRosterRow(config: config)
            }
            .onDelete(perform: onRemove)
        } header: {
            HStack {
                Text("Players")
                Spacer()
                Button("Add Player", systemImage: "person.badge.plus", action: onAddPlayer)
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .labelStyle(.iconOnly)
            }
        } footer: {
            if playerConfigs.isEmpty {
                Text("Add players to calculate an accurate difficulty budget.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Empty") {
    Form {
        PlayerRosterSection(
            playerConfigs: [],
            onAddPlayer: {},
            onRemove: { _ in }
        )
    }
}

#Preview("With players") {
    Form {
        PlayerRosterSection(
            playerConfigs: [
                PlayerConfig(name: "Aric", maxHP: 6, maxStress: 6, evasion: 12,
                             thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3),
                PlayerConfig(name: "Lira", maxHP: 5, maxStress: 7, evasion: 14,
                             thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2),
            ],
            onAddPlayer: {},
            onRemove: { _ in }
        )
    }
}
