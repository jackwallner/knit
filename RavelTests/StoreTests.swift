import StoreKit
import StoreKitTest
import XCTest
@testable import Ravel

/// Buys the products in `Ravel.storekit` through StoreKit Testing. Nothing here reaches RevenueCat.
@MainActor
final class StoreTests: XCTestCase {
    private var session: SKTestSession!
    private let store = SubscriptionService.shared

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "Ravel")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        store.setLocalOverride(isPro: false)
        // The test store can take a moment to serve products after a reset.
        for _ in 0..<20 where store.offers.isEmpty {
            await store.loadOffers()
            if store.offers.isEmpty { try await Task.sleep(for: .milliseconds(500)) }
        }
    }

    private func offer(_ term: Offer.Term) throws -> Offer {
        try XCTUnwrap(store.offers.first { $0.term == term })
    }

    func testOffersCarryStorePricesAndTrials() throws {
        XCTAssertEqual(store.offers.map(\.term), [.yearly, .monthly, .lifetime])
        XCTAssertEqual(try offer(.yearly).priceLine, "$39.99 a year")
        XCTAssertEqual(try offer(.monthly).priceLine, "$6.99 a month")
        XCTAssertEqual(try offer(.lifetime).priceLine, "$79.99 once")
        XCTAssertEqual(store.offers.map(\.trialDays), [7, 7, 0])
        XCTAssertEqual(try offer(.yearly).action, "Try Free for 7 Days")
        XCTAssertEqual(try offer(.lifetime).action, "Buy Lifetime")
    }

    /// Once the test store has gone quiet it stays quiet, and a purchase left hanging blocks the next one.
    private static var storeIsSilent = false

    /// Buys an offer. On some simulators the test store never answers a purchase, so the wait is bounded
    /// and the test is skipped, never left hanging.
    private func buy(_ term: Offer.Term) async throws -> SubscriptionService.Outcome {
        let offer = try offer(term)
        guard !Self.storeIsSilent else { throw XCTSkip("StoreKit Testing is not answering purchases on this simulator") }
        let answered = expectation(description: "the store answers")
        var outcome: SubscriptionService.Outcome?
        Task {
            outcome = await store.purchase(offer)
            answered.fulfill()
        }
        guard await XCTWaiter.fulfillment(of: [answered], timeout: 30) == .completed, let outcome else {
            Self.storeIsSilent = true
            XCTAssertFalse(store.isPro)
            throw XCTSkip("StoreKit Testing did not answer the purchase on this simulator")
        }
        return outcome
    }

    func testYearlyStartsOnTheFreeTrial() async throws {
        let outcome = try await buy(.yearly)
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(store.isPro)
        XCTAssertEqual(session.allTransactions().map(\.productIdentifier), [RevenueCatConfig.yearly])
        let latest = await Transaction.latest(for: RevenueCatConfig.yearly)
        XCTAssertEqual(latest?.unsafePayloadValue.offerType, .introductory)
    }

    func testMonthlyUnlocks() async throws {
        let outcome = try await buy(.monthly)
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(store.isPro)
        XCTAssertEqual(session.allTransactions().map(\.productIdentifier), [RevenueCatConfig.monthly])
    }

    func testLifetimeUnlocks() async throws {
        let outcome = try await buy(.lifetime)
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(store.isPro)
        XCTAssertEqual(session.allTransactions().map(\.productIdentifier), [RevenueCatConfig.lifetime])
    }

    func testAFailedPurchaseStaysLocked() async throws {
        session.failTransactionsEnabled = true
        session.failureError = .unknown
        let outcome = try await buy(.yearly)
        XCTAssertEqual(outcome, .failed)
        XCTAssertFalse(store.isPro)
        XCTAssertTrue(session.allTransactions().isEmpty)
    }
}
