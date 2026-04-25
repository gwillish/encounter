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

  @Environment(Compendium.self) private var compendium

  private var adversaryTypes: [AdversaryType] {
    definition.adversaryIDs.compactMap { compendium.adversary(id: $0)?.role }
  }

  private var rating: DifficultyBudget.Rating? {
    DifficultyBudget.rating(
      adversaryTypes: adversaryTypes,
      playerCount: definition.playerConfigs.count
    )
  }

  private var summaryText: String {
    if definition.playerConfigs.isEmpty { return "No players configured" }
    if definition.adversaryIDs.isEmpty { return "No adversaries added" }
    guard let rating else { return "No players configured" }
    return "\(rating.displayName) — \(rating.cost)/\(rating.budget) BP"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(definition.name)
        .font(.body)
      Text(summaryText)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  EncounterLibraryRow(definition: EncounterDefinition(name: "Goblin Ambush"))
    .padding()
    .environment(Compendium())
}
