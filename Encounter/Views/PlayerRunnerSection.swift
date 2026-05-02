//
//  PlayerRunnerSection.swift
//  Encounter
//
//  ForEach over player slots in EncounterRunnerView.
//  Drives the accordion via the expandedPlayerID binding — shared with
//  AdversaryRunnerSection so only one card can be open at a time across
//  both sections (single UUID stored; adversary and player IDs do not collide).
//

import DHKit
import DHModels
import SwiftUI

struct PlayerRunnerSection: View {
  let slots: [PlayerState]
  @Binding var expandedPlayerID: UUID?
  let session: EncounterSession

  var body: some View {
    ForEach(slots) { player in
      if expandedPlayerID == player.id {
        PlayerRunnerCard(
          player: player,
          session: session,
          onCollapse: { expandedPlayerID = nil }
        )
        .listRowSeparator(.hidden)
      } else {
        Button {
          expandedPlayerID = player.id
        } label: {
          PlayerRunnerRow(player: player)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("runner.player-row")
        .accessibilityLabel(
          {
            var parts: [String] = [player.name]
            if !player.conditions.isEmpty {
              let conditionNames = player.conditions.map(\.displayName).sorted().joined(
                separator: ", ")
              parts.append("Conditions: \(conditionNames)")
            }
            return parts.joined(separator: ", ")
          }()
        )
        .accessibilityHint("Tap to expand")
      }
    }
  }
}
