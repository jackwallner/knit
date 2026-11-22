import Foundation

extension Engines {
    struct Tank: Equatable, Sendable {
        var plan: PatternPlan
        var body: Int
        var piece: Int
        var strap: Int
        var frontNeck: Int
        var backNeck: Int
        var armholeRows: Int
    }

    /// A sleeveless top knit in the round from the hem to the underarms, then the front and back worked flat:
    /// armholes cut deeper than a vest's for a bare arm, a scoop neck front and back, and narrow straps sewn at
    /// the shoulder. The neck and armholes get a narrow k1, p1 rib. `chest` is the finished chest.
    static func tank(chest: Double, wearer: Double, body length: Double, gauge g: Gauge) -> Tank {
        let body = Sizing.stitches(chest, per: g.spi, multiple: 4)
        let piece = body / 2
        let rows = Sizing.rows(min(10.5, wearer * 0.125 + 3.5), per: g.rpi, even: true)
        // Straps about 2 in wide, set on shoulders 2 in narrower than a sweater's cross back.
        let strap = max(3, Int((min(2.75, max(1.5, wearer * 0.055)) * g.spi).rounded()))
        let shoulders = max(min(even((min(18.5, wearer * 0.2 + 8.5) - 2) * g.spi), piece - 4), 2 * strap + 6)
        let neck = shoulders - 2 * strap
        let armhole = (piece - shoulders) / 2
        let boundOff = (armhole + 1) / 2
        let decreases = armhole - boundOff
        // The bound-off share goes in steps of about 1.25 in, one at the start of each row, larger steps first.
        let steps = max(1, Int((Double(boundOff) / max(1, (1.25 * g.spi).rounded())).rounded(.up)))
        let chunks = (0..<steps).map { boundOff / steps + ($0 < boundOff % steps ? 1 : 0) }
        // The rest on right-side rows, or on every row at first when the armhole is short of rows for them,
        // so the front neck keeps its depth.
        let frontDepth = Sizing.rows(min(Double(rows) / g.rpi - 1.5, wearer * 0.06 + 2.5), per: g.rpi)
        let pairs = min(decreases, max((decreases + 1) / 2, (rows - frontDepth - 2 * steps - 1) / 2))
        let doubled = decreases - pairs
        var armholeRows: [(text: String, change: Int)] = []
        for pair in 0..<pairs {
            armholeRows.append(("K1, ssk, knit to the last 3 stitches, k2tog, k1, turn", 2))
            armholeRows.append(pair < doubled ? ("P1, p2tog, purl to the last 3 stitches, ssp, p1, turn", 2) : ("Purl to the end, turn", 0))
        }
        let shaped = 2 * steps + armholeRows.count

        /// One piece from the underarm: the armholes, then the neck split `depth` rows below the shoulder,
        /// each side worked on its own and bound off at the strap.
        func shape(depth wanted: Int) -> (texts: [(text: String, stitches: Int)], first: [(text: String, stitches: Int)], second: [(text: String, stitches: Int)], center: Int, curve: Int, depth: Int) {
            // The split falls on a right-side row after the armholes are shaped.
            var split = max(shaped + 1, rows - wanted)
            if split % 2 == 0 { split += 1 }
            let depth = rows - split + 1
            let curve = max(1, min(neck / 4, (depth - 2) / 2))
            let center = neck - 2 * curve
            var below: [(text: String, stitches: Int)] = []
            var count = piece
            for chunk in chunks {
                let bind = "Bind off \(chunk) stitch\(chunk == 1 ? "" : "es")"
                count -= chunk
                below.append(("\(bind), knit to the end, turn", count))
                count -= chunk
                below.append(("\(bind), purl to the end, turn", count))
            }
            for (text, change) in armholeRows {
                count -= change
                below.append((text, count))
            }
            for row in (shaped + 1)..<split { below.append((row % 2 == 0 ? "Purl to the end, turn" : "Knit to the end, turn", count)) }
            let side = (count - center) / 2
            below.append(("K\(side), bind off the next \(center) stitches, knit to the end. Work the \(side) stitches just knit first, on their own, turn", side))
            // The neck edge starts the right-side rows of the first side and ends those of the second.
            var first: [(text: String, stitches: Int)] = [], second: [(text: String, stitches: Int)] = []
            var left = side
            for row in (split + 1)...rows {
                let right = row % 2 == 1
                let narrowing = right && (row - split) / 2 <= curve
                if narrowing { left -= 1 }
                first.append((right ? (narrowing ? "K1, ssk, knit to the end, turn" : "Knit to the end, turn") : "Purl to the neck, turn", left))
                second.append((right ? (narrowing ? "Knit to the last 3 stitches, k2tog, k1, turn" : "Knit to the end, turn") : "Purl to the end, turn", left))
            }
            return (below, first, second, center, curve, depth)
        }

        var b = PlanBuilder()
        let hem = Sizing.rows(min(1, length * 0.1), per: g.rpi, minimum: 4)
        b.section = "Hem"
        b.action("Cast on \(body) stitches with the smaller needle. Join in the round without twisting and place a marker at the side.", stitches: body)
        b.work(["*K1, p1; repeat from * around"], rows: hem, stitches: body)
        b.section = "Body"
        b.row("Change to the larger needle and knit", stitches: body)
        b.work(["Knit"], rows: max(1, Sizing.rows(length, per: g.rpi) - hem - 1), stitches: body)
        b.action("The first \(piece) stitches of the round are the front. Slip the other \(piece), the back, to waste yarn. The front is worked first, back and forth.")

        let front = shape(depth: frontDepth)
        let back = shape(depth: Sizing.rows(1.5, per: g.rpi, minimum: 4))
        for (name, part) in [("Front", front), ("Back", back)] {
            b.section = name
            if name == "Back" {
                b.action("Return the \(piece) back stitches to the needle. With the right side facing, join new yarn at the underarm.", stitches: piece)
            }
            // Rows that decrease on both sides read as one step, the count after each row given by its offset.
            let lead = 2 * steps, both = 2 * doubled
            runs(&b, Array(part.texts.prefix(lead)), from: piece)
            if both > 0 {
                b.work([armholeRows[0].text, armholeRows[1].text], rows: both, stitches: part.texts[lead].stitches, delta: -4, offsets: [0, -2])
            }
            runs(&b, Array(part.texts.dropFirst(lead + both)), from: part.texts[lead + both - 1].stitches)
            b.section = "\(name) · First Strap"
            runs(&b, part.first, from: part.first[0].stitches)
            b.action("Bind off the \(strap) strap stitches.")
            b.section = "\(name) · Second Strap"
            b.action("With the wrong side facing, join new yarn at the neck edge of the other side.", stitches: part.first[0].stitches)
            runs(&b, part.second, from: part.first[0].stitches)
            b.action("Bind off the \(strap) strap stitches.")
        }
        b.section = "Finishing"
        b.action("Sew the front straps to the back straps at the shoulders.")

        // Picked up at about 9 stitches for every 10 rows along the curves.
        func edge(_ part: (texts: [(text: String, stitches: Int)], first: [(text: String, stitches: Int)], second: [(text: String, stitches: Int)], center: Int, curve: Int, depth: Int)) -> Int {
            let slant = (pow(Double(part.depth) / g.rpi, 2) + pow(Double(part.curve) / g.spi, 2)).squareRoot()
            return part.center + 2 * Int((slant * g.spi * 0.9).rounded())
        }
        // Both edges are even: the neck and each curve are.
        let frontEdge = edge(front), backEdge = edge(back)
        let around = frontEdge + backEdge
        let edging = Sizing.rows(0.5, per: g.rpi, minimum: 3)
        b.section = "Neck Edging"
        b.action("With the smaller \(Sizing.cable(16)) needle and the right side facing, start at the left shoulder seam. Pick up and knit \(frontEdge) stitches around the front neck to the other shoulder seam, then \(backEdge) around the back neck. Join in the round and place a marker.", stitches: around)
        b.work(["*K1, p1; repeat from * around"], rows: edging, stitches: around)
        b.action("Bind off loosely in pattern.")
        let armStitches = even(Double(2 * rows) * g.spi / g.rpi * 0.85 + Double(2 * boundOff))
        for name in ["First Armhole", "Second Armhole"] {
            b.section = name
            b.action("With the smaller \(Sizing.cable(16)) needle or double-pointed needles and the right side facing, pick up and knit \(armStitches) stitches around the armhole, starting at the middle of the underarm. Join in the round and place a marker.", stitches: armStitches)
            b.work(["*K1, p1; repeat from * around"], rows: edging, stitches: armStitches)
            b.action("Bind off loosely in pattern.")
        }
        b.section = "Finishing"
        b.action("Weave in the ends and block to the finished measurements.")

        let finishedChest = Double(body) / g.spi
        let depth = Double(rows) / g.rpi
        let yards = Sizing.yards(squareInches: finishedChest * (length + depth * 0.7), spi: g.spi)
        let long = finishedChest < 34 ? 24 : 32
        let needle = finishedChest > 45 ? longCircular(body, g, flat: false) : "\(g.needle.label) \(Sizing.cable(long)) circular needle"
        let plan = pattern(b, estimate: yards, tools: [needle, "\(g.ribNeedle.label) circular needles, \(Sizing.cable(16)) and \(Sizing.cable(long)), for the ribbing", "Stitch marker, waste yarn, tapestry needle"], finished: "Finished chest \(Sizing.inches(finishedChest)), to fit a \(Sizing.inches(wearer)) chest with \(Sizing.inches(finishedChest - wearer)) of ease. \(Sizing.inches(length)) from the hem to the underarm and \(Sizing.inches(depth)) from the underarm to the shoulder", gauge: g, round: true)
        return Tank(plan: plan, body: body, piece: piece, strap: strap, frontNeck: frontEdge, backNeck: backEdge, armholeRows: rows)
    }
}
