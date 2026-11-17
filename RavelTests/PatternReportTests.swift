import XCTest
@testable import Ravel

/// A knitter's report must rebuild the exact pattern they were knitting, and a corrected design must
/// land them on the same step and row.
final class PatternReportTests: XCTestCase {
    private let gauge = Gauge(stitches: 20, rows: 28)

    private func castOn(_ design: Design, revision: Int? = nil) -> PatternPlan {
        let measures = design.defaultSize.values
        var plan = design.plan(measures: measures, gauge: gauge)
        plan.source = PlanSource(design: design.rawValue, measures: measures, gauge: gauge, revision: revision ?? design.revision)
        return plan
    }

    func testReportLineRoundTripsAndRebuildsThePattern() throws {
        let plan = castOn(.raglanPullover)
        let code = PatternReport.code(plan: plan, design: "raglanPullover", taps: 57)
        let line = PatternReport.line(code)
        let decoded = try XCTUnwrap(PatternReport.decode("Some text\n\(line)\nSent from my iPhone"))
        XCTAssertEqual(decoded, code)
        let design = try XCTUnwrap(Design(rawValue: decoded.design))
        var rebuilt = design.plan(measures: try XCTUnwrap(decoded.measures), gauge: try XCTUnwrap(decoded.gauge))
        rebuilt.source = plan.source
        XCTAssertEqual(rebuilt, plan)
        let spot = try XCTUnwrap(plan.position(at: 57))
        XCTAssertEqual([decoded.step, decoded.row], [spot.step, spot.row])
    }

    func testMailCarriesTheLine() throws {
        let plan = castOn(.ribbedBeanie)
        let url = try XCTUnwrap(PatternReport.mail(plan: plan, design: "ribbedBeanie", title: "Ribbed Beanie", taps: 3))
        let body = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "body" }?.value)
        XCTAssertNotNil(PatternReport.decode(body))
        XCTAssertTrue(body.contains("Ribbed Beanie, step"))
    }

    func testCurrentRevisionOffersNoCorrection() {
        XCTAssertNil(Design.correction(for: castOn(.raglanPullover)))
        var unsourced = castOn(.raglanPullover)
        unsourced.source = nil
        XCTAssertNil(Design.correction(for: unsourced))
    }

    func testCorrectionKeepsTheKnittersPlace() throws {
        let old = castOn(.raglanPullover, revision: -1)
        let fixed = try XCTUnwrap(Design.correction(for: old))
        XCTAssertEqual(fixed.source?.revision, Design.raglanPullover.revision)
        let project = Project(name: "Raglan", color: .madder)
        project.follow(old, as: "raglanPullover")
        project.setRows(140)
        let before = try XCTUnwrap(old.position(at: 140))
        project.adopt(fixed)
        let after = try XCTUnwrap(project.plan?.position(at: project.rows))
        XCTAssertEqual([after.step, after.row], [before.step, before.row])
        XCTAssertNil(Design.correction(for: try XCTUnwrap(project.plan)))
    }
}
