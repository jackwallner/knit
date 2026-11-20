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
    /// The colors of each row, cycled like `texts`, as palette letters: one letter for a row in a
    /// single color, or one letter per stitch, left to right as the right side faces. Nil is color A.
    var paint: [String]? = nil
    /// For a cycle whose rows each change the count: how far each row's count sits from the cycle's end,
    /// cycled like `texts`. Nil when only the first row of a cycle shapes.
    var offsets: [Int]? = nil

    func text(at row: Int) -> String { texts[row % texts.count] }

    func paint(at row: Int) -> String? { paint.flatMap { $0.isEmpty ? nil : $0[row % $0.count] } }

    func stitches(after row: Int) -> Int? {
        let offset = offsets.flatMap { $0.isEmpty ? nil : $0[row % $0.count] } ?? 0
        return stitches.map { $0 + delta * (row / texts.count) + offset }
    }
}

extension Step {
    /// A cast-on project keeps its plan for good, so a plan saved by an older version must always
    /// open. Any key added after 1.0 has to be read with `decodeIfPresent` here.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        section = try values.decode(String.self, forKey: .section)
        texts = try values.decode([String].self, forKey: .texts)
        rows = try values.decode(Int.self, forKey: .rows)
        stitches = try values.decodeIfPresent(Int.self, forKey: .stitches)
        delta = try values.decodeIfPresent(Int.self, forKey: .delta) ?? 0
        isAction = try values.decodeIfPresent(Bool.self, forKey: .isAction) ?? false
        paint = try values.decodeIfPresent([String].self, forKey: .paint)
        offsets = try values.decodeIfPresent([Int].self, forKey: .offsets)
        if texts.isEmpty { texts = [""] }
    }
}

/// The design, measurements and gauge a plan was written from, and the design's revision at the time.
struct PlanSource: Codable, Equatable, Sendable {
    var design: String
    var measures: [String: Double]
    var gauge: Gauge
    var revision: Int
}

/// A full pattern, sized: every row, in order, plus what to buy.
struct PatternPlan: Codable, Equatable, Sendable {
    var steps: [Step]
    var materials: [String]
    var finished: String
    var yards: Int
    /// The yarns of a colorwork pattern, color A first. Nil for a pattern in one color.
    var palette: [Shade]? = nil
    /// The shape the pattern draws as, kept with the plan so a project never needs its design to draw.
    var silhouette: String? = nil
    /// What the pattern was written from, so a knitter's report can be rebuilt exactly and a corrected
    /// design can offer its fix. Nil for a plan cast on before it was kept.
    var source: PlanSource? = nil

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

    /// The sections whose rows differ from `old`, in this plan's order, so a knitter offered a correction
    /// can see whether it touches work already on the needles.
    func changedSections(from old: PatternPlan) -> [String] {
        func rows(_ plan: PatternPlan) -> [String: [Step]] { Dictionary(grouping: plan.steps, by: \.section) }
        let before = rows(old), after = rows(self)
        var seen = Set<String>()
        let order = (steps + old.steps).map(\.section).filter { seen.insert($0).inserted }
        return order.filter { before[$0] != after[$0] }
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
    /// See `Step.init(from:)`: plans saved by older versions must keep opening.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        steps = try values.decode([Step].self, forKey: .steps)
        materials = try values.decodeIfPresent([String].self, forKey: .materials) ?? []
        finished = try values.decodeIfPresent(String.self, forKey: .finished) ?? ""
        yards = try values.decodeIfPresent(Int.self, forKey: .yards) ?? 0
        palette = try values.decodeIfPresent([Shade].self, forKey: .palette)
        silhouette = try values.decodeIfPresent(String.self, forKey: .silhouette)
        source = try values.decodeIfPresent(PlanSource.self, forKey: .source)
    }

    /// The palette letters of every knitted row among the first `taps` taps, oldest first. Empty for a
    /// pattern in one color.
    func paints(upTo taps: Int = .max) -> [String] {
        guard palette != nil else { return [] }
        var remaining = max(0, taps)
        var rows: [String] = []
        for step in steps {
            let done = min(remaining, step.rows)
            if !step.isAction { for row in 0..<done { rows.append(step.paint(at: row) ?? "A") } }
            remaining -= done
            if remaining == 0 { break }
        }
        return rows
    }

    /// Where the front of a row sits, as a fraction across it as the right side faces: a round's front
    /// is its first half, which is the right-hand half; a flat piece faces front in the middle.
    var front: Double { steps.first?.texts.first?.contains("Join in the round") == true ? 0.75 : 0.5 }

    /// "Round" for a tap worked in the round, "Row" for one worked flat, so a label over the counter can
    /// say what the knitter is working. A piece is in the round from the action that joins it until a
    /// row turns, and again after an action that joins it back.
    func unit(at taps: Int) -> String {
        guard let spot = position(at: taps) else { return "Row" }
        var round = false
        for step in steps.prefix(spot.step) where step.isAction {
            if step.texts[0].range(of: "^(Loosely )?cast on", options: [.regularExpression, .caseInsensitive]) != nil || step.texts[0].hasPrefix("With") { round = false }
            if step.texts[0].range(of: "join in the round|start of the round", options: [.regularExpression, .caseInsensitive]) != nil { round = true }
        }
        let step = steps[spot.step]
        if step.isAction { return round ? "Round" : "Row" }
        let text = step.text(at: spot.row)
        if text.hasSuffix("turn") { return "Row" }
        return round ? "Round" : "Row"
    }

    /// The opening of the pattern as a knitter reads it before casting on: its first sections written out
    /// with their row numbers, then the names of the sections after them. Never the whole pattern: a short
    /// design shows its opening steps only and never its last one.
    struct Preview: Equatable {
        struct Block: Equatable {
            var section: String
            var lines: [String]
        }
        var blocks: [Block]
        var later: [String]
    }

    func preview(sections limit: Int = 2, steps most: Int = 6) -> Preview? {
        guard steps.count > 1 else { return nil }
        var blocks: [Preview.Block] = []
        var tap = 0
        var row = 1
        for step in steps.prefix(min(most, steps.count - 1)) {
            if blocks.last?.section != step.section {
                guard blocks.count < limit else { break }
                blocks.append(Preview.Block(section: step.section, lines: []))
                row = 1
            }
            defer { tap += step.rows }
            if step.isAction {
                blocks[blocks.count - 1].lines.append(step.texts[0])
                continue
            }
            let unit = self.unit(at: tap)
            let last = row + step.rows - 1
            let span = step.rows == 1 ? "\(unit) \(row)" : "\(unit)s \(row)-\(last)"
            if step.texts.count == 1 || step.rows <= 1 {
                blocks[blocks.count - 1].lines.append("\(span): \(step.texts[0])")
            } else {
                blocks[blocks.count - 1].lines.append("\(span), repeating \(step.texts.count) \(unit.lowercased())s:")
                for (index, text) in step.texts.enumerated() { blocks[blocks.count - 1].lines.append("\(unit) \(row + index): \(text)") }
            }
            row = last + 1
        }
        // The parts still to come, each named once: the second sock's heel is the first sock's heel again.
        var seen = Set(blocks.map(\.section).map(Self.part))
        let later = sections.map { Self.part($0.name) }.filter { seen.insert($0).inserted }
        return Preview(blocks: blocks, later: later)
    }

    /// The steps of the section a tap is in: the run of neighbouring steps that share its name, and the tap
    /// the run starts on. Nil once the pattern is complete.
    private func sectionRun(at taps: Int) -> (steps: Range<Int>, tap: Int)? {
        guard let spot = position(at: taps) else { return nil }
        let name = steps[spot.step].section
        var first = spot.step
        while first > 0, steps[first - 1].section == name { first -= 1 }
        var last = spot.step
        while last + 1 < steps.count, steps[last + 1].section == name { last += 1 }
        return (first..<(last + 1), steps[..<first].reduce(0) { $0 + $1.rows })
    }

    /// The knitted row or round a tap is within its section, from 1, and how many the section has: "Round 5"
    /// of the body, whatever steps the body is written in. Nil on a step that is not a row (cast on, join).
    func sectionRow(at taps: Int) -> (row: Int, of: Int)? {
        guard let spot = position(at: taps), !steps[spot.step].isAction, let run = sectionRun(at: taps) else { return nil }
        let before = steps[run.steps.lowerBound..<spot.step].filter { !$0.isAction }.reduce(0) { $0 + $1.rows }
        let total = steps[run.steps].filter { !$0.isAction }.reduce(0) { $0 + $1.rows }
        return (before + spot.row + 1, total)
    }

    /// The tap that lands on knitted row `row` (from 1) of the section a knitter is in, kept inside the
    /// section. Nil when the section has no rows or the pattern is complete.
    func tap(ofRow row: Int, inSectionAt taps: Int) -> Int? {
        guard let run = sectionRun(at: taps) else { return nil }
        let total = steps[run.steps].filter { !$0.isAction }.reduce(0) { $0 + $1.rows }
        guard total > 0 else { return nil }
        var left = min(max(row, 1), total) - 1
        var tap = run.tap
        for step in steps[run.steps] {
            if !step.isAction {
                if left < step.rows { return tap + left }
                left -= step.rows
            }
            tap += step.rows
        }
        return nil
    }

    /// The instruction after the one at `taps`, when it reads differently: what to get ready for.
    func upcoming(after taps: Int) -> String? {
        guard let spot = position(at: taps), let next = position(at: taps + 1) else { return nil }
        let now = steps[spot.step].text(at: spot.row), then = steps[next.step].text(at: next.row)
        return then == now ? nil : then
    }

    /// One line of the written pattern and the taps it covers.
    struct Line: Equatable, Identifiable {
        var text: String
        var taps: Range<Int>
        /// The tap the line starts on. A repeat's heading covers no tap and takes a negative id of its own.
        var id: Int { taps.isEmpty ? -taps.lowerBound - 1 : taps.lowerBound }
    }

    /// The whole pattern as written, section by section, numbered like the preview: rows count from 1 in each
    /// section, a run of rows is one line, and a repeat lists its rows once.
    func written() -> [(section: String, lines: [Line])] {
        var blocks: [(section: String, lines: [Line])] = []
        var tap = 0
        var row = 1
        for step in steps {
            if blocks.last?.section != step.section {
                blocks.append((step.section, []))
                row = 1
            }
            defer { tap += step.rows }
            let span = tap..<(tap + step.rows)
            if step.isAction {
                blocks[blocks.count - 1].lines.append(Line(text: step.texts[0], taps: span))
                continue
            }
            let unit = self.unit(at: tap)
            let last = row + step.rows - 1
            let label = step.rows == 1 ? "\(unit) \(row)" : "\(unit)s \(row)-\(last)"
            if step.texts.count == 1 || step.rows <= 1 {
                blocks[blocks.count - 1].lines.append(Line(text: "\(label): \(step.texts[0])", taps: span))
            } else {
                // The heading covers no tap of its own; each row of the repeat covers its first time through.
                blocks[blocks.count - 1].lines.append(Line(text: "\(label), repeating \(step.texts.count) \(unit.lowercased())s:", taps: tap..<tap))
                for (index, text) in step.texts.enumerated() where index < step.rows {
                    blocks[blocks.count - 1].lines.append(Line(text: "\(unit) \(row + index): \(text)", taps: (tap + index)..<(tap + index + 1)))
                }
            }
            row = last + 1
        }
        return blocks
    }

    /// The line of `written()` a knitter is on: the row of a repeat they are working, whichever time through.
    func currentLine(at taps: Int) -> Int? {
        guard let spot = position(at: taps) else { return nil }
        let step = steps[spot.step]
        let start = taps - spot.row
        return step.texts.count > 1 && step.rows > 1 && !step.isAction ? start + spot.row % step.texts.count : start
    }

    /// The glossary terms an instruction uses that are worth a tap: the house wordings and the two-letter-plus
    /// abbreviations, not the bare k and p every row has.
    func terms(in text: String) -> [(term: String, meaning: String)] {
        Self.glossary.filter { entry in
            entry.term.count > 1 && text.range(of: "\\b\(NSRegularExpression.escapedPattern(for: entry.term))\\b", options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    /// "Cuff" for "Sock 2 · Cuff": the part of a section, without the piece it belongs to.
    static func part(_ section: String) -> String { section.components(separatedBy: " · ").last ?? section }

    /// Each section with the tap it starts on, in knitting order.
    var sections: [(name: String, tap: Int)] {
        var found: [(name: String, tap: Int)] = []
        var tap = 0
        for step in steps {
            if found.last?.name != step.section { found.append((step.section, tap)) }
            tap += step.rows
        }
        return found
    }

    private static let glossary: [(term: String, meaning: String)] = [
        ("k2tog", "Knit 2 stitches together"),
        ("ssk", "Slip 2 stitches knitwise one at a time, then knit them together through the back"),
        ("p2tog", "Purl 2 stitches together"),
        ("yo", "Yarn over"),
        ("duplicate stitch", "Sewn over a finished knit stitch with a tapestry needle, following its two legs, so it looks knitted in"),
        ("M1", "Make 1: lift the bar between the stitches and knit it through the back"),
        ("M1L", "Make 1 left: lift the bar from the front and knit it through the back"),
        ("M1R", "Make 1 right: lift the bar from the back and knit it through the front"),
        ("M1P", "Make 1 purlwise: lift the bar between the stitches and purl it through the back"),
        ("C6F", "Cable 6 front: slip 3 stitches to a cable needle and hold it in front, knit 3, then knit the 3 from the cable needle"),
        ("k", "Knit. K2 is knit 2 stitches"),
        ("p", "Purl. P2 is purl 2 stitches"),
        ("repeat from", "Work the stitches after the * again and again, as far as the row says"),
        ("marker", "A ring on the needle that marks a spot. Slip it from the left needle to the right when you reach it"),
        ("turn", "Swap the needles between your hands and work back the other way"),
        ("join in the round", "Knit the first cast-on stitch with the working yarn to close the circle, with the cast-on edge lying flat, not spiraled, around the needle"),
        ("backward loop", "Twist a loop of the working yarn and slide it onto the right needle. Each loop is 1 stitch"),
        ("pick up and knit", "Push the needle through the edge of the fabric, wrap the yarn and pull a loop through. Each loop is 1 stitch"),
        ("in pattern", "Knit the knit stitches and purl the purl stitches as you bind off"),
        ("inc across", "K1, M1L, knit to 1 stitch before the next marker, M1R, k1, slip the marker. It adds 2 stitches"),
        ("inc purlwise", "P1, M1P, purl to 1 stitch before the next marker, M1P, p1, slip the marker. It adds 2 stitches"),
        ("Kitchener stitch", "Graft two rows of live stitches together with a tapestry needle, so the join looks like knitting"),
        ("double stitch", "A German short row turn: with the yarn in front, slip the first stitch purlwise, then pull the yarn up and over the needle so the stitch shows two legs. Work both legs together as one stitch when you come back to it"),
    ]

    /// The abbreviations this pattern uses, spelled out.
    /// A term a listed meaning uses is listed too: "inc across" is spelled out with M1L and M1R.
    var abbreviations: [(term: String, meaning: String)] {
        func used(in text: String) -> [(term: String, meaning: String)] {
            Self.glossary.filter { entry in
                // "k" and "p" stand in front of a count: k2, p14.
                let pattern = entry.term.count == 1 ? "\\b\(entry.term)\\d" : "\\b\(entry.term)\\b"
                return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
            }
        }
        let text = steps.flatMap(\.texts).joined(separator: " ")
        return used(in: text + " " + used(in: text).map(\.meaning).joined(separator: " "))
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
    mutating func work(_ texts: [String], rows: Int, stitches: Int? = nil, delta: Int = 0, offsets: [Int]? = nil) {
        guard rows > 0 else { return }
        steps.append(Step(section: section, texts: texts, rows: rows, stitches: stitches, delta: delta, offsets: offsets))
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

    /// Yardage counted from the rows a pattern actually writes: every stitch takes about 4.3 times its
    /// own width in yarn, and 15 percent is added for the swatch, the ends and a loose hand.
    static func yards(worked steps: [Step], spi: Double) -> Int {
        var stitches = 0
        for step in steps where !step.isAction {
            for row in 0..<step.rows { stitches += step.stitches(after: row) ?? 0 }
        }
        let raw = Double(stitches) * 4.3 / spi / 36 * 1.15
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
