import XCTest
@testable import Ravel

final class TopicalTests: XCTestCase {
    private static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    /// Every published record and every draft, the files `scripts/topical-check.sh` reads.
    private func recordFiles() throws -> [URL] {
        var files: [URL] = []
        let published = Self.root.appending(path: "docs/designs.json")
        if FileManager.default.fileExists(atPath: published.path) { files.append(published) }
        files.append(Self.root.appending(path: "Ravel/collection.json"))
        let drafts = Self.root.appending(path: "project-docs/topical/drafts")
        files += try FileManager.default.contentsOfDirectory(at: drafts, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }
        return files.sorted { $0.path < $1.path }
    }

    private func draft(_ id: String) throws -> Topical {
        let data = try Data(contentsOf: Self.root.appending(path: "project-docs/topical/drafts/\(id).json"))
        return try XCTUnwrap(Topical.parse(data).first?.topical)
    }

    private func record(_ fields: String) -> Data {
        Data(##"{"designs":[{"id":"test-hat","title":"Test Hat","base":"ribbedBeanie","palette":[{"name":"gray","hex":"#888888"},{"name":"black","hex":"#222222"}],"stripes":[{"color":"B","inches":1}],"weights":["worsted"],"tag":"New"\##(fields)}]}"##.utf8)
    }

    // MARK: Records

    /// The same check the script and CI run: every size, both ends of every measurement, every allowed weight.
    func testEveryPublishedAndDraftRecordPasses() throws {
        let files = try recordFiles()
        XCTAssertGreaterThanOrEqual(files.count, 2)
        for file in files {
            let data = try Data(contentsOf: file)
            // The published list may be empty, but it must always be a list.
            XCTAssertNoThrow(try JSONDecoder().decode(Topical.Listing.self, from: data), file.lastPathComponent)
            let parsed = Topical.parse(data)
            for record in parsed {
                XCTAssertEqual(record.problems, [], "\(file.lastPathComponent) \(record.id)")
                guard let topical = record.topical else { continue }
                XCTAssertEqual(TopicalCheck.problems(topical), [], topical.id)
            }
        }
    }

    func testBadRecordsAreSkippedAndTheRestLoad() {
        let json = #"""
        {"designs":[
          {"id":"good-hat","title":"Good Hat","base":"ribbedBeanie","palette":[{"name":"gray","hex":"#888888"},{"name":"black","hex":"#222222"}],"stripes":[{"color":"B","inches":1}],"weights":["worsted"],"tag":"New"},
          {"id":"sweater","title":"Sweater","base":"raglanPullover","palette":[{"name":"gray","hex":"#888888"},{"name":"black","hex":"#222222"}],"weights":["worsted"],"tag":"New"},
          {"id":"bad-letter","title":"Bad","base":"ribbedBeanie","palette":[{"name":"gray","hex":"#888888"},{"name":"black","hex":"#222222"}],"stripes":[{"color":"E","inches":1}],"weights":["worsted"],"tag":"New"},
          {"id":"future","title":"Future","base":"ribbedBeanie","requires":2,"palette":[{"name":"gray","hex":"#888888"},{"name":"black","hex":"#222222"}],"weights":["worsted"],"tag":"New"},
          {"id":"odd-crown","title":"Odd","base":"ribbedBeanie","crown":"pompom","palette":[{"name":"gray","hex":"#888888"},{"name":"black","hex":"#222222"}],"weights":["worsted"],"tag":"New"},
          {"id":"bad-hex","title":"Hex","base":"ribbedBeanie","palette":[{"name":"gray","hex":"grey"},{"name":"black","hex":"#222222"}],"weights":["worsted"],"tag":"New"},
          {"id":"good-hat","title":"Twice","base":"ribbedBeanie","palette":[{"name":"gray","hex":"#888888"},{"name":"black","hex":"#222222"}],"weights":["worsted"],"tag":"New"}
        ]}
        """#
        XCTAssertEqual(Topical.decode(Data(json.utf8)).map(\.id), ["good-hat"])
        XCTAssertEqual(Topical.decode(Data("not json".utf8)), [])
    }

    func testDesignsShowOnlyBetweenTheirDates() {
        let data = record(#","starts":"2026-11-20","ends":"2027-01-01""#)
        let day = { (text: String) in ISO8601DateFormatter().date(from: text + "T12:00:00Z")! }
        XCTAssertEqual(Topical.decode(data, now: day("2026-11-19")), [])
        XCTAssertEqual(Topical.decode(data, now: day("2026-12-01")).count, 1)
        XCTAssertEqual(Topical.decode(data, now: day("2027-01-02")), [])
    }

    func testDeniedNamesFailTheCheck() throws {
        let topical = try XCTUnwrap(Topical.parse(Data(String(decoding: record(""), as: UTF8.self).replacingOccurrences(of: "Test Hat", with: "Seahawks Hat").utf8)).first?.topical)
        XCTAssertTrue(TopicalCheck.problems(topical).contains { $0.contains("seahawks") })
    }

    // MARK: Colorwork

    /// Color never changes the shape: the same rows, the same stitch counts, row for row.
    func testColorworkKeepsEveryStitchOfTheShape() throws {
        for id in ["round-raccoon-beanie", "fir-tree-hat"] {
            let topical = try draft(id)
            for weight in topical.weights {
                for input in TopicalCheck.inputs(for: topical.base) {
                    let plain = topical.base.plan(measures: input, gauge: weight.gauge, fit: topical.fit)
                    let painted = topical.plan(measures: input, gauge: weight.gauge)
                    XCTAssertEqual(painted.totalTaps, plain.totalTaps, id)
                    XCTAssertEqual(painted.knitRows(upTo: .max), plain.knitRows(upTo: .max), id)
                    func counts(_ plan: PatternPlan) -> [Int?] { plan.steps.flatMap { step in (0..<step.rows).map { step.stitches(after: $0) } } }
                    XCTAssertEqual(counts(painted), counts(plain), id)
                    XCTAssertEqual(painted.paints().count, painted.knitRows(upTo: .max), id)
                }
            }
        }
    }

    /// A row worked in a new yarn says which, and a chart row names every color it uses.
    func testEveryChangeOfYarnIsNamed() throws {
        let topical = try draft("round-raccoon-beanie")
        let plan = topical.plan(measures: topical.base.defaultSize.values, gauge: YarnWeight.worsted.gauge)
        let names = topical.work.palette.map(\.name)
        var previous: String?
        for step in plan.steps {
            if step.isAction {
                // A cast on starts a piece; a pick-up names the yarn its rows are worked in.
                if step.texts[0].hasPrefix("Cast on") { previous = nil }
                if let name = names.first(where: { step.texts[0].hasPrefix("With \($0), pick up") }) { previous = Colorwork.letter(names.firstIndex(of: name)!) }
                continue
            }
            for row in 0..<step.rows {
                let paint = try XCTUnwrap(step.paint(at: row))
                let text = step.text(at: row)
                if paint.count > 1 {
                    for letter in Set(paint) { XCTAssertTrue(text.contains(names[Colorwork.index(letter)!]), text) }
                    previous = nil
                } else {
                    if let previous, previous != paint { XCTAssertTrue(text.hasPrefix("With \(names[Colorwork.index(Character(paint))!])"), "\(step.section): \(text)") }
                    previous = paint
                }
            }
        }
        XCTAssertTrue(plan.steps[0].texts[0].hasPrefix("Cast on 88 stitches in gray"))
        XCTAssertEqual(plan.materials.prefix(3).map { $0.components(separatedBy: ",")[0] }, ["Gray", "Black", "Cream"])
        XCTAssertEqual(plan.materials.last, Painter.carrying)
        XCTAssertEqual(plan.silhouette, "ears")
        // The rim is picked up in its own color.
        XCTAssertEqual(plan.steps.filter { $0.texts[0].hasPrefix("With cream, pick up and knit") }.count, 2)
    }

    /// No float is longer than 5 stitches, at any weight a chart can be offered in.
    /// A gauge the knitter types can leave too few rows for the chart: that plan is never cast on.
    func testAChartThatDoesNotFitIsNeverCastOn() throws {
        let item = LibraryItem.topical(try draft("fir-tree-hat"))
        XCTAssertTrue(item.fits(measures: item.base.defaultSize.values, gauge: item.defaultGauge))
        var small = item.base.defaultSize.values
        small["head"] = 13
        XCTAssertFalse(item.fits(measures: small, gauge: Gauge(stitches: 24, rows: 20)))
        XCTAssertTrue(LibraryItem.builtIn(.ribbedBeanie).fits(measures: small, gauge: Gauge(stitches: 24, rows: 20)))
    }

    func testFloatsStayShort() {
        for weight in YarnWeight.allCases { XCTAssertLessThanOrEqual(Topical.longestFloat(weight.gauge), 5, "\(weight)") }
        let chart = Colorwork.Chart(placement: .repeating, rows: [[1] + Array(repeating: -1, count: 7)], stripe: nil)
        let work = Colorwork(palette: [Shade(name: "oat", hex: "#CCBB99"), Shade(name: "plum", hex: "#663366")], chart: chart)
        let topical = Topical(id: "test-hat", title: "Test Hat", base: .ribbedBeanie, work: work, weights: [.fingering], tag: "New", starts: nil, ends: nil, isFree: false)
        XCTAssertTrue(TopicalCheck.problems(topical).contains { $0.contains("A float of 7") })
    }

    /// Stripes that cover the whole hat at its smallest size leave no main color at the top, and fail.
    func testStripesLeaveTheMainColorAtTheTop() {
        let work = Colorwork(palette: [Shade(name: "oat", hex: "#CCBB99"), Shade(name: "plum", hex: "#663366")], stripes: [Colorwork.Stripe(color: 1, inches: 9)])
        let topical = Topical(id: "test-hat", title: "Test Hat", base: .ribbedBeanie, work: work, weights: [.worsted], tag: "New", starts: nil, ends: nil, isFree: false)
        XCTAssertTrue(TopicalCheck.problems(topical).contains { $0.contains("rows of oat at the top") })
    }

    func testRepeatingChartSetsTheStitchCount() {
        let chart = Colorwork.Chart(placement: .repeating, rows: [Array(repeating: 1, count: 3) + Array(repeating: -1, count: 3)], stripe: nil)
        let work = Colorwork(palette: [Shade(name: "oat", hex: "#CCBB99"), Shade(name: "plum", hex: "#663366")], chart: chart)
        let topical = Topical(id: "test-cowl", title: "Test Cowl", base: .ribbedCowl, work: work, weights: [.worsted], tag: "New", starts: nil, ends: nil, isFree: false)
        for input in TopicalCheck.inputs(for: .ribbedCowl) {
            let plan = topical.plan(measures: input, gauge: YarnWeight.worsted.gauge)
            XCTAssertEqual((plan.steps[0].stitches ?? 0) % 12, 0, "\(input)")
            XCTAssertTrue(plan.steps.contains { $0.texts[0].hasPrefix("*K3 oat, k3 plum; repeat from * around") })
        }
    }

    /// Ears are knit apart, rimmed and sewn to a crown that closes like any hat's.
    func testEarsAreKnitAndSewnOn() {
        for weight in YarnWeight.allCases {
            let plan = Engines.hat(.ribbed, head: 22, gauge: weight.gauge, fit: Engines.Fit(ears: true))
            XCTAssertTrue(plan.steps.contains { $0.section == "Crown" })
            for ear in ["First Ear", "Second Ear"] {
                let steps = plan.steps.filter { $0.section == ear }
                XCTAssertTrue(steps.first?.texts[0].hasPrefix("Cast on") == true, ear)
                XCTAssertTrue(steps.contains { $0.texts[0].hasPrefix("Pick up and knit") }, ear)
                XCTAssertEqual(steps.compactMap { $0.stitches(after: $0.rows - 1) }.min(), 4, ear)
            }
            XCTAssertTrue(plan.steps.last?.texts[0].hasPrefix("Sew the cast-on edge of each ear") == true)
            XCTAssertFalse(plan.steps.contains { $0.texts.contains { $0.contains("three-needle") } })
            XCTAssertEqual(PlanCheck.problems(plan), [], "\(weight)")
        }
    }

    // MARK: Saved plans

    func testAColorPlanSurvivesSaving() throws {
        let topical = try draft("fir-tree-hat")
        let plan = topical.plan(measures: topical.base.defaultSize.values, gauge: YarnWeight.worsted.gauge)
        let decoded = try JSONDecoder().decode(PatternPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(decoded, plan)
        XCTAssertEqual(decoded.palette?.count, 4)
    }

    /// A project cast on from a topical design draws from its own plan, so it outlives the record.
    func testATopicalProjectNeedsNothingButItsPlan() throws {
        let topical = try draft("round-raccoon-beanie")
        let project = Project(name: topical.title)
        project.follow(topical.plan(measures: topical.base.defaultSize.values, gauge: YarnWeight.worsted.gauge), as: topical.designRaw)
        XCTAssertEqual(project.designRaw, "topical.round-raccoon-beanie")
        XCTAssertEqual(project.silhouette(project.plan), .ears)
        XCTAssertNotNil(project.plan?.palette)
    }

    /// The shared checks agree with `PatternTests` on every built-in design.
    func testEveryBuiltInPlanPassesTheSharedChecks() {
        for design in Design.allCases {
            for input in TopicalCheck.inputs(for: design) {
                for weight in YarnWeight.allCases {
                    XCTAssertEqual(PlanCheck.problems(design.plan(measures: input, gauge: weight.gauge)), [], "\(design) \(input) \(weight)")
                }
            }
        }
    }

    @MainActor
    func testTheStoreOpensWithTheLastListItFetched() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "topical.tests"))
        defaults.removePersistentDomain(forName: "topical.tests")
        XCTAssertEqual(TopicalStore(defaults: defaults).items, [])
        defaults.set(record(""), forKey: "topical.list")
        XCTAssertEqual(TopicalStore(defaults: defaults).items.map(\.id), ["test-hat"])
        defaults.removePersistentDomain(forName: "topical.tests")
    }
}
