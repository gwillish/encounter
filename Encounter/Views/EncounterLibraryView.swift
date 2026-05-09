//
//  EncounterLibraryView.swift
//  Encounter
//
//  Browse, create, rename, and delete encounter definitions.
//

import DHKit
import DHModels
import SwiftUI

struct EncounterLibraryView: View {
  let store: EncounterStore
  let playerStore: PlayerStore
  let compendium: Compendium
  let contentStore: ContentStore
  let sessionRegistry: SessionRegistry
  let sessionStore: SessionStore

  @Binding var selection: EncounterDefinition.ID?
  @State private var isCreating = false
  @State private var newName = ""
  @State private var isRenaming = false
  @State private var renameTarget: EncounterDefinition?
  @State private var renameText = ""
  @State private var isConfirmingDelete = false
  @State private var deleteTarget: EncounterDefinition?
  @State private var actionError: String?
  @State private var loadErrorDismissed = false
  @State private var isShowingSources = false
  @State private var isShowingAbout = false

  private var pausedDefinitionIDs: Set<UUID> {
    Set(
      sessionRegistry.sessions.values
        .filter { $0.phase == .paused }
        .compactMap { $0.definitionID }
    )
  }

  var body: some View {
    Group {
      if store.isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if store.definitions.isEmpty {
        EncounterLibraryEmptyState(onCreateTapped: beginCreate)
      } else {
        EncounterLibraryList(
          definitions: store.definitions,
          selection: $selection,
          onRename: beginRename,
          onDelete: beginDelete,
          playerStore: playerStore,
          compendium: compendium,
          pausedDefinitionIDs: pausedDefinitionIDs
        )
      }
    }
    .navigationTitle("Encounters")
    .toolbar { toolbarContent }
    // Create alert
    .alert("New Encounter", isPresented: $isCreating) {
      TextField("Encounter name", text: $newName)
        .accessibilityIdentifier("library.new-name-field")
      Button("Create") { createEncounter() }
      Button("Cancel", role: .cancel) { newName = "" }
    }
    // Rename alert — uses presenting: to avoid Binding(get:set:)
    .alert("Rename Encounter", isPresented: $isRenaming, presenting: renameTarget) { _ in
      TextField("Name", text: $renameText)
        .accessibilityIdentifier("library.rename-field")
      Button("Rename") { commitRename() }
      Button("Cancel", role: .cancel) {}
    }
    // Delete confirmation — uses presenting: to avoid Binding(get:set:)
    .confirmationDialog(
      "Delete Encounter?",
      isPresented: $isConfirmingDelete,
      presenting: deleteTarget
    ) { target in
      Button("Delete \"\(target.name)\"", role: .destructive) { commitDelete() }
      Button("Cancel", role: .cancel) {}
    } message: { _ in
      Text("This action cannot be undone.")
    }
    // Reset dismissed flag whenever a new distinct error appears, so fresh errors surface.
    .onChange(of: store.loadError?.localizedDescription) { _, newDescription in
      if newDescription != nil { loadErrorDismissed = false }
    }
    .sheet(isPresented: $isShowingSources) {
      NavigationStack {
        ContentSourcesView(contentStore: contentStore)
      }
    }
    #if !os(macOS)
      .navigationDestination(for: EncounterDefinition.self) { definition in
        EncounterBuilderView(
          definition: definition, store: store, compendium: compendium,
          sessionRegistry: sessionRegistry, sessionStore: sessionStore,
          playerStore: playerStore
        )
      }
    #endif
    .sheet(isPresented: $isShowingAbout) {
      AboutView()
    }
    // Error banners
    .safeAreaInset(edge: .top) {
      if let error = store.loadError, !loadErrorDismissed {
        EncounterErrorBanner(
          message: error.localizedDescription,
          onDismiss: { loadErrorDismissed = true }
        )
      } else if let error = actionError {
        EncounterErrorBanner(
          message: error,
          onDismiss: { actionError = nil }
        )
      }
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button("New Encounter", systemImage: "plus", action: beginCreate)
        .accessibilityIdentifier("library.create-button")
    }
    ToolbarItem(placement: .secondaryAction) {
      Button("Content Sources", systemImage: "archivebox") {
        isShowingSources = true
      }
      .accessibilityIdentifier("library.sources-button")
    }
    #if os(iOS) || os(visionOS)
      ToolbarItem(placement: .secondaryAction) {
        Button("About", systemImage: "info.circle") {
          isShowingAbout = true
        }
        .accessibilityIdentifier("library.about-button")
      }
    #endif
  }

  // MARK: - Actions

  private func beginCreate() {
    newName = ""
    isCreating = true
  }

  private func createEncounter() {
    let name = newName.trimmingCharacters(in: .whitespaces)
    let finalName = name.isEmpty ? "New Encounter" : name
    newName = ""
    Task {
      do {
        try await store.create(name: finalName)
      } catch {
        actionError = error.localizedDescription
      }
    }
  }

  private func beginRename(_ definition: EncounterDefinition) {
    renameText = definition.name
    renameTarget = definition
    isRenaming = true
  }

  private func commitRename() {
    guard var target = renameTarget else { return }
    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }
    target.name = trimmed
    renameTarget = nil
    Task {
      do {
        try await store.save(target)
      } catch {
        actionError = error.localizedDescription
      }
    }
  }

  private func beginDelete(_ definition: EncounterDefinition) {
    deleteTarget = definition
    isConfirmingDelete = true
  }

  private func commitDelete() {
    guard let target = deleteTarget else { return }
    deleteTarget = nil
    Task {
      do {
        try await store.delete(id: target.id)
      } catch {
        actionError = error.localizedDescription
      }
    }
  }
}

#Preview {
  @Previewable @State var selection: EncounterDefinition.ID? = nil
  NavigationStack {
    EncounterLibraryView(
      store: PreviewData.encounterStore(),
      playerStore: PreviewData.playerStore(),
      compendium: PreviewData.compendium(),
      contentStore: PreviewData.contentStore(),
      sessionRegistry: PreviewData.sessionRegistry(),
      sessionStore: PreviewData.sessionStore(),
      selection: $selection
    )
  }
}
