//
//  EnvironmentRow.swift
//  Encounter
//
//  A single row in the environment list: name, description preview, homebrew badge.
//

import DHKit
import DHModels
import SwiftUI

struct EnvironmentRow: View {
  let environment: DaggerheartEnvironment

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(environment.name)
          .font(.body)
        if environment.isHomebrew {
          Text(environment.source)
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.blue)
            .clipShape(.capsule)
        }
      }
      Text(environment.description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  EnvironmentRow(
    environment: DaggerheartEnvironment(
      id: "collapsing-cavern",
      name: "Collapsing Cavern",
      flavorText: "The ceiling threatens to fall with every heavy blow."
    )
  )
  .padding()
}
