//
//  EncounterAndPartyRootViewTests.swift
//  EncounterTests
//

#if !os(macOS)

  import DHKit
  import DHModels
  import Foundation
  import SwiftUI
  import Testing
  import ViewInspector

  @testable import Encounter

  @MainActor
  @Suite("EncounterAndPartyRootView")
  struct EncounterAndPartyRootViewTests {

    // MARK: - Helpers

    private func makeTempDir() -> URL {
      FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    private func makePlayer(name: String = "Aric", level: Int = 3) -> Player {
      Player(
        name: name, level: level,
        maxHP: 6, maxStress: 6, evasion: 12,
        thresholdMajor: 5, thresholdSevere: 10, armorSlots: 2
      )
    }

    private func makeSUT(
      playerStore: PlayerStore? = nil,
      initialMode: iOSRootMode = .encounters
    ) -> EncounterAndPartyRootView {
      let compendium = Compendium()
      return EncounterAndPartyRootView(
        store: EncounterStore(directory: makeTempDir()),
        playerStore: playerStore ?? PlayerStore(directory: makeTempDir()),
        compendium: compendium,
        contentStore: ContentStore(contentDirectory: makeTempDir(), compendium: compendium),
        sessionRegistry: SessionRegistry(),
        sessionStore: SessionStore(directory: makeTempDir()),
        initialMode: initialMode
      )
    }

    // MARK: - Toolbar

    // The segmented mode toggle renders as UISegmentedControl on iOS; its option labels
    // and toolbar buttons are not traversable by ViewInspector from a view that has no
    // internal NavigationStack. Structural toggle presence is covered by XCUITest.
    // Here we verify the toggle defaults to encounters mode (both list sections visible).
    @Test func modeToggleDefaultsToEncounters() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(
        texts.contains("Encounters"), "Encounters section confirms default mode is encounters")
      #expect(
        texts.contains("Party"), "Party section also present confirms both sections are shown")
    }

    // MARK: - Encounters mode

    @Test func encounterSectionVisibleInEncountersMode() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Encounters"), "Encounters section header should be present")
    }

    @Test func partySectionVisibleInEncountersMode() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Party"), "Party section header should be present in encounters mode")
    }

    @Test func partyPlayerNamesAppearInPartySection() async throws {
      let store = PlayerStore(directory: makeTempDir())
      let player = makePlayer(name: "Seraphina")
      await store.addPlayer(player)
      await store.addToParty(id: player.id)
      let sut = makeSUT(playerStore: store)
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Seraphina"), "Party member name should appear in the party section")
    }

    @Test func hiddenPlayerStillAppearsInPartySection() async throws {
      let store = PlayerStore(directory: makeTempDir())
      let player = makePlayer(name: "GhostedGuild")
      await store.addPlayer(player)
      await store.addToParty(id: player.id)
      await store.hidePlayer(id: player.id)
      let sut = makeSUT(playerStore: store)
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(
        texts.contains("GhostedGuild"),
        "Hidden player should still appear in the party list (grayed, not removed)"
      )
    }

    // MARK: - Compendium mode

    @Test func compendiumModeHidesPartySection() throws {
      let sut = makeSUT(initialMode: .compendium)
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(
        !texts.contains("Party"),
        "Party section must not be visible when compendium mode is active"
      )
    }

    @Test func compendiumModeHidesEncounterSection() throws {
      let sut = makeSUT(initialMode: .compendium)
      // In compendium mode, the encounters list section is replaced entirely by CompendiumRootView.
      // "No encounters yet" and "No party members" are section-body strings from encounters mode only.
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(!texts.contains("No encounters yet"))
      #expect(!texts.contains("No party members"))
    }
  }

#endif
