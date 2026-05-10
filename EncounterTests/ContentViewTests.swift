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
      let url = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)
      try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
      return url
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

    // The toolbar Picker ("root.mode-toggle") is not traversable by ViewInspector even inside
    // a NavigationStack; toolbar structural presence is covered by XCUITest. Instead we verify
    // that EncounterAndPartyRootView's List section headers — unique to its encounters mode —
    // appear in the tree, confirming it is the iOS root.
    @Test func iOSLayoutRendersEncounterAndPartyRoot() throws {
      let sut = makeSUT()
      let texts = try sut.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
      #expect(texts.contains("Encounters"), "Encounters section header should be present")
      #expect(texts.contains("Party"), "Party section header should be present")
    }

    @Test func iOSLayoutHasNoTabView() throws {
      let sut = makeSUT()
      // findAll returns [] when absent — no try? needed, real errors propagate
      let tabViews = try sut.inspect().findAll(ViewType.TabView.self)
      #expect(tabViews.isEmpty, "iOS layout must not use TabView")
    }
  }

#endif
