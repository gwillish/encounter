//
//  EncounterLibraryRow.swift
//  Encounter
//
//  A single row in the encounter library list.
//

import DHKit
import DHModels
import SwiftUI

struct EncounterLibraryRow: View {
  let definition: EncounterDefinition
  let playerCount: Int?

  @Environment(Compendium.self) private var compendium

  private var adversaryTypes: [AdversaryType] {
    definition.adversaryIDs.compactMap { compendium.adversary(id: $0)?.role }
  }

  private var summaryText: String? {
    guard let playerCount else { return nil }
    if definition.adversaryIDs.isEmpty { return "No adversaries added" }
    if adversaryTypes.count < definition.adversaryIDs.count { return "—" }
    guard
      let rating = DifficultyBudget.rating(
        adversaryTypes: adversaryTypes, playerCount: playerCount
      )
    else { return nil }
    return "\(rating.displayName) — \(rating.cost) / \(rating.budget) BP"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(definition.name)
        .font(.body)
      if let summaryText {
        Text(summaryText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 2)
  }
}

#Preview("No party selected") {
  EncounterLibraryRow(definition: EncounterDefinition(name: "Goblin Ambush"), playerCount: nil)
    .padding()
    .environment(Compendium())
}

#Preview("Party of 4, no adversaries") {
  EncounterLibraryRow(definition: EncounterDefinition(name: "Goblin Ambush"), playerCount: 4)
    .padding()
    .environment(Compendium())
}
