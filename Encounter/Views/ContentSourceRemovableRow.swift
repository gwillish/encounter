//
//  ContentSourceRemovableRow.swift
//  Encounter
//
//  ContentSourceRow decorated with swipe-to-delete (iOS) and a context menu
//  remove action, used in ContentSourcesView.
//

import SwiftUI

struct ContentSourceRemovableRow: View {
  let source: ContentSource
  let onRemove: (ContentSource) -> Void

  var body: some View {
    ContentSourceRow(source: source)
      #if os(iOS)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button(role: .destructive) {
            onRemove(source)
          } label: {
            Label("Remove", systemImage: "trash")
          }
        }
      #endif
      .contextMenu {
        Button(role: .destructive) {
          onRemove(source)
        } label: {
          Label("Remove", systemImage: "trash")
        }
      }
  }
}
