import Foundation

/// The checks every generated pattern must pass, shared by the tests, the topical design check and its
/// script, so a design published as data is held to exactly what the built-in library is.
enum PlanCheck {
    /// What is wrong with a plan, as sentences. Empty when it is sound.
    static func problems(_ plan: PatternPlan) -> [String] {
        var problems: [String] = []
        func check(_ ok: Bool, _ problem: @autoclosure () -> String) { if !ok { problems.append(problem()) } }

        check(plan.steps.count > 2, "Fewer than 3 steps")
        check(plan.yards > 0, "No yarn")
        check(!plan.materials.isEmpty, "No materials")
        check(plan.steps.first?.isAction == true, "Does not open with a cast on")
        check(plan.steps.last?.isAction == true, "Does not close with an action")
        for step in plan.steps {
            check(step.rows > 0, "\(step.section): a step of no rows")
            check(!step.section.isEmpty, "A step with no section")
            check(!step.texts.isEmpty, "\(step.section): a step with no text")
            check(!step.texts.contains { $0.isEmpty || $0.contains("\u{2014}") }, "\(step.section): an empty row or an em dash")
            if let first = step.stitches, let last = step.stitches(after: step.rows - 1) {
                check(first > 0 && last > 0, "\(step.section): no stitches left on \(step.texts[0])")
            }
        }

        // A step that changes the count must hand the next step the count it ends on.
        var carried: Int?
        for step in plan.steps {
            guard let first = step.stitches else { continue }
            if step.isAction, ["Cast on", "With", "Return"].contains(where: step.texts[0].hasPrefix) {
                carried = step.stitches(after: step.rows - 1)
                continue
            }
            if let previous = carried, step.delta == 0, step.texts.count == 1, step.texts[0] == "Knit" {
                check(first == previous, "\(step.section): \(first) stitches after \(previous)")
            }
            carried = step.stitches(after: step.rows - 1)
        }

        // Colorwork: every row names colors on the palette, one per stitch or one for the row.
        if let palette = plan.palette {
            for step in plan.steps where !step.isAction {
                for row in 0..<step.rows {
                    guard let paint = step.paint(at: row) else { continue }
                    let stitches = step.stitches(after: row) ?? 0
                    check(paint.count == 1 || paint.count == stitches, "\(step.section): \(paint.count) colors on a row of \(stitches)")
                    check(paint.allSatisfy { Colorwork.index($0).map { $0 < palette.count } ?? false }, "\(step.section): a color not on the palette")
                    if paint.count > 1 { break }
                }
            }
        }
        return problems
    }
}

/// The full check of a topical design: every named size and both ends of every measurement, at every
/// yarn weight it allows.
enum TopicalCheck {
    /// Words a design may never carry: characters, brands, leagues and teams, and the names memes give
    /// real animals. Colors can nod to a team; names cannot.
    static let denied = [
        "disney", "marvel", "pixar", "pokemon", "pikachu", "sanrio", "hello kitty", "snoopy", "peanuts", "grinch",
        "star wars", "harry potter", "hogwarts", "barbie", "mickey", "minnie", "elsa", "frozen", "bluey", "sesame",
        "nfl", "nba", "mlb", "nhl", "mls", "ncaa", "fifa", "super bowl", "world cup", "olympic",
        "seahawks", "chiefs", "packers", "cowboys", "yankees", "dodgers", "lakers", "celtics", "steelers",
        "jimothy", "moo deng", "pesto", "tiktok", "instagram", "ravelry",
    ]

    static func inputs(for design: Design) -> [[String: Double]] {
        var inputs = design.sizes.map(\.values)
        inputs.append(Dictionary(uniqueKeysWithValues: design.measures.map { ($0.key, $0.range.lowerBound) }))
        inputs.append(Dictionary(uniqueKeysWithValues: design.measures.map { ($0.key, $0.range.upperBound) }))
        return inputs
    }

    /// What a stitch pattern's repeat did to the size asked for, if it moved it too far: a hat must stay in
    /// the ease band, anything else within a tenth of the size or half a repeat, whichever is more.
    static func stitchFit(_ stitch: Stitch, base: Design, input: [String: Double], gauge g: Gauge, plan: PatternPlan) -> String? {
        guard let widest = plan.steps.compactMap(\.stitches).max() else { return "No stitch count" }
        let across = g.spi * stitch.widthFactor
        let measured = Double(widest) / across
        let head = input["head"] ?? 0
        if base == .ribbedBeanie {
            let band = (head * (Engines.hatEase.lowerBound - 0.01))...(head * (Engines.hatEase.upperBound + 0.01))
            return band.contains(measured) ? nil : "\(widest) stitches make \(measured.formatted(.number.precision(.fractionLength(1)))) in for a \(head.formatted()) in head"
        }
        let wanted: Double
        switch base {
        // The slouch's own body, which a small head at a heavy weight keeps 8 stitches wider than its brim.
        case .slouchHat: wanted = Double(base.plan(measures: input, gauge: g).steps.compactMap(\.stitches).max() ?? 0) / g.spi
        case .earWarmer: wanted = head * 0.9
        case .garterScarf, .borderedBlanket: wanted = input["width"] ?? 0
        case .ribbedCowl: wanted = input["around"] ?? 0
        default: return nil
        }
        let room = max(wanted * 0.1, (Double(stitch.multiple) / 2 + 1) / across)
        return abs(measured - wanted) <= room ? nil : "\(widest) stitches make \(measured.formatted(.number.precision(.fractionLength(1)))) in where \(wanted.formatted(.number.precision(.fractionLength(1)))) in was asked for"
    }

    static func problems(_ topical: Topical) -> [String] {
        var problems: [String] = []
        let words = ([topical.title, topical.tag, topical.id] + topical.work.palette.map(\.name)).joined(separator: " ").lowercased()
        for word in denied where words.range(of: "\\b\(word)\\b", options: .regularExpression) != nil {
            problems.append("Names \(word), which a design may not")
        }
        for input in inputs(for: topical.base) {
            for weight in topical.weights {
                let gauge = weight.gauge
                let label = "\(weight.label) \(input.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value.formatted())" }.joined(separator: ", "))"
                let result = topical.painted(measures: input, gauge: gauge)
                for problem in result.issues + PlanCheck.problems(result.plan) { problems.append("\(label): \(problem)") }
                // A chart repeat may round the stitch count, but never far from the size asked for.
                let plain = topical.base.plan(measures: input, gauge: gauge)
                // A stitch pattern changes the count on purpose (ribs draw in, lace opens out): `stitchFit` checks it.
                if topical.stitch == nil, let sized = result.plan.steps.compactMap(\.stitches).max(), let wanted = plain.steps.compactMap(\.stitches).max(), wanted > 0 {
                    let off = abs(Double(sized - wanted)) / Double(wanted)
                    if off > 0.05 { problems.append("\(label): the chart repeat moves the fit \(Int((off * 100).rounded())) percent (\(wanted) to \(sized) stitches)") }
                }
                if let stitch = topical.stitch, let off = stitchFit(stitch, base: topical.base, input: input, gauge: gauge, plan: result.plan) {
                    problems.append("\(label): \(off)")
                }
                // Each yarn covers its own rows plus 15 percent, and together they cover the shape knit plain.
                let shape = topical.base.plan(measures: input, gauge: gauge, fit: topical.fit)
                if result.plan.yards < shape.yards { problems.append("\(label): \(result.plan.yards) yd is less than the \(shape.yards) yd the shape needs") }
            }
        }
        // One line per problem, however many sizes share it.
        var seen = Set<String>()
        return problems.filter { seen.insert($0).inserted }
    }
}
