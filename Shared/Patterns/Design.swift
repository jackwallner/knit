import Foundation

/// A measurement the knitter can set.
struct Measure: Identifiable, Sendable {
    let key: String
    let label: String
    let range: ClosedRange<Double>
    let step: Double

    var id: String { key }
}

/// A named starting point for the measurements.
struct NamedSize: Identifiable, Sendable {
    let name: String
    let values: [String: Double]

    var id: String { name }
}

/// The pattern library. Every design is a set of rules that writes itself to
/// the knitter's gauge and measurements, so the stitch counts always add up.
enum Design: String, CaseIterable, Identifiable, Codable, Sendable {
    case ribbedBeanie, slouchHat, rolledBrimHat
    case garterScarf, ribbedScarf, seedScarf
    case ribbedCowl, seedCowl
    case borderedBlanket, garterBlanket, dishcloth
    case earWarmer, handwarmers, legWarmers, triangleShawl
    case raglanPullover
    case chunkyCowl, neckScarf, cableHeadband, balaclava

    enum Shelf: String, CaseIterable, Identifiable, Sendable {
        case hats = "Hats"
        case scarves = "Scarves & Cowls"
        case home = "Blankets & Home"
        case accessories = "Accessories"
        case sweaters = "Sweaters"

        var id: String { rawValue }
    }

    enum Level: String, Sendable {
        case beginner = "Beginner"
        case easy = "Easy"
        case intermediate = "Intermediate"
    }

    enum Silhouette: Sendable {
        case hat, slouch, scarf, cowl, blanket, cloth, band, mitts, tubes, shawl, sweater, hood, kerchief
    }

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ribbedBeanie: "Ribbed Beanie"
        case .slouchHat: "Slouch Hat"
        case .rolledBrimHat: "Rolled Brim Hat"
        case .garterScarf: "Garter Scarf"
        case .ribbedScarf: "Ribbed Scarf"
        case .seedScarf: "Seed Stitch Scarf"
        case .ribbedCowl: "Ribbed Cowl"
        case .seedCowl: "Seed Stitch Cowl"
        case .borderedBlanket: "Bordered Blanket"
        case .garterBlanket: "Garter Blanket"
        case .dishcloth: "Diagonal Dishcloth"
        case .earWarmer: "Ear Warmer"
        case .handwarmers: "Handwarmers"
        case .legWarmers: "Leg Warmers"
        case .triangleShawl: "Triangle Shawl"
        case .raglanPullover: "Raglan Pullover"
        case .chunkyCowl: "Chunky Cowl"
        case .neckScarf: "Neck Scarf"
        case .cableHeadband: "Cabled Headband"
        case .balaclava: "Balaclava"
        }
    }

    var shelf: Shelf {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .balaclava: .hats
        case .garterScarf, .ribbedScarf, .seedScarf, .ribbedCowl, .seedCowl, .chunkyCowl, .neckScarf: .scarves
        case .borderedBlanket, .garterBlanket, .dishcloth: .home
        case .earWarmer, .handwarmers, .legWarmers, .triangleShawl, .cableHeadband: .accessories
        case .raglanPullover: .sweaters
        }
    }

    var level: Level {
        switch self {
        case .garterScarf, .garterBlanket, .ribbedScarf, .seedScarf: .beginner
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .ribbedCowl, .seedCowl, .borderedBlanket, .earWarmer, .legWarmers, .triangleShawl, .chunkyCowl, .neckScarf, .dishcloth, .handwarmers: .easy
        case .raglanPullover, .cableHeadband, .balaclava: .intermediate
        }
    }

    /// Free designs show what the library does before anyone is asked to pay.
    var isFree: Bool { self == .garterScarf || self == .dishcloth }

    var silhouette: Silhouette {
        switch self {
        case .ribbedBeanie, .rolledBrimHat: .hat
        case .slouchHat: .slouch
        case .garterScarf, .ribbedScarf, .seedScarf: .scarf
        case .ribbedCowl, .seedCowl, .chunkyCowl: .cowl
        case .neckScarf: .kerchief
        case .balaclava: .hood
        case .borderedBlanket, .garterBlanket: .blanket
        case .dishcloth: .cloth
        case .earWarmer, .cableHeadband: .band
        case .handwarmers: .mitts
        case .legWarmers: .tubes
        case .triangleShawl: .shawl
        case .raglanPullover: .sweater
        }
    }

    var yarn: YarnColor {
        switch self {
        case .ribbedBeanie: .spruce
        case .slouchHat: .plum
        case .rolledBrimHat: .marigold
        case .garterScarf: .madder
        case .ribbedScarf: .charcoal
        case .seedScarf: .moss
        case .ribbedCowl: .indigo
        case .seedCowl: .oat
        case .borderedBlanket: .oat
        case .garterBlanket: .spruce
        case .dishcloth: .marigold
        case .earWarmer: .madder
        case .handwarmers: .moss
        case .legWarmers: .plum
        case .triangleShawl: .indigo
        case .raglanPullover: .madder
        case .chunkyCowl: .marigold
        case .neckScarf: .spruce
        case .cableHeadband: .oat
        case .balaclava: .indigo
        }
    }

    var weight: YarnWeight {
        switch self {
        case .triangleShawl, .neckScarf: .dk
        case .garterBlanket, .slouchHat, .cableHeadband: .aran
        case .chunkyCowl: .superBulky
        default: .worsted
        }
    }

    var measures: [Measure] {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat:
            [Measure(key: "head", label: "Head", range: 13...26, step: 0.5)]
        case .garterScarf, .ribbedScarf, .seedScarf:
            [Measure(key: "width", label: "Width", range: 4...14, step: 0.5), Measure(key: "length", label: "Length", range: 30...90, step: 2)]
        case .ribbedCowl, .seedCowl, .chunkyCowl:
            [Measure(key: "around", label: "Around", range: 18...60, step: 1), Measure(key: "height", label: "Height", range: 5...16, step: 0.5)]
        case .borderedBlanket, .garterBlanket:
            [Measure(key: "width", label: "Width", range: 20...70, step: 1), Measure(key: "length", label: "Length", range: 20...90, step: 1)]
        case .dishcloth:
            [Measure(key: "side", label: "Side", range: 6...12, step: 0.5)]
        case .earWarmer, .cableHeadband:
            [Measure(key: "head", label: "Head", range: 15...25, step: 0.5), Measure(key: "width", label: "Width", range: 2.5...5, step: 0.25)]
        case .handwarmers:
            [Measure(key: "hand", label: "Hand", range: 5.5...10.5, step: 0.25)]
        case .legWarmers:
            [Measure(key: "calf", label: "Calf", range: 9...20, step: 0.5), Measure(key: "length", label: "Length", range: 8...22, step: 1)]
        case .triangleShawl:
            [Measure(key: "wingspan", label: "Wingspan", range: 36...84, step: 2)]
        case .neckScarf:
            [Measure(key: "length", label: "Length", range: 28...60, step: 2), Measure(key: "width", label: "Width", range: 3...9, step: 0.5)]
        case .balaclava:
            [Measure(key: "head", label: "Head", range: 17...26, step: 0.5)]
        case .raglanPullover:
            [Measure(key: "chest", label: "Chest", range: 26...62, step: 1), Measure(key: "body", label: "Body Length", range: 8...22, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 10...22, step: 0.5)]
        }
    }

    var sizes: [NamedSize] {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat:
            [("Baby", 16), ("Toddler", 18), ("Child", 20), ("Small", 21), ("Medium", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1]) }
        case .garterScarf, .ribbedScarf, .seedScarf:
            [NamedSize(name: "Child", values: ["width": 5, "length": 48]), NamedSize(name: "Classic", values: ["width": 7, "length": 64]), NamedSize(name: "Long", values: ["width": 8, "length": 76])]
        case .ribbedCowl, .seedCowl, .chunkyCowl:
            [NamedSize(name: "Snug", values: ["around": 22, "height": 8]), NamedSize(name: "Classic", values: ["around": 26, "height": 10]), NamedSize(name: "Infinity", values: ["around": 52, "height": 9])]
        case .borderedBlanket, .garterBlanket:
            [NamedSize(name: "Stroller", values: ["width": 30, "length": 35]), NamedSize(name: "Crib", values: ["width": 36, "length": 45]), NamedSize(name: "Throw", values: ["width": 48, "length": 60])]
        case .dishcloth:
            [("Small", 7), ("Classic", 8.5), ("Large", 10)].map { NamedSize(name: $0.0, values: ["side": $0.1]) }
        case .earWarmer, .cableHeadband:
            [("Child", 20), ("Adult", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1, "width": 3.5]) }
        case .handwarmers:
            [("Small", 6.5), ("Medium", 7.5), ("Large", 8.5)].map { NamedSize(name: $0.0, values: ["hand": $0.1]) }
        case .legWarmers:
            [NamedSize(name: "Child", values: ["calf": 10, "length": 10]), NamedSize(name: "Adult", values: ["calf": 14, "length": 14]), NamedSize(name: "Wide", values: ["calf": 17, "length": 14])]
        case .triangleShawl:
            [("Shawlette", 44), ("Classic", 60), ("Wrap", 72)].map { NamedSize(name: $0.0, values: ["wingspan": $0.1]) }
        case .neckScarf:
            [NamedSize(name: "Small", values: ["length": 36, "width": 4.5]), NamedSize(name: "Classic", values: ["length": 42, "width": 5.5]), NamedSize(name: "Long", values: ["length": 50, "width": 6.5])]
        case .balaclava:
            [("Child", 20), ("Small", 21), ("Medium", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1]) }
        case .raglanPullover:
            [("XS", 30, 14, 17), ("S", 34, 14.5, 17.5), ("M", 38, 15, 18), ("L", 42, 15.5, 18.5), ("XL", 46, 16, 19), ("2X", 50, 16.5, 19), ("3X", 54, 17, 19.5), ("4X", 58, 17, 19.5), ("5X", 62, 17.5, 20)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        }
    }

    /// Inches a pullover is knit larger than the chest it is for: a classic, easy fit.
    static let sweaterEase = 3.0

    /// The size a new knitter most likely wants.
    var defaultSize: NamedSize {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat: sizes[4]
        case .raglanPullover, .balaclava: sizes[2]
        default: sizes[1]
        }
    }

    func plan(measures: [String: Double], gauge: Gauge) -> PatternPlan {
        var values = defaultSize.values
        for measure in self.measures {
            if let given = measures[measure.key] { values[measure.key] = min(max(given, measure.range.lowerBound), measure.range.upperBound) }
        }
        func value(_ key: String) -> Double { values[key] ?? 0 }
        switch self {
        case .ribbedBeanie: return Engines.hat(.ribbed, head: value("head"), gauge: gauge)
        case .slouchHat: return Engines.hat(.slouch, head: value("head"), gauge: gauge)
        case .rolledBrimHat: return Engines.hat(.rolled, head: value("head"), gauge: gauge)
        case .garterScarf: return Engines.scarf(.garter, width: value("width"), length: value("length"), gauge: gauge)
        case .ribbedScarf: return Engines.scarf(.rib, width: value("width"), length: value("length"), gauge: gauge)
        case .seedScarf: return Engines.scarf(.seed, width: value("width"), length: value("length"), gauge: gauge)
        case .ribbedCowl: return Engines.cowl(.rib, around: value("around"), height: value("height"), gauge: gauge)
        case .seedCowl: return Engines.cowl(.seed, around: value("around"), height: value("height"), gauge: gauge)
        case .borderedBlanket: return Engines.blanket(bordered: true, width: value("width"), length: value("length"), gauge: gauge)
        case .garterBlanket: return Engines.blanket(bordered: false, width: value("width"), length: value("length"), gauge: gauge)
        case .dishcloth: return Engines.dishcloth(side: value("side"), gauge: gauge)
        case .earWarmer: return Engines.earWarmer(head: value("head"), width: value("width"), gauge: gauge)
        case .handwarmers: return Engines.handwarmers(hand: value("hand"), gauge: gauge)
        case .legWarmers: return Engines.legWarmers(calf: value("calf"), length: value("length"), gauge: gauge)
        case .triangleShawl: return Engines.shawl(wingspan: value("wingspan"), gauge: gauge)
        case .chunkyCowl: return Engines.cowl(.garter, around: value("around"), height: value("height"), gauge: gauge)
        case .neckScarf: return Engines.neckScarf(length: value("length"), width: value("width"), gauge: gauge)
        case .cableHeadband: return Engines.cableHeadband(head: value("head"), width: value("width"), gauge: gauge)
        case .balaclava: return Engines.balaclava(head: value("head"), gauge: gauge)
        // The chest a knitter measures is the body: the sweater is knit with room to wear over it.
        case .raglanPullover: return Engines.raglan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge).plan
        }
    }
}

extension YarnWeight {
    /// The gauge a yarn label for this weight usually states.
    var gauge: Gauge {
        switch self {
        case .lace: Gauge(stitches: 32, rows: 40)
        case .fingering: Gauge(stitches: 28, rows: 36)
        case .sport: Gauge(stitches: 24, rows: 32)
        case .dk: Gauge(stitches: 22, rows: 28)
        case .worsted: Gauge(stitches: 18, rows: 24)
        case .aran: Gauge(stitches: 16, rows: 22)
        case .bulky: Gauge(stitches: 14, rows: 20)
        case .superBulky: Gauge(stitches: 10, rows: 14)
        }
    }
}

extension Gauge {
    /// The needle a knitter would usually reach for at this gauge.
    var needle: NeedleSize {
        let millimeters: Double = switch stitches {
        case 30...: 2.75
        case 26..<30: 3.25
        case 23..<26: 3.75
        case 20..<23: 4.0
        case 17..<20: 4.5
        case 15..<17: 5.5
        case 12..<15: 6.5
        default: 9.0
        }
        return NeedleSize.nearest(to: millimeters, hook: false)
    }

    /// Two sizes down, for ribbing.
    var ribNeedle: NeedleSize {
        let all = NeedleSize.needles
        let index = all.firstIndex(of: needle) ?? 7
        return all[max(0, index - 2)]
    }
}
