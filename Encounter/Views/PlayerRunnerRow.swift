//
//  PlayerRunnerRow.swift
//  Encounter
//
//  Collapsed player row shown in the live encounter runner.
//  Row 1: name, active condition icons, stress pip track.
//  Row 2: HP pip track, armor pip track (when armorSlots > 0).
//  Tapping expands to PlayerRunnerCard (managed by PlayerRunnerSection).
//

import DHKit
import DHModels
import SwiftUI

struct PlayerRunnerRow: View {
  let player: PlayerState

  @ScaledMetric(relativeTo: .caption2) private var conditionIconSize: CGFloat = 8

  private var sortedConditions: [Condition] {
    player.conditions.sorted { $0.displayName < $1.displayName }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        Text(player.name)
          .font(.body)
          .fontWeight(.medium)
          .lineLimit(1)
          .truncationMode(.tail)

        if !sortedConditions.isEmpty {
          HStack(spacing: 3) {
            ForEach(sortedConditions, id: \.self) { condition in
              Image(systemName: condition.sfSymbol)
                .font(.system(size: conditionIconSize))
                .foregroundStyle(.orange)
            }
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(
            "Conditions: " + sortedConditions.map(\.displayName).joined(separator: ", ")
          )
        }

        Spacer()

        PipTrack(
          current: player.currentStress,
          maximum: player.maxStress,
          filledSymbol: "bolt.fill",
          emptySymbol: "bolt",
          tint: .primary
        )
      }

      HStack(spacing: 6) {
        PipTrack(
          current: player.currentHP,
          maximum: player.maxHP,
          filledSymbol: "heart.fill",
          emptySymbol: "heart"
        )

        Spacer()

        if player.armorSlots > 0 {
          PipTrack(
            current: player.currentArmorSlots,
            maximum: player.armorSlots,
            filledSymbol: "shield.fill",
            emptySymbol: "shield",
            tint: .secondary
          )
        }
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  List {
    PlayerRunnerRow(
      player: PlayerState(
        name: "Aric Stonehammer",
        maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3))
    PlayerRunnerRow(
      player: PlayerState(
        name: "Lira Dawnwhisper",
        maxHP: 5, currentHP: 3, maxStress: 7, currentStress: 2,
        evasion: 14, thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2,
        conditions: [.vulnerable]))
    PlayerRunnerRow(
      player: PlayerState(
        name: "No Armor",
        maxHP: 4, maxStress: 5, evasion: 10,
        thresholdMajor: 3, thresholdSevere: 6, armorSlots: 0))
  }
}
