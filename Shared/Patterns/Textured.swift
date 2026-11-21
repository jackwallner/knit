import Foundation

/// Shapes worked in a stitch pattern (`Stitch`): the shape's own sizing, with the stitch's rows written out
/// for the main fabric. Only a design that asks for a stitch reaches these, so every other plan is untouched.
extension Engines {
    /// Stitches to the inch of a stitch pattern's fabric.
    private static func spi(_ stitch: Stitch, _ g: Gauge) -> Double { g.spi * stitch.widthFactor }

    private static func tools(_ stitch: Stitch) -> [String] { stitch == .ropeCable ? ["Cable needle"] : [] }

    /// A beanie or slouch hat with its body in the stitch pattern: the shape's brim, a plain round, the
    /// stitch in whole repeats, then the usual crown in stockinette.
    static func texturedHat(_ style: HatStyle, _ stitch: Stitch, head: Double, gauge g: Gauge, fit: Fit) -> PatternPlan {
        let share = style == .slouch ? 0.88 : 0.9
        let ribs: [(multiple: Int, text: String)] = style == .slouch
            ? [(2, "*K1, p1; repeat from * around")]
            : [(4, "*K2, p2; repeat from * around"), (2, "*K1, p1; repeat from * around")]
        let across = spi(stitch, g)
        // The ribbed beanie's body is its brim count, so the brim must divide into the stitch's repeat too.
        let together = style == .slouch ? 1 : Stitch.lcm(stitch.multiple, fit.multiple)
        let picked = ribs.lazy.compactMap { rib in
            hatCount(head: head, share: share, spi: style == .slouch ? g.spi : across, multiple: lcm(rib.multiple, together)).map { (count: $0, text: rib.text) }
        }.first
        let rib = picked?.text ?? ribs[0].text
        let brim = picked?.count ?? Sizing.stitches(head * share, per: style == .slouch ? g.spi : across, multiple: lcm(ribs[0].multiple, together), minimum: 24)
        // The crown's adjusting round takes any count to a multiple of 8, so the body need only fit the stitch.
        let body = style == .slouch ? Sizing.stitches(head * 1.08, per: across, multiple: lcm(stitch.multiple, fit.multiple), minimum: brim + 8) : brim
        let top = max(24, 8 * ((body + 3) / 8))
        let crown = crownRounds(wedge: top / 8)
        let height = head * (style == .slouch ? 0.47 : 0.37)
        let brimRounds = Sizing.rows(head * (style == .slouch ? 0.07 : 0.09), per: g.rpi, minimum: 4)
        // The first body round is the plain round or the increases; the rest of the body is the stitch.
        let plain = max(4, Sizing.rows(height, per: g.rpi) - brimRounds - 1 - crown.count - (top == body ? 0 : 1))
        let rounds = stitch.rows(Double(plain) / g.rpi, rpi: g.rpi, flat: false)
        let small = Double(brim) / g.spi < 16
        guard let texts = stitch.texts(stitches: body, flat: false) else { return hat(style, head: head, gauge: g) }

        var b = PlanBuilder()
        b.section = "Brim"
        b.action("Cast on \(brim) stitches with the smaller needle. Join in the round without twisting and place a marker.", stitches: brim)
        b.work([rib], rows: brimRounds, stitches: brim)
        b.section = "Body"
        if style == .slouch {
            b.row("Change to the larger needle. " + spread(body - brim, over: brim), stitches: body)
        } else {
            b.row("Change to the larger needle and knit", stitches: body)
        }
        b.work(texts, rows: rounds, stitches: body)
        if top != body { b.row(adjusting(body, to: top), stitches: top) }
        b.section = "Crown"
        for round in small ? crown : switching(crown, g) { b.row(round.text, stitches: round.stitches) }
        b.section = "Finishing"
        b.action("Cut the yarn, thread it through the last 8 stitches and pull tight. Weave in the ends.")

        let tall = Double(brimRounds + 1 + crown.count) / g.rpi + Double(rounds) / (g.rpi * stitch.rowFactor)
        let yards = Sizing.yards(squareInches: Double(body) / across * tall, spi: g.spi, factor: stitch.yarnFactor)
        let needles = small
            ? ["\(g.ribNeedle.label) double-pointed needles for the brim, or a long circular for magic loop", "\(g.needle.label) double-pointed needles for the body, or a long circular for magic loop"]
            : ["\(g.ribNeedle.label) \(Sizing.cable(16)) circular needle for the brim", "\(g.needle.label) \(Sizing.cable(16)) circular needle for the body", "Double-pointed needles in the larger size for the crown"]
        let around = Double(body) / across
        return pattern(b, estimate: yards, tools: needles + tools(stitch) + ["Stitch marker", "Tapestry needle"],
                       finished: "\(Sizing.inches(around)) around, to fit a \(Sizing.inches(head)) head", gauge: g, round: true)
    }

    /// A scarf in the stitch pattern. Fabric that curls gets a garter border at each edge and garter rows at
    /// each end; the rest lies flat as it is.
    static func texturedScarf(_ stitch: Stitch, width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let border = stitch.curls ? max(3, Int((0.5 * g.spi).rounded())) : 0
        let ends = stitch.curls ? even(0.75 * g.spi * 2, minimum: 4) : 0
        let wanted = Double(2 * border) + (width - Double(2 * border) / g.spi) * spi(stitch, g)
        let caston = stitch.count(near: wanted, flat: true, border: border)
        let body = stitch.rows(length - Double(ends) / g.spi, rpi: g.rpi, flat: true)
        guard let texts = stitch.texts(stitches: caston, flat: true, border: border) else { return scarf(.garter, width: width, length: length, gauge: g) }

        var b = PlanBuilder()
        b.section = "Scarf"
        b.action("Cast on \(caston) stitches.", stitches: caston)
        b.work(["Knit"], rows: ends, stitches: caston)
        b.work(texts, rows: body, stitches: caston)
        b.work(["Knit"], rows: ends, stitches: caston)
        b.section = "Finishing"
        b.action("\(stitch.curls ? "Bind off loosely knitwise" : stitch.bindOff). Weave in the ends.\(stitch.isLace ? " Block the scarf to open up the lace." : "")")
        let wide = Double(2 * border) / g.spi + Double(caston - 2 * border) / spi(stitch, g)
        let long = Double(2 * ends) / (g.spi * 2) + Double(body) / (g.rpi * stitch.rowFactor)
        let yards = Sizing.yards(squareInches: wide * long, spi: g.spi, factor: stitch.yarnFactor)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) needles"] + tools(stitch) + ["Tapestry needle"], finished: "\(Sizing.inches(wide)) wide, \(Sizing.inches(long)) long", gauge: g)
    }

    /// A cowl in the round in the stitch pattern, with garter edges where the fabric would roll.
    static func texturedCowl(_ stitch: Stitch, around: Double, height: Double, gauge g: Gauge, fit: Fit) -> PatternPlan {
        let caston = stitch.count(near: around * spi(stitch, g), flat: false, multiple: fit.multiple)
        let edge = stitch.curls ? even(0.5 * g.spi * 2, minimum: 4) : 0
        let body = stitch.rows(height - Double(edge) / g.spi, rpi: g.rpi, flat: false)
        guard let texts = stitch.texts(stitches: caston, flat: false) else { return cowl(.rib, around: around, height: height, gauge: g) }

        var b = PlanBuilder()
        b.section = "Cowl"
        b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
        b.work(["Purl", "Knit"], rows: edge, stitches: caston)
        b.work(texts, rows: body, stitches: caston)
        b.work(["Purl", "Knit"], rows: edge, stitches: caston)
        b.section = "Finishing"
        b.action("\(stitch.curls ? "Bind off loosely purlwise" : stitch.bindOff). Weave in the ends.\(stitch.isLace ? " Block the cowl to open up the lace." : "")")
        let wide = Double(caston) / spi(stitch, g)
        let tall = Double(edge) / g.spi + Double(body) / (g.rpi * stitch.rowFactor)
        let yards = Sizing.yards(squareInches: wide * tall, spi: g.spi, factor: stitch.yarnFactor)
        let cable = wide > 45 ? longCircular(caston, g, flat: false) : "\(g.needle.label) \(Sizing.cable(wide < 20 ? 16 : wide < 34 ? 24 : 32)) circular needle"
        return pattern(b, estimate: yards, tools: [cable] + tools(stitch) + ["Stitch marker", "Tapestry needle"], finished: "\(Sizing.inches(wide)) around, \(Sizing.inches(tall)) tall", gauge: g, round: true)
    }

    /// A blanket with a garter border and its middle in the stitch pattern.
    static func texturedBlanket(_ stitch: Stitch, width: Double, length: Double, gauge g: Gauge, border edge: Double = 1.25, noun: String = "blanket") -> PatternPlan {
        let border = max(3, Int((edge * g.spi).rounded()))
        let wanted = Double(2 * border) + (width - Double(2 * border) / g.spi) * spi(stitch, g)
        let caston = stitch.count(near: wanted, flat: true, border: border, repeats: 2)
        let body = stitch.rows(length - 2 * Double(border) / g.spi, rpi: g.rpi, flat: true)
        guard let texts = stitch.texts(stitches: caston, flat: true, border: border) else {
            switch noun {
            case "cloth": return washcloth(side: width, gauge: g)
            case "wrap": return wrap(width: width, length: length, gauge: g)
            default: return blanket(bordered: true, width: width, length: length, gauge: g)
            }
        }

        var b = PlanBuilder()
        b.section = "Bottom Border"
        b.action("Cast on \(caston) stitches.", stitches: caston)
        b.work(["Knit"], rows: border * 2, stitches: caston)
        b.section = "Body"
        b.work(texts, rows: body, stitches: caston)
        b.section = "Top Border"
        b.work(["Knit"], rows: border * 2, stitches: caston)
        b.section = "Finishing"
        b.action("Bind off loosely. Weave in the ends.\(stitch.isLace ? " Block the \(noun) to open up the lace." : "")")
        let wide = Double(2 * border) / g.spi + Double(caston - 2 * border) / spi(stitch, g)
        let long = 2 * Double(border) / g.spi + Double(body) / (g.rpi * stitch.rowFactor)
        let yards = Sizing.yards(squareInches: wide * long, spi: g.spi, factor: stitch.yarnFactor)
        if noun == "cloth" {
            return pattern(b, estimate: yards, yarnNote: ", cotton for a cloth that scrubs", tools: ["\(g.needle.label) needles"] + tools(stitch) + ["Tapestry needle"], finished: "\(Sizing.inches(wide)) wide, \(Sizing.inches(long)) long", gauge: g)
        }
        return pattern(b, estimate: yards, tools: [longCircular(caston, g, flat: true)] + tools(stitch) + ["Tapestry needle"], finished: "\(Sizing.inches(wide)) wide, \(Sizing.inches(long)) long", gauge: g)
    }

    /// An ear warmer in the round: a little k2, p2 rib at each edge and the stitch pattern between.
    static func texturedEarWarmer(_ stitch: Stitch, head: Double, width: Double, gauge g: Gauge, fit: Fit) -> PatternPlan {
        let caston = stitch.count(near: head * 0.9 * spi(stitch, g), flat: false, multiple: lcm(4, fit.multiple))
        let edge = Sizing.rows(0.4, per: g.rpi, minimum: 3)
        let middle = stitch.rows(width - 2 * Double(edge) / g.rpi, rpi: g.rpi, flat: false)
        let rib = "*K2, p2; repeat from * around"
        guard let texts = stitch.texts(stitches: caston, flat: false) else { return earWarmer(head: head, width: width, gauge: g) }

        var b = PlanBuilder()
        b.section = "Band"
        b.action("Cast on \(caston) stitches. Join in the round without twisting and place a marker.", stitches: caston)
        b.work([rib], rows: edge, stitches: caston)
        b.work(texts, rows: middle, stitches: caston)
        b.work([rib], rows: edge, stitches: caston)
        b.section = "Finishing"
        b.action("Bind off loosely in pattern. Weave in the ends.")
        let wide = Double(2 * edge) / g.rpi + Double(middle) / (g.rpi * stitch.rowFactor)
        let around = Double(caston) / spi(stitch, g)
        let yards = Sizing.yards(squareInches: head * wide, spi: g.spi, factor: stitch.yarnFactor * 1.1)
        return pattern(b, estimate: yards, tools: ["\(g.needle.label) \(Sizing.cable(16)) circular needle"] + tools(stitch) + ["Stitch marker", "Tapestry needle"],
                       finished: "\(Sizing.inches(around)) around, to fit a \(Sizing.inches(head)) head, \(Sizing.inches(wide)) wide", gauge: g, round: true)
    }
}
