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

    @MainActor func testCurrentRevisionOffersNoCorrection() {
        XCTAssertNil(LibraryItem.correction(for: castOn(.raglanPullover)))
        var unsourced = castOn(.raglanPullover)
        unsourced.source = nil
        XCTAssertNil(LibraryItem.correction(for: unsourced))
    }

    @MainActor func testCorrectionKeepsTheKnittersPlace() throws {
        let old = castOn(.raglanPullover, revision: -1)
        let fixed = try XCTUnwrap(LibraryItem.correction(for: old))
        XCTAssertEqual(fixed.source?.revision, Design.raglanPullover.revision)
        let project = Project(name: "Raglan", color: .madder)
        project.follow(old, as: "raglanPullover")
        project.setRows(140)
        let before = try XCTUnwrap(old.position(at: 140))
        project.adopt(fixed)
        let after = try XCTUnwrap(project.plan?.position(at: project.rows))
        XCTAssertEqual([after.step, after.row], [before.step, before.row])
        XCTAssertNil(LibraryItem.correction(for: try XCTUnwrap(project.plan)))
    }

    /// A published seasonal record that is corrected (its "revision" raised) is offered to projects cast on from it.
    @MainActor func testCorrectedTopicalRecordIsOffered() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "docs/designs.json")
        var listing = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-12-01T12:00:00Z"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "PatternReportTests.topical"))
        defaults.removePersistentDomain(forName: "PatternReportTests.topical")
        defer { defaults.removePersistentDomain(forName: "PatternReportTests.topical") }
        defaults.set(try JSONSerialization.data(withJSONObject: listing), forKey: "topical.list")
        let topical = try XCTUnwrap(TopicalStore(defaults: defaults, now: now).items.first)
        let item = LibraryItem.topical(topical)
        let measures = topical.base.defaultSize.values
        var plan = item.plan(measures: measures, gauge: item.defaultGauge)
        plan.source = PlanSource(design: item.designRaw, measures: measures, gauge: item.defaultGauge, revision: item.revision)
        XCTAssertNil(LibraryItem.correction(for: plan, topicals: TopicalStore(defaults: defaults, now: now)))

        var records = try XCTUnwrap(listing["designs"] as? [[String: Any]])
        let index = try XCTUnwrap(records.firstIndex { $0["id"] as? String == topical.id })
        records[index]["revision"] = 1
        listing["designs"] = records
        defaults.set(try JSONSerialization.data(withJSONObject: listing), forKey: "topical.list")
        let fixed = try XCTUnwrap(LibraryItem.correction(for: plan, topicals: TopicalStore(defaults: defaults, now: now)))
        XCTAssertEqual(fixed.source?.revision, item.revision + 1)
        XCTAssertEqual(fixed.source?.design, item.designRaw)
    }
}
