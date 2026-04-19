#if DEBUG
//
//  ExplorationRootView.swift
//  Encounter
//
//  Root of the debug exploration harness. Shown when the app is launched
//  with -UIExploration. Platform-adaptive: NavigationSplitView on macOS,
//  NavigationStack + List on iOS/iPadOS.
//
//  Each scene row carries a stable accessibilityIdentifier so XCUITest
//  can navigate directly without traversing real app state.
//

import SwiftUI

struct ExplorationRootView: View {
  private let scenes = ExplorationScene.all

  var body: some View {
    #if os(macOS)
      macOSLayout
    #else
      iOSLayout
    #endif
  }

  // MARK: - iOS / iPadOS

  #if !os(macOS)
    private var iOSLayout: some View {
      NavigationStack {
        List(scenes) { scene in
          NavigationLink(destination: scene.destination.navigationTitle(scene.title)) {
            sceneRow(scene)
          }
          .accessibilityIdentifier(scene.id)
        }
        .navigationTitle("Exploration")
        .navigationBarTitleDisplayMode(.large)
      }
    }
  #endif

  // MARK: - macOS

  #if os(macOS)
    @State private var selectedID: String?

    private var macOSLayout: some View {
      NavigationSplitView {
        List(scenes, selection: $selectedID) { scene in
          sceneRow(scene)
            .tag(scene.id)
            .accessibilityIdentifier(scene.id)
        }
        .navigationTitle("Exploration")
      } detail: {
        if let id = selectedID, let scene = scenes.first(where: { $0.id == id }) {
          scene.destination
            .navigationTitle(scene.title)
        } else {
          Text("Select a scene")
            .foregroundStyle(.secondary)
        }
      }
    }
  #endif

  // MARK: - Shared row

  private func sceneRow(_ scene: ExplorationScene) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(scene.title)
        .font(.body)
      Text(scene.subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  ExplorationRootView()
}
#endif
