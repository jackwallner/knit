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
                    let caston = plan.steps[0].stitches ?? 0
                    XCTAssertEqual(caston % 8, 0)
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
            XCTAssertEqual((Engines.cowl(.seed, around: 26, height: 10, gauge: gauge).steps[0].stitches ?? 0) % 2, 1)
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
                    XCTAssertEqual(yoke.dropFirst().reduce(0) { $0 + $1.rows }, r.yokeRounds, label)

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
}
