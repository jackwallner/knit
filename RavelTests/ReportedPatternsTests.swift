import XCTest
@testable import Ravel

/// One test per confirmed pattern report, built from its `ravel-report` line with `scripts/pattern-report.py`.
/// Each pins the exact design, measurements and gauge the knitter used, and asserts what was wrong is now right.
/// The class of mistake also goes into `PlanCheck`, so every design at every size is held to it.
final class ReportedPatternsTests: XCTestCase {
    /// Every rebuilt report must also pass the checks every plan passes.
    private func sound(_ plan: PatternPlan, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(PlanCheck.problems(plan), [], file: file, line: line)
    }

    func testNoReportsYet() {
        // Replace with the first confirmed report.
        sound(Design.garterScarf.plan(measures: Design.garterScarf.defaultSize.values, gauge: Gauge(stitches: 20, rows: 28)))
    }
}
