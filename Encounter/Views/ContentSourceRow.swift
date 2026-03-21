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
                lastFetchedLabel
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

    @ViewBuilder
    private var lastFetchedLabel: some View {
        if let date = source.lastFetched {
            Text("Last updated ")
                .font(.caption2)
                .foregroundStyle(.secondary)
            + Text(date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.secondary)
            + Text(" ago")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            Text("Never updated")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Local import") {
    List {
        ContentSourceRow(source: ContentSource(
            id: "sample-homebrew",
            name: "sample-homebrew",
            importedAt: Date().addingTimeInterval(-3600)
        ))
    }
}

#Preview("Remote source") {
    List {
        ContentSourceRow(source: ContentSource(
            id: "expanded-compendium",
            name: "Expanded Adversary Compendium",
            url: URL(string: "https://example.com/expanded.dhpack")!,
            lastFetched: Date().addingTimeInterval(-86400)
        ))
    }
}
