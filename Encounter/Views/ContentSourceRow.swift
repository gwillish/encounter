//
//  ContentSourceRow.swift
//  Encounter
//
//  A single row in the content sources list showing a registered ContentSource.
//

import SwiftUI

struct ContentSourceRow: View {
  let source: ContentSource

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(source.name)
        .font(.body)
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
      HStack(spacing: 8) {
        LastFetchedLabel(lastFetched: source.lastFetched)
        if source.isThrottled() {
          Text("Fetch paused")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var subtitle: String {
    if source.isLocalImport {
      return "Imported from file"
    } else if let url = source.url {
      return url.absoluteString
    } else {
      return "Unknown source"
    }
  }
}

#Preview("Local import") {
  List {
    ContentSourceRow(
      source: ContentSource(
        id: "sample-homebrew",
        name: "sample-homebrew",
        importedAt: Date().addingTimeInterval(-3600)
      ))
  }
}

#Preview("Remote source") {
  let url = URL(string: "https://example.com/expanded.dhpack")
  List {
    if let url {
      ContentSourceRow(
        source: ContentSource(
          id: "expanded-compendium",
          name: "Expanded Adversary Compendium",
          url: url,
          lastFetched: Date().addingTimeInterval(-86400)
        ))
    }
  }
}
