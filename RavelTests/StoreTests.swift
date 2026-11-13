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

    func testYearlyStartsOnTheFreeTrial() async throws {
        let outcome = await store.purchase(try offer(.yearly))
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(store.isPro)
        XCTAssertEqual(session.allTransactions().map(\.productIdentifier), [RevenueCatConfig.yearly])
        let latest = await Transaction.latest(for: RevenueCatConfig.yearly)
        XCTAssertEqual(latest?.unsafePayloadValue.offerType, .introductory)
    }

    func testMonthlyUnlocks() async throws {
        let outcome = await store.purchase(try offer(.monthly))
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(store.isPro)
        XCTAssertEqual(session.allTransactions().map(\.productIdentifier), [RevenueCatConfig.monthly])
    }

    func testLifetimeUnlocks() async throws {
        let outcome = await store.purchase(try offer(.lifetime))
        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(store.isPro)
        XCTAssertEqual(session.allTransactions().map(\.productIdentifier), [RevenueCatConfig.lifetime])
    }

    func testAFailedPurchaseStaysLocked() async throws {
        session.failTransactionsEnabled = true
        session.failureError = .unknown
        let outcome = await store.purchase(try offer(.yearly))
        XCTAssertEqual(outcome, .failed)
        XCTAssertFalse(store.isPro)
        XCTAssertTrue(session.allTransactions().isEmpty)
    }
}
