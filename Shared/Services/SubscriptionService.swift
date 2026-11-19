import Foundation
import Observation
import RevenueCat
import StoreKit

enum RevenueCatConfig {
    /// Public SDK key. It is never configured on a simulator.
    static let apiKey = "appl_jiazUDjlvOWTBBUIRFJlnsorHtP"
    static let entitlement = "pro"
    static let yearly = "com.jackwallner.knit.yearly"
    static let monthly = "com.jackwallner.knit.monthly"
    static let lifetime = "com.jackwallner.knit.lifetime"
}

enum Links {
    static let privacy = URL(string: "https://jackwallner.github.io/knit/privacy-policy.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://jackwallner.github.io/knit/support.html")!
    static let writeReview = URL(string: "https://apps.apple.com/app/id6834244566?action=write-review")!
    static let feedback = URL(string: "mailto:jackwallner@gmail.com?subject=Ravel%20feedback")!
}

/// One way to buy the library: a subscription, or a single payment.
struct Offer: Identifiable, Equatable, Sendable {
    enum Term: Int, Sendable { case yearly, monthly, lifetime }

    let id: String
    let term: Term
    /// Localized price for one term, from the store.
    let price: String
    /// Days of free trial this customer can still claim. 0 for none.
    let trialDays: Int
    /// The price as a number, for the yearly plan's saving. 0 when unknown.
    var amount: Decimal = 0
    /// Yearly's price over twelve months, in the store's currency, shown small under the billed amount as on Mahj.
    var perMonth: String? = nil

    var termName: String {
        switch term {
        case .yearly: String(localized: "Yearly", comment: "Paywall plan name")
        case .monthly: String(localized: "Monthly", comment: "Paywall plan name")
        case .lifetime: String(localized: "Lifetime", comment: "Paywall plan name")
        }
    }

    /// Stable across languages, for accessibility identifiers.
    var slug: String {
        switch term {
        case .yearly: "yearly"
        case .monthly: "monthly"
        case .lifetime: "lifetime"
        }
    }

    var priceLine: String {
        switch term {
        case .yearly: String(localized: "\(price) a year", comment: "Plan price; the argument is a localized price such as $39.99")
        case .monthly: String(localized: "\(price) a month", comment: "Plan price; the argument is a localized price")
        case .lifetime: String(localized: "\(price) once", comment: "Lifetime price, paid one time; the argument is a localized price")
        }
    }

    /// The paywall button, worded as on every fleet paywall (Mahj, Cribbity, Bridge).
    var action: String {
        if term == .lifetime { return String(localized: "Buy Lifetime", comment: "Paywall button for the one-time purchase") }
        return trialDays > 0
            ? String(localized: "Start \(trialDays)-Day Free Trial", comment: "Paywall button, title case; the argument is the number of free trial days")
            : String(localized: "Subscribe", comment: "Paywall button")
    }

    /// The onboarding trial button: the paywall's words in sentence case, as on the fleet's trial pages.
    var trialAction: String {
        trialDays > 0
            ? String(localized: "Start \(trialDays)-day free trial", comment: "Onboarding trial button; the argument is the number of free trial days")
            : String(localized: "Subscribe", comment: "Paywall button")
    }

    /// One line of terms over the button, the fleet's approved point-of-purchase copy: trial length, price,
    /// that it renews. An account that already had its free week is charged today, and says so (3.1.2).
    var disclosure: String {
        if term == .lifetime {
            return String(localized: "One payment of \(price). Every pattern is yours for good.", comment: "Lifetime terms; the argument is a localized price")
        }
        return trialDays > 0
            ? String(localized: "\(trialDays) days free, then \(priceLine). Auto-renews until canceled.", comment: "Trial terms; the arguments are the trial days and a price such as $6.99 a month")
            : String(localized: "\(priceLine), billed today. Auto-renews until canceled.", comment: "Terms with no trial; the argument is a price such as $6.99 a month")
    }

    /// The line under a plan's name on the paywall.
    var detail: String {
        switch term {
        case .lifetime: String(localized: "One payment. Nothing renews.", comment: "Under the Lifetime plan")
        case .yearly: trialDays > 0
            ? String(localized: "\(trialDays) days free, then billed yearly.", comment: "Under the Yearly plan; the argument is the trial days")
            : String(localized: "Billed yearly.", comment: "Under the Yearly plan, no trial")
        case .monthly: trialDays > 0
            ? String(localized: "\(trialDays) days free, then billed monthly.", comment: "Under the Monthly plan; the argument is the trial days")
            : String(localized: "Billed monthly.", comment: "Under the Monthly plan, no trial")
        }
    }

    /// The yearly plan's saving over twelve months of the monthly one, in whole percent. nil when it saves nothing
    /// or a price is unknown.
    static func saving(yearly: Decimal, monthly: Decimal) -> Int? {
        guard yearly > 0, monthly > 0 else { return nil }
        let percent = NSDecimalNumber(decimal: (1 - yearly / (monthly * 12)) * 100).doubleValue.rounded(.down)
        return percent >= 1 ? Int(percent) : nil
    }

    /// `offers` with StoreKit's free week: `days` per subscription plan, none where it has no entry. Lifetime never
    /// has one.
    static func redrawn(_ offers: [Offer], freeWeek days: [String: Int]) -> [Offer] {
        offers.map { offer in
            guard offer.term != .lifetime else { return offer }
            return Offer(id: offer.id, term: offer.term, price: offer.price, trialDays: days[offer.id] ?? 0, amount: offer.amount, perMonth: offer.perMonth)
        }
    }

    #if DEBUG
    static let samples = [
        Offer(id: RevenueCatConfig.yearly, term: .yearly, price: "$39.99", trialDays: 7, amount: 39.99, perMonth: "$3.33"),
        Offer(id: RevenueCatConfig.monthly, term: .monthly, price: "$6.99", trialDays: 7, amount: 6.99),
        Offer(id: RevenueCatConfig.lifetime, term: .lifetime, price: "$79.99", trialDays: 0, amount: 79.99),
    ]
    #endif
}

/// Who can open the paid patterns. The tracker never asks this.
@MainActor
@Observable
final class SubscriptionService {
    /// `unconfirmed`: the store took the payment but the entitlement has not arrived yet.
    /// `termsChanged`: the free week the screen showed is not what Apple would sell, so the screen redrew with the
    /// live terms and nothing was bought. `alreadyOwned`: this Apple Account already has the patterns.
    /// `unavailable`: the store did not answer in time, so nothing was sold; a later tap tries again.
    enum Outcome: Equatable { case purchased, cancelled, pending, unconfirmed, failed, termsChanged, alreadyOwned, unavailable }
    enum Restored: Equatable { case found, notFound, cancelled, failed }

    static let shared = SubscriptionService()

    private(set) var isPro = false
    private(set) var offers: [Offer] = []
    private(set) var isLoading = false
    /// The plan the onboarding trial sells. Monthly: someone who has not used the app yet reacts to the
    /// figure on Apple's sheet, and the smaller one starts the trial. The paywall still leads with yearly.
    /// RevenueCat's offering metadata `onboarding_plan` ("monthly" or "yearly") switches it remotely.
    private(set) var onboardingTerm: Offer.Term = .monthly
    @ObservationIgnored private var packages: [String: Package] = [:]
    @ObservationIgnored private var isConfigured = false
    /// The latest answer to "can this Apple Account still have a free week", for the screens across reloads. The
    /// plans share one subscription group, so one answer covers them all.
    @ObservationIgnored private var freeWeek: Bool?
    /// The tap whose StoreKit question is still out, and that question's reply when it came after the tap gave up.
    /// The very next tap uses the late reply once instead of asking again; everything else asks StoreKit.
    @ObservationIgnored private var askingFor: UUID?
    @ObservationIgnored private var lateReply: (eligible: Bool, at: Date)?
    /// StoreKit answered at a tap this session, so RevenueCat's cached list no longer repaints the free week.
    @ObservationIgnored private var storeKitAnswered = false
    #if DEBUG && targetEnvironment(simulator)
    @ObservationIgnored private var testProducts: [String: StoreKit.Product] = [:]
    #endif

    func canOpen(_ design: Design) -> Bool { design.isFree || isPro }

    func canOpen(_ item: LibraryItem) -> Bool { item.isFree || isPro }

    /// Development and tests only: grant or drop the entitlement without a purchase.
    func setLocalOverride(isPro: Bool) { self.isPro = isPro }

    func start() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-Pro") { isPro = true }
        if arguments.contains("-MockProducts") { offers = Offer.samples }
        if let plan = UserDefaults.standard.string(forKey: "OnboardingPlan") { onboardingTerm = Self.onboardingTerm(plan) }
        #endif
        configureIfNeeded()
        guard isConfigured else { return }
        Task { for await info in Purchases.shared.customerInfoStream { apply(info) } }
        Task { await loadOffers() }
    }

    func loadOffers() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        guard isConfigured else {
            #if DEBUG && targetEnvironment(simulator)
            if offers.isEmpty { await loadTestStoreOffers() }
            #endif
            return
        }
        guard let current = try? await Purchases.shared.offerings().current else { return }
        onboardingTerm = Self.onboardingTerm(current.metadata["onboarding_plan"] as? String)
        let terms: [PackageType: Offer.Term] = [.annual: .yearly, .monthly: .monthly, .lifetime: .lifetime]
        let available = current.availablePackages.filter { terms[$0.packageType] != nil }
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: available)
        let statuses = eligibility.values.map(\.status)
        let listed: Bool? = statuses.contains(.ineligible) ? false : statuses.contains(.eligible) ? true : nil
        // A reload's answer is for the screens; a purchase still asks StoreKit itself.
        if let listed, !storeKitAnswered { freeWeek = listed }
        packages = Dictionary(available.map { ($0.storeProduct.productIdentifier, $0) }) { first, _ in first }
        offers = available
            .map { package in
                let product = package.storeProduct
                // Unknown reads as eligible, as on Mahj: the trial is offered unless StoreKit says this account
                // already had its free week. Hiding it on an unanswered check costs eligible people the trial.
                let canTrial = freeWeek ?? (eligibility[package]?.status != .ineligible)
                return Offer(
                    id: product.productIdentifier,
                    term: terms[package.packageType] ?? .monthly,
                    price: product.localizedPriceString,
                    trialDays: canTrial ? Self.trialDays(product.introductoryDiscount) : 0,
                    amount: product.price,
                    perMonth: package.packageType == .annual ? product.localizedPricePerMonth : nil
                )
            }
            .sorted { $0.term.rawValue < $1.term.rawValue }
    }

    #if DEBUG && targetEnvironment(simulator)
    /// Under StoreKit Testing the simulator sells the products in `Ravel.storekit`, so the real
    /// paywall and purchase flow can be walked without touching RevenueCat.
    private func loadTestStoreOffers() async {
        let terms: [String: Offer.Term] = [RevenueCatConfig.yearly: .yearly, RevenueCatConfig.monthly: .monthly, RevenueCatConfig.lifetime: .lifetime]
        guard let products = try? await StoreKit.Product.products(for: Array(terms.keys)), !products.isEmpty else { return }
        testProducts = Dictionary(products.map { ($0.id, $0) }) { first, _ in first }
        offers = products
            .map { product in
                var days = 0
                if let intro = product.subscription?.introductoryOffer, intro.paymentMode == .freeTrial {
                    let unit = switch intro.period.unit {
                    case .day: 1
                    case .week: 7
                    case .month: 30
                    case .year: 365
                    @unknown default: 0
                    }
                    days = intro.period.value * unit
                }
                let perMonth = terms[product.id] == .yearly ? (product.price / 12).formatted(product.priceFormatStyle) : nil
                return Offer(id: product.id, term: terms[product.id] ?? .monthly, price: product.displayPrice, trialDays: days, amount: product.price, perMonth: perMonth)
            }
            .sorted { $0.term.rawValue < $1.term.rawValue }
    }

    private func purchaseFromTestStore(_ product: StoreKit.Product) async -> Outcome {
        guard let result = try? await product.purchase() else { return .failed }
        switch result {
        case let .success(verification):
            if case let .verified(transaction) = verification { await transaction.finish() }
            isPro = true
            return .purchased
        case .userCancelled: return .cancelled
        case .pending: return .pending
        @unknown default: return .failed
        }
    }
    #endif

    /// `shown` reads what the screen offers right now, so a reload during the preflight that changed the plan on
    /// screen stops the purchase.
    func purchase(_ offer: Offer, shown: @MainActor () -> Offer?) async -> Outcome {
        guard isConfigured, packages[offer.id] != nil else {
            #if DEBUG && targetEnvironment(simulator)
            if let product = testProducts[offer.id] { return await purchaseFromTestStore(product) }
            #endif
            #if DEBUG
            // No store on a simulator: stand in for a purchase so the flow can be walked.
            isPro = true
            return .purchased
            #else
            return .failed
            #endif
        }
        let package: Package
        switch await preflight(offer, shown: shown) {
        case let .buy(cleared): package = cleared
        case let .stop(outcome): return outcome
        }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            // Whatever was sold, this account's free week is spent now, and no earlier reply may say otherwise.
            if offer.term != .lifetime { freeWeek = false; askingFor = nil; lateReply = nil }
            apply(result.customerInfo)
            // Paid, but the entitlement can trail the receipt by a moment: ask once more before saying so.
            if !isPro, let info = try? await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent) { apply(info) }
            return isPro ? .purchased : .unconfirmed
        } catch {
            return (error as? ErrorCode) == .paymentPendingError ? .pending : .failed
        }
    }

    private enum Cleared { case buy(Package), stop(Outcome) }

    /// Mahj's preflight, run after every tap: settle ownership, then get StoreKit's free-week answer, each bounded,
    /// then compare the live terms with the tapped ones. A reinstall that owns the patterns is not sold them again,
    /// and an account whose free week is spent never meets a charge under "7 days free" (3.1.2).
    private func preflight(_ offer: Offer, shown: @MainActor () -> Offer?) async -> Cleared {
        let ids: Set = [RevenueCatConfig.yearly, RevenueCatConfig.monthly, RevenueCatConfig.lifetime]
        guard let checked = await Self.within(3, { await Self.ownsInStoreKit(ids) }), let owns = checked else { return .stop(.unavailable) }
        if owns {
            // StoreKit holds a current purchase that RevenueCat has not caught up with yet.
            if !isPro, let info = await Self.within(3, { try? await Purchases.shared.syncPurchases() }) ?? nil { apply(info) }
            return .stop(isPro ? .alreadyOwned : .unavailable)
        }
        var eligible = false
        if offer.term != .lifetime {
            guard let package = packages[offer.id], let answer = await freeWeekAnswer(package) else { return .stop(.unavailable) }
            eligible = answer
        }
        // Nothing below waits, so no reload or RevenueCat update can land between this check and Apple's sheet.
        // The screen went away during the waits (Close, Get Started): nothing reaches Apple's sheet unseen.
        guard !Task.isCancelled else { return .stop(.cancelled) }
        if isPro { return .stop(.alreadyOwned) }
        // The package that will be bought, read after the waits, decides the price and the free week.
        let package = packages[offer.id]
        let liveDays = eligible ? Self.trialDays(package?.storeProduct.introductoryDiscount) : 0
        if offer.term != .lifetime { redrawFreeWeek(eligible) }
        if let stop = Self.confirm(tapped: offer, shown: shown(), storePrice: package?.storeProduct.localizedPriceString, freeWeekDays: liveDays) {
            return .stop(stop)
        }
        return package.map(Cleared.buy) ?? .stop(.unavailable)
    }

    /// The last check before Apple's sheet: buy only when the screen still shows exactly the plan that was tapped,
    /// at the store's price, with the free week StoreKit gives this account. nil means buy.
    nonisolated static func confirm(tapped: Offer, shown: Offer?, storePrice: String?, freeWeekDays: Int) -> Outcome? {
        guard let shown, let storePrice else { return .unavailable }
        guard shown == tapped, storePrice == tapped.price, freeWeekDays == tapped.trialDays else { return .termsChanged }
        return nil
    }

    /// StoreKit's answer within 3 seconds, asked at every tap. When the previous tap gave up waiting and its reply
    /// came in since (within 30 seconds), this tap uses that reply once instead.
    private func freeWeekAnswer(_ package: Package) async -> Bool? {
        if let late = lateReply {
            lateReply = nil
            if Date().timeIntervalSince(late.at) < 30 { return late.eligible }
        }
        guard let subscription = package.storeProduct.sk2Product?.subscription else { return nil }
        let tap = UUID()
        askingFor = tap
        let answer = await Self.within(3) { [weak self] in
            let eligible = await subscription.isEligibleForIntroOffer
            await self?.reply(eligible, for: tap)
            return eligible
        }
        // Answered in time: the reply was this tap's own, so nothing is kept for the next one.
        if answer != nil { lateReply = nil; if askingFor == tap { askingFor = nil } }
        return answer
    }

    /// Drops a kept late reply and the question still out, so the next tap asks StoreKit about the current account.
    func forgetPendingAnswer() {
        askingFor = nil
        lateReply = nil
    }

    /// A reply counts only for the tap still waiting on it: a purchase or a newer tap since makes it stale.
    private func reply(_ eligible: Bool, for tap: UUID) {
        guard askingFor == tap else { return }
        askingFor = nil
        lateReply = (eligible, Date())
        redrawFreeWeek(eligible)
    }

    /// StoreKit's answer, on every subscription plan on screen: the plans share one free week.
    private func redrawFreeWeek(_ eligible: Bool) {
        freeWeek = eligible
        storeKitAnswered = true
        let days = eligible ? packages.mapValues { Self.trialDays($0.storeProduct.introductoryDiscount) } : [:]
        let redrawn = Offer.redrawn(offers, freeWeek: days)
        if redrawn != offers { offers = redrawn }
    }

    /// After `termsChanged`: the words for a free week that turned out to be spent. nil when the change went the
    /// other way.
    func spentTrialMessage(_ tapped: Offer) -> String? {
        guard tapped.trialDays > 0, offers.first(where: { $0.id == tapped.id })?.trialDays == 0 else { return nil }
        return String(localized: "This Apple Account already had its free week.", comment: "After a purchase tap, when the account turned out to have used its free trial")
    }

    /// nil when a matching purchase is there but StoreKit could not verify it: ownership is unresolved, so nothing is sold.
    private nonisolated static func ownsInStoreKit(_ ids: Set<String>) async -> Bool? {
        var unverified = false
        for await result in Transaction.currentEntitlements {
            switch result {
            case let .verified(transaction):
                if ids.contains(transaction.productID), transaction.revocationDate == nil { return true }
            case let .unverified(transaction, _):
                if ids.contains(transaction.productID) { unverified = true }
            }
        }
        return unverified ? nil : false
    }

    /// `work`'s answer, or nil when it takes longer than `seconds`. The work keeps running; nobody waits on it.
    nonisolated static func within<T: Sendable>(_ seconds: Double, _ work: @escaping @Sendable () async -> T) async -> T? {
        let once = Once<T?>()
        return await withCheckedContinuation { continuation in
            once.set(continuation)
            Task { once.resume(await work()) }
            Task { try? await Task.sleep(for: .seconds(seconds)); once.resume(nil) }
        }
    }

    /// Looks for an earlier purchase. A failure to reach the store is not the same as finding nothing.
    func restore() async -> Restored {
        guard isConfigured else { return isPro ? .found : .notFound }
        do { apply(try await Purchases.shared.restorePurchases()) } catch {
            if isPro { return .found }
            // Closing the Apple Account sign-in is a change of mind, not a failure.
            return (error as? ErrorCode) == .purchaseCancelledError ? .cancelled : .failed
        }
        return isPro ? .found : .notFound
    }

    private func apply(_ info: CustomerInfo) {
        isPro = info.entitlements[RevenueCatConfig.entitlement]?.isActive == true
    }

    /// Yearly only when asked for by name; anything else, missing or misspelled, is the monthly default.
    nonisolated static func onboardingTerm(_ value: String?) -> Offer.Term {
        value?.trimmingCharacters(in: .whitespaces).lowercased() == "yearly" ? .yearly : .monthly
    }

    private static func trialDays(_ discount: StoreProductDiscount?) -> Int {
        guard let discount, discount.paymentMode == .freeTrial else { return 0 }
        let unit: Int = switch discount.subscriptionPeriod.unit {
        case .day: 1
        case .week: 7
        case .month: 30
        case .year: 365
        @unknown default: 0
        }
        return discount.subscriptionPeriod.value * unit * max(1, discount.numberOfPeriods)
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        #if targetEnvironment(simulator)
        // Simulator and agent runs never reach the production project: no fake customers.
        return
        #else
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        isConfigured = true
        #endif
    }
}

/// Resumes a continuation with whichever answer comes first and ignores the rest.
private final class Once<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Never>?

    func set(_ continuation: CheckedContinuation<Value, Never>) {
        lock.withLock { self.continuation = continuation }
    }

    func resume(_ value: Value) {
        let waiting = lock.withLock { () -> CheckedContinuation<Value, Never>? in
            defer { continuation = nil }
            return continuation
        }
        waiting?.resume(returning: value)
    }
}
