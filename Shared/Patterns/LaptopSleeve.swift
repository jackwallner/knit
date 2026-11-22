import Foundation

extension Engines {
    struct LaptopSleeve: Equatable, Sendable {
        var plan: PatternPlan
        var half: Int
        var flapRows: Int
        var bodyRounds: Int
        var buttonhole: Int
    }

    /// A seed stitch laptop sleeve knit from the tip of its flap down: the flap flat with a buttonhole, then the
    /// front cast on beside it and the body worked in the round to the bottom, closed with a three-needle bind
    /// off. Seed stitch is firm and cushions. `width` and `height` are the laptop's, measured flat.
    static func laptopSleeve(width: Double, height: Double, gauge g: Gauge) -> LaptopSleeve {
        // Half an inch of ease across, for the laptop's thickness. An even count for seed stitch in the round.
        let half = max(20, 2 * Int(((width + 0.5) * g.spi / 2).rounded()))
        let around = 2 * half
        let rate = g.rpi * 1.1
        let flap = max(6, Sizing.rows(min(4, height * 0.35), per: rate, even: true))
        let hole = max(2, Int((0.6 * g.spi).rounded()))
        let before = (half - hole) / 2
        let tip = max(2, Sizing.rows(0.6, per: rate, even: true))
        let body = max(8, Sizing.rows(height + 0.5, per: rate, even: true))
        let odd = "*K1, p1; repeat from * to the end"
        let even = "*P1, k1; repeat from * to the end"

        var b = PlanBuilder()
        b.section = "Flap"
        b.action("Cast on \(half) stitches. This edge is the tip of the flap.", stitches: half)
        b.work([odd, even], rows: tip, stitches: half)
        b.row("Work \(before) stitches in pattern, bind off the next \(hole) stitches for the buttonhole and work in pattern to the end", stitches: half - hole)
        b.row("Work in pattern to the gap, cast on \(hole) stitches over it with the backward loop method and work in pattern to the end", stitches: half)
        b.work([odd, even], rows: flap - tip - 2, stitches: half)
        b.section = "Body"
        b.row("With the right side facing, work across the flap in pattern, then cast on \(half) stitches for the front. Join in the round without twisting and place a marker. The flap stitches are now the back", stitches: around)
        // The back was just worked as an odd row, so the first round starts with the even one.
        b.work(["*P1, k1; repeat from * around", "*K1, p1; repeat from * around"], rows: body, stitches: around)
        b.section = "Bottom"
        b.action("Turn the sleeve inside out. Put the \(half) back stitches on one needle and the \(half) front stitches on another, held parallel.")
        b.action("Join them with a three-needle bind off, and turn the sleeve right side out.")
        b.section = "Finishing"
        b.action("Weave in the ends. Fold the flap over the front, mark where the buttonhole falls and sew the button there.")

        let wide = Double(half) / g.spi
        let tall = Double(body) / rate
        let flapLength = Double(flap) / rate
        let button = Double(hole) / g.spi
        let plan = pattern(
            b, estimate: Sizing.yards(squareInches: wide * (2 * tall + flapLength), spi: g.spi, factor: 1.2),
            yarnNote: ", a sturdy wool or wool blend",
            tools: [
                "\(g.needle.label) \(Sizing.cable(Double(around) / g.spi >= 30 ? 24 : 16)) circular needle, and a spare needle in the same size for the bind off",
                "A button about \(Sizing.inches(button)) across", "Stitch marker", "Tapestry needle",
            ],
            finished: "\(Sizing.inches(wide)) wide and \(Sizing.inches(tall)) deep inside, with a \(Sizing.inches(flapLength)) flap",
            gauge: g
        )
        return LaptopSleeve(plan: plan, half: half, flapRows: flap, bodyRounds: body, buttonhole: hole)
    }
}
