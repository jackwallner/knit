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
    case washcloth, knotHat, asymmetricShawl, bandanaCowl, armWarmers, watchCap, hoodedScarf, coasters, babyMittens, catHat, teaCozy, bootCuffs, kidsCardigan, babySocks, mugCozy, capelet, placemat, miniStocking, raglanTee, pouch, bottleCover, bandanaKerchief, turtleneck, shrug, gloves, yokeSweater, tankTop, croppedCardigan, babyPullover, bucketHat, toteBag, babyCocoon, tubeSocks, knitBasket, kidsVest

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
        case toeUp, topDown, poncho, stocking, knot, asymmetric, bandana, sleeves, watch, hoodedScarf, coasters, babyMittens, catHat, teaCozy, bootCuffs, mugCozy, capelet, placemat, tee, pouch, bottleCover, tieKerchief, turtleneck, shrug, gloves, yoke, tank, cropped, babyPullover, bucket, tote, cocoon, tubeSock, basket
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
        case .raglanTee: "Short-Sleeve Raglan Tee"
        case .turtleneck: "Turtleneck Pullover"
        case .chunkyCowl: "Chunky Cowl"
        case .neckScarf: "Neck Scarf"
        case .cableHeadband: "Cabled Headband"
        case .balaclava: "Balaclava"
        case .cuffDownSocks: "Cuff-Down Socks"
        case .mittens: "Mittens"
        case .raglanCardigan: "Raglan Cardigan"
        case .sweaterVest: "Sweater Vest"
        case .kidsRaglan: "Kids' Raglan"
        case .kidsCardigan: "Kids' Cardigan"
        case .kidsVest: "Kids' Vest"
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
        case .babySocks: "Baby Socks"
        case .fingerlessMitts: "Fingerless Mitts"
        case .babyCardigan: "Baby Cardigan"
        case .topDownBeanie: "Top-Down Beanie"
        case .twistedHeadband: "Twisted Headband"
        case .poncho: "Poncho"
        case .christmasStocking: "Christmas Stocking"
        case .miniStocking: "Mini Stocking Ornament"
        case .washcloth: "Bordered Washcloth"
        case .knotHat: "Baby Knot Hat"
        case .asymmetricShawl: "Asymmetric Shawl"
        case .bandanaCowl: "Bandana Cowl"
        case .armWarmers: "Arm Warmers"
        case .watchCap: "Watch Cap"
        case .catHat: "Cat Ear Hat"
        case .hoodedScarf: "Hooded Scarf"
        case .capelet: "Capelet"
        case .shrug: "Shrug"
        case .gloves: "Gloves"
        case .yokeSweater: "Yoke Sweater"
        case .tankTop: "Tank Top"
        case .croppedCardigan: "Cropped Cardigan"
        case .babyPullover: "Baby Pullover"
        case .bucketHat: "Bucket Hat"
        case .toteBag: "Tote Bag"
        case .babyCocoon: "Baby Cocoon"
        case .tubeSocks: "Tube Socks"
        case .knitBasket: "Knit Basket"
        case .coasters: "Coasters"
        case .placemat: "Placemat"
        case .pouch: "Drawstring Pouch"
        case .bandanaKerchief: "Bandana Kerchief"
        case .bottleCover: "Hot Water Bottle Cover"
        case .mugCozy: "Mug Cozy"
        case .bootCuffs: "Boot Cuffs"
        case .teaCozy: "Tea Cozy"
        case .babyMittens: "Baby Mittens"
        }
    }

    /// English words a search should find the design by beyond its name: "christmas" searches as "holiday".
    var searchWords: String {
        switch self {
        case .christmasStocking: "holiday"
        case .miniStocking: "holiday tree"
        case .washcloth: "dishcloth facecloth"
        case .raglanTee: "t-shirt top summer"
        case .turtleneck: "roll neck polo neck jumper"
        case .pouch: "bag sack"
        case .bottleCover: "cosy cozy"
        case .bandanaKerchief: "headscarf head scarf triangle"
        case .shrug: "bolero cropped cardigan"
        case .gloves: "glove fingers five finger winter"
        case .yokeSweater: "round yoke circular yoke pullover jumper ridges"
        case .tankTop: "tank top sleeveless summer camisole shell scoop neck"
        case .croppedCardigan: "cropped short boxy v-neck v neck buttons three-quarter sleeve"
        case .babyPullover: "baby sweater jumper infant shoulder buttons"
        case .bucketHat: "bucket hat brim sun fisherman"
        case .toteBag: "tote bag shopping book beach carryall purse"
        case .babyCocoon: "baby cocoon newborn photo prop sack swaddle sleep"
        case .tubeSocks: "tube socks spiral heelless no heel easy"
        case .knitBasket: "basket storage bin bowl organizer"
        case .kidsVest: "kids child children vest sleeveless v-neck school"
        default: ""
        }
    }

    /// The name in the knitter's language. `name` stays English, as the tests and saved plans know it.
    var title: String { Loc.text(name) }

    var shelf: Shelf {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .balaclava, .earflapHat, .cabledBeanie, .pompomBonnet, .beret, .topDownBeanie, .knotHat, .watchCap, .catHat, .bucketHat: .hats
        case .garterScarf, .ribbedScarf, .seedScarf, .ribbedCowl, .seedCowl, .chunkyCowl, .neckScarf, .rectangularWrap, .keyholeScarf, .poncho, .bandanaCowl, .capelet, .hoodedScarf, .bandanaKerchief, .triangleShawl, .crescentShawl, .asymmetricShawl: .scarves
        case .borderedBlanket, .garterBlanket, .dishcloth, .basketweaveBlanket, .pillowCover, .marketBag, .christmasStocking, .washcloth, .coasters, .teaCozy, .mugCozy, .placemat, .miniStocking, .pouch, .bottleCover, .toteBag, .babyCocoon, .knitBasket: .home
        case .earWarmer, .handwarmers, .legWarmers, .cableHeadband, .mittens, .cuffDownSocks, .slippers, .babyBooties, .toeUpSocks, .babySocks, .fingerlessMitts, .twistedHeadband, .armWarmers, .babyMittens, .bootCuffs, .gloves, .tubeSocks: .accessories
        case .raglanPullover, .raglanCardigan, .sweaterVest, .kidsRaglan, .dropShoulder, .babyCardigan, .kidsCardigan, .raglanTee, .turtleneck, .shrug, .yokeSweater, .tankTop, .croppedCardigan, .babyPullover, .kidsVest: .sweaters
        }
    }

    var level: Level {
        switch self {
        case .garterScarf, .garterBlanket, .ribbedScarf, .seedScarf, .keyholeScarf, .slippers, .twistedHeadband, .poncho, .washcloth, .bootCuffs, .placemat, .bandanaKerchief: .beginner
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .ribbedCowl, .seedCowl, .borderedBlanket, .earWarmer, .legWarmers, .triangleShawl, .chunkyCowl, .neckScarf, .dishcloth, .handwarmers: .easy
        case .earflapHat, .basketweaveBlanket, .rectangularWrap, .crescentShawl, .marketBag, .pillowCover, .mittens: .easy
        case .pompomBonnet, .beret, .dropShoulder, .babyBooties, .fingerlessMitts, .topDownBeanie, .knotHat, .asymmetricShawl, .bandanaCowl, .armWarmers, .watchCap, .coasters, .hoodedScarf, .babyMittens, .catHat, .teaCozy, .mugCozy, .capelet, .miniStocking, .pouch, .bottleCover, .shrug, .bucketHat, .toteBag, .babyCocoon, .tubeSocks, .knitBasket: .easy
        case .raglanPullover, .cableHeadband, .balaclava, .raglanTee, .turtleneck, .yokeSweater, .tankTop, .croppedCardigan, .babyPullover: .intermediate
        case .cuffDownSocks, .raglanCardigan, .sweaterVest, .kidsRaglan, .cabledBeanie, .toeUpSocks, .babyCardigan, .christmasStocking, .kidsCardigan, .babySocks, .gloves, .kidsVest: .intermediate
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
        case .dishcloth, .washcloth: .cloth
        case .earWarmer, .cableHeadband, .twistedHeadband: .band
        case .handwarmers, .fingerlessMitts: .mitts
        case .legWarmers: .tubes
        case .triangleShawl: .shawl
        case .raglanPullover, .kidsRaglan: .sweater
        case .raglanTee: .tee
        case .turtleneck: .turtleneck
        case .cuffDownSocks, .babySocks: .socks
        case .mittens: .mittens
        case .raglanCardigan, .babyCardigan, .kidsCardigan: .cardigan
        case .sweaterVest, .kidsVest: .vest
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
        case .christmasStocking, .miniStocking: .stocking
        case .knotHat: .knot
        case .asymmetricShawl: .asymmetric
        case .bandanaCowl: .bandana
        case .armWarmers: .sleeves
        case .watchCap: .watch
        case .catHat: .catHat
        case .hoodedScarf: .hoodedScarf
        case .capelet: .capelet
        case .shrug: .shrug
        case .gloves: .gloves
        case .yokeSweater: .yoke
        case .tankTop: .tank
        case .croppedCardigan: .cropped
        case .babyPullover: .babyPullover
        case .bucketHat: .bucket
        case .toteBag: .tote
        case .babyCocoon: .cocoon
        case .tubeSocks: .tubeSock
        case .knitBasket: .basket
        case .coasters: .coasters
        case .placemat: .placemat
        case .pouch: .pouch
        case .bandanaKerchief: .tieKerchief
        case .bottleCover: .bottleCover
        case .mugCozy: .mugCozy
        case .bootCuffs: .bootCuffs
        case .teaCozy: .teaCozy
        case .babyMittens: .babyMittens
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
        case .kidsCardigan: .indigo
        case .kidsVest: .spruce
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
        case .babySocks: .marigold
        case .fingerlessMitts: .charcoal
        case .babyCardigan: .moss
        case .topDownBeanie: .indigo
        case .twistedHeadband: .plum
        case .poncho: .oat
        case .christmasStocking: .madder
        case .miniStocking: .spruce
        case .raglanTee: .moss
        case .turtleneck: .charcoal
        case .washcloth: .indigo
        case .knotHat: .marigold
        case .asymmetricShawl: .plum
        case .bandanaCowl: .madder
        case .armWarmers: .charcoal
        case .watchCap: .spruce
        case .catHat: .charcoal
        case .hoodedScarf: .oat
        case .capelet: .moss
        case .shrug: .plum
        case .gloves: .madder
        case .yokeSweater: .oat
        case .tankTop: .marigold
        case .croppedCardigan: .plum
        case .babyPullover: .spruce
        case .bucketHat: .moss
        case .toteBag: .indigo
        case .babyCocoon: .oat
        case .tubeSocks: .madder
        case .knitBasket: .charcoal
        case .coasters: .madder
        case .placemat: .oat
        case .pouch: .madder
        case .bandanaKerchief: .marigold
        case .bottleCover: .oat
        case .mugCozy: .spruce
        case .bootCuffs: .oat
        case .teaCozy: .plum
        case .babyMittens: .moss
        }
    }

    /// The gauge this design is knit at in a yarn weight. Socks are knit firmer than the label so they wear well.
    func gauge(for weight: YarnWeight) -> Gauge {
        if [.cuffDownSocks, .toeUpSocks, .babySocks].contains(self), weight == .fingering { return Gauge(stitches: 32, rows: 44) }
        return weight.gauge
    }

    var weight: YarnWeight {
        switch self {
        case .triangleShawl, .neckScarf, .sweaterVest, .rectangularWrap, .beret, .babyBooties, .babyCardigan, .asymmetricShawl, .raglanTee, .bandanaKerchief, .gloves, .tankTop, .babyPullover, .tubeSocks, .kidsVest: .dk
        case .garterBlanket, .slouchHat, .cableHeadband, .cabledBeanie, .keyholeScarf, .slippers: .aran
        case .cuffDownSocks, .crescentShawl, .toeUpSocks, .babySocks: .fingering
        // Chunky is #5 bulky to most knitters.
        case .chunkyCowl, .dropShoulder, .babyCocoon, .knitBasket: .bulky
        default: .worsted
        }
    }

    var measures: [Measure] {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .earflapHat, .cabledBeanie, .pompomBonnet, .beret, .topDownBeanie, .watchCap, .catHat:
            [Measure(key: "head", label: "Head", range: 13...26, step: 0.5)]
        case .garterScarf, .ribbedScarf, .seedScarf:
            [Measure(key: "width", label: "Width", range: 4...14, step: 0.5), Measure(key: "length", label: "Length", range: 30...90, step: 2)]
        case .ribbedCowl, .seedCowl, .chunkyCowl:
            [Measure(key: "around", label: "Around", range: 18...60, step: 1), Measure(key: "height", label: "Height", range: 5...16, step: 0.5)]
        case .borderedBlanket, .garterBlanket, .basketweaveBlanket:
            [Measure(key: "width", label: "Width", range: 20...70, step: 1), Measure(key: "length", label: "Length", range: 20...90, step: 1)]
        case .babyMittens:
            [Measure(key: "hand", label: "Hand", range: 3.75...6.5, step: 0.25), Measure(key: "handLength", label: "Hand Length", range: 2...4.5, step: 0.25)]
        case .teaCozy:
            [Measure(key: "around", label: "Around", range: 16...36, step: 1), Measure(key: "height", label: "Height", range: 4...9, step: 0.5)]
        case .bootCuffs:
            [Measure(key: "calf", label: "Calf", range: 10...20, step: 0.5), Measure(key: "height", label: "Height", range: 4...9, step: 0.5)]
        case .mugCozy:
            [Measure(key: "around", label: "Around", range: 8...15, step: 0.25), Measure(key: "height", label: "Height", range: 2...5, step: 0.25)]
        case .placemat:
            [Measure(key: "width", label: "Width", range: 9...16, step: 0.5), Measure(key: "length", label: "Length", range: 12...22, step: 0.5)]
        case .bandanaKerchief:
            [Measure(key: "width", label: "Width", range: 12...30, step: 1), Measure(key: "ties", label: "Ties", range: 6...18, step: 1)]
        case .bottleCover:
            [Measure(key: "width", label: "Width", range: 5...10, step: 0.25), Measure(key: "height", label: "Height", range: 6...14, step: 0.5)]
        case .pouch:
            [Measure(key: "width", label: "Width", range: 3...12, step: 0.5), Measure(key: "height", label: "Height", range: 3...14, step: 0.5)]
        case .coasters:
            [Measure(key: "diameter", label: "Across", range: 3.5...6, step: 0.25)]
        case .gloves:
            [Measure(key: "hand", label: "Hand", range: 6...10, step: 0.25), Measure(key: "length", label: "Length", range: 6...9, step: 0.25)]
        case .shrug:
            [Measure(key: "arm", label: "Upper Arm", range: 9...20, step: 0.5), Measure(key: "span", label: "Cuff to Cuff", range: 40...66, step: 1), Measure(key: "sleeve", label: "Sleeve Length", range: 8...20, step: 0.5)]
        case .capelet:
            [Measure(key: "chest", label: "Chest", range: 28...58, step: 1), Measure(key: "length", label: "Length", range: 8...16, step: 0.5)]
        case .hoodedScarf:
            [Measure(key: "head", label: "Head", range: 16...25, step: 0.5), Measure(key: "length", label: "Length", range: 12...40, step: 1)]
        case .armWarmers:
            [Measure(key: "wrist", label: "Wrist", range: 5...9, step: 0.25), Measure(key: "arm", label: "Arm", range: 7...16, step: 0.5), Measure(key: "length", label: "Length", range: 8...22, step: 1)]
        case .bandanaCowl:
            [Measure(key: "around", label: "Around", range: 18...30, step: 1), Measure(key: "height", label: "Height", range: 3...8, step: 0.5)]
        case .asymmetricShawl:
            [Measure(key: "wingspan", label: "Wingspan", range: 36...84, step: 2)]
        case .knotHat:
            [Measure(key: "head", label: "Head", range: 12...19, step: 0.5)]
        case .dishcloth, .washcloth:
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
        case .balaclava, .bucketHat:
            [Measure(key: "head", label: "Head", range: 17...26, step: 0.5)]
        case .raglanPullover, .raglanCardigan, .dropShoulder, .turtleneck, .yokeSweater:
            [Measure(key: "chest", label: "Chest", range: 26...62, step: 1), Measure(key: "body", label: "Body Length", range: 8...22, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 10...22, step: 0.5)]
        case .croppedCardigan:
            [Measure(key: "chest", label: "Chest", range: 26...62, step: 1), Measure(key: "body", label: "Body Length", range: 6...14, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 8...20, step: 0.5)]
        case .sweaterVest, .tankTop:
            [Measure(key: "chest", label: "Chest", range: 26...62, step: 1), Measure(key: "body", label: "Body Length", range: 8...22, step: 0.5)]
        case .raglanTee:
            [Measure(key: "chest", label: "Chest", range: 26...62, step: 1), Measure(key: "body", label: "Body Length", range: 8...22, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 2...8, step: 0.5)]
        case .kidsVest:
            [Measure(key: "chest", label: "Chest", range: 18...34, step: 0.5), Measure(key: "body", label: "Body Length", range: 5...16, step: 0.5)]
        case .kidsRaglan, .kidsCardigan:
            [Measure(key: "chest", label: "Chest", range: 18...34, step: 0.5), Measure(key: "body", label: "Body Length", range: 5...16, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 5...17, step: 0.5)]
        case .miniStocking:
            [Measure(key: "around", label: "Around", range: 4...8, step: 0.25), Measure(key: "leg", label: "Leg Length", range: 1.5...4, step: 0.25), Measure(key: "footLength", label: "Foot Length", range: 2...4.5, step: 0.25)]
        case .christmasStocking:
            [Measure(key: "around", label: "Around", range: 12...26, step: 1), Measure(key: "leg", label: "Leg Length", range: 6...20, step: 0.5), Measure(key: "footLength", label: "Foot Length", range: 6...14, step: 0.5)]
        case .poncho:
            [Measure(key: "width", label: "Width", range: 8...24, step: 0.5)]
        case .babyCardigan, .babyPullover:
            [Measure(key: "chest", label: "Chest", range: 14...24, step: 0.5), Measure(key: "body", label: "Body Length", range: 4...12, step: 0.5), Measure(key: "sleeve", label: "Sleeve Length", range: 4...12, step: 0.5)]
        case .keyholeScarf:
            [Measure(key: "width", label: "Width", range: 3...9, step: 0.5), Measure(key: "length", label: "Length", range: 20...50, step: 1)]
        case .slippers, .babyBooties:
            [Measure(key: "foot", label: "Foot", range: 3.5...12, step: 0.25), Measure(key: "footLength", label: "Foot Length", range: 3...13, step: 0.25)]
        case .babySocks:
            [Measure(key: "foot", label: "Foot", range: 3.5...6, step: 0.25), Measure(key: "footLength", label: "Foot Length", range: 3...5.5, step: 0.25), Measure(key: "leg", label: "Leg Length", range: 1...4, step: 0.25)]
        case .cuffDownSocks, .toeUpSocks:
            [Measure(key: "foot", label: "Foot", range: 5...12, step: 0.25), Measure(key: "footLength", label: "Foot Length", range: 4...13, step: 0.25), Measure(key: "leg", label: "Leg Length", range: 2...12, step: 0.5)]
        case .mittens:
            [Measure(key: "hand", label: "Hand", range: 4.5...10.5, step: 0.25), Measure(key: "handLength", label: "Hand Length", range: 3.5...9.5, step: 0.25)]
        case .rectangularWrap:
            [Measure(key: "width", label: "Width", range: 12...30, step: 1), Measure(key: "length", label: "Length", range: 48...90, step: 2)]
        case .marketBag:
            [Measure(key: "width", label: "Width", range: 9...20, step: 0.5), Measure(key: "height", label: "Height", range: 8...20, step: 0.5), Measure(key: "handle", label: "Handle Length", range: 8...30, step: 1)]
        case .babyCocoon:
            [Measure(key: "around", label: "Around", range: 14...26, step: 0.5), Measure(key: "length", label: "Length", range: 12...24, step: 0.5)]
        case .knitBasket:
            [Measure(key: "diameter", label: "Across", range: 5...14, step: 0.5), Measure(key: "height", label: "Height", range: 3...10, step: 0.5)]
        case .tubeSocks:
            [Measure(key: "foot", label: "Foot", range: 5...11, step: 0.25), Measure(key: "length", label: "Length", range: 10...26, step: 0.5)]
        case .toteBag:
            [Measure(key: "width", label: "Width", range: 10...20, step: 0.5), Measure(key: "height", label: "Height", range: 9...18, step: 0.5), Measure(key: "handle", label: "Handle Length", range: 10...30, step: 1)]
        case .pillowCover:
            [Measure(key: "side", label: "Side", range: 10...26, step: 1)]
        }
    }

    var sizes: [NamedSize] {
        switch self {
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .earflapHat, .cabledBeanie, .pompomBonnet, .topDownBeanie, .watchCap, .catHat:
            [("Baby", 16), ("Toddler", 18), ("Child", 20), ("Small", 21), ("Medium", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1]) }
        case .garterScarf, .ribbedScarf, .seedScarf:
            [NamedSize(name: "Child", values: ["width": 5, "length": 48]), NamedSize(name: "Classic", values: ["width": 7, "length": 64]), NamedSize(name: "Long", values: ["width": 8, "length": 76])]
        case .ribbedCowl, .seedCowl, .chunkyCowl:
            [NamedSize(name: "Snug", values: ["around": 22, "height": 8]), NamedSize(name: "Classic", values: ["around": 26, "height": 10]), NamedSize(name: "Infinity", values: ["around": 52, "height": 9])]
        case .borderedBlanket, .garterBlanket, .basketweaveBlanket:
            [NamedSize(name: "Stroller", values: ["width": 30, "length": 35]), NamedSize(name: "Crib", values: ["width": 36, "length": 45]), NamedSize(name: "Throw", values: ["width": 48, "length": 60])]
        case .babyMittens:
            [("Newborn", 4.25, 2.5), ("3 Months", 4.75, 2.75), ("6 Months", 5.25, 3.25), ("12 Months", 5.75, 3.75)].map { NamedSize(name: $0.0, values: ["hand": $0.1, "handLength": $0.2]) }
        case .teaCozy:
            [("Small", 20, 5), ("Classic", 26, 6), ("Large", 30, 7)].map { NamedSize(name: $0.0, values: ["around": $0.1, "height": $0.2]) }
        case .bootCuffs:
            [("Small", 12, 6), ("Medium", 14, 7), ("Large", 16, 7.5)].map { NamedSize(name: $0.0, values: ["calf": $0.1, "height": $0.2]) }
        case .mugCozy:
            [("Small", 9.5, 2.75), ("Classic", 11, 3.25), ("Large", 12.5, 3.75)].map { NamedSize(name: $0.0, values: ["around": $0.1, "height": $0.2]) }
        // Around the knuckles, and from the wrist to the tip of the middle finger.
        case .gloves:
            [("S", 7, 6.75), ("M", 7.75, 7.25), ("L", 8.5, 7.75), ("XL", 9.5, 8.25)].map { NamedSize(name: $0.0, values: ["hand": $0.1, "length": $0.2]) }
        // Upper arm, the span from cuff to cuff across the back, and each sleeve's seam.
        case .shrug:
            [("S", 11, 48, 14), ("M", 12.5, 52, 15), ("L", 14, 56, 16), ("XL", 16, 60, 17), ("2X", 18, 62, 17)].map { NamedSize(name: $0.0, values: ["arm": $0.1, "span": $0.2, "sleeve": $0.3]) }
        case .bandanaKerchief:
            [("Child", 16, 9), ("Classic", 21, 11), ("Large", 25, 13)].map { NamedSize(name: $0.0, values: ["width": $0.1, "ties": $0.2]) }
        // A hot water bottle's width laid flat and its height to the top of the shoulders.
        case .bottleCover:
            [("Small", 5.5, 7.5), ("Classic", 7.5, 10), ("Large", 8.5, 11.5)].map { NamedSize(name: $0.0, values: ["width": $0.1, "height": $0.2]) }
        case .pouch:
            [("Small", 4, 5), ("Medium", 6, 7), ("Large", 8, 10)].map { NamedSize(name: $0.0, values: ["width": $0.1, "height": $0.2]) }
        case .placemat:
            [("Small", 11, 16), ("Classic", 12, 18), ("Large", 14, 20)].map { NamedSize(name: $0.0, values: ["width": $0.1, "length": $0.2]) }
        case .coasters:
            [("Small", 4), ("Classic", 4.5), ("Large", 5)].map { NamedSize(name: $0.0, values: ["diameter": $0.1]) }
        case .capelet:
            [("Small", 32, 10), ("Medium", 38, 11), ("Large", 44, 12), ("Extra Large", 50, 12.5)].map { NamedSize(name: $0.0, values: ["chest": $0.1, "length": $0.2]) }
        case .hoodedScarf:
            [("Child", 20, 18), ("Adult", 22, 24), ("Large", 23.5, 28)].map { NamedSize(name: $0.0, values: ["head": $0.1, "length": $0.2]) }
        case .armWarmers:
            [("Small", 6, 9.5, 14), ("Medium", 6.5, 10.5, 16), ("Large", 7.5, 12, 18)].map { NamedSize(name: $0.0, values: ["wrist": $0.1, "arm": $0.2, "length": $0.3]) }
        case .bandanaCowl:
            [NamedSize(name: "Child", values: ["around": 20, "height": 4]), NamedSize(name: "Adult", values: ["around": 23, "height": 5]), NamedSize(name: "Large", values: ["around": 26, "height": 5.5])]
        case .asymmetricShawl:
            [("Small", 48), ("Classic", 60), ("Large", 72)].map { NamedSize(name: $0.0, values: ["wingspan": $0.1]) }
        case .knotHat:
            [("Newborn", 13.5), ("3 Months", 14.5), ("6 Months", 16), ("12 Months", 17)].map { NamedSize(name: $0.0, values: ["head": $0.1]) }
        case .dishcloth, .washcloth:
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
        case .balaclava, .beret, .bucketHat:
            [("Child", 20), ("Small", 21), ("Medium", 22), ("Large", 23.5)].map { NamedSize(name: $0.0, values: ["head": $0.1]) }
        case .raglanPullover, .raglanCardigan, .dropShoulder, .turtleneck, .yokeSweater:
            [("XS", 30, 14, 17), ("S", 34, 14.5, 17.5), ("M", 38, 15, 18), ("L", 42, 15.5, 18.5), ("XL", 46, 16, 19), ("2X", 50, 16.5, 19), ("3X", 54, 17, 19.5), ("4X", 58, 17, 19.5), ("5X", 62, 17.5, 20)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        case .croppedCardigan:
            [("XS", 30, 8.5, 11.5), ("S", 34, 9, 12), ("M", 38, 9, 12.5), ("L", 42, 9.5, 13), ("XL", 46, 10, 13), ("2X", 50, 10, 13.5), ("3X", 54, 10.5, 13.5), ("4X", 58, 10.5, 14), ("5X", 62, 11, 14)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        case .tankTop:
            [("XS", 30, 13), ("S", 34, 13.5), ("M", 38, 14), ("L", 42, 14.5), ("XL", 46, 15), ("2X", 50, 15.5), ("3X", 54, 16), ("4X", 58, 16), ("5X", 62, 16.5)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2]) }
        case .raglanTee:
            [("XS", 30, 13, 3.5), ("S", 34, 13.5, 4), ("M", 38, 14, 4), ("L", 42, 14.5, 4.5), ("XL", 46, 15, 4.5), ("2X", 50, 15.5, 5), ("3X", 54, 16, 5), ("4X", 58, 16, 5.5), ("5X", 62, 16.5, 5.5)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        case .sweaterVest:
            [("XS", 30, 14), ("S", 34, 14.5), ("M", 38, 15), ("L", 42, 15.5), ("XL", 46, 16), ("2X", 50, 16.5), ("3X", 54, 17), ("4X", 58, 17), ("5X", 62, 17.5)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2]) }
        // Craft Yarn Council child chest and sleeve-to-underarm lengths; the body runs from the underarm to the hem.
        case .kidsVest:
            [("2T", 21, 8.5), ("4", 23, 9.5), ("6", 25, 10.5), ("8", 26.5, 11.5), ("10", 28, 12), ("12", 30, 12.5)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2]) }
        case .kidsRaglan, .kidsCardigan:
            [("2T", 21, 8.5, 8.5), ("4", 23, 9.5, 10.5), ("6", 25, 10.5, 11.5), ("8", 26.5, 11.5, 12.5), ("10", 28, 12, 13.5), ("12", 30, 12.5, 15)]
                .map { NamedSize(name: $0.0, values: ["chest": $0.1, "body": $0.2, "sleeve": $0.3]) }
        case .miniStocking:
            [("Small", 4.5, 2, 2.5), ("Classic", 5.5, 2.5, 3), ("Large", 6.5, 3, 3.5)].map { NamedSize(name: $0.0, values: ["around": $0.1, "leg": $0.2, "footLength": $0.3]) }
        case .christmasStocking:
            [("Small", 14, 9, 7.5), ("Classic", 18, 12, 9), ("Large", 22, 15, 11)].map { NamedSize(name: $0.0, values: ["around": $0.1, "leg": $0.2, "footLength": $0.3]) }
        // Each panel's width: the poncho hangs about 1.4 times that from the neck.
        case .poncho:
            [("Child", 11), ("Small", 15), ("Medium", 17), ("Large", 19)].map { NamedSize(name: $0.0, values: ["width": $0.1]) }
        // Craft Yarn Council baby chest and sleeve lengths; the body runs from the underarm to the hem.
        case .babyCardigan, .babyPullover:
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
        case .babySocks:
            [("Newborn", 4, 3.5, 2), ("3 Months", 4.25, 3.75, 2), ("6 Months", 4.5, 4.25, 2.25), ("12 Months", 5, 4.75, 2.5)]
                .map { NamedSize(name: $0.0, values: ["foot": $0.1, "footLength": $0.2, "leg": $0.3]) }
        case .cuffDownSocks, .toeUpSocks:
            [("Child", 6.5, 7, 4), ("Small", 7.5, 9, 6), ("Medium", 8, 9.5, 6.5), ("Large", 9, 10.5, 7)]
                .map { NamedSize(name: $0.0, values: ["foot": $0.1, "footLength": $0.2, "leg": $0.3]) }
        case .mittens:
            [("Toddler", 5, 4.25), ("Child", 6, 5.5), ("Small", 7, 6.75), ("Medium", 7.5, 7.25), ("Large", 8.5, 8)]
                .map { NamedSize(name: $0.0, values: ["hand": $0.1, "handLength": $0.2]) }
        case .rectangularWrap:
            [NamedSize(name: "Small", values: ["width": 16, "length": 60]), NamedSize(name: "Classic", values: ["width": 20, "length": 72]), NamedSize(name: "Wide", values: ["width": 24, "length": 80])]
        case .babyCocoon:
            [("Newborn", 18, 17), ("3 Months", 20, 20)].map { NamedSize(name: $0.0, values: ["around": $0.1, "length": $0.2]) }
        case .knitBasket:
            [("Small", 6, 4), ("Medium", 8, 6), ("Large", 10, 7)].map { NamedSize(name: $0.0, values: ["diameter": $0.1, "height": $0.2]) }
        case .tubeSocks:
            [("Child", 6, 14), ("Small", 7.5, 18), ("Medium", 8.5, 20), ("Large", 9.5, 22)].map { NamedSize(name: $0.0, values: ["foot": $0.1, "length": $0.2]) }
        case .toteBag:
            [("Small", 12, 11, 16), ("Medium", 14, 13, 22), ("Large", 16, 15, 24)].map { NamedSize(name: $0.0, values: ["width": $0.1, "height": $0.2, "handle": $0.3]) }
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
        case .ribbedBeanie, .slouchHat, .rolledBrimHat, .earflapHat, .cabledBeanie, .pompomBonnet, .topDownBeanie, .watchCap, .catHat: sizes[4]
        case .raglanPullover, .raglanCardigan, .sweaterVest, .kidsRaglan, .kidsCardigan, .kidsVest, .raglanTee, .turtleneck, .yokeSweater, .tankTop, .croppedCardigan, .balaclava, .bucketHat, .cuffDownSocks, .beret, .dropShoulder, .slippers, .toeUpSocks: sizes[2]
        case .mittens: sizes[3]
        case .babyCocoon: sizes[0]
        case .tubeSocks: sizes[2]
        case .fingerlessMitts, .babyCardigan, .babyPullover, .poncho: sizes[2]
        case .knotHat, .asymmetricShawl, .bandanaCowl, .armWarmers, .hoodedScarf, .coasters, .babyMittens, .teaCozy, .bootCuffs, .babySocks, .mugCozy, .capelet, .placemat, .miniStocking, .pouch, .bottleCover, .bandanaKerchief, .shrug, .toteBag: sizes[1]
        default: sizes[1]
        }
    }

    /// Rows to the inch of the design's main fabric: garter packs two rows into each ridge.
    func rowsPerInch(_ g: Gauge) -> Double {
        switch self {
        case .garterScarf, .garterBlanket, .chunkyCowl, .keyholeScarf, .slippers, .babyBooties, .twistedHeadband, .asymmetricShawl, .hoodedScarf, .bandanaKerchief: g.spi * 2
        case .seedScarf, .seedCowl: g.rpi * 1.1
        default: g.rpi
        }
    }

    var isGarter: Bool { [.garterScarf, .garterBlanket, .chunkyCowl, .keyholeScarf, .slippers, .babyBooties, .twistedHeadband, .asymmetricShawl, .hoodedScarf, .bandanaKerchief].contains(self) }

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
        case .babyMittens: return Engines.babyMittens(hand: value("hand"), length: value("handLength"), gauge: gauge)
        case .teaCozy: return Engines.teaCozy(around: value("around"), height: value("height"), gauge: gauge)
        case .bootCuffs: return Engines.bootCuff(calf: value("calf"), height: value("height"), gauge: gauge)
        case .mugCozy: return Engines.mugCozy(around: value("around"), height: value("height"), gauge: gauge)
        case .bandanaKerchief: return Engines.bandanaKerchief(width: value("width"), ties: value("ties"), gauge: gauge)
        case .bottleCover: return Engines.bottleCover(width: value("width"), height: value("height"), gauge: gauge)
        case .pouch: return Engines.pouch(width: value("width"), height: value("height"), gauge: gauge)
        case .placemat: return Engines.placemat(width: value("width"), length: value("length"), gauge: gauge)
        case .coasters: return Engines.coaster(diameter: value("diameter"), gauge: gauge)
        case .croppedCardigan: return Engines.croppedCardigan(chest: value("chest") + 5, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge).plan
        case .tankTop: return Engines.tank(chest: value("chest") + 2, wearer: value("chest"), body: value("body"), gauge: gauge).plan
        case .yokeSweater: return Engines.yokeSweater(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge).plan
        case .gloves: return Engines.gloves(hand: value("hand"), length: value("length"), gauge: gauge)
        case .shrug: return Engines.shrug(arm: value("arm"), span: value("span"), sleeve: value("sleeve"), gauge: gauge)
        case .capelet: return Engines.capelet(chest: value("chest"), length: value("length"), gauge: gauge)
        case .hoodedScarf: return Engines.hoodedScarf(head: value("head"), length: value("length"), gauge: gauge).plan
        case .catHat: return Engines.catHat(head: value("head"), gauge: gauge)
        case .watchCap: return Engines.watchCap(head: value("head"), gauge: gauge)
        case .armWarmers: return Engines.armWarmers(wrist: value("wrist"), arm: value("arm"), length: value("length"), gauge: gauge).plan
        case .bandanaCowl: return Engines.bandanaCowl(around: value("around"), height: value("height"), gauge: gauge).plan
        case .asymmetricShawl: return Engines.asymmetricShawl(wingspan: value("wingspan"), gauge: gauge)
        case .knotHat: return Engines.knotHat(head: value("head"), gauge: gauge).plan
        case .washcloth: return Engines.washcloth(side: value("side"), gauge: gauge, fit: fit)
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
        case .turtleneck: return Engines.raglan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge, collar: 7).plan
        case .raglanTee: return Engines.raglan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge, short: true).plan
        case .raglanCardigan: return Engines.cardigan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge).plan
        case .kidsVest: return Engines.vest(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), gauge: gauge, child: true).plan
        case .sweaterVest: return Engines.vest(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), gauge: gauge).plan
        case .kidsCardigan: return Engines.cardigan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge, child: true).plan
        case .kidsRaglan: return Engines.raglan(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge, child: true).plan
        case .babySocks:
            return Engines.socks(foot: value("foot"), length: value("footLength"), leg: value("leg"), gauge: gauge).plan
        case .cuffDownSocks: return Engines.socks(foot: value("foot"), length: value("footLength"), leg: value("leg"), gauge: gauge).plan
        case .mittens: return Engines.mittens(hand: value("hand"), length: value("handLength"), gauge: gauge).plan
        case .earflapHat: return Engines.earflapHat(head: value("head"), gauge: gauge)
        case .cabledBeanie: return Engines.cabledBeanie(head: value("head"), gauge: gauge).plan
        case .basketweaveBlanket: return Engines.basketweave(width: value("width"), length: value("length"), gauge: gauge)
        case .rectangularWrap: return Engines.wrap(width: value("width"), length: value("length"), gauge: gauge, fit: fit)
        case .crescentShawl: return Engines.crescent(wingspan: value("wingspan"), gauge: gauge)
        case .marketBag: return Engines.marketBag(width: value("width"), height: value("height"), handle: value("handle"), gauge: gauge)
        case .pillowCover: return Engines.pillow(side: value("side"), gauge: gauge).plan
        case .pompomBonnet: return Engines.bonnet(head: value("head"), gauge: gauge)
        case .beret: return Engines.beret(head: value("head"), gauge: gauge)
        case .dropShoulder: return Engines.dropShoulder(chest: value("chest") + Self.dropEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge)
        case .keyholeScarf: return Engines.keyholeScarf(width: value("width"), length: value("length"), gauge: gauge)
        case .slippers: return Engines.slipper(foot: value("foot"), length: value("footLength"), gauge: gauge, bootie: false)
        case .babyBooties: return Engines.slipper(foot: value("foot"), length: value("footLength"), gauge: gauge, bootie: true)
        case .miniStocking: return Engines.socks(foot: value("around"), length: value("footLength"), leg: value("leg"), gauge: gauge, stocking: true, loop: 8).plan
        case .christmasStocking: return Engines.socks(foot: value("around"), length: value("footLength"), leg: value("leg"), gauge: gauge, stocking: true).plan
        case .poncho: return Engines.poncho(width: value("width"), gauge: gauge)
        case .twistedHeadband: return Engines.twistedHeadband(head: value("head"), width: value("width"), gauge: gauge)
        case .topDownBeanie: return Engines.topDownBeanie(head: value("head"), gauge: gauge).plan
        case .bucketHat: return Engines.bucketHat(head: value("head"), gauge: gauge)
        case .babyCocoon: return Engines.cocoon(around: value("around"), length: value("length"), gauge: gauge)
        case .knitBasket: return Engines.basket(diameter: value("diameter"), height: value("height"), gauge: gauge).plan
        case .tubeSocks: return Engines.tubeSocks(foot: value("foot"), length: value("length"), gauge: gauge).plan
        case .toteBag: return Engines.tote(width: value("width"), height: value("height"), handle: value("handle"), gauge: gauge).plan
        case .babyPullover: return Engines.babyPullover(chest: value("chest") + Self.sweaterEase, wearer: value("chest"), body: value("body"), sleeve: value("sleeve"), gauge: gauge).plan
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
