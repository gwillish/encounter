//
//  AccessibilityTreeDump.swift
//  EncounterUITests
//
//  Dumps the full XCUITest accessibility tree for the current screen.
//  Run individual tests to capture the hierarchy at specific app states.
//  Output appears in the test log — use `xcodebuild test -only-testing:...`
//  and grep for "AX TREE" to extract.
//
//  Note: tests that navigate to the Encounters tab (testDumpBuilderScreen,
//  testToggleDifficultyAdjustments, testDumpCompendiumBrowser) require at
//  least one encounter to exist in the app. Run them manually after creating
//  an encounter, not in an automated clean-state CI run.
//

import XCTest

final class AccessibilityTreeDump: XCTestCase {

  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  // MARK: - Library screen

  /// Dumps the accessibility tree of the initial Party screen.
  @MainActor
  func testDumpLibraryScreen() throws {
    // Party tab is the first screen since the navigation restructure in PR #64.
    _ = app.navigationBars["Party"].waitForExistence(timeout: 5)
    printTree("Library screen")
  }

  // MARK: - Builder screen

  /// Opens the first encounter and dumps the builder screen tree.
  /// Requires an encounter to exist — create one manually before running.
  @MainActor
  func testDumpBuilderScreen() throws {
    // Wait for the app to finish loading and the tab bar to be ready.
    _ = app.navigationBars["Party"].waitForExistence(timeout: 5)
    _ = app.tabBars.buttons["Encounters"].waitForExistence(timeout: 3)
    // Navigate to Encounters — Party tab is first since PR #64.
    app.tabBars.buttons["Encounters"].tap()
    _ = app.navigationBars["Encounters"].waitForExistence(timeout: 3)
    // Tap the first row if one exists
    let firstRow = app.buttons.matching(identifier: "library.row").firstMatch
    if firstRow.waitForExistence(timeout: 2) {
      firstRow.tap()
      sleep(1)
    }
    printTree("Builder screen")
  }

  // MARK: - Toggle interaction test

  /// Attempts to toggle the difficulty adjustments from within XCUITest.
  /// Tests whether XCUITest's .tap() can activate Toggles in the safeAreaInset
  /// that AXe's HID simulation cannot.
  /// Requires an encounter to exist — create one manually before running.
  @MainActor
  func testToggleDifficultyAdjustments() throws {
    // Wait for the app to finish loading and the tab bar to be ready.
    _ = app.navigationBars["Party"].waitForExistence(timeout: 5)
    _ = app.tabBars.buttons["Encounters"].waitForExistence(timeout: 3)
    // Navigate to Encounters — Party tab is first since PR #64.
    app.tabBars.buttons["Encounters"].tap()
    _ = app.navigationBars["Encounters"].waitForExistence(timeout: 3)
    let firstRow = app.buttons.matching(identifier: "library.row").firstMatch
    guard firstRow.waitForExistence(timeout: 2) else {
      throw XCTSkip("No encounter row found — create one first for this diagnostic test")
    }
    firstRow.tap()
    sleep(1)

    let easierToggle = app.switches["builder.difficulty.toggle.easierFight"]
    XCTAssertTrue(easierToggle.waitForExistence(timeout: 3), "easierFight toggle not found")
    XCTAssertEqual(easierToggle.value as? String, "0", "should start off")

    easierToggle.tap()
    sleep(1)

    let valueAfter = easierToggle.value as? String
    // Write result to file for inspection
    let result = "easierFight value after tap: \(valueAfter ?? "nil")\n"
    try? result.write(toFile: "/tmp/toggle_test_result.txt", atomically: true, encoding: .utf8)
    printTree("Builder after toggle tap")

    XCTAssertEqual(valueAfter, "1", "Toggle should be on after tap")
  }

  // MARK: - Library create button

  /// Verifies the library 'New Encounter' button is accessible and tappable via XCUITest.
  @MainActor
  func testLibraryCreateButton() throws {
    // Wait for the app to finish loading and the tab bar to be ready.
    _ = app.navigationBars["Party"].waitForExistence(timeout: 5)
    _ = app.tabBars.buttons["Encounters"].waitForExistence(timeout: 3)
    // Navigate to Encounters — Party tab is first since PR #64.
    app.tabBars.buttons["Encounters"].tap()
    _ = app.navigationBars["Encounters"].waitForExistence(timeout: 3)
    // Use firstMatch — both the toolbar and empty-state CTA share this identifier.
    let createButton = app.buttons.matching(identifier: "library.create-button").firstMatch
    XCTAssertTrue(createButton.waitForExistence(timeout: 3), "library.create-button not found")
    XCTAssertTrue(createButton.isEnabled, "Create button should be enabled")
    let result = "library.create-button found: true, enabled: \(createButton.isEnabled), frame: \(createButton.frame)\n"
    try? result.write(toFile: "/tmp/library_create_button.txt", atomically: true, encoding: .utf8)
  }

  // MARK: - Compendium browser

  /// Opens the compendium browser from the builder and dumps its tree.
  /// Requires an encounter to exist — create one manually before running.
  @MainActor
  func testDumpCompendiumBrowser() throws {
    // Wait for the app to finish loading and the tab bar to be ready.
    _ = app.navigationBars["Party"].waitForExistence(timeout: 5)
    _ = app.tabBars.buttons["Encounters"].waitForExistence(timeout: 3)
    // Navigate to Encounters — Party tab is first since PR #64.
    app.tabBars.buttons["Encounters"].tap()
    _ = app.navigationBars["Encounters"].waitForExistence(timeout: 3)
    let firstRow = app.buttons.matching(identifier: "library.row").firstMatch
    guard firstRow.waitForExistence(timeout: 2) else {
      throw XCTSkip("No encounter row found — create one first for this diagnostic test")
    }
    firstRow.tap()
    sleep(1)
    let addAdversary = app.buttons["builder.add-adversary-button"]
    guard addAdversary.waitForExistence(timeout: 2) else {
      XCTFail("Add adversary button not found")
      return
    }
    addAdversary.tap()
    sleep(1)
    printTree("Compendium browser")
  }

  // MARK: - Helpers

  private func printTree(_ label: String) {
    let tree = app.debugDescription
    // Write to a temp file so it can be read from the terminal after the test
    let path = "/tmp/encounter_ax_tree_\(label.replacingOccurrences(of: " ", with: "_")).txt"
    let content = "=== AX TREE: \(label) ===\n\(tree)\n=== END AX TREE ===\n"
    try? content.write(toFile: path, atomically: true, encoding: .utf8)
    // Also add as an XCTAttachment for the xcresult bundle
    let attachment = XCTAttachment(string: content)
    attachment.name = "AX Tree - \(label)"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
