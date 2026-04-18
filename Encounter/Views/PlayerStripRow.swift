//
//  PlayerStripRow.swift
//  Encounter
//
//  Compact player row inside the always-visible PlayerStrip.
//  Shows name, HP pip track, stress pip track, and armor slot count.
//  Tapping opens PlayerEditPopover for HP/Stress/Armor stepper controls.
//

import DHKit
import DHModels
import SwiftUI

struct PlayerStripRow: View {
  let player: PlayerState
  let session: EncounterSession
  @State private var showPopover = false

  var body: some View {
    Button {
      showPopover = true
    } label: {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(player.name)
            .font(.caption)
            .fontWeight(.medium)
            .frame(minWidth: 60, alignment: .leading)
            .lineLimit(1)
            .truncationMode(.tail)

          Spacer()

          HStack(spacing: 4) {
            Text("HP")
              .font(.caption2)
              .foregroundStyle(.secondary)
            PipTrack(current: player.currentHP, maximum: player.maxHP)
          }

          HStack(spacing: 4) {
            Text("St")
              .font(.caption2)
              .foregroundStyle(.secondary)
            PipTrack(current: player.currentStress, maximum: player.maxStress)
          }

          if player.armorSlots > 0 {
            HStack(spacing: 4) {
              Text("Arm")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text("\(player.currentArmorSlots)/\(player.armorSlots)")
                .font(.caption)
                .monospacedDigit()
            }
          }
        }

        if !player.conditions.isEmpty {
          HStack(spacing: 6) {
            ForEach(
              player.conditions.sorted { $0.displayName < $1.displayName }, id: \.self
            ) { condition in
              HStack(spacing: 3) {
                Image(systemName: "circle.fill")
                  .font(.system(size: 5))
                Text(condition.displayName)
                  .font(.caption2)
              }
              .foregroundStyle(.orange)
              .accessibilityElement(children: .ignore)
              .accessibilityLabel(condition.displayName)
              .accessibilityIdentifier(
                "runner.player-row.condition.\(condition.displayName.lowercased())"
              )
            }
          }
        }
      }
      .foregroundStyle(.primary)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("runner.player-row")
    .accessibilityLabel(
      player.conditions.isEmpty
        ? player.name
        : player.name + ", " + player.conditions.map(\.displayName).sorted().joined(separator: ", ")
    )
    .popover(isPresented: $showPopover) {
      PlayerEditPopover(player: player, session: session)
        .presentationCompactAdaptation(.popover)
    }
  }
}

#Preview {
  let session = EncounterSession(
    name: "Test",
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
  List {
    ForEach(session.playerSlots) { player in
      PlayerStripRow(player: player, session: session)
    }
  }
}
