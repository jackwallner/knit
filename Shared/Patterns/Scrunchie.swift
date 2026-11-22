import Foundation

extension Engines {
    /// A scrunchie: a long stockinette strip folded lengthwise around a hair elastic and seamed shut, so it
    /// gathers into a soft ring. `width` is the strip's width as knit and `length` its length, about two and a
    /// half times around the elastic.
    static func scrunchie(width: Double, length: Double, gauge g: Gauge) -> PatternPlan {
        let stitches = max(8, Sizing.stitches(width, per: g.spi))
        let rows = max(20, Sizing.rows(length, per: g.rpi, even: true))

        var b = PlanBuilder()
        b.section = "Strip"
        b.action("Cast on \(stitches) stitches, leaving a \(Sizing.inches(12)) tail.", stitches: stitches)
        b.work(["Knit", "Purl"], rows: rows, stitches: stitches)
        b.action("Bind off, leaving a \(Sizing.inches(24)) tail to sew with.")
        b.section = "Finishing"
        b.action("Lay the hair elastic on the wrong side of the strip. Fold the strip lengthwise around it, right side out, and sew the long edges together with the long tail, pushing the strip along the elastic as you go so it gathers. Sew the cast-on edge to the bound-off edge with the other tail, and weave in the ends.")

        let area = Double(stitches) / g.spi * Double(rows) / g.rpi
        return pattern(
            b, estimate: Sizing.yards(squareInches: area, spi: g.spi),
            yarnNote: ", cotton, silk or a soft wool",
            tools: ["\(g.needle.label) needles", "A hair elastic about \(Sizing.inches(2)) across", "Tapestry needle"],
            finished: "A strip \(Sizing.inches(Double(stitches) / g.spi)) wide and \(Sizing.inches(Double(rows) / g.rpi)) long, gathered into a ring about \(Sizing.inches(Double(stitches) / g.spi / 2 + 2.5)) across",
            gauge: g
        )
    }
}
