//
//  SourceBadgeView.swift
//  Encounter
//
//  Small blue capsule badge showing a homebrew content source name.
//  Used in adversary and environment rows and detail views.
//

import SwiftUI

/// A small capsule badge displaying a homebrew content source label.
struct SourceBadgeView: View {
  let label: String

  var body: some View {
    Text(label)
      .font(.caption2)
      .foregroundStyle(.white)
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .background(.blue)
      .clipShape(.capsule)
  }
}

#Preview {
  HStack {
    SourceBadgeView(label: "my-homebrew")
    SourceBadgeView(label: "Expanded Compendium")
  }
  .padding()
}
