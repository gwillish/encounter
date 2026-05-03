//
//  AdversaryRosterSection.swift
//  Encounter
//
//  Form section listing adversaries added to the encounter.
//  Uses index-based identity to support duplicate adversary IDs; onDelete receives a position-based IndexSet.
//

import DHKit
import DHModels
import SwiftUI

struct AdversaryRosterSection: View {
  let adversaryIDs: [String]
  let compendium: Compendium
  let partyTier: Int?
  let onBrowse: () -> Void
  let onRemove: (IndexSet) -> Void

  var body: some View {
    Section {
      if adversaryIDs.isEmpty {
        Text("No adversaries added yet.")
          .foregroundStyle(.secondary)
          .italic()
      } else {
        ForEach(adversaryIDs.indices, id: \.self) { index in
          AdversaryRosterRow(
            adversaryID: adversaryIDs[index],
            compendium: compendium,
            partyTier: partyTier
          )
        }
        .onDelete(perform: onRemove)
      }
    } header: {
      HStack {
        Text("Adversaries")
        Spacer()
        Button("Add", systemImage: "plus", action: onBrowse)
          .buttonStyle(.borderless)
          .font(.caption)
          .labelStyle(.iconOnly)
          .accessibilityIdentifier("builder.add-adversary-button")
      }
    }
  }
}

#Preview("No party tier") {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  return Form {
    AdversaryRosterSection(
      adversaryIDs: ["goblin", "goblin"],
      compendium: compendium,
      partyTier: nil,
      onBrowse: {},
      onRemove: { _ in }
    )
  }
}

#Preview("T2 party") {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  return Form {
    AdversaryRosterSection(
      adversaryIDs: ["goblin", "goblin"],
      compendium: compendium,
      partyTier: 2,
      onBrowse: {},
      onRemove: { _ in }
    )
  }
}
