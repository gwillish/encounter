//
//  LastFetchedLabel.swift
//  Encounter
//
//  Caption-sized label showing when a ContentSource was last fetched.
//

import DHKit
import DHModels
import SwiftUI

struct LastFetchedLabel: View {
  let lastFetched: Date?

  var body: some View {
    if let date = lastFetched {
      Text("Last updated \(Text(date, style: .relative)) ago")
        .font(.caption2)
        .foregroundStyle(.secondary)
    } else {
      Text("Never updated")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }
}
