import CryptoKit
import XCTest
@testable import Ravel

/// The stitch pattern layer: each stitch's rows, the shapes that wear them, and proof that the designs
/// that shipped before it write exactly what they wrote before.
final class StitchTests: XCTestCase {
    private static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    /// Every stitch draws the same fabric flat and in the round: its wrong-side rows, written by hand,
    /// really are the right-side rows seen from the back.
    func testFlatAndRoundRowsMakeTheSameFabric() throws {
        for stitch in Stitch.allCases {
            let m = stitch.multiple
            let flatCount = stitch.extra + m * 4, roundCount = m * 4
            let height = Stitch.lcm(stitch.flat.count, stitch.round.count)
            let flat = try XCTUnwrap(stitch.looks(stitches: flatCount, flat: true, repeats: height / stitch.flat.count), "\(stitch)")
            let round = try XCTUnwrap(stitch.looks(stitches: roundCount, flat: false, repeats: height / stitch.round.count), "\(stitch)")
            let matches = (0..<flatCount).contains { offset in
                (0..<m).contains { phase in
                    (0..<height).allSatisfy { r in
                        (0..<(m * 2)).allSatisfy { c in offset + c < flatCount && flat[r][offset + c] == round[r][(c + phase) % roundCount] }
                    }
                }
            }
            XCTAssertTrue(matches, "\(stitch): its flat rows do not make the fabric its rounds do")
        }
    }

    /// Every row works every stitch and leaves the same count: a lace repeat makes as many as it decreases.
    func testEveryRowKeepsItsCount() {
        for stitch in Stitch.allCases {
            // From two: a row that opens and closes with part of a repeat needs them, and `count(near:)` adds them.
            for repeats in 2...5 {
                let flat = stitch.extra + stitch.multiple * repeats + 6
                XCTAssertNotNil(stitch.looks(stitches: flat, flat: true, border: 3), "\(stitch) flat \(flat)")
                XCTAssertNotNil(stitch.looks(stitches: stitch.multiple * repeats, flat: false), "\(stitch) round")
                if stitch.multiple > 1 { XCTAssertNil(stitch.texts(stitches: flat + 1, flat: true, border: 3), "\(stitch) fits a count it should not") }
            }
        }
    }

    func testRowsReadTheWayPatternsWriteThem() throws {
        let moss = try XCTUnwrap(Stitch.doubleMoss.texts(stitches: 20, flat: true, border: 3))
        XCTAssertEqual(moss[0], "K3, *k2, p2; repeat from * to the last 5 stitches, k5")
        XCTAssertEqual(moss[1], "K3, *p2, k2; repeat from * to the last 5 stitches, p2, k3")
        let waffle = try XCTUnwrap(Stitch.waffle.texts(stitches: 99, flat: false))
        XCTAssertEqual(waffle, ["*P1, k2; repeat from * around", "*P1, k2; repeat from * around", "*P1, k2; repeat from * around", "Purl"])
        let fan = try XCTUnwrap(Stitch.featherFan.texts(stitches: 26, flat: true))
        XCTAssertEqual(fan[2], "K1, *k2tog twice, (yo, k1) 4 times, k2tog twice; repeat from * to the last stitch, k1")
    }

    /// Each shape that takes a stitch, at every size and weight: sound plans whose rows fit their counts.
    func testEveryShapeWearsEveryStitch() {
        for stitch in Stitch.allCases {
            for base in Topical.stitchBases {
                var fit = Engines.Fit()
                fit.stitch = stitch
                for input in TopicalCheck.inputs(for: base) {
                    for weight in [YarnWeight.sport, .worsted, .bulky] {
                        let plan = base.plan(measures: input, gauge: weight.gauge, fit: fit)
                        XCTAssertEqual(PlanCheck.problems(plan), [], "\(stitch) \(base) \(input) \(weight)")
                        let rows = Set([stitch.flat.count, stitch.round.count])
                        let bands = Set([stitch.band(flat: true), stitch.band(flat: false)])
                        XCTAssertTrue(plan.steps.contains { step in rows.contains(step.texts.count) && bands.contains { step.rows % $0 == 0 } && !step.isAction }, "\(stitch) \(base): no whole repeats of the stitch")
                    }
                }
            }
        }
    }

    /// A flat stitch pattern ends on a wrong-side row, so the bind off is worked from the right side.
    func testFlatStitchesEndOnTheWrongSide() {
        for stitch in Stitch.allCases {
            for inches in stride(from: 1.0, through: 30, by: 3.5) {
                XCTAssertEqual(stitch.rows(inches, rpi: 6, flat: true) % 2, 0, "\(stitch)")
                XCTAssertEqual(stitch.rows(inches, rpi: 6, flat: true) % stitch.band(flat: true), 0, "\(stitch)")
            }
        }
    }

    // MARK: Nothing that shipped changes

    /// The 2,229 plans of the designs that shipped, hashed before the stitch layer and the new library
    /// (`scripts/catalog/golden.sh`), are written exactly as before.
    @MainActor func testExistingDesignsAreUnchanged() throws {
        let golden = try String(contentsOf: Self.root.appending(path: "project-docs/catalog/golden.txt"), encoding: .utf8)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        func digest(_ plan: PatternPlan) throws -> String {
            SHA256.hash(data: try encoder.encode(plan)).map { String(format: "%02x", $0) }.joined()
        }
        func label(_ input: [String: Double]) -> String {
            input.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value.formatted())" }.joined(separator: ",")
        }
        var records: [String: Topical] = [:]
        for file in ["Ravel/collection.json", "docs/designs.json"] {
            guard let data = FileManager.default.contents(atPath: Self.root.appending(path: file).path) else { continue }
            for topical in Topical.parse(data).compactMap(\.topical) { records[topical.designRaw] = topical }
        }
        var checked = 0
        for line in golden.split(separator: "\n") {
            let parts = line.split(separator: " ").map(String.init)
            guard parts.count == 4, let weight = YarnWeight(rawValue: parts[2]) else { return XCTFail("Unreadable golden line \(line)") }
            let plan: PatternPlan
            if let design = Design(rawValue: parts[0]) {
                let input = TopicalCheck.inputs(for: design).first { label($0) == parts[1] }
                plan = design.plan(measures: try XCTUnwrap(input, "\(line)"), gauge: design.gauge(for: weight))
            } else {
                let topical = try XCTUnwrap(records[parts[0]], "\(parts[0]) is gone")
                let input = TopicalCheck.inputs(for: topical.base).first { label($0) == parts[1] }
                plan = topical.plan(measures: try XCTUnwrap(input, "\(line)"), gauge: weight.gauge)
            }
            XCTAssertEqual(try digest(plan), parts[3], "\(parts[0]) \(parts[1]) \(parts[2]) changed")
            checked += 1
        }
        XCTAssertEqual(checked, 2229)
    }
}
