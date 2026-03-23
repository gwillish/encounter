//
//  EncounterLibraryEmptyState.swift
//  Encounter
//
//  Empty-state placeholder shown when no encounter definitions exist.
//

import SwiftUI

struct EncounterLibraryEmptyState: View {
  let onCreateTapped: () -> Void

  var body: some View {
    ContentUnavailableView {
      Label("No Encounters", systemImage: "list.bullet.clipboard")
    } description: {
      Text("Create your first encounter to get started.")
    } actions: {
      Button("Create Encounter", action: onCreateTapped)
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("library.create-button")
    }
  }
}

#Preview {
  EncounterLibraryEmptyState(onCreateTapped: {})
}
