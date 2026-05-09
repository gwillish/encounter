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
  let compendium: Compendium
  var isPaused: Bool = false

  private var adversaryTypes: [AdversaryType] {
    definition.adversaryIDs.compactMap { compendium.adversary(id: $0)?.role }
  }

  private var summaryText: String? {
    guard let playerCount else { return nil }
    if definition.adversaryIDs.isEmpty { return "No adversaries added" }
    if adversaryTypes.count < definition.adversaryIDs.count { return nil }
    guard
      let rating = DifficultyBudget.rating(
        adversaryTypes: adversaryTypes, playerCount: playerCount
      )
    else { return nil }
    return "\(rating.displayName) — \(rating.cost) / \(rating.budget) BP"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 6) {
        Text(definition.name)
          .font(.body)
          .lineLimit(1)
        if isPaused {
          Text("In Progress")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.tint.opacity(0.15), in: Capsule())
            .foregroundStyle(.tint)
        }
      }
      if isPaused {
        Text("Resume")
          .font(.caption)
          .foregroundStyle(.tint)
      } else if let summaryText {
        Text(summaryText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(isPaused ? "\(definition.name), in progress" : definition.name)
    .accessibilityHint(isPaused ? "Resume" : "")
  }
}

#Preview("No party selected") {
  EncounterLibraryRow(
    definition: EncounterDefinition(name: "Goblin Ambush"),
    playerCount: nil,
    compendium: PreviewData.compendium()
  )
  .padding()
}

#Preview("In Progress — paused session") {
  EncounterLibraryRow(
    definition: EncounterDefinition(name: "Goblin Ambush"),
    playerCount: nil,
    compendium: PreviewData.compendium(),
    isPaused: true
  )
  .padding()
}

#Preview("Party of 4, no adversaries") {
  EncounterLibraryRow(
    definition: EncounterDefinition(name: "Goblin Ambush"),
    playerCount: 4,
    compendium: PreviewData.compendium()
  )
  .padding()
}

#Preview("Party of 4, rated encounter") {
  @Previewable @State var compendium = Compendium()
  var definition = EncounterDefinition(name: "Goblin Ambush")
  definition.adversaryIDs = ["ironguard-soldier", "ironguard-soldier", "thornwood-archer"]
  return EncounterLibraryRow(definition: definition, playerCount: 4, compendium: compendium)
    .padding()
    .task { try? await compendium.load() }
}
