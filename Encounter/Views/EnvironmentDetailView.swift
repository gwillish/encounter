//
//  EnvironmentDetailView.swift
//  Encounter
//
//  Full detail card for a single environment.
//  When onSelect is provided, an "Add to Encounter" toolbar button is shown.
//

import SwiftUI

struct EnvironmentDetailView: View {
  let environment: DaggerheartEnvironment
  let onSelect: ((DaggerheartEnvironment) -> Void)?

  @Environment(\.dismiss) private var dismiss

  init(environment: DaggerheartEnvironment, onSelect: ((DaggerheartEnvironment) -> Void)? = nil) {
    self.environment = environment
    self.onSelect = onSelect
  }

  var body: some View {
    List {
      // Identity
      Section {
        VStack(alignment: .leading, spacing: 6) {
          if environment.source != "srd" {
            Text(environment.source)
              .font(.caption2)
              .foregroundStyle(.white)
              .padding(.horizontal, 5)
              .padding(.vertical, 2)
              .background(.blue)
              .clipShape(.capsule)
          }
          Text(environment.description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }

      // Features grouped: passives → actions → reactions
      FeatureSectionsView(features: environment.features)
    }
    .navigationTitle(environment.name)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.large)
    #endif
    .toolbar {
      if let onSelect {
        ToolbarItem(placement: .primaryAction) {
          Button("Add to Encounter") {
            onSelect(environment)
            dismiss()
          }
          .accessibilityIdentifier("compendium.add-to-encounter-button")
        }
      }
    }
  }

}

#Preview {
  NavigationStack {
    EnvironmentDetailView(
      environment: DaggerheartEnvironment(
        id: "collapsing-cavern",
        name: "Collapsing Cavern",
        description:
          "The ceiling threatens to fall with every heavy blow. Whenever a Severe hit is dealt, roll 1d6 — on a 1–3, a section collapses.",
        features: [
          AdversaryFeature(
            name: "Cave-In",
            text:
              "When a Severe hit is dealt, roll 1d6. On 1–3, creatures in the area make an Agility roll against DC 14 or take 2d8 physical damage.",
            featType: .reaction)
        ]
      ))
  }
}
