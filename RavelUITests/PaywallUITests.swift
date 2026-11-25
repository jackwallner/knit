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
        XCTAssertEqual(unlock.label, "Try Free for 7 Days")
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
        // Yearly leads, as on every fleet paywall, with the one badge on the page.
        XCTAssertEqual(app.buttons["paywall.buy"].label, "Start 7-Day Free Trial")
        XCTAssertTrue(app.staticTexts["7 days free, then $39.99 a year. Auto-renews until canceled."].exists)
        XCTAssertTrue(app.staticTexts["Save 52%"].exists)
        app.buttons["paywall.monthly"].tap()
        XCTAssertTrue(app.staticTexts["7 days free, then $6.99 a month. Auto-renews until canceled."].exists)
        app.buttons["paywall.lifetime"].tap()
        XCTAssertEqual(app.buttons["paywall.buy"].label, "Buy Lifetime")
        XCTAssertTrue(app.staticTexts["One payment of $79.99. Every pattern is yours for good."].exists)
    }

    /// Every plan is on screen above the button when the paywall opens, with no scrolling. An 11-inch iPad's form
    /// sheet once hid Monthly and Lifetime under it, and App Review could not find them (2.1(b), Nov 2026).
    func testEveryPlanShowsAboveTheButton() {
        openPaywall()
        expectEveryPlanAboveTheButton()
    }

    /// An iPad turned sideways has the least height a paywall sheet gets.
    func testEveryPlanShowsAboveTheButtonSideways() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPhone stays portrait") }
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        openPaywall()
        expectEveryPlanAboveTheButton()
    }

    private func expectEveryPlanAboveTheButton() {
        let buy = app.buttons["paywall.buy"].frame
        for plan in ["paywall.yearly", "paywall.monthly", "paywall.lifetime"] {
            let card = app.buttons[plan]
            XCTAssertTrue(card.exists, plan)
            XCTAssertLessThan(card.frame.maxY, buy.minY - 40, "\(plan) sits under the button")
        }
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
        XCTAssertEqual(app.buttons["design.castOn"].label, "Try Free for 7 Days")
    }
}
