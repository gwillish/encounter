#if DEBUG
  //
  //  ExplorationScene.swift
  //  Encounter
  //
  //  Catalogue of named exploration scenes. Each scene has a stable
  //  accessibilityIdentifier so XCUITest can navigate directly without
  //  traversing real app state.
  //

  import SwiftUI

  struct ExplorationScene: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let destination: AnyView

    init<V: View>(id: String, title: String, subtitle: String, @ViewBuilder destination: () -> V) {
      self.id = id
      self.title = title
      self.subtitle = subtitle
      self.destination = AnyView(destination())
    }
  }

  extension ExplorationScene {
    static var all: [ExplorationScene] {
      [
        ExplorationScene(
          id: "exploration.design-language",
          title: "Icon Design Language",
          subtitle: "Four proposals side-by-side at 20/28/44pt"
        ) {
          DesignLanguageExplorationView()
        },
        ExplorationScene(
          id: "exploration.pip-track",
          title: "Pip Track",
          subtitle: "HP gradient · stress · armor · text fallback — interactive sliders"
        ) {
          PipTrackExplorationView()
        },
        ExplorationScene(
          id: "exploration.runner-row",
          title: "Adversary Runner Row",
          subtitle: "All slot states: normal, stressed, conditioned, defeated"
        ) {
          RunnerRowExplorationView()
        },
        ExplorationScene(
          id: "exploration.player-runner",
          title: "Player Runner",
          subtitle: "PlayerRunnerSection rows collapsed and expanded"
        ) {
          PlayerRunnerExplorationView()
        },
      ]
    }
  }
#endif
