import XCTest

/// Taps the counter the way a knitter does: one tap is one row, and a tap on or beside undo never knits.
@MainActor
final class CounterUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private var window: XCUIElement { app.windows.firstMatch }

    /// Taps a point of the window, in points from its top left corner.
    private func tap(_ point: CGPoint) {
        window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: point.x, dy: point.y)).tap()
    }

    /// Taps a share of the way across and down the window, whatever its size.
    private func tap(across: Double, down: Double) {
        tap(CGPoint(x: window.frame.width * across, y: window.frame.height * down))
    }

    private func expect(_ element: XCUIElement, toRead format: String, _ value: String, _ message: String) {
        let reached = expectation(for: NSPredicate(format: format, value), evaluatedWith: element)
        XCTAssertEqual(XCTWaiter.wait(for: [reached], timeout: 5), .completed, "\(message) (reads \(element.label))")
    }

    private func expectRow(_ row: Int, _ message: String) {
        expect(app.staticTexts["counter.value"], toRead: "label == %@", "Row \(row)", message)
    }

    /// Where undo sits, found while it shows: at row 0 it is unseen and cannot be asked.
    private func undoSpot() -> CGPoint {
        let undo = app.buttons["counter.minus"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        return CGPoint(x: undo.frame.midX - window.frame.minX, y: undo.frame.midY - window.frame.minY)
    }

    func testOneTapIsOneRowAndUndoNeverKnits() {
        app.launchArguments = ["-UITesting"]
        app.launch()
        let castOn = app.buttons["projects.castOn"]
        XCTAssertTrue(castOn.waitForExistence(timeout: 15))
        castOn.tap()
        let name = app.alerts.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.typeText("Scarf")
        app.alerts.buttons["Cast On"].tap()
        XCTAssertTrue(app.staticTexts["counter.value"].waitForExistence(timeout: 10))

        tap(across: 0.5, down: 0.7)
        expectRow(1, "one tap on the fabric is one row")
        let undo = undoSpot()
        tap(undo)
        expectRow(0, "undo takes the row back")
        // Undo is unseen at row 0 and still takes the tap.
        tap(undo)
        tap(undo)
        expectRow(0, "a tap where undo sits must not knit a row")
        tap(across: 0.5, down: 0.7)
        expectRow(1, "one tap on the fabric is one row")
        tap(across: 0.5, down: 0.4)
        expectRow(2, "one tap above the fabric is one row")
        // Just outside the circle still lands on undo.
        tap(CGPoint(x: undo.x + 30, y: undo.y - 24))
        expectRow(1, "a near miss beside undo goes back a row")
        tap(undo)
        tap(undo)
        expectRow(0, "a second quick tap on undo stops at 0")
    }

    /// A library pattern: the whole screen is one button, and the fabric must not count the tap a second time.
    func testOneTapIsOneRowInAGuidedPattern() throws {
        app.launchArguments = ["-SeedDemo", "-OpenProject", "Ribbed Beanie"]
        app.launch()
        let detail = app.staticTexts["guide.detail"]
        XCTAssertTrue(detail.waitForExistence(timeout: 15))
        let row = try XCTUnwrap(Int(detail.label.prefix(while: \.isNumber)), "the seeded row sits inside a section: \(detail.label)")
        tap(across: 0.5, down: 0.75)
        expect(detail, toRead: "label BEGINSWITH %@", "\(row + 1) of", "one tap on the fabric is one row")
        tap(across: 0.5, down: 0.3)
        expect(detail, toRead: "label BEGINSWITH %@", "\(row + 2) of", "one tap on the instruction is one row")
        tap(undoSpot())
        expect(detail, toRead: "label BEGINSWITH %@", "\(row + 1) of", "undo takes one row back")
    }

    /// A PDF pattern: only the strip under the page counts.
    func testOneTapIsOneRowUnderAPDF() {
        app.launchArguments = ["-SeedDemo", "-OpenProject", "Raglan Sweater"]
        app.launch()
        XCTAssertTrue(app.staticTexts["counter.value"].waitForExistence(timeout: 15))
        expectRow(44, "the seeded sweater opens on row 44")
        let strip = app.buttons["counter.plus"]
        XCTAssertTrue(strip.waitForExistence(timeout: 5))
        strip.tap()
        expectRow(45, "one tap on the strip is one row")
        strip.tap()
        expectRow(46, "a second tap is a second row")
        tap(undoSpot())
        expectRow(45, "undo takes one row back")
    }
}
