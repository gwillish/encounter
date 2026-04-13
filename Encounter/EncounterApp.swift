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
    // Wipe persisted state for XCUITest runs. Both stores are initialized with
    // localDirectory as a placeholder URL and perform no I/O until load() is
    // called in .task, so this runs before any data is read or written.
    // On the iOS simulator iCloud is unavailable, so defaultDirectory() falls
    // back to localDirectory — the wipe covers the real storage path.
    if CommandLine.arguments.contains("-UITestResetState") {
      try? FileManager.default.removeItem(at: EncounterStore.localDirectory)
      try? FileManager.default.removeItem(at: PlayerStore.localDirectory)
      try? FileManager.default.removeItem(at: SessionStore.localDirectory)
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
  @State private var sessionStore = SessionStore(directory: SessionStore.localDirectory)

  @Environment(\.scenePhase) private var scenePhase

  @State private var isShowingAbout = false

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(compendium)
        .environment(store)
        .environment(sessionRegistry)
        .environment(contentStore)
        .environment(playerStore)
        .environment(sessionStore)
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

          let sessionsDir = dir.deletingLastPathComponent()
            .appending(path: "Sessions", directoryHint: .isDirectory)
          sessionStore.relocate(to: sessionsDir)

          // All loads are independent — run concurrently.
          async let compendiumLoad: Void = compendium.load()
          async let storeLoad: Void = store.load()
          async let contentLoad: Void = contentStore.loadOnStartup()
          async let playerLoad: Void = playerStore.load()
          async let sessionLoad: Void = sessionStore.load(into: sessionRegistry)
          do { try await compendiumLoad } catch {}
          await storeLoad
          await contentLoad
          await playerLoad
          await sessionLoad
        }
        .onChange(of: scenePhase) { _, phase in
          if phase == .background {
            let registry = sessionRegistry
            #if os(iOS) || os(visionOS)
              // Request a background-execution extension so writes complete
              // before iOS/visionOS suspends the process.
              ProcessInfo.processInfo.performExpiringActivity(
                withReason: "save-sessions"
              ) { expired in
                guard !expired else { return }
                DispatchQueue.main.async {
                  Task { @MainActor in
                    await sessionStore.saveAll(from: registry)
                  }
                }
              }
            #else
              Task { await sessionStore.saveAll(from: registry) }
            #endif
          }
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
