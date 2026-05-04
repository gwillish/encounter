//
//  SnapshotHelpers.swift
//  EncounterTests
//
//  Shared helpers for swift-snapshot-testing on iOS Simulator.
//
//  Snapshot tests are iOS-only (#if os(iOS)). The iOS Simulator test process
//  can write to the host filesystem, so assertSnapshot records and compares
//  PNG files in __Snapshots__/ next to each test source file.
//
//  Record mode: .missing (global default in swift-snapshot-testing 1.17+).
//  New tests auto-record on first run; existing images are compared on reruns.
//  To regenerate an image, delete its file from __Snapshots__/ and re-run.
//

#if os(iOS)
import SnapshotTesting
import SwiftUI

// Named layout presets — 390pt width matches standard iPhone layout.
enum SnapshotLayout {
  static let row: SwiftUISnapshotLayout = .fixed(width: 390, height: 80)
  static let card: SwiftUISnapshotLayout = .fixed(width: 390, height: 200)
  static let badge: SwiftUISnapshotLayout = .fixed(width: 200, height: 44)
}
#endif
