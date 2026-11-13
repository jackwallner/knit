import Foundation
import Observation

/// One design on the Trending shelf, with the reason it is there.
struct Trend: Identifiable, Equatable, Sendable {
    let design: Design
    let tag: String

    var id: String { design.rawValue }
}

/// What the Patterns tab leads with: new designs and what knitters are making this season.
/// The list ships inside the app and follows the calendar. When the phone is online it is
/// replaced by the list on the Ravel site, so the shelf can change without an app update.
@MainActor
@Observable
final class Trending {
    static let shared = Trending()

    static let source = URL(string: "https://jackwallner.github.io/knit/trending.json")!
    private static let cacheKey = "trending.list"
    private static let fetchedKey = "trending.fetched"

    private(set) var items: [Trend]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        items = defaults.data(forKey: Self.cacheKey).map(Self.decode) ?? []
        if items.isEmpty { items = Self.bundled(for: now) }
    }

    /// Fetches the current list at most once a day. Any failure keeps what is already shown.
    func refresh(now: Date = .now) async {
        if let last = defaults.object(forKey: Self.fetchedKey) as? Date, now.timeIntervalSince(last) < 86_400 { return }
        var request = URLRequest(url: Self.source, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await URLSession.shared.data(for: request), (response as? HTTPURLResponse)?.statusCode == 200 else { return }
        let fresh = Self.decode(data)
        guard !fresh.isEmpty else { return }
        defaults.set(data, forKey: Self.cacheKey)
        defaults.set(now, forKey: Self.fetchedKey)
        items = fresh
    }

    private struct Listing: Decodable {
        struct Entry: Decodable {
            let design: String
            let tag: String
        }

        let items: [Entry]
    }

    /// Reads a list, skipping designs this version of the app does not have.
    nonisolated static func decode(_ data: Data) -> [Trend] {
        guard let listing = try? JSONDecoder().decode(Listing.self, from: data) else { return [] }
        var seen = Set<Design>()
        return listing.items.compactMap { entry in
            let tag = entry.tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let design = Design(rawValue: entry.design), !tag.isEmpty, tag.count <= 24, seen.insert(design).inserted else { return nil }
            return Trend(design: design, tag: tag)
        }
    }

    /// The list for a date with no network: the newest designs, then what suits the season.
    nonisolated static func bundled(for date: Date, calendar: Calendar = .current) -> [Trend] {
        let new = [Design.balaclava, .neckScarf, .cableHeadband, .chunkyCowl].map { Trend(design: $0, tag: "New") }
        let seasonal: [Trend] = switch calendar.component(.month, from: date) {
        case 10, 11, 12: [Trend(design: .handwarmers, tag: "Gift season"), Trend(design: .ribbedBeanie, tag: "Gift season")]
        case 1, 2: [Trend(design: .raglanPullover, tag: "Deep winter"), Trend(design: .legWarmers, tag: "Deep winter")]
        case 3, 4, 5: [Trend(design: .triangleShawl, tag: "Spring layers"), Trend(design: .seedCowl, tag: "Spring layers")]
        case 6, 7, 8: [Trend(design: .dishcloth, tag: "Summer cotton"), Trend(design: .triangleShawl, tag: "Travel knitting")]
        default: [Trend(design: .raglanPullover, tag: "Sweater weather"), Trend(design: .slouchHat, tag: "First cold days")]
        }
        return new + seasonal
    }
}
