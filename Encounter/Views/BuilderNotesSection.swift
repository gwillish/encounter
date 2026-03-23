//
//  BuilderNotesSection.swift
//  Encounter
//
//  Collapsible notes section inside EncounterBuilderView.
//  Collapsed by default; onChange fires save() on every keystroke.
//

import SwiftUI

struct BuilderNotesSection: View {
  @Binding var notes: String
  @Binding var isExpanded: Bool
  let onChange: () -> Void

  var body: some View {
    Section {
      DisclosureGroup("Notes", isExpanded: $isExpanded) {
        TextEditor(text: $notes)
          .frame(minHeight: 100)
          .onChange(of: notes) { _, _ in onChange() }
          .accessibilityIdentifier("builder.notes-field")
      }
    }
  }
}

#Preview {
  @Previewable @State var notes = ""
  @Previewable @State var isExpanded = false
  return Form {
    BuilderNotesSection(notes: $notes, isExpanded: $isExpanded, onChange: {})
  }
}
