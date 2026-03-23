//
//  EncounterErrorBanner.swift
//  Encounter
//
//  Non-blocking error banner shown at the top of a screen.
//

import SwiftUI

struct EncounterErrorBanner: View {
  let message: String
  let onDismiss: () -> Void

  var body: some View {
    HStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.yellow)
        .accessibilityHidden(true)
      Text(message)
        .font(.footnote)
      Spacer()
      Button("Dismiss", action: onDismiss)
        .font(.footnote)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(.thinMaterial)
  }
}

#Preview {
  EncounterErrorBanner(message: "Could not load encounters.", onDismiss: {})
}
