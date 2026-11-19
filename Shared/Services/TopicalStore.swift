import Foundation
import Observation

/// The seasonal and topical designs published on the Ravel site. They arrive as data, so a new one
/// reaches the library without an app update; the app's own engines still write every stitch.
@MainActor
@Observable
final class TopicalStore {
    static let shared = TopicalStore()

    static let source = URL(string: "https://jackwallner.github.io/knit/designs.json")!
    private static let cacheKey = "topical.list"
    private static let fetchedKey = "topical.fetched"

    private(set) var items: [Topical]
    /// Every readable record in the list, ended ones too: a record kept in the list after its season can
    /// still offer a fix to the projects cast on from it.
    @ObservationIgnored private var published: [Topical]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        let cached = defaults.data(forKey: Self.cacheKey)
        items = cached.map { Topical.decode($0, now: now) } ?? []
        published = cached.map { Topical.parse($0).compactMap(\.topical) } ?? []
        #if DEBUG
        // `-TopicalFile <path>`: drafts from disk, for screenshots and checks before anything is published.
        // A relative path is read from the repository this build was compiled from.
        if let path = UserDefaults.standard.string(forKey: "TopicalFile"),
           let data = FileManager.default.contents(atPath: path.hasPrefix("/") ? path : Self.repository.appending(path: path).path) {
            items = Topical.parse(data).compactMap(\.topical)
            published = items
        }
        #endif
    }

    #if DEBUG
    private static let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    #endif

    /// Fetches the list at most once a day. Any failure keeps what is already shown.
    func refresh(now: Date = .now) async {
        #if DEBUG
        if UserDefaults.standard.string(forKey: "TopicalFile") != nil { return }
        #endif
        if let last = defaults.object(forKey: Self.fetchedKey) as? Date, now.timeIntervalSince(last) < 86_400 { return }
        var request = URLRequest(url: Self.source, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await URLSession.shared.data(for: request), (response as? HTTPURLResponse)?.statusCode == 200 else { return }
        // A file that is not a list at all is a broken publish: keep the last good one.
        guard (try? JSONDecoder().decode(Topical.Listing.self, from: data)) != nil else { return }
        defaults.set(data, forKey: Self.cacheKey)
        defaults.set(now, forKey: Self.fetchedKey)
        // A shelf already showing is swapped on the next launch, so it never shifts under a knitter. A first install
        // has nothing to shift, and someone who came for a seasonal design must find it on the first visit.
        guard published.isEmpty else { return }
        items = Topical.decode(data, now: now)
        published = Topical.parse(data).compactMap(\.topical)
    }

    /// The colorwork designs the library ships with: the record format the site uses, bundled, with no season.
    static let collection: [Topical] = {
        guard let url = Bundle.main.url(forResource: "collection", withExtension: "json"), let data = try? Data(contentsOf: url) else { return [] }
        return Topical.parse(data).compactMap(\.topical).map { record in
            var topical = record
            topical.bundled = true
            return topical
        }
    }()

    func item(_ id: String) -> Topical? {
        items.first { $0.id == id || $0.designRaw == id } ?? Self.collection.first { $0.id == id || $0.designRaw == id }
    }

    /// A record by id whether or not its season is on, for corrections.
    func record(_ id: String) -> Topical? {
        published.first { $0.id == id || $0.designRaw == id } ?? Self.collection.first { $0.id == id || $0.designRaw == id }
    }
}

/// A design in the library: one of the built-in patterns, or a topical one from the site.
enum LibraryItem: Hashable, Identifiable, Sendable {
    case builtIn(Design)
    case topical(Topical)

    var id: String { designRaw }

    /// What a cast-on project records as its design.
    var designRaw: String {
        switch self {
        case .builtIn(let design): design.rawValue
        case .topical(let topical): topical.designRaw
        }
    }

    var name: String {
        switch self {
        case .builtIn(let design): design.name
        case .topical(let topical): topical.title
        }
    }

    /// The name as the library shows it: translated for a built-in design, as published for a topical one.
    var title: String {
        switch self {
        case .builtIn(let design): design.title
        case .topical(let topical): topical.bundled ? String(localized: String.LocalizationValue(topical.title)) : topical.title
        }
    }

    /// The sample photo's asset name, for the designs that have one.
    var photo: String? {
        switch self {
        case .builtIn(let design): design.photo
        case .topical(let topical): topical.bundled ? "sample-\(topical.id)" : nil
        }
    }

    var base: Design {
        switch self {
        case .builtIn(let design): design
        case .topical(let topical): topical.base
        }
    }

    var silhouette: Design.Silhouette {
        switch self {
        case .builtIn(let design): design.silhouette
        case .topical(let topical): topical.silhouette
        }
    }

    /// The single color a project shows where it cannot show its colorwork.
    var yarn: YarnColor {
        switch self {
        case .builtIn(let design): design.yarn
        case .topical(let topical): .nearest(to: topical.work.palette.first)
        }
    }

    var level: Design.Level {
        switch self {
        case .builtIn(let design): design.level
        case .topical(let topical): topical.level
        }
    }

    var isFree: Bool {
        switch self {
        case .builtIn(let design): design.isFree
        case .topical(let topical): topical.isFree
        }
    }

    /// The yarn weights the pattern is offered in.
    var weights: [YarnWeight] {
        switch self {
        case .builtIn: YarnWeight.allCases
        case .topical(let topical): topical.weights
        }
    }

    var defaultGauge: Gauge {
        switch self {
        case .builtIn(let design): design.gauge(for: design.weight)
        case .topical(let topical): topical.defaultWeight.gauge
        }
    }

    /// The gauge a yarn weight's chip sets for this pattern.
    func gauge(for weight: YarnWeight) -> Gauge {
        switch self {
        case .builtIn(let design): design.gauge(for: weight)
        case .topical: weight.gauge
        }
    }

    /// The gauges a knitter can dial in: any for a built-in design, and for a colorwork one the span of
    /// the weights its chart was proven at.
    var stitchRange: ClosedRange<Double> {
        let counts = weights.map(\.gauge.stitches)
        guard case .topical = self, let low = counts.min(), let high = counts.max() else { return 8...40 }
        return low...high
    }

    var rowRange: ClosedRange<Double> {
        let counts = weights.map(\.gauge.rows)
        guard case .topical = self, let low = counts.min(), let high = counts.max() else { return 10...56 }
        return low...high
    }

    /// What a cast-on project records, to tell later whether its pattern was corrected. A topical design
    /// adds its record's revision to its base engine's: a fix to either one raises it.
    var revision: Int {
        switch self {
        case .builtIn(let design): design.revision
        case .topical(let topical): topical.base.revision + topical.revision
        }
    }

    /// The corrected pattern for a cast-on project, rebuilt from the numbers it was cast on with, or nil when
    /// nothing it was built from has changed since (or a topical record was taken out of the list).
    @MainActor static func correction(for plan: PatternPlan, topicals: TopicalStore = .shared) -> PatternPlan? {
        guard let source = plan.source else { return nil }
        let item = Design(rawValue: source.design).map(LibraryItem.builtIn) ?? topicals.record(source.design).map(LibraryItem.topical)
        guard let item, item.revision > source.revision else { return nil }
        var fixed = item.plan(measures: source.measures, gauge: source.gauge)
        fixed.source = PlanSource(design: source.design, measures: source.measures, gauge: source.gauge, revision: item.revision)
        return fixed
    }

    func plan(measures: [String: Double], gauge: Gauge) -> PatternPlan {
        switch self {
        case .builtIn(let design): design.plan(measures: measures, gauge: gauge)
        case .topical(let topical): topical.plan(measures: measures, gauge: gauge)
        }
    }

    /// False when a topical chart cannot be worked at these numbers (too few rows for the chart, floats too long):
    /// such a plan would drop the colorwork, so it is never cast on.
    func fits(measures: [String: Double], gauge: Gauge) -> Bool {
        guard case .topical(let topical) = self else { return true }
        return topical.painted(measures: measures, gauge: gauge).issues.isEmpty
    }

    /// The pattern at its default size, for drawing a colorwork design before it is sized. Nil in one color.
    var preview: PatternPlan? {
        guard case .topical = self else { return nil }
        return plan(measures: base.defaultSize.values, gauge: defaultGauge)
    }
}
