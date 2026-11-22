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
        XCTAssertEqual(find("winter gloves").first?.id, Design.gloves.rawValue)
        XCTAssertEqual(find("tote").first?.id, Design.toteBag.rawValue)
        XCTAssertEqual(find("tube socks").first?.id, Design.tubeSocks.rawValue)
        XCTAssertEqual(find("cocoon").first?.id, Design.babyCocoon.rawValue)
        XCTAssertEqual(find("basket").first?.id, Design.knitBasket.rawValue)
        XCTAssertEqual(find("vest for a 6 year old").first?.id, Design.kidsVest.rawValue)
        XCTAssertEqual(find("table runner").first?.id, Design.tableRunner.rawValue)
        XCTAssertEqual(find("ruana").first?.id, Design.ruana.rawValue)
        XCTAssertEqual(find("scrunchie").first?.id, Design.scrunchie.rawValue)
        XCTAssertEqual(find("pouf").first?.id, Design.floorPouf.rawValue)
        XCTAssertEqual(find("ottoman").first?.id, Design.floorPouf.rawValue)
        XCTAssertEqual(find("bib").first?.id, Design.babyBib.rawValue)
        XCTAssertEqual(find("bath mat").first?.id, Design.bathMat.rawValue)
        XCTAssertEqual(find("bathroom rug").first?.id, Design.bathMat.rawValue)
        XCTAssertEqual(find("laptop").first?.id, Design.laptopSleeve.rawValue)
        XCTAssertEqual(find("bauble").first?.id, Design.bauble.rawValue)
        XCTAssertEqual(find("neck warmer").first?.id, Design.buttonNeckWarmer.rawValue)
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
        // The Christmas Stocking and the ornaments are holiday designs by their own words, tag or not.
        let stocking = Design.christmasStocking.rawValue, ornament = Design.miniStocking.rawValue, bauble = Design.bauble.rawValue
        XCTAssertEqual(find("christmas", tags: tags).map(\.id), [Design.ribbedBeanie.rawValue, stocking, ornament, bauble])
        XCTAssertEqual(find("xmas", tags: tags).map(\.id), [Design.ribbedBeanie.rawValue, stocking, ornament, bauble])
        XCTAssertEqual(find("gifts", tags: tags).map(\.id), [Design.mittens.rawValue])
        XCTAssertEqual(find("a present", tags: tags).map(\.id), [Design.mittens.rawValue])
        XCTAssertEqual(find("christmas").map(\.id), [stocking, ornament, bauble], "no tag, no match")
        XCTAssertEqual(find("ornament").map(\.id), [ornament, bauble])
    }

    func testATeeIsFoundByWhatPeopleCallIt() {
        for query in ["tee", "t-shirt", "short sleeve", "summer top"] {
            XCTAssertEqual(find(query).first?.id, Design.raglanTee.rawValue, query)
        }
    }

    func testAStitchAndAShapeFindTheDesignWithBoth() {
        let all = library + TopicalStore.collection.map { Ravel.LibraryItem.topical($0) }
        XCTAssertEqual(LibrarySearch.find("honeycomb hat", in: all).first?.id, "topical.honeycomb-beanie")
        XCTAssertEqual(LibrarySearch.find("honeycomb cowl", in: all).first?.id, "topical.honeycomb-cowl")
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
