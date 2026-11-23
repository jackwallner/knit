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

    /// A shelf shows its first designs in a row; See All opens all of it, older designs included.
    func testSeeAllOpensTheWholeShelf() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-SeedDemo"])
        tab("Patterns", "Muster", in: app)
        let all = app.buttons["shelf.Hats"]
        XCTAssertTrue(all.waitForExistence(timeout: 10))
        all.tap()
        let design = app.buttons["design.ribbedBeanie"]
        scrollTo(design, in: app)
        QA.checkpoint(app, "library-shelf")
        design.tap()
        XCTAssertTrue(app.buttons["design.castOn"].waitForExistence(timeout: 10))
    }

    func testCoreLoopRowsCountAndSurviveRelaunch() {
        let app = XCUIApplication()
        QA.launch(app)
        passOnboarding(app)
        // First run lands on Patterns; a knitter with her own project goes to Projects.
        tab("Projects", "Projekte", in: app)
        let typed = "Gate Scarf \(Int(Date().timeIntervalSince1970) % 100_000)"
        let castOn = app.buttons["projects.castOn"]
        if castOn.waitForExistence(timeout: 15) {
            QA.checkpoint(app, "projects-empty")
            castOn.tap()
        } else {
            tap(app.buttons["projects.add"], "New Project")
            tap(app.buttons["projects.add.counter"], "Row Counter")
        }
        let field = app.alerts.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        QA.type(typed, into: field, in: app)
        // A loaded simulator can drop a synthesized keystroke. This journey proves rows survive a
        // relaunch, so it follows the project by the name the field actually holds.
        sleep(1)
        // An empty field reports its placeholder as the value, so only text the field holds counts.
        let held = (field.value as? String).flatMap { $0.isEmpty || $0 == field.placeholderValue ? nil : $0 }
        let name = held ?? typed
        QA.checkpoint(app, "new-project-name")
        tap(app.alerts.buttons.matching(label("Cast On", "Anschlagen")).firstMatch, "Cast On")

        let counter = app.staticTexts["counter.value"]
        XCTAssertTrue(counter.waitForExistence(timeout: 10))
        QA.checkpoint(app, "counter-new")
        for _ in 0..<3 { tapFabric(app) }
        expect(counter, reads: "Row 3", "Reihe 3")
        QA.checkpoint(app, "counter-three-rows")

        QA.relaunch(app)
        openProject(name, name, in: app)
        XCTAssertTrue(counter.waitForExistence(timeout: 10))
        expect(counter, reads: "Row 3", "Reihe 3")
        QA.checkpoint(app, "counter-after-relaunch")
    }

    func testFirstRunToAFreePattern() {
        let app = XCUIApplication()
        QA.launch(app)
        passOnboarding(app)
        tab("Patterns", "Muster", in: app)
        QA.checkpoint(app, "library")
        let design = app.buttons["free.garterScarf"]
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
        tab("Patterns", "Muster", in: app)
        // A new knitter looking for one thing searches for it.
        let search = app.searchFields.firstMatch
        QA.type("ribbed", into: search, in: app)
        let design = app.buttons["design.ribbedBeanie"]
        XCTAssertTrue(design.waitForExistence(timeout: 10))
        QA.checkpoint(app, "library-search")
        design.tap()
        let unlock = app.buttons["design.castOn"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 10))
        QA.checkpoint(app, "design-locked")
        unlock.tap()
        XCTAssertTrue(app.buttons["paywall.yearly"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "paywall-yearly", paywall: true)
        revealPlan(app.buttons["paywall.monthly"], in: app)
        tap(app.buttons["paywall.monthly"], "Monthly")
        QA.checkpoint(app, "paywall-monthly", paywall: true)
        revealPlan(app.buttons["paywall.lifetime"], in: app)
        tap(app.buttons["paywall.lifetime"], "Lifetime")
        QA.checkpoint(app, "paywall-lifetime", paywall: true)
        tap(app.buttons.matching(label("Close", "Schließen")).firstMatch, "Close")
        XCTAssertTrue(unlock.waitForExistence(timeout: 10))
        QA.checkpoint(app, "design-after-paywall-dismissed")
    }

    func testReturnVisitToAProjectWithAPDF() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-SeedDemo"])
        let projects = app.staticTexts.matching(label("Raglan Sweater", "Raglanpullover")).firstMatch
        XCTAssertTrue(projects.waitForExistence(timeout: 15))
        QA.checkpoint(app, "projects-seeded")
        openProject("Raglan Sweater", "Raglanpullover", in: app)
        XCTAssertTrue(app.buttons["counter.plus"].waitForExistence(timeout: 15))
        QA.checkpoint(app, "pdf-reader")
        tap(app.buttons["counter.plus"], "Add a row")
        QA.checkpoint(app, "pdf-row-added")
    }

    func testInterruptedMidRowKeepsTheCount() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-SeedDemo"])
        openProject("Ribbed Beanie", "Gerippte Mütze", in: app)
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
        tab("Stash", "Vorrat", in: app)
        QA.checkpoint(app, "stash-empty")
        tap(app.buttons.matching(label("Add Yarn", "Garn hinzufügen")).firstMatch, "Add Yarn")
        XCTAssertTrue(app.navigationBars.matching(NSPredicate(format: "identifier IN %@", ["Yarn", "Garn"])).firstMatch.waitForExistence(timeout: 10))
        QA.checkpoint(app, "yarn-editor")
        // A knitter who pauses before naming must not lose the yarn: autosave runs in the pause
        // and once closed the editor and deleted the unnamed yarn.
        sleep(15)
        QA.type("Merino", into: app.textFields["Name"], in: app)
        tap(app.buttons.matching(label("Done", "Fertig")).firstMatch, "Done")
        XCTAssertTrue(app.staticTexts["Merino"].firstMatch.waitForExistence(timeout: 10))
        QA.checkpoint(app, "stash-one-yarn")
    }

    /// Settings is one tap from Projects, and the appearance picked there is the one the app keeps.
    func testSettingsPicksAnAppearance() {
        let app = XCUIApplication()
        QA.launch(app, arguments: ["-SeedDemo"])
        tap(app.buttons["projects.settings"], "Settings")
        let appearance = app.segmentedControls["settings.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 10))
        QA.checkpoint(app, "settings")
        let dark = appearance.buttons.element(boundBy: 2)
        tap(dark, "Dark")
        XCTAssertTrue(dark.isSelected)
        QA.checkpoint(app, "settings-dark")
        // Back to the device's own, so the journeys after this one look as they did.
        tap(appearance.buttons.element(boundBy: 0), "Automatic")
    }

    // MARK: - Helpers

    /// A fresh install opens on onboarding: through its pages to the trial, then the free way out.
    private func passOnboarding(_ app: XCUIApplication) {
        let next = app.buttons["onboarding.next"]
        guard next.waitForExistence(timeout: 10) else { return }
        QA.checkpoint(app, "onboarding-counter")
        next.tap()
        QA.checkpoint(app, "onboarding-patterns")
        next.tap()
        // The two questions. Hats and "A few projects" leave the library in its own order for the journeys after.
        tap(app.buttons["onboarding.shelf.0"], "the first answer")
        QA.checkpoint(app, "onboarding-shelf")
        next.tap()
        tap(app.buttons["onboarding.experience.1"], "the second answer")
        QA.checkpoint(app, "onboarding-experience")
        next.tap()
        let skip = app.buttons["onboarding.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        QA.checkpoint(app, "onboarding-trial")
        skip.tap()
        XCTAssertTrue(next.waitForNonExistence(timeout: 10))
    }

    private func tap(_ element: XCUIElement, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 15), "\(name) never appeared", file: file, line: line)
        element.tap()
    }

    /// The plans scroll under the paywall's pinned purchase bar (all of them on an iPad form sheet, and at large
    /// text sizes): scroll as a person would until the plan sits clear of the bar, so a tap lands on the plan and
    /// not on the button over it.
    private func revealPlan(_ plan: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(plan.waitForExistence(timeout: 10))
        let bar = app.buttons["paywall.buy"]
        let plans = app.scrollViews.containing(.button, identifier: "paywall.yearly").firstMatch
        for _ in 0..<10 {
            // The bar's terms sit about 80 points over its button.
            if plan.frame.maxY > bar.frame.minY - 80 {
                plans.swipeUp(velocity: .slow)
            } else if plan.frame.minY < app.windows.firstMatch.frame.minY + 60 {
                plans.swipeDown(velocity: .slow)
            } else { break }
            sleep(1)
        }
    }

    /// Tabs are matched by label on any element, so a tab bar and a sidebar both work.
    private func tab(_ label: String, _ german: String, in app: XCUIApplication) {
        QA.openTab(app, label, german)
    }

    /// Matches the English label or its German translation (the `german` persona).
    private func label(_ english: String, _ german: String) -> NSPredicate {
        NSPredicate(format: "label IN %@", [english, german])
    }

    /// The fabric fills the lower part of a project; one tap there is one row or one step.
    private func tapFabric(_ app: XCUIApplication) {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).tap()
        sleep(1)
    }

    /// A seeded project by its English name or the German one the demo seed uses in German.
    private func openProject(_ name: String, _ german: String, in app: XCUIApplication) {
        let row = app.staticTexts.matching(label(name, german)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15), "\(name) is not in Projects")
        row.tap()
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        // The library is lazy: a tile further down is not built until it is near the screen.
        // Large text puts one tile a row, so a shelf of forty designs runs twenty screens long.
        let window = app.windows.firstMatch
        _ = element.waitForExistence(timeout: 15)
        // Flings until the tile is built, then slow drags: a fling over the tall photo tiles carries a
        // tile past the screen between checks, so the slow drags follow it whichever way it went.
        for _ in 0..<60 where !element.exists { drag(window, up: true, fling: true) }
        for _ in 0..<40 where !(element.exists && element.isHittable) {
            drag(window, up: !element.exists || element.frame.midY > window.frame.midY, fling: false)
        }
        // A swipe keeps scrolling after the finger lifts: tap only once the tile has stopped moving.
        var frame = element.frame
        for _ in 0..<10 {
            Thread.sleep(forTimeInterval: 0.4)
            if element.frame == frame { break }
            frame = element.frame
        }
        XCTAssertTrue(element.isHittable)
    }

    /// Scrolls by dragging between two points of the window. XCTest's own swipes land rotated on the
    /// unfolded Duo, where they never scroll the page.
    private func drag(_ window: XCUIElement, up: Bool, fling: Bool) {
        let from = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.7 : 0.3))
        let to = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.3 : 0.7))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: fling ? .fast : .slow, thenHoldForDuration: fling ? 0 : 0.2)
    }

    private func expect(_ element: XCUIElement, reads label: String, _ german: String, file: StaticString = #filePath, line: UInt = #line) {
        let reached = expectation(for: NSPredicate(format: "label IN %@", [label, german]), evaluatedWith: element)
        XCTAssertEqual(XCTWaiter.wait(for: [reached], timeout: 8), .completed,
                       "expected \(label), reads \(element.label)", file: file, line: line)
    }
}
