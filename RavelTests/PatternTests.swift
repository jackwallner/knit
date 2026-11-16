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
            let round = plan.steps[0].texts[0].contains("Join in the round")
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
}
