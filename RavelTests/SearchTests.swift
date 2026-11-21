import XCTest
@testable import Ravel

/// Search reads what a knitter types the way they mean it.
@MainActor
final class SearchTests: XCTestCase {
    private let library = Design.allCases.map { Ravel.LibraryItem.builtIn($0) }

    private func find(_ query: String, tags: [String: [String]] = [:]) -> [Ravel.LibraryItem] {
        LibrarySearch.find(query, in: library, tags: tags)
    }

    func testOtherWordsForAGarmentFindIt() {
        let toques = find("toque")
        XCTAssertFalse(toques.isEmpty)
        XCTAssertTrue(toques.allSatisfy { $0.base.shelf == .hats }, "a toque is a hat")
        let jumpers = find("jumpers")
        XCTAssertFalse(jumpers.isEmpty)
        XCTAssertTrue(jumpers.allSatisfy { $0.base.shelf == .sweaters }, "a jumper is a sweater")
    }

    /// Every design is found by its own name, and the way knitters write it: "toe up socks".
    func testEveryDesignIsFoundByItsName() {
        for design in Design.allCases {
            XCTAssertTrue(find(design.name).contains { $0.id == design.rawValue }, design.name)
        }
        XCTAssertEqual(find("toe up socks").first?.id, Design.toeUpSocks.rawValue)
    }

    func testShelfTagsAreSearched() {
        let tags = [Design.ribbedBeanie.rawValue: ["Holiday"], Design.mittens.rawValue: ["Gift season"]]
        XCTAssertEqual(find("christmas", tags: tags).map(\.id), [Design.ribbedBeanie.rawValue])
        XCTAssertEqual(find("xmas", tags: tags).map(\.id), [Design.ribbedBeanie.rawValue])
        XCTAssertEqual(find("gifts", tags: tags).map(\.id), [Design.mittens.rawValue])
        XCTAssertEqual(find("a present", tags: tags).map(\.id), [Design.mittens.rawValue])
        XCTAssertTrue(find("christmas").isEmpty, "no tag, no match")
    }

    func testNothingForWhatRavelDoesNotHave() {
        for query in ["dog sweater", "crochet hat", "cat toy", "amigurumi"] {
            XCTAssertTrue(find(query).isEmpty, query)
        }
    }

    func testAnAgeMeansASize() {
        XCTAssertEqual(LibrarySearch.words("hat for a 3 year old"), ["hat", "child"])
        XCTAssertEqual(LibrarySearch.words("6-month-old blanket"), ["baby", "blanket"])
        let hats = find("hat for a 3 year old")
        XCTAssertFalse(hats.isEmpty)
        XCTAssertTrue(hats.allSatisfy { $0.base.shelf == .hats })
        XCTAssertTrue(hats.allSatisfy { item in item.base.sizes.contains { $0.name == "Child" } }, "only hats that come in a child size")
    }

    func testTheGarmentOutranksTheSize() {
        let found = find("cardigan for baby")
        XCTAssertFalse(found.isEmpty)
        XCTAssertTrue(found.allSatisfy { $0.name.lowercased().contains("cardigan") }, "cardigans, not every baby pattern")
    }

    func testAnEmptySearchShowsEverything() {
        XCTAssertEqual(find("  ").count, library.count)
        XCTAssertEqual(find("for the").count, library.count)
    }
}
