import XCTest
@testable import Ravel

final class TrendingTests: XCTestCase {
    private func date(month: Int) -> Date { Calendar.current.date(from: DateComponents(year: 2026, month: month, day: 15))! }

    func testBundledListLeadsWithNewDesignsEveryMonth() {
        for month in 1...12 {
            let list = Trending.bundled(for: date(month: month))
            XCTAssertEqual(list.prefix(4).map(\.tag), ["New", "New", "New", "New"], "month \(month)")
            XCTAssertEqual(Set(list.map(\.design)).count, list.count, "month \(month) repeats a design")
            XCTAssertGreaterThanOrEqual(list.count, 6, "month \(month)")
        }
    }

    func testBundledListFollowsTheSeason() {
        XCTAssertTrue(Trending.bundled(for: date(month: 11)).contains(Trend(design: .handwarmers, tag: "Gift season")))
        XCTAssertTrue(Trending.bundled(for: date(month: 7)).contains(Trend(design: .dishcloth, tag: "Summer cotton")))
    }

    func testDecodeSkipsUnknownDesignsRepeatsAndBadTags() {
        let json = """
        {"items":[{"design":"balaclava","tag":"New"},{"design":"notADesign","tag":"New"},{"design":"balaclava","tag":"Again"},
        {"design":"dishcloth","tag":""},{"design":"neckScarf","tag":"A tag that runs far past the limit"},{"design":"chunkyCowl","tag":" Chunky "}]}
        """
        XCTAssertEqual(Trending.decode(Data(json.utf8)), [Trend(design: .balaclava, tag: "New"), Trend(design: .chunkyCowl, tag: "Chunky")])
        XCTAssertEqual(Trending.decode(Data("not json".utf8)), [])
    }

    @MainActor
    func testCachedListWinsOverTheBundledOne() {
        let defaults = UserDefaults(suiteName: "trending.tests")!
        defaults.removePersistentDomain(forName: "trending.tests")
        XCTAssertEqual(Trending(defaults: defaults, now: date(month: 11)).items, Trending.bundled(for: date(month: 11)))
        defaults.set(Data(#"{"items":[{"design":"seedCowl","tag":"Hot"}]}"#.utf8), forKey: "trending.list")
        defaults.set(Date.now.addingTimeInterval(-86_400), forKey: "trending.fetched")
        XCTAssertEqual(Trending(defaults: defaults).items, [Trend(design: .seedCowl, tag: "Hot")])
        defaults.removePersistentDomain(forName: "trending.tests")
    }

    /// The list on the site must name designs this build has.
    func testPublishedListDecodes() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "docs/trending.json")
        let list = Trending.decode(try Data(contentsOf: file))
        XCTAssertGreaterThanOrEqual(list.count, 4)
    }
}

final class UnitsTests: XCTestCase {
    func testLengthsReadInBothSystems() {
        XCTAssertEqual(Sizing.inches(40, units: .imperial), "40 in")
        XCTAssertEqual(Sizing.inches(40, units: .metric), "101.5 cm")
        XCTAssertEqual(Sizing.inches(7.5, units: .metric), "19 cm")
        XCTAssertEqual(Sizing.cable(16, units: .metric), "40 cm")
        XCTAssertEqual(Sizing.cable(32, units: .metric), "80 cm")
        XCTAssertEqual(Sizing.cable(9, units: .metric), "23 cm")
        XCTAssertEqual(Sizing.cable(16, units: .imperial), "16 in")
        XCTAssertEqual(Sizing.yardage(1240, units: .imperial), "1,240 yd")
        XCTAssertEqual(Sizing.yardage(480, units: .metric), "440 m")
        XCTAssertEqual(Sizing.swatch(units: .metric), "10 cm")
    }
}

final class NewDesignTests: XCTestCase {
    private let gauges = YarnWeight.allCases.map(\.gauge)

    func testNeckScarfGrowsToItsWidthAndBackToThree() {
        for gauge in gauges {
            for (length, width) in [(28.0, 3.0), (28, 9), (42, 5.5), (60, 3), (60, 9)] {
                let plan = Engines.neckScarf(length: length, width: width, gauge: gauge)
                let steps = plan.steps
                let widest = steps[2].stitches ?? 0
                XCTAssertEqual(steps[1].stitches(after: steps[1].rows - 1), widest, "increase ends at the middle width")
                XCTAssertEqual(steps[3].stitches(after: steps[3].rows - 1), 3, "decrease ends on 3 stitches")
                XCTAssertEqual(steps[1].rows, steps[3].rows, "both tapers match")
                XCTAssertEqual(steps[1].texts.count % 2, 0, "shaping stays on the same edge")
                let knitted = Double(plan.totalTaps - 2) / (gauge.spi * 2)
                XCTAssertEqual(knitted, length, accuracy: length * 0.2, "\(length) x \(width) at \(gauge.stitches)")
            }
        }
    }

    func testCabledHeadbandRowsFillTheCastOn() {
        for gauge in gauges {
            for width in [2.5, 3.5, 5.0] {
                let plan = Engines.cableHeadband(head: 22, width: width, gauge: gauge)
                let caston = plan.steps[0].stitches ?? 0
                // Cables of 8 stitches, 6 at the edges, and up to 3 extra purl stitches a side.
                let side = ((caston - 6) % 8) / 2
                XCTAssertEqual((caston - 6) % 2, 0)
                XCTAssertLessThanOrEqual(side, 3)
                XCTAssertTrue(plan.steps[1].texts[0].hasPrefix("K2, p\(side + 2), *k6, p2"))
                XCTAssertTrue(plan.steps[1].texts[1].hasPrefix("K\(side + 4), *p6, k2"))
                // One cable with its edges is 14 stitches, so thick yarn cannot go narrower than that.
                let narrowest = 14 / (gauge.spi * 1.2)
                XCTAssertEqual(Double(caston) / (gauge.spi * 1.2), max(width, narrowest), accuracy: max(1, 5 / gauge.spi), "the band tracks the width asked for")
                XCTAssertEqual(plan.steps[1].rows % 8, 0, "ends on a full cable repeat")
                XCTAssertTrue(plan.abbreviations.contains { $0.term == "C6F" })
            }
        }
    }

    func testBalaclavaOpensAndClosesTheFace() {
        for gauge in gauges {
            for head in stride(from: 17.0, through: 26.0, by: 1.5) {
                let plan = Engines.balaclava(head: head, gauge: gauge)
                let around = plan.steps[0].stitches ?? 0
                XCTAssertEqual(around % 8, 0)
                let opening = plan.steps.filter { $0.section == "Face Opening" }
                let face = around - (opening[0].stitches ?? 0)
                XCTAssertGreaterThanOrEqual(face, 8)
                XCTAssertLessThan(face, around / 2)
                XCTAssertEqual(opening[1].rows % 2, 1, "the turned rows end on a purl row")
                XCTAssertEqual(opening.last?.stitches, around, "cast on gives back what was bound off")
                XCTAssertEqual(plan.steps.last { $0.section == "Crown" && $0.stitches != nil }?.stitches, 8)
                XCTAssertEqual((plan.steps.first { $0.section == "Face Edging" }?.stitches ?? 1) % 2, 0)
            }
        }
    }
}

final class ProjectRowTests: XCTestCase {
    @MainActor
    func testSetRowsClampsAndKeepsTheRepeatPosition() {
        let project = Project(name: "Mid project")
        project.repeatLength = 30
        project.setRows(137)
        XCTAssertEqual(project.rows, 137)
        XCTAssertEqual(project.repeatPosition, 17)
        project.setRows(-4)
        XCTAssertEqual(project.rows, 0)
    }
}
