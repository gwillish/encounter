//
//  CompendiumBrowserView.swift
//  Encounter
//
//  Root screen for browsing the adversary and environment compendium.
//
//  The optional onSelect / onSelectEnvironment closures establish the
//  Step 3 seam: when non-nil (called from EncounterBuilderView),
//  detail views show an "Add to Encounter" button that calls the closure
//  and dismisses the sheet.
//

import DHKit
import DHModels
import SwiftUI

struct CompendiumBrowserView: View {
  @Environment(Compendium.self) private var compendium
  @Environment(\.dismiss) private var dismiss

  let onSelect: ((Adversary) -> Void)?
  let onSelectEnvironment: ((DaggerheartEnvironment) -> Void)?

  @State private var activeTab = BrowserTab.adversaries
  @State private var searchText = ""
  @State private var selectedType: AdversaryType?

  init(
    onSelect: ((Adversary) -> Void)? = nil,
    onSelectEnvironment: ((DaggerheartEnvironment) -> Void)? = nil
  ) {
    self.onSelect = onSelect
    self.onSelectEnvironment = onSelectEnvironment
  }

  var filteredAdversaries: [Adversary] {
    let base =
      selectedType.map { t in compendium.adversaries.filter { $0.role == t } }
      ?? compendium.adversaries
    guard !searchText.isEmpty else { return base }
    return base.filter {
      $0.name.localizedStandardContains(searchText)
        || $0.description.localizedStandardContains(searchText)
    }
  }

  var filteredEnvironments: [DaggerheartEnvironment] {
    guard !searchText.isEmpty else { return compendium.environments }
    return compendium.environments.filter {
      $0.name.localizedStandardContains(searchText)
        || $0.description.localizedStandardContains(searchText)
    }
  }

  var body: some View {
    Group {
      switch activeTab {
      case .adversaries:
        AdversaryListView(adversaries: filteredAdversaries)
      case .environments:
        EnvironmentListView(environments: filteredEnvironments)
      }
    }
    .navigationTitle("Compendium")
    .navigationDestination(for: Adversary.self) { adversary in
      AdversaryDetailView(adversary: adversary, onSelect: onSelect)
    }
    .navigationDestination(for: DaggerheartEnvironment.self) { environment in
      EnvironmentDetailView(environment: environment, onSelect: onSelectEnvironment)
    }
    .searchable(text: $searchText, prompt: "Search \(activeTab.rawValue.lowercased())")
    .onChange(of: activeTab) { selectedType = nil }
    .toolbar { toolbarContent }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    // Done button when shown as a sheet from the builder
    if onSelect != nil || onSelectEnvironment != nil {
      ToolbarItem(placement: .cancellationAction) {
        Button("Done") { dismiss() }
          .accessibilityIdentifier("compendium.done-button")
      }
    }

    // Tab switcher
    ToolbarItem(placement: .principal) {
      Picker("Category", selection: $activeTab) {
        ForEach(BrowserTab.allCases, id: \.self) { tab in
          Text(tab.rawValue).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 240)
      .accessibilityIdentifier("compendium.tab-picker")
    }

    // Type filter — adversaries tab only
    ToolbarItem(placement: .primaryAction) {
      if activeTab == .adversaries {
        Menu {
          Button("All Types") { selectedType = nil }
          Divider()
          ForEach(AdversaryType.allCases, id: \.self) { type in
            Button(type.rawValue) { selectedType = type }
          }
        } label: {
          Label(
            selectedType?.rawValue ?? "Filter",
            systemImage: selectedType != nil
              ? "line.3.horizontal.decrease.circle.fill"
              : "line.3.horizontal.decrease.circle"
          )
        }
      }
    }
  }
}

#Preview("Standalone") {
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
  compendium.addEnvironment(
    DaggerheartEnvironment(
      id: "collapsing-cavern", name: "Collapsing Cavern",
      flavorText: "The ceiling threatens to fall with every heavy blow."
    ))
  return NavigationStack {
    CompendiumBrowserView()
  }
  .environment(compendium)
}

#Preview("From Builder (with selection)") {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  return NavigationStack {
    CompendiumBrowserView(
      onSelect: { adversary in print("Selected: \(adversary.name)") },
      onSelectEnvironment: { env in print("Selected: \(env.name)") }
    )
  }
  .environment(compendium)
}
