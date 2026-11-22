import XCTest
@testable import Ravel

/// The two first-launch answers and what the library does with them.
@MainActor
final class TasteTests: XCTestCase {
    func testTheShelfAskedForComesFirstAndNoneIsLost() {
        XCTAssertEqual(Taste.shelves(first: nil), Design.Shelf.allCases)
        let shelves = Taste.shelves(first: .home)
        XCTAssertEqual(shelves.first, .home)
        XCTAssertEqual(Set(shelves), Set(Design.Shelf.allCases))
        XCTAssertEqual(shelves.count, Design.Shelf.allCases.count)
    }

    func testANewKnitterSeesBeginnerDesignsFirstAndEveryoneElseTheShelfAsItIs() {
        let hats = LibraryView.items(on: .hats, topical: [])
        XCTAssertEqual(Taste.ordered(hats, for: nil).map(\.id), hats.map(\.id))
        XCTAssertEqual(Taste.ordered(hats, for: .years).map(\.id), hats.map(\.id))
        let sorted = Taste.ordered(hats, for: .new)
        XCTAssertEqual(Set(sorted.map(\.id)), Set(hats.map(\.id)))
        let rank: [Design.Level: Int] = [.beginner: 0, .easy: 1, .intermediate: 2]
        let ranks = sorted.map { rank[$0.level]! }
        XCTAssertEqual(ranks, ranks.sorted(), "easier designs come first")
        // Within a level the shelf keeps its own order.
        for level in [Design.Level.beginner, .easy, .intermediate] {
            XCTAssertEqual(sorted.filter { $0.level == level }.map(\.id), hats.filter { $0.level == level }.map(\.id))
        }
    }

    func testTheTrialPageLeadsWithTheKindAskedFor() {
        XCTAssertEqual(OnboardingView.pieces(leading: nil), [.hat, .sweater, .shawl, .mittens, .scarf, .cowl])
        for shelf in Design.Shelf.allCases {
            let pieces = OnboardingView.pieces(leading: shelf)
            XCTAssertEqual(pieces.count, 6)
            XCTAssertEqual(Set(pieces).count, 6, "\(shelf): a piece shows twice")
        }
        XCTAssertEqual(OnboardingView.pieces(leading: .home).prefix(3), [.blanket, .pillow, .cloth])
    }
}
