import XCTest

/// Taps through the paywall with the sample plans: locked design, plan picked, bought, cast on.
/// The real store purchase is covered by `StoreTests`.
@MainActor
final class PaywallUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["-SeedDemo", "-MockProducts", "-Tab", "1", "-OpenDesign", "raglanPullover"]
        app.launch()
    }

    private func openPaywall() {
        let unlock = app.buttons["design.castOn"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 15))
        XCTAssertEqual(unlock.label, "Unlock Patterns")
        unlock.tap()
        XCTAssertTrue(app.buttons["paywall.yearly"].waitForExistence(timeout: 15))
    }

    private func expectUnlocked() {
        let castOn = app.buttons["design.castOn"]
        let unlocked = NSPredicate(format: "label == %@", "Cast On")
        wait(for: [expectation(for: unlocked, evaluatedWith: castOn)], timeout: 20)
        castOn.tap()
        XCTAssertTrue(app.descendants(matching: .any)["guide.instruction"].waitForExistence(timeout: 10))
    }

    func testEachPlanStatesItsPriceBeforeTheButton() {
        openPaywall()
        XCTAssertEqual(app.buttons["paywall.buy"].label, "Try Free for 7 Days")
        XCTAssertTrue(app.staticTexts["7 days free, then $39.99 a year. Renews until you cancel in Settings."].exists)
        app.buttons["paywall.monthly"].tap()
        XCTAssertTrue(app.staticTexts["7 days free, then $6.99 a month. Renews until you cancel in Settings."].exists)
        app.buttons["paywall.lifetime"].tap()
        XCTAssertEqual(app.buttons["paywall.buy"].label, "Buy Lifetime")
        XCTAssertTrue(app.staticTexts["One payment of $79.99. Every pattern is yours for good."].exists)
    }

    func testBuyingYearlyOpensThePattern() {
        openPaywall()
        app.buttons["paywall.buy"].tap()
        expectUnlocked()
    }

    func testBuyingLifetimeOpensThePattern() {
        openPaywall()
        app.buttons["paywall.lifetime"].tap()
        app.buttons["paywall.buy"].tap()
        expectUnlocked()
    }

    func testClosingThePaywallLeavesThePatternLocked() {
        openPaywall()
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["design.castOn"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["design.castOn"].label, "Unlock Patterns")
    }
}
