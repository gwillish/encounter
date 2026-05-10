//
//  CompendiumRootViewTests.swift
//  EncounterTests
//

#if !os(macOS)

  import DHKit
  import DHModels
  import SwiftUI
  import Testing
  import ViewInspector

  @testable import Encounter

  @MainActor
  @Suite("CompendiumRootView")
  struct CompendiumRootViewTests {

    private static func makeAdversary(
      id: String, name: String, source: String = "srd"
    ) -> Adversary {
      Adversary(
        id: id, name: name, source: source, tier: 1, role: .minion,
        flavorText: "", difficulty: 8,
        thresholdMajor: 4, thresholdSevere: 8, hp: 3, stress: 2,
        attackModifier: "+1", attackName: "Club", attackRange: .melee, damage: "1d4 phy"
      )
    }

    // packAdversaries: injected via replaceSourceContent so they land in the pack
    // bucket of Compendium, not homebrewAdversaries.
    // localAdversaries: injected via addAdversary — the source field value is irrelevant
    // to section placement; only the addAdversary call routes them to homebrewAdversaries.
    private func makeSUT(
      srdAdversaries: [Adversary] = [],
      packAdversaries: [(sourceID: String, adversaries: [Adversary])] = [],
      localAdversaries: [Adversary] = []
    ) -> CompendiumRootView {
      let compendium = Compendium()
      compendium.replaceSRDContent(adversaries: srdAdversaries, environments: [])
      for (sourceID, adversaries) in packAdversaries {
        compendium.replaceSourceContent(
          sourceID: sourceID, adversaries: adversaries, environments: [])
      }
      for adversary in localAdversaries {
        compendium.addAdversary(adversary)
      }
      return CompendiumRootView(
        compendium: compendium,
        contentStore: PreviewData.contentStore(compendium: compendium))
    }

    // MARK: - Filter bar

    @Test func filterBarIsPresent() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("All tiers"), "AdversaryFilterBar tier picker should be present")
      #expect(texts.contains("All types"), "AdversaryFilterBar type picker should be present")
    }

    // MARK: - Adversary list
    //
    // Row content (adversary names) is not directly testable via ViewInspector because
    // NavigationLink(value:) is opaque to ViewInspector on iOS. The section-header tests
    // below serve as a proxy for "adversary list visible": sections are only rendered when
    // the filtered adversary array is non-empty.
    //
    // Filter-removes-all-results paths are not testable at this tier because @State filter
    // vars (searchText, selectedTier, selectedType) are private and cannot be set externally.

    @Test func srdSectionHeaderPresent() throws {
      let goblin = Self.makeAdversary(id: "goblin", name: "Goblin")
      let sut = makeSUT(srdAdversaries: [goblin])
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("SRD"))
    }

    @Test func srdSectionHiddenWhenNoSrdAdversaries() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(!texts.contains("SRD"), "SRD section header must not render when SRD list is empty")
    }

    @Test func packSectionHeaderPresent() throws {
      // Pack adversaries use replaceSourceContent — their source field must match
      // the sourceID for the fallback section title to capitalise correctly.
      let packAdversary = Self.makeAdversary(id: "dark-elf", name: "Dark Elf", source: "my-pack")
      let sut = makeSUT(packAdversaries: [("my-pack", [packAdversary])])
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      // No ContentSource registered → fallback capitalises "my-pack" → "My Pack"
      #expect(
        texts.contains("My Pack"), "Pack section header should appear for loaded pack adversaries")
    }

    @Test func multiplePackSectionsEachShowHeader() throws {
      let fireDrake = Self.makeAdversary(id: "fire-drake", name: "Fire Drake", source: "fire-pack")
      let iceTroll = Self.makeAdversary(id: "ice-troll", name: "Ice Troll", source: "ice-pack")
      let sut = makeSUT(packAdversaries: [("fire-pack", [fireDrake]), ("ice-pack", [iceTroll])])
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Fire Pack"), "First pack section header should be present")
      #expect(texts.contains("Ice Pack"), "Second pack section header should be present")
    }

    @Test func localSectionHeaderPresent() throws {
      let custom = Self.makeAdversary(id: "custom", name: "Custom Adversary", source: "local")
      let sut = makeSUT(localAdversaries: [custom])
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Local"))
    }

    @Test func localSectionHiddenWhenNoLocalAdversaries() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(
        !texts.contains("Local"),
        "Local section header must not render when no local adversaries exist")
    }

    // MARK: - Toolbar

    @Test func importButtonPresent() throws {
      let sut = makeSUT()
      let buttons = try sut.inspect().findAll(ViewType.Button.self)
      #expect(
        buttons.contains { (try? $0.accessibilityIdentifier()) == "compendium.root.import-button" },
        "Import DHPack button should be present")
    }

    @Test func addAdversaryButtonPresent() throws {
      let sut = makeSUT()
      let buttons = try sut.inspect().findAll(ViewType.Button.self)
      #expect(
        buttons.contains {
          (try? $0.accessibilityIdentifier()) == "compendium.root.add-adversary-button"
        },
        "Add Adversary button should be present")
    }

    @Test func addAdversaryButtonAlwaysDisabled() throws {
      let sut = makeSUT()
      let buttons = try sut.inspect().findAll(ViewType.Button.self)
      let addButton = try #require(
        buttons.first {
          (try? $0.accessibilityIdentifier()) == "compendium.root.add-adversary-button"
        },
        "Add Adversary button should be present")
      #expect(addButton.isDisabled(), "Add Adversary is disabled pending AdversaryCreatorForm")
    }

    // These tests find the Export button by AX identifier and check its disabled state.
    // Individual ToolbarItem(placement: .primaryAction) declarations are used (not
    // ToolbarItemGroup) which makes button traversal more reliable across ViewInspector versions.
    @Test func exportButtonPresentAndDisabledWhenNoLocalAdversaries() throws {
      let sut = makeSUT()
      let buttons = try sut.inspect().findAll(ViewType.Button.self)
      let exportButton = try #require(
        buttons.first { (try? $0.accessibilityIdentifier()) == "compendium.root.export-button" },
        "Export Local button should be present")
      #expect(
        exportButton.isDisabled(),
        "Export button should be disabled when no local adversaries exist")
    }

    @Test func exportButtonAlwaysDisabled() throws {
      let custom = Self.makeAdversary(id: "custom", name: "Custom", source: "local")
      let sut = makeSUT(localAdversaries: [custom])
      let buttons = try sut.inspect().findAll(ViewType.Button.self)
      let exportButton = try #require(
        buttons.first { (try? $0.accessibilityIdentifier()) == "compendium.root.export-button" },
        "Export Local button should be present")
      #expect(exportButton.isDisabled(), "Export button is disabled pending DHPackExportSheet")
    }
  }

#endif
