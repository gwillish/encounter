//
//  PlayerRunnerCard.swift
//  Encounter
//
//  Expanded inline player card in the live encounter runner.
//  Shows stepper controls for HP, Stress, and Armor, plus condition toggles.
//

import DHKit
import DHModels
import SwiftUI

struct PlayerRunnerCard: View {
  let player: PlayerState
  let session: EncounterSession
  let onCollapse: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(player.name)
          .font(.headline)
        Spacer()
        Button("Collapse", systemImage: "chevron.up", action: onCollapse)
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          .accessibilityIdentifier("runner.player-card.collapse-button")
      }

      PlayerStatRow(
        label: "HP",
        current: player.currentHP,
        maximum: player.maxHP,
        onDecrement: { session.applyDamage(1, to: player.id) },
        onIncrement: { session.applyHealing(1, to: player.id) }
      )

      PlayerStatRow(
        label: "Stress",
        current: player.currentStress,
        maximum: player.maxStress,
        onDecrement: { session.reduceStress(1, for: player.id) },
        onIncrement: { session.applyStress(1, to: player.id) }
      )

      if player.armorSlots > 0 {
        PlayerStatRow(
          label: "Armor",
          current: player.currentArmorSlots,
          maximum: player.armorSlots,
          onDecrement: { session.markArmorSlot(for: player.id) },
          onIncrement: { session.restoreArmorSlot(for: player.id) }
        )
      }

      Divider()

      PlayerConditionsSection(player: player, session: session)
    }
    .padding(.vertical, 8)
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
  return List {
    if let player = session.playerSlots.first {
      PlayerRunnerCard(player: player, session: session, onCollapse: {})
    }
  }
}
