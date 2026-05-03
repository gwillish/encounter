//
//  AdversaryRosterRow.swift
//  Encounter
//
//  Single row in the adversary roster inside EncounterBuilderView.
//  Looks up the adversary by ID for display; shows a fallback if unresolvable.
//  When partyTier is provided, off-tier adversaries show a TierBadgeView.
//

import DHKit
import DHModels
import SwiftUI

struct AdversaryRosterRow: View {
  let adversaryID: String
  let compendium: Compendium
  let partyTier: Int?

  private var adversary: Adversary? {
    compendium.adversary(id: adversaryID)
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(adversary?.name ?? "Unknown Adversary")
          .font(.body)
        if let adversary {
          Text("\(adversary.role.rawValue) · Tier \(adversary.tier)")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          Text("ID: \(adversaryID)")
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
      }
      Spacer()
      if let adversary, let pt = partyTier, adversary.tier != pt {
        TierBadgeView(adversaryTier: adversary.tier, partyTier: pt)
      }
    }
    .padding(.vertical, 2)
  }
}

#Preview("No party tier") {
  let compendium = Compendium()
  compendium.addAdversary(
    Adversary(
      id: "goblin", name: "Goblin", tier: 1, role: .minion,
      flavorText: "Small and cunning.", difficulty: 10,
      thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
      attackModifier: "+2", attackName: "Rusty Blade",
      attackRange: .veryClose, damage: "1d4 phy"
    ))
  return List {
    AdversaryRosterRow(adversaryID: "goblin", compendium: compendium, partyTier: nil)
    AdversaryRosterRow(adversaryID: "missing-id", compendium: compendium, partyTier: nil)
  }
}

#Preview("T2 party — mixed tiers") {
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
  compendium.addAdversary(
    Adversary(
      id: "dragon", name: "Young Dragon", tier: 3, role: .solo,
      flavorText: "Barely contained fury.", difficulty: 18,
      thresholdMajor: 15, thresholdSevere: 30, hp: 20, stress: 6,
      attackModifier: "+8", attackName: "Flame Breath",
      attackRange: .far, damage: "4d10 fir"
    ))
  return List {
    AdversaryRosterRow(adversaryID: "goblin", compendium: compendium, partyTier: 2)
    AdversaryRosterRow(adversaryID: "orc", compendium: compendium, partyTier: 2)
    AdversaryRosterRow(adversaryID: "dragon", compendium: compendium, partyTier: 2)
  }
}
