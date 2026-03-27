//
//  EnvironmentListView.swift
//  Encounter
//
//  Filtered list of environments. Navigation destinations are registered
//  on the parent CompendiumBrowserView so they persist across tab switches.
//

import DaggerheartKit
import DaggerheartModels
import SwiftUI

struct EnvironmentListView: View {
  let environments: [DaggerheartEnvironment]

  var body: some View {
    if environments.isEmpty {
      ContentUnavailableView(
        "No Environments",
        systemImage: "magnifyingglass",
        description: Text("Try a different search term.")
      )
    } else {
      List(environments) { environment in
        NavigationLink(value: environment) {
          EnvironmentRow(environment: environment)
        }
        .accessibilityIdentifier("compendium.environment-row")
        .accessibilityValue(environment.name)
      }
      .accessibilityIdentifier("compendium.environment-list")
    }
  }
}

#Preview("With results") {
  NavigationStack {
    EnvironmentListView(environments: [
      DaggerheartEnvironment(
        id: "collapsing-cavern", name: "Collapsing Cavern",
        description: "The ceiling threatens to fall with every heavy blow."),
      DaggerheartEnvironment(
        id: "burning-bridge", name: "Burning Bridge",
        description: "The planks crumble underfoot as flames spread."),
    ])
  }
}

#Preview("Empty") {
  NavigationStack {
    EnvironmentListView(environments: [])
  }
}
