//
//  AdversaryFilterBar.swift
//  Encounter
//
//  Stateless filter bar for adversary lists. Binds search text, tier, and type;
//  all active filters compose with AND. The static filter(_:searchText:tier:type:)
//  method applies the same logic for use in parent views.
//

import DHModels
import SwiftUI

struct AdversaryFilterBar: View {
  @Binding var searchText: String
  @Binding var selectedTier: Int?
  @Binding var selectedType: AdversaryType?

  var body: some View {
    HStack(spacing: 8) {
      HStack(spacing: 4) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("Search", text: $searchText)
          .textFieldStyle(.plain)
          .accessibilityIdentifier("compendium.filter-bar.search")
        if !searchText.isEmpty {
          Button("Clear search", systemImage: "xmark.circle.fill") {
            searchText = ""
          }
          .labelStyle(.iconOnly)
          .foregroundStyle(.secondary)
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))

      Picker("Tier", selection: $selectedTier) {
        Text("All").tag(Int?.none)
        ForEach(1...5, id: \.self) { tier in
          Text("Tier \(tier)").tag(Int?.some(tier))
        }
      }
      .pickerStyle(.menu)
      .accessibilityIdentifier("compendium.filter-bar.tier")

      Picker("Type", selection: $selectedType) {
        Text("All").tag(AdversaryType?.none)
        ForEach(AdversaryType.allCases, id: \.self) { type in
          Text(type.rawValue).tag(AdversaryType?.some(type))
        }
      }
      .pickerStyle(.menu)
      .accessibilityIdentifier("compendium.filter-bar.type")
    }
    .padding(.horizontal)
    .padding(.vertical, 6)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("compendium.filter-bar")
  }

  // MARK: - Filter logic

  static func filter(
    _ adversaries: [Adversary],
    searchText: String,
    tier: Int?,
    type: AdversaryType?
  ) -> [Adversary] {
    adversaries.filter { adversary in
      let matchesSearch = searchText.isEmpty
        || adversary.name.localizedCaseInsensitiveContains(searchText)
      let matchesTier = tier == nil || adversary.tier == tier
      let matchesType = type == nil || adversary.role == type
      return matchesSearch && matchesTier && matchesType
    }
  }
}

#Preview {
  @Previewable @State var searchText = ""
  @Previewable @State var selectedTier: Int? = nil
  @Previewable @State var selectedType: AdversaryType? = nil
  VStack {
    AdversaryFilterBar(
      searchText: $searchText,
      selectedTier: $selectedTier,
      selectedType: $selectedType
    )
    Spacer()
  }
}
