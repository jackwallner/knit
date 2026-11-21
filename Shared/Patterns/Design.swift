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
    case cuffDownSocks, mittens, raglanCardigan, sweaterVest, kidsRaglan, earflapHat, cabledBeanie
    case basketweaveBlanket, rectangularWrap, crescentShawl, marketBag, pillowCover
    case pompomBonnet, beret
    case dropShoulder, keyholeScarf, slippers, babyBooties
    case toeUpSocks, fingerlessMitts, babyCardigan, topDownBeanie, twistedHeadband, poncho, christmasStocking

    enum Shelf: String, CaseIterable, Identifiable, Sendable {
        case hats = "Hats"
        case scarves = "Scarves & Cowls"
        case home = "Blankets & Home"
        case accessories = "Accessories"
        case sweaters = "Sweaters"

        var id: String { rawValue }

        var title: String { Loc.text(rawValue) }
    }

    enum Level: String, Sendable {
        case beginner = "Beginner"
        case easy = "Easy"
        case intermediate = "Intermediate"

        var title: String { Loc.text(rawValue) }
    }

    /// Raw values are stored in a cast-on plan, so they never change.
    enum Silhouette: String, Sendable {
        case hat, slouch, scarf, cowl, blanket, cloth, band, mitts, tubes, shawl, sweater, hood, kerchief, ears
        case socks, mittens, cardigan, vest, earflap, wrap, crescent, bag, pillow, bonnet, beret
        case dropShoulder, keyhole, slipper
        case toeUp, topDown, poncho, stocking
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
        case .cuffDownSocks: "Cuff-Down Socks"
        case .mittens: "Mittens"
        case .raglanCardigan: "Raglan Cardigan"
        case .sweaterVest: "Sweater Vest"
        case .kidsRaglan: "Kids' Raglan"
        case .earflapHat: "Earflap Hat"
        case .cabledBeanie: "Cabled Beanie"
        case .basketweaveBlanket: "Basketweave Blanket"
        case .rectangularWrap: "Rectangular Wrap"
        case .crescentShawl: "Crescent Shawl"
        case .marketBag: "Market Bag"
        case .pillowCover: "Pillow Cover"
        case .pompomBonnet: "Pompom Bonnet"
        case .beret: "Beret"
        case .dropShoulder: "Drop-Shoulder Sweater"
        case .keyholeScarf: "Keyhole Scarf"
        case .slippers: "Slippers"
        case .babyBooties: "Baby Booties"
        case .toeUpSocks: "Toe-Up Socks"
        case .fingerlessMitts: "Fingerless Mitts"
        case .babyCardigan: "Baby Cardigan"
        case .topDownBeanie: "Top-Down Beanie"
        case .twistedHeadband: "Twisted Headband"
        case .poncho: "Poncho"
        case .christmasStocking: "Christmas Stocking"
        }
    }

    /// English words a search should find the design by beyond its name: "christmas" searches as "holiday".
    var searchWords: String { self == .christmasStocking ? "holiday" : "" }

    /// The name in the knitter's language. `name` stays English, as the tests and saved plans know it.
    var title: String { Loc.text(name) }

    var shelf: Shelf {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .balaclava, .earflapHat, .cabledBeanie, .pompomBonnet, .beret, .topDownBeanie: .hats
        case .garterScarf, .ribbedScarf, .seedScarf, .ribbedCowl, .seedCowl, .chunkyCowl, .neckScarf, .rectangularWrap, .keyholeScarf, .poncho: .scarves
        case .borderedBlanket, .garterBlanket, .dishcloth, .basketweaveBlanket, .pillowCover, .marketBag, .christmasStocking: .home
        case .earWarmer, .handwarmers, .legWarmers, .triangleShawl, .cableHeadband, .crescentShawl, .mittens, .cuffDownSocks, .slippers, .babyBooties, .toeUpSocks, .fingerlessMitts, .twistedHeadband: .accessories
        case .raglanPullover, .raglanCardigan, .sweaterVest, .kidsRaglan, .dropShoulder, .babyCardigan: .sweaters
        }
    }

    var level: Level {
        switch self {
        case .garterScarf, .garterBlanket, .ribbedScarf, .seedScarf, .keyholeScarf, .slippers, .twistedHeadband, .poncho: .beginner
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .ribbedCowl, .seedCowl, .borderedBlanket, .earWarmer, .legWarmers, .triangleShawl, .chunkyCowl, .neckScarf, .dishcloth, .handwarmers: .easy
        case .earflapHat, .basketweaveBlanket, .rectangularWrap, .crescentShawl, .marketBag, .pillowCover, .mittens: .easy
        case .pompomBonnet, .beret, .dropShoulder, .babyBooties, .fingerlessMitts, .topDownBeanie: .easy
        case .raglanPullover, .cableHeadband, .balaclava: .intermediate
        case .cuffDownSocks, .raglanCardigan, .sweaterVest, .kidsRaglan, .cabledBeanie, .toeUpSocks, .babyCardigan, .christmasStocking: .intermediate
        }
    }

    /// Raised when an engine fix changes what a knitter of this design must knit (a confirmed pattern report,
    /// `.claude/rules/pattern-reports.md`). A project cast on at a lower revision is offered the corrected
    /// pattern; it is never changed without the knitter's tap.
    var revision: Int { Self.revisions[self] ?? 0 }
    private static let revisions: [Design: Int] = [:]

    /// Free designs show what the library does before anyone is asked to pay.
    var isFree: Bool { self == .garterScarf || self == .dishcloth }

    /// The asset name of the knitted sample photographed for the design page.
    var photo: String { "sample-\(rawValue)" }

    /// The designs that shipped in 1.0 carry their photo in the app. Every one added since has it on the
    /// site instead, under this path, so the app does not grow with the library.
    var sitePhoto: String? { Self.firstRelease.contains(self) ? nil : "photos/\(rawValue).jpg" }

    private static let firstRelease: Set<Design> = [
        .ribbedBeanie, .slouchHat, .rolledBrimHat, .garterScarf, .ribbedScarf, .seedScarf, .ribbedCowl, .seedCowl,
        .borderedBlanket, .garterBlanket, .dishcloth, .earWarmer, .handwarmers, .legWarmers, .triangleShawl,
        .raglanPullover, .chunkyCowl, .neckScarf, .cableHeadband, .balaclava, .cuffDownSocks, .mittens, .raglanCardigan,
        .sweaterVest, .kidsRaglan, .earflapHat, .cabledBeanie, .basketweaveBlanket, .rectangularWrap, .crescentShawl,
        .marketBag, .pillowCover, .pompomBonnet, .beret, .dropShoulder, .keyholeScarf, .slippers, .babyBooties,
    ]

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
        case .earWarmer, .cableHeadband, .twistedHeadband: .band
        case .handwarmers, .fingerlessMitts: .mitts
        case .legWarmers: .tubes
        case .triangleShawl: .shawl
        case .raglanPullover, .kidsRaglan: .sweater
        case .cuffDownSocks: .socks
        case .mittens: .mittens
        case .raglanCardigan, .babyCardigan: .cardigan
        case .sweaterVest: .vest
        case .earflapHat: .earflap
        case .cabledBeanie: .hat
        case .basketweaveBlanket: .blanket
        case .rectangularWrap: .wrap
        case .crescentShawl: .crescent
        case .marketBag: .bag
        case .pillowCover: .pillow
        case .pompomBonnet: .bonnet
        case .beret: .beret
        case .dropShoulder: .dropShoulder
        case .keyholeScarf: .keyhole
        case .slippers, .babyBooties: .slipper
        case .toeUpSocks: .toeUp
        case .topDownBeanie: .topDown
        case .poncho: .poncho
        case .christmasStocking: .stocking
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
        case .cuffDownSocks: .moss
        case .mittens: .madder
        case .raglanCardigan: .oat
        case .sweaterVest: .charcoal
        case .kidsRaglan: .marigold
        case .earflapHat: .spruce
        case .cabledBeanie: .oat
        case .basketweaveBlanket: .madder
        case .rectangularWrap: .plum
        case .crescentShawl: .spruce
        case .marketBag: .marigold
        case .pillowCover: .indigo
        case .pompomBonnet: .oat
        case .beret: .madder
        case .dropShoulder: .oat
        case .keyholeScarf: .plum
        case .slippers: .spruce
        case .babyBooties: .marigold
        case .toeUpSocks: .indigo
        case .fingerlessMitts: .charcoal
        case .babyCardigan: .moss
        case .topDownBeanie: .indigo
        case .twistedHeadband: .plum
        case .poncho: .oat
        case .christmasStocking: .madder
        }
    }

    /// The gauge this design is knit at in a yarn weight. Socks are knit firmer than the label so they wear well.
    func gauge(for weight: YarnWeight) -> Gauge {
        if [.cuffDownSocks, .toeUpSocks].contains(self), weight == .fingering { return Gauge(stitches: 32, rows: 44) }
        return weight.gauge
    }

    var weight: YarnWeight {
        switch self {
        case .triangleShawl, .neckScarf, .sweaterVest, .rectangularWrap, .beret, .babyBooties, .babyCardigan: .dk
        case .garterBlanket, .slouchHat, .cableHeadband, .cabledBeanie, .keyholeScarf, .slippers: .aran
        case .cuffDownSocks, .crescentShawl, .toeUpSocks: .fingering
        // Chunky is #5 bulky to most knitters.
        case .chunkyCowl, .dropShoulder: .bulky
        default: .worsted
        }
    }

    var measures: [Measure] {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .earflapHat, .cabledBeanie, .pompomBonnet, .beret, .topDownBeanie:
            [Measure(key: "head", label: "Head", range: 13...26, step: 0.5)]
        case .garterScarf, .ribbedScarf, .seedScarf:
            [Measure(key: "width", label: "Width", range: 4...14, step: 0.5), Measure(key: "length", label: "Length", range: 30...90, step: 2)]
        case .ribbedCowl, .seedCowl, .chunkyCowl:
            [Measure(key: "around", label: "Around", range: 18...60, step: 1), Measure(key: "height", label: "Height", range: 5...16, step: 0.5)]
        case .borderedBlanket, .garterBlanket, .basketweaveBlanket:
            [Measure(key: "width", label: "Width", range: 20...70, step: 1), Measure(key: "length", label: "Length", range: 20...90, step: 1)]
        case .dishcloth:
            [Measure(key: "side", label: "Side", range: 6...12, step: 0.5)]
        case .earWarmer, .cableHeadband, .twistedHeadband:
            [Measure(key: "head", label: "Head", range: 15...25, step: 0.5), Measure(key: "width", label: "Width", range: 2.5...5, step: 0.25)]
        case .handwarmers, .fingerlessMitts:
            [Measure(key: "hand", label: "Hand", range: 5.5...10.5, step: 0.25)]
        case .legWarmers:
            [Measure(key: "calf", label: "Calf", range: 9...20, step: 0.5), Measure(key: "length", label: "Length", range: 8...22, step: 1)]
        case .triangleShawl:
            [Measure(key: "wingspan", label: "Wingspan", range: 36...84, step: 2)]
        case .crescentShawl:
            [Measure(key: "wingspan", label: "Wingspan", range: 30...84, step: 2)]
        case .neckScarf:
            [Measure(key: "length", label: "Length", range: 28...60, step: 2), Measure(key: "width", label: "Width", range: 3...9, step: 0.5)]
        case .balaclava:
            [Measure(key: "head", label: "Head", range: 17...26, step: 0.5)]
        case .raglanPullover, .raglanCardigan, .dropShoulder:
            [Measure(key: "chest", label: "Chest", range: 26...62, step: 1), Measure(key: "body", label: "Body Length", range: 8...22, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 10...22, step: 0.5)]
        case .sweaterVest:
            [Measure(key: "chest", label: "Chest", range: 26...62, step: 1), Measure(key: "body", label: "Body Length", range: 8...22, step: 0.5)]
        case .kidsRaglan:
            [Measure(key: "chest", label: "Chest", range: 18...34, step: 0.5), Measure(key: "body", label: "Body Length", range: 5...16, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 5...17, step: 0.5)]
        case .christmasStocking:
            [Measure(key: "around", label: "Around", range: 12...26, step: 1), Measure(key: "leg", label: "Leg Length", range: 6...20, step: 0.5), Measure(key: "footLength", label: "Foot Length", range: 6...14, step: 0.5)]
        case .poncho:
            [Measure(key: "width", label: "Width", range: 8...24, step: 0.5)]
        case .babyCardigan:
            [Measure(key: "chest", label: "Chest", range: 14...24, step: 0.5), Measure(key: "body", label: "Body Length", range: 4...12, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 4...12, step: 0.5)]
        case .keyholeScarf:
            [Measure(key: "width", label: "Width", range: 3...9, step: 0.5), Measure(key: "length", label: "Length", range: 20...50, step: 1)]
        case .slippers, .babyBooties:
            [Measure(key: "foot", label: "Foot", range: 3.5...12, step: 0.25), Measure(key: "footLength", label: "Foot Length", range: 3...13, step: 0.25)]
        case .cuffDownSocks, .toeUpSocks:
            [Measure(key: "foot", label: "Foot", range: 5...12, step: 0.25), Measure(key: "footLength", label: "Foot Length", range: 4...13, step: 0.25), Measure(key: "leg", label: "Leg Length", range: 2...12, step: 0.5)]
        case .mittens:
            [Measure(key: "hand", label: "Hand", range: 4.5...10.5, step: 0.25), Measure(key: "handLength", label: "Hand Length", range: 3.5...9.5, step: 0.25)]
        case .rectangularWrap:
            [Measure(key: "width", label: "Width", range: 12...30, step: 1), Measure(key: "length", label: "Length", range: 48...90, step: 2)]
        case .marketBag:
            [Measure(key: "width", label: "Width", range: 9...20, step: 0.5), Measure(key: "height", label: "Height", range: 8...20, step: 0.5), Measure(key: "handle", label: "Handle Length", range: 8...30, step: 1)]
        case .pillowCover:
            [Measure(key: "side", label: "Side", range: 10...26, step: 1)]
        }
    }

    var sizes: [NamedSize] {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .earflapHat, .cabledBeanie, .pompomBonnet, .topDownBeanie:
            [("Baby", 16), ("Toddler", 18), ("Child", 20), ("Small", 21), ("Medium", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1]) }
        case .garterScarf, .ribbedScarf, .seedScarf:
            [NamedSize(name: "Child", values: ["width": 5, "length": 48]), NamedSize(name: "Classic", values: ["width": 7, "length": 64]), NamedSize(name: "Long", values: ["width": 8, "length": 76])]
        case .ribbedCowl, .seedCowl, .chunkyCowl:
            [NamedSize(name: "Snug", values: ["around": 22, "height": 8]), NamedSize(name: "Classic", values: ["around": 26, "height": 10]), NamedSize(name: "Infinity", values: ["around": 52, "height": 9])]
        case .borderedBlanket, .garterBlanket, .basketweaveBlanket:
            [NamedSize(name: "Stroller", values: ["width": 30, "length": 35]), NamedSize(name: "Crib", values: ["width": 36, "length": 45]), NamedSize(name: "Throw", values: ["width": 48, "length": 60])]
        case .dishcloth:
            [("Small", 7), ("Classic", 8.5), ("Large", 10)].map { NamedSize(name: $0.0, values: ["side": $0.1]) }
        case .twistedHeadband:
            [("Child", 20), ("Adult", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1, "width": 4]) }
        case .earWarmer, .cableHeadband:
            [("Child", 20), ("Adult", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1, "width": 3.5]) }
        case .fingerlessMitts:
            [("Child", 6), ("Small", 6.5), ("Medium", 7.5), ("Large", 8.5)].map { NamedSize(name: $0.0, values: ["hand": $0.1]) }
        case .handwarmers:
            [("Small", 6.5), ("Medium", 7.5), ("Large", 8.5)].map { NamedSize(name: $0.0, values: ["hand": $0.1]) }
        case .legWarmers:
            [NamedSize(name: "Child", values: ["calf": 10, "length": 10]), NamedSize(name: "Adult", values: ["calf": 14, "length": 14]), NamedSize(name: "Wide", values: ["calf": 17, "length": 14])]
        case .triangleShawl, .crescentShawl:
            [("Shawlette", 44), ("Classic", 60), ("Wrap", 72)].map { NamedSize(name: $0.0, values: ["wingspan": $0.1]) }
        case .neckScarf:
            [NamedSize(name: "Small", values: ["length": 36, "width": 4.5]), NamedSize(name: "Classic", values: ["length": 42, "width": 5.5]), NamedSize(name: "Long", values: ["length": 50, "width": 6.5])]
        case .balaclava, .beret:
            [("Child", 20), ("Small", 21), ("Medium", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1]) }
        case .raglanPullover, .raglanCardigan, .dropShoulder:
            [("XS", 30, 14, 17), ("S", 34, 14.5, 17.5), ("M", 38, 15, 18), ("L", 42, 15.5, 18.5), ("XL", 46, 16, 19), ("2X", 50, 16.5, 19), ("3X", 54, 17, 19.5), ("4X", 58, 17, 19.5), ("5X", 62, 17.5, 20)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        case .sweaterVest:
            [("XS", 30, 14), ("S", 34, 14.5), ("M", 38, 15), ("L", 42, 15.5), ("XL", 46, 16), ("2X", 50, 16.5), ("3X", 54, 17), ("4X", 58, 17), ("5X", 62, 17.5)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2]) }
        // Craft Yarn Council child chest and sleeve-to-underarm lengths; the body runs from the underarm to the hem.
        case .kidsRaglan:
            [("2T", 21, 8.5, 8.5), ("4", 23, 9.5, 10.5), ("6", 25, 10.5, 11.5), ("8", 26.5, 11.5, 12.5), ("10", 28, 12, 13.5), ("12", 30, 12.5, 15)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        case .christmasStocking:
            [("Small", 14, 9, 7.5), ("Classic", 18, 12, 9), ("Large", 22, 15, 11)].map { NamedSize(name: $0.0, values: ["around": $0.1, "leg": $0.2, "footLength": $0.3]) }
        // Each panel's width: the poncho hangs about 1.4 times that from the neck.
        case .poncho:
            [("Child", 11), ("Small", 15), ("Medium", 17), ("Large", 19)].map { NamedSize(name: $0.0, values: ["width": $0.1]) }
        // Craft Yarn Council baby chest and sleeve lengths; the body runs from the underarm to the hem.
        case .babyCardigan:
            [("3 Months", 16, 6, 6), ("6 Months", 17, 6.5, 6.5), ("12 Months", 18, 7.5, 7.5), ("18 Months", 19, 8, 8), ("24 Months", 20, 8.5, 8.5)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        case .keyholeScarf:
            [NamedSize(name: "Child", values: ["width": 4, "length": 26]), NamedSize(name: "Classic", values: ["width": 5, "length": 34]), NamedSize(name: "Long", values: ["width": 6, "length": 42])]
        case .slippers:
            [("Child", 6.5, 7), ("Small", 7.5, 9), ("Medium", 8, 9.5), ("Large", 9, 10.5), ("Extra Large", 9.5, 11.5)]
                .map { NamedSize(name: $0.0, values: ["foot": $0.1, "footLength": $0.2]) }
        // Foot around and long, birth to about two.
        case .babyBooties:
            [("Newborn", 3.75, 3.25), ("Baby", 4.25, 4), ("Toddler", 5, 4.75)]
                .map { NamedSize(name: $0.0, values: ["foot": $0.1, "footLength": $0.2]) }
        case .cuffDownSocks, .toeUpSocks:
            [("Child", 6.5, 7, 4), ("Small", 7.5, 9, 6), ("Medium", 8, 9.5, 6.5), ("Large", 9, 10.5, 7)]
                .map { NamedSize(name: $0.0, values: ["foot": $0.1, "footLength": $0.2, "leg": $0.3]) }
        case .mittens:
            [("Toddler", 5, 4.25), ("Child", 6, 5.5), ("Small", 7, 6.75), ("Medium", 7.5, 7.25), ("Large", 8.5, 8)]
                .map { NamedSize(name: $0.0, values: ["hand": $0.1, "handLength": $0.2]) }
        case .rectangularWrap:
            [NamedSize(name: "Small", values: ["width": 16, "length": 60]), NamedSize(name: "Classic", values: ["width": 20, "length": 72]), NamedSize(name: "Wide", values: ["width": 24, "length": 80])]
        case .marketBag:
            [NamedSize(name: "Small", values: ["width": 11, "height": 11, "handle": 14]), NamedSize(name: "Medium", values: ["width": 13, "height": 13, "handle": 20]), NamedSize(name: "Large", values: ["width": 15, "height": 15, "handle": 24])]
        case .pillowCover:
            [("Small", 14), ("Medium", 16), ("Large", 18), ("Extra Large", 20)].map { NamedSize(name: $0.0, values: ["side": $0.1]) }
        }
    }

    /// Inches a pullover is knit larger than the chest it is for: a classic, easy fit.
    static let sweaterEase = 3.0

    /// A drop-shoulder sweater is roomy by design: its shoulders sit down the arm.
    static let dropEase = 8.0

    /// The size a new knitter most likely wants.
    var defaultSize: NamedSize {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .earflapHat, .cabledBeanie, .pompomBonnet, .topDownBeanie: sizes[4]
        case .raglanPullover, .raglanCardigan, .sweaterVest, .kidsRaglan, .balaclava, .cuffDownSocks, .beret, .dropShoulder, .slippers, .toeUpSocks: sizes[2]
        case .mittens: sizes[3]
        case .fingerlessMitts, .babyCardigan, .poncho: sizes[2]
        default: sizes[1]
        }
    }

    /// Rows to the inch of the design's main fabric: garter packs two rows into each ridge.
    func rowsPerInch(_ g: Gauge) -> Double {
        switch self {
        case .garterScarf, .garterBlanket, .chunkyCowl, .keyholeScarf, .slippers, .babyBooties, .twistedHeadband: g.spi * 2
        case .seedScarf, .seedCowl: g.rpi * 1.1
        default: g.rpi
        }
    }

    var isGarter: Bool { [.garterScarf, .garterBlanket, .chunkyCowl, .keyholeScarf, .slippers, .babyBooties, .twistedHeadband].contains(self) }

    func plan(measures: [String: Double], gauge: Gauge, fit: Engines.Fit = .plain) -> PatternPlan {
        var values = defaultSize.values
        for measure in self.measures {
            if let given = measures[measure.key] { values[measure.key] = min(max(given, measure.range.lowerBound), measure.range.upperBound) }
        }
        func value(_ key: String) -> Double { values[key] ?? 0 }
        switch self {
        case .ribbedBeanie: return Engines.hat(.ribbed, head: value("head"), gauge: gauge, fit: fit)
        case .slouchHat: return Engines.hat(.slouch, head: value("head"), gauge: gauge, fit: fit)
        case .rolledBrimHat: return Engines.hat(.rolled, head: value("head"), gauge: gauge, fit: fit)
        case .garterScarf: return Engines.scarf(.garter, width: value("width"), length: value("length"), gauge: gauge, fit: fit)
        case .ribbedScarf: return Engines.scarf(.rib, width: value("width"), length: value("length"), gauge: gauge, fit: fit)
        case .seedScarf: return Engines.scarf(.seed, width: value("width"), length: value("length"), gauge: gauge, fit: fit)
        case .ribbedCowl: return Engines.cowl(.rib, around: value("around"), height: value("height"), gauge: gauge, fit: fit)
        case .seedCowl: return Engines.cowl(.seed, around: value("around"), height: value("height"), gauge: gauge, fit: fit)
        case .borderedBlanket: return Engines.blanket(bordered: true, width: value("width"), length: value("length"), gauge: gauge, fit: fit)
        case .garterBlanket: return Engines.blanket(bordered: false, width: value("width"), length: value("length"), gauge: gauge, fit: fit)
        case .dishcloth: return Engines.dishcloth(side: value("side"), gauge: gauge)
        case .earWarmer: return Engines.earWarmer(head: value("head"), width: value("width"), gauge: gauge, fit: fit)
        case .handwarmers: return Engines.handwarmers(hand: value("hand"), gauge: gauge, fit: fit)
        case .legWarmers: return Engines.legWarmers(calf: value("calf"), length: value("length"), gauge: gauge)
        case .triangleShawl: return Engines.shawl(wingspan: value("wingspan"), gauge: gauge)
        case .chunkyCowl: return Engines.cowl(.garter, around: value("around"), height: value("height"), gauge: gauge, fit: fit)
        case .neckScarf: return Engines.neckScarf(length: value("length"), width: value("width"), gauge: gauge)
        case .cableHeadband: return Engines.cableHeadband(head: value("head"), width: value("width"), gauge: gauge)
        case .balaclava: return Engines.balaclava(head: value("head"), gauge: gauge)
        // The chest a knitter measures is the body: the sweater is knit with room to wear over it.
        case .raglanPullover: return Engines.raglan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge).plan
        case .raglanCardigan: return Engines.cardigan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge).plan
        case .sweaterVest: return Engines.vest(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), gauge: gauge).plan
        case .kidsRaglan: return Engines.raglan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge, child: true).plan
        case .cuffDownSocks: return Engines.socks(foot: value("foot"), length: value("footLength"), leg: value("leg"), gauge: gauge).plan
        case .mittens: return Engines.mittens(hand: value("hand"), length: value("handLength"), gauge: gauge).plan
        case .earflapHat: return Engines.earflapHat(head: value("head"), gauge: gauge)
        case .cabledBeanie: return Engines.cabledBeanie(head: value("head"), gauge: gauge).plan
        case .basketweaveBlanket: return Engines.basketweave(width: value("width"), length: value("length"), gauge: gauge)
        case .rectangularWrap: return Engines.wrap(width: value("width"), length: value("length"), gauge: gauge)
        case .crescentShawl: return Engines.crescent(wingspan: value("wingspan"), gauge: gauge)
        case .marketBag: return Engines.marketBag(width: value("width"), height: value("height"), handle: value("handle"), gauge: gauge)
        case .pillowCover: return Engines.pillow(side: value("side"), gauge: gauge).plan
        case .pompomBonnet: return Engines.bonnet(head: value("head"), gauge: gauge)
        case .beret: return Engines.beret(head: value("head"), gauge: gauge)
        case .dropShoulder: return Engines.dropShoulder(chest: value("chest") + Self.dropEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge)
        case .keyholeScarf: return Engines.keyholeScarf(width: value("width"), length: value("length"), gauge: gauge)
        case .slippers: return Engines.slipper(foot: value("foot"), length: value("footLength"), gauge: gauge, bootie: false)
        case .babyBooties: return Engines.slipper(foot: value("foot"), length: value("footLength"), gauge: gauge, bootie: true)
        case .christmasStocking: return Engines.socks(foot: value("around"), length: value("footLength"), leg: value("leg"), gauge: gauge, stocking: true).plan
        case .poncho: return Engines.poncho(width: value("width"), gauge: gauge)
        case .twistedHeadband: return Engines.twistedHeadband(head: value("head"), width: value("width"), gauge: gauge)
        case .topDownBeanie: return Engines.topDownBeanie(head: value("head"), gauge: gauge).plan
        case .babyCardigan: return Engines.cardigan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge, baby: true).plan
        case .fingerlessMitts: return Engines.fingerlessMitts(hand: value("hand"), gauge: gauge).plan
        case .toeUpSocks: return Engines.toeUpSocks(foot: value("foot"), length: value("footLength"), leg: value("leg"), gauge: gauge).plan
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
        case 32...: 2.25
        case 30..<32: 2.75
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
