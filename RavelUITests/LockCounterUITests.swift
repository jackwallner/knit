import XCTest

/// Counts rows from the Lock Screen, end to end: the Live Activity's button runs in the app, the app counts
/// by its own rules, and both the card and the project show the new round.
///
/// It proves the path where the simulator can run it and skips where it cannot: the fleet's slim pool boots
/// without Live Activities (outside `--widgets` leases) and without `linkd`, the daemon that runs a widget's
/// button, and a hosted simulator is often too slow to show the card or run the tap in time. The rules
/// themselves are in `LockCounterTests`. Run it on a pool simulator restored to stock (`simslim off <udid>`
/// on a `--widgets` lease), and read the result for "passed", not "skipped".
@MainActor
final class LockCounterUITests: XCTestCase {
    private let app = XCUIApplication()
    private let lockScreen = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func pressLock() {
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
    }

    private func reads(_ text: String, timeout: TimeInterval = 20) -> Bool {
        lockScreen.staticTexts[text].waitForExistence(timeout: timeout)
    }

    /// One try at getting the card up and a tap through. Nil when the tap moved the card; otherwise what
    /// the simulator failed at.
    private func tapReachesTheCard() -> String? {
        app.terminate()
        app.launchArguments = ["-SeedDemo", "-OpenProject", "Ribbed Beanie"]
        app.launch()
        guard app.staticTexts["guide.section"].waitForExistence(timeout: 20) else { return "the project did not open" }
        XCTAssertEqual(app.staticTexts["guide.section"].label.lowercased(), "body · round 6")

        let toggle = app.buttons["counter.lockScreen"]
        guard toggle.waitForExistence(timeout: 5) else { return "Live Activities are off on this simulator" }
        toggle.tap()

        // Lock, then wake to the Lock Screen.
        pressLock()
        sleep(2)
        pressLock()
        let knit = lockScreen.buttons["Add a row"]
        guard knit.waitForExistence(timeout: 20) else {
            record("lock-screen-without-card")
            unlock()
            return "the Lock Screen showed no Live Activity"
        }
        // The first Live Activity of an app asks once whether to keep showing them. The card then closes
        // over the question and its buttons move: let it settle before a tap.
        for allow in ["Allow", "Always Allow"] where lockScreen.buttons[allow].exists { lockScreen.buttons[allow].tap() }
        sleep(3)
        XCTAssertTrue(reads("Body · Round 6"), "the card opens on the round the project is on")

        knit.tap()
        guard reads("Body · Round 7", timeout: 60) else {
            record("lock-screen-after-tap")
            unlock()
            return "a tap did not move the card"
        }
        return nil
    }

    func testRowsCountedOnTheLockScreenReachTheProject() throws {
        // A hosted simulator can be minutes behind on its first Live Activity: one more try, then skip.
        var failures: [String] = []
        for _ in 0..<2 {
            guard let failure = tapReachesTheCard() else { break }
            failures.append(failure)
            if failure.contains("are off") { break }
        }
        guard failures.count < 2, failures.last?.contains("are off") != true else {
            throw XCTSkip("This simulator cannot run the Lock Screen counter: " + failures.joined(separator: "; "))
        }
        let knit = lockScreen.buttons["Add a row"]
        knit.tap()
        XCTAssertTrue(reads("Body · Round 8"), "a second tap is a second round")
        lockScreen.buttons["Back one row"].tap()
        XCTAssertTrue(reads("Body · Round 7"), "undo takes one round back")

        // The project itself moved: the same count is on its own screen.
        unlock()
        app.activate()
        let section = app.staticTexts["guide.section"]
        let moved = expectation(for: NSPredicate(format: "label == %@", "Body · Round 7"), evaluatedWith: section)
        XCTAssertEqual(XCTWaiter.wait(for: [moved], timeout: 20), .completed, "reads \(section.label)")

        // A row counted in the app shows on the card.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()
        pressLock()
        sleep(2)
        pressLock()
        XCTAssertTrue(reads("Body · Round 8"), "the card follows a row counted in the app")
        unlock()
    }

    /// Keeps what the Lock Screen showed, so a skip can be told from a card this test failed to find.
    private func record(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
        let tree = XCTAttachment(string: lockScreen.debugDescription)
        tree.name = name + "-tree"
        tree.lifetime = .keepAlways
        add(tree)
    }

    /// Leaves the device unlocked for whatever runs next.
    private func unlock() {
        XCUIDevice.shared.press(.home)
        let bottom = lockScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99))
        bottom.press(forDuration: 0.05, thenDragTo: lockScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
    }
}
