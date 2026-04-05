//
//  PlayerEditPopover.swift
//  Encounter
//
//  Popover presenting stepper-style controls for a player's HP, Stress,
//  and Armor Slots during a live encounter.
//

import DHKit
import DHModels
import SwiftUI

struct PlayerEditPopover: View {
  let player: PlayerState
  let session: EncounterSession

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(player.name)
        .font(.headline)

      statRow(
        label: "HP",
        current: player.currentHP,
        maximum: player.maxHP,
        onDecrement: { session.applyDamage(1, to: player.id) },
        onIncrement: { session.applyHealing(1, to: player.id) }
      )

      statRow(
        label: "Stress",
        current: player.currentStress,
        maximum: player.maxStress,
        onDecrement: { session.reduceStress(1, for: player.id) },
        onIncrement: { session.applyStress(1, to: player.id) }
      )

      if player.armorSlots > 0 {
        statRow(
          label: "Armor",
          current: player.currentArmorSlots,
          maximum: player.armorSlots,
          onDecrement: { session.markArmorSlot(for: player.id) },
          onIncrement: { session.restoreArmorSlot(for: player.id) }
        )
      }
    }
    .padding()
    .frame(minWidth: 220)
  }

  @ViewBuilder
  private func statRow(
    label: String,
    current: Int,
    maximum: Int,
    onDecrement: @escaping () -> Void,
    onIncrement: @escaping () -> Void
  ) -> some View {
    HStack {
      Text(label)
        .font(.subheadline)
        .frame(minWidth: 60, alignment: .leading)
      Spacer()
      Button("Decrease \(label)", systemImage: "minus.circle", action: onDecrement)
        .labelStyle(.iconOnly)
        .font(.title3)
        .buttonStyle(.borderless)
        .disabled(current <= 0)
        .accessibilityIdentifier(
          "runner.player-edit.\(label.lowercased()).decrement"
        )

      Text("\(current) / \(maximum)")
        .font(.body)
        .monospacedDigit()
        .frame(minWidth: 64, alignment: .center)

      Button("Increase \(label)", systemImage: "plus.circle", action: onIncrement)
        .labelStyle(.iconOnly)
        .font(.title3)
        .buttonStyle(.borderless)
        .disabled(current >= maximum)
        .accessibilityIdentifier(
          "runner.player-edit.\(label.lowercased()).increment"
        )
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
  return PlayerEditPopover(
    player: session.playerSlots[0],
    session: session
  )
}
