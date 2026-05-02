//
//  PlayerRunnerSection.swift
//  Encounter
//
//  ForEach over player slots in EncounterRunnerView.
//  Drives the accordion via the expandedItemID binding — shared with
//  AdversaryRunnerSection so only one card can be open at a time across
//  both sections (single UUID stored; adversary and player IDs do not collide).
//

import DHKit
import DHModels
import SwiftUI

struct PlayerRunnerSection: View {
  let slots: [PlayerState]
  @Binding var expandedItemID: UUID?
  let session: EncounterSession

  var body: some View {
    ForEach(slots) { player in
      if expandedItemID == player.id {
        PlayerRunnerCard(
          player: player,
          session: session,
          onCollapse: { expandedItemID = nil }
        )
        .listRowSeparator(.hidden)
      } else {
        Button {
          expandedItemID = player.id
        } label: {
          PlayerRunnerRow(player: player)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("runner.player-row")
        .accessibilityLabel(rowLabel(for: player))
        .accessibilityHint("Tap to expand")
      }
    }
  }

  private func rowLabel(for player: PlayerState) -> String {
    var parts: [String] = [player.name]
    if !player.conditions.isEmpty {
      let conditionNames = player.conditions.map(\.displayName).sorted().joined(separator: ", ")
      parts.append("Conditions: \(conditionNames)")
    }
    return parts.joined(separator: ", ")
  }
}
