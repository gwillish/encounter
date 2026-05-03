//
//  TypeBadgeView.swift
//  Encounter
//
//  Capsule badge showing an adversary's role type (e.g. "Minion", "Bruiser").
//

import DHModels
import SwiftUI

/// A small capsule badge displaying an adversary's role type.
struct TypeBadgeView: View {
  let type: AdversaryType

  var body: some View {
    Text(type.rawValue)
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(.secondary.opacity(0.15))
      .clipShape(.capsule)
  }
}

#Preview {
  HStack {
    TypeBadgeView(type: .minion)
    TypeBadgeView(type: .solo)
    TypeBadgeView(type: .bruiser)
  }
  .padding()
}
