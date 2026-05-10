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

    private func makeSUT(
      srdAdversaries: [Adversary] = [],
      localAdversaries: [Adversary] = []
    ) -> CompendiumRootView {
      let compendium = Compendium()
      if !srdAdversaries.isEmpty {
        compendium.replaceSRDContent(adversaries: srdAdversaries, environments: [])
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

    @Test func srdSectionHeaderPresent() throws {
      let goblin = Self.makeAdversary(id: "goblin", name: "Goblin")
      let sut = makeSUT(srdAdversaries: [goblin])
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("SRD"))
    }

    @Test func localSectionHeaderPresentWhenLocalAdversariesExist() throws {
      let custom = Self.makeAdversary(id: "custom", name: "Custom Adversary", source: "homebrew")
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
      let custom = Self.makeAdversary(id: "custom", name: "Custom", source: "homebrew")
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
