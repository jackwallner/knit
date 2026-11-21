import Foundation

/// A seasonal or topical design, published on the Ravel site as data: one of the library's shapes, with
/// stripes, a chart and a name of its own. The shape's engine still writes every stitch, so a record can
/// only change what the pattern looks like, never whether its numbers add up.
struct Topical: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let base: Design
    let work: Colorwork
    /// The stitch pattern the shape's main fabric is worked in. Nil keeps the shape's own fabric.
    var stitch: Stitch?
    /// The sample photo on the Ravel site, for a record that has one: a path under `photos/`.
    var photo: String?
    /// The yarn weights the chart was proven to fit at every size.
    let weights: [YarnWeight]
    let tag: String
    let starts: Date?
    let ends: Date?
    let isFree: Bool
    /// Raised each time a published record is corrected, so projects cast on from it are offered the fix.
    /// Optional in the file and ignored by builds that do not know it.
    var revision = 0
    /// Shipped inside the app as part of the library rather than published on the site: no season, a
    /// translated name and a sample photo.
    var bundled = false

    /// The newest record format this build reads. A record that needs more is skipped, so a feature added
    /// later can never be misread by an older app.
    /// 2: `stitch`, a stitch pattern for the shape's fabric, and records of one color.
    static let featureLevel = 2

    /// Shapes a stitch pattern can be worked on.
    static let stitchBases: [Design] = [.ribbedBeanie, .slouchHat, .garterScarf, .ribbedCowl, .borderedBlanket, .earWarmer]

    /// Shapes a record may build on: the ones colorwork has been taught.
    static let bases: [Design] = [
        .ribbedBeanie, .slouchHat, .rolledBrimHat, .ribbedCowl, .seedCowl, .chunkyCowl, .earWarmer, .handwarmers,
        .garterScarf, .ribbedScarf, .seedScarf, .borderedBlanket, .garterBlanket,
    ]

    /// The design a cast-on project names: "topical." in front, so it never meets a built-in name.
    var designRaw: String { "topical.\(id)" }

    var silhouette: Design.Silhouette { work.ears ? .ears : base.silhouette }

    var level: Design.Level {
        if work.chart != nil { return .intermediate }
        let order: [Design.Level] = [.beginner, .easy, .intermediate]
        let levels = [base.level] + (stitch.map { [$0.level] } ?? [])
        return levels.max { order.firstIndex(of: $0)! < order.firstIndex(of: $1)! } ?? base.level
    }

    /// What the knitter will do beyond the shape's own stitches, in the order they meet it.
    var techniques: [String] {
        var all: [String] = []
        if let stitch { all.append(stitch.technique) }
        if !work.stripes.isEmpty { all.append("Stripes") }
        if let chart = work.chart { all.append(chart.duplicate ? "Duplicate stitch" : "Stranded colorwork") }
        if work.ears { all.append("Sewn-on ears") }
        return all
    }

    var defaultWeight: YarnWeight { weights.contains(base.weight) ? base.weight : weights[weights.count / 2] }

    var fit: Engines.Fit {
        var fit = Engines.Fit()
        fit.ears = work.ears
        fit.stitch = stitch
        guard let chart = work.chart else { return fit }
        if chart.placement == .repeating, !base.isFlat { fit.multiple = chart.width }
        // A shape that is all texture gets a band of stockinette for the chart, a round above and below it.
        if [.ribbedCowl, .seedCowl, .chunkyCowl, .earWarmer, .handwarmers].contains(base) { fit.band = chart.height + 2 }
        return fit
    }

    /// The longest strand a chart may carry behind the work: an inch and a quarter, so it does not snag.
    /// Never more than 5 stitches, however fine the yarn.
    static func longestFloat(_ g: Gauge) -> Int { min(5, max(3, Int((g.spi * 1.25).rounded()))) }

    func painted(measures: [String: Double], gauge: Gauge) -> Painter.Result {
        let plain = base.plan(measures: measures, gauge: gauge, fit: fit)
        // One yarn and no stripes: a stitch pattern alone, so the plan stays a plan in one color.
        if work.palette.count == 1, work.stripes.isEmpty, work.chart == nil, !work.ears {
            var single = plain
            single.silhouette = silhouette.rawValue
            return Painter.Result(plan: single, issues: [])
        }
        var result = Painter.paint(plain, with: work, gauge: gauge, rate: base.rowsPerInch(gauge), float: Self.longestFloat(gauge), garter: base.isGarter)
        result.plan.silhouette = silhouette.rawValue
        return result
    }

    func plan(measures: [String: Double], gauge: Gauge) -> PatternPlan { painted(measures: measures, gauge: gauge).plan }

    func isLive(at date: Date) -> Bool {
        (starts.map { date >= $0 } ?? true) && (ends.map { date < $0 } ?? true)
    }
}

extension Design {
    var isFlat: Bool {
        switch self {
        case .garterScarf, .ribbedScarf, .seedScarf, .borderedBlanket, .garterBlanket, .dishcloth, .triangleShawl, .neckScarf, .cableHeadband: true
        case .basketweaveBlanket, .rectangularWrap, .crescentShawl: true
        default: false
        }
    }
}

// MARK: Reading records

extension Topical {
    struct Record: Codable, Sendable {
        struct Stripe: Codable, Sendable {
            var color: String
            var inches: Double
        }

        struct Chart: Codable, Sendable {
            var placement: String
            var stripe: Int?
            var rows: [String]
            /// "duplicate" sews the chart on afterward. Builds that do not know it knit the chart in.
            var stitch: String?
        }

        var id: String
        var title: String
        var base: String
        var requires: Int?
        var crown: String?
        var palette: [Shade]
        var brim: String?
        var rim: String?
        var stripes: [Stripe]?
        var repeatStripes: Bool?
        var chart: Chart?
        var weights: [String]
        var tag: String
        var starts: String?
        var ends: String?
        var free: Bool?
        var revision: Int?
        /// A `Stitch` raw value (format 2).
        var stitch: String?
        /// "photos/<id>.jpg" on the Ravel site. Builds that do not know it draw the design instead.
        var photo: String?
    }

    struct Listing: Codable, Sendable {
        var designs: [Record]
    }

    /// One record read from a file, with what is wrong with it if it cannot be used.
    struct Parsed: Sendable {
        var id: String
        var topical: Topical?
        var problems: [String]
    }

    private static func day(_ text: String?) -> Date?? {
        guard let text else { return .some(nil) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else { return nil }
        return .some(date)
    }

    /// Every record in a list, usable or not. A file that is not a list gives nothing.
    static func parse(_ data: Data) -> [Parsed] {
        guard let listing = try? JSONDecoder().decode(Listing.self, from: data) else { return [] }
        var seen = Set<String>()
        return listing.designs.map { record in
            var parsed = make(record)
            if !seen.insert(record.id).inserted { parsed.problems.append("The id \(record.id) is used twice") }
            if !parsed.problems.isEmpty { parsed.topical = nil }
            return parsed
        }
    }

    /// The records the app can show today. Anything it cannot read is left out, and the rest still load.
    static func decode(_ data: Data, now: Date = .now) -> [Topical] {
        parse(data).compactMap(\.topical).filter { $0.isLive(at: now) }
    }

    /// Reads one record strictly: a field this build does not understand rejects the record.
    static func make(_ r: Record) -> Parsed {
        var problems: [String] = []
        func check(_ ok: Bool, _ problem: String) { if !ok { problems.append(problem) } }

        check(r.id.range(of: "^[a-z0-9]+(-[a-z0-9]+)*$", options: .regularExpression) != nil && (3...40).contains(r.id.count), "The id must be 3 to 40 lowercase letters, digits and single hyphens")
        let title = r.title.trimmingCharacters(in: .whitespaces)
        let tag = r.tag.trimmingCharacters(in: .whitespaces)
        check(!title.isEmpty && title.count <= 28, "The title must be 1 to 28 characters")
        check(!tag.isEmpty && tag.count <= 24, "The tag must be 1 to 24 characters")
        for text in [title, tag] + r.palette.map(\.name) { check(!text.contains("\u{2014}") && !text.contains("\u{2013}"), "No dashes other than hyphens: \(text)") }
        check((r.requires ?? 1) <= featureLevel, "Needs record format \(r.requires ?? 1); this build reads \(featureLevel)")

        let base = Design(rawValue: r.base)
        check(base.map(bases.contains) ?? false, "\(r.base) is not a shape colorwork can use")

        let stitch = r.stitch.flatMap(Stitch.init(rawValue:))
        check(r.stitch == nil || stitch != nil, "Stitch \(r.stitch ?? "") is not one this build knows")
        check(r.stitch == nil || (r.requires ?? 1) >= 2, "A stitch pattern needs record format 2")
        check(r.stitch == nil || base.map(stitchBases.contains) ?? false, "\(r.base) is not a shape a stitch pattern can use")
        check(r.stitch == nil || r.chart == nil, "A chart goes on stockinette, not on a stitch pattern")
        check((stitch == nil ? 2 : 1)...4 ~= r.palette.count, stitch == nil ? "The palette has 2 to 4 colors" : "The palette has 1 to 4 colors")
        if let photo = r.photo {
            // A replaced photo takes a new name ("-2"), so a phone that cached the old one fetches it.
            check(photo.range(of: "^photos/\(r.id)(-[0-9]+)?\\.jpg$", options: .regularExpression) != nil, "A photo is photos/\(r.id).jpg on the Ravel site")
        }
        for shade in r.palette {
            check(shade.name.range(of: "^[a-z][a-z ]{1,11}$", options: .regularExpression) != nil, "Color names are 2 to 12 lowercase letters: \(shade.name)")
            check(shade.rgb != nil, "\(shade.hex) is not a #RRGGBB color")
        }
        check(Set(r.palette.map(\.name)).count == r.palette.count, "Two colors share a name")

        func color(_ letter: String) -> Int? {
            guard letter.count == 1, let index = Colorwork.index(Character(letter)), index < r.palette.count else { return nil }
            return index
        }
        let brim = r.brim.flatMap(color)
        check(r.brim == nil || brim != nil, "Brim color \(r.brim ?? "") is not in the palette")
        var stripes: [Colorwork.Stripe] = []
        for stripe in r.stripes ?? [] {
            guard let index = color(stripe.color) else {
                problems.append("Stripe color \(stripe.color) is not in the palette")
                continue
            }
            check((0.25...30).contains(stripe.inches), "A stripe is 0.25 to 30 inches high")
            stripes.append(Colorwork.Stripe(color: index, inches: stripe.inches))
        }

        var chart: Colorwork.Chart?
        if let c = r.chart {
            let placement = Colorwork.Chart.Placement(rawValue: c.placement)
            check(placement != nil, "Chart placement \(c.placement) is not repeat or motif")
            var cells: [[Int]] = []
            for line in c.rows {
                var row: [Int] = []
                for letter in line {
                    if letter == "." { row.append(-1) } else if let index = color(String(letter)) { row.append(index) } else {
                        problems.append("Chart letter \(letter) is not in the palette")
                    }
                }
                cells.append(row)
            }
            let width = cells.first?.count ?? 0
            check(!cells.isEmpty && cells.allSatisfy { $0.count == width }, "Every chart row is the same width")
            check((1...40).contains(width) && (1...30).contains(cells.count), "A chart is 1 to 40 stitches wide and 1 to 30 rows high")
            check(cells.contains { $0.contains { $0 >= 0 } }, "The chart has no stitches in a color")
            if let stripe = c.stripe { check(stripe >= 0 && stripe < stripes.count, "The chart sits on stripe \(stripe), which does not exist") }
            check(c.stitch == nil || c.stitch == "duplicate", "Chart stitch \(c.stitch ?? "") is not one this build knows")
            check(c.stitch == nil || placement == .motif, "Only a motif can be worked in duplicate stitch")
            if let placement { chart = Colorwork.Chart(placement: placement, rows: cells, stripe: c.stripe, duplicate: c.stitch == "duplicate") }
        }

        var ears = false
        switch r.crown {
        case nil: break
        case "ears":
            ears = true
            check(base == .ribbedBeanie || base == .rolledBrimHat, "Only a beanie can have the ear crown")
        default: problems.append("Crown \(r.crown!) is not one this build knows")
        }
        let rim = r.rim.flatMap(color)
        check(r.rim == nil || rim != nil, "Rim color \(r.rim ?? "") is not in the palette")
        check(r.rim == nil || ears, "A rim needs the ear crown")

        let weights = r.weights.compactMap(YarnWeight.init(rawValue:))
        check(!weights.isEmpty && weights.count == r.weights.count, "Weights must name yarn weights: \(r.weights.joined(separator: ", "))")
        let starts = day(r.starts), ends = day(r.ends)
        check(starts != nil && ends != nil, "Dates are written 2026-12-01")
        if let s = starts ?? nil, let e = ends ?? nil { check(s < e, "The design ends before it starts") }

        guard problems.isEmpty, let base else { return Parsed(id: r.id, topical: nil, problems: problems) }
        let work = Colorwork(palette: r.palette, brim: brim, stripes: stripes, repeatsStripes: r.repeatStripes ?? false, chart: chart, ears: ears, rim: rim)
        let order = YarnWeight.allCases
        var topical = Topical(
            id: r.id, title: title, base: base, work: work,
            weights: order.filter(weights.contains), tag: tag,
            starts: starts ?? nil, ends: ends ?? nil, isFree: r.free ?? false
        )
        topical.revision = max(0, r.revision ?? 0)
        topical.stitch = stitch
        topical.photo = r.photo
        return Parsed(id: r.id, topical: topical, problems: [])
    }
}
