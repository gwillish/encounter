//
//  AdversaryFilterBar.swift
//  Encounter
//
//  Stateless filter bar for adversary lists: search text, tier, and type compose
//  with AND. All filter state is owned by the parent so the bar can be mounted
//  in multiple contexts without duplicating the predicate. See Adversary+Filtering.swift.
//

import DHModels
import SwiftUI

struct AdversaryFilterBar: View {
  @Binding var searchText: String
  @Binding var selectedTier: Int?
  @Binding var selectedType: AdversaryType?

  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 8) {
        searchField.layoutPriority(1)
        tierPicker
        typePicker
      }
      VStack(spacing: 6) {
        searchField
        HStack(spacing: 8) {
          tierPicker
          typePicker
          Spacer()
        }
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 6)
    .accessibilityIdentifier("compendium.filter-bar")
  }

  @ViewBuilder private var searchField: some View {
    HStack(spacing: 4) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      TextField("Search", text: $searchText)
        .textFieldStyle(.plain)
        .accessibilityLabel("Search adversaries")
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
    .frame(minHeight: 44)
    .padding(.horizontal, 8)
    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
  }

  @ViewBuilder private var tierPicker: some View {
    Picker("Tier", selection: $selectedTier) {
      Text("All tiers").tag(Int?.none)
      ForEach(1...4, id: \.self) { tier in
        Text("Tier \(tier)").tag(Int?.some(tier))
      }
    }
    .pickerStyle(.menu)
    .accessibilityIdentifier("compendium.filter-bar.tier")
  }

  @ViewBuilder private var typePicker: some View {
    Picker("Type", selection: $selectedType) {
      Text("All types").tag(AdversaryType?.none)
      ForEach(AdversaryType.allCases, id: \.self) { type in
        Text(type.rawValue).tag(AdversaryType?.some(type))
      }
    }
    .pickerStyle(.menu)
    .accessibilityIdentifier("compendium.filter-bar.type")
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
