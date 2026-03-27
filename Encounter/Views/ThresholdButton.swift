//
//  ThresholdButton.swift
//  Encounter
//
//  A button in the adversary runner card that applies a hit threshold's
//  HP mark count to an adversary slot.
//

import DaggerheartKit
import DaggerheartModels
import SwiftUI

/// Applies a Daggerheart hit threshold (Minor/Major/Severe) to an adversary slot.
///
/// Displays the hit label and the damage range subtitle, and is disabled
/// when the slot is already defeated.
struct ThresholdButton: View {
  let label: String
  let subtitle: String
  let marks: Int
  let isDefeated: Bool
  let session: EncounterSession
  let slotID: UUID

  var body: some View {
    Button {
      session.applyDamage(marks, to: slotID)
    } label: {
      VStack(spacing: 2) {
        Text(label)
          .font(.subheadline)
          .bold()
        Text(subtitle)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .disabled(isDefeated)
    .accessibilityIdentifier("runner.threshold.\(label.lowercased())")
  }
}
