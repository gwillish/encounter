//
//  AdversaryRow.swift
//  Encounter
//
//  A single row in the adversary list: name, type/tier/difficulty, homebrew badge.
//

import DaggerheartKit
import DaggerheartModels
import SwiftUI

struct AdversaryRow: View {
  let adversary: Adversary

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(adversary.name)
          .font(.body)
        if adversary.isHomebrew {
          Text(adversary.source)
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.blue)
            .clipShape(.capsule)
        }
      }
      Text("\(adversary.type.rawValue) · Tier \(adversary.tier) · DC \(adversary.difficulty)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  AdversaryRow(
    adversary: Adversary(
      id: "goblin",
      name: "Goblin",
      tier: 1,
      type: .minion,
      description: "Small and cunning.",
      difficulty: 10,
      thresholdMajor: 5,
      thresholdSevere: 10,
      hp: 3,
      stress: 2,
      attackModifier: "+2",
      attackName: "Rusty Blade",
      attackRange: .veryClose,
      damage: "1d4 phy"
    )
  )
  .padding()
}
