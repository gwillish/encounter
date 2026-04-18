//
//  PlayerConditionsSection.swift
//  Encounter
//
//  Condition toggle strip for a player slot in the live encounter runner.
//

import DHKit
import DHModels
import SwiftUI

/// Displays toggleable condition buttons for a player slot.
///
/// Active conditions are highlighted in orange. Tapping a condition applies
/// or removes it from the slot via the session.
struct PlayerConditionsSection: View {
  let player: PlayerState
  let session: EncounterSession

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Conditions")
        .font(.caption)
        .foregroundStyle(.secondary)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(Condition.standardConditions, id: \.self) { condition in
            let active = player.conditions.contains(condition)
            Button(condition.displayName) {
              if active {
                session.removeCondition(condition, from: player.id)
              } else {
                session.applyCondition(condition, to: player.id)
              }
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .tint(active ? .orange : nil)
            .accessibilityAddTraits(active ? .isSelected : [])
            .accessibilityIdentifier(
              "runner.player-edit.condition.\(condition.displayName.lowercased())"
            )
          }
        }
      }
    }
  }
}

#Preview {
  let session = EncounterSession(name: "Test")
  session.add(
    player: PlayerState(
      name: "Aric Stonehammer",
      maxHP: 6, maxStress: 6, evasion: 12,
      thresholdMajor: 5, thresholdSevere: 10, armorSlots: 3
    ))
  session.applyCondition(.hidden, to: session.playerSlots[0].id)
  return PlayerConditionsSection(player: session.playerSlots[0], session: session)
    .padding()
}
