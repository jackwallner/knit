import Foundation

/// Baby garments added after the first release.
extension Engines {
    /// A raglan cut for a baby: the child's upper arm and yoke depth (Craft Yarn Council), with a neck
    /// scaled down to a baby's, an inch narrower across the back and half an inch at the top of each sleeve.
    static func babyFit(chest: Double, wearer: Double?, gauge g: Gauge) -> RaglanFit {
        var fit = raglanFit(chest: chest, wearer: wearer, child: true, gauge: g)
        fit.backAtNeck = min(even(min(chest * 0.1 + 2.5, 8.5) * g.spi, minimum: 4), fit.panel - 2)
        fit.sleeveAtNeck = min(even(1.5 * g.spi, minimum: 4), fit.sleeveTop - 2)
        fit.bodyIncreases = (fit.panel - fit.backAtNeck) / 2
        fit.sleeveIncreases = (fit.sleeveTop - fit.sleeveAtNeck) / 2
        fit.yokeRounds = max(Sizing.rows(fit.depth, per: g.rpi), max(fit.bodyIncreases, fit.sleeveIncreases))
        return fit
    }

    struct BabyPullover: Equatable, Sendable {
        var plan: PatternPlan
        var neck: Int
        var body: Int
        var flatRows: Int
        var band: Int
    }

    /// A baby's pullover knit from the neck down as a raglan. A baby's head is large for the neck, so the
    /// neck and the top of the yoke are worked flat, open at the raglan line between the back and the left
    /// sleeve, then joined in the round. The opening gets a ribbed band on each side and two buttons.
    /// `chest` is the finished chest.
    static func babyPullover(chest: Double, wearer: Double, body length: Double, sleeve sleeveLength: Double, gauge g: Gauge) -> BabyPullover {
        let fit = babyFit(chest: chest, wearer: wearer, gauge: g)
        let neck = fit.neck
        let neckband = Sizing.rows(0.75, per: g.rpi, even: true, minimum: 4)
        // The opening runs about 2 in below the cast on: the neckband, then the first rows of the yoke.
        let flat = max(4, Sizing.rows(2, per: g.rpi, even: true) - neckband)
        let yoke = max(fit.yokeRounds, flat + 2)

        var b = PlanBuilder()
        b.section = "Neckband"
        b.action("With the smaller needle, cast on \(neck) stitches. The neck is worked back and forth at first, open where the back meets a sleeve.", stitches: neck)
        b.work(["*K1, p1; repeat from * to the end"], rows: neckband, stitches: neck)

        b.section = "Yoke"
        b.row("Change to the larger needle. K\(fit.sleeveAtNeck) sleeve, place marker, k\(fit.backAtNeck) front, place marker, k\(fit.sleeveAtNeck) sleeve, place marker, k\(fit.backAtNeck) back, turn", stitches: neck)
        b.row("Purl to the end, turn", stitches: neck)
        var onNeedle = neck
        var rows: [(text: String, stitches: Int)] = []
        var moved = false
        for (index, grows) in raglanSchedule(body: fit.bodyIncreases, sleeves: fit.sleeveIncreases, rounds: yoke - 2).enumerated() {
            onNeedle += (grows.body ? 4 : 0) + (grows.sleeves ? 4 : 0)
            let worked = index + 2
            var text: String
            if worked < flat {
                // Back and forth: the right side ends with the back and the wrong side with a sleeve, at the edge of the opening, not at a marker.
                let right = worked % 2 == 0
                text = switch (grows.body, grows.sleeves, right) {
                case (true, true, true): "*Inc across; repeat from * 2 more times. K1, M1L, knit to the last stitch, M1R, k1, turn"
                case (true, false, true): "Knit the sleeve. Inc across the front. Knit the sleeve. K1, M1L, knit to the last stitch, M1R, k1, turn"
                case (false, true, true): "Inc across the sleeve. Knit the front. Inc across the sleeve. Knit to the end, turn"
                case (false, false, true): "Knit to the end, turn"
                case (true, true, false): "*Inc purlwise; repeat from * 2 more times. P1, M1P, purl to the last stitch, M1P, p1, turn"
                case (true, false, false): "Inc purlwise across the back. Purl the sleeve. Inc purlwise across the front. Purl to the end, turn"
                case (false, true, false): "Purl the back. Inc purlwise across the sleeve. Purl the front. P1, M1P, purl to the last stitch, M1P, p1, turn"
                case (false, false, false): "Purl to the end, turn"
                }
                if worked == flat - 1 { text += ". Join in the round to close the opening, and place a marker for the start of the round" }
            } else {
                text = switch (grows.body, grows.sleeves) {
                case (true, true): "*Inc across; repeat from * 3 more times"
                case (true, false): "Knit the sleeve. Inc across the front. Knit the sleeve. Inc across the back"
                case (false, true): "Inc across the sleeve. Knit the front. Inc across the sleeve. Knit the back"
                case (false, false): "Knit"
                }
            }
            if !moved, worked >= flat, Double(onNeedle) / g.spi > 16 {
                text += ". Move the stitches to the longer needle"
                moved = true
            }
            rows.append((text, onNeedle))
        }
        runs(&b, rows, from: neck)

        b.section = "Divide"
        b.action("Slip the \(fit.sleeveTop) stitches of the first sleeve to waste yarn, removing the markers on each side.")
        b.action("Under the arm, cast on \(fit.underarm) stitches with the backward loop method. Knit the \(fit.panel) front stitches.")
        b.action("Slip the \(fit.sleeveTop) stitches of the second sleeve to waste yarn, removing the markers on each side.")
        b.row("Under the arm, cast on \(fit.underarm) stitches. Knit the \(fit.panel) back stitches. Place a marker here for the new start of the round", stitches: fit.body)

        let hem = Sizing.rows(min(1.25, length * 0.2), per: g.rpi, minimum: 4)
        b.section = "Body"
        b.work(["Knit"], rows: max(2, Sizing.rows(length, per: g.rpi) - hem), stitches: fit.body)
        b.section = "Hem"
        b.row("Change to the smaller needle. *K1, p1; repeat from * around", stitches: fit.body)
        b.work(["*K1, p1; repeat from * around"], rows: hem - 1, stitches: fit.body)
        b.action("Bind off loosely in pattern.")

        let cuff = raglanSleeves(&b, fit, chest: chest, length: sleeveLength, gauge: g)

        // Each side of the opening: the neckband and the flat rows of the yoke.
        let edge = Double(neckband + flat) / g.rpi
        let picked = Int((edge * g.spi * 0.9).rounded())
        let band = max(9, picked + 1 - picked % 2)
        let bandRows = Sizing.rows(0.5, per: g.rpi, even: true, minimum: 4)
        let wrong = "P1, *k1, p1; repeat from * to the end", right = "K1, *p1, k1; repeat from * to the end"
        let hole = bandRows / 2 - (bandRows / 2 % 2 == 0 ? 1 : 0)
        let gaps = buttonholeGaps(2, over: band, edge: max(1, band / 8))
        b.section = "Button Band"
        b.action("With the smaller needle and the right side facing, pick up and knit \(band) stitches down the back edge of the opening, from the top of the neckband to the base.", stitches: band)
        b.work([wrong, right], rows: bandRows, stitches: band)
        b.action("Bind off in pattern.")
        b.section = "Buttonhole Band"
        b.action("With the smaller needle and the right side facing, pick up and knit \(band) stitches up the sleeve edge of the opening, from the base to the top of the neckband.", stitches: band)
        b.work([wrong, right], rows: hole, stitches: band)
        b.row(buttonholeText(gaps, rest: "work the last \(gaps.last ?? 0) in rib"), stitches: band)
        b.row(wrong + ", working each yarn over as a stitch", stitches: band)
        b.work([right, wrong], rows: bandRows - hole - 2, stitches: band)
        b.action("Bind off in pattern.")
        b.section = "Finishing"
        b.action("Lap the buttonhole band over the button band at the base of the opening and sew both ends down. Sew the 2 buttons to the button band, opposite the buttonholes. Weave in the ends, closing any gaps at the underarms.")

        let finishedChest = Double(fit.body) / g.spi
        let area = finishedChest * (length + fit.depth) + (fit.arm + Double(cuff) / g.spi) * sleeveLength + fit.arm * fit.depth
        let long = Double(fit.body) / g.spi < 21 ? 16 : 24
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            tools: ["\(g.needle.label) circular needles, \(Sizing.cable(12)) and \(Sizing.cable(long)), or a long circular for magic loop", "\(g.ribNeedle.label) needle of the same kind, for the ribbing and bands", "Double-pointed needles in both sizes for the sleeves, or a long circular for magic loop", "2 buttons, about \(Sizing.inches(max(0.375, 2 / g.spi))) across", "4 stitch markers, waste yarn, tapestry needle"],
            finished: "Finished chest \(Sizing.inches(finishedChest)), to fit a \(Sizing.inches(wearer)) chest with \(Sizing.inches(finishedChest - wearer)) of ease. Body \(Sizing.inches(length)) and sleeve \(Sizing.inches(sleeveLength)) from the underarm",
            gauge: g
        )
        return BabyPullover(plan: plan, neck: neck, body: fit.body, flatRows: neckband + flat, band: band)
    }
}
