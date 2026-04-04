//
//  EncounterApp.swift
//  Encounter
//
//

import DHKit
import Logging
import OSLogging
import SwiftUI

@main
struct EncounterApp: App {

  init() {
    LoggingSystem.bootstrap { label in
      OSLogHandler(subsystem: "gwillish.Encounter", category: label)
    }
  }

  @State private var compendium = Compendium()
  @State private var store = EncounterStore(directory: EncounterStore.localDirectory)
  @State private var sessionRegistry = SessionRegistry()
  // Initialized with the local placeholder directory so the store is non-nil
  // from the first render. relocate(to:) is called in .task once the real
  // directory is resolved, before loadOnStartup() reads or writes anything.
  @State private var contentStore = ContentStore(
    contentDirectory: ContentStore.localContentDirectory,
    compendium: Compendium()  // placeholder; replaced by the real compendium below
  )
  @State private var playerStore = PlayerStore(directory: PlayerStore.localDirectory)

  @State private var isShowingAbout = false

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(compendium)
        .environment(store)
        .environment(sessionRegistry)
        .environment(contentStore)
        .environment(playerStore)
        .task {
          let dir = await EncounterStore.defaultDirectory()
          store.relocate(to: dir)

          // Content lives alongside encounters in the same Application
          // Support root, one level up from the Encounters subdirectory.
          let contentDir = dir.deletingLastPathComponent()
            .appending(path: "Content", directoryHint: .isDirectory)

          // Wire in the real Compendium and switch to the resolved directory.
          // configure() avoids recreating ContentStore just to swap the reference.
          contentStore.configure(compendium: compendium)
          await contentStore.relocate(to: contentDir)

          let playersDir = dir.deletingLastPathComponent()
            .appending(path: "Players", directoryHint: .isDirectory)
          playerStore.relocate(to: playersDir)

          // All loads are independent — run concurrently.
          async let compendiumLoad: Void = compendium.load()
          async let storeLoad: Void = store.load()
          async let contentLoad: Void = contentStore.loadOnStartup()
          async let playerLoad: Void = playerStore.load()
          do { try await compendiumLoad } catch {}
          await storeLoad
          await contentLoad
          await playerLoad
        }
        // onOpenURL on the root view handles .dhpack file opens on both
        // iOS and macOS. contentStore is non-nil from first render, so
        // there is no startup race.
        .sheet(isPresented: $isShowingAbout) {
          AboutView()
        }
        .onOpenURL { url in
          guard url.pathExtension.lowercased() == "dhpack" else { return }
          guard url.startAccessingSecurityScopedResource() else { return }
          Task { @MainActor in
            defer { url.stopAccessingSecurityScopedResource() }
            await contentStore.importPack(from: url)
          }
        }
    }
    #if os(macOS)
      .commands {
        CommandGroup(replacing: .appInfo) {
          Button("About Encounter") {
            isShowingAbout = true
          }
        }
      }
    #endif
  }
}
