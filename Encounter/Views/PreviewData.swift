//
//  PreviewData.swift
//  Encounter
//

#if DEBUG
  import DHKit
  import DHModels
  import Foundation

  /// Factory for preview-ready store instances.
  /// All stores use `.temporaryDirectory` and perform no disk I/O until explicitly loaded.
  enum PreviewData {

    static func compendium() -> Compendium { Compendium() }

    static func encounterStore() -> EncounterStore {
      EncounterStore(directory: .temporaryDirectory)
    }

    static func playerStore() -> PlayerStore {
      PlayerStore(directory: .temporaryDirectory)
    }

    static func sessionRegistry() -> SessionRegistry { SessionRegistry() }

    static func sessionStore() -> SessionStore {
      SessionStore(directory: .temporaryDirectory)
    }

    static func contentStore(compendium: Compendium = PreviewData.compendium()) -> ContentStore {
      ContentStore(contentDirectory: .temporaryDirectory, compendium: compendium)
    }
  }
#endif
