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
    private func walkToTrial() -> [CGRect] {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        var frames: [CGRect] = []
        for _ in 0..<2 {
            XCTAssertEqual(next.label, "Continue")
            frames.append(next.frame)
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
        XCTAssertTrue(app.staticTexts["7 days free. Then $39.99 a year. Renews until you cancel in Settings. A pattern you cast on is yours to keep."].exists)
    }

    func testButtonKeepsItsFrameAndStartsTheMonthlyTrial() {
        let frames = walkToTrial()
        XCTAssertEqual(Set(frames.map { "\($0)" }).count, 1, "\(frames)")
        let next = app.buttons["onboarding.next"]
        XCTAssertEqual(next.label, "Try Free for 7 Days")
        XCTAssertTrue(app.staticTexts["7 days free. Then $6.99 a month. Renews until you cancel in Settings. A pattern you cast on is yours to keep."].exists)
        for link in ["Restore", "Terms", "Privacy"] {
            let button = app.buttons[link]
            XCTAssertTrue(button.exists && app.windows.firstMatch.frame.contains(button.frame), "\(link) \(button.frame)")
        }
        next.tap()
        XCTAssertTrue(next.waitForNonExistence(timeout: 15))
        app.tabBars.buttons["Patterns"].tap()
        let design = app.buttons["design.raglanPullover"]
        XCTAssertTrue(app.buttons["free.garterScarf"].waitForExistence(timeout: 10))
        for _ in 0..<12 where !design.isHittable { app.swipeUp() }
        design.tap()
        XCTAssertEqual(app.buttons["design.castOn"].label, "Cast On")
    }

    func testGetStartedKeepsTheFreeApp() {
        _ = walkToTrial()
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.buttons["projects.castOn"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboarding.next"].exists)
    }
}
