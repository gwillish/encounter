//
//  TierBadgeView.swift
//  Encounter
//
//  Badge indicating an adversary's tier relative to the party tier.
//  Amber = below party tier, Red = above party tier, hidden when matching or partyTier is nil.
//

import SwiftUI

struct TierBadgeView: View {
  let adversaryTier: Int
  let partyTier: Int

  @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

  private var color: Color? {
    if adversaryTier < partyTier { return .orange }
    if adversaryTier > partyTier { return .red }
    return nil
  }

  private var relationLabel: String {
    adversaryTier < partyTier ? "below party tier" : "above party tier"
  }

  var body: some View {
    if let color {
      HStack(spacing: 2) {
        if differentiateWithoutColor {
          Image(systemName: adversaryTier < partyTier ? "arrow.down" : "arrow.up")
            .font(.caption.bold())
            .accessibilityHidden(true)
        }
        Text("T\(adversaryTier)")
          .font(.caption.bold())
      }
      .foregroundStyle(color)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(color.opacity(0.12), in: Capsule())
      .accessibilityLabel("Tier \(adversaryTier), \(relationLabel)")
    }
  }
}

#Preview("Below party tier") {
  TierBadgeView(adversaryTier: 1, partyTier: 2)
    .padding()
}

#Preview("Above party tier") {
  TierBadgeView(adversaryTier: 3, partyTier: 2)
    .padding()
}

#Preview("Matching tier — hidden") {
  TierBadgeView(adversaryTier: 2, partyTier: 2)
    .padding()
}
