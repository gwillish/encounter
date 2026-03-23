//
//  ContentSourcesView.swift
//  Encounter
//
//  Lists all registered content sources and lets the GM remove any of them.
//

import SwiftUI

struct ContentSourcesView: View {
  @Environment(ContentStore.self) private var contentStore
  @Environment(\.dismiss) private var dismiss

  @State private var removeTarget: ContentSource?
  @State private var isConfirmingRemove = false

  private var sortedSources: [ContentSource] {
    contentStore.sources.values.sorted { $0.name < $1.name }
  }

  private var localImports: [ContentSource] {
    sortedSources.filter { $0.isLocalImport }
  }

  private var remoteSources: [ContentSource] {
    sortedSources.filter { !$0.isLocalImport }
  }

  var body: some View {
    Group {
      if contentStore.sources.isEmpty {
        ContentUnavailableView {
          Label("No Content Packs", systemImage: "archivebox")
        } description: {
          Text("Import a .dhpack file or add a remote source URL to get started.")
        }
      } else {
        List {
          if !localImports.isEmpty {
            Section("Local Imports") {
              ForEach(localImports) { source in
                ContentSourceRemovableRow(source: source, onRemove: beginRemove)
              }
            }
          }
          if !remoteSources.isEmpty {
            Section("Remote Sources") {
              ForEach(remoteSources) { source in
                ContentSourceRemovableRow(source: source, onRemove: beginRemove)
              }
            }
          }
        }
      }
    }
    .navigationTitle("Content Sources")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") { dismiss() }
      }
    }
    .confirmationDialog(
      "Remove \"\(removeTarget?.name ?? "")\"?",
      isPresented: $isConfirmingRemove,
      presenting: removeTarget
    ) { source in
      Button("Remove", role: .destructive) { commitRemove(source) }
      Button("Cancel", role: .cancel) {}
    } message: { _ in
      Text("All adversaries and environments from this pack will be removed immediately.")
    }
  }

  private func beginRemove(_ source: ContentSource) {
    removeTarget = source
    isConfirmingRemove = true
  }

  private func commitRemove(_ source: ContentSource) {
    removeTarget = nil
    Task {
      await contentStore.removeSource(id: source.id)
    }
  }
}

#Preview("Empty") {
  NavigationStack {
    ContentSourcesView()
  }
  .environment(
    ContentStore(
      contentDirectory: .temporaryDirectory,
      compendium: Compendium()
    ))
}

#Preview("With sources") {
  let store = ContentStore(
    contentDirectory: .temporaryDirectory,
    compendium: Compendium()
  )
  NavigationStack {
    ContentSourcesView()
  }
  .environment(store)
  .task {
    await store.addSource(
      ContentSource(
        id: "sample-homebrew",
        name: "sample-homebrew",
        importedAt: Date().addingTimeInterval(-3600)
      ))
    if let url = URL(string: "https://example.com/expanded.dhpack") {
      await store.addSource(
        ContentSource(
          id: "expanded-compendium",
          name: "Expanded Adversary Compendium",
          url: url,
          lastFetched: Date().addingTimeInterval(-86400)
        ))
    }
  }
}
