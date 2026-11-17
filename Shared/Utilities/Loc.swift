import Foundation

/// Looks up interface text that arrives as an English string: section names the engines write, the
/// glossary, the Trending tags. The catalog (`Ravel/Localizable.xcstrings`) holds each one under its
/// English text; anything it does not know comes back unchanged. Instruction text is never run through
/// here: stitch counts and abbreviations stay in English on purpose.
enum Loc {
    private final class AppBundle {}

    /// The bundle that holds the catalog: the app, also when the code runs under a test host.
    static let bundle = Bundle(for: AppBundle.self)

    static func text(_ english: String) -> String {
        bundle.localizedString(forKey: english, value: english, table: nil)
    }

    /// A section name such as "Crown" or "Mitt 1 · Cuff". Numbered pieces keep their number.
    static func section(_ english: String) -> String {
        english.components(separatedBy: " · ").map(piece).joined(separator: " · ")
    }

    private static func piece(_ english: String) -> String {
        for prefix in ["Mitt ", "Leg Warmer ", "Sock ", "Mitten "] where english.hasPrefix(prefix) {
            guard let number = Int(english.dropFirst(prefix.count)) else { break }
            let format = text(prefix + "%lld")
            return String(format: format, number)
        }
        return text(english)
    }
}
