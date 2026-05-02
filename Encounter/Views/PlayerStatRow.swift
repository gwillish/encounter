//
//  PlayerStatRow.swift
//  Encounter
//
//  Stepper row for a single player stat (HP, Stress, or Armor) in the runner.
//  Used by PlayerRunnerCard.
//

import SwiftUI

struct PlayerStatRow: View {
  let label: String
  let current: Int
  let maximum: Int
  let onDecrement: () -> Void
  let onIncrement: () -> Void

  var body: some View {
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
        .accessibilityIdentifier("runner.player-edit.\(label.lowercased()).decrement")

      Text("\(current) / \(maximum)")
        .font(.body)
        .monospacedDigit()
        .frame(minWidth: 64, alignment: .center)

      Button("Increase \(label)", systemImage: "plus.circle", action: onIncrement)
        .labelStyle(.iconOnly)
        .font(.title3)
        .buttonStyle(.borderless)
        .disabled(current >= maximum)
        .accessibilityIdentifier("runner.player-edit.\(label.lowercased()).increment")
    }
  }
}

#Preview {
  List {
    PlayerStatRow(label: "HP", current: 4, maximum: 6, onDecrement: {}, onIncrement: {})
    PlayerStatRow(label: "Stress", current: 0, maximum: 6, onDecrement: {}, onIncrement: {})
    PlayerStatRow(label: "Armor", current: 2, maximum: 3, onDecrement: {}, onIncrement: {})
  }
}
