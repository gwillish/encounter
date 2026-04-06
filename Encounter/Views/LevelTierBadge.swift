//
//  LevelTierBadge.swift
//  Encounter
//
//  Compact level + tier label used in party and roster rows.
//

import DHModels
import SwiftUI

struct LevelTierBadge: View {
  let level: Int

  var body: some View {
    let tier = DifficultyBudget.tier(forLevel: level)
    Text("Lv \(level) · T\(tier)")
      .font(.caption)
      .foregroundStyle(.secondary)
      .accessibilityLabel("Level \(level), Tier \(tier)")
  }
}
