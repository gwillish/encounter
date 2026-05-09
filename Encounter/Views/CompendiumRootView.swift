//
//  CompendiumRootView.swift
//  Encounter
//
//  iOS compendium root: grouped adversary list with filter, import, and export.
//  Full implementation in #109; this is a placeholder stub.
//

#if !os(macOS)

  import DHKit
  import DHModels
  import SwiftUI

  struct CompendiumRootView: View {
    let compendium: Compendium
    let contentStore: ContentStore

    var body: some View {
      ContentUnavailableView(
        "Compendium",
        systemImage: "books.vertical",
        description: Text("Full compendium view coming soon.")
      )
    }
  }

  #Preview {
    CompendiumRootView(
      compendium: PreviewData.compendium(),
      contentStore: PreviewData.contentStore()
    )
  }

#endif
