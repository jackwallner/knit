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
        let collection = TopicalStore.collection.map { Ravel.LibraryItem.topical($0) }
        for item in collection {
            XCTAssertTrue(LibrarySearch.find(item.title, in: collection).contains { $0.id == item.id }, item.title)
        }
    }

    /// A stitch design is found by its stitch, even when the name leaves it out.
    func testStitchDesignsAreFoundByTheirStitch() {
        let collection = TopicalStore.collection.map { Ravel.LibraryItem.topical($0) }
        XCTAssertTrue(LibrarySearch.find("waffle", in: collection).contains { $0.id == "topical.waffle-beanie" })
        XCTAssertTrue(LibrarySearch.find("moss", in: collection).contains { $0.id == "topical.double-moss-scarf" })
        XCTAssertTrue(LibrarySearch.find("texture", in: collection).contains { $0.id == "topical.waffle-beanie" })
    }

    func testShelfTagsAreSearched() {
        let tags = [Design.ribbedBeanie.rawValue: ["Holiday"], Design.mittens.rawValue: ["Gift season"]]
        // The Christmas Stocking and the ornament are holiday designs by their own words, tag or not.
        let stocking = Design.christmasStocking.rawValue, ornament = Design.miniStocking.rawValue
        XCTAssertEqual(find("christmas", tags: tags).map(\.id), [Design.ribbedBeanie.rawValue, stocking, ornament])
        XCTAssertEqual(find("xmas", tags: tags).map(\.id), [Design.ribbedBeanie.rawValue, stocking, ornament])
        XCTAssertEqual(find("gifts", tags: tags).map(\.id), [Design.mittens.rawValue])
        XCTAssertEqual(find("a present", tags: tags).map(\.id), [Design.mittens.rawValue])
        XCTAssertEqual(find("christmas").map(\.id), [stocking, ornament], "no tag, no match")
        XCTAssertEqual(find("ornament").map(\.id), [ornament])
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
