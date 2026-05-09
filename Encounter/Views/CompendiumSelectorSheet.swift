//
//  CompendiumSelectorSheet.swift
//  Encounter
//
//  Modal adversary selector presented from the encounter editor on iOS.
//  Tapping a row calls onSelect and dismisses; Import DHPack and Done are
//  always visible in the toolbar.
//

import DHKit
import DHModels
import SwiftUI
import UniformTypeIdentifiers

struct CompendiumSelectorSheet: View {
  let compendium: Compendium
  let contentStore: ContentStore
  let onSelect: (Adversary) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var searchText = ""
  @State private var selectedTier: Int?
  @State private var selectedType: AdversaryType?
  @State private var isImporting = false

  private var filteredAdversaries: [Adversary] {
    compendium.adversaries.filtered(
      searchText: searchText,
      tier: selectedTier,
      type: selectedType
    )
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        AdversaryFilterBar(
          searchText: $searchText,
          selectedTier: $selectedTier,
          selectedType: $selectedType
        )
        Divider()
        if filteredAdversaries.isEmpty {
          ContentUnavailableView(
            "No Adversaries",
            systemImage: "magnifyingglass",
            description: Text("Try a different search or filter.")
          )
          .frame(maxHeight: .infinity)
        } else {
          List(filteredAdversaries) { adversary in
            Button {
              onSelect(adversary)
              dismiss()
            } label: {
              AdversaryRow(adversary: adversary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("compendium.adversary-row")
            .accessibilityValue(adversary.name)
          }
        }
      }
      .navigationTitle("Add Adversary")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .accessibilityIdentifier("compendium.selector-sheet")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { dismiss() }
            .accessibilityIdentifier("compendium.selector-sheet.done-button")
        }
        ToolbarItem(placement: .primaryAction) {
          Button {
            isImporting = true
          } label: {
            Label("Import DHPack", systemImage: "square.and.arrow.down")
          }
          .accessibilityIdentifier("compendium.selector-sheet.import-button")
        }
      }
      .fileImporter(
        isPresented: $isImporting,
        allowedContentTypes: [UTType("gwillish.Encounter.dhpack") ?? .json]
      ) { result in
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        Task { @MainActor in
          defer { url.stopAccessingSecurityScopedResource() }
          await contentStore.importPack(from: url)
        }
      }
    }
  }
}

#Preview("With adversaries") {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  compendium.addAdversary(
    Adversary(
      id: "orc", name: "Orc Bruiser", tier: 2, role: .bruiser,
      flavorText: "Massive and relentless.", difficulty: 14,
      thresholdMajor: 10, thresholdSevere: 20, hp: 8, stress: 4,
      attackModifier: "+5", attackName: "Great Axe",
      attackRange: .veryClose, damage: "2d10+4 phy"
    ))
  return CompendiumSelectorSheet(
    compendium: compendium,
    contentStore: PreviewData.contentStore(compendium: compendium),
    onSelect: { adversary in print("Selected: \(adversary.name)") }
  )
}

#Preview("Empty compendium") {
  CompendiumSelectorSheet(
    compendium: PreviewData.compendium(),
    contentStore: PreviewData.contentStore(),
    onSelect: { _ in }
  )
}
