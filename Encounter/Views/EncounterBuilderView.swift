//
//  EncounterBuilderView.swift
//  Encounter
//
//  Full encounter preparation screen.
//  Manages a local draft copy of the EncounterDefinition and auto-saves
//  after every mutation via EncounterStore.
//
//  Step 4 seam: Run Encounter button is present but disabled until
//  EncounterRunnerView is implemented.
//

import SwiftUI

struct EncounterBuilderView: View {
    let definition: EncounterDefinition

    @State private var draft: EncounterDefinition
    @Environment(EncounterStore.self) private var store
    @Environment(Compendium.self) private var compendium

    @State private var showCompendium = false
    @State private var showAddPlayer = false
    @State private var notesExpanded = false
    @State private var manualAdjustments: Set<DifficultyBudget.Adjustment> = []
    @State private var saveError: String?

    init(definition: EncounterDefinition) {
        self.definition = definition
        _draft = State(initialValue: definition)
    }

    // MARK: - Computed difficulty

    private var adversaryTypes: [AdversaryType] {
        draft.adversaryIDs.compactMap { compendium.adversary(id: $0)?.type }
    }

    private var autoAdjustments: Set<DifficultyBudget.Adjustment> {
        DifficultyBudget.suggestedAdjustments(adversaryTypes: adversaryTypes)
    }

    private var budgetAdjustment: Int {
        autoAdjustments.union(manualAdjustments).reduce(0) { $0 + $1.pointValue }
    }

    private var difficultyRating: DifficultyBudget.Rating {
        DifficultyBudget.rating(
            adversaryTypes: adversaryTypes,
            playerCount: draft.playerConfigs.count,
            budgetAdjustment: budgetAdjustment
        )
    }

    // MARK: - Body

    var body: some View {
        Form {
            AdversaryRosterSection(
                adversaryIDs: draft.adversaryIDs,
                compendium: compendium,
                onBrowse: { showCompendium = true },
                onRemove: removeAdversary(at:)
            )
            EnvironmentSection(
                environmentIDs: draft.environmentIDs,
                compendium: compendium,
                onBrowse: { showCompendium = true },
                onRemove: removeEnvironment(at:)
            )
            PlayerRosterSection(
                playerConfigs: draft.playerConfigs,
                onAddPlayer: { showAddPlayer = true },
                onRemove: removePlayer(at:)
            )
            BuilderNotesSection(
                notes: $draft.gmNotes,
                isExpanded: $notesExpanded,
                onChange: save
            )
        }
        .navigationTitle(draft.name)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) {
            DifficultyAssessorView(
                rating: difficultyRating,
                autoAdjustments: autoAdjustments,
                manualAdjustments: $manualAdjustments
            )
        }
        .safeAreaInset(edge: .top) {
            if let error = saveError {
                EncounterErrorBanner(message: error, onDismiss: { saveError = nil })
            }
        }
        .sheet(isPresented: $showCompendium) {
            NavigationStack {
                CompendiumBrowserView(
                    onSelect: { adversary in
                        addAdversary(adversary)
                        showCompendium = false
                    },
                    onSelectEnvironment: { environment in
                        setEnvironment(environment)
                        showCompendium = false
                    }
                )
            }
            .environment(compendium)
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerForm { config in
                addPlayer(config)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Run Encounter") {}
                .disabled(true)
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Browse Compendium", systemImage: "books.vertical") {
                showCompendium = true
            }
        }
    }

    // MARK: - Mutations

    private func addAdversary(_ adversary: Adversary) {
        draft.adversaryIDs.append(adversary.id)
        save()
    }

    private func removeAdversary(at offsets: IndexSet) {
        draft.adversaryIDs.remove(atOffsets: offsets)
        save()
    }

    private func setEnvironment(_ environment: DaggerheartEnvironment) {
        draft.environmentIDs = [environment.id]
        save()
    }

    private func removeEnvironment(at offsets: IndexSet) {
        draft.environmentIDs.remove(atOffsets: offsets)
        save()
    }

    private func addPlayer(_ config: PlayerConfig) {
        draft.playerConfigs.append(config)
        save()
    }

    private func removePlayer(at offsets: IndexSet) {
        draft.playerConfigs.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        Task {
            do {
                try await store.save(draft)
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}

#Preview {
    let store = EncounterStore(directory: URL.temporaryDirectory.appending(path: "preview-builder"))
    let compendium = Compendium()
    compendium.addAdversary(Adversary(
        id: "goblin", name: "Goblin", tier: 1, type: .minion,
        description: "Small and cunning.", difficulty: 10,
        thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
        attackModifier: "+2", attackName: "Rusty Blade",
        attackRange: .veryClose, damage: "1d4 phy"
    ))
    compendium.addAdversary(Adversary(
        id: "orc", name: "Orc Bruiser", tier: 2, type: .bruiser,
        description: "Massive and relentless.", difficulty: 14,
        thresholdMajor: 10, thresholdSevere: 20, hp: 8, stress: 4,
        attackModifier: "+5", attackName: "Great Axe",
        attackRange: .veryClose, damage: "2d10+4 phy"
    ))
    return NavigationStack {
        // Create and inject a matching definition so auto-save succeeds in preview
        EncounterBuilderPreviewWrapper()
    }
    .environment(store)
    .environment(compendium)
}

/// Preview wrapper that creates a definition in the store before showing the builder.
private struct EncounterBuilderPreviewWrapper: View {
    @Environment(EncounterStore.self) private var store
    @State private var definition: EncounterDefinition?

    var body: some View {
        Group {
            if let definition {
                EncounterBuilderView(definition: definition)
            } else {
                ProgressView()
                    .task {
                        try? await store.create(name: "Goblin Ambush")
                        definition = store.definitions.first
                    }
            }
        }
    }
}
