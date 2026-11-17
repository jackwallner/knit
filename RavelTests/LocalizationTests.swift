import XCTest
@testable import Ravel

final class LocalizationTests: XCTestCase {
    /// The folders the App Store listing ships, mapped to the codes the app is translated into.
    private let languages = [
        "ar", "bn", "ca", "cs", "da", "de", "el", "es", "es-MX", "fi", "fr", "fr-CA", "gu", "he", "hi", "hr", "hu",
        "id", "it", "ja", "kn", "ko", "ml", "mr", "ms", "nl", "nb", "or", "pa", "pl", "pt-BR", "pt-PT", "ro", "ru",
        "sk", "sl", "sv", "ta", "te", "th", "tr", "uk", "ur", "vi", "zh-Hans", "zh-Hant", "en-AU", "en-CA", "en-GB",
    ]

    private func table(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(Loc.bundle.path(forResource: language, ofType: "lproj"), "no \(language).lproj in the app")
        return try XCTUnwrap(Bundle(path: path))
    }

    func testEveryLanguageShips() throws {
        for language in languages { _ = try table(language) }
    }

    func testTabTitlesAreTranslated() throws {
        let expected = ["de": "Muster", "ja": "編み図", "ar": "الأنماط", "ru": "Схемы", "hi": "पैटर्न", "fi": "Ohjeet"]
        for (language, patterns) in expected {
            XCTAssertEqual(try table(language).localizedString(forKey: "Patterns", value: nil, table: nil), patterns, language)
        }
    }

    func testEveryLanguageTranslatesTheTabsAndGlossary() throws {
        let keys = ["Projects", "Patterns", "Stash", "Cast On", "Knit 2 stitches together", "Ribbed Beanie", "Beginner"]
        // Words a language really shares with English, translated to themselves on purpose.
        let shared: Set<String> = ["nl:Beginner"]
        for language in languages where !language.hasPrefix("en") {
            let bundle = try table(language)
            for key in keys where !shared.contains("\(language):\(key)") {
                XCTAssertNotEqual(bundle.localizedString(forKey: key, value: key, table: nil), key, "\(language): \(key) left in English")
            }
        }
    }

    func testPlaceholdersSurvive() throws {
        for language in languages {
            let bundle = try table(language)
            let delete = bundle.localizedString(forKey: "Delete %@?", value: "Delete %@?", table: nil)
            XCTAssertTrue(delete.contains("%@"), "\(language): the name is missing from the delete question")
            let repeating = bundle.localizedString(forKey: "Row %lld of %lld in the repeat", value: "Row %lld of %lld in the repeat", table: nil)
            XCTAssertEqual(repeating.components(separatedBy: "lld").count - 1, 2, "\(language): both numbers must stay")
        }
    }

    /// Every name the library shows, every section a pattern is divided into and every abbreviation it spells
    /// out has a line in each language. Letter and number sizes keep their international names.
    func testEveryLibraryWordIsInTheCatalog() throws {
        var keys = Set<String>()
        for design in Design.allCases {
            keys.formUnion([design.name, design.shelf.rawValue, design.level.rawValue])
            keys.formUnion(design.sizes.map(\.name).filter { $0.range(of: "^([0-9]+T?|[0-9]?X?[SMLX]+)$", options: .regularExpression) == nil })
            keys.formUnion(design.measures.map(\.label))
            let plan = design.plan(measures: [:], gauge: design.weight.gauge)
            for section in plan.sections.map(\.name) {
                keys.formUnion(section.components(separatedBy: " · ").map { $0.replacingOccurrences(of: " [0-9]+$", with: " %lld", options: .regularExpression) })
            }
            keys.formUnion(plan.abbreviations.map(\.meaning))
        }
        for language in languages where !language.hasPrefix("en") {
            let bundle = try table(language)
            for key in keys.sorted() {
                XCTAssertNotEqual(bundle.localizedString(forKey: key, value: "\u{1}", table: nil), "\u{1}", "\(language): no line for \(key)")
            }
        }
        XCTAssertTrue(Loc.section("Sock 2 · Heel Turn").contains("2"))
    }

    func testSectionNamesKeepTheirNumbers() {
        XCTAssertTrue(Loc.section("Mitt 2 · Cuff").contains("2"))
        XCTAssertEqual(Loc.section("Unheard Of"), "Unheard Of")
    }

    func testUnknownTextComesBackUnchanged() {
        XCTAssertEqual(Loc.text("k2tog, p2"), "k2tog, p2")
    }
}
