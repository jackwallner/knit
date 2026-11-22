import Foundation

/// What the knitter said at first launch: what they want to knit first and how long they have knitted.
/// The library reads it to put that shelf first and, for a new knitter, the beginner designs first.
/// Nothing leaves the phone, and no answer leaves the library in its own order.
enum Taste {
    enum Experience: String, CaseIterable, Sendable {
        case new, some, years

        /// The answer as the question page shows it.
        var title: String {
            switch self {
            case .new: String(localized: "I'm new to knitting")
            case .some: String(localized: "A few projects")
            case .years: String(localized: "Years")
            }
        }
    }

    private static let shelfKey = "tasteShelf"
    private static let experienceKey = "tasteExperience"

    static var shelf: Design.Shelf? {
        get { UserDefaults.standard.string(forKey: shelfKey).flatMap(Design.Shelf.init(rawValue:)) }
        set { UserDefaults.standard.set(newValue?.rawValue, forKey: shelfKey) }
    }

    static var experience: Experience? {
        get { UserDefaults.standard.string(forKey: experienceKey).flatMap(Experience.init(rawValue:)) }
        set { UserDefaults.standard.set(newValue?.rawValue, forKey: experienceKey) }
    }

    /// The shelves in the order the library shows them: the one asked for first, the rest as they were.
    static func shelves(first: Design.Shelf? = shelf) -> [Design.Shelf] {
        guard let first else { return Design.Shelf.allCases }
        return [first] + Design.Shelf.allCases.filter { $0 != first }
    }

    /// A shelf's designs for this knitter: a new knitter sees the beginner ones first, then easy, each
    /// group in the order it had. Anyone else sees the shelf as it is.
    static func ordered(_ items: [LibraryItem], for experience: Experience? = experience) -> [LibraryItem] {
        guard experience == .new else { return items }
        let rank: [Design.Level: Int] = [.beginner: 0, .easy: 1, .intermediate: 2]
        return items.enumerated().sorted { a, b in
            let (x, y) = (rank[a.element.level] ?? 2, rank[b.element.level] ?? 2)
            return x == y ? a.offset < b.offset : x < y
        }.map(\.element)
    }
}
