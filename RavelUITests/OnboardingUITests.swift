import XCTest

/// First launch: one button in one frame on every page, the monthly trial on the last (yearly when RevenueCat's
/// `onboarding_plan` says so), and a free way out.
@MainActor
final class OnboardingUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITesting", "-Onboarding", "-MockProducts"]
        app.launch()
    }

    /// Walks to the trial page and returns the button's frame on each page.
    /// `shelf` is the answer to the first question, by its place in the list; the second answer is "A few projects".
    private func walkToTrial(shelf: Int = 0) -> [CGRect] {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        var frames: [CGRect] = []
        for page in 0..<4 {
            XCTAssertEqual(next.label, "Continue")
            frames.append(next.frame)
            // The two questions: the button waits for an answer.
            if page >= 2 {
                XCTAssertFalse(next.isEnabled, "page \(page) moves on with no answer")
                app.buttons[page == 2 ? "onboarding.shelf.\(shelf)" : "onboarding.experience.1"].tap()
            }
            next.tap()
        }
        XCTAssertTrue(app.buttons["onboarding.skip"].waitForExistence(timeout: 5))
        frames.append(next.frame)
        return frames
    }

    func testYearlyWhenTheOfferingAsksForIt() {
        app.terminate()
        app.launchArguments += ["-OnboardingPlan", "yearly"]
        app.launch()
        _ = walkToTrial()
        XCTAssertTrue(app.staticTexts["7 days free, then $39.99 a year. Auto-renews until canceled."].exists)
    }

    func testButtonKeepsItsFrameAndStartsTheMonthlyTrial() {
        let frames = walkToTrial()
        XCTAssertEqual(Set(frames.map { "\($0)" }).count, 1, "\(frames)")
        let next = app.buttons["onboarding.next"]
        XCTAssertEqual(next.label, "Start 7-day free trial")
        XCTAssertTrue(app.staticTexts["7 days free, then $6.99 a month. Auto-renews until canceled."].exists)
        for link in ["Restore", "Terms", "Privacy"] {
            let button = app.buttons[link]
            XCTAssertTrue(button.exists && app.windows.firstMatch.frame.contains(button.frame), "\(link) \(button.frame)")
        }
        next.tap()
        XCTAssertTrue(next.waitForNonExistence(timeout: 15))
        // Any paid design will do: each shelf shows its newest designs first, so a named one can scroll off.
        let design = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'design.'")).firstMatch
        XCTAssertTrue(app.buttons["free.garterScarf"].waitForExistence(timeout: 10))
        for _ in 0..<12 where !design.isHittable { app.swipeUp() }
        design.tap()
        XCTAssertEqual(app.buttons["design.castOn"].label, "Cast On")
    }

    /// The shelf asked for leads the library: Blankets & Home sits under Free, where Hats would be.
    func testTheShelfAskedForComesFirst() {
        _ = walkToTrial(shelf: 2)
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.buttons["free.garterScarf"].waitForExistence(timeout: 10))
        let home = app.buttons["shelf.Blankets & Home"]
        for _ in 0..<3 where !home.exists { app.swipeUp() }
        XCTAssertTrue(home.exists)
        let hats = app.buttons["shelf.Hats"]
        if hats.exists { XCTAssertLessThan(home.frame.minY, hats.frame.minY, "Hats still comes before the shelf asked for") }
    }

    func testGetStartedKeepsTheFreeApp() {
        _ = walkToTrial()
        app.buttons["onboarding.skip"].tap()
        // Everyone came for the patterns: the free way out opens on them too.
        XCTAssertTrue(app.buttons["free.garterScarf"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboarding.next"].exists)
    }
}
