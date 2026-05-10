//
//  ContentViewTests.swift
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
  @Suite("ContentView iOS")
  struct ContentViewTests {

    private func makeTempDir() -> URL {
      FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    private func makeSUT() -> ContentView {
      let compendium = Compendium()
      return ContentView(
        store: EncounterStore(directory: makeTempDir()),
        sessionRegistry: SessionRegistry(),
        sessionStore: SessionStore(directory: makeTempDir()),
        compendium: compendium,
        playerStore: PlayerStore(directory: makeTempDir()),
        contentStore: ContentStore(contentDirectory: makeTempDir(), compendium: compendium)
      )
    }

    // "Encounters" and "Party" section headers are the fingerprint of
    // EncounterAndPartyRootView (encounters mode) being the iOS root.
    // If TabView were still present, these texts would not be in the tree.
    @Test func iOSLayoutRendersEncounterAndPartyRoot() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Encounters"), "Encounters section header should be present")
      #expect(texts.contains("Party"), "Party section header should be present")
    }

    @Test func iOSLayoutHasNoTabView() throws {
      let sut = makeSUT()
      let tabViews = try? sut.inspect().findAll(ViewType.TabView.self)
      #expect(tabViews == nil || tabViews!.isEmpty, "iOS layout must not use TabView")
    }
  }

#endif
