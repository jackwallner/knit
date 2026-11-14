import XCTest

/// Release-gate journeys. `QA.checkpoint` runs the oracles on every screen; the
/// assertions here only prove a screen is reachable, except the core loop, which
/// also proves rows counted on a new project survive a relaunch.
///
/// The core loop and first run use the on-disk store a customer gets. The rest
/// use the in-memory demo seed so their screens are populated and deterministic.
/// The paywall reads prices from `Ravel.storekit` through the scheme's StoreKit Testing.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: - Journeys

    func testCoreLoopRowsCountAndSurviveRelaunch() {
        let app = XCUIApplication()
        QA.launch(app)
        let name = "Gate Scarf \(Int(Date().timeIntervalSince1970) % 100_000)"
        let castOn = app.buttons["projects.castOn"]
        if castOn.waitForExistence(timeout: 15) {
            QA.checkpoint(app, "projects-empty")
            castOn.tap()
        } else {
            tap(app.buttons["projects.add"], "New Project")
        }
        let field = app.alerts.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.typeText(name)
        QA.checkpoint(app, "new-project-name")
        tap(app.alerts.buttons["Cast On"], "Cast On")

        let counter = app.staticTexts["counter.value"]
        XCTAssertTrue(counter.waitForExistence(timeout: 10))
        QA.checkpoint(app, "counter-new")
        for _ in 0..<3 { tapFabric(app) }
        expect(counter, reads: "Row 3")
        QA.checkpoint(app, "counter-three-rows")

        QA.relaunch(app)
        openProject(name, in: app)
        XCTAssertTrue(counter.waitForExistence(timeout: 10))
        expect(counter, reads: "Row 3")
        QA.checkpoint(app, "counter-after-relaunch")
    }

    func testFirstRunToAFreePattern() {
        let app = XCUIApplication()
        QA.launch(app)
        tab("Patterns", in: app)
        QA.checkpoint(app, "library")
        let design = app.buttons["design.garterScarf"]
        scrollTo(design, in: app)
        design.tap()
        let castOn = app.buttons["design.castOn"]
        XCTAssertTrue(castOn.waitForExistence(timeout: 10))
        QA.checkpoint(app, "design-free")
        castOn.tap()
        let instruction = app.descendants(matching: .any)["guide.instruction"]
        XCTAssertTrue(instruction.waitForExistence(timeout: 10))
        QA.checkpoint(app, "guide-first-step")
        tapFabric(app)
        QA.checkpoint(app, "guide-next-step")
    }

    func testPaywallShownAndDismissed() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-SeedDemo"])
        tab("Patterns", in: app)
        let design = app.buttons["design.ribbedBeanie"]
        scrollTo(design, in: app)
        design.tap()
        let unlock = app.buttons["design.castOn"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 10))
        QA.checkpoint(app, "design-locked")
        unlock.tap()
        XCTAssertTrue(app.buttons["paywall.yearly"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "paywall-yearly", paywall: true)
        tap(app.buttons["paywall.monthly"], "Monthly")
        QA.checkpoint(app, "paywall-monthly", paywall: true)
        tap(app.buttons["paywall.lifetime"], "Lifetime")
        QA.checkpoint(app, "paywall-lifetime", paywall: true)
        tap(app.buttons["Close"], "Close")
        XCTAssertTrue(unlock.waitForExistence(timeout: 10))
        QA.checkpoint(app, "design-after-paywall-dismissed")
    }

    func testReturnVisitToAProjectWithAPDF() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-SeedDemo"])
        let projects = app.staticTexts["Raglan Sweater"].firstMatch
        XCTAssertTrue(projects.waitForExistence(timeout: 15))
        QA.checkpoint(app, "projects-seeded")
        openProject("Raglan Sweater", in: app)
        XCTAssertTrue(app.buttons["counter.plus"].waitForExistence(timeout: 15))
        QA.checkpoint(app, "pdf-reader")
        tap(app.buttons["counter.plus"], "Add a row")
        QA.checkpoint(app, "pdf-row-added")
    }

    func testInterruptedMidRowKeepsTheCount() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-SeedDemo"])
        openProject("Ribbed Beanie", in: app)
        let detail = app.staticTexts["guide.detail"]
        XCTAssertTrue(detail.waitForExistence(timeout: 15))
        QA.checkpoint(app, "guide-seeded")
        let before = detail.label
        tapFabric(app)
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertNotEqual(detail.label, before)
        let after = detail.label
        QA.interrupt(app)
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
        XCTAssertEqual(detail.label, after)
        QA.checkpoint(app, "guide-after-interruption")
    }

    func testStashAddYarn() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-UITesting"])
        tab("Stash", in: app)
        QA.checkpoint(app, "stash-empty")
        tap(app.buttons["Add Yarn"], "Add Yarn")
        XCTAssertTrue(app.navigationBars["Yarn"].waitForExistence(timeout: 10))
        QA.checkpoint(app, "yarn-editor")
        app.typeText("Merino")
        tap(app.buttons["Done"], "Done")
        XCTAssertTrue(app.staticTexts["Merino"].firstMatch.waitForExistence(timeout: 10))
        QA.checkpoint(app, "stash-one-yarn")
    }

    // MARK: - Helpers

    private func tap(_ element: XCUIElement, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 15), "\(name) never appeared", file: file, line: line)
        element.tap()
    }

    /// Tabs are matched by label on any element, so a tab bar and a sidebar both work.
    private func tab(_ label: String, in app: XCUIApplication) {
        let button = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
        tap(button, "\(label) tab")
    }

    /// The fabric fills the lower part of a project; one tap there is one row or one step.
    private func tapFabric(_ app: XCUIApplication) {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).tap()
        sleep(1)
    }

    private func openProject(_ name: String, in app: XCUIApplication) {
        let row = app.staticTexts[name].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15), "\(name) is not in Projects")
        row.tap()
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<8 where !element.isHittable {
            QA.swipe(app.windows.firstMatch, .up)
        }
        XCTAssertTrue(element.isHittable)
    }

    private func expect(_ element: XCUIElement, reads label: String, file: StaticString = #filePath, line: UInt = #line) {
        let reached = expectation(for: NSPredicate(format: "label == %@", label), evaluatedWith: element)
        XCTAssertEqual(XCTWaiter.wait(for: [reached], timeout: 8), .completed,
                       "expected \(label), reads \(element.label)", file: file, line: line)
    }
}
