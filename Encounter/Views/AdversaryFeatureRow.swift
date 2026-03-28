//
//  AdversaryFeatureRow.swift
//  Encounter
//
//  A single adversary or environment feature row: name, type badge, description text.
//  Used in both AdversaryDetailView and EnvironmentDetailView.
//

import DHKit
import DHModels
import SwiftUI

struct AdversaryFeatureRow: View {
  let feature: EncounterFeature

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        Text(feature.name)
          .font(.subheadline)
          .fontWeight(.semibold)
        Text(feature.kind.rawValue.capitalized)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 5)
          .padding(.vertical, 2)
          .background(.secondary.opacity(0.15))
          .clipShape(.capsule)
      }
      Text(feature.text)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  AdversaryFeatureRow(
    feature: EncounterFeature(
      name: "Pack Tactics",
      text: "Deal +1 damage for each ally adjacent to the target.",
      kind: .passive
    )
  )
  .padding()
}
