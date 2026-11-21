import UIKit
import XCTest
@testable import Ravel

final class PatternTests: XCTestCase {
    private let gauges = YarnWeight.allCases.map(\.gauge)

    /// Every design, at every named size and both ends of its range, at every yarn weight.
    private func everyPlan(_ body: (Design, [String: Double], Gauge, PatternPlan) -> Void) {
        for design in Design.allCases {
            var inputs = design.sizes.map(\.values)
            inputs.append(Dictionary(uniqueKeysWithValues: design.measures.map { ($0.key, $0.range.lowerBound) }))
            inputs.append(Dictionary(uniqueKeysWithValues: design.measures.map { ($0.key, $0.range.upperBound) }))
            for input in inputs {
                for gauge in gauges { body(design, input, gauge, design.plan(measures: input, gauge: gauge)) }
            }
        }
    }

    /// Every built-in design page has its knitted sample photo in the app.
    /// Designs whose photo is not made yet. Each is drawn until its photo is on the site. Empty at a release.
    static let awaitingPhoto: Set<String> = ["toeUpSocks", "fingerlessMitts", "babyCardigan", "double-moss-scarf", "topDownBeanie", "twistedHeadband", "poncho", "christmasStocking", "washcloth", "waffle-beanie", "snowflake-beanie", "knotHat", "asymmetricShawl", "broken-rib-cowl", "feather-and-fan-scarf", "double-moss-blanket", "basketweave-washcloth", "bandanaCowl", "armWarmers", "honeycomb-cowl", "watchCap", "chevron-lace-blanket", "hoodedScarf", "striped-scarf", "coasters", "rope-cable-scarf", "babyMittens", "catHat", "seeded-rib-beanie", "eyelet-lace-wrap", "teaCozy", "bootCuffs", "striped-beanie", "kidsCardigan", "linen-stitch-scarf", "babySocks", "waffle-blanket", "mugCozy", "houndstooth-beanie", "capelet", "double-moss-cowl", "placemat", "miniStocking", "rope-cable-mitts", "raglanTee", "honeycomb-beanie", "waffle-washcloth", "feather-and-fan-wrap", "pouch", "color-block-beanie", "twisted-rib-scarf", "bottleCover", "bandanaKerchief", "snowflake-cowl", "broken-rib-beanie", "rope-cable-blanket", "turtleneck", "linen-stitch-washcloth", "star-beanie", "waffle-cowl"]

    private static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    /// Every design page has its knitted sample: in the app for the designs 1.0 shipped, on the site for the rest.
    func testEveryDesignHasASamplePhoto() {
        for design in Design.allCases {
            if let path = design.sitePhoto {
                let onSite = FileManager.default.fileExists(atPath: Self.root.appending(path: "docs/\(path)").path)
                XCTAssertTrue(onSite || Self.awaitingPhoto.contains(design.rawValue), "\(design) has no photo at docs/\(path)")
                XCTAssertNil(UIImage(named: design.photo), "\(design) carries a photo the site should serve")
            } else {
                XCTAssertNotNil(UIImage(named: design.photo), "\(design) has no sample photo")
            }
        }
    }

    /// The colorwork collection ships inside the app: every record loads, has its photo and a name in every language.
    @MainActor func testTheCollectionLoadsWithPhotosAndNames() throws {
        let collection = TopicalStore.collection
        XCTAssertGreaterThanOrEqual(collection.count, 7)
        let strings = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "Ravel/Localizable.xcstrings"))) as? [String: Any]
        let keys = strings?["strings"] as? [String: Any] ?? [:]
        for topical in collection {
            let item = LibraryItem.topical(topical)
            if let path = topical.photo {
                let onSite = FileManager.default.fileExists(atPath: Self.root.appending(path: "docs/\(path)").path)
                XCTAssertTrue(onSite || Self.awaitingPhoto.contains(topical.id), "\(topical.id) has no photo at docs/\(path)")
            } else {
                XCTAssertNotNil(item.photo.flatMap { UIImage(named: $0) }, "\(topical.id) has no sample photo")
            }
            XCTAssertNotNil(keys[topical.title], "\(topical.title) is not translated")
            XCTAssertNil(topical.ends, "\(topical.id) is part of the library and never ends")
        }
    }

    /// The free preview shows the opening of every pattern and never the whole of it.
    func testPreviewShowsTheOpeningNeverTheWholePattern() {
        everyPlan { design, input, gauge, plan in
            guard let preview = plan.preview() else { return XCTFail("\(design) has no preview") }
            let lines = preview.blocks.flatMap(\.lines)
            XCTAssertFalse(lines.isEmpty, "\(design) \(input)")
            XCTAssertEqual(preview.blocks.first?.section, plan.steps[0].section)
            let last = plan.steps[plan.steps.count - 1]
            if last.isAction { XCTAssertFalse(lines.contains(last.texts[0]), "\(design) previews its last step") }
            for block in preview.blocks { XCTAssertFalse(preview.later.contains(PatternPlan.part(block.section))) }
            XCTAssertEqual(Set(preview.later).count, preview.later.count, "\(design) names a part twice")
        }
    }

    func testEveryPlanIsWellFormed() {
        everyPlan { design, input, gauge, plan in
            let label = "\(design.rawValue) \(input) \(gauge.stitches)"
            XCTAssertGreaterThan(plan.steps.count, 2, label)
            XCTAssertGreaterThan(plan.yards, 0, label)
            XCTAssertFalse(plan.materials.isEmpty, label)
            XCTAssertTrue(plan.steps.first?.isAction == true, label)
            XCTAssertTrue(plan.steps.last?.isAction == true, label)
            for step in plan.steps {
                XCTAssertGreaterThan(step.rows, 0, label)
                XCTAssertFalse(step.section.isEmpty, label)
                XCTAssertFalse(step.texts.isEmpty, label)
                XCTAssertFalse(step.texts.contains { $0.isEmpty || $0.contains("\u{2014}") }, label)
                if let first = step.stitches, let last = step.stitches(after: step.rows - 1) {
                    XCTAssertGreaterThan(first, 0, label)
                    XCTAssertGreaterThan(last, 0, "\(label): \(step.texts[0])")
                }
            }
        }
    }

    /// A step that changes the count must hand the next step the count it ends on.
    func testStitchCountsCarryFromStepToStep() {
        everyPlan { design, input, gauge, plan in
            var carried: Int?
            for step in plan.steps {
                guard let first = step.stitches else { continue }
                if step.isAction, step.texts[0].hasPrefix("Cast on") || step.texts[0].hasPrefix("With") || step.texts[0].hasPrefix("Return") {
                    carried = step.stitches(after: step.rows - 1)
                    continue
                }
                if let previous = carried, step.delta == 0, step.texts.count == 1, step.texts[0] == "Knit" {
                    XCTAssertEqual(first, previous, "\(design.rawValue) \(input) \(gauge.stitches): \(step.section)")
                }
                carried = step.stitches(after: step.rows - 1)
            }
        }
    }

    func testHatCrownClosesOnEightStitches() {
        for style in [Engines.HatStyle.ribbed, .slouch, .rolled] {
            for gauge in gauges {
                for head in stride(from: 13.0, through: 26.0, by: 1.5) {
                    let plan = Engines.hat(style, head: head, gauge: gauge)
                    let crown = plan.steps.filter { $0.section == "Crown" }
                    XCTAssertEqual(crown.last?.stitches, 8)
                    // The body reaches the crown on a multiple of 8, the crown's wedges.
                    XCTAssertEqual((plan.steps.last { $0.section == "Body" }?.stitches ?? 0) % 8, 0)
                    // Each decrease round takes exactly 8 stitches off.
                    var previous = plan.steps.last { $0.section == "Body" }?.stitches ?? 0
                    for round in crown {
                        let now = round.stitches ?? 0
                        XCTAssertTrue(now == previous || now == previous - 8, "\(previous) to \(now)")
                        previous = now
                    }
                }
            }
        }
    }

    /// A hat too small for a 16 in circular is on the short needles from the cast on, so it is never told to change to them.
    func testASmallHatIsNeverToldToChangeNeedles() {
        var small = 0
        for style in [Engines.HatStyle.ribbed, .slouch, .rolled] {
            for head in stride(from: 13.0, through: 24.0, by: 1) {
                for weight in YarnWeight.allCases {
                    let plan = Engines.hat(style, head: head, gauge: weight.gauge)
                    let changes = plan.steps.contains { $0.texts.contains { $0.contains("Change to double-pointed") } }
                    let circular = plan.materials.contains { $0.contains("circular needle") }
                    if !circular { small += 1 }
                    XCTAssertEqual(changes, circular, "\(style) head \(head) \(weight)")
                }
            }
        }
        XCTAssertGreaterThan(small, 0)
    }

    func testHatFitsTheHead() {
        let plan = Engines.hat(.ribbed, head: 22, gauge: Gauge(stitches: 18, rows: 24))
        XCTAssertEqual(plan.steps[0].stitches, 88)
        // 8 in tall at 6 rounds an inch, give or take a round.
        let rounds = plan.steps.filter { !$0.isAction }.reduce(0) { $0 + $1.rows }
        XCTAssertEqual(Double(rounds) / 6, 22 * 0.37, accuracy: 0.5)
    }

    func testDishclothGrowsAndShrinksBackToFour() {
        for gauge in gauges {
            let plan = Engines.dishcloth(side: 8.5, gauge: gauge)
            let grow = plan.steps[2]
            let shrink = plan.steps[3]
            XCTAssertEqual(grow.stitches(after: 0), 5)
            XCTAssertEqual(shrink.stitches(after: 0), (grow.stitches(after: grow.rows - 1) ?? 0) - 1)
            XCTAssertEqual(shrink.stitches(after: shrink.rows - 1), 4)
        }
    }

    func testShawlBindsOffWhatIsOnTheNeedle() {
        let plan = Engines.shawl(wingspan: 60, gauge: YarnWeight.dk.gauge)
        let body = plan.steps[2]
        let last = body.stitches(after: body.rows - 1) ?? 0
        XCTAssertEqual((last - 5) % 4, 0)
        XCTAssertTrue(plan.steps.last?.texts[0].contains("all \(last) stitches") == true)
    }

    func testRibAndSeedCountsFitTheirRepeats() {
        for gauge in gauges {
            XCTAssertEqual((Engines.scarf(.rib, width: 7, length: 64, gauge: gauge).steps[0].stitches ?? 0) % 4, 2)
            XCTAssertEqual((Engines.scarf(.seed, width: 7, length: 64, gauge: gauge).steps[0].stitches ?? 0) % 2, 1)
            XCTAssertEqual((Engines.cowl(.rib, around: 26, height: 10, gauge: gauge).steps[0].stitches ?? 0) % 4, 0)
            // Seed stitch in the round needs an even count, or the pattern breaks at the marker.
            XCTAssertEqual((Engines.cowl(.seed, around: 26, height: 10, gauge: gauge).steps[0].stitches ?? 0) % 2, 0)
            XCTAssertEqual((Engines.handwarmers(hand: 7.5, gauge: gauge).steps[0].stitches ?? 0) % 4, 0)
        }
    }

    func testRaglanAddsUpAtEverySizeAndGauge() {
        for gauge in gauges {
            for chest in stride(from: 28.0, through: 66.0, by: 2) {
                for sleeve in [10.0, 18.0, 22.0] {
                    let r = Engines.raglan(chest: chest, body: 15, sleeve: sleeve, gauge: gauge)
                    let label = "chest \(chest) sleeve \(sleeve) gauge \(gauge.stitches)"
                    let panel = r.backAtNeck + 2 * r.bodyIncreases
                    let sleeveTop = r.sleeveAtNeck + 2 * r.sleeveIncreases
                    XCTAssertEqual(r.neck, 2 * r.backAtNeck + 2 * r.sleeveAtNeck, label)
                    XCTAssertEqual(r.body, 2 * panel + 2 * r.underarm, label)
                    XCTAssertEqual(r.sleeve, sleeveTop + r.underarm, label)
                    XCTAssertEqual(r.neck % 2, 0, label)
                    XCTAssertEqual(r.cuff % 2, 0, label)
                    XCTAssertGreaterThanOrEqual(r.sleeveAtNeck, 4, label)
                    XCTAssertGreaterThanOrEqual(r.bodyIncreases, 1, label)
                    XCTAssertGreaterThanOrEqual(r.sleeveIncreases, 1, label)
                    XCTAssertLessThanOrEqual(r.cuff, r.sleeve, label)

                    // The yoke ends on exactly the stitches the divide hands out.
                    let yoke = r.plan.steps.filter { $0.section == "Yoke" }
                    let end = yoke.last.flatMap { $0.stitches(after: $0.rows - 1) }
                    XCTAssertEqual(end, 2 * panel + 2 * sleeveTop, label)
                    XCTAssertEqual(yoke.reduce(0) { $0 + $1.rows }, r.yokeRounds, label)

                    // Each sleeve tapers down to the cuff count.
                    let taper = r.plan.steps.last { $0.section == "First Sleeve" }
                    XCTAssertEqual(taper.flatMap { $0.stitches(after: $0.rows - 1) }, r.cuff, label)
                }
            }
        }
    }

    func testRaglanKeepsAWearableNeckInLargeSizes() {
        let gauge = YarnWeight.worsted.gauge
        for chest in [32.0, 40, 52, 64] {
            let neck = Double(Engines.raglan(chest: chest, body: 15, sleeve: 18, gauge: gauge).neck) / gauge.spi
            XCTAssertGreaterThan(neck, 16, "chest \(chest)")
            XCTAssertLessThan(neck, 24, "chest \(chest)")
        }
        let medium = Engines.raglan(chest: 40, body: 15, sleeve: 18, gauge: gauge)
        XCTAssertEqual(medium.body, 180)
        XCTAssertEqual(Double(medium.plan.yards), 1200, accuracy: 250)
    }

    func testPositionWalksEveryTap() {
        let plan = Engines.hat(.ribbed, head: 22, gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(plan.position(at: 0)?.step, 0)
        XCTAssertEqual(plan.position(at: 1)?.step, 1)
        XCTAssertEqual(plan.position(at: 1)?.row, 0)
        XCTAssertNil(plan.position(at: plan.totalTaps))
        XCTAssertNotNil(plan.position(at: plan.totalTaps - 1))
        // Casting on and finishing are taps that do not grow the fabric.
        XCTAssertEqual(plan.knitRows(upTo: 1), 0)
        XCTAssertEqual(plan.knitRows(upTo: plan.totalTaps), plan.totalTaps - 2)
    }

    func testMeasurementsAreClampedToTheirRange() {
        let tiny = Design.ribbedBeanie.plan(measures: ["head": 2], gauge: YarnWeight.worsted.gauge)
        let smallest = Design.ribbedBeanie.plan(measures: ["head": 13], gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(tiny, smallest)
    }

    func testPlanSurvivesEncoding() throws {
        let plan = Design.raglanPullover.plan(measures: [:], gauge: YarnWeight.worsted.gauge)
        let decoded = try JSONDecoder().decode(PatternPlan.self, from: JSONEncoder().encode(plan))
        XCTAssertEqual(decoded, plan)
    }

    func testEveryDesignHasADefaultSizeInRange() {
        for design in Design.allCases {
            XCTAssertFalse(design.name.isEmpty)
            for size in design.sizes {
                for measure in design.measures {
                    let value = size.values[measure.key]
                    XCTAssertNotNil(value, "\(design.rawValue) \(size.name) \(measure.key)")
                    XCTAssertTrue(measure.range.contains(value ?? -1), "\(design.rawValue) \(size.name) \(measure.key)")
                }
            }
        }
    }

    /// The face opening is knit flat. It has to end with the right side facing, or the top of the
    /// hood is worked inside out.
    func testBalaclavaRejoinsWithTheRightSideFacing() {
        for gauge in gauges {
            for head in stride(from: 17.0, through: 26.0, by: 1.5) {
                let steps = Engines.balaclava(head: head, gauge: gauge).steps.filter { $0.section == "Face Opening" }
                let flat = steps.filter { !$0.isAction }
                let turns = flat.reduce(0) { total, step in
                    total + (0..<step.rows).filter { step.text(at: $0).hasSuffix(", turn") }.count
                }
                XCTAssertEqual(turns % 2, 0, "head \(head) gauge \(gauge.stitches): an odd number of turns leaves the wrong side facing")
                XCTAssertEqual(flat.last?.texts, ["Knit to the end. Do not turn"])
                XCTAssertTrue(steps.last?.isAction == true)
            }
        }
    }

    /// Running out of yarn is the worst way for a pattern to be wrong.
    func testYarnCoversEveryRowWritten() {
        for design in Design.allCases {
            for size in design.sizes {
                for weight in YarnWeight.allCases {
                    let plan = design.plan(measures: size.values, gauge: weight.gauge)
                    let needed = Sizing.yards(worked: plan.steps, spi: weight.gauge.spi)
                    XCTAssertGreaterThanOrEqual(plan.yards, needed, "\(design.rawValue) \(size.name) \(weight.rawValue)")
                    XCTAssertTrue(plan.materials[0].contains(Sizing.yardage(plan.yards)), "\(design.rawValue): the yarn line must state the same yardage")
                }
            }
        }
        // Checked by hand: 32 stitches by 576 rows of worsted is 489 yd on the needles, before the reserve.
        let scarf = Engines.scarf(.garter, width: 7, length: 64, gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(scarf.yards, 570)
        // A throw in garter, aran: 2,577 to 2,770 yd on the needles.
        XCTAssertGreaterThan(Engines.blanket(bordered: false, width: 48, length: 60, gauge: YarnWeight.aran.gauge).yards, 2_770)
        XCTAssertGreaterThan(Engines.neckScarf(length: 42, width: 5.5, gauge: YarnWeight.dk.gauge).yards, 207)
    }

    /// A project cast on in 1.0 keeps its plan for good. This is a plan as 1.0 wrote it, with the
    /// optional keys left out, and it must open in every later version.
    func testPlanSavedByVersionOneStillOpens() throws {
        let saved = """
        {"steps":[
          {"section":"Scarf","texts":["Cast on 32 stitches."],"rows":1,"stitches":32,"delta":0,"isAction":true},
          {"section":"Scarf","texts":["Knit"],"rows":576,"stitches":32},
          {"section":"Finishing","texts":["Bind off loosely. Weave in the ends."],"rows":1,"isAction":true}
        ],"materials":["About 480 yd of yarn"],"finished":"7 in wide, 64 in long","yards":480,"somethingNewer":true}
        """
        let plan = try JSONDecoder().decode(PatternPlan.self, from: Data(saved.utf8))
        XCTAssertEqual(plan.totalTaps, 578)
        XCTAssertEqual(plan.steps[1].delta, 0)
        XCTAssertFalse(plan.steps[1].isAction)
        XCTAssertNil(plan.steps[2].stitches)
        XCTAssertEqual(plan.knitRows(upTo: plan.totalTaps), 576)
    }

    func testSweaterIsKnitWithRoomOverTheChestGiven() {
        let plan = Design.raglanPullover.plan(measures: ["chest": 38], gauge: YarnWeight.worsted.gauge)
        XCTAssertTrue(plan.finished.contains(Sizing.inches(41)), plan.finished)
        XCTAssertTrue(plan.finished.contains(Sizing.inches(38)), plan.finished)
    }

    func testSleeveDecreasesAreNeverPacked() {
        for gauge in gauges {
            for chest in [31.0, 45, 65] {
                let plan = Engines.raglan(chest: chest, body: 15, sleeve: 10, gauge: gauge).plan
                for step in plan.steps where step.section == "First Sleeve" && step.delta < 0 {
                    XCTAssertGreaterThanOrEqual(step.texts.count, 4, "chest \(chest) gauge \(gauge.stitches)")
                }
            }
        }
    }

    func testSectionsStartWhereTheirFirstStepDoes() {
        let plan = Engines.hat(.ribbed, head: 22, gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(plan.sections.map(\.name), ["Brim", "Body", "Crown", "Finishing"])
        XCTAssertEqual(plan.sections[0].tap, 0)
        XCTAssertEqual(plan.sections[1].tap, plan.steps[0].rows + plan.steps[1].rows)
        XCTAssertEqual(plan.position(at: plan.sections[2].tap).map { plan.steps[$0.step].section }, "Crown")
    }

    // MARK: Tech edit, 2026-11-15

    private let hats: [Design] = [.ribbedBeanie, .slouchHat, .rolledBrimHat]

    /// K-14: every hat is cast on 5 to 15 percent smaller than the head, at every head and every weight.
    func testHatEaseStaysInTheBand() {
        for design in hats {
            let heads = Array(stride(from: 13.0, through: 26.0, by: 0.5)) + design.sizes.compactMap { $0.values["head"] }
            for head in heads {
                for weight in YarnWeight.allCases {
                    let plan = design.plan(measures: ["head": head], gauge: weight.gauge)
                    let around = Double(plan.steps[0].stitches ?? 0) / weight.gauge.spi
                    let ease = around / head - 1
                    XCTAssertTrue((-0.15...(-0.05)).contains(ease), "\(design) head \(head) \(weight): \(Int((ease * 100).rounded())) percent")
                    // The rib's repeat divides the cast on.
                    let rib = plan.steps[1].texts[0]
                    if rib.hasPrefix("*K2, p2") { XCTAssertEqual((plan.steps[0].stitches ?? 0) % 4, 0) }
                    if rib.hasPrefix("*K1, p1") { XCTAssertEqual((plan.steps[0].stitches ?? 0) % 2, 0) }
                }
            }
        }
    }

    /// K-14: a body that is not a multiple of 8 is brought to one on its last round, by at most 4 stitches.
    func testHatAdjustsToTheCrownOnTheLastBodyRound() {
        var adjusted = 0
        for design in hats {
            for head in stride(from: 13.0, through: 26.0, by: 0.5) {
                for weight in YarnWeight.allCases {
                    let plan = design.plan(measures: ["head": head], gauge: weight.gauge)
                    let body = plan.steps.filter { $0.section == "Body" }
                    guard let last = body.last, last.texts[0].contains("evenly") else { continue }
                    adjusted += 1
                    let before = body[body.count - 2].stitches ?? 0
                    XCTAssertLessThanOrEqual(abs((last.stitches ?? 0) - before), 4, "\(design) head \(head) \(weight)")
                    XCTAssertTrue(last.texts[0].contains(last.stitches ?? 0 > before ? "increasing \((last.stitches ?? 0) - before)" : "decreasing \(before - (last.stitches ?? 0))"), last.texts[0])
                }
            }
        }
        XCTAssertGreaterThan(adjusted, 0)
        XCTAssertEqual(Engines.hat(.ribbed, head: 16, gauge: YarnWeight.superBulky.gauge).steps.first { $0.texts[0].contains("evenly") }?.texts[0], "Knit, decreasing 4 evenly: work (k7, k2tog) 4 times")
    }

    /// K-21: a ribbed brim is worked on the smaller needle, and the body on the larger one.
    func testRibbedBrimsAreOnTheSmallerNeedle() {
        for design in [Design.ribbedBeanie, .slouchHat] {
            for size in design.sizes {
                for weight in YarnWeight.allCases {
                    let gauge = weight.gauge
                    let plan = design.plan(measures: size.values, gauge: gauge)
                    let label = "\(design) \(size.name) \(weight)"
                    XCTAssertTrue(plan.steps[0].texts[0].contains("with the smaller needle"), label)
                    XCTAssertTrue(plan.materials.contains { $0.hasPrefix(gauge.ribNeedle.label) && $0.contains("for the brim") }, label)
                    XCTAssertTrue(plan.materials.contains { $0.hasPrefix(gauge.needle.label) && $0.contains("for the body") }, label)
                    XCTAssertTrue(plan.steps.first { $0.section == "Body" }?.texts[0].hasPrefix("Change to the larger needle") == true, label)
                }
            }
        }
        XCTAssertFalse(Design.rolledBrimHat.plan(measures: [:], gauge: YarnWeight.worsted.gauge).steps.contains { $0.texts.contains { $0.contains("larger needle") } })
    }

    /// K-29: a piece worked in the round says "rounds" in its gauge and never calls a round a row. Flat
    /// pieces keep "rows".
    func testRoundPiecesSayRound() {
        everyPlan { design, input, gauge, plan in
            let label = "\(design.rawValue) \(input) \(gauge.stitches)"
            let round = ["Join in the round", "Work in the round"].contains(where: plan.steps[0].texts[0].contains)
            let gaugeLine = plan.materials.last { $0.hasPrefix("Gauge") } ?? ""
            XCTAssertTrue(gaugeLine.contains(round ? " rounds over" : " rows over"), "\(label): \(gaugeLine)")
            guard round else { return }
            for (tap, text) in plan.steps.enumerated().flatMap({ index, step in (0..<step.rows).map { (index, step.text(at: $0)) } }) where !text.hasSuffix("turn") {
                let words = text.replacingOccurrences(of: "short row", with: "", options: .caseInsensitive)
                XCTAssertNil(words.range(of: "\\brows?\\b", options: [.regularExpression, .caseInsensitive]), "\(label) step \(tap): \(text)")
            }
        }
    }

    /// K-29: the counter's label can ask the plan whether a tap is a round or a row.
    func testPlanNamesRoundsAndRows() {
        let hat = Engines.hat(.ribbed, head: 22, gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(hat.unit(at: 1), "Round")
        XCTAssertEqual(hat.unit(at: hat.totalTaps - 1), "Round")
        let scarf = Engines.scarf(.garter, width: 7, length: 64, gauge: YarnWeight.worsted.gauge)
        XCTAssertEqual(scarf.unit(at: 1), "Row")
        let mitts = Engines.handwarmers(hand: 7.5, gauge: YarnWeight.worsted.gauge)
        let slit = mitts.sections.first { $0.name.hasSuffix("Thumb Opening") }?.tap ?? 0
        let upper = mitts.sections.first { $0.name.hasSuffix("Upper Hand") }?.tap ?? 0
        XCTAssertEqual(mitts.unit(at: slit), "Row")
        XCTAssertEqual(mitts.unit(at: upper), "Round")
        let sweater = Design.raglanPullover.plan(measures: [:], gauge: YarnWeight.worsted.gauge)
        let neck = sweater.sections.first { $0.name == "Back Neck" }?.tap ?? 0
        XCTAssertEqual(sweater.unit(at: neck), "Round")
        XCTAssertEqual(sweater.unit(at: neck + 1), "Row")
        let sleeve = sweater.sections.first { $0.name == "First Sleeve" }?.tap ?? 0
        XCTAssertEqual(sweater.unit(at: sleeve + 2), "Round")
    }

    /// K-05: German short rows across the back and sleeves raise the back neck before the yoke grows.
    /// They turn an even number of times, so the yoke starts with the right side facing.
    func testRaglanRaisesTheBackNeck() {
        for gauge in gauges {
            for chest in stride(from: 29.0, through: 65.0, by: 4) {
                let r = Engines.raglan(chest: chest, body: 15, sleeve: 18, gauge: gauge)
                let label = "chest \(chest) gauge \(gauge.stitches)"
                let steps = r.plan.steps.filter { $0.section == "Back Neck" }
                let rows = steps.flatMap { step in (0..<step.rows).map { step.text(at: $0) } }
                let turns = rows.filter { $0.hasSuffix(", turn") }.count
                XCTAssertGreaterThanOrEqual(turns, 4, label)
                XCTAssertEqual(turns % 2, 0, label)
                XCTAssertTrue(rows[1].hasPrefix("Short row"), label)
                XCTAssertEqual(rows.last, "Knit 1 round, knitting each double stitch as one stitch", label)
                XCTAssertTrue(steps.allSatisfy { $0.stitches == r.neck && $0.delta == 0 }, label)
                // Front and back differ: the back gets the short rows, about an inch of them.
                let back = turns
                XCTAssertGreaterThanOrEqual(Double(back) / gauge.rpi, 0.5, label)
                XCTAssertLessThanOrEqual(Double(back) / gauge.rpi, 1.6, label)
                // The turns step into the front from each side, and never meet in the middle.
                let reach = Int(rows.first { $0.contains("as one stitch, k") }?.split(separator: "k").last?.split(separator: ",").first ?? "0") ?? 0
                XCTAssertLessThan(reach * (turns / 2 - 1), r.backAtNeck / 2, label)
            }
        }
        let plan = Design.raglanPullover.plan(measures: [:], gauge: YarnWeight.worsted.gauge)
        XCTAssertTrue(plan.abbreviations.contains { $0.term == "double stitch" })
        XCTAssertTrue(plan.abbreviations.contains { $0.term == "inc across" })
    }

    /// K-16: the yoke, divide and pick-up are short sentences a knitter can keep their place in.
    func testRaglanInstructionsAreShortSentences() {
        for gauge in gauges {
            for chest in [29.0, 41, 65] {
                let plan = Engines.raglan(chest: chest, body: 15, sleeve: 18, gauge: gauge).plan
                for text in plan.steps.flatMap(\.texts) {
                    XCTAssertLessThanOrEqual(text.count, 160, text)
                    for sentence in text.components(separatedBy: ". ") { XCTAssertLessThanOrEqual(sentence.count, 100, sentence) }
                }
                for step in plan.steps where step.section == "Yoke" { XCTAssertLessThanOrEqual(step.texts[0].count, 120, step.texts[0]) }
                XCTAssertEqual(plan.steps.filter { $0.section == "Divide" }.count, 4)
            }
        }
    }

    /// K-25: sleeve increases are spread from the neck to the underarm. Only the body increases on
    /// back-to-back rounds, and only when the yoke is too short to space its increases out.
    func testRaglanSleevesGrowThroughTheWholeYoke() {
        for gauge in gauges {
            for chest in stride(from: 29.0, through: 65.0, by: 2) {
                let r = Engines.raglan(chest: chest, body: 15, sleeve: 18, gauge: gauge)
                let label = "chest \(chest) gauge \(gauge.stitches)"
                let rounds = r.plan.steps.filter { $0.section == "Yoke" }.flatMap { step in (0..<step.rows).map { step.text(at: $0) } }
                XCTAssertEqual(rounds.count, r.yokeRounds, label)
                let sleeveAt = rounds.indices.filter { rounds[$0].hasPrefix("*Inc across") || rounds[$0].hasPrefix("Inc across the sleeve") }
                let bodyAt = rounds.indices.filter { rounds[$0].hasPrefix("*Inc across") || rounds[$0].contains("Inc across the front") }
                XCTAssertEqual(sleeveAt.count, r.sleeveIncreases, label)
                XCTAssertEqual(bodyAt.count, r.bodyIncreases, label)
                guard r.bodyIncreases >= r.sleeveIncreases, let lastBody = bodyAt.last, let lastSleeve = sleeveAt.last else { continue }
                let spacing = Double(lastBody + 1) / Double(r.sleeveIncreases)
                let gaps = zip(sleeveAt, sleeveAt.dropFirst()).map { $1 - $0 }
                if 2 * r.sleeveIncreases <= r.yokeRounds { XCTAssertGreaterThanOrEqual(gaps.min() ?? 2, 2, label) }
                XCTAssertLessThanOrEqual(Double(gaps.max() ?? 0), spacing + 2, label)
                // The sleeves grow until close to where the body stops.
                XCTAssertLessThanOrEqual(Double(lastBody - lastSleeve), spacing + 2, label)
            }
        }
        // The 5X in worsted used to stop the sleeves 20 rounds before the underarm.
        let large = Engines.raglan(chest: 65, body: 17.5, sleeve: 20, gauge: YarnWeight.worsted.gauge)
        let rounds = large.plan.steps.filter { $0.section == "Yoke" }.flatMap { step in (0..<step.rows).map { step.text(at: $0) } }
        let lastSleeve = rounds.lastIndex { $0.hasPrefix("*Inc across") || $0.hasPrefix("Inc across the sleeve") } ?? 0
        XCTAssertGreaterThanOrEqual(lastSleeve, large.yokeRounds - 3)
    }

    /// K-19: garter in the round slips the first stitch of each purl round to hide the jog, and the
    /// Chunky Cowl starts in chunky (bulky) yarn.
    func testChunkyCowlHidesTheJog() {
        XCTAssertEqual(Design.chunkyCowl.weight, .bulky)
        for size in Design.chunkyCowl.sizes {
            let plan = Design.chunkyCowl.plan(measures: size.values, gauge: Design.chunkyCowl.weight.gauge)
            let rounds = plan.steps.filter { !$0.isAction }.flatMap(\.texts)
            XCTAssertTrue(rounds.contains("Knit"))
            XCTAssertFalse(rounds.contains("Purl"))
            XCTAssertTrue(rounds.contains { $0.hasPrefix("Slip the first stitch purlwise, then purl") })
        }
    }

    /// K-30: leg warmers grip with a deep rib at the top and narrow toward the ankle.
    func testLegWarmersNarrowTowardTheAnkle() {
        everyPlan { design, input, gauge, plan in
            guard design == .legWarmers else { return }
            let label = "\(input) \(gauge.stitches)"
            let top = plan.steps.filter { $0.section == "Leg Warmer 1 · Top" && !$0.isAction }
            let ankle = plan.steps.filter { $0.section == "Leg Warmer 1 · Ankle" && !$0.isAction }
            let caston = plan.steps[0].stitches ?? 0
            let narrow = ankle.first?.stitches ?? 0
            XCTAssertGreaterThanOrEqual(top.reduce(0) { $0 + $1.rows }, ankle.reduce(0) { $0 + $1.rows }, label)
            XCTAssertEqual(narrow % 4, 0, label)
            let taper = 1 - Double(narrow) / Double(caston)
            XCTAssertTrue((0.08...0.22).contains(taper), "\(label): \(taper)")
            for step in plan.steps where step.delta < 0 { XCTAssertGreaterThanOrEqual(step.texts.count, 2, label) }
        }
    }

    // MARK: Library of 32, 2026-11-16

    private func inputs(_ design: Design) -> [[String: Double]] {
        var inputs = design.sizes.map(\.values)
        inputs.append(Dictionary(uniqueKeysWithValues: design.measures.map { ($0.key, $0.range.lowerBound) }))
        inputs.append(Dictionary(uniqueKeysWithValues: design.measures.map { ($0.key, $0.range.upperBound) }))
        return inputs
    }

    private func rows(_ plan: PatternPlan, _ section: String) -> [(text: String, stitches: Int)] {
        plan.steps.filter { $0.section == section && !$0.isAction }.flatMap { step in (0..<step.rows).map { (step.text(at: $0), step.stitches(after: $0) ?? 0) } }
    }

    private func numbers(_ text: String) -> [Int] {
        text.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
    }

    /// 38 shapes shipped in 1.0 with 7 colorwork designs bundled on them, the 45 the store listing promises,
    /// and every design added since. Raise both counts with each one.
    @MainActor func testTheLibraryHoldsEveryDesign() {
        XCTAssertEqual(Design.allCases.count, 68)
        XCTAssertEqual(Design.allCases.count + TopicalStore.collection.count, 105)
        XCTAssertEqual(Design.allCases.filter(\.isFree), [.garterScarf, .dishcloth])
        XCTAssertEqual(Set(Design.allCases.map(\.shelf)).count, Design.Shelf.allCases.count)
    }

    /// A flat stretch worked inside a round piece hands the work back with the right side facing: an even
    /// number of turns before the next round, unless it is bound off.
    func testFlatStretchesInRoundPiecesEndOnTheRightSide() {
        everyPlan { design, input, gauge, plan in
            guard plan.steps[0].texts[0].contains("Join in the round") else { return }
            var turns = 0
            for step in plan.steps {
                for row in 0..<step.rows {
                    let text = step.text(at: row)
                    if text.hasSuffix(", turn") { turns += 1; continue }
                    if turns > 0, !text.hasPrefix("Bind off") {
                        XCTAssertEqual(turns % 2, 0, "\(design.rawValue) \(input) \(gauge.stitches): \(step.section) hands back the wrong side")
                    }
                    turns = 0
                }
            }
        }
    }

    /// Works a heel turn stitch by stitch. The gap is where the last row turned: past it are stitches the last
    /// row did not work. The first two rows leave as many on each side, each row after decreases across the gap,
    /// and the last row uses the last stitch.
    func testHeelTurnWorksEveryStitch() {
        for heel in stride(from: 8, through: 64, by: 2) {
            let turn = Engines.heelTurn(heel)
            let label = "heel \(heel)"
            // The row each stitch was last worked on, -1 for none. The front of `ahead` is the next stitch.
            var ahead = Array(repeating: -1, count: heel), behind: [Int] = []
            for (index, row) in turn.rows.enumerated() {
                func move(_ count: Int) {
                    for _ in 0..<count {
                        guard !ahead.isEmpty else { return XCTFail("\(label) row \(index + 1): runs out of stitches") }
                        ahead.removeFirst()
                        behind.insert(index, at: 0)
                    }
                }
                let parts = row.components(separatedBy: ", ")
                XCTAssertEqual(parts.last, "turn", label)
                for part in parts.dropLast() {
                    switch part {
                    case "Slip 1 purlwise": move(1)
                    case "ssk", "p2tog":
                        guard ahead.count >= 2 else { XCTFail("\(label) row \(index + 1): nothing to decrease into"); break }
                        if index >= 2 { XCTAssertTrue(ahead[0] == index - 1 && ahead[1] != index - 1, "\(label) row \(index + 1): the decrease must close the gap") }
                        ahead.removeFirst(2)
                        behind.insert(index, at: 0)
                    case "knit to 1 stitch before the gap", "purl to 1 stitch before the gap":
                        let cup = ahead.prefix { $0 == index - 1 }.count
                        XCTAssertGreaterThan(cup, 0, label)
                        move(cup - 1)
                    default:
                        let count = Int(part.dropFirst()) ?? -1
                        XCTAssertTrue(["k", "p"].contains(part.prefix(1)) && count > 0, "\(label): \(part)")
                        move(max(0, count))
                    }
                }
                if index == 1 { XCTAssertEqual(ahead.count, behind.filter { $0 != 1 }.count, "\(label): the cup is off center") }
                if index == turn.rows.count - 1 { XCTAssertTrue(ahead.isEmpty, "\(label): stitches left past the gap") }
                swap(&ahead, &behind)
            }
            XCTAssertEqual(ahead.count + behind.count, turn.left, label)
            XCTAssertEqual(turn.rows.count % 2, 0, label)
        }
        // A 32-stitch heel turns the classic way, to 18 stitches.
        XCTAssertEqual(Array(Engines.heelTurn(32).rows.prefix(2)), ["Slip 1 purlwise, k17, ssk, k1, turn", "Slip 1 purlwise, p5, p2tog, p1, turn"])
        XCTAssertEqual(Engines.heelTurn(32).left, 18)
    }

    func testSocksComeBackToTheFootCount() {
        for input in inputs(.cuffDownSocks) {
            for gauge in gauges {
                let sock = Engines.socks(foot: input["foot"] ?? 0, length: input["footLength"] ?? 0, leg: input["leg"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let plan = sock.plan
                XCTAssertEqual(sock.stitches % 4, 0, label)
                XCTAssertEqual(sock.heel * 2, sock.stitches, label)
                XCTAssertEqual(sock.flapRows % 2, 0, label)
                XCTAssertEqual(sock.pickedUp, sock.flapRows / 2 + 1, label)
                XCTAssertEqual(rows(plan, "Sock 1 · Heel Turn").last?.stitches, sock.turned, label)
                let picked = plan.steps.first { $0.section == "Sock 1 · Gusset" && $0.stitches != nil }?.stitches
                XCTAssertEqual(picked, sock.turned + 2 * sock.pickedUp + sock.heel, label)
                let gusset = rows(plan, "Sock 1 · Gusset")
                XCTAssertEqual(gusset.last?.stitches, sock.stitches, label)
                XCTAssertEqual(gusset.filter { $0.text.contains("ssk") }.count, sock.gussetDecreases, label)
                XCTAssertTrue(rows(plan, "Sock 1 · Foot").allSatisfy { $0.stitches == sock.stitches }, label)
                let toe = rows(plan, "Sock 1 · Toe")
                XCTAssertEqual(toe.last?.stitches, sock.toe, label)
                XCTAssertEqual(sock.toe % 4, 0, label)
                XCTAssertGreaterThanOrEqual(sock.toe, 8, label)
                XCTAssertTrue(plan.steps.contains { $0.texts[0].contains("the \(sock.toe / 2) instep stitches") && $0.texts[0].contains("Kitchener") }, label)
                // Both socks alike.
                XCTAssertEqual(plan.steps.filter { $0.section.hasPrefix("Sock 1") }.map(\.texts), plan.steps.filter { $0.section.hasPrefix("Sock 2") }.map(\.texts), label)
            }
        }
        // A worsted medium sock fits the foot it was sized for, from the back of the heel to the toe, within a round or two.
        let gauge = YarnWeight.fingering.gauge
        let sock = Engines.socks(foot: 8, length: 9.5, leg: 6.5, gauge: gauge)
        let rounds = ["Sock 1 · Heel Turn", "Sock 1 · Gusset", "Sock 1 · Foot", "Sock 1 · Toe"].map { rows(sock.plan, $0).count }.reduce(0, +)
        XCTAssertEqual(Double(rounds) / gauge.rpi, 9.5 * 0.95, accuracy: 0.3)
        XCTAssertTrue(sock.plan.abbreviations.contains { $0.term == "Kitchener stitch" })
        XCTAssertTrue(sock.plan.abbreviations.contains { $0.term == "p2tog" })
    }

    func testToeUpSocksGrowToTheFootAndCloseAtTheHeel() {
        for input in inputs(.toeUpSocks) {
            for gauge in gauges {
                let sock = Engines.toeUpSocks(foot: input["foot"] ?? 0, length: input["footLength"] ?? 0, leg: input["leg"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let plan = sock.plan
                XCTAssertEqual(sock.stitches % 4, 0, label)
                XCTAssertEqual(sock.toe, Engines.wedgeEnd(sock.stitches), label)
                XCTAssertEqual(plan.steps.first?.stitches, sock.toe, label)
                XCTAssertTrue(plan.steps[0].texts[0].contains("Judy's magic cast-on, \(sock.toe / 2) on each"), label)
                XCTAssertEqual(rows(plan, "Sock 1 · Toe").last?.stitches, sock.stitches, label)
                XCTAssertTrue(rows(plan, "Sock 1 · Foot").allSatisfy { $0.stitches == sock.stitches }, label)
                XCTAssertTrue(rows(plan, "Sock 1 · Foot").last?.text.contains("knit the \(sock.stitches / 2) sole stitches") == true, label)
                let heel = plan.steps.filter { $0.section == "Sock 1 · Heel" }
                XCTAssertEqual(heel.compactMap(\.stitches).first, sock.stitches + 2, label)
                XCTAssertEqual(rows(plan, "Sock 1 · Heel").last?.stitches, sock.toe, label)
                XCTAssertTrue(heel.last?.texts[0].contains("the \(sock.toe / 2) stitches on each side") == true, label)
                XCTAssertEqual(plan.steps.filter { $0.section.hasPrefix("Sock 1") }.map(\.texts), plan.steps.filter { $0.section.hasPrefix("Sock 2") }.map(\.texts), label)
            }
        }
        // A medium sock fits its foot from the back of the heel to the toe, within a round or two.
        let gauge = Design.toeUpSocks.gauge(for: .fingering)
        let sock = Engines.toeUpSocks(foot: 8, length: 9.5, leg: 6.5, gauge: gauge)
        let rounds = ["Sock 1 · Toe", "Sock 1 · Foot", "Sock 1 · Heel"].map { rows(sock.plan, $0).count }.reduce(0, +)
        XCTAssertEqual(Double(rounds) / gauge.rpi, 9.5 * 0.95, accuracy: 0.3)
        XCTAssertTrue(sock.plan.materials[0].contains("fingering weight"), sock.plan.materials[0])
        XCTAssertTrue(sock.plan.abbreviations.contains { $0.term == "Judy's magic cast-on" })
        XCTAssertTrue(sock.plan.abbreviations.contains { $0.term == "M1L" })
    }

    /// The top-down crown is the ribbed beanie's crown read upward, and the brim lands in the hat ease band.
    func testTopDownBeanieGrowsItsCrownAndFitsTheHead() {
        for input in inputs(.topDownBeanie) {
            for gauge in gauges {
                let hat = Engines.topDownBeanie(head: input["head"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(hat.stitches % 8, 0, label)
                let crown = rows(hat.plan, "Crown")
                XCTAssertEqual(crown.count, hat.crownRounds, label)
                XCTAssertEqual(crown.first?.stitches, 16, label)
                XCTAssertEqual(crown.last?.stitches, hat.stitches, label)
                XCTAssertEqual(crown.count, Engines.crownRounds(wedge: hat.stitches / 8).count, label)
                let brim = rows(hat.plan, "Brim")
                let head = input["head"] ?? 0
                let ease = Double(brim.last?.stitches ?? 0) / gauge.spi / head
                XCTAssertTrue((Engines.hatEase.lowerBound - 0.01...Engines.hatEase.upperBound + 0.01).contains(ease), "\(label): ease \(ease)")
                XCTAssertTrue(hat.plan.steps.last?.texts[0].contains("8 cast-on stitches") == true, label)
            }
        }
    }

    /// Each poncho panel is twice as long as it is wide, so each end covers half the other's side.
    func testPonchoPanelsAreTwiceAsLongAsWide() {
        for input in inputs(.poncho) {
            for gauge in gauges {
                let plan = Design.poncho.plan(measures: input, gauge: gauge)
                let width = Double(plan.steps[0].stitches ?? 0) / gauge.spi
                let long = Double(rows(plan, "Panel 1").count) / gauge.rpi
                XCTAssertEqual(long / width, 2, accuracy: 0.25, "\(input) \(gauge.stitches)")
                XCTAssertEqual(rows(plan, "Panel 1").count % 2, 0)
            }
        }
    }

    /// One stocking, not a pair, as wide as asked, with a loop to hang it by.
    @MainActor func testTheStockingIsOneSockWithALoop() {
        for input in inputs(.christmasStocking) {
            for gauge in gauges {
                let plan = Design.christmasStocking.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertFalse(plan.steps.contains { $0.section.hasPrefix("Sock") }, label)
                XCTAssertEqual(plan.steps.filter { $0.texts[0].hasPrefix("Cast on") }.count, 1, label)
                XCTAssertEqual(Double(plan.steps[0].stitches ?? 0) / gauge.spi, input["around"] ?? 0, accuracy: 4.5 / gauge.spi, label)
                XCTAssertTrue(plan.steps.last?.texts[0].contains("braid") == true, label)
            }
        }
        XCTAssertEqual(LibrarySearch.find("christmas", in: Design.allCases.map { LibraryItem.builtIn($0) }).first?.id, Design.christmasStocking.rawValue)
    }

    /// Knit straight and square: as tall as it is wide, with a garter frame of the same width all round.
    @MainActor func testTheWashclothIsSquare() {
        for input in inputs(.washcloth) {
            for gauge in gauges {
                let plan = Design.washcloth.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let side = input["side"] ?? 0
                XCTAssertEqual(Double(plan.steps[0].stitches ?? 0) / gauge.spi, side, accuracy: 1 / gauge.spi, label)
                let body = plan.steps.filter { $0.section == "Body" }.map(\.rows).reduce(0, +)
                let border = plan.steps.filter { $0.section.hasSuffix("Border") && !$0.isAction }.map(\.rows).reduce(0, +)
                let tall = Double(body) / gauge.rpi + Double(border) / (gauge.spi * 2)
                XCTAssertEqual(tall, side, accuracy: side * 0.1, label)
            }
        }
        XCTAssertTrue(LibrarySearch.find("dishcloth", in: Design.allCases.map { LibraryItem.builtIn($0) }).contains { $0.id == Design.washcloth.rawValue })
    }

    /// The knot hat narrows by 8 a round to a tube no more than half the hat, long enough to tie.
    func testTheKnotHatNarrowsToATube() {
        for input in inputs(.knotHat) {
            for gauge in gauges {
                let hat = Engines.knotHat(head: input["head"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(hat.stitches % 8, 0, label)
                XCTAssertLessThanOrEqual(hat.tube * 2, hat.stitches, label)
                XCTAssertGreaterThanOrEqual(hat.tube, 16, label)
                let tube = hat.plan.steps.last { $0.texts == ["Knit"] && $0.stitches == hat.tube }
                XCTAssertGreaterThanOrEqual(Double(tube?.rows ?? 0) / gauge.rpi, 3.5, label)
                XCTAssertTrue(hat.plan.steps.last?.texts[0].contains("knot") == true, label)
            }
        }
    }

    /// One edge grows a stitch every sixth row, so the slope comes out at the wingspan asked for, three times the depth.
    func testTheAsymmetricShawlSlopesToItsWingspan() {
        for input in inputs(.asymmetricShawl) {
            for gauge in gauges {
                let plan = Design.asymmetricShawl.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let rows = plan.steps.filter { !$0.isAction }.map(\.rows).reduce(0, +)
                let long = Double(rows) / (gauge.spi * 2)
                let deep = Double(plan.steps.compactMap(\.stitches).max() ?? 0) / gauge.spi
                XCTAssertEqual((long * long + deep * deep).squareRoot(), input["wingspan"] ?? 0, accuracy: (input["wingspan"] ?? 0) * 0.05, label)
                XCTAssertEqual(long / deep, 3, accuracy: 0.3, label)
            }
        }
    }

    /// The point grows to a little under half the round, ends on a wrong-side row, and the neck closes the round.
    func testTheBandanaPointJoinsTheNeck() {
        for input in inputs(.bandanaCowl) {
            for gauge in gauges {
                let cowl = Engines.bandanaCowl(around: input["around"] ?? 0, height: input["height"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(cowl.stitches % 4, 0, label)
                XCTAssertTrue((0.3...0.5).contains(Double(cowl.front) / Double(cowl.stitches)), label)
                let point = cowl.plan.steps.filter { $0.section == "Point" && !$0.isAction }
                XCTAssertEqual(point.map(\.rows).reduce(0, +) % 2, 0, label)
                XCTAssertEqual(point.last?.stitches(after: (point.last?.rows ?? 1) - 1), cowl.front, label)
            }
        }
    }

    /// The warmer widens from the hand to the arm in pairs, keeping a multiple of 4 for the top rib, and the
    /// thumb slit hands the work back with the right side facing.
    func testArmWarmersWidenToTheArm() {
        for input in inputs(.armWarmers) {
            for gauge in gauges {
                let warmers = Engines.armWarmers(wrist: input["wrist"] ?? 0, arm: input["arm"] ?? 0, length: input["length"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(warmers.top % 4, 0, label)
                XCTAssertGreaterThanOrEqual(warmers.top, warmers.hand, label)
                let slit = warmers.plan.steps.first { $0.section.hasSuffix("Thumb Opening") }
                XCTAssertEqual((slit?.rows ?? 1) % 2, 0, label)
                let rows = warmers.plan.steps.filter { $0.section.hasPrefix("Arm Warmer 1") && !$0.isAction }.map(\.rows).reduce(0, +)
                XCTAssertEqual(Double(rows) / gauge.rpi, input["length"] ?? 0, accuracy: 1, label)
            }
        }
    }

    /// The watch cap stays in rib to the top: every round before the crown is k2, p2, and the crown keeps
    /// a rib of its own until the last two rounds.
    func testTheWatchCapIsRibbedToTheCrown() {
        for input in inputs(.watchCap) {
            for gauge in gauges {
                let plan = Design.watchCap.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual((plan.steps[0].stitches ?? 0) % 8, 0, label)
                XCTAssertTrue(plan.steps.filter { ["Brim", "Body"].contains($0.section) && !$0.isAction }.allSatisfy { $0.texts == ["*K2, p2; repeat from * around"] }, label)
                let tall = Double(plan.steps.filter { !$0.isAction }.map(\.rows).reduce(0, +)) / gauge.rpi
                XCTAssertGreaterThan(tall, (input["head"] ?? 0) * 0.37 + 1, label)
            }
        }
    }

    /// The hood is twice the seam long and about half the head deep, and the piece narrows back to the scarf.
    func testTheHoodedScarfHasAHoodToSeam() {
        for input in inputs(.hoodedScarf) {
            for gauge in gauges {
                let scarf = Engines.hoodedScarf(head: input["head"] ?? 0, length: input["length"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let middle = scarf.plan.steps.filter { ["Increase", "Hood", "Decrease"].contains($0.section) }.map(\.rows).reduce(0, +)
                XCTAssertEqual(Double(middle) / (gauge.spi * 2), scarf.seam * 2, accuracy: 4 / gauge.spi, label)
                XCTAssertEqual(Double(scarf.hood) / gauge.spi, (input["head"] ?? 0) * 0.5, accuracy: max(1, 4 / gauge.spi), label)
                XCTAssertEqual(scarf.plan.steps.last { $0.section == "Scarf" && !$0.isAction }?.stitches, scarf.end, label)
            }
        }
    }

    /// A coaster grows by eight stitches every other round to the size asked for, so it lies flat.
    func testTheCoasterGrowsToItsSize() {
        for input in inputs(.coasters) {
            for gauge in gauges {
                let plan = Design.coasters.plan(measures: input, gauge: gauge)
                let counts = plan.steps.compactMap(\.stitches)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(counts.first, 8, label)
                XCTAssertTrue(counts.allSatisfy { $0 % 8 == 0 }, label)
                let across = Double(counts.max() ?? 0) / (Double.pi * gauge.spi)
                XCTAssertEqual(across, input["diameter"] ?? 0, accuracy: max(0.5, 8 / (Double.pi * gauge.spi)), label)
            }
        }
    }

    /// A baby mitten has no thumb: the hand is one tube to a top gathered to a quarter of its stitches.
    func testBabyMittensGatherAtTheTop() {
        for input in inputs(.babyMittens) {
            for gauge in gauges {
                let plan = Design.babyMittens.plan(measures: input, gauge: gauge)
                let counts = plan.steps.compactMap(\.stitches)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(counts.max(), counts.first, label)
                XCTAssertEqual(counts.last, (counts.first ?? 0) / 4, label)
                XCTAssertFalse(plan.steps.contains { $0.section.contains("Thumb") }, label)
            }
        }
    }

    /// The cat ear hat keeps every stitch to the top, where its halves meet in a three-needle bind off.
    func testTheCatEarHatClosesFlat() {
        for input in inputs(.catHat) {
            for gauge in gauges {
                let plan = Design.catHat.plan(measures: input, gauge: gauge)
                let counts = Set(plan.steps.compactMap(\.stitches))
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(counts.count, 1, label)
                XCTAssertEqual((counts.first ?? 1) % 4, 0, label)
                XCTAssertTrue(plan.steps.contains { step in step.texts.contains { $0.contains("three-needle bind off") } }, label)
            }
        }
    }

    /// The tea cozy's two sides end on a wrong-side row, join into one round and close to 8 stitches.
    func testTheTeaCozySidesJoinOverThePot() {
        for input in inputs(.teaCozy) {
            for gauge in gauges {
                let plan = Design.teaCozy.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                for side in ["First Side", "Second Side"] {
                    let rows = plan.steps.filter { $0.section == side && !$0.isAction }.map(\.rows).reduce(0, +)
                    XCTAssertEqual(rows % 2, 0, "\(label) \(side)")
                }
                let half = plan.steps.first?.stitches ?? 0
                XCTAssertEqual(plan.steps.first { $0.section == "Top" }?.stitches, half * 2, label)
                XCTAssertEqual(plan.steps.last { $0.stitches != nil }?.stitches, 8, label)
            }
        }
    }

    /// A boot cuff is one tube to the height asked for: rib, seed stitch, rib.
    func testBootCuffsReachTheirHeight() {
        for input in inputs(.bootCuffs) {
            for gauge in gauges {
                let plan = Design.bootCuffs.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(Set(plan.steps.compactMap(\.stitches)).count, 1, label)
                let rounds = plan.steps.filter { !$0.isAction }.map(\.rows).reduce(0, +)
                XCTAssertEqual(Double(rounds) / gauge.rpi, max(input["height"] ?? 0, 8 / gauge.rpi), accuracy: 2 / gauge.rpi, label)
            }
        }
    }

    /// Baby socks name the yarn to buy, fingering, not the lace weight their firm gauge reads as.
    func testBabySocksAskForFingering() {
        let plan = Design.babySocks.plan(measures: Design.babySocks.defaultSize.values, gauge: Design.babySocks.gauge(for: .fingering))
        XCTAssertTrue(plan.materials[0].contains("fingering weight"), plan.materials[0])
    }

    /// The bandana is half as deep as it is wide, and its ties are cast on evenly at both ends of the top.
    func testTheBandanaIsHalfAsDeepAsItIsWide() {
        for input in inputs(.bandanaKerchief) {
            for gauge in gauges {
                let plan = Design.bandanaKerchief.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let point = plan.steps.filter { $0.section == "Point" && !$0.isAction }
                let base = point.last.flatMap { $0.stitches(after: $0.rows - 1) } ?? 0
                let rows = point.reduce(0) { $0 + $1.rows }
                XCTAssertEqual(Double(rows) / (gauge.spi * 2), Double(base) / gauge.spi / 2, accuracy: 0.75, label)
                let ties = plan.steps.filter { $0.section == "Ties" }.compactMap(\.stitches)
                XCTAssertEqual((ties.first ?? 0) - base, (ties.dropFirst().first ?? 0) - (ties.first ?? 0), label)
            }
        }
    }

    /// The bottle cover's neck is narrower than its body, and the shoulders widen it to the body count, which
    /// halves at the second marker for the bind off.
    func testTheBottleCoverShouldersReachTheBody() {
        for input in inputs(.bottleCover) {
            for gauge in gauges {
                let plan = Design.bottleCover.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let neck = plan.steps.first?.stitches ?? 0
                let body = plan.steps.first { $0.section == "Body" }?.stitches ?? 0
                XCTAssertLessThan(neck, body, label)
                XCTAssertEqual(neck % 4, 0, label)
                XCTAssertGreaterThanOrEqual(Double(neck) / gauge.spi, 4.5, label)
                XCTAssertTrue(plan.steps.contains { $0.texts.contains { $0.contains("the \(body / 2) stitches before the second marker") } }, label)
            }
        }
    }

    /// The pouch has an even number of eyelets, so the cord comes out where it went in, and halves that
    /// close the bottom with a three-needle bind off.
    func testThePouchCordComesOutWhereItWentIn() {
        for input in inputs(.pouch) {
            for gauge in gauges {
                let plan = Design.pouch.plan(measures: input, gauge: gauge)
                let stitches = plan.steps.first?.stitches ?? 0
                XCTAssertEqual(stitches % 8, 0, "\(input) \(gauge.stitches)")
                XCTAssertTrue(plan.steps.contains { $0.texts.contains { $0.contains("yo, k2tog") } })
                XCTAssertTrue(plan.steps.contains { $0.texts.contains { $0.contains("first \(stitches / 2) stitches") } })
            }
        }
    }

    /// The turtleneck's collar is about 7 in of k2p2 rib on a count it divides into, folded in half to wear.
    func testTheTurtleneckCollarFoldsInHalf() {
        for input in inputs(.turtleneck) {
            for gauge in gauges {
                let plan = Design.turtleneck.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let collar = plan.steps.filter { $0.section == "Collar" && !$0.isAction }
                XCTAssertEqual((collar.first?.stitches ?? 1) % 4, 0, label)
                XCTAssertEqual(Double(collar.reduce(0) { $0 + $1.rows }) / gauge.rpi, 7, accuracy: 0.5, label)
                XCTAssertTrue(plan.steps.last?.text(at: 0).contains("Fold the collar") ?? false, label)
            }
        }
    }

    /// The tee's sleeves stop above the elbow in a narrow band, and they barely taper, so they do not pull in.
    func testTheTeeSleevesEndInABand() {
        for input in inputs(.raglanTee) {
            for gauge in gauges {
                let plan = Design.raglanTee.plan(measures: input, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                let sleeve = plan.steps.filter { $0.section == "First Sleeve" }
                let band = plan.steps.filter { $0.section == "First Sleeve · Band" }
                XCTAssertFalse(band.isEmpty, label)
                XCTAssertLessThanOrEqual(Double(band.filter { !$0.isAction }.reduce(0) { $0 + $1.rows }) / gauge.rpi, 1.1, label)
                let widest = sleeve.compactMap(\.stitches).max() ?? 0, narrowest = band.compactMap(\.stitches).min() ?? 0
                XCTAssertGreaterThanOrEqual(Double(narrowest), Double(widest) * 0.8, label)
                let worked = (sleeve + band).filter { !$0.isAction }.reduce(0) { $0 + $1.rows }
                XCTAssertEqual(Double(worked) / gauge.rpi, input["sleeve"] ?? 0, accuracy: 0.75, label)
            }
        }
    }

    /// The capelet's collar pulls over the head, and its hem rib comes out whole.
    func testTheCapeletCollarPullsOverTheHead() {
        for input in inputs(.capelet) {
            for gauge in gauges {
                let plan = Design.capelet.plan(measures: input, gauge: gauge)
                let counts = plan.steps.compactMap(\.stitches)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertGreaterThanOrEqual(Double(counts.first ?? 0) / gauge.spi, 17.5, label)
                XCTAssertEqual((counts.last ?? 1) % 4, 0, label)
                XCTAssertGreaterThan(Double(counts.last ?? 0) / gauge.spi, input["chest"] ?? 0, label)
            }
        }
    }

    func testMittenThumbGussetAddsUp() {
        for input in inputs(.mittens) {
            for gauge in gauges {
                let mitten = Engines.mittens(hand: input["hand"] ?? 0, length: input["handLength"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(mitten.stitches % 4, 0, label)
                XCTAssertEqual(mitten.gusset, 1 + 2 * mitten.increases, label)
                XCTAssertEqual(mitten.thumb, mitten.gusset + 1, label)
                let ratio = Double(mitten.thumb) / Double(mitten.stitches)
                XCTAssertTrue((0.3...0.45).contains(ratio), "\(label): thumb \(ratio)")
                let gusset = rows(mitten.plan, "Mitten 1 · Thumb Gusset")
                XCTAssertEqual(gusset.filter { $0.text.hasPrefix("M1L") }.count, mitten.increases, label)
                XCTAssertEqual(gusset[gusset.count - 2].stitches, mitten.stitches - 1 + mitten.gusset, label)
                XCTAssertTrue(gusset.last?.text.contains("Slip the \(mitten.gusset) gusset stitches") == true, label)
                XCTAssertEqual(gusset.last?.stitches, mitten.stitches, label)
                let thumb = mitten.plan.steps.filter { $0.section == "Mitten 1 · Thumb" }
                XCTAssertEqual(thumb.first?.stitches, mitten.thumb + 2, label)
                XCTAssertEqual(thumb.dropFirst().first?.stitches, mitten.thumb, label)
                XCTAssertEqual(rows(mitten.plan, "Mitten 1 · Top").last?.stitches, mitten.top, label)
            }
        }
    }

    func testFingerlessMittsGrowAThumbAndEndAtTheKnuckles() {
        for input in inputs(.fingerlessMitts) {
            for gauge in gauges {
                let mitts = Engines.fingerlessMitts(hand: input["hand"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(mitts.stitches % 4, 0, label)
                XCTAssertEqual(mitts.gusset, 1 + 2 * mitts.increases, label)
                XCTAssertEqual(mitts.thumb % 2, 0, "\(label): the thumb rib needs an even count")
                let ratio = Double(mitts.thumb) / Double(mitts.stitches)
                XCTAssertTrue((0.3...0.45).contains(ratio), "\(label): thumb \(ratio)")
                let gusset = rows(mitts.plan, "Mitt 1 · Thumb Gusset")
                XCTAssertEqual(gusset.filter { $0.text.hasPrefix("M1L") }.count, mitts.increases, label)
                XCTAssertEqual(gusset[gusset.count - 2].stitches, mitts.stitches - 1 + mitts.gusset, label)
                XCTAssertEqual(gusset.last?.stitches, mitts.stitches, label)
                XCTAssertTrue(rows(mitts.plan, "Mitt 1 · Top").allSatisfy { $0.stitches == mitts.stitches }, label)
                XCTAssertEqual(rows(mitts.plan, "Mitt 1 · Thumb").last?.stitches, mitts.thumb, label)
                XCTAssertTrue(mitts.plan.steps.last?.texts[0].hasPrefix("Bind off") == true, label)
            }
        }
    }

    func testCardiganFrontsAndBandsMakeTheChest() {
        let adults: [Double] = Design.raglanCardigan.sizes.map { $0.values["chest"] ?? 0 } + [26, 62]
        let babies: [Double] = Design.babyCardigan.sizes.map { $0.values["chest"] ?? 0 } + [14, 24]
        let children: [Double] = Design.kidsCardigan.sizes.map { $0.values["chest"] ?? 0 } + [18, 34]
        for (baby, child, chest) in adults.map({ (false, false, $0) }) + babies.map({ (true, false, $0) }) + children.map({ (false, true, $0) }) {
            for gauge in gauges {
                let c = Engines.cardigan(chest: chest + Design.sweaterEase, wearer: chest, body: baby ? 7 : child ? 11 : 15, sleeve: baby ? 7 : child ? 12 : 18, gauge: gauge, baby: baby, child: child)
                let label = "\(baby ? "baby " : child ? "child " : "")chest \(chest) gauge \(gauge.stitches)"
                XCTAssertEqual(c.body + c.band, c.fit.body, label)
                XCTAssertEqual(2 * c.front + c.fit.panel + 2 * c.fit.underarm, c.body, label)
                XCTAssertEqual(c.neck, c.fit.backAtNeck + 2 * c.frontAtNeck + 2 * c.fit.sleeveAtNeck, label)
                XCTAssertGreaterThanOrEqual(c.frontAtNeck, 2, label)
                XCTAssertGreaterThanOrEqual(c.band, 2, label)
                // The yoke ends on a wrong-side row with the stitches the divide hands out.
                let yoke = rows(c.plan, "Yoke")
                XCTAssertEqual(yoke.count, c.yokeRows, label)
                XCTAssertEqual(c.yokeRows % 2, 0, label)
                XCTAssertEqual(yoke.last?.stitches, 2 * c.front + c.fit.panel + 2 * c.fit.sleeveTop, label)
                for (index, row) in yoke.enumerated() {
                    let right = index % 2 == 0
                    XCTAssertEqual(right, row.text.hasPrefix("K"), "\(label) yoke row \(index + 1): \(row.text)")
                }
                let packed = 2 * max(c.fit.bodyIncreases, c.fit.sleeveIncreases) > c.yokeRows
                if !packed { XCTAssertFalse(yoke.contains { $0.text.contains("M1P") }, label) }
                // The buttonholes: evenly spaced, as far from each end, and the count adds up.
                let gaps = c.buttonholes
                XCTAssertEqual(gaps.count, c.buttons + 1, label)
                XCTAssertEqual(gaps.reduce(0, +) + 2 * c.buttons, c.bandPickUp, label)
                XCTAssertEqual(gaps.first, gaps.last, label)
                let inner = gaps.dropFirst().dropLast()
                XCTAssertLessThanOrEqual((inner.max() ?? 0) - (inner.min() ?? 0), 1, label)
                XCTAssertGreaterThanOrEqual(inner.min() ?? 0, 3, label)
                XCTAssertEqual(c.bandPickUp % 2, 1, label)
                // The holes are worked from the right side: after an odd number of band rows.
                let band = rows(c.plan, "Buttonhole Band")
                let hole = band.firstIndex { $0.text.contains("yo") } ?? 0
                XCTAssertEqual(hole % 2, 1, label)
                let worked = holes(band[hole].text)
                XCTAssertEqual(worked.holes, c.buttons, label)
                XCTAssertEqual(worked.stitches + (gaps.last ?? 0), c.bandPickUp, label)
                XCTAssertEqual(rows(c.plan, "Back Neck").filter { $0.text.hasSuffix(", turn") }.count % 2, 0, label)
                // About one button every 3 in, and every 2 on a baby's.
                let spacing = Double(c.bandPickUp) / gauge.spi / Double(c.buttons)
                XCTAssertTrue((baby ? 1.2...3.25 : 2.4...4).contains(spacing), "\(label): \(spacing)")
            }
        }
        let plan = Design.raglanCardigan.plan(measures: [:], gauge: YarnWeight.worsted.gauge)
        XCTAssertTrue(plan.finished.contains(Sizing.inches(41)), plan.finished)
        XCTAssertTrue(plan.materials.contains { $0.contains("buttons") })
        // A baby's neck is cut smaller than a child's raglan would make it: about 10 to 12 in around.
        for size in Design.babyCardigan.sizes {
            let gauge = YarnWeight.dk.gauge
            let c = Engines.cardigan(chest: (size.values["chest"] ?? 0) + Design.sweaterEase, wearer: size.values["chest"], body: 7, sleeve: 7, gauge: gauge, baby: true)
            XCTAssertTrue((9.5...12.5).contains(Double(c.neck) / gauge.spi), "\(size.name): neck \(Double(c.neck) / gauge.spi)")
            XCTAssertTrue(c.plan.steps.contains { $0.texts[0].contains("To button it the other way") }, size.name)
        }
    }

    /// Reads a buttonhole row back: the stitches it works up to and through its last hole, and how many holes.
    private func holes(_ text: String) -> (stitches: Int, holes: Int) {
        let first = numbers(String(text.prefix { $0 != "," })).first ?? 0
        var stitches = first + 2, holes = 1
        let pattern = try? NSRegularExpression(pattern: "\\(k2tog, yo, work (\\d+) in rib\\) (once|(\\d+) times)")
        for match in pattern?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? [] {
            let gap = Int((text as NSString).substring(with: match.range(at: 1))) ?? 0
            let times = match.range(at: 3).location == NSNotFound ? 1 : Int((text as NSString).substring(with: match.range(at: 3))) ?? 0
            stitches += times * (gap + 2)
            holes += times
        }
        return (stitches, holes)
    }

    func testVestShapingAddsUp() {
        for input in inputs(.sweaterVest) {
            for gauge in gauges {
                let chest = input["chest"] ?? 0
                let v = Engines.vest(chest: chest + Design.sweaterEase, wearer: chest, body: input["body"] ?? 0, gauge: gauge)
                let label = "\(input) \(gauge.stitches)"
                XCTAssertEqual(2 * v.piece, v.body, label)
                XCTAssertEqual(2 * v.shoulder + v.neck, v.shoulders, label)
                XCTAssertGreaterThanOrEqual(v.shoulder, 2, label)
                XCTAssertGreaterThanOrEqual(v.boundOff, 1, label)
                XCTAssertEqual(v.piece / 2 - v.boundOff - v.armholeDecreases - v.neckDecreases, v.shoulder, label)
                for name in ["Front · First Side", "Front · Second Side"] {
                    let side = rows(v.plan, name)
                    XCTAssertEqual(side.count, v.armholeRows, "\(label) \(name)")
                    XCTAssertEqual(side.last?.stitches, v.shoulder, "\(label) \(name)")
                    XCTAssertTrue(side.allSatisfy { $0.text.hasSuffix(", turn") }, label)
                    // Shaping only on right-side rows, besides the second side's armhole bind off.
                    for (index, row) in side.enumerated() where index % 2 == 1 && !row.text.hasPrefix("Bind off") {
                        XCTAssertEqual(row.text, "Purl to the end, turn", label)
                    }
                }
                XCTAssertEqual(rows(v.plan, "Back").last?.stitches, v.shoulders, label)
                XCTAssertEqual(rows(v.plan, "Back").count, v.armholeRows, label)
                // The V is as deep as the armhole and narrows to the back neck's width.
                XCTAssertEqual(v.neckDecreases * 2, v.neck, label)
                let neckband = v.plan.steps.first { $0.section == "Neck Edging" }?.stitches ?? 0
                XCTAssertEqual(neckband % 2, 0, label)
            }
        }
    }

    func testKidsRaglanIsCutForAChild() {
        let gauge = YarnWeight.worsted.gauge
        for size in Design.kidsRaglan.sizes {
            let chest = size.values["chest"] ?? 0
            let child = Engines.raglanFit(chest: chest + Design.sweaterEase, wearer: chest, child: true, gauge: gauge)
            let adult = Engines.raglanFit(chest: chest + Design.sweaterEase, wearer: chest, child: false, gauge: gauge)
            // The neck still stretches over a child's head, the armhole is a child's.
            XCTAssertGreaterThanOrEqual(Double(child.neck) / gauge.spi, 15, size.name)
            XCTAssertTrue((4.5...7.5).contains(child.depth), "\(size.name): \(child.depth)")
            XCTAssertLessThan(child.depth, adult.depth, size.name)
            XCTAssertLessThanOrEqual(Double(child.sleeve) / gauge.spi, child.arm + 0.5, size.name)
            let plan = Design.kidsRaglan.plan(measures: size.values, gauge: gauge)
            XCTAssertTrue(plan.finished.contains(Sizing.inches(chest)), plan.finished)
            // A small body never goes on a needle longer than it is around.
            if Double(child.body) / gauge.spi < 32 { XCTAssertFalse(plan.materials.joined().contains(Sizing.cable(32)), size.name) }
        }
    }

    func testCabledBeanieFitsWholeCables() {
        for head in stride(from: 13.0, through: 26.0, by: 0.5) {
            for gauge in gauges {
                let hat = Engines.cabledBeanie(head: head, gauge: gauge)
                let label = "head \(head) gauge \(gauge.stitches)"
                XCTAssertEqual(hat.stitches, hat.cables * 8, label)
                XCTAssertGreaterThanOrEqual(hat.cables, 3, label)
                let span = 8 / (gauge.spi * 1.2)
                let fits = Engines.hatEase.contains(Double(hat.cables) * span / head)
                let possible = (1...80).contains { Engines.hatEase.contains(Double($0) * span / head) && $0 >= 3 }
                if possible { XCTAssertTrue(fits, "\(label): \(Double(hat.cables) * span / head)") }
                // Every crown round keeps a whole number of stitches in each cable until one is left of each.
                for row in rows(hat.plan, "Crown") where row.stitches >= hat.cables {
                    XCTAssertEqual(row.stitches % hat.cables, 0, "\(label): \(row.text)")
                }
                XCTAssertTrue(rows(hat.plan, "Body").contains { $0.text.contains("C6F") }, label)
                XCTAssertLessThanOrEqual(rows(hat.plan, "Crown").last?.stitches ?? 99, 10, label)
            }
        }
    }

    func testCrescentBindsOffItsIncreases() {
        for input in inputs(.crescentShawl) {
            for gauge in gauges {
                let plan = Design.crescentShawl.plan(measures: input, gauge: gauge)
                let shawl = plan.steps.first { $0.section == "Shawl" }
                let rows = shawl?.rows ?? 0
                XCTAssertEqual(shawl?.delta, 6)
                XCTAssertEqual(shawl?.texts.count, 2)
                // The right-side row adds 4 and the wrong-side row 2: each row states the count it leaves.
                XCTAssertEqual(shawl.flatMap { $0.stitches(after: 0) }, 13)
                XCTAssertEqual(shawl.flatMap { $0.stitches(after: 1) }, 15)
                XCTAssertEqual(shawl.flatMap { $0.stitches(after: 2) }, 19)
                XCTAssertEqual(rows % 2, 0)
                XCTAssertEqual(shawl.flatMap { $0.stitches(after: rows - 1) }, 9 + 3 * rows)
                XCTAssertTrue(plan.steps.last { $0.section == "Finishing" }?.texts[0].contains("all \(9 + 3 * rows) stitches") == true)
            }
        }
    }

    func testSocksDefaultToAFirmSockGauge() {
        let gauge = LibraryItem.builtIn(.cuffDownSocks).defaultGauge
        XCTAssertEqual(gauge, Gauge(stitches: 32, rows: 44))
        XCTAssertEqual(gauge.needle.millimeters, 2.25)
        XCTAssertEqual(Design.cuffDownSocks.plan(measures: Design.cuffDownSocks.defaultSize.values, gauge: gauge).steps[0].stitches, 56)
    }

    func testBasketweaveStartsAndEndsOnTheSameBlock() {
        for input in inputs(.basketweaveBlanket) {
            for gauge in gauges {
                let plan = Design.basketweaveBlanket.plan(measures: input, gauge: gauge)
                let body = plan.steps.first { $0.section == "Body" }
                let first = numbers(body?.texts[0] ?? "")
                let border = first[0], block = first[1]
                let caston = plan.steps[0].stitches ?? 0
                XCTAssertEqual((caston - 2 * border) % block, 0)
                XCTAssertEqual((caston - 2 * border) / block % 2, 1)
                let blockRows = (body?.texts.count ?? 0) / 2
                XCTAssertEqual(blockRows % 2, 0)
                XCTAssertEqual((body?.rows ?? 0) % blockRows, 0)
                XCTAssertEqual((body?.rows ?? 0) / blockRows % 2, 1)
            }
        }
    }

    func testPillowAndBagCountsAddUp() {
        for input in inputs(.pillowCover) {
            for gauge in gauges {
                let pillow = Engines.pillow(side: input["side"] ?? 0, gauge: gauge)
                XCTAssertEqual(pillow.buttonholes.reduce(0, +) + 2 * pillow.buttons, pillow.stitches / 2)
                XCTAssertGreaterThanOrEqual(pillow.buttonholes.dropFirst().dropLast().min() ?? 0, 3)
                let row = rows(pillow.plan, "Buttonhole Band").first { $0.text.contains("yo") }?.text ?? ""
                let worked = holes(row)
                XCTAssertEqual(worked.holes, pillow.buttons)
                XCTAssertEqual(worked.stitches + (pillow.buttonholes.last ?? 0), pillow.stitches / 2)
            }
        }
        for input in inputs(.marketBag) {
            for gauge in gauges {
                let plan = Design.marketBag.plan(measures: input, gauge: gauge)
                let pick = plan.steps.first { $0.section == "Body" && $0.isAction }
                let parts = numbers(pick?.texts[0] ?? "")
                XCTAssertEqual(parts.reduce(0) { $0 + $1 } + (plan.steps[0].stitches ?? 0), pick?.stitches)
                XCTAssertEqual((pick?.stitches ?? 1) % 2, 0)
            }
        }
    }

    func testEarflapsJoinIntoTheHat() {
        for input in inputs(.earflapHat) {
            for gauge in gauges {
                let plan = Design.earflapHat.plan(measures: input, gauge: gauge)
                let flap = rows(plan, "First Earflap").last?.stitches ?? 0
                XCTAssertEqual(rows(plan, "First Earflap").count % 2, 0)
                let join = plan.steps.first { $0.section == "Brim" && $0.isAction }
                let cast = numbers((join?.texts[0] ?? "").replacingOccurrences(of: Sizing.cable(16), with: ""))
                // Cast on, the second flap, cast on, the first flap, cast on.
                XCTAssertEqual(cast.count, 5)
                XCTAssertEqual([cast[1], cast[3]], [flap, flap])
                XCTAssertEqual(cast[0] + cast[2] + cast[4] + 2 * flap, join?.stitches)
                XCTAssertEqual(plan.steps.filter { $0.section == "Ties" && !$0.isAction }.count, 2)
            }
        }
    }

    // MARK: Outlines

    /// Every outline draws inside its square and fills a fair share of it, filled the way the app fills it.
    /// Each drawing is attached to the run, so the shapes can be looked at.
    func testEveryOutlineDraws() throws {
        let silhouettes = Set(Design.allCases.map(\.silhouette)).union([.ears]).sorted { $0.rawValue < $1.rawValue }
        let side = 200
        let frame = CGRect(x: 0, y: 0, width: side, height: side)
        for silhouette in silhouettes {
            let path = GarmentShape.path(silhouette, in: frame)
            XCTAssertFalse(path.isEmpty, silhouette.rawValue)
            XCTAssertTrue(frame.insetBy(dx: -0.5, dy: -0.5).contains(path.boundingBoxOfPath), "\(silhouette): \(path.boundingBoxOfPath)")
            let context = try XCTUnwrap(CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue))
            context.setFillColor(gray: 1, alpha: 1)
            context.fill(frame)
            // The app draws with the y axis pointing down.
            context.translateBy(x: 0, y: CGFloat(side))
            context.scaleBy(x: 1, y: -1)
            context.addPath(path)
            context.setFillColor(gray: 0, alpha: 1)
            context.fillPath(using: .evenOdd)
            let pixels = try XCTUnwrap(context.data).bindMemory(to: UInt8.self, capacity: side * side)
            let share = Double((0..<(side * side)).filter { pixels[$0] < 128 }.count) / Double(side * side)
            XCTAssertTrue((0.1...0.75).contains(share), "\(silhouette) fills \(share)")
            let image = try XCTUnwrap(context.makeImage())
            let attachment = XCTAttachment(image: UIImage(cgImage: image))
            attachment.name = "outline-\(silhouette.rawValue)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
