//
//  AdversaryStatReference.swift
//  Encounter
//
//  Compact stat block shown at the bottom of AdversaryRunnerCard.
//  Includes core stats, attack info, and the adversary's feature list.
//

import SwiftUI

/// Compact stat reference shown in the expanded adversary runner card.
///
/// Displays difficulty, damage thresholds, attack info, damage expression,
/// and the full feature list. Preceded by a visual divider.
struct AdversaryStatReference: View {
  let adversary: Adversary

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Divider()
      LabeledContent("Difficulty", value: "\(adversary.difficulty)")
        .font(.caption)
      LabeledContent("Thresholds") {
        Text("\(adversary.thresholdMajor) / \(adversary.thresholdSevere)")
      }
      .font(.caption)
      LabeledContent("Attack") {
        Text(
          "\(adversary.attackName) \(adversary.attackModifier) · \(adversary.attackRange.rawValue)")
      }
      .font(.caption)
      LabeledContent("Damage", value: adversary.damage)
        .font(.caption)
      if !adversary.features.isEmpty {
        Divider()
        ForEach(adversary.features) { AdversaryFeatureRow(feature: $0) }
      }
    }
  }
}
