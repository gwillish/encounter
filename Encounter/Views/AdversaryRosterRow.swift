//
//  AdversaryRosterRow.swift
//  Encounter
//
//  Single row in the adversary roster inside EncounterBuilderView.
//  Looks up the adversary by ID for display; shows a fallback if unresolvable.
//

import SwiftUI

struct AdversaryRosterRow: View {
  let adversaryID: String
  let compendium: Compendium

  private var adversary: Adversary? {
    compendium.adversary(id: adversaryID)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(adversary?.name ?? "Unknown Adversary")
        .font(.body)
      if let adversary {
        Text("\(adversary.type.rawValue) · Tier \(adversary.tier)")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        Text("ID: \(adversaryID)")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, type: .minion,
      description: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  return List {
    AdversaryRosterRow(adversaryID: "goblin", compendium: compendium)
    AdversaryRosterRow(adversaryID: "missing-id", compendium: compendium)
  }
}
