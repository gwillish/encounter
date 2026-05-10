//
//  CompendiumRootView.swift
//  Encounter
//
//  iOS compendium root: grouped adversary list with filter, import, and export.
//  Shown when the root mode toggle is set to .compendium.
//

#if !os(macOS)

  import DHKit
  import DHModels
  import SwiftUI
  import UniformTypeIdentifiers

  struct CompendiumRootView: View {
    let compendium: Compendium
    let contentStore: ContentStore

    @State private var searchText = ""
    @State private var selectedTier: Int?
    @State private var selectedType: AdversaryType?
    @State private var isImporting = false

    // MARK: - Derived sections

    private var srdAdversaries: [Adversary] {
      compendium.adversaries
        .filter { $0.source == "srd" }
        .filtered(searchText: searchText, tier: selectedTier, type: selectedType)
    }

    // Groups non-SRD, non-homebrew adversaries by their `source` tag.
    // importPack rejects sourceIDs in the reserved set {"srd","sources","homebrew"}, so
    // correctly-imported packs cannot collide with the SRD or Local sections here.
    //
    // Looks up ContentStore.sources[sourceKey] for a display name; falls back
    // to capitalising the raw source value if no registered source matches.
    private var sourcePackSections: [(id: String, title: String, adversaries: [Adversary])] {
      let homebrewIDs = Set(compendium.homebrewAdversaries.map { $0.id })
      let packAdversaries = compendium.adversaries
        .filter { $0.source != "srd" && !homebrewIDs.contains($0.id) }
        .filtered(searchText: searchText, tier: selectedTier, type: selectedType)

      var grouped: [String: [Adversary]] = [:]
      for adversary in packAdversaries {
        grouped[adversary.source, default: []].append(adversary)
      }

      return
        grouped
        .map { sourceKey, adversaries in
          let title =
            contentStore.sources[sourceKey]?.name
            ?? sourceKey.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
          return (
            id: sourceKey, title: title, adversaries: adversaries.sorted { $0.name < $1.name }
          )
        }
        .sorted { $0.title < $1.title }
    }

    private var localAdversaries: [Adversary] {
      compendium.homebrewAdversaries
        .filtered(searchText: searchText, tier: selectedTier, type: selectedType)
    }

    // MARK: - Body

    var body: some View {
      List {
        if !srdAdversaries.isEmpty {
          Section {
            ForEach(srdAdversaries) { adversary in
              NavigationLink(value: adversary) {
                AdversaryRow(adversary: adversary)
              }
              .accessibilityIdentifier("compendium.adversary-row.\(adversary.id)")
            }
          } header: {
            Text("SRD")
              .accessibilityLabel("System Reference Document")
          }
        }

        ForEach(sourcePackSections, id: \.id) { section in
          if !section.adversaries.isEmpty {
            Section(section.title) {
              ForEach(section.adversaries) { adversary in
                NavigationLink(value: adversary) {
                  AdversaryRow(adversary: adversary)
                }
                .accessibilityIdentifier("compendium.adversary-row.\(adversary.id)")
              }
            }
          }
        }

        if !localAdversaries.isEmpty {
          Section("Local") {
            ForEach(localAdversaries) { adversary in
              NavigationLink(value: adversary) {
                AdversaryRow(adversary: adversary)
              }
              .accessibilityIdentifier("compendium.adversary-row.\(adversary.id)")
            }
          }
        }
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        filterBarHeader
      }
      .accessibilityIdentifier("compendium.root")
      .toolbar {
        // Add Adversary — disabled until AdversaryCreatorForm is implemented.
        ToolbarItem(placement: .primaryAction) {
          Button("Add Adversary", systemImage: "plus") {
            // TODO: present AdversaryCreatorForm
          }
          .disabled(true)
          .accessibilityHint("Coming soon")
          .accessibilityIdentifier("compendium.root.add-adversary-button")
        }
        ToolbarItem(placement: .primaryAction) {
          Button("Import DHPack", systemImage: "square.and.arrow.down") {
            isImporting = true
          }
          .accessibilityIdentifier("compendium.root.import-button")
        }
        // Export enabled when any local adversaries exist, regardless of active filters.
        // Disabled until DHPackExportSheet is implemented.
        ToolbarItem(placement: .primaryAction) {
          Button("Export Local", systemImage: "square.and.arrow.up") {
            // TODO: present DHPackExportSheet
          }
          .disabled(compendium.homebrewAdversaries.isEmpty)
          .accessibilityHint(
            compendium.homebrewAdversaries.isEmpty ? "No local adversaries to export" : ""
          )
          .accessibilityIdentifier("compendium.root.export-button")
        }
      }
      .fileImporter(
        isPresented: $isImporting,
        allowedContentTypes: [.dhpack]
      ) { result in
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        Task { @MainActor in
          await contentStore.importPack(from: url)
          url.stopAccessingSecurityScopedResource()
        }
      }
    }

    // MARK: - Subviews

    private var filterBarHeader: some View {
      VStack(spacing: 0) {
        AdversaryFilterBar(
          searchText: $searchText,
          selectedTier: $selectedTier,
          selectedType: $selectedType
        )
        Divider()
      }
      .background(.regularMaterial)
    }
  }

  #Preview("SRD adversaries") {
    let compendium = Compendium()
    compendium.replaceSRDContent(
      adversaries: [
        Adversary(
          id: "goblin", name: "Goblin", tier: 1, role: .minion,
          flavorText: "Small and cunning.", difficulty: 10,
          thresholdMajor: 5, thresholdSevere: 10, hp: 3, stress: 2,
          attackModifier: "+2", attackName: "Rusty Blade",
          attackRange: .veryClose, damage: "1d4 phy"
        ),
        Adversary(
          id: "orc", name: "Orc Bruiser", tier: 2, role: .bruiser,
          flavorText: "Massive and relentless.", difficulty: 14,
          thresholdMajor: 10, thresholdSevere: 20, hp: 8, stress: 4,
          attackModifier: "+5", attackName: "Great Axe",
          attackRange: .veryClose, damage: "2d10+4 phy"
        ),
      ],
      environments: []
    )
    return NavigationStack {
      CompendiumRootView(
        compendium: compendium,
        contentStore: PreviewData.contentStore(compendium: compendium)
      )
    }
  }

  #Preview("Empty compendium") {
    NavigationStack {
      CompendiumRootView(
        compendium: PreviewData.compendium(),
        contentStore: PreviewData.contentStore()
      )
    }
  }

#endif
