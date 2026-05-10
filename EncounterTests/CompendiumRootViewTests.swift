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
      if !srdAdversaries.isEmpty {
        compendium.replaceSRDContent(adversaries: srdAdversaries, environments: [])
      }
      for (sourceID, adversaries) in packAdversaries {
        compendium.replaceSourceContent(
          sourceID: sourceID, adversaries: adversaries, environments: [])
      }
      for adversary in localAdversaries {
        compendium.addAdversary(adversary)
      }
      let contentStore = ContentStore(contentDirectory: .temporaryDirectory, compendium: compendium)
      return CompendiumRootView(compendium: compendium, contentStore: contentStore)
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

    @Test func packSectionHeaderPresent() throws {
      // Pack adversaries use replaceSourceContent — their source field must match
      // the sourceID for the fallback section title to capitalise correctly.
      let packAdversary = Self.makeAdversary(id: "dark-elf", name: "Dark Elf", source: "my-pack")
      let sut = makeSUT(packAdversaries: [("my-pack", [packAdversary])])
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      // No ContentSource registered → fallback capitalises "my-pack" → "My Pack"
      #expect(texts.contains("My Pack"), "Pack section header should appear for loaded pack adversaries")
    }

    @Test func localSectionHeaderPresentWhenLocalAdversariesExist() throws {
      let custom = Self.makeAdversary(id: "custom", name: "Custom Adversary")
      let sut = makeSUT(localAdversaries: [custom])
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Local"))
    }

    // MARK: - Toolbar

    @Test func importButtonPresent() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Import DHPack"))
    }

    @Test func addAdversaryButtonPresent() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Add Adversary"))
    }

    // These tests find the Export button and check its disabled state via ViewInspector.
    // Individual ToolbarItem(placement: .primaryAction) declarations are used (not
    // ToolbarItemGroup) which makes button traversal more reliable across ViewInspector versions.
    @Test func exportButtonPresentAndDisabledWhenNoLocalAdversaries() throws {
      let sut = makeSUT()
      let buttons = try sut.inspect().findAll(ViewType.Button.self)
      let exportButton = try #require(
        buttons.first { btn in
          let texts = (try? btn.findAll(ViewType.Text.self)) ?? []
          return texts.contains { (try? $0.string()) == "Export Local" }
        },
        "Export Local button should be present"
      )
      #expect(
        try exportButton.isDisabled(),
        "Export button should be disabled when no local adversaries exist")
    }

    @Test func exportButtonEnabledWhenLocalAdversariesExist() throws {
      let custom = Self.makeAdversary(id: "custom", name: "Custom")
      let sut = makeSUT(localAdversaries: [custom])
      let buttons = try sut.inspect().findAll(ViewType.Button.self)
      let exportButton = try #require(
        buttons.first { btn in
          let texts = (try? btn.findAll(ViewType.Text.self)) ?? []
          return texts.contains { (try? $0.string()) == "Export Local" }
        },
        "Export Local button should be present"
      )
      #expect(
        try !exportButton.isDisabled(),
        "Export button should be enabled when local adversaries exist")
    }
  }

#endif
