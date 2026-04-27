//
//  PlayerStripRow.swift
//  Encounter
//
//  Compact player row inside the always-visible PlayerStrip.
//  Row 1: name, active condition icons, stress pip track.
//  Row 2: HP pip track, armor pip track.
//  Tapping sets editingPlayer on the parent so EncounterRunnerView can
//  present the PlayerEditPopover sheet from outside the safeAreaInset.
//

import DHKit
import DHModels
import SwiftUI

struct PlayerStripRow: View {
  let player: PlayerState
  let session: EncounterSession
  @Binding var editingPlayer: PlayerState?

  private var sortedConditions: [Condition] {
    player.conditions.sorted { $0.displayName < $1.displayName }
  }

  var body: some View {
    Button {
      editingPlayer = player
    } label: {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(player.name)
            .font(.caption)
            .fontWeight(.medium)
            .lineLimit(1)
            .truncationMode(.tail)

          if !sortedConditions.isEmpty {
            HStack(spacing: 3) {
              ForEach(sortedConditions, id: \.self) { condition in
                Image(systemName: condition.sfSymbol)
                  .font(.system(size: 8))
                  .foregroundStyle(.orange)
              }
            }
            .accessibilityElement(children: .ignore)
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
      .foregroundStyle(.primary)
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
    .accessibilityIdentifier("runner.player-row")
    .accessibilityLabel(
      sortedConditions.isEmpty
        ? player.name
        : player.name + ", " + sortedConditions.map(\.displayName).joined(separator: ", ")
    )
    .accessibilityHint("Opens player details")
  }
}

#Preview {
  @Previewable @State var editingPlayer: PlayerState? = nil
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
        evasion: 14, thresholdMajor: 4, thresholdSevere: 8, armorSlots: 2,
        conditions: [.vulnerable]),
    ]
  )
  List {
    ForEach(session.playerSlots) { player in
      PlayerStripRow(player: player, session: session, editingPlayer: $editingPlayer)
    }
  }
  .sheet(item: $editingPlayer) { player in
    PlayerEditPopover(player: player, session: session)
  }
}
