import XCTest

/// Taps the counter the way a knitter does: one tap is one row, and a tap on or beside undo never knits.
@MainActor
final class CounterUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
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
    }

    private func tap(_ x: Double, _ y: Double) {
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
    }

    private func expectRow(_ row: Int, _ message: String) {
        let label = NSPredicate(format: "label == %@", "Row \(row)")
        let reached = expectation(for: label, evaluatedWith: app.staticTexts["counter.value"])
        XCTAssertEqual(XCTWaiter.wait(for: [reached], timeout: 5), .completed, message)
    }

    func testOneTapIsOneRowAndUndoNeverKnits() {
        // Undo is unseen at row 0 and still takes the tap.
        tap(0.114, 0.957)
        tap(0.114, 0.957)
        expectRow(0, "a tap where undo sits must not knit a row")
        tap(0.5, 0.7)
        expectRow(1, "one tap on the fabric is one row")
        tap(0.5, 0.4)
        expectRow(2, "one tap above the fabric is one row")
        // Just outside the circle still lands on undo.
        tap(0.19, 0.93)
        expectRow(1, "a near miss beside undo goes back a row")
        tap(0.114, 0.957)
        tap(0.114, 0.957)
        expectRow(0, "a second quick tap on undo stops at 0")
    }
}
