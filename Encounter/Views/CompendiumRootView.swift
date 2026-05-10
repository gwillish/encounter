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

  extension UTType {
    // Force-unwrap is intentional: type is declared in this app's Info.plist.
    // A nil result means the identifier was mistyped — crash loudly at dev time.
    fileprivate static let dhpack = UTType("gwillish.Encounter.dhpack")!
  }

  struct CompendiumRootView: View {
    let compendium: Compendium
    let contentStore: ContentStore

    @State private var searchText = ""
    @State private var selectedTier: Int?
    @State private var selectedType: AdversaryType?
    @State private var isImporting = false
    @State private var isAddingAdversary = false
    @State private var isExporting = false

    // MARK: - Derived sections

    private var srdAdversaries: [Adversary] {
      compendium.adversaries
        .filter { $0.source == "srd" }
        .filtered(searchText: searchText, tier: selectedTier, type: selectedType)
    }

    // Groups non-SRD, non-homebrew adversaries by their source tag.
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

    private var hasLocalAdversaries: Bool {
      !compendium.homebrewAdversaries.isEmpty
    }

    // MARK: - Body

    var body: some View {
      List {
        if !srdAdversaries.isEmpty {
          Section("SRD") {
            ForEach(srdAdversaries) { adversary in
              NavigationLink(value: adversary) {
                AdversaryRow(adversary: adversary)
              }
              .accessibilityIdentifier("compendium.adversary-row.\(adversary.id)")
            }
          }
        }

        ForEach(sourcePackSections, id: \.id) { section in
          Section(section.title) {
            ForEach(section.adversaries) { adversary in
              NavigationLink(value: adversary) {
                AdversaryRow(adversary: adversary)
              }
              .accessibilityIdentifier("compendium.adversary-row.\(adversary.id)")
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
      .navigationDestination(for: Adversary.self) { adversary in
        AdversaryDetailView(adversary: adversary)
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        filterBarHeader
      }
      .accessibilityIdentifier("compendium.root")
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button("Add Adversary", systemImage: "plus") {
            isAddingAdversary = true
          }
          .accessibilityIdentifier("compendium.root.add-adversary-button")

          Button("Import DHPack", systemImage: "square.and.arrow.down") {
            isImporting = true
          }
          .accessibilityIdentifier("compendium.root.import-button")

          Button("Export Local", systemImage: "square.and.arrow.up") {
            isExporting = true
          }
          .disabled(!hasLocalAdversaries)
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
          defer { url.stopAccessingSecurityScopedResource() }
          await contentStore.importPack(from: url)
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
