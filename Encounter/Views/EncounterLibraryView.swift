//
//  EncounterLibraryView.swift
//  Encounter
//
//  Browse, create, rename, and delete encounter definitions.
//

import SwiftUI

struct EncounterLibraryView: View {
    @Environment(EncounterStore.self) private var store

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
                    onDelete: beginDelete
                )
            }
        }
        .navigationTitle("Encounters")
        .toolbar { toolbarContent }
        // Create alert
        .alert("New Encounter", isPresented: $isCreating) {
            TextField("Encounter name", text: $newName)
            Button("Create") { createEncounter() }
            Button("Cancel", role: .cancel) { newName = "" }
        }
        // Rename alert — uses presenting: to avoid Binding(get:set:)
        .alert("Rename Encounter", isPresented: $isRenaming, presenting: renameTarget) { _ in
            TextField("Name", text: $renameText)
            Button("Rename") { commitRename() }
            Button("Cancel", role: .cancel) { }
        }
        // Delete confirmation — uses presenting: to avoid Binding(get:set:)
        .confirmationDialog(
            "Delete Encounter?",
            isPresented: $isConfirmingDelete,
            presenting: deleteTarget
        ) { target in
            Button("Delete \"\(target.name)\"", role: .destructive) { commitDelete() }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("This action cannot be undone.")
        }
        // Reset dismissed flag whenever a new load cycle begins, so fresh errors surface.
        .onChange(of: store.isLoading) {
            if store.isLoading { loadErrorDismissed = false }
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
        }
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
        EncounterLibraryView(selection: $selection)
    }
    .environment(EncounterStore(directory: .temporaryDirectory))
}
