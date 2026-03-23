//
//  AdversaryFeatureRow.swift
//  Encounter
//
//  A single adversary or environment feature row: name, type badge, description text.
//  Used in both AdversaryDetailView and EnvironmentDetailView.
//

import SwiftUI

struct AdversaryFeatureRow: View {
  let feature: AdversaryFeature

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        Text(feature.name)
          .font(.subheadline)
          .fontWeight(.semibold)
        Text(feature.featType.rawValue.capitalized)
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
    feature: AdversaryFeature(
      name: "Pack Tactics",
      text: "Deal +1 damage for each ally adjacent to the target.",
      featType: .passive
    )
  )
  .padding()
}
