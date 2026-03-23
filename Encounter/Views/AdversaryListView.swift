//
//  AdversaryListView.swift
//  Encounter
//
//  Filtered list of adversaries. Navigation destinations are registered
//  on the parent CompendiumBrowserView so they persist across tab switches.
//

import SwiftUI

struct AdversaryListView: View {
  let adversaries: [Adversary]

  var body: some View {
    if adversaries.isEmpty {
      ContentUnavailableView(
        "No Adversaries",
        systemImage: "magnifyingglass",
        description: Text("Try a different search or filter.")
      )
    } else {
      List(adversaries) { adversary in
        NavigationLink(value: adversary) {
          AdversaryRow(adversary: adversary)
        }
        .accessibilityIdentifier("compendium.adversary-row")
        .accessibilityValue(adversary.name)
      }
      .accessibilityIdentifier("compendium.adversary-list")
    }
  }
}

#Preview("With results") {
  NavigationStack {
    AdversaryListView(adversaries: [
      Adversary(
        id: "goblin", name: "Goblin", tier: 1, type: .minion,
        description: "Small and cunning.", difficulty: 10,
        thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
        attackModifier: "+2", attackName: "Rusty Blade",
        attackRange: .veryClose, damage: "1d4 phy"),
      Adversary(
        id: "orc", name: "Orc Bruiser", tier: 2, type: .bruiser,
        description: "Massive and relentless.", difficulty: 14,
        thresholdMajor: 10, thresholdSevere: 20, hp: 8, stress: 4,
        attackModifier: "+5", attackName: "Great Axe",
        attackRange: .veryClose, damage: "2d10+4 phy"),
    ])
  }
}

#Preview("Empty") {
  NavigationStack {
    AdversaryListView(adversaries: [])
  }
}
