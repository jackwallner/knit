import Foundation

extension Engines {
    struct CroppedCardigan: Equatable, Sendable {
        var plan: PatternPlan
        var neck: Int
        var frontAtNeck: Int
        var neckIncreases: Int
        var front: Int
        var body: Int
        var band: Int
        var buttons: Int
    }

    /// A short, boxy cardigan knit flat from the neck down as a raglan, its fronts starting narrow and widening
    /// at the neck edge all through the yoke, so the opening makes a V. A deep ribbed hem, three-quarter
    /// sleeves, and one ribbed band picked up around the whole opening, with the buttons below the V.
    /// `chest` is the finished chest.
    static func croppedCardigan(chest: Double, wearer: Double, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge) -> CroppedCardigan {
        let fit = raglanFit(chest: chest, wearer: wearer, child: false, gauge: g)
        let bandRows = Sizing.rows(1, per: g.rpi, even: true, minimum: 4)
        let bandWidth = max(2, min(even(Double(bandRows) / g.rpi * g.spi), fit.backAtNeck - 4))
        // Each front ends as wide as a crew cardigan's, half the back less half the band.
        let wide = (fit.backAtNeck - bandWidth) / 2
        let yoke = fit.yokeRounds + fit.yokeRounds % 2
        let rightRows = yoke / 2
        let increases = min(wide - 2, rightRows)
        let start = wide - increases
        let front = wide + fit.bodyIncreases
        let neck = fit.backAtNeck + 2 * start + 2 * fit.sleeveAtNeck
        let flatBody = 2 * front + fit.panel + 2 * fit.underarm

        var b = PlanBuilder()
        b.section = "Yoke"
        b.action("With the larger needle, cast on \(neck) stitches.", stitches: neck)
        b.row("P\(start) front, place marker, p\(fit.sleeveAtNeck) sleeve, place marker, p\(fit.backAtNeck) back, place marker, p\(fit.sleeveAtNeck) sleeve, place marker, p\(start) front", stitches: neck)

        // The V widens on right-side rows spread evenly down the yoke, one stitch in from each front edge.
        var onNeedle = neck
        var rows: [(text: String, stitches: Int)] = []
        for (index, grows) in raglanSchedule(body: fit.bodyIncreases, sleeves: fit.sleeveIncreases, rounds: yoke, flat: true).enumerated() {
            let right = index % 2 == 0
            let k = index / 2
            let widen = right && (k + 1) * increases / rightRows > k * increases / rightRows
            onNeedle += (grows.body ? 4 : 0) + (grows.sleeves ? 4 : 0) + (widen ? 2 : 0)
            var text: String = switch (grows.body, grows.sleeves, right) {
            case (true, true, true): "Knit to 1 stitch before the marker, M1R, k1, slip the marker. *Inc across; repeat from * 2 more times. K1, M1L, knit to the end"
            case (true, false, true): "Knit to 1 stitch before the marker, M1R, k1, slip the marker. Knit the sleeve. Inc across the back. Knit the sleeve. K1, M1L, knit to the end"
            case (false, true, true): "Knit the front. Inc across the sleeve. Knit the back. Inc across the sleeve. Knit the front"
            case (false, false, true): "Knit"
            case (true, true, false): "Purl to 1 stitch before the marker, M1P, p1, slip the marker. *Inc purlwise; repeat from * 2 more times. P1, M1P, purl to the end"
            case (true, false, false): "Purl to 1 stitch before the marker, M1P, p1, slip the marker. Purl the sleeve. Inc purlwise across the back. Purl the sleeve. P1, M1P, purl to the end"
            case (false, true, false): "Purl the front. Inc purlwise across the sleeve. Purl the back. Inc purlwise across the sleeve. Purl the front"
            case (false, false, false): "Purl"
            }
            if widen {
                text = "K1, M1L, " + lowerFirst(text)
                text = text.hasSuffix(" to the end") ? String(text.dropLast(" to the end".count)) + " to the last stitch, M1R, k1" : text + " to the last stitch, M1R, k1"
            }
            rows.append((text, onNeedle))
        }
        runs(&b, rows, from: neck)

        b.section = "Divide"
        b.action("Knit the \(front) front stitches. Slip the \(fit.sleeveTop) stitches of the first sleeve to waste yarn, removing the markers on each side.")
        b.action("Under the arm, cast on \(fit.underarm) stitches with the backward loop method. Knit the \(fit.panel) back stitches.")
        b.action("Slip the \(fit.sleeveTop) stitches of the second sleeve to waste yarn, removing the markers on each side.")
        b.row("Under the arm, cast on \(fit.underarm) stitches. Knit the \(front) front stitches", stitches: flatBody)

        // A cropped body ends in a deep rib that pulls it in a little at the waist.
        let hem = Sizing.rows(min(2.5, length * 0.3), per: g.rpi, minimum: 6)
        let bodyRows = max(2, Sizing.rows(length, per: g.rpi) - hem)
        b.section = "Body"
        b.work(["Purl", "Knit"], rows: bodyRows, stitches: flatBody)
        b.section = "Hem"
        b.row("Change to the smaller needle. *K1, p1; repeat from * to the end", stitches: flatBody)
        b.work(["*K1, p1; repeat from * to the end"], rows: hem - 1, stitches: flatBody)
        b.action("Bind off loosely in pattern.")

        let cuff = raglanSleeves(&b, fit, chest: chest, length: sleeveLength, gauge: g)

        // One band around the opening: up the right front, along the V, across the back neck, and back down.
        let straightRows = 1 + bodyRows + hem
        let straightLength = Double(straightRows) / g.rpi
        let straight = Int((straightLength * g.spi).rounded())
        let slant = (pow(Double(yoke + 1) / g.rpi, 2) + pow(Double(increases) / g.spi, 2)).squareRoot()
        let along = Int((slant * g.spi * 0.95).rounded())
        let across = neck - 2 * start
        var pickUp = 2 * straight + 2 * along + across
        let backNeck = across + (pickUp % 2 == 0 ? 1 : 0)
        pickUp = 2 * straight + 2 * along + backNeck
        let buttons = max(3, Int((straightLength / 2.5).rounded()))
        let gaps = buttonholeGaps(buttons, over: straight, edge: max(2, Int((0.4 * g.spi).rounded())))
        let wrong = "P1, *k1, p1; repeat from * to the end", right = "K1, *p1, k1; repeat from * to the end"
        let hole = bandRows / 2 - (bandRows / 2 % 2 == 0 ? 1 : 0)
        b.section = "Front Band"
        b.action("With the smaller needle and the right side facing, start at the hem of the right front. Pick up and knit \(straight) stitches up the right front to the start of the V, \(along) up the V to the cast-on edge, \(backNeck) across the back neck, \(along) down the left side of the V and \(straight) down the left front to the hem. For a man's closing, put the buttonholes on the left front instead.", stitches: pickUp)
        b.work([wrong, right], rows: hole, stitches: pickUp)
        b.row(buttonholeText(gaps, rest: "work the last \((gaps.last ?? 0) + pickUp - straight) in rib"), stitches: pickUp)
        b.row(wrong + ", working each yarn over as a stitch", stitches: pickUp)
        b.work([right, wrong], rows: bandRows - hole - 2, stitches: pickUp)
        b.action("Bind off in pattern.")
        b.section = "Finishing"
        b.action("Sew the \(buttons) buttons to the left front band, opposite the buttonholes. Weave in the ends, closing any gaps at the underarms. Block to the finished measurements.")

        let finishedChest = Double(fit.body) / g.spi
        let area = finishedChest * (length + fit.depth) + (fit.arm + Double(cuff) / g.spi) * sleeveLength + fit.arm * fit.depth + (2 * straightLength + 2 * slant + Double(across) / g.spi) * Double(bandRows) / g.rpi
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            tools: [longCircular(flatBody, g, flat: true), "\(g.ribNeedle.label) circular needle of the same length, for the hem and band", "Double-pointed needles in both sizes for the sleeves, or a long circular for magic loop", "\(buttons) buttons, about \(Sizing.inches(max(0.5, 2.5 / g.spi))) across", "4 stitch markers, waste yarn, tapestry needle"],
            finished: "Finished chest \(Sizing.inches(finishedChest)) with the band buttoned, to fit a \(Sizing.inches(wearer)) chest with \(Sizing.inches(finishedChest - wearer)) of ease. Body \(Sizing.inches(length)) and sleeve \(Sizing.inches(sleeveLength)) from the underarm",
            gauge: g
        )
        return CroppedCardigan(plan: plan, neck: neck, frontAtNeck: start, neckIncreases: increases, front: front, body: flatBody, band: pickUp, buttons: buttons)
    }
}
