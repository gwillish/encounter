//
//  AdversaryRunnerSection.swift
//  Encounter
//
//  ForEach over the sorted adversary slots in EncounterRunnerView.
//  Drives the accordion via the expandedSlotID binding — only one
//  card can be open at a time by design (single UUID stored).
//

import DHKit
import DHModels
import SwiftUI

struct AdversaryRunnerSection: View {
  let slots: [AdversaryState]
  @Binding var expandedSlotID: UUID?
  let session: EncounterSession
  let compendium: Compendium

  var body: some View {
    ForEach(slots) { slot in
      if expandedSlotID == slot.id && !slot.isDefeated {
        AdversaryRunnerCard(
          slot: slot,
          session: session,
          compendium: compendium,
          onCollapse: { expandedSlotID = nil }
        )
        .listRowSeparator(.hidden)
      } else {
        Button {
          expandedSlotID = slot.id
        } label: {
          AdversaryRunnerRow(slot: slot, compendium: compendium)
            .opacity(slot.isDefeated ? 0.4 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(slot.isDefeated)
        .accessibilityIdentifier("runner.adversary-row")
        .accessibilityValue(slot.customName ?? slot.adversaryID)
      }
    }
  }
}
