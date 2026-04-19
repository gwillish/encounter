//
//  ExplorationUITestCase.swift
//  EncounterUITests
//
//  Base class for tests that use the debug exploration harness.
//  Launches the app with -UIExploration so ExplorationRootView replaces
//  ContentView — no live app state, no data loading required.
//
//  Usage:
//    class MyExplorationTests: ExplorationUITestCase {
//      func testDesignLanguageScreenshot() throws {
//        navigate(to: "exploration.design-language")
//        screenshotScene(named: "design-language")
//      }
//    }
//

import XCTest

class ExplorationUITestCase: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-UIExploration"]
    app.launch()
    XCTAssertTrue(
      app.navigationBars["Exploration"].waitForExistence(timeout: 10),
      "Exploration root should appear within 10 seconds")
  }

  // MARK: - Navigation

  /// Taps the scene row with the given accessibilityIdentifier and waits for
  /// the destination navigation bar to appear before returning.
  func navigate(to sceneID: String) {
    let row = app.buttons[sceneID]
    XCTAssertTrue(row.waitForExistence(timeout: 3), "Scene '\(sceneID)' not found in list")
    row.tap()
    // Wait for any navigation bar other than "Exploration" to confirm the destination loaded.
    let destination = app.navigationBars.matching(NSPredicate(format: "identifier != 'Exploration'")).firstMatch
    XCTAssertTrue(destination.waitForExistence(timeout: 5), "Scene destination should load after tapping '\(sceneID)'")
  }

  // MARK: - Screenshots

  /// Captures a full-screen screenshot, attaches it to the test result with
  /// the given name, and keeps it regardless of pass/fail.
  @discardableResult
  func screenshotScene(named name: String) -> XCUIScreenshot {
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
    return screenshot
  }
}
