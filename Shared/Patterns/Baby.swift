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
}
