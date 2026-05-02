//
//  SessionResumeUITests.swift
//  EncounterUITests
//
//  Verifies session persistence and the resume-prompt flow.
//
//  Pattern:
//    1. setUp launches with -UITestResetState (clean state via EncounterUITestCase)
//    2. navigate into the runner so a live session is registered
//    3. press home → scenePhase == .background → saveAll fires
//    4. wait for app to enter background state (avoids sleep timing hacks)
//    5. re-launch WITHOUT -UITestResetState → session survives
//    6. assert resume sheet / happy-path behavior
//

import XCTest

// Home-button backgrounding is iOS-only; macOS apps do not get reaped the same way.
#if os(iOS)

  final class SessionResumeUITests: EncounterUITestCase {

    // MARK: - Resume after relaunch

    /// Background the app while in the runner, relaunch without resetting state,
    /// and verify the resume prompt appears and leads back into the runner.
    func testResumePromptAppearsAfterRelaunch() throws {
      navigateToRunner()
      XCTAssertTrue(
        app.collectionViews["runner.list"].waitForExistence(timeout: 5),
        "Should be in the runner before backgrounding")

      // Background triggers scenePhase == .background → saveAll via performExpiringActivity
      XCUIDevice.shared.press(.home)
      XCTAssertTrue(
        app.wait(for: .runningBackground, timeout: 5),
        "App should enter background state so saveAll can fire")
      // .runningBackground confirms process state, not I/O completion.
      // performExpiringActivity blocks the handler until saveAll finishes,
      // but a brief pause reduces CI flakiness on slower devices or builds.
      Thread.sleep(forTimeInterval: 1)

      // Relaunch without resetting — persisted session survives
      app.launchArguments = []
      app.launch()

      // Resume sheet should appear automatically
      XCTAssertTrue(
        app.navigationBars["In Progress"].waitForExistence(timeout: 10),
        "Resume sheet ('In Progress' nav bar) should appear when an in-flight session is found")
      XCTAssertTrue(
        app.buttons["resume.resume-button"].waitForExistence(timeout: 5),
        "Resume button should be visible in the single-session resume sheet")

      // Tapping Resume dismisses the sheet and presents the runner full-screen
      app.buttons["resume.resume-button"].tap()
      XCTAssertTrue(
        app.collectionViews["runner.list"].waitForExistence(timeout: 5),
        "Runner adversary list should be visible after resuming")
      XCTAssertTrue(
        app.buttons["runner.done-button"].waitForExistence(timeout: 3),
        "Done button should be visible in the full-screen runner cover")
    }

    // MARK: - Dismiss resume prompt

    /// Tapping "Not Now" dismisses the sheet; the prompt does not re-appear.
    func testDismissingResumePromptDoesNotReprompt() throws {
      navigateToRunner()
      XCTAssertTrue(
        app.collectionViews["runner.list"].waitForExistence(timeout: 5))

      XCUIDevice.shared.press(.home)
      XCTAssertTrue(
        app.wait(for: .runningBackground, timeout: 5),
        "App should enter background state so saveAll can fire")
      Thread.sleep(forTimeInterval: 1)

      app.launchArguments = []
      app.launch()

      XCTAssertTrue(
        app.buttons["resume.dismiss-button"].waitForExistence(timeout: 10),
        "Resume sheet should appear on relaunch")
      app.buttons["resume.dismiss-button"].tap()

      // Sheet should be gone
      XCTAssertFalse(
        app.navigationBars["In Progress"].waitForExistence(timeout: 3),
        "Resume sheet should dismiss after tapping 'Not Now'")

      // Normal app state: Encounters tab is default
      XCTAssertTrue(
        app.navigationBars["Encounters"].waitForExistence(timeout: 5),
        "App should show the Encounters screen after dismissing the resume prompt")

      // Navigate away and back to confirm the dismiss is sticky.
      app.tabBars.buttons["Encounters"].tap()
      app.tabBars.buttons["Party"].tap()
      XCTAssertFalse(
        app.navigationBars["In Progress"].waitForExistence(timeout: 3),
        "Resume sheet should not re-appear after navigating away and back")
    }

    // MARK: - No resume prompt on fresh launch

    /// A fresh launch with no in-flight sessions should not show the resume prompt.
    func testNoResumePromptOnFreshLaunch() throws {
      // setUp already launched with -UITestResetState; no sessions exist.
      XCTAssertFalse(
        app.navigationBars["In Progress"].waitForExistence(timeout: 3),
        "Resume sheet should not appear on a clean launch with no in-flight sessions")
    }
  }

#endif  // os(iOS)
