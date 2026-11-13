import Foundation

/// Stockinette gauge over 4 inches, the way a yarn label and a swatch state it.
struct Gauge: Codable, Equatable, Sendable {
    var stitches: Double
    var rows: Double

    var spi: Double { stitches / 4 }
    var rpi: Double { rows / 4 }
}

/// One instruction in a generated pattern. Either a single action (cast on,
/// bind off) or a stretch of rows worked the same way.
struct Step: Codable, Equatable, Sendable {
    var section: String
    /// The row instructions, cycled. One entry when every row is the same.
    var texts: [String]
    /// How many taps this step takes.
    var rows: Int
    /// Stitches on the needle after the first cycle. Nil when it does not apply.
    var stitches: Int?
    /// Change in the stitch count per cycle after the first.
    var delta = 0
    /// True for actions that are not a knitted row, so the fabric does not grow.
    var isAction = false

    func text(at row: Int) -> String { texts[row % texts.count] }

    func stitches(after row: Int) -> Int? { stitches.map { $0 + delta * (row / texts.count) } }
}

/// A full pattern, sized: every row, in order, plus what to buy.
struct PatternPlan: Codable, Equatable, Sendable {
    var steps: [Step]
    var materials: [String]
    var finished: String
    var yards: Int

    var totalTaps: Int { steps.reduce(0) { $0 + $1.rows } }

    /// Where a knitter is after `taps` taps. Nil once the pattern is complete.
    func position(at taps: Int) -> (step: Int, row: Int)? {
        var remaining = max(0, taps)
        for (index, step) in steps.enumerated() {
            if remaining < step.rows { return (index, remaining) }
            remaining -= step.rows
        }
        return nil
    }

    /// Knitted rows among the first `taps` taps, for drawing the fabric.
    func knitRows(upTo taps: Int) -> Int {
        var remaining = max(0, taps)
        var rows = 0
        for step in steps {
            let done = min(remaining, step.rows)
            if !step.isAction { rows += done }
            remaining -= done
            if remaining == 0 { break }
        }
        return rows
    }
}

extension PatternPlan {
    private static let glossary: [(term: String, meaning: String)] = [
        ("k2tog", "Knit 2 stitches together"),
        ("ssk", "Slip 2 stitches knitwise one at a time, then knit them together through the back"),
        ("yo", "Yarn over"),
        ("M1", "Make 1: lift the bar between the stitches and knit it through the back"),
        ("M1L", "Make 1 left: lift the bar from the front and knit it through the back"),
        ("M1R", "Make 1 right: lift the bar from the back and knit it through the front"),
        ("C6F", "Cable 6 front: slip 3 stitches to a cable needle and hold it in front, knit 3, then knit the 3 from the cable needle"),
    ]

    /// The abbreviations this pattern uses, spelled out.
    var abbreviations: [(term: String, meaning: String)] {
        let text = steps.flatMap(\.texts).joined(separator: " ")
        return Self.glossary.filter { text.range(of: "\\b\($0.term)\\b", options: [.regularExpression, .caseInsensitive]) != nil }
    }
}

struct PlanBuilder {
    private(set) var steps: [Step] = []
    var section = ""

    /// A one-off action: cast on, join, bind off.
    mutating func action(_ text: String, stitches: Int? = nil) {
        steps.append(Step(section: section, texts: [text], rows: 1, stitches: stitches, isAction: true))
    }

    /// A single knitted row.
    mutating func row(_ text: String, stitches: Int? = nil) {
        steps.append(Step(section: section, texts: [text], rows: 1, stitches: stitches))
    }

    /// `rows` rows cycling through `texts`.
    mutating func work(_ texts: [String], rows: Int, stitches: Int? = nil, delta: Int = 0) {
        guard rows > 0 else { return }
        steps.append(Step(section: section, texts: texts, rows: rows, stitches: stitches, delta: delta))
    }
}

enum Sizing {
    /// Stitches for a width, rounded to a multiple (plus any edge stitches).
    static func stitches(_ inches: Double, per inch: Double, multiple: Int = 1, extra: Int = 0, minimum: Int = 0) -> Int {
        let repeats = max(1, Int(((inches * inch - Double(extra)) / Double(multiple)).rounded()))
        let count = repeats * multiple + extra
        guard count < minimum else { return count }
        let needed = Int((Double(minimum - extra) / Double(multiple)).rounded(.up))
        return needed * multiple + extra
    }

    static func rows(_ inches: Double, per inch: Double, even: Bool = false, minimum: Int = 1) -> Int {
        var count = max(minimum, Int((inches * inch).rounded()))
        if even, count % 2 == 1 { count += 1 }
        return count
    }

    /// Yardage for an area of fabric at a stitch gauge, with a tenth held back for swatching and ends.
    /// `factor` covers stitches that eat more yarn than stockinette.
    static func yards(squareInches: Double, spi: Double, factor: Double = 1) -> Int {
        let raw = squareInches * 0.17 * spi * 1.1 * factor
        return max(10, Int((raw / 10).rounded(.up)) * 10)
    }

    /// A length, in the units this knitter measures in. Patterns are sized in inches underneath.
    static func inches(_ value: Double, units: Units = .current) -> String {
        if units == .metric {
            let half = (value * 2.54 * 2).rounded() / 2
            return half.formatted(.number.precision(.fractionLength(0...1))) + " cm"
        }
        let quarter = (value * 4).rounded() / 4
        return quarter.formatted(.number.precision(.fractionLength(0...2))) + " in"
    }

    /// A needle or cable length the way it is sold: 16 in, or 40 cm.
    static func cable(_ inches: Int, units: Units = .current) -> String {
        guard units == .metric else { return "\(inches) in" }
        let centimeters = Double(inches) * 2.54
        return "\(Int(inches < 12 ? centimeters.rounded() : (centimeters / 10).rounded() * 10)) cm"
    }

    static func yardage(_ yards: Int, units: Units = .current) -> String {
        guard units == .metric else { return "\(yards.formatted()) yd" }
        return "\((Int((Double(yards) * 0.9144 / 10).rounded(.up)) * 10).formatted()) m"
    }

    /// The span a gauge swatch is counted over.
    static func swatch(units: Units = .current) -> String { units == .metric ? "10 cm" : "4 in" }
}

/// Inches and yards in the United States, centimeters and meters everywhere else.
enum Units: Sendable {
    case imperial, metric

    static let current: Units = Locale.current.measurementSystem == .us ? .imperial : .metric
}
