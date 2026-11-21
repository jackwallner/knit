import Foundation

/// Finding a design from what a knitter types, the way people talk: "hat for kids", "a baby blanket",
/// "christmas", "cardigan for a 3 year old". In the knitter's language or in English.
enum LibrarySearch {
    /// Small words, and genders: sizes are letters or measurements, so "men sweater" looks for sweaters.
    private static let skipped: Set<String> = ["a", "an", "the", "for", "to", "of", "and", "with", "my", "in", "on", "pattern", "patterns",
                                                "men", "man", "mens", "women", "woman", "womens"]
    private static let same = [
        "kid": "child", "children": "child", "toddler": "child", "newborn": "baby", "infant": "baby",
        "beanie": "hat", "toque": "hat", "glove": "mitten", "jumper": "sweater",
        "christmas": "holiday", "xmas": "holiday", "present": "gift",
    ]
    /// Things Ravel has no patterns for. A search for one finds nothing, never a human sweater for a dog.
    private static let absent: Set<String> = ["dog", "cat", "pet", "puppy", "crochet", "amigurumi", "toy", "doll"]

    /// The words that count, each in the form the library uses. An age becomes the size it means.
    static func words(_ query: String) -> [String] {
        let aged = query.lowercased()
            .replacingOccurrences(of: #"\b\d+\s*-?\s*(months?|mos?|weeks?)(\s*-?\s*old)?\b"#, with: "baby", options: .regularExpression)
            .replacingOccurrences(of: #"\b\d+\s*-?\s*(years?|yrs?|yo)(\s*-?\s*old)?\b"#, with: "child", options: .regularExpression)
        return aged.split(whereSeparator: { $0 == " " || $0 == "," }).map { word -> String in
            // "christmas" is looked up whole before it is read as a plural.
            if let known = same[String(word)] { return known }
            let one = word.hasSuffix("s") && word.count > 3 ? String(word.dropLast()) : String(word)
            return same[one] ?? one
        }.filter { !skipped.contains($0) }
    }

    /// Designs with every word, in the order given. When none has them all, the garment asked for outranks the
    /// size: "cardigan for baby" shows the cardigans, not every baby pattern. Nothing for what Ravel does not have.
    /// `tags` are the shelf tags a design carries ("Holiday", "Gift season"), by design id.
    static func find(_ query: String, in items: [LibraryItem], tags: [String: [String]] = [:]) -> [LibraryItem] {
        let words = words(query)
        guard !words.isEmpty else { return items }
        guard absent.isDisjoint(with: words) else { return [] }
        let free = String(localized: "Free", comment: "Label under a design that needs no purchase")
        let read = items.map { item -> (item: LibraryItem, what: String, size: String) in
            let shelf = (tags[item.id] ?? []).flatMap { [$0, Loc.text($0)] }
            // A stitch design is found by its stitch and how it is worked: "lace", "cable", "waffle".
            let stitch = item.techniques.flatMap { [$0, Loc.text($0)] } + (item.stitch.map { [$0.name, Loc.text($0.name)] } ?? [])
            let what = ([item.title, item.name, item.base.shelf.title, item.base.shelf.rawValue, item.base.searchWords] + shelf + stitch).joined(separator: " ").lowercased()
            // Blankets come in stroller, crib and throw sizes: a baby blanket is one of the first two.
            let baby = item.base.sizes.contains { ["Stroller", "Crib"].contains($0.name) } ? "baby" : ""
            let size = ([item.level.title, item.isFree ? free : "", baby] + item.base.sizes.flatMap { [$0.name, Loc.text($0.name)] }).joined(separator: " ").lowercased()
            return (item, what, size)
        }
        func hits(_ entry: (item: LibraryItem, what: String, size: String), _ list: [String]) -> Int {
            list.filter { entry.what.contains($0) || entry.size.contains($0) }.count
        }
        let all = read.filter { hits($0, words) == words.count }.map(\.item)
        guard all.isEmpty else { return all }
        // What is asked for (a cardigan), as against who it is for (a baby): a word no size uses.
        let garments = words.filter { word in read.contains { $0.what.contains(word) } && !read.contains { $0.size.contains(word) } }
        let pool = garments.isEmpty ? read : read.filter { entry in garments.allSatisfy(entry.what.contains) }
        return pool.map { ($0.item, hits($0, words)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.map(\.0)
    }
}
