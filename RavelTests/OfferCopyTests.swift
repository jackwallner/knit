import XCTest
@testable import Ravel

/// The trial and paywall words follow the fleet's approved copy (Mahj, Cribbity), and the terms always name
/// what is charged.
final class OfferCopyTests: XCTestCase {
    private let yearly = Offer(id: "y", term: .yearly, price: "$39.99", trialDays: 7, amount: 39.99)
    private let monthly = Offer(id: "m", term: .monthly, price: "$6.99", trialDays: 7, amount: 6.99)
    private let lifetime = Offer(id: "l", term: .lifetime, price: "$79.99", trialDays: 0, amount: 79.99)
    /// An Apple Account that already had its free week.
    private let usedTrial = Offer(id: "m", term: .monthly, price: "$6.99", trialDays: 0, amount: 6.99)

    func testButtonsSayTheTrial() {
        XCTAssertEqual(monthly.trialAction, "Start 7-day free trial")
        XCTAssertEqual(yearly.action, "Start 7-Day Free Trial")
        XCTAssertEqual(lifetime.action, "Buy Lifetime")
    }

    func testTermsAreOneLineNamingTheCharge() {
        XCTAssertEqual(monthly.disclosure, "7 days free, then $6.99 a month. Auto-renews until canceled.")
        XCTAssertEqual(yearly.disclosure, "7 days free, then $39.99 a year. Auto-renews until canceled.")
        XCTAssertEqual(lifetime.disclosure, "One payment of $79.99. Every pattern is yours for good.")
    }

    /// No free week left: nothing on the page promises one (App Review 3.1.2).
    func testNoTrialWordsWithoutATrial() {
        XCTAssertEqual(usedTrial.trialAction, "Subscribe")
        XCTAssertEqual(usedTrial.action, "Subscribe")
        XCTAssertEqual(usedTrial.disclosure, "$6.99 a month, billed today. Auto-renews until canceled.")
        XCTAssertEqual(usedTrial.detail, "Billed monthly.")
        XCTAssertFalse(usedTrial.detail.contains("free"))
    }

    func testPlanDetails() {
        XCTAssertEqual(yearly.detail, "7 days free, then billed yearly.")
        XCTAssertEqual(monthly.detail, "7 days free, then billed monthly.")
        XCTAssertEqual(lifetime.detail, "One payment. Nothing renews.")
    }

    func testYearlySavingIsRoundedDown() {
        // $39.99 against 12 x $6.99 = $83.88 saves 52.3 percent.
        XCTAssertEqual(Offer.saving(yearly: 39.99, monthly: 6.99), 52)
        XCTAssertNil(Offer.saving(yearly: 0, monthly: 6.99))
        XCTAssertNil(Offer.saving(yearly: 100, monthly: 6.99))
    }

    /// A spent free week found at the tap: every subscription redraws without trial words, lifetime is untouched.
    func testSpentTrialRedrawsEverySubscription() {
        let redrawn = Offer.redrawn([yearly, monthly, lifetime], freeWeek: [:])
        XCTAssertEqual(redrawn.map(\.trialDays), [0, 0, 0])
        XCTAssertEqual(redrawn[1].trialAction, "Subscribe")
        XCTAssertEqual(redrawn[0].amount, 39.99)
        XCTAssertEqual(redrawn[2], lifetime)
    }

    /// A free week found available puts it back on every subscription plan, not only the tapped one.
    func testFoundTrialRedrawsEverySubscription() {
        let noTrial = Offer(id: "y", term: .yearly, price: "$39.99", trialDays: 0, amount: 39.99)
        let redrawn = Offer.redrawn([noTrial, usedTrial, lifetime], freeWeek: ["y": 7, "m": 7, "l": 0])
        XCTAssertEqual(redrawn.map(\.trialDays), [7, 7, 0])
    }

    /// The preflight never waits on a store that does not answer.
    func testPreflightWaitIsBounded() async {
        let start = Date()
        let slow = await SubscriptionService.within(0.2) { try? await Task.sleep(for: .seconds(5)); return true }
        XCTAssertNil(slow)
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
        let fast = await SubscriptionService.within(2) { true }
        XCTAssertEqual(fast, true)
    }

    /// The last check before Apple's sheet buys only on exactly the terms that were tapped.
    func testConfirmBuysOnlyTheTappedTerms() {
        XCTAssertNil(SubscriptionService.confirm(tapped: monthly, shown: monthly, storePrice: "$6.99", freeWeekDays: 7))
        XCTAssertNil(SubscriptionService.confirm(tapped: lifetime, shown: lifetime, storePrice: "$79.99", freeWeekDays: 0))
        // Free week spent since the screen drew.
        XCTAssertEqual(SubscriptionService.confirm(tapped: monthly, shown: monthly, storePrice: "$6.99", freeWeekDays: 0), .termsChanged)
        // A reload redrew the plan with another price.
        let repriced = Offer(id: "m", term: .monthly, price: "$7.99", trialDays: 7, amount: 7.99)
        XCTAssertEqual(SubscriptionService.confirm(tapped: monthly, shown: repriced, storePrice: "$7.99", freeWeekDays: 7), .termsChanged)
        XCTAssertEqual(SubscriptionService.confirm(tapped: monthly, shown: monthly, storePrice: "$7.99", freeWeekDays: 7), .termsChanged)
        // The plan is gone from the store.
        XCTAssertEqual(SubscriptionService.confirm(tapped: monthly, shown: nil, storePrice: nil, freeWeekDays: 7), .unavailable)
    }
}
